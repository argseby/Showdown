// Command server is the Showdown API. It only wires packages together.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"showdown/internal/config"
	"showdown/internal/server"
	"showdown/internal/store"
	"showdown/internal/table"
)

const shutdownTimeout = 10 * time.Second

func main() {
	healthcheck := flag.Bool("healthcheck", false, "probe the running server's /readyz and exit (used by the container healthcheck)")
	backup := flag.String("backup", "", "write a consistent copy of the database to this file and exit (safe while the server runs)")
	flag.Parse()

	if *healthcheck {
		if err := runHealthcheck(os.Getenv("LISTEN_ADDR")); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		return
	}
	if *backup != "" {
		if err := runBackup(*backup); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		return
	}

	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "fatal:", err)
		os.Exit(1)
	}
}

// runBackup copies the live database with SQLite's VACUUM INTO, which yields
// a consistent single-file snapshot even while the server is writing.
func runBackup(path string) error {
	cfg, err := config.Load(os.Getenv)
	if err != nil {
		return err
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	st, err := store.Open(ctx, cfg.DataDir, slog.New(slog.DiscardHandler))
	if err != nil {
		return err
	}
	defer st.Close()
	if err := st.BackupTo(ctx, path); err != nil {
		return err
	}
	fmt.Fprintln(os.Stdout, "backup written to", path)
	return nil
}

func run() error {
	cfg, err := config.Load(os.Getenv)
	if err != nil {
		return err
	}
	log := newLogger(cfg)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	st, err := store.Open(ctx, cfg.DataDir, log)
	if err != nil {
		return err
	}
	defer func() {
		if err := st.Close(); err != nil {
			log.Error("close store", "err", err)
		}
	}()

	registry := table.NewRegistry(table.Deps{Store: st, Log: log}, cfg.MaxTables)
	if err := registry.LoadAll(ctx); err != nil {
		return fmt.Errorf("restore tables: %w", err)
	}

	// Retention: ended tables lose hands and chat after TABLE_RETENTION_DAYS;
	// player results are kept for the global leaderboard.
	go st.RunRetention(ctx, cfg.TableRetentionDays, 24*time.Hour, log)

	srv := server.New(cfg, st, registry, log)
	httpSrv := &http.Server{
		Addr:              cfg.ListenAddr,
		Handler:           srv.Handler(),
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
		ErrorLog:          slog.NewLogLogger(log.Handler(), slog.LevelWarn),
	}

	errCh := make(chan error, 1)
	go func() {
		log.Info("listening", "addr", cfg.ListenAddr, "data_dir", cfg.DataDir)
		if err := httpSrv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			errCh <- err
		}
		close(errCh)
	}()

	select {
	case err := <-errCh:
		if err != nil {
			return fmt.Errorf("listen on %s: %w", cfg.ListenAddr, err)
		}
	case <-ctx.Done():
		log.Info("shutdown signal received")
	}

	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()
	// Stop accepting, tell every connection, drain persistence.
	if err := httpSrv.Shutdown(shutdownCtx); err != nil {
		log.Warn("http shutdown", "err", err)
	}
	registry.Shutdown(shutdownCtx)
	log.Info("stopped")
	return nil
}

func newLogger(cfg config.Config) *slog.Logger {
	opts := &slog.HandlerOptions{Level: cfg.SlogLevel()}
	var h slog.Handler
	if cfg.LogFormat == "text" {
		h = slog.NewTextHandler(os.Stdout, opts)
	} else {
		h = slog.NewJSONHandler(os.Stdout, opts)
	}
	return slog.New(h)
}

// runHealthcheck GETs /readyz on the local server. It exists because the
// distroless runtime image has no shell or curl.
func runHealthcheck(listenAddr string) error {
	if listenAddr == "" {
		listenAddr = ":8080"
	}
	host, port, err := net.SplitHostPort(listenAddr)
	if err != nil {
		return fmt.Errorf("parse LISTEN_ADDR %q: %w", listenAddr, err)
	}
	if host == "" || host == "0.0.0.0" || host == "::" {
		host = "127.0.0.1"
	}
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://" + net.JoinHostPort(host, port) + "/readyz")
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("readyz returned %d", resp.StatusCode)
	}
	return nil
}
