package server

import (
	"context"
	"net/http"

	"showdown/internal/account"
	"showdown/internal/protocol"
	"showdown/internal/store"
)

// canSee is the whole visibility rule, in one place. Your own profile is
// always yours to read; a block hides everything both ways; "public" is
// for anyone signed in or not; "friends" needs the friendship.
//
// A guest (viewerID "") sees only what is public.
func (s *Server) canSee(ctx context.Context, viewerID string, owner store.AccountRow, value string) bool {
	if viewerID != "" && viewerID == owner.ID {
		return true
	}
	if viewerID != "" {
		if blocked, err := s.store.IsBlocked(ctx, viewerID, owner.ID); err != nil || blocked {
			return false
		}
	}
	switch value {
	case visPublic:
		return true
	case visFriends:
		if viewerID == "" {
			return false
		}
		friends, err := s.store.AreFriends(ctx, viewerID, owner.ID)
		return err == nil && friends
	default:
		return false
	}
}

// handleProfile answers another player's profile, one section at a time,
// and only the sections its owner shares with this viewer. A profile that
// is not shared at all is not there: the answer is the same 404 as for a
// handle nobody ever took, so the page cannot be used to find out who
// exists or who blocked you.
func (s *Server) handleProfile(w http.ResponseWriter, r *http.Request) {
	if !s.accountsOn(w) {
		return
	}
	owner, err := s.store.GetAccountByHandle(r.Context(), account.Key(r.PathValue("handle")))
	if err != nil {
		writeError(w, http.StatusNotFound, protocol.ErrNotFound, "no such profile")
		return
	}
	ctx := r.Context()
	var viewerID string
	if viewer, ok := s.accountOf(ctx, r); ok {
		viewerID = viewer.ID
	}
	if !s.canSee(ctx, viewerID, owner, owner.VisProfile) {
		writeError(w, http.StatusNotFound, protocol.ErrNotFound, "no such profile")
		return
	}
	out := map[string]any{
		"handle": owner.Handle, "display_name": owner.DisplayName,
		"since": owner.CreatedAt, "you": viewerID == owner.ID,
	}
	// How the two stand to each other, so the page can offer the right
	// button without a second call.
	if viewerID != "" && viewerID != owner.ID {
		out["relation"] = s.relationTo(ctx, viewerID, owner.ID)
	}

	var stats store.ProfileStats
	needStats := s.canSee(ctx, viewerID, owner, owner.VisWinnings) ||
		s.canSee(ctx, viewerID, owner, owner.VisActivity)
	if needStats {
		stats, err = s.store.AccountStats(ctx, owner.ID)
		if err != nil {
			s.log.Error("profile stats", "err", err)
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the profile")
			return
		}
	}
	if s.canSee(ctx, viewerID, owner, owner.VisWinnings) {
		// Every hand played counts, here as on the owner's own page.
		var per100 float64
		if stats.Hands > 0 {
			per100 = stats.NetBB / float64(stats.Hands) * 100
		}
		out["winnings"] = map[string]any{
			"hands": stats.Hands, "net": stats.Net,
			"net_bb": stats.NetBB, "bb_per_100": per100,
			"rounds_won": stats.RoundsWon, "podiums": stats.Podiums,
		}
	}
	if s.canSee(ctx, viewerID, owner, owner.VisBestHands) {
		best, err := s.store.PublicBestHands(ctx, owner.ID, highlightCount)
		if err != nil {
			s.log.Error("public best hands", "err", err)
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the profile")
			return
		}
		hands := make([]map[string]any, 0, len(best))
		for _, h := range best {
			hands = append(hands, highlightView(h))
		}
		out["best_hands"] = hands
	}
	if s.canSee(ctx, viewerID, owner, owner.VisAchievements) {
		earned, err := s.store.AccountAchievements(ctx, owner.ID)
		if err != nil {
			s.log.Error("profile achievements", "err", err)
			writeError(w, http.StatusInternalServerError, protocol.ErrInternal, "could not read the profile")
			return
		}
		list := make([]map[string]any, 0, len(earned))
		for _, a := range earned {
			if a.EarnedAt == 0 {
				continue // what somebody has not done is nobody's business
			}
			list = append(list, map[string]any{"id": a.ID, "earned_at": a.EarnedAt})
		}
		out["achievements"] = list
	}
	if s.canSee(ctx, viewerID, owner, owner.VisActivity) {
		out["activity"] = map[string]any{
			"last_hand": stats.LastHand, "tables": stats.Tables,
			"playing": s.playingAt(owner.ID),
		}
	}
	writeJSON(w, http.StatusOK, out)
}

// relationTo reports how the viewer stands to another profile.
func (s *Server) relationTo(ctx context.Context, viewerID, otherID string) string {
	if friends, err := s.store.AreFriends(ctx, viewerID, otherID); err == nil && friends {
		return relFriend
	}
	incoming, outgoing, err := s.store.PendingRequests(ctx, viewerID)
	if err != nil {
		return relNone
	}
	for _, rq := range incoming {
		if rq.ID == otherID {
			return relPendingIn
		}
	}
	for _, rq := range outgoing {
		if rq.ID == otherID {
			return relPendingOut
		}
	}
	return relNone
}

// playingAt names the table a profile is sitting at right now, or "".
func (s *Server) playingAt(accountID string) string {
	for _, t := range s.registry.List() {
		seated, _ := t.Profiles()
		for _, p := range seated {
			if p.AccountID == accountID {
				return t.ID
			}
		}
	}
	return ""
}
