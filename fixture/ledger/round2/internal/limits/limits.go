package limits

import (
	"context"
	"errors"
	"fmt"

	"github.com/demo/ledger/internal/store"
)

var ErrExceeded = errors.New("daily transfer limit exceeded")

type TotalsFunc func(ctx context.Context, q store.Querier, account string) (spent, limit int64, err error)

type Checker struct {
	totals TotalsFunc
}

func NewChecker(t TotalsFunc) *Checker {
	return &Checker{totals: t}
}

func (c *Checker) Check(ctx context.Context, q store.Querier, account string, amount int64) error {
	spent, limit, err := c.totals(ctx, q, account)
	if err != nil {
		return fmt.Errorf("limits for %s: %w", account, err)
	}
	if limit > 0 && spent+amount > limit {
		return fmt.Errorf("%w: %d of %d spent, %d requested", ErrExceeded, spent, limit, amount)
	}
	return nil
}
