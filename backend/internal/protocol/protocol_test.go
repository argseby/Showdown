package protocol

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const fixturesDir = "../../../docs/protocol/fixtures"

// payloadTypes maps fixture file names (without .json) to the typed payload
// they must round-trip through. Empty payloads are represented by struct{}.
var payloadTypes = map[string]func() any{
	"hello":             func() any { return &Hello{} },
	"action":            func() any { return &ActionPayload{} },
	"sit_out":           func() any { return &struct{}{} },
	"sit_in":            func() any { return &struct{}{} },
	"rebuy":             func() any { return &struct{}{} },
	"leave":             func() any { return &struct{}{} },
	"show_cards":        func() any { return &struct{}{} },
	"chat_client":       func() any { return &ChatPayload{} },
	"say":               func() any { return &SayPayload{} },
	"straddle":          func() any { return &StraddlePayload{} },
	"run_twice":         func() any { return &RunTwicePayload{} },
	"phrase":            func() any { return &PhrasePayload{} },
	"ping":              func() any { return &struct{}{} },
	"welcome":           func() any { return &Welcome{} },
	"snapshot":          func() any { return &Snapshot{} },
	"events":            func() any { return &EventsPayload{} },
	"chat_server":       func() any { return &ChatMessage{} },
	"chat_history":      func() any { return &ChatHistory{} },
	"chat_removed":      func() any { return &ChatRemoved{} },
	"ack":               func() any { return &Ack{} },
	"error":             func() any { return &ErrorPayload{} },
	"kicked":            func() any { return &Kicked{} },
	"table_ended":       func() any { return &TableEnded{} },
	"server_restarting": func() any { return &struct{}{} },
	"pong":              func() any { return &Pong{} },
}

// canonical re-encodes arbitrary JSON with sorted keys and no whitespace.
func canonical(t *testing.T, raw []byte) []byte {
	t.Helper()
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.UseNumber()
	var v any
	if err := dec.Decode(&v); err != nil {
		t.Fatalf("decode: %v", err)
	}
	out, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("encode: %v", err)
	}
	return out
}

func TestFixturesRoundTrip(t *testing.T) {
	t.Parallel()
	files, err := filepath.Glob(filepath.Join(fixturesDir, "*.json"))
	if err != nil || len(files) == 0 {
		t.Fatalf("no fixtures found in %s: %v", fixturesDir, err)
	}
	covered := map[string]bool{}
	for _, file := range files {
		name := strings.TrimSuffix(filepath.Base(file), ".json")
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			raw, err := os.ReadFile(file)
			if err != nil {
				t.Fatal(err)
			}
			var env Envelope
			if err := json.Unmarshal(raw, &env); err != nil {
				t.Fatalf("envelope: %v", err)
			}
			if env.Type == "" {
				t.Fatal("fixture has no type")
			}
			mk, ok := payloadTypes[name]
			if !ok {
				t.Fatalf("no payload type registered for fixture %s", name)
			}
			payload := mk()
			dec := json.NewDecoder(bytes.NewReader(env.Payload))
			dec.DisallowUnknownFields()
			if err := dec.Decode(payload); err != nil {
				t.Fatalf("payload does not fit %T: %v", payload, err)
			}
			re, err := Encode(env.Type, env.ID, payload)
			if err != nil {
				t.Fatal(err)
			}
			got, err := json.Marshal(re)
			if err != nil {
				t.Fatal(err)
			}
			if a, b := canonical(t, got), canonical(t, raw); !bytes.Equal(a, b) {
				t.Fatalf("round trip differs\n got: %s\nwant: %s", a, b)
			}
		})
		covered[name] = true
	}
	for name := range payloadTypes {
		if !covered[name] {
			t.Errorf("fixture %s.json missing", name)
		}
	}
}

func TestEncodeHelpers(t *testing.T) {
	t.Parallel()
	env := MustEncode(TypePong, "", Pong{ServerTS: 5})
	if env.Type != TypePong || string(env.Payload) != `{"server_ts":5}` {
		t.Fatalf("envelope = %+v", env)
	}
	env, err := Encode(TypeServerRestarting, "", nil)
	if err != nil || env.Payload != nil {
		t.Fatalf("nil payload: %+v %v", env, err)
	}
	if _, err := Encode("x", "", make(chan int)); err == nil {
		t.Fatal("expected marshal error")
	}
	defer func() {
		if recover() == nil {
			t.Fatal("MustEncode must panic on error")
		}
	}()
	MustEncode("x", "", make(chan int))
	if *Int(3) != 3 || *Int64(4) != 4 || !*Bool(true) {
		t.Fatal("pointer helpers")
	}
}
