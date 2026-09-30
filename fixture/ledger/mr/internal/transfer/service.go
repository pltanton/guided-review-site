package transfer

import (
	"context"
	"database/sql"
	"time"

	"github.com/demo/ledger/internal/limits"
	"github.com/demo/ledger/internal/store"
)

type Request struct {
	From   string
	To     string
	Amount int64
}

type Service struct {
	store   *store.Store
	limits  *limits.Checker
	retries int
}

func NewService(s *store.Store, l *limits.Checker, retries int) *Service {
	return &Service{store: s, limits: l, retries: retries}
}

func (s *Service) Transfer(ctx context.Context, req Request) error {
	if err := Validate(req); err != nil {
		return err
	}
	if err := s.limits.Check(ctx, req.From, req.Amount); err != nil {
		return err
	}
	return retry(ctx, s.retries, func() error {
		return s.store.InTx(ctx, func(tx *sql.Tx) error {
			if err := store.Debit(ctx, tx, req.From, req.Amount); err != nil {
				return err
			}
			if err := store.Credit(ctx, tx, req.To, req.Amount); err != nil {
				return err
			}
			if err := store.AddSpent(ctx, tx, req.From, req.Amount); err != nil {
				return err
			}
			return store.RecordTransfer(ctx, tx, req.From, req.To, req.Amount)
		})
	})
}

func retry(ctx context.Context, attempts int, fn func() error) error {
	var err error
	for i := range attempts {
		if err = fn(); err == nil || !store.IsRetryable(err) {
			return err
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(time.Duration(i+1) * 50 * time.Millisecond):
		}
	}
	return err
}
