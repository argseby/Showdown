// Command simulate plays a large number of complete poker tables through the
// engine and verifies, after every single event, that the rules of
// docs/rules.md hold and that not a single chip is created or destroyed:
//
//	go run ./cmd/simulate                          # the default run
//	go run ./cmd/simulate -tables 50000 -hands 200 # a long one
//	go run ./cmd/simulate -json report.json        # machine readable
//
// The report has three parts: an exhaustive audit of the hand ranking, a
// fairness test of the production shuffle, and the play simulation with its
// invariant checks. The exit status is non-zero when anything failed, so the
// command can be used as a gate.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"math/rand/v2"
	"os"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"text/tabwriter"
	"time"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "simulate:", err)
		os.Exit(1)
	}
}

type options struct {
	tables    int
	hands     int
	workers   int
	seed      uint64
	deals     int64
	evaluator bool
	jsonPath  string
	maxViol   int
	quiet     bool
}

// report is the whole result of a run, also the shape of -json.
type report struct {
	Seed      uint64          `json:"seed"`
	Workers   int             `json:"workers"`
	Go        string          `json:"go"`
	Seconds   float64         `json:"seconds"`
	Evaluator *evaluatorAudit `json:"evaluator,omitempty"`
	Shuffle   *shuffleAudit   `json:"shuffle,omitempty"`
	Play      playReport      `json:"play"`
	OK        bool            `json:"ok"`
}

type playReport struct {
	Tables      int64        `json:"tables"`
	Hands       int64        `json:"hands"`
	Actions     int64        `json:"actions"`
	Checks      int64        `json:"checks"`
	Violations  int64        `json:"violations"`
	PerCheck    []checkCount `json:"per_check"`
	Examples    []violation  `json:"examples,omitempty"`
	BoughtIn    int64        `json:"chips_bought_in"`
	Adjusted    int64        `json:"chips_adjusted"`
	CashedOut   int64        `json:"chips_cashed_out"`
	FinalStacks int64        `json:"chips_in_stacks"`
	Wagered     int64        `json:"chips_wagered"`
	BiggestPot  int64        `json:"biggest_pot"`
	Showdowns   int64        `json:"showdowns"`
	SidePots    int64        `json:"side_pots"`
	AllIns      int64        `json:"all_ins"`
	Timeouts    int64        `json:"timeouts"`
	RunTwice    int64        `json:"run_twice"`
	Rebuys      int64        `json:"rebuys"`
	Joins       int64        `json:"joins"`
	Leaves      int64        `json:"leaves"`
	Categories  [9]int64     `json:"showdown_categories"`
}

type checkCount struct {
	Name   string `json:"name"`
	Desc   string `json:"description"`
	Passed int64  `json:"passed"`
	Failed int64  `json:"failed"`
}

func run() error {
	var o options
	flag.IntVar(&o.tables, "tables", 2000, "number of tables to play")
	flag.IntVar(&o.hands, "hands", 50, "hands per table")
	flag.IntVar(&o.workers, "workers", runtime.GOMAXPROCS(0), "parallel workers")
	flag.Uint64Var(&o.seed, "seed", 20260906, "random seed; 0 picks one from the clock")
	flag.Int64Var(&o.deals, "deals", 250_000, "deals for the shuffle fairness test (0 skips it)")
	flag.BoolVar(&o.evaluator, "eval", true, "run the exhaustive five-card evaluator audit")
	flag.StringVar(&o.jsonPath, "json", "", "also write the report as JSON to this file")
	flag.IntVar(&o.maxViol, "max-violations", 20, "how many violations to list")
	flag.BoolVar(&o.quiet, "q", false, "no progress output")
	flag.Parse()
	if o.tables < 1 || o.hands < 1 {
		return fmt.Errorf("-tables and -hands must be positive")
	}
	if o.workers < 1 {
		o.workers = 1
	}
	if o.seed == 0 {
		o.seed = uint64(time.Now().UnixNano())
	}

	rep := report{Seed: o.seed, Workers: o.workers, Go: runtime.Version(), OK: true}
	started := time.Now()

	if o.evaluator {
		o.progress("classifying all 2,598,960 five-card hands")
		a := auditEvaluator()
		rep.Evaluator = &a
		rep.OK = rep.OK && a.OK
	}
	if o.deals > 0 {
		o.progress("dealing %s hands with the production shuffle", comma(o.deals))
		a := auditShuffle(o.deals)
		rep.Shuffle = &a
		rep.OK = rep.OK && a.OK
	}

	f := o.play()
	rep.Play = buildPlayReport(f)
	rep.OK = rep.OK && rep.Play.Violations == 0
	rep.Seconds = time.Since(started).Seconds()

	o.clearProgress()
	printReport(os.Stdout, rep, o)
	if o.jsonPath != "" {
		buf, err := json.MarshalIndent(rep, "", "  ")
		if err != nil {
			return err
		}
		if err := os.WriteFile(o.jsonPath, append(buf, '\n'), 0o644); err != nil {
			return err
		}
	}
	if !rep.OK {
		return fmt.Errorf("verification failed")
	}
	return nil
}

// play runs the table simulations across workers and merges their findings.
func (o options) play() *findings {
	var done atomic.Int64
	stop := make(chan struct{})
	if !o.quiet {
		go func() {
			t := time.NewTicker(200 * time.Millisecond)
			defer t.Stop()
			for {
				select {
				case <-stop:
					return
				case <-t.C:
					o.progress("playing tables: %s / %s", comma(done.Load()), comma(int64(o.tables)))
				}
			}
		}()
	}

	next := make(chan int, o.workers)
	go func() {
		for i := 0; i < o.tables; i++ {
			next <- i
		}
		close(next)
	}()
	parts := make([]*findings, o.workers)
	var wg sync.WaitGroup
	for w := 0; w < o.workers; w++ {
		wg.Add(1)
		go func(w int) {
			defer wg.Done()
			f := newFindings(o.maxViol)
			for i := range next {
				// Seeded per table, so any violation is reproducible with
				// the same -seed and table index.
				playTable(i, rand.New(rand.NewPCG(o.seed, uint64(i))), f, o.hands)
				done.Add(1)
			}
			parts[w] = f
		}(w)
	}
	wg.Wait()
	close(stop)

	all := newFindings(o.maxViol)
	for _, p := range parts {
		if p != nil {
			all.merge(p)
		}
	}
	return all
}

// playTable runs one table and turns a panic in the engine into a violation,
// so one broken hand does not take the whole report down with it.
func playTable(idx int, rng *rand.Rand, f *findings, hands int) {
	t := newTableSim(idx, rng, f)
	defer func() {
		if r := recover(); r != nil {
			f.fail(chkEvents, idx, t.handNo, "the engine panicked: %v", r)
		}
	}()
	t.run(hands)
}

func buildPlayReport(f *findings) playReport {
	passed, failed := f.totals()
	p := playReport{
		Tables: f.tables, Hands: f.hands, Actions: f.actions,
		Checks: passed + failed, Violations: failed, Examples: f.list,
		BoughtIn: f.boughtIn, Adjusted: f.adjusted, CashedOut: f.cashedOut,
		FinalStacks: f.finalStacks, Wagered: f.wagered, BiggestPot: f.biggestPot,
		Showdowns: f.showdowns, SidePots: f.sidePots, AllIns: f.allIns,
		Timeouts: f.timeouts, RunTwice: f.runTwice, Rebuys: f.rebuys,
		Joins: f.joins, Leaves: f.leaves, Categories: f.categories,
	}
	for i := checkID(0); i < numChecks; i++ {
		p.PerCheck = append(p.PerCheck, checkCount{
			Name: checkInfo[i].Name, Desc: checkInfo[i].Desc,
			Passed: f.passed[i], Failed: f.failed[i],
		})
	}
	return p
}

// ---- output -----------------------------------------------------------------

func (o options) progress(format string, args ...any) {
	if o.quiet {
		return
	}
	fmt.Fprintf(os.Stderr, "\r\033[K%s", fmt.Sprintf(format, args...))
}

func (o options) clearProgress() {
	if !o.quiet {
		fmt.Fprint(os.Stderr, "\r\033[K")
	}
}

func printReport(w *os.File, r report, o options) {
	out := &strings.Builder{}
	rule := strings.Repeat("─", 74)
	fmt.Fprintf(out, "Showdown — rules and chip verification\n%s\n", rule)
	fmt.Fprintf(out, "seed %d · %d workers · %s · %.1fs\n", r.Seed, r.Workers, r.Go, r.Seconds)

	if a := r.Evaluator; a != nil {
		fmt.Fprintf(out, "\n1  HAND RANKING — every five-card hand there is\n")
		fmt.Fprintf(out, "   All %s distinct five-card hands were classified and counted.\n", comma(a.Hands))
		tw := tabwriter.NewWriter(out, 0, 0, 2, ' ', 0)
		fmt.Fprintf(tw, "\n   \tcategory\tcounted\texpected\t\n")
		for i := 8; i >= 0; i-- {
			mark := "ok"
			if a.Counts[i] != a.Expected[i] {
				mark = "MISMATCH"
			}
			fmt.Fprintf(tw, "   \t%s\t%s\t%s\t%s\n", categoryNames[i], comma(a.Counts[i]), comma(a.Expected[i]), mark)
		}
		tw.Flush()
		fmt.Fprintf(out, "   %s\n", verdict(a.OK, "the hand ranking matches the textbook frequencies exactly",
			"the hand ranking does NOT match the textbook frequencies"))
	}

	if a := r.Shuffle; a != nil {
		fmt.Fprintf(out, "\n2  SHUFFLE — the same crypto/rand deal the server uses\n")
		fmt.Fprintf(out, "   %s hands were dealt and compared with the theoretical distribution.\n", comma(a.Deals))
		tw := tabwriter.NewWriter(out, 0, 0, 2, ' ', 0)
		fmt.Fprintf(tw, "\n   \tcategory\tdealt\texpected\tdeviation\t\n")
		for i := 8; i >= 0; i-- {
			dev := "—"
			if a.Expected[i] > 0 {
				dev = fmt.Sprintf("%+.2f%%", (float64(a.Counts[i])-a.Expected[i])/a.Expected[i]*100)
			}
			fmt.Fprintf(tw, "   \t%s\t%s\t%s\t%s\n", categoryNames[i], comma(a.Counts[i]), comma(int64(math.Round(a.Expected[i]))), dev)
		}
		tw.Flush()
		fmt.Fprintf(out, "\n   hand categories   chi-square %8.2f (8 df)   p = %.3f\n", a.CategoryX2, a.CategoryP)
		fmt.Fprintf(out, "   card positions    chi-square %8.2f (51 df)  p = %.3f\n", a.PositionX2, a.PositionP)
		fmt.Fprintf(out, "   %s\n", verdict(a.OK, "the deal is indistinguishable from a uniform shuffle (p > 0.001)",
			"the deal deviates from a uniform shuffle (p <= 0.001)"))
	}

	p := r.Play
	fmt.Fprintf(out, "\n3  PLAY — %s tables, %s hands, %s actions\n", comma(p.Tables), comma(p.Hands), comma(p.Actions))
	fmt.Fprintf(out, "   Random legal play with all-ins, side pots, time-outs, re-buys, joins,\n")
	fmt.Fprintf(out, "   leaves, straddles, dead blinds, run-it-twice and a moving button.\n")

	tw := tabwriter.NewWriter(out, 0, 0, 2, ' ', 0)
	fmt.Fprintf(tw, "\n   \tchips brought to the tables\t%s\t\n", comma(p.BoughtIn))
	fmt.Fprintf(tw, "   \thost adjustments\t%s\t\n", comma(p.Adjusted))
	fmt.Fprintf(tw, "   \tchips taken off the tables\t%s\t\n", comma(p.CashedOut))
	fmt.Fprintf(tw, "   \tchips left in the stacks\t%s\t\n", comma(p.FinalStacks))
	fmt.Fprintf(tw, "   \tdifference\t%s\t%s\n", comma(p.BoughtIn+p.Adjusted-p.CashedOut-p.FinalStacks),
		mark(p.BoughtIn+p.Adjusted-p.CashedOut == p.FinalStacks))
	fmt.Fprintf(tw, "   \ttotal wagered into pots\t%s\t\n", comma(p.Wagered))
	fmt.Fprintf(tw, "   \tbiggest pot\t%s\t\n", comma(p.BiggestPot))
	tw.Flush()

	tw = tabwriter.NewWriter(out, 0, 0, 2, ' ', 0)
	fmt.Fprintf(tw, "\n   \tinvariant\tchecked\tfailed\t\n")
	for _, c := range p.PerCheck {
		fmt.Fprintf(tw, "   \t%s\t%s\t%s\t%s\n", c.Name, comma(c.Passed), comma(c.Failed), mark(c.Failed == 0))
	}
	fmt.Fprintf(tw, "   \tTOTAL\t%s\t%s\t%s\n", comma(p.Checks), comma(p.Violations), mark(p.Violations == 0))
	tw.Flush()

	fmt.Fprintf(out, "\n   what the invariants mean\n")
	for _, c := range p.PerCheck {
		fmt.Fprintf(out, "     %-24s %s\n", c.Name, c.Desc)
	}

	tw = tabwriter.NewWriter(out, 0, 0, 2, ' ', 0)
	fmt.Fprintf(tw, "\n   \tshowdowns\t%s\tside pots\t%s\t\n", comma(p.Showdowns), comma(p.SidePots))
	fmt.Fprintf(tw, "   \tall-in actions\t%s\ttime-outs\t%s\t\n", comma(p.AllIns), comma(p.Timeouts))
	fmt.Fprintf(tw, "   \trun it twice\t%s\tre-buys\t%s\t\n", comma(p.RunTwice), comma(p.Rebuys))
	fmt.Fprintf(tw, "   \tplayers seated\t%s\tplayers left\t%s\t\n", comma(p.Joins), comma(p.Leaves))
	tw.Flush()

	if len(p.Examples) > 0 {
		fmt.Fprintf(out, "\n   first %d violations\n", len(p.Examples))
		for _, v := range p.Examples {
			fmt.Fprintf(out, "     [%s] table %d hand %d: %s\n", v.Check, v.Table, v.Hand, v.Detail)
		}
		fmt.Fprintf(out, "   reproduce a single one with: go run ./cmd/simulate -seed %d -tables %d -hands %d\n",
			r.Seed, o.tables, o.hands)
	}

	fmt.Fprintf(out, "\n%s\n", rule)
	if r.OK {
		fmt.Fprintf(out, "PASS — %s checks, no rule broken, not one chip created or lost.\n", comma(p.Checks))
	} else {
		fmt.Fprintf(out, "FAIL — %s of %s checks failed.\n", comma(p.Violations), comma(p.Checks))
	}
	fmt.Fprint(w, out.String())
}

func verdict(ok bool, good, bad string) string {
	if ok {
		return "ok — " + good
	}
	return "FAILED — " + bad
}

func mark(ok bool) string {
	if ok {
		return "ok"
	}
	return "FAILED"
}

// comma formats n with thousands separators.
func comma(n int64) string {
	s := strconv.FormatInt(n, 10)
	sign := ""
	if strings.HasPrefix(s, "-") {
		sign, s = "-", s[1:]
	}
	var b strings.Builder
	for i, c := range s {
		if i > 0 && (len(s)-i)%3 == 0 {
			b.WriteByte(',')
		}
		b.WriteRune(c)
	}
	return sign + b.String()
}
