package table

import (
	"context"
	"errors"
	"strings"
	"unicode"
	"unicode/utf8"

	"showdown/internal/protocol"
	"showdown/internal/store"
)

// ErrInvalidText is returned for empty or oversized chat lines.
var ErrInvalidText = errors.New("chat text must be 1–300 characters")

// SanitizeChat strips control characters, trims and enforces the length.
func SanitizeChat(text string) (string, error) {
	var b strings.Builder
	for _, r := range text {
		if unicode.IsControl(r) {
			continue
		}
		b.WriteRune(r)
	}
	out := strings.TrimSpace(b.String())
	if n := utf8.RuneCountInString(out); n < 1 || n > maxChatRunes {
		return "", ErrInvalidText
	}
	return out, nil
}

// Chat posts a message from a connected client.
func (t *Table) Chat(c *Client, text string) error {
	return t.callErr(func() error {
		if t.state == StateEnded {
			return ErrTableEnded
		}
		if !t.settings.ChatEnabled {
			return ErrChatDisabled
		}
		var kind, name string
		switch c.Role {
		case RolePlayer:
			p, ok := t.players[c.PlayerID]
			if !ok {
				return ErrNotSeated
			}
			if p.Muted {
				return ErrMuted
			}
			kind, name = "player", p.Name
			if c.Admin {
				kind = "admin"
			}
		case RoleSpectator:
			if !t.settings.SpectatorChat && !c.Admin {
				return ErrChatDisabled
			}
			kind, name = "spectator", c.Name
			if c.Admin {
				kind = "admin"
			}
		case RoleAdmin:
			kind, name = "admin", "admin"
		default:
			return ErrIllegalAction
		}
		clean, err := SanitizeChat(text)
		if err != nil {
			return err
		}
		t.postChat(kind, name, clean)
		return nil
	})
}

// postChat appends a line, persists it and broadcasts it.
func (t *Table) postChat(kind, name, text string) {
	t.chatSeq++
	msg := protocol.ChatMessage{ID: t.chatSeq, AuthorKind: kind, AuthorName: name, Text: text, TS: t.nowMs()}
	t.chat = append(t.chat, msg)
	if len(t.chat) > chatKeep {
		t.chat = t.chat[len(t.chat)-chatKeep:]
	}
	row := store.ChatRow{ID: msg.ID, TableID: t.ID, AuthorKind: kind, AuthorName: name, Text: text, TS: msg.TS}
	t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
		_, err := st.InsertChat(ctx, row)
		return err
	})
	t.broadcastMsg(protocol.MustEncode(protocol.TypeChat, "", msg))
}

// RemoveChat deletes a message (admin moderation).
func (t *Table) RemoveChat(id int64) error {
	return t.callErr(func() error {
		found := false
		for i, m := range t.chat {
			if m.ID == id {
				t.chat = append(t.chat[:i], t.chat[i+1:]...)
				found = true
				break
			}
		}
		t.persist.enqueue(func(ctx context.Context, st *store.Store, _ *persister) error {
			err := st.DeleteChat(ctx, t.ID, id)
			if errors.Is(err, store.ErrNotFound) {
				return nil
			}
			return err
		})
		t.audit("chat_removed", "", map[string]any{"id": id})
		if !found {
			return ErrNotFound
		}
		t.broadcastMsg(protocol.MustEncode(protocol.TypeChatRemoved, "", protocol.ChatRemoved{ID: id}))
		return nil
	})
}
