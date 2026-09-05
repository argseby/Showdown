package table

import (
	"crypto/rand"
	"math/big"
)

// TableIDAlphabet avoids look-alike characters (docs §5.1).
const TableIDAlphabet = "abcdefghjkmnpqrstuvwxyz23456789"

// TableIDLength is the fixed length of table ids.
const TableIDLength = 10

// NewTableID returns a random 10-character table id.
func NewTableID() string { return randomString(TableIDAlphabet, TableIDLength) }

func newPlayerID() string { return "p" + randomString(TableIDAlphabet, 12) }

func randomString(alphabet string, n int) string {
	out := make([]byte, n)
	max := big.NewInt(int64(len(alphabet)))
	for i := range out {
		v, err := rand.Int(rand.Reader, max)
		if err != nil {
			panic("crypto/rand unavailable: " + err.Error())
		}
		out[i] = alphabet[v.Int64()]
	}
	return string(out)
}
