package server

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"sort"
	"sync"
	"testing"
	"time"

	"showdown/internal/botclient"
)

// TestBotMatch sits the solid strategy down with the scripted ones and counts
// the chips afterwards. It plays real hands over the real protocol, so it
// takes about ten minutes and runs only when asked for:
//
//	SHOWDOWN_BOT_MATCH=1 go test ./internal/server -run TestBotMatch -v -timeout 30m
//
// Several tables run at once because the server floors the pause between
// hands at two seconds, and one table alone would not gather a useful sample.
func TestBotMatch(t *testing.T) {
	if os.Getenv("SHOWDOWN_BOT_MATCH") == "" {
		t.Skip("set SHOWDOWN_BOT_MATCH=1 to play the match (about ten minutes)")
	}
	const (
		tables = 4
		hands  = 250
	)
	// Each bot presents its own address: the per-IP join limit is far below
	// two dozen clients from one machine.
	h := newHarness(t, t.TempDir(), "", map[string]string{"TRUST_PROXY": "true"})
	defer h.stop()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	var mu sync.Mutex
	byStrategy := map[botclient.Strategy]int64{}
	seats := map[botclient.Strategy]int{}
	played := 0
	var rows []string

	var wg sync.WaitGroup
	for tbl := range tables {
		wg.Add(1)
		go func() {
			defer wg.Done()
			settings := map[string]any{
				"turn_time": 5, "disconnected_turn_time": 3, "hand_delay_ms": 2000, "start_money": 20000,
				"time_bank_seconds": 0, "small_blind": 50, "big_blind": 100,
				"sit_out_after_missed_turns": 10, "max_players": 6, "allow_rebuy": true,
			}
			tableID, token := h.createTable(settings)
			var bs botSet
			kinds := []botclient.Strategy{
				botclient.StrategySolid, botclient.StrategyRandom,
				botclient.StrategySolid, botclient.StrategyAggressive,
				botclient.StrategySolid, botclient.StrategyPassive,
			}
			names := map[string]botclient.Strategy{}
			for i := range kinds {
				// Rotate the seating per table so position evens out.
				st := kinds[(i+tbl)%len(kinds)]
				name := fmt.Sprintf("t%d-%s%d", tbl, st, i+1)
				n := tbl*len(kinds) + i
				b := botclient.New(botclient.Config{
					BaseURL: h.base, TableID: tableID, Name: name, Strategy: st,
					Seed:   uint64(tbl*7919 + i*977 + 13),
					Header: http.Header{"X-Forwarded-For": {fmt.Sprintf("10.9.%d.%d", (n>>8)&255, n&255)}},
				})
				if err := b.Join(ctx); err != nil {
					t.Error(err)
					return
				}
				names[name] = st
				bs.players = append(bs.players, b)
			}
			admin := botclient.New(botclient.Config{BaseURL: h.base, TableID: tableID, Name: "admin", Role: botclient.RoleAdmin, Token: token})
			bs.others = []*botclient.Bot{admin}
			bs.start(ctx)

			deadline := time.Now().Add(25 * time.Minute)
			for admin.HandsEnded() < hands && time.Now().Before(deadline) && ctx.Err() == nil {
				time.Sleep(200 * time.Millisecond)
			}
			n := admin.HandsEnded()
			for _, b := range bs.all() {
				b.Disconnect()
			}

			status, out := h.request(http.MethodGet, "/api/admin/tables/"+tableID, token, nil)
			if status != http.StatusOK {
				t.Errorf("admin: %d", status)
				return
			}
			mu.Lock()
			defer mu.Unlock()
			played += n
			for _, p := range out["players"].([]any) {
				pm := p.(map[string]any)
				name := pm["name"].(string)
				net := int64(pm["stack"].(float64)) - int64(pm["buy_in_total"].(float64))
				byStrategy[names[name]] += net
				seats[names[name]]++
				rows = append(rows, fmt.Sprintf("  %-22s %+10d", name, net))
			}
		}()
	}
	wg.Wait()
	cancel()

	sort.Strings(rows)
	t.Logf("%d hands over %d tables:", played, tables)
	for _, r := range rows {
		t.Log(r)
	}
	for _, st := range []botclient.Strategy{botclient.StrategySolid, botclient.StrategyRandom, botclient.StrategyAggressive, botclient.StrategyPassive} {
		t.Logf("== %-11s %+11d over %d seats", st, byStrategy[st], seats[st])
	}
	// The scripted strategies fold at random, shove at random or never fold
	// at all; anything that reads its cards should take money off all three.
	if byStrategy[botclient.StrategySolid] <= 0 {
		t.Errorf("solid ended %+d over %d hands, want a profit", byStrategy[botclient.StrategySolid], played)
	}
	for _, st := range []botclient.Strategy{botclient.StrategyRandom, botclient.StrategyAggressive, botclient.StrategyPassive} {
		if byStrategy[st] >= 0 {
			t.Errorf("%s ended %+d, want a loss", st, byStrategy[st])
		}
	}
}
