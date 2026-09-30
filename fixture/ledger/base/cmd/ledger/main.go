package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/demo/ledger/internal/api"
	"github.com/demo/ledger/internal/config"
	"github.com/demo/ledger/internal/legacy"
	"github.com/demo/ledger/internal/store"
	"github.com/demo/ledger/internal/transfer"
)

func main() {
	cfg := config.Load()
	db, err := sql.Open("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatal(err)
	}
	fees := legacy.NewFeeCalculator(cfg.FeePercent)
	svc := transfer.NewService(store.New(db), fees)
	mux := http.NewServeMux()
	api.NewHandler(svc).Routes(mux)
	log.Printf("ledger listening on %s", cfg.Addr)
	log.Fatal(http.ListenAndServe(cfg.Addr, mux))
}
