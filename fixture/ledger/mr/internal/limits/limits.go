package limits

import (
	"context"
	"errors"
	"fmt"
)

var ErrExceeded = errors.New("daily transfer limit exceeded")

type Totals interface {
	SpentToday(ctx context.Context, account string) (spent, limit int64, err error)
}

type Checker struct {
	totals Totals
}

func NewChecker(t Totals) *Checker {
	return &Checker{totals: t}
}

func (c *Checker) Check(ctx context.Context, account string, amount int64) error {
	spent, limit, err := c.totals.SpentToday(ctx, account)
	if err != nil {
		return fmt.Errorf("limits for %s: %w", account, err)
	}
	if limit > 0 && spent+amount > limit {
		return fmt.Errorf("%w: %d of %d spent, %d requested", ErrExceeded, spent, limit, amount)
	}
	return nil
}
