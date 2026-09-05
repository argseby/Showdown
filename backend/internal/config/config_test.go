package config

import (
	"log/slog"
	"reflect"
	"strings"
	"testing"
)

func env(m map[string]string) func(string) string {
	return func(k string) string { return m[k] }
}

func TestLoadDefaults(t *testing.T) {
	t.Parallel()
	cfg, err := Load(env(map[string]string{}))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := Config{
		ListenAddr:          ":8080",
		DataDir:             "/data",
		TableRetentionDays:  90,
		MaxTables:           100,
		MaxConnectionsPerIP: 50,
		TrustProxy:          true,
		LogLevel:            "info",
		LogFormat:           "json",
	}
	if !reflect.DeepEqual(cfg, want) {
		t.Fatalf("defaults mismatch:\n got %+v\nwant %+v", cfg, want)
	}
}

func TestLoadOverrides(t *testing.T) {
	t.Parallel()
	cfg, err := Load(env(map[string]string{
		"LISTEN_ADDR":            "127.0.0.1:9090",
		"DATA_DIR":               "/tmp/x",
		"TABLE_RETENTION_DAYS":   "0",
		"MAX_TABLES":             "5",
		"MAX_CONNECTIONS_PER_IP": "7",
		"TRUST_PROXY":            "0",
		"DEV_CORS_ORIGIN":        "http://localhost:3000",
		"LOG_LEVEL":              "DEBUG",
		"LOG_FORMAT":             "text",
	}))
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if cfg.ListenAddr != "127.0.0.1:9090" || cfg.DataDir != "/tmp/x" ||
		cfg.TableRetentionDays != 0 || cfg.MaxTables != 5 || cfg.MaxConnectionsPerIP != 7 ||
		cfg.TrustProxy || cfg.DevCORSOrigin != "http://localhost:3000" ||
		cfg.LogLevel != "debug" || cfg.LogFormat != "text" {
		t.Fatalf("overrides not applied: %+v", cfg)
	}
	if cfg.SlogLevel() != slog.LevelDebug {
		t.Fatalf("SlogLevel = %v, want debug", cfg.SlogLevel())
	}
}

func TestLoadValidation(t *testing.T) {
	t.Parallel()
	base := map[string]string{}
	cases := []struct {
		name    string
		env     map[string]string
		wantErr string
	}{
		{"bad bool", merge(base, "TRUST_PROXY", "maybe"), "TRUST_PROXY must be a boolean"},
		{"bad int", merge(base, "MAX_TABLES", "ten"), "MAX_TABLES must be an integer"},
		{"zero tables", merge(base, "MAX_TABLES", "0"), "MAX_TABLES must be >= 1"},
		{"negative retention", merge(base, "TABLE_RETENTION_DAYS", "-1"), "TABLE_RETENTION_DAYS"},
		{"zero conns", merge(base, "MAX_CONNECTIONS_PER_IP", "0"), "MAX_CONNECTIONS_PER_IP"},
		{"cors with path", merge(base, "DEV_CORS_ORIGIN", "http://localhost:3000/app"), "DEV_CORS_ORIGIN"},
		{"cors bad scheme", merge(base, "DEV_CORS_ORIGIN", "ftp://localhost"), "DEV_CORS_ORIGIN"},
		{"cors no scheme", merge(base, "DEV_CORS_ORIGIN", "localhost:3000"), "DEV_CORS_ORIGIN"},
		{"bad level", merge(base, "LOG_LEVEL", "verbose"), "LOG_LEVEL"},
		{"bad format", merge(base, "LOG_FORMAT", "xml"), "LOG_FORMAT"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			_, err := Load(env(tc.env))
			if err == nil {
				t.Fatalf("expected error containing %q, got nil", tc.wantErr)
			}
			if !strings.Contains(err.Error(), tc.wantErr) {
				t.Fatalf("error %q does not contain %q", err.Error(), tc.wantErr)
			}
		})
	}
}

func TestLoadReportsAllErrors(t *testing.T) {
	t.Parallel()
	_, err := Load(env(map[string]string{"MAX_TABLES": "0", "LOG_FORMAT": "xml"}))
	if err == nil {
		t.Fatal("expected error")
	}
	for _, want := range []string{"MAX_TABLES", "LOG_FORMAT"} {
		if !strings.Contains(err.Error(), want) {
			t.Errorf("error %q missing %q", err.Error(), want)
		}
	}
}

func merge(base map[string]string, k, v string) map[string]string {
	out := make(map[string]string, len(base)+1)
	for kk, vv := range base {
		out[kk] = vv
	}
	out[k] = v
	return out
}

func TestVoiceStunURLs(t *testing.T) {
	t.Parallel()
	cfg, err := Load(env(map[string]string{"VOICE_STUN_URLS": " stun:stun.example.org:3478 , stuns:b.example.org "}))
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.VoiceStunURLs) != 2 || cfg.VoiceStunURLs[0] != "stun:stun.example.org:3478" || cfg.VoiceStunURLs[1] != "stuns:b.example.org" {
		t.Fatalf("urls = %v", cfg.VoiceStunURLs)
	}
	if _, err := Load(env(map[string]string{"VOICE_STUN_URLS": "https://not-stun"})); err == nil {
		t.Fatal("non-stun url must be rejected")
	}
	if cfg, _ := Load(env(map[string]string{})); len(cfg.VoiceStunURLs) != 0 {
		t.Fatal("default is no STUN")
	}
}
