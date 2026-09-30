package transfer

import (
	"context"
	"database/sql"

	"github.com/demo/ledger/internal/legacy"
	"github.com/demo/ledger/internal/store"
)

type Request struct {
	From   string
	To     string
	Amount int64
}

type Service struct {
	store *store.Store
	fees  *legacy.FeeCalculator
}

func NewService(s *store.Store, fees *legacy.FeeCalculator) *Service {
	return &Service{store: s, fees: fees}
}

func (s *Service) Transfer(ctx context.Context, req Request) error {
	fee := s.fees.Fee(req.Amount)
	return s.store.InTx(ctx, func(tx *sql.Tx) error {
		if err := store.Debit(ctx, tx, req.From, req.Amount+fee); err != nil {
			return err
		}
		if err := store.Credit(ctx, tx, req.To, req.Amount); err != nil {
			return err
		}
		return store.RecordTransfer(ctx, tx, req.From, req.To, req.Amount)
	})
}
