package table

import (
	"context"
	"log/slog"
	"time"

	"showdown/internal/store"
)

// persistJob runs on the persister goroutine. handRowID is the database id
// of the hand most recently inserted for this table; jobs run in order, so a
// FinishHand job always sees the id set by the preceding InsertHand job.
type persistJob func(ctx context.Context, st *store.Store, p *persister) error

// persister serialises database writes of one table so that slow disk never
// blocks the actor. Jobs are executed in order; Drain waits for the queue to
// empty.
type persister struct {
	jobs      chan persistJob
	done      chan struct{}
	st        *store.Store
	log       *slog.Logger
	handRowID int64
}

func newPersister(st *store.Store, log *slog.Logger) *persister {
	p := &persister{jobs: make(chan persistJob, 1024), done: make(chan struct{}), st: st, log: log}
	go p.run()
	return p
}

func (p *persister) run() {
	defer close(p.done)
	for job := range p.jobs {
		p.execute(job)
	}
}

// persistAttempts and persistBackoff bound the retries of a failed job. A
// transient SQLite error (busy database, slow disk) must not silently drop a
// hand row or a stack update; later jobs wait, since order matters.
const persistAttempts = 4

var persistBackoff = 100 * time.Millisecond

func (p *persister) execute(job persistJob) {
	var err error
	wait := persistBackoff
	for attempt := 1; attempt <= persistAttempts; attempt++ {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		err = job(ctx, p.st, p)
		cancel()
		if err == nil {
			return
		}
		if attempt < persistAttempts {
			p.log.Warn("persist failed; retrying", "attempt", attempt, "err", err)
			time.Sleep(wait)
			wait *= 4
		}
	}
	p.log.Error("persist failed permanently", "attempts", persistAttempts, "err", err)
}

// enqueue never blocks the actor for long: if the queue is full the job is
// still delivered (backpressure) but that only happens when the disk is far
// behind.
func (p *persister) enqueue(job persistJob) {
	if p.st == nil {
		return
	}
	p.jobs <- job
}

// close stops accepting jobs and waits until the queue is drained.
func (p *persister) close(ctx context.Context) {
	close(p.jobs)
	select {
	case <-p.done:
	case <-ctx.Done():
		p.log.Warn("persister drain timed out")
	}
}
