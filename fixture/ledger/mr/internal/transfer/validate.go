package transfer

import (
	"errors"
	"fmt"
)

func Validate(req Request) error {
	if req.From == "" || req.To == "" {
		return errors.New("from and to are required")
	}
	if req.From == req.To {
		return errors.New("cannot transfer to the same account")
	}
	if req.Amount <= 0 {
		return fmt.Errorf("amount must be positive, got %d", req.Amount)
	}
	return nil
}
