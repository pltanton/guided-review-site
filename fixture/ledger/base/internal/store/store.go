package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
)

var (
	ErrInsufficientFunds = errors.New("insufficient funds")
	ErrNoAccount         = errors.New("account not found")
)

type Store struct {
	db *sql.DB
}

func New(db *sql.DB) *Store {
	return &Store{db: db}
}

func (s *Store) InTx(ctx context.Context, fn func(tx *sql.Tx) error) error {
	tx, err := s.db.BeginTx(ctx, &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		return fmt.Errorf("begin: %w", err)
	}
	if err := fn(tx); err != nil {
		_ = tx.Rollback()
		return err
	}
	return tx.Commit()
}

func Debit(ctx context.Context, tx *sql.Tx, account string, amount int64) error {
	res, err := tx.ExecContext(ctx,
		`UPDATE accounts SET balance = balance - $2 WHERE id = $1 AND balance >= $2`,
		account, amount)
	if err != nil {
		return fmt.Errorf("debit %s: %w", account, err)
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrInsufficientFunds
	}
	return nil
}

func Credit(ctx context.Context, tx *sql.Tx, account string, amount int64) error {
	res, err := tx.ExecContext(ctx,
		`UPDATE accounts SET balance = balance + $2 WHERE id = $1`, account, amount)
	if err != nil {
		return fmt.Errorf("credit %s: %w", account, err)
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNoAccount
	}
	return nil
}

func RecordTransfer(ctx context.Context, tx *sql.Tx, from, to string, amount int64) error {
	_, err := tx.ExecContext(ctx,
		`INSERT INTO transfers (from_account, to_account, amount) VALUES ($1, $2, $3)`,
		from, to, amount)
	return err
}
