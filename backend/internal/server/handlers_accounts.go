package server

import (
	"context"
	"crypto/subtle"
	"errors"
	"net/http"
	"strings"
	"time"

	"showdown/internal/account"
	"showdown/internal/protocol"
	"showdown/internal/store"
	"showdown/internal/table"
)

// accountSessionLifetime is how long a profile stays signed in on a device.
const accountSessionLifetime = 90 * 24 * time.Hour

// accountView is the profile as its owner sees it.
type accountView struct {
	ID          string `json:"id"`
	Handle      string `json:"handle"`
	DisplayName string `json:"display_name"`
	CreatedAt   int64  `json:"created_at"`
	Visibility  struct {
		Profile      string `json:"profile"`
		Winnings     string `json:"winnings"`
		BestHands    string `json:"best_hands"`
		Achievements string `json:"achievements"`
		Activity     string `json:"activity"`
	} `json:"visibility"`
}

func viewOf(a store.AccountRow) accountView {
	v := accountView{ID: a.ID, Handle: a.Handle, DisplayName: a.DisplayName, CreatedAt: a.CreatedAt}
	v.Visibility.Profile = a.VisProfile
	v.Visibility.Winnings = a.VisWinnings
	v.Visibility.BestHands = a.VisBestHands
	v.Visibility.Achievements = a.VisAchievements
	v.Visibility.Activity = a.VisActivity
	return v
}

// accountsOn refuses every profile route on an instance that runs without
// them (the default for a self-hosted table).
func (s *Server) accountsOn(w http.ResponseWriter) bool {
	if s.cfg.Accounts {
		return true
	}
	writeError(w, http.StatusNotFound, protocol.ErrAccountsOff, "this instance has no player profiles")
	return false
}

type registerRequest struct {
	Handle      string `json:"handle"`
	Password    string `json:"password"`
	DisplayName string `json:"display_name"`
}

// handleRegister creates a profile and signs the device in. The recovery
// code comes back exactly once: it is the only way in when the password is
// forgotten, because the server sends no mail.
func (s *Server) handleRegister(w http.ResponseWriter, r *http.Request) {
	if !s.accountsOn(w) {
		return
	}
	var req registerRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := account.ValidateHandle(req.Handle); err != nil {
		writeError(w, http.StatusBadRequest, protocol.ErrValidation, err.Error())
		return
	}
	if err := account.ValidatePassword(req.Password); err != nil {
		writeError(w, http.StatusBadRequest, protocol.ErrValidation, err.Error())
		return
	}
	// The display name goes through the same rules as a later change: it
	// is shown to other people (friend lists, requests, invitations), so
	// "Showdown Support" in 900 characters of right-to-left marks is not
	// something a sign-up gets to store.
	display := req.Handle
	if req.DisplayName != "" {
		name, err := table.NormalizeName(req.DisplayName)
		if err != nil {
			writeError(w, http.StatusBadRequest, protocol.ErrValidation, "invalid display name")
			return
		}
		display = name
	}
	pwHash, err := hashPassword(req.Password)
	if err != nil {
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not hash password")
		return
	}
	code := account.NewRecoveryCode()
	row := store.AccountRow{
		ID: account.NewID(), Handle: req.Handle, HandleKey: account.Key(req.Handle),
		DisplayName: display, PasswordHash: pwHash, RecoveryHash: hashToken(code),
		CreatedAt: s.now().UnixMilli(),
		// Friends see your record — that is most of what a friend is for
		// here. The public sees nothing until the owner says otherwise.
		VisProfile: visFriends, VisWinnings: visFriends, VisBestHands: visFriends,
		VisAchievements: visFriends, VisActivity: visFriends,
	}
	if err := s.store.CreateAccount(r.Context(), row); err != nil {
		if errors.Is(err, store.ErrHandleTaken) {
			writeError(w, http.StatusConflict, protocol.ErrHandleTaken, "that name is taken")
			return
		}
		s.log.Error("create account", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not create the profile")
		return
	}
	token, err := s.createAccountSession(r.Context(), row.ID)
	if err != nil {
		s.log.Error("create account session", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not sign in")
		return
	}
	s.audit(r, "account_created", "", "", map[string]any{"handle": row.Handle})
	writeJSON(w, http.StatusCreated, map[string]any{
		"token": token, "account": viewOf(row), "recovery_code": code,
	})
}

// Visibility values (see the accounts migration).
const (
	visPrivate = "private"
	visFriends = "friends"
	visPublic  = "public"
)

type loginRequest struct {
	Handle   string `json:"handle"`
	Password string `json:"password"`
}

// handleLogin signs a device in.
func (s *Server) handleLogin(w http.ResponseWriter, r *http.Request) {
	if !s.accountsOn(w) {
		return
	}
	var req loginRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	a, err := s.store.GetAccountByHandle(r.Context(), account.Key(req.Handle))
	// The same answer either way: a wrong name must not be told apart from
	// a wrong password.
	if err != nil || !checkPassword(a.PasswordHash, req.Password) || a.PasswordHash == "" {
		writeError(w, http.StatusUnauthorized, protocol.ErrBadCredentials, "wrong name or password")
		return
	}
	token, err := s.createAccountSession(r.Context(), a.ID)
	if err != nil {
		s.log.Error("create account session", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not sign in")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"token": token, "account": viewOf(a)})
}

// handleLogout drops this device's session.
func (s *Server) handleLogout(w http.ResponseWriter, r *http.Request) {
	if !s.accountsOn(w) {
		return
	}
	if token := bearerToken(r); token != "" {
		if err := s.store.DeleteAccountSession(r.Context(), hashToken(token)); err != nil {
			s.log.Error("delete account session", "err", err)
		}
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "signed_out"})
}

// handleAccountMe returns the signed-in profile.
func (s *Server) handleAccountMe(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"account": viewOf(a)})
}

type passwordRequest struct {
	CurrentPassword string `json:"current_password"`
	RecoveryCode    string `json:"recovery_code"`
	NewPassword     string `json:"new_password"`
}

// handleAccountPassword sets a new password, proven either by the current
// one or by the recovery code. Both are replaced: a fresh code comes back,
// and every other device is signed out.
func (s *Server) handleAccountPassword(w http.ResponseWriter, r *http.Request) {
	if !s.accountsOn(w) {
		return
	}
	var req passwordRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if err := account.ValidatePassword(req.NewPassword); err != nil {
		writeError(w, http.StatusBadRequest, protocol.ErrValidation, err.Error())
		return
	}
	// Either signed in with the old password, or holding the recovery code.
	var a store.AccountRow
	switch {
	case req.RecoveryCode != "":
		handle := account.Key(r.Header.Get("X-Handle"))
		found, err := s.store.GetAccountByHandle(r.Context(), handle)
		given := hashToken(req.RecoveryCode)
		if err != nil || found.RecoveryHash == "" ||
			subtle.ConstantTimeCompare([]byte(found.RecoveryHash), []byte(given)) != 1 {
			writeError(w, http.StatusUnauthorized, protocol.ErrBadCredentials, "wrong name or recovery code")
			return
		}
		a = found
	default:
		found, ok := s.requireAccount(w, r)
		if !ok {
			return
		}
		if !checkPassword(found.PasswordHash, req.CurrentPassword) {
			writeError(w, http.StatusUnauthorized, protocol.ErrBadCredentials, "wrong password")
			return
		}
		a = found
	}
	pwHash, err := hashPassword(req.NewPassword)
	if err != nil {
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not hash password")
		return
	}
	code := account.NewRecoveryCode()
	if err := s.store.UpdateAccountSecrets(r.Context(), a.ID, pwHash, hashToken(code)); err != nil {
		s.log.Error("update account secrets", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not save")
		return
	}
	// A new password means every other device starts over.
	if err := s.store.DeleteAccountSessions(r.Context(), a.ID); err != nil {
		s.log.Error("drop account sessions", "err", err)
	}
	token, err := s.createAccountSession(r.Context(), a.ID)
	if err != nil {
		s.log.Error("create account session", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not sign in")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"token": token, "recovery_code": code})
}

// handleAccountStats answers the signed-in profile's own record. It is
// private: nothing here is readable by anyone else yet.
func (s *Server) handleAccountStats(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	st, err := s.store.AccountStats(r.Context(), a.ID)
	if err != nil {
		s.log.Error("account stats", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the statistics")
		return
	}
	classes := make([]map[string]any, 0, len(st.Categories))
	for _, c := range st.Categories {
		classes = append(classes, map[string]any{
			"category": c.Category, "royal": c.Royal, "made": c.Made, "shown": c.Shown,
		})
	}
	// bb/100 is the rate every poker player compares by; it needs hands to
	// mean anything, so it is only sent once some have been played.
	var per100 float64
	if st.Hands > 0 {
		per100 = st.NetBB / float64(st.Hands) * 100
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"hands": st.Hands, "tables": st.Tables, "rounds": st.Rounds,
		"first_hand": st.FirstHand, "last_hand": st.LastHand,
		"net": st.Net, "net_bb": st.NetBB, "bb_per_100": per100,
		"biggest_pot": st.BiggestPot, "biggest_win": st.BiggestWin,
		"best_round": st.BestRound, "hands_won": st.HandsWon,
		"rounds_won": st.RoundsWon, "podiums": st.Podiums, "tournaments": st.Tournaments,
		"vpip": st.VPIP, "showdowns": st.Showdowns, "showdowns_won": st.ShowdownsWon,
		"won_without_showdown": st.WonWithoutShowdown, "folded": st.Folded,
		"all_ins": st.AllIns, "hand_classes": classes,
	})
}

// highlightCount is how many hands of each kind the page keeps. Enough to
// tell a story, few enough that nobody reads their whole history here.
const highlightCount = 8

func highlightView(h store.HandHighlight) map[string]any {
	return map[string]any{
		"category": h.Category, "royal": h.Royal, "description": h.Description,
		"cards": strings.Fields(h.BestCards), "net": h.Net, "won": h.Won,
		"won_bb": h.WonBB(), "big_blind": h.BigBlind, "table_name": h.TableName,
		"hand_number": h.HandNumber, "ended_at": h.EndedAt,
		"shown": h.Shown,
	}
}

// handleAccountHighlights answers the best hands, the biggest pots and the
// milestones of the signed-in profile. Private, like the statistics: the
// public profile reads the same rows through the visibility rules.
func (s *Server) handleAccountHighlights(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	best, err := s.store.BestHands(r.Context(), a.ID, highlightCount)
	if err != nil {
		s.log.Error("best hands", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the hands")
		return
	}
	biggest, err := s.store.BiggestWins(r.Context(), a.ID, highlightCount)
	if err != nil {
		s.log.Error("biggest wins", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the hands")
		return
	}
	earned, err := s.store.AccountAchievements(r.Context(), a.ID)
	if err != nil {
		s.log.Error("achievements", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the achievements")
		return
	}
	bestOut := make([]map[string]any, 0, len(best))
	for _, h := range best {
		bestOut = append(bestOut, highlightView(h))
	}
	biggestOut := make([]map[string]any, 0, len(biggest))
	for _, h := range biggest {
		biggestOut = append(biggestOut, highlightView(h))
	}
	achOut := make([]map[string]any, 0, len(earned))
	for _, a := range earned {
		achOut = append(achOut, map[string]any{
			"id": a.ID, "earned_at": a.EarnedAt, "progress": a.Progress, "goal": a.Goal,
		})
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"best_hands": bestOut, "biggest_wins": biggestOut, "achievements": achOut,
	})
}

// visSections are the parts of a profile that can be shown or hidden, and
// the column each one writes to.
func visSections(a *store.AccountRow) map[string]*string {
	return map[string]*string{
		"profile":      &a.VisProfile,
		"winnings":     &a.VisWinnings,
		"best_hands":   &a.VisBestHands,
		"achievements": &a.VisAchievements,
		"activity":     &a.VisActivity,
	}
}

type profileRequest struct {
	DisplayName *string           `json:"display_name"`
	Visibility  map[string]string `json:"visibility"`
}

// handleAccountUpdate changes the display name and who may see which part
// of the profile: private, friends or public, section by section. What the
// values mean lives in canSee, which is the only thing that reads them.
func (s *Server) handleAccountUpdate(w http.ResponseWriter, r *http.Request) {
	a, ok := s.requireAccount(w, r)
	if !ok {
		return
	}
	var req profileRequest
	if !decodeJSON(w, r, &req) {
		return
	}
	if req.DisplayName != nil {
		name, err := table.NormalizeName(*req.DisplayName)
		if err != nil {
			writeError(w, http.StatusBadRequest, protocol.ErrValidation, "invalid display name")
			return
		}
		a.DisplayName = name
	}
	fields := visSections(&a)
	for section, value := range req.Visibility {
		field, ok := fields[section]
		if !ok {
			writeError(w, http.StatusBadRequest, protocol.ErrValidation, "unknown section "+section)
			return
		}
		if value != visPrivate && value != visFriends && value != visPublic {
			writeError(w, http.StatusBadRequest, protocol.ErrValidation,
				"visibility must be private, friends or public")
			return
		}
		*field = value
	}
	if err := s.store.UpdateAccountProfile(r.Context(), a); err != nil {
		s.log.Error("update account profile", "err", err)
		writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not save")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"account": viewOf(a)})
}

// createAccountSession issues a profile token for a device.
func (s *Server) createAccountSession(ctx context.Context, accountID string) (string, error) {
	token := newToken()
	now := s.now()
	row := store.AccountSessionRow{
		TokenHash: hashToken(token), AccountID: accountID,
		CreatedAt: now.UnixMilli(), ExpiresAt: now.Add(accountSessionLifetime).UnixMilli(),
	}
	if err := s.store.CreateAccountSession(ctx, row); err != nil {
		return "", err
	}
	return token, nil
}

// accountOf resolves the bearer token to a profile, or reports none. It
// never fails the request: a guest simply has no profile.
func (s *Server) accountOf(ctx context.Context, r *http.Request) (store.AccountRow, bool) {
	if !s.cfg.Accounts {
		return store.AccountRow{}, false
	}
	token := bearerToken(r)
	if token == "" {
		return store.AccountRow{}, false
	}
	a, err := s.store.AccountForSession(ctx, hashToken(token), s.now().UnixMilli())
	if err != nil {
		return store.AccountRow{}, false
	}
	return a, true
}

// requireAccount is accountOf for the routes that need one.
func (s *Server) requireAccount(w http.ResponseWriter, r *http.Request) (store.AccountRow, bool) {
	if !s.accountsOn(w) {
		return store.AccountRow{}, false
	}
	a, ok := s.accountOf(r.Context(), r)
	if !ok {
		writeError(w, http.StatusUnauthorized, protocol.ErrUnauthorized, "sign in first")
		return store.AccountRow{}, false
	}
	return a, true
}
