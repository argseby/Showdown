package revokedauth

import (
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"strings"
	"sync"
	"time"
)

// Claims are the parts of an ID token this server acts on. Everything else
// the token carries is ignored: a profile is made from the subject, and the
// name is only a suggestion the player may overwrite.
type Claims struct {
	Issuer   string `json:"iss"`
	Subject  string `json:"sub"`
	Audience audience
	Expiry   int64  `json:"exp"`
	IssuedAt int64  `json:"iat"`
	Nonce    string `json:"nonce"`

	Name          string `json:"name"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	// RevokedIdentity is the fingerprint of the person's primary identity,
	// the same across services. Stored by nobody here; it exists so a
	// later feature can recognise one person across two revoked servers.
	RevokedIdentity string `json:"revoked_identity"`
}

// audience accepts both shapes RFC 7519 allows: one string or a list.
type audience []string

func (a *audience) UnmarshalJSON(b []byte) error {
	var one string
	if err := json.Unmarshal(b, &one); err == nil {
		*a = audience{one}
		return nil
	}
	var many []string
	if err := json.Unmarshal(b, &many); err != nil {
		return errors.New("aud must be a string or a list of strings")
	}
	*a = many
	return nil
}

func (a audience) has(want string) bool {
	for _, s := range a {
		if s == want {
			return true
		}
	}
	return false
}

// claimsWire exists because Claims carries a custom audience type; decoding
// straight into Claims would need the tag on an unexported field.
type claimsWire struct {
	Claims
	Aud audience `json:"aud"`
}

// jwk is one key of a JWKS. Only RSA signing keys are understood: the
// revoked spec signs ID tokens with RS256 and nothing else.
type jwk struct {
	Kty string `json:"kty"`
	Alg string `json:"alg"`
	Use string `json:"use"`
	Kid string `json:"kid"`
	N   string `json:"n"`
	E   string `json:"e"`
}

func (k jwk) publicKey() (*rsa.PublicKey, error) {
	if k.Kty != "RSA" {
		return nil, fmt.Errorf("key %q: kty %q is not RSA", k.Kid, k.Kty)
	}
	n, err := base64.RawURLEncoding.DecodeString(k.N)
	if err != nil {
		return nil, fmt.Errorf("key %q: modulus: %w", k.Kid, err)
	}
	e, err := base64.RawURLEncoding.DecodeString(k.E)
	if err != nil {
		return nil, fmt.Errorf("key %q: exponent: %w", k.Kid, err)
	}
	if len(e) == 0 || len(e) > 8 {
		return nil, fmt.Errorf("key %q: exponent out of range", k.Kid)
	}
	// The exponent is a big-endian number of any length; widen it to the
	// eight bytes binary.BigEndian wants.
	var buf [8]byte
	copy(buf[8-len(e):], e)
	exp := binary.BigEndian.Uint64(buf[:])
	if exp == 0 || exp > 1<<31-1 {
		return nil, fmt.Errorf("key %q: exponent out of range", k.Kid)
	}
	key := &rsa.PublicKey{N: new(big.Int).SetBytes(n), E: int(exp)}
	// 2048 bits is the floor RFC 7518 sets for RS256.
	if key.N.BitLen() < 2048 {
		return nil, fmt.Errorf("key %q: modulus is only %d bits", k.Kid, key.N.BitLen())
	}
	return key, nil
}

// keySet caches one server's signing keys. A kid that is not in the cache
// refetches once, which is how a rotated key is picked up; a fetch is at
// most once a minute so an unknown kid cannot be used to hammer the server.
type keySet struct {
	mu       sync.Mutex
	keys     map[string]*rsa.PublicKey
	fetched  time.Time
	refetch  time.Duration
	jwksURI  string
	download func(ctx context.Context, uri string) ([]jwk, error)
}

func (s *keySet) key(ctx context.Context, kid string) (*rsa.PublicKey, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if k, ok := s.keys[kid]; ok {
		return k, nil
	}
	if time.Since(s.fetched) < s.refetch {
		return nil, fmt.Errorf("no signing key %q", kid)
	}
	ks, err := s.download(ctx, s.jwksURI)
	if err != nil {
		return nil, err
	}
	s.fetched = time.Now()
	s.keys = map[string]*rsa.PublicKey{}
	for _, k := range ks {
		if k.Kty != "RSA" || (k.Use != "" && k.Use != "sig") || (k.Alg != "" && k.Alg != "RS256") {
			continue
		}
		pub, err := k.publicKey()
		if err != nil {
			// One unusable key must not hide the others.
			continue
		}
		s.keys[k.Kid] = pub
	}
	if k, ok := s.keys[kid]; ok {
		return k, nil
	}
	return nil, fmt.Errorf("no signing key %q", kid)
}

// verifyIDToken checks the signature and every claim this server relies on,
// and returns what the token says. The caller has already established that
// md came from the issuer it names.
func verifyIDToken(ctx context.Context, ks *keySet, raw, issuer, clientID, nonce string, now time.Time) (Claims, error) {
	parts := strings.Split(raw, ".")
	if len(parts) != 3 {
		return Claims{}, errors.New("id_token is not a JWS")
	}
	headerRaw, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return Claims{}, fmt.Errorf("id_token header: %w", err)
	}
	var header struct {
		Alg string `json:"alg"`
		Kid string `json:"kid"`
		Typ string `json:"typ"`
	}
	if err := json.Unmarshal(headerRaw, &header); err != nil {
		return Claims{}, fmt.Errorf("id_token header: %w", err)
	}
	// Pinned, not negotiated: "none" and the HMAC algorithms are the
	// classic way to forge a token, and revoked signs with RS256 only.
	if header.Alg != "RS256" {
		return Claims{}, fmt.Errorf("id_token alg %q is not RS256", header.Alg)
	}

	key, err := ks.key(ctx, header.Kid)
	if err != nil {
		return Claims{}, err
	}
	sig, err := base64.RawURLEncoding.DecodeString(parts[2])
	if err != nil {
		return Claims{}, fmt.Errorf("id_token signature: %w", err)
	}
	signed := sha256.Sum256([]byte(parts[0] + "." + parts[1]))
	if err := rsa.VerifyPKCS1v15(key, crypto.SHA256, signed[:], sig); err != nil {
		return Claims{}, errors.New("id_token signature does not verify")
	}

	payload, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return Claims{}, fmt.Errorf("id_token payload: %w", err)
	}
	var wire claimsWire
	if err := json.Unmarshal(payload, &wire); err != nil {
		return Claims{}, fmt.Errorf("id_token payload: %w", err)
	}
	c := wire.Claims
	c.Audience = wire.Aud

	switch {
	case c.Issuer != issuer:
		return Claims{}, fmt.Errorf("id_token issued by %q, not %q", c.Issuer, issuer)
	case c.Subject == "":
		return Claims{}, errors.New("id_token has no subject")
	case !c.Audience.has(clientID):
		return Claims{}, errors.New("id_token is for another service")
	case nonce != "" && c.Nonce != nonce:
		return Claims{}, errors.New("id_token nonce does not match")
	}
	// A token good for ten minutes needs no generous skew; a minute keeps
	// a slightly wrong clock on either side from locking anyone out.
	const skew = time.Minute
	if c.Expiry == 0 || now.After(time.Unix(c.Expiry, 0).Add(skew)) {
		return Claims{}, errors.New("id_token has expired")
	}
	if c.IssuedAt != 0 && now.Add(skew).Before(time.Unix(c.IssuedAt, 0)) {
		return Claims{}, errors.New("id_token was issued in the future")
	}
	return c, nil
}
