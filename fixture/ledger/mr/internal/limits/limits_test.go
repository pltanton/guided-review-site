package limits

import (
	"context"
	"errors"
	"testing"
)

func TestCheck(t *testing.T) {
	tests := []struct {
		name         string
		spent, limit int64
		amount       int64
		want         error
	}{
		{name: "under", spent: 100, limit: 1000, amount: 500},
		{name: "exactly at limit", spent: 500, limit: 1000, amount: 500},
		{name: "over", spent: 900, limit: 1000, amount: 200, want: ErrExceeded},
		{name: "no limit", spent: 1 << 40, limit: 0, amount: 1},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c := NewChecker(&MockTotals{Spent: tt.spent, Limit: tt.limit})
			err := c.Check(context.Background(), "acc-1", tt.amount)
			if !errors.Is(err, tt.want) {
				t.Fatalf("Check() = %v, want %v", err, tt.want)
			}
		})
	}
}
