package main

import "fmt"

// checkID identifies one invariant. Every check is counted so the report can
// state how often it held, and every failure is recorded with the table and
// hand it happened in.
type checkID int

// The invariants this command verifies. The descriptions are what the report
// prints, so they are written for a reader who has not seen the code.
const (
	chkChips checkID = iota
	chkBankroll
	chkEvents
	chkDeck
	chkPositions
	chkTurnOrder
	chkOptions
	chkRejects
	chkPots
	chkAwards
	chkResults
	numChecks
)

var checkInfo = [numChecks]struct{ Name, Desc string }{
	chkChips:     {"chip_conservation", "stacks + pots + bets stay constant through every event of a hand (rules.md 7.9)"},
	chkBankroll:  {"table_bankroll", "between hands the chips on the table equal buy-ins + adjustments - cash-outs"},
	chkEvents:    {"event_stream", "sequence numbers increase, the log opens with hand_started and closes with hand_ended"},
	chkDeck:      {"deck_integrity", "no card is dealt twice in a hand, holes and board come from one 52-card deck (7.3)"},
	chkPositions: {"button_and_blinds", "small and big blind sit clockwise from the button, heads-up the button is the small blind (7.2)"},
	chkTurnOrder: {"turn_order", "the first actor of every street is correct and no other seat can act (7.4)"},
	chkOptions:   {"legal_options", "the offered fold/check/call/raise/all-in set matches the betting rules re-derived independently (7.5)"},
	chkRejects:   {"illegal_actions_rejected", "checks facing a bet, undersized raises and raises over the stack are refused and move no chips (7.5)"},
	chkPots:      {"pot_construction", "main and side pots recomputed from the contributions match the engine, folded chips count but never win (7.6)"},
	chkAwards:    {"showdown_awards", "every pot goes to the best eligible hand, splits are equal and odd chips go clockwise from the button (7.8)"},
	chkResults:   {"hand_results", "the result of a hand adds up: net per seat sums to zero and equals end stack minus start stack"},
}

// violation is one broken invariant, kept for the report.
type violation struct {
	Check  string `json:"check"`
	Table  int    `json:"table"`
	Hand   int    `json:"hand"`
	Detail string `json:"detail"`
}

// findings accumulates one worker's counts; workers merge into one at the end
// so the simulation itself needs no synchronisation.
type findings struct {
	passed  [numChecks]int64
	failed  [numChecks]int64
	list    []violation
	maxList int

	// Play statistics for the report.
	tables, hands, actions, timeouts int64
	showdowns, runouts, runTwice     int64
	allIns, sidePots, headsUp        int64
	wagered, biggestPot              int64
	rebuys, joins, leaves            int64
	boughtIn, adjusted, cashedOut    int64
	finalStacks                      int64
	streets                          [4]int64
	categories                       [9]int64
}

func newFindings(maxList int) *findings { return &findings{maxList: maxList} }

func (f *findings) ok(c checkID) { f.passed[c]++ }

func (f *findings) fail(c checkID, table, hand int, format string, args ...any) {
	f.failed[c]++
	if len(f.list) < f.maxList {
		f.list = append(f.list, violation{Check: checkInfo[c].Name, Table: table, Hand: hand, Detail: fmt.Sprintf(format, args...)})
	}
}

func (f *findings) merge(o *findings) {
	for i := range f.passed {
		f.passed[i] += o.passed[i]
		f.failed[i] += o.failed[i]
	}
	for _, v := range o.list {
		if len(f.list) < f.maxList {
			f.list = append(f.list, v)
		}
	}
	f.tables += o.tables
	f.hands += o.hands
	f.actions += o.actions
	f.timeouts += o.timeouts
	f.showdowns += o.showdowns
	f.runouts += o.runouts
	f.runTwice += o.runTwice
	f.allIns += o.allIns
	f.sidePots += o.sidePots
	f.headsUp += o.headsUp
	f.wagered += o.wagered
	f.rebuys += o.rebuys
	f.joins += o.joins
	f.leaves += o.leaves
	f.boughtIn += o.boughtIn
	f.adjusted += o.adjusted
	f.cashedOut += o.cashedOut
	f.finalStacks += o.finalStacks
	if o.biggestPot > f.biggestPot {
		f.biggestPot = o.biggestPot
	}
	for i := range f.streets {
		f.streets[i] += o.streets[i]
	}
	for i := range f.categories {
		f.categories[i] += o.categories[i]
	}
}

// totals returns the number of checks performed and the number that failed.
func (f *findings) totals() (passed, failed int64) {
	for i := range f.passed {
		passed += f.passed[i]
		failed += f.failed[i]
	}
	return passed, failed
}
