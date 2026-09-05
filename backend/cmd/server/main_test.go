package main

import (
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestRunHealthcheck(t *testing.T) {
	ready := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/readyz" {
			w.WriteHeader(http.StatusOK)
			return
		}
		w.WriteHeader(http.StatusNotFound)
	}))
	defer ready.Close()
	_, port, _ := net.SplitHostPort(ready.Listener.Addr().String())

	if err := runHealthcheck(":" + port); err != nil {
		t.Fatalf("expected healthy, got %v", err)
	}

	down := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusServiceUnavailable)
	}))
	defer down.Close()
	_, port, _ = net.SplitHostPort(down.Listener.Addr().String())
	if err := runHealthcheck("127.0.0.1:" + port); err == nil {
		t.Fatal("expected error for 503")
	}

	if err := runHealthcheck("not-an-addr"); err == nil {
		t.Fatal("expected parse error")
	}
}
