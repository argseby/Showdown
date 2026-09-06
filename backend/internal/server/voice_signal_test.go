package server

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"

	"showdown/internal/protocol"
)

// rawClient is a plain WebSocket client: the botclient plays poker, these
// tests only exercise the transport's size caps.
type rawClient struct {
	t    *testing.T
	conn *websocket.Conn
	id   string
}

func dialRaw(t *testing.T, h *harness, tableID, token, playerID string) *rawClient {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	url := "ws://" + h.addr + "/ws/table/" + tableID
	conn, resp, err := websocket.Dial(ctx, url, nil)
	if resp != nil && resp.Body != nil {
		_ = resp.Body.Close()
	}
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	t.Cleanup(func() { _ = conn.CloseNow() })
	c := &rawClient{t: t, conn: conn, id: playerID}
	c.write(protocol.MustEncode(protocol.TypeHello, "hello-1", protocol.Hello{V: protocol.Version, Token: token}))
	if env := c.read(2 * time.Second); env.Type != protocol.TypeWelcome {
		t.Fatalf("expected welcome, got %q", env.Type)
	}
	return c
}

func (c *rawClient) write(env protocol.Envelope) {
	c.t.Helper()
	data, err := json.Marshal(env)
	if err != nil {
		c.t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := c.conn.Write(ctx, websocket.MessageText, data); err != nil {
		c.t.Fatalf("write: %v", err)
	}
}

// writeRaw sends bytes that need not be a valid envelope.
func (c *rawClient) writeRaw(data []byte) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	return c.conn.Write(ctx, websocket.MessageText, data)
}

func (c *rawClient) read(timeout time.Duration) protocol.Envelope {
	c.t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	_, data, err := c.conn.Read(ctx)
	if err != nil {
		c.t.Fatalf("read: %v", err)
	}
	var env protocol.Envelope
	if err := json.Unmarshal(data, &env); err != nil {
		c.t.Fatalf("read: bad JSON %q", data)
	}
	return env
}

// await reads until a message of one of the wanted types arrives, skipping
// the snapshots and events the table pushes on its own.
func (c *rawClient) await(timeout time.Duration, want ...string) protocol.Envelope {
	c.t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		env := c.read(time.Until(deadline))
		for _, w := range want {
			if env.Type == w {
				return env
			}
		}
	}
	c.t.Fatalf("timed out waiting for %v", want)
	return protocol.Envelope{}
}

// expectClosed asserts the server closed the connection with the given code.
func (c *rawClient) expectClosed(code int) {
	c.t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		ctx, cancel := context.WithTimeout(context.Background(), time.Until(deadline))
		_, _, err := c.conn.Read(ctx)
		cancel()
		if err == nil {
			continue // a snapshot in flight
		}
		var ce websocket.CloseError
		if errors.As(err, &ce) {
			if int(ce.Code) != code {
				c.t.Fatalf("close code = %d, want %d", ce.Code, code)
			}
			return
		}
		c.t.Fatalf("read: %v", err)
	}
	c.t.Fatal("connection stayed open")
}

// signalOfSize builds a voice_signal whose opaque data is exactly n bytes,
// the way a browser's SDP offer arrives.
func signalOfSize(to string, n int) protocol.Envelope {
	sdp := "v=0\r\n" + strings.Repeat("a", n)
	return protocol.MustEncode(protocol.TypeVoiceSignal, "c-1", protocol.VoiceSignal{
		To: to, Kind: "offer", Data: sdp[:n],
	})
}

// A camera offer is far bigger than an audio-only one (~9 KiB against
// ~1.5 KiB). It must reach the other player instead of being refused.
func TestVoiceSignalCarriesVideoOffer(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, _ := h.createTable(fastSettings())

	status, a := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "alice"})
	if status != http.StatusCreated {
		t.Fatalf("join alice: %d %v", status, a)
	}
	status, b := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "bob"})
	if status != http.StatusCreated {
		t.Fatalf("join bob: %d %v", status, b)
	}

	alice := dialRaw(t, h, tableID, a["player_token"].(string), a["player_id"].(string))
	bob := dialRaw(t, h, tableID, b["player_token"].(string), b["player_id"].(string))

	const videoOffer = 9 << 10 // a Chrome offer with a video track
	alice.write(signalOfSize(bob.id, videoOffer))

	got := bob.await(5*time.Second, protocol.TypeVoiceSignal)
	var sig protocol.VoiceSignal
	if err := json.Unmarshal(got.Payload, &sig); err != nil {
		t.Fatal(err)
	}
	if sig.From != alice.id {
		t.Errorf("from = %q, want %q", sig.From, alice.id)
	}
	if len(sig.Data) != videoOffer {
		t.Errorf("relayed %d bytes, want %d", len(sig.Data), videoOffer)
	}
}

// The signalling payload is still bounded, and refusing one must not take
// the player's table connection down with it.
func TestVoiceSignalTooLargeIsRefused(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, _ := h.createTable(fastSettings())

	_, a := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "alice"})
	_, b := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "bob"})
	alice := dialRaw(t, h, tableID, a["player_token"].(string), a["player_id"].(string))
	bob := dialRaw(t, h, tableID, b["player_token"].(string), b["player_id"].(string))

	alice.write(signalOfSize(bob.id, wsSignalDataLimit+1))

	env := alice.await(5*time.Second, protocol.TypeError)
	var perr protocol.ErrorPayload
	if err := json.Unmarshal(env.Payload, &perr); err != nil {
		t.Fatal(err)
	}
	if perr.Code != protocol.ErrIllegalAction {
		t.Errorf("code = %q, want %q", perr.Code, protocol.ErrIllegalAction)
	}

	// The socket still works: a signal within the cap goes through.
	alice.write(signalOfSize(bob.id, 1024))
	bob.await(5*time.Second, protocol.TypeVoiceSignal)
}

// Everything that is not signalling keeps the ordinary 8 KiB cap.
func TestOversizeNonSignalMessageClosesConnection(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, _ := h.createTable(fastSettings())

	_, a := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "alice"})
	alice := dialRaw(t, h, tableID, a["player_token"].(string), a["player_id"].(string))

	alice.write(protocol.MustEncode(protocol.TypeChat, "c-1", protocol.ChatPayload{
		Text: strings.Repeat("x", wsMessageLimit),
	}))
	alice.expectClosed(protocol.ClosePolicy)
}

// A frame beyond the raw read limit is dropped by the transport itself.
func TestFrameBeyondReadLimitClosesConnection(t *testing.T) {
	h := newHarness(t, t.TempDir(), "")
	defer h.stop()
	tableID, _ := h.createTable(fastSettings())

	_, a := h.request(http.MethodPost, "/api/tables/"+tableID+"/join", "", map[string]any{"name": "alice"})
	alice := dialRaw(t, h, tableID, a["player_token"].(string), a["player_id"].(string))

	if err := alice.writeRaw([]byte(strings.Repeat("x", wsReadLimit+1))); err != nil {
		return // the server may close before the write completes
	}
	alice.expectClosed(int(websocket.StatusMessageTooBig))
}
