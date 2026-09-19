package store

import (
	"context"
	"errors"
	"testing"
)

func account(t *testing.T, s *Store, ctx context.Context, id, handle string) {
	t.Helper()
	err := s.CreateAccount(ctx, AccountRow{
		ID: id, Handle: handle, HandleKey: handle, DisplayName: handle,
		PasswordHash: "x", CreatedAt: 1000,
		VisProfile: "private", VisWinnings: "private", VisBestHands: "private",
		VisAchievements: "private", VisActivity: "private",
	})
	if err != nil {
		t.Fatalf("CreateAccount %s: %v", handle, err)
	}
}

func friendsStore(t *testing.T) (*Store, context.Context) {
	t.Helper()
	ctx := context.Background()
	s := openTest(t, t.TempDir())
	account(t, s, ctx, "a", "ann")
	account(t, s, ctx, "b", "ben")
	account(t, s, ctx, "c", "cid")
	return s, ctx
}

func TestAFriendshipTakesBothSides(t *testing.T) {
	t.Parallel()
	s, ctx := friendsStore(t)

	if _, err := s.RequestFriend(ctx, "a", "b", 10); err != nil {
		t.Fatalf("RequestFriend: %v", err)
	}
	// Asking twice is not an error and does not ask twice.
	if _, err := s.RequestFriend(ctx, "a", "b", 11); err != nil {
		t.Fatalf("RequestFriend again: %v", err)
	}
	incoming, outgoing, err := s.PendingRequests(ctx, "b")
	if err != nil {
		t.Fatalf("PendingRequests: %v", err)
	}
	if len(incoming) != 1 || incoming[0].Handle != "ann" || len(outgoing) != 0 {
		t.Fatalf("ben's requests: in %v out %v", incoming, outgoing)
	}
	// Nobody is a friend on the strength of an ask alone.
	if ok, _ := s.AreFriends(ctx, "a", "b"); ok {
		t.Error("friends before the answer")
	}

	ok, err := s.AcceptRequest(ctx, "b", "a", 20)
	if err != nil || !ok {
		t.Fatalf("AcceptRequest: %v %v", ok, err)
	}
	for _, pair := range [][2]string{{"a", "b"}, {"b", "a"}} {
		if ok, _ := s.AreFriends(ctx, pair[0], pair[1]); !ok {
			t.Errorf("%s is not a friend of %s", pair[0], pair[1])
		}
	}
	// The ask is spent.
	incoming, _, _ = s.PendingRequests(ctx, "b")
	if len(incoming) != 0 {
		t.Errorf("the request outlived the answer: %v", incoming)
	}
	friends, err := s.Friends(ctx, "a")
	if err != nil || len(friends) != 1 || friends[0].Handle != "ben" {
		t.Fatalf("ann's friends: %v %v", friends, err)
	}
	if _, err := s.RequestFriend(ctx, "a", "b", 30); !errors.Is(err, ErrAlreadyFriends) {
		t.Errorf("asking a friend: %v", err)
	}
}

func TestTwoAsksAreOneAgreement(t *testing.T) {
	t.Parallel()
	s, ctx := friendsStore(t)
	if _, err := s.RequestFriend(ctx, "a", "b", 10); err != nil {
		t.Fatal(err)
	}
	mutual, err := s.RequestFriend(ctx, "b", "a", 20)
	if err != nil {
		t.Fatalf("RequestFriend back: %v", err)
	}
	if !mutual {
		t.Error("both asked, so both agreed")
	}
	if ok, _ := s.AreFriends(ctx, "a", "b"); !ok {
		t.Error("not friends after asking each other")
	}
}

func TestABlockCutsEveryPath(t *testing.T) {
	t.Parallel()
	s, ctx := friendsStore(t)
	if _, err := s.RequestFriend(ctx, "a", "b", 10); err != nil {
		t.Fatal(err)
	}
	if _, err := s.AcceptRequest(ctx, "b", "a", 20); err != nil {
		t.Fatal(err)
	}
	if err := s.CreateInvite(ctx, InviteRow{
		ID: "i1", TableID: "t1", TableName: "Kitchen", FromID: "a", ToID: "b",
		CreatedAt: 25, ExpiresAt: 1_000_000,
	}); err != nil {
		t.Fatal(err)
	}

	if err := s.BlockAccount(ctx, "b", "a", 30); err != nil {
		t.Fatalf("BlockAccount: %v", err)
	}
	if ok, _ := s.AreFriends(ctx, "a", "b"); ok {
		t.Error("still friends after a block")
	}
	if ok, _ := s.IsBlocked(ctx, "a", "b"); !ok {
		t.Error("the block is not seen from the other side")
	}
	// The blocked side cannot ask again, and is not told why.
	if _, err := s.RequestFriend(ctx, "a", "b", 40); !errors.Is(err, ErrBlocked) {
		t.Errorf("request after a block: %v", err)
	}
	invites, err := s.Invites(ctx, "b", 100)
	if err != nil || len(invites) != 0 {
		t.Errorf("invitations survived the block: %v %v", invites, err)
	}
	// Neither profile finds the other by searching.
	found, err := s.SearchAccounts(ctx, "a", "b", 10)
	if err != nil {
		t.Fatal(err)
	}
	for _, f := range found {
		if f.ID == "b" {
			t.Error("the blocker turns up in search")
		}
	}
	blocked, err := s.Blocked(ctx, "b")
	if err != nil || len(blocked) != 1 || blocked[0].Handle != "ann" {
		t.Errorf("ben's block list: %v %v", blocked, err)
	}
	// Lifting it does not put the friendship back.
	if err := s.UnblockAccount(ctx, "b", "a"); err != nil {
		t.Fatal(err)
	}
	if ok, _ := s.AreFriends(ctx, "a", "b"); ok {
		t.Error("unblocking restored the friendship")
	}
	if _, err := s.RequestFriend(ctx, "a", "b", 50); err != nil {
		t.Errorf("request after unblocking: %v", err)
	}
}

func TestSearchFindsByHandleAndName(t *testing.T) {
	t.Parallel()
	s, ctx := friendsStore(t)
	found, err := s.SearchAccounts(ctx, "a", "be", 10)
	if err != nil || len(found) != 1 || found[0].ID != "b" {
		t.Fatalf("search for be: %v %v", found, err)
	}
	// Never yourself.
	found, _ = s.SearchAccounts(ctx, "a", "ann", 10)
	if len(found) != 0 {
		t.Errorf("search found the searcher: %v", found)
	}
}

func TestInvitesExpireAndAreSpent(t *testing.T) {
	t.Parallel()
	s, ctx := friendsStore(t)
	for _, in := range []InviteRow{
		{ID: "live", TableID: "t1", TableName: "Kitchen", FromID: "a", ToID: "b", CreatedAt: 10, ExpiresAt: 500},
		{ID: "dead", TableID: "t2", TableName: "Garage", FromID: "a", ToID: "b", CreatedAt: 5, ExpiresAt: 50},
	} {
		if err := s.CreateInvite(ctx, in); err != nil {
			t.Fatal(err)
		}
	}
	invites, err := s.Invites(ctx, "b", 100)
	if err != nil {
		t.Fatal(err)
	}
	if len(invites) != 1 || invites[0].ID != "live" || invites[0].FromName != "ann" {
		t.Fatalf("invitations at t=100: %v", invites)
	}
	if err := s.DeleteInvite(ctx, "b", "live"); err != nil {
		t.Fatal(err)
	}
	if invites, _ = s.Invites(ctx, "b", 100); len(invites) != 0 {
		t.Errorf("invitation outlived its use: %v", invites)
	}
}

func TestUnfriendGoesBothWays(t *testing.T) {
	t.Parallel()
	s, ctx := friendsStore(t)
	if _, err := s.RequestFriend(ctx, "a", "b", 10); err != nil {
		t.Fatal(err)
	}
	if _, err := s.AcceptRequest(ctx, "b", "a", 20); err != nil {
		t.Fatal(err)
	}
	if err := s.Unfriend(ctx, "a", "b"); err != nil {
		t.Fatal(err)
	}
	for _, pair := range [][2]string{{"a", "b"}, {"b", "a"}} {
		if ok, _ := s.AreFriends(ctx, pair[0], pair[1]); ok {
			t.Errorf("%s still has %s", pair[0], pair[1])
		}
	}
}
