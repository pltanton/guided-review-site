package api

import (
	"encoding/json"
	"errors"
	"math"
	"net/http"

	"github.com/demo/ledger/internal/limits"
	"github.com/demo/ledger/internal/store"
	"github.com/demo/ledger/internal/transfer"
)

type Handler struct {
	transfers *transfer.Service
}

func NewHandler(t *transfer.Service) *Handler {
	return &Handler{transfers: t}
}

func (h *Handler) Routes(mux *http.ServeMux) {
	mux.HandleFunc("POST /transfers", h.createTransfer)
}

type transferBody struct {
	From   string  `json:"from"`
	To     string  `json:"to"`
	Amount float64 `json:"amount"`
}

func (h *Handler) createTransfer(w http.ResponseWriter, r *http.Request) {
	var body transferBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad json", http.StatusBadRequest)
		return
	}
	req := transfer.Request{
		From:   body.From,
		To:     body.To,
		Amount: int64(math.Round(body.Amount * 100)),
	}
	err := h.transfers.Transfer(r.Context(), req)
	switch {
	case errors.Is(err, limits.ErrExceeded):
		http.Error(w, err.Error(), http.StatusUnprocessableEntity)
	case errors.Is(err, store.ErrInsufficientFunds):
		http.Error(w, err.Error(), http.StatusConflict)
	case errors.Is(err, store.ErrNoAccount):
		http.Error(w, err.Error(), http.StatusNotFound)
	case err != nil:
		http.Error(w, err.Error(), http.StatusBadRequest)
	default:
		w.WriteHeader(http.StatusCreated)
	}
}
