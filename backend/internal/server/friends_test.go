package server

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"

	"showdown/internal/protocol"
)

// signUp creates a profile and returns its token.
func signUp(t *testing.T, h *harness, handle string) string {
	t.Helper()
	_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": handle, "password": "hunter22",
	})
	token, _ := out["token"].(string)
	if token == "" {
		t.Fatalf("register %s: %v", handle, out)
	}
	return token
}

// userSocket opens /ws/me for a profile and returns the events it receives.
type userSocket struct {
	t    *testing.T
	conn *websocket.Conn
}

func dialUser(t *testing.T, h *harness, token string) *userSocket {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	conn, resp, err := websocket.Dial(ctx, "ws://"+h.addr+"/ws/me", nil)
	if resp != nil && resp.Body != nil {
		_ = resp.Body.Close()
	}
	if err != nil {
		t.Fatalf("dial /ws/me: %v", err)
	}
	t.Cleanup(func() { _ = conn.CloseNow() })
	s := &userSocket{t: t, conn: conn}
	s.write(protocol.MustEncode(protocol.TypeHello, "h1", protocol.Hello{V: protocol.Version, Token: token}))
	if env := s.read(2 * time.Second); env.Type != protocol.TypeWelcome {
		t.Fatalf("expected welcome on the user socket, got %q", env.Type)
	}
	return s
}

func (s *userSocket) write(env protocol.Envelope) {
	s.t.Helper()
	data, err := json.Marshal(env)
	if err != nil {
		s.t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := s.conn.Write(ctx, websocket.MessageText, data); err != nil {
		s.t.Fatalf("write: %v", err)
	}
}

func (s *userSocket) read(timeout time.Duration) protocol.Envelope {
	s.t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	_, data, err := s.conn.Read(ctx)
	if err != nil {
		s.t.Fatalf("read: %v", err)
	}
	var env protocol.Envelope
	if err := json.Unmarshal(data, &env); err != nil {
		s.t.Fatalf("decode: %v", err)
	}
	return env
}

// waitFor reads until an event of this kind turns up, ignoring the rest.
func (s *userSocket) waitFor(kind string, timeout time.Duration) protocol.UserEvent {
	s.t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		env := s.read(time.Until(deadline))
		if env.Type != protocol.TypeUserEvent {
			continue
		}
		var e protocol.UserEvent
		if err := json.Unmarshal(env.Payload, &e); err != nil {
			s.t.Fatalf("decode user event: %v", err)
		}
		if e.Kind == kind {
			return e
		}
	}
	s.t.Fatalf("no %s event within %s", kind, timeout)
	return protocol.UserEvent{}
}

// Asking, answering, and what each side is told about it.
func TestFriendRequestReachesTheOtherDevice(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	ann, ben := signUp(t, h, "ann"), signUp(t, h, "ben")
	bensPhone := dialUser(t, h, ben)

	status, out := h.request(http.MethodPost, "/api/friends/requests", ann,
		map[string]string{"handle": "ben"})
	if status != http.StatusOK || out["state"] != "pending_out" {
		t.Fatalf("request: %d %v", status, out)
	}
	// It arrives where the person is, not where the table is.
	e := bensPhone.waitFor(protocol.UserFriendRequest, 3*time.Second)
	if e.Handle != "ann" {
		t.Errorf("friend request event: %+v", e)
	}

	_, list := h.request(http.MethodGet, "/api/friends", ben, nil)
	incoming := list["incoming"].([]any)
	if len(incoming) != 1 || incoming[0].(map[string]any)["handle"] != "ann" {
		t.Fatalf("ben's incoming: %v", list)
	}

	// Accepting tells the asker, who was not looking at the screen.
	annsLaptop := dialUser(t, h, ann)
	status, out = h.request(http.MethodPost, "/api/friends/requests/ann/accept", ben, nil)
	if status != http.StatusOK || out["state"] != "friend" {
		t.Fatalf("accept: %d %v", status, out)
	}
	if e := annsLaptop.waitFor(protocol.UserFriendAccepted, 3*time.Second); e.Handle != "ben" {
		t.Errorf("accepted event: %+v", e)
	}
	_, list = h.request(http.MethodGet, "/api/friends", ann, nil)
	if len(list["friends"].([]any)) != 1 {
		t.Errorf("ann's friends: %v", list)
	}
}

// A decline leaves no trace for the asker; a block also closes the door.
func TestDeclineIsQuietAndBlockIsFinal(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	ann, ben := signUp(t, h, "ann"), signUp(t, h, "ben")

	h.request(http.MethodPost, "/api/friends/requests", ann, map[string]string{"handle": "ben"})
	if status, _ := h.request(http.MethodPost, "/api/friends/requests/ann/decline", ben, nil); status != http.StatusOK {
		t.Fatal("decline")
	}
	_, list := h.request(http.MethodGet, "/api/friends", ann, nil)
	if len(list["outgoing"].([]any)) != 0 || len(list["friends"].([]any)) != 0 {
		t.Errorf("after a decline: %v", list)
	}
	// Asking again is allowed after a plain decline.
	if status, _ := h.request(http.MethodPost, "/api/friends/requests", ann,
		map[string]string{"handle": "ben"}); status != http.StatusOK {
		t.Error("a second ask after a decline")
	}

	// A block ends it, and says nothing about itself.
	if status, _ := h.request(http.MethodPost, "/api/friends/requests/ann/block", ben, nil); status != http.StatusOK {
		t.Fatal("block")
	}
	// To the blocked side it reads exactly like a name nobody ever took —
	// the same answer the profile route and the search give.
	status, out := h.request(http.MethodPost, "/api/friends/requests", ann,
		map[string]string{"handle": "ben"})
	_, missing := h.request(http.MethodPost, "/api/friends/requests", ann,
		map[string]string{"handle": "nobody"})
	if status != http.StatusNotFound {
		t.Errorf("asking after a block: %d %v", status, out)
	}
	if out["error"].(map[string]any)["code"] != missing["error"].(map[string]any)["code"] {
		t.Errorf("a block is told apart from a missing profile: %v vs %v", out, missing)
	}
	// Neither finds the other by searching.
	_, found := h.request(http.MethodGet, "/api/friends/search?q=be", ann, nil)
	if len(found["results"].([]any)) != 0 {
		t.Errorf("the blocker turns up in search: %v", found)
	}
	_, list = h.request(http.MethodGet, "/api/friends", ben, nil)
	if len(list["blocked"].([]any)) != 1 {
		t.Errorf("ben's block list: %v", list)
	}
}

// Blocking yourself is a mistake, not a server failure, and a display
// name is checked at sign-up the same way it is on a change.
func TestSelfBlockAndDisplayNameAreRefusedPlainly(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	ann := signUp(t, h, "ann")

	if status, _ := h.request(http.MethodPost, "/api/friends/requests/ann/block", ann, nil); status != http.StatusBadRequest {
		t.Errorf("blocking yourself: %d, want 400", status)
	}

	// A name shown to other people cannot be 900 characters of anything.
	for _, name := range []string{
		strings.Repeat("a", 300),
		"  ",
		"admin",
		"we\u202eird",
	} {
		status, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
			"handle": "ben" + strconv.Itoa(len(name)), "password": "hunter22",
			"display_name": name,
		})
		if status != http.StatusBadRequest {
			t.Errorf("sign-up with display name %q: %d %v", name, status, out)
		}
	}
	// A plain one is kept, and none at all falls back to the handle.
	_, out := h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "cid", "password": "hunter22", "display_name": "Cid the Kid",
	})
	if out["account"].(map[string]any)["display_name"] != "Cid the Kid" {
		t.Errorf("display name: %v", out)
	}
	_, out = h.request(http.MethodPost, "/api/accounts", "", map[string]string{
		"handle": "dora", "password": "hunter22",
	})
	if out["account"].(map[string]any)["display_name"] != "dora" {
		t.Errorf("display name falls back to the handle: %v", out)
	}
}

// Search says how each profile already stands to the searcher.
func TestSearchCarriesTheRelation(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	ann, ben := signUp(t, h, "ann"), signUp(t, h, "ben")
	signUp(t, h, "bella")

	h.request(http.MethodPost, "/api/friends/requests", ann, map[string]string{"handle": "ben"})
	_, found := h.request(http.MethodGet, "/api/friends/search?q=be", ann, nil)
	byHandle := map[string]string{}
	for _, r := range found["results"].([]any) {
		m := r.(map[string]any)
		byHandle[m["handle"].(string)] = m["relation"].(string)
	}
	if byHandle["ben"] != "pending_out" || byHandle["bella"] != "none" {
		t.Fatalf("relations: %v", byHandle)
	}
	// From the other side the same ask reads as incoming.
	_, found = h.request(http.MethodGet, "/api/friends/search?q=ann", ben, nil)
	first := found["results"].([]any)[0].(map[string]any)
	if first["relation"] != "pending_in" {
		t.Errorf("ben sees ann as %v", first["relation"])
	}
}

// An invitation goes from one friend at a table to another, and is waiting
// for them even if nothing was open when it was sent.
func TestInviteNeedsAFriendAndASeat(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	ann, ben := signUp(t, h, "ann"), signUp(t, h, "ben")
	cid := signUp(t, h, "cid")
	tableID, _ := h.createTable(fastSettings())

	// Ann sits down, signed in.
	status, _ := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", ann,
		map[string]any{"name": "Ann"})
	if status != http.StatusCreated {
		t.Fatalf("join: %d", status)
	}
	// Ben is not a friend yet.
	if status, _ := h.request(http.MethodPost, "/api/tables/"+tableID+"/invites", ann,
		map[string]string{"handle": "ben"}); status != http.StatusForbidden {
		t.Errorf("inviting a stranger: %d", status)
	}
	h.request(http.MethodPost, "/api/friends/requests", ann, map[string]string{"handle": "ben"})
	h.request(http.MethodPost, "/api/friends/requests/ann/accept", ben, nil)

	bensPhone := dialUser(t, h, ben)
	status, out := h.request(http.MethodPost, "/api/tables/"+tableID+"/invites", ann,
		map[string]string{"handle": "ben"})
	if status != http.StatusCreated {
		t.Fatalf("invite: %d %v", status, out)
	}
	e := bensPhone.waitFor(protocol.UserTableInvite, 3*time.Second)
	if e.TableID != tableID || e.Handle != "ann" {
		t.Errorf("invite event: %+v", e)
	}
	// And it is still there for a device that was not listening.
	_, list := h.request(http.MethodGet, "/api/friends", ben, nil)
	invites := list["invites"].([]any)
	if len(invites) != 1 || invites[0].(map[string]any)["table_id"] != tableID {
		t.Fatalf("ben's invitations: %v", list)
	}
	id := invites[0].(map[string]any)["id"].(string)
	if status, _ := h.request(http.MethodDelete, "/api/friends/invites/"+id, ben, nil); status != http.StatusNoContent {
		t.Error("dismissing an invitation")
	}

	// Cid is at no table and invites nobody.
	if status, _ := h.request(http.MethodPost, "/api/tables/"+tableID+"/invites", cid,
		map[string]string{"handle": "ben"}); status != http.StatusForbidden {
		t.Errorf("inviting to a table you are not at: %d", status)
	}
}

// The home screen's list: which friends are playing, where, and how much
// room is left.
func TestFriendsPlayingShowsTheTable(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	ann, ben := signUp(t, h, "ann"), signUp(t, h, "ben")
	tableID, _ := h.createTable(fastSettings())

	h.request(http.MethodPost, "/api/friends/requests", ann, map[string]string{"handle": "ben"})
	h.request(http.MethodPost, "/api/friends/requests/ann/accept", ben, nil)

	// Nobody is playing yet.
	_, out := h.request(http.MethodGet, "/api/friends/playing", ben, nil)
	if len(out["tables"].([]any)) != 0 {
		t.Fatalf("before anyone sat down: %v", out)
	}

	bensPhone := dialUser(t, h, ben)
	if status, _ := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", ann,
		map[string]any{"name": "Ann"}); status != http.StatusCreated {
		t.Fatal("join")
	}
	bensPhone.waitFor(protocol.UserFriendsPlaying, 3*time.Second)

	_, out = h.request(http.MethodGet, "/api/friends/playing", ben, nil)
	tables := out["tables"].([]any)
	if len(tables) != 1 {
		t.Fatalf("friends playing: %v", out)
	}
	tbl := tables[0].(map[string]any)
	friends := tbl["friends"].([]any)
	if tbl["id"] != tableID || len(friends) != 1 || friends[0].(map[string]any)["handle"] != "ann" {
		t.Errorf("the table ann is at: %v", tbl)
	}
	if tbl["free_seats"] != float64(5) || tbl["seated"] != float64(1) {
		t.Errorf("room at the table: %v", tbl)
	}

	// A guest at the same table is nobody's friend and shows up for no one.
	_, guests := h.request(http.MethodGet, "/api/friends/playing", ann, nil)
	if len(guests["tables"].([]any)) != 0 {
		t.Errorf("ann sees herself: %v", guests)
	}
}

// The user socket refuses a bad token and takes no commands.
func TestUserSocketIsPushOnly(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	ann := signUp(t, h, "ann")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	conn, resp, err := websocket.Dial(ctx, "ws://"+h.addr+"/ws/me", nil)
	if resp != nil && resp.Body != nil {
		_ = resp.Body.Close()
	}
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer func() { _ = conn.CloseNow() }()
	data, _ := json.Marshal(protocol.MustEncode(protocol.TypeHello, "h", protocol.Hello{
		V: protocol.Version, Token: "not-a-token",
	}))
	if err := conn.Write(ctx, websocket.MessageText, data); err != nil {
		t.Fatal(err)
	}
	if _, _, err := conn.Read(ctx); err == nil {
		t.Error("a bad token stayed connected")
	}

	// A real socket answers a ping and closes on anything else.
	s := dialUser(t, h, ann)
	s.write(protocol.Envelope{Type: protocol.TypePing, ID: "p1"})
	if env := s.read(2 * time.Second); env.Type != protocol.TypePong {
		t.Fatalf("ping answered with %q", env.Type)
	}
	s.write(protocol.Envelope{Type: protocol.TypeAction, ID: "a1"})
	ctx2, cancel2 := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel2()
	if _, _, err := s.conn.Read(ctx2); err == nil {
		t.Error("the user socket accepted a command")
	}
}

// Without profiles there is no user socket and no friends at all.
func TestFriendsNeedProfiles(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	if status, _ := h.request(http.MethodGet, "/api/friends", "", nil); status != http.StatusNotFound {
		t.Errorf("friends without profiles: %d", status)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	conn, resp, err := websocket.Dial(ctx, "ws://"+h.addr+"/ws/me", nil)
	if err == nil {
		_ = conn.CloseNow()
		t.Error("the user socket opened on an instance without profiles")
	}
	if resp != nil {
		if resp.Body != nil {
			_ = resp.Body.Close()
		}
		if resp.StatusCode != http.StatusNotFound {
			t.Errorf("user socket status: %d", resp.StatusCode)
		}
	}
}

// The visibility switches, read from the other side: private hides the
// page itself, friends opens it only to a friend, public to anyone.
func TestWhoCanSeeAProfile(t *testing.T) {
	t.Parallel()
	h := newHarness(t, t.TempDir(), "", on)
	defer h.stop()
	ann, ben := signUp(t, h, "ann"), signUp(t, h, "ben")
	cid := signUp(t, h, "cid")

	// Everything starts private: for everyone else the page is not there.
	if status, _ := h.request(http.MethodGet, "/api/profiles/ann", ben, nil); status != http.StatusNotFound {
		t.Errorf("a private profile: %d", status)
	}
	// Its owner always sees it.
	status, mine := h.request(http.MethodGet, "/api/profiles/ann", ann, nil)
	if status != http.StatusOK || mine["you"] != true {
		t.Fatalf("own profile: %d %v", status, mine)
	}

	// Friends only: a stranger still finds nothing.
	h.request(http.MethodPatch, "/api/accounts/me", ann, map[string]any{
		"visibility": map[string]string{"profile": "friends", "winnings": "friends"},
	})
	if status, _ := h.request(http.MethodGet, "/api/profiles/ann", ben, nil); status != http.StatusNotFound {
		t.Errorf("friends-only profile before the friendship: %d", status)
	}
	h.request(http.MethodPost, "/api/friends/requests", ann, map[string]string{"handle": "ben"})
	h.request(http.MethodPost, "/api/friends/requests/ann/accept", ben, nil)

	status, seen := h.request(http.MethodGet, "/api/profiles/ann", ben, nil)
	if status != http.StatusOK {
		t.Fatalf("friends-only profile for a friend: %d %v", status, seen)
	}
	if seen["relation"] != "friend" || seen["winnings"] == nil {
		t.Errorf("what ben sees: %v", seen)
	}
	// Sections that were not shared are absent, not empty.
	if _, has := seen["best_hands"]; has {
		t.Errorf("best hands were never shared: %v", seen)
	}
	// Cid is nobody's friend.
	if status, _ := h.request(http.MethodGet, "/api/profiles/ann", cid, nil); status != http.StatusNotFound {
		t.Errorf("friends-only profile for a stranger: %d", status)
	}

	// Public: even a guest with no profile at all.
	h.request(http.MethodPatch, "/api/accounts/me", ann, map[string]any{
		"visibility": map[string]string{"profile": "public"},
	})
	status, guestView := h.request(http.MethodGet, "/api/profiles/ann", "", nil)
	if status != http.StatusOK {
		t.Fatalf("public profile for a guest: %d", status)
	}
	if guestView["winnings"] != nil {
		t.Errorf("a guest saw the friends-only winnings: %v", guestView)
	}

	// A block hides a public profile from the blocked side.
	h.request(http.MethodPost, "/api/friends/requests/ben/block", ann, nil)
	if status, _ := h.request(http.MethodGet, "/api/profiles/ann", ben, nil); status != http.StatusNotFound {
		t.Errorf("a blocked viewer saw a public profile: %d", status)
	}
}
