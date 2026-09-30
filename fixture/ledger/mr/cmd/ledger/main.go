package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/demo/ledger/internal/api"
	"github.com/demo/ledger/internal/config"
	"github.com/demo/ledger/internal/limits"
	"github.com/demo/ledger/internal/store"
	"github.com/demo/ledger/internal/transfer"
)

func main() {
	cfg := config.Load()
	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatal(err)
	}
	st := store.New(db)
	svc := transfer.NewService(st, limits.NewChecker(st), cfg.TransferRetries)
	mux := http.NewServeMux()
	api.NewHandler(svc).Routes(mux)
	log.Printf("ledger listening on %s", cfg.Addr)
	log.Fatal(http.ListenAndServe(cfg.Addr, mux))
}
