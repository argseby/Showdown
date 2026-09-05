package server

import (
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

// bucket is a token bucket.
type bucket struct {
	tokens float64
	last   time.Time
}

// limiter keys token buckets by string (usually a client IP).
type limiter struct {
	mu     sync.Mutex
	rate   float64 // tokens per second
	burst  float64
	bucket map[string]*bucket
}

func newLimiter(perMinute float64, burst int) *limiter {
	return &limiter{rate: perMinute / 60, burst: float64(burst), bucket: map[string]*bucket{}}
}

// allow consumes one token for key if available.
func (l *limiter) allow(key string, now time.Time) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	b, ok := l.bucket[key]
	if !ok {
		if len(l.bucket) > 10000 {
			l.sweep(now)
		}
		b = &bucket{tokens: l.burst, last: now}
		l.bucket[key] = b
	}
	b.tokens = min(l.burst, b.tokens+now.Sub(b.last).Seconds()*l.rate)
	b.last = now
	if b.tokens < 1 {
		return false
	}
	b.tokens--
	return true
}

func (l *limiter) sweep(now time.Time) {
	for k, b := range l.bucket {
		if now.Sub(b.last) > 10*time.Minute {
			delete(l.bucket, k)
		}
	}
}

// rateBucket is a single token bucket for one connection.
type rateBucket struct {
	rate   float64
	burst  float64
	tokens float64
	last   time.Time
}

func newRateBucket(perSecond float64, burst int, now time.Time) *rateBucket {
	return &rateBucket{rate: perSecond, burst: float64(burst), tokens: float64(burst), last: now}
}

func (b *rateBucket) allow(now time.Time) bool {
	b.tokens = min(b.burst, b.tokens+now.Sub(b.last).Seconds()*b.rate)
	b.last = now
	if b.tokens < 1 {
		return false
	}
	b.tokens--
	return true
}

// clientIP returns the caller's address, honouring X-Forwarded-For when the
// proxy is trusted.
func (s *Server) clientIP(r *http.Request) string {
	if s.cfg.TrustProxy {
		if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
			if first, _, ok := strings.Cut(xff, ","); ok {
				return strings.TrimSpace(first)
			}
			return strings.TrimSpace(xff)
		}
	}
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

// rateLimited wraps a handler with a per-IP limiter.
func (s *Server) rateLimited(l *limiter, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !l.allow(s.clientIP(r), s.now()) {
			writeError(w, http.StatusTooManyRequests, "rate_limited", "too many requests")
			return
		}
		next(w, r)
	}
}
