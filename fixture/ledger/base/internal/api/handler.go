package api

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"

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
	From        string `json:"from"`
	To          string `json:"to"`
	AmountCents int64  `json:"amount_cents"`
}

func (h *Handler) createTransfer(w http.ResponseWriter, r *http.Request) {
	var body transferBody
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad json", http.StatusBadRequest)
		return
	}
	req := transfer.Request{From: body.From, To: body.To, Amount: body.AmountCents}
	if err := validateTransfer(req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	err := h.transfers.Transfer(r.Context(), req)
	switch {
	case errors.Is(err, store.ErrInsufficientFunds):
		http.Error(w, err.Error(), http.StatusConflict)
	case errors.Is(err, store.ErrNoAccount):
		http.Error(w, err.Error(), http.StatusNotFound)
	case err != nil:
		http.Error(w, "internal error", http.StatusInternalServerError)
	default:
		w.WriteHeader(http.StatusCreated)
	}
}

func validateTransfer(req transfer.Request) error {
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
