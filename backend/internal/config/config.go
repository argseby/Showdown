// Package config loads and validates the server configuration from
// environment variables. Configuration comes exclusively from the environment;
// any invalid value fails startup.
package config

import (
	"errors"
	"fmt"
	"log/slog"
	"net/url"
	"strconv"
	"strings"
)

// Config is the fully validated server configuration.
type Config struct {
	ListenAddr          string
	DataDir             string
	TableRetentionDays  int
	MaxTables           int
	MaxConnectionsPerIP int
	TrustProxy          bool
	DevCORSOrigin       string
	LogLevel            string
	LogFormat           string
	// VoiceStunURLs are handed to browsers for the voice chat (WebRTC ICE);
	// empty means no STUN, which works within one network only.
	VoiceStunURLs []string
}

// Load reads the configuration through getenv (usually os.Getenv), applies
// defaults and validates every field. All validation problems are reported
// together in the returned error.
func Load(getenv func(string) string) (Config, error) {
	l := loader{getenv: getenv}

	cfg := Config{
		ListenAddr:          l.str("LISTEN_ADDR", ":8080"),
		DataDir:             l.str("DATA_DIR", "/data"),
		TableRetentionDays:  l.integer("TABLE_RETENTION_DAYS", 90),
		MaxTables:           l.integer("MAX_TABLES", 100),
		MaxConnectionsPerIP: l.integer("MAX_CONNECTIONS_PER_IP", 50),
		TrustProxy:          l.boolean("TRUST_PROXY", true),
		DevCORSOrigin:       l.str("DEV_CORS_ORIGIN", ""),
		LogLevel:            strings.ToLower(l.str("LOG_LEVEL", "info")),
		LogFormat:           strings.ToLower(l.str("LOG_FORMAT", "json")),
		VoiceStunURLs:       splitList(l.str("VOICE_STUN_URLS", "")),
	}
	for _, u := range cfg.VoiceStunURLs {
		if !strings.HasPrefix(u, "stun:") && !strings.HasPrefix(u, "stuns:") {
			l.errorf("VOICE_STUN_URLS: %q must start with stun: or stuns:", u)
		}
	}

	if cfg.ListenAddr == "" {
		l.errorf("LISTEN_ADDR must not be empty")
	}
	if cfg.DataDir == "" {
		l.errorf("DATA_DIR must not be empty")
	}
	if cfg.TableRetentionDays < 0 {
		l.errorf("TABLE_RETENTION_DAYS must be >= 0")
	}
	if cfg.MaxTables < 1 {
		l.errorf("MAX_TABLES must be >= 1")
	}
	if cfg.MaxConnectionsPerIP < 1 {
		l.errorf("MAX_CONNECTIONS_PER_IP must be >= 1")
	}
	if cfg.DevCORSOrigin != "" {
		if err := validateOrigin(cfg.DevCORSOrigin); err != nil {
			l.errorf("DEV_CORS_ORIGIN: %v", err)
		}
	}
	switch cfg.LogLevel {
	case "debug", "info", "warn", "error":
	default:
		l.errorf("LOG_LEVEL must be one of debug, info, warn, error")
	}
	switch cfg.LogFormat {
	case "json", "text":
	default:
		l.errorf("LOG_FORMAT must be json or text")
	}

	if len(l.errs) > 0 {
		return Config{}, fmt.Errorf("invalid configuration: %w", errors.Join(l.errs...))
	}
	return cfg, nil
}

// SlogLevel maps LogLevel to a slog.Level.
func (c Config) SlogLevel() slog.Level {
	switch c.LogLevel {
	case "debug":
		return slog.LevelDebug
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

type loader struct {
	getenv func(string) string
	errs   []error
}

func (l *loader) errorf(format string, args ...any) {
	l.errs = append(l.errs, fmt.Errorf(format, args...))
}

func (l *loader) str(key, def string) string {
	v := strings.TrimSpace(l.getenv(key))
	if v == "" {
		return def
	}
	return v
}

func (l *loader) boolean(key string, def bool) bool {
	v := strings.TrimSpace(l.getenv(key))
	if v == "" {
		return def
	}
	b, err := strconv.ParseBool(v)
	if err != nil {
		l.errorf("%s must be a boolean, got %q", key, v)
		return def
	}
	return b
}

func (l *loader) integer(key string, def int) int {
	v := strings.TrimSpace(l.getenv(key))
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		l.errorf("%s must be an integer, got %q", key, v)
		return def
	}
	return n
}

// validateOrigin accepts exactly an origin: scheme://host[:port] with no
// path, query or fragment.
// splitList splits a comma-separated list, trimming blanks.
func splitList(s string) []string {
	var out []string
	for _, part := range strings.Split(s, ",") {
		if p := strings.TrimSpace(part); p != "" {
			out = append(out, p)
		}
	}
	return out
}

func validateOrigin(s string) error {
	u, err := url.Parse(s)
	if err != nil {
		return err
	}
	if u.Scheme != "http" && u.Scheme != "https" {
		return errors.New("scheme must be http or https")
	}
	if u.Host == "" {
		return errors.New("host is required")
	}
	if u.Path != "" || u.RawQuery != "" || u.Fragment != "" || u.User != nil {
		return errors.New("must be an origin only (scheme://host[:port])")
	}
	return nil
}
