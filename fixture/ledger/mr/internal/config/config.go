package config

import (
	"os"
	"strconv"
)

type Config struct {
	Addr            string
	DatabaseURL     string
	TransferRetries int
}

func Load() Config {
	return Config{
		Addr:            env("LEDGER_ADDR", ":8080"),
		DatabaseURL:     env("DATABASE_URL", "postgres://localhost/ledger"),
		TransferRetries: envInt("LEDGER_TRANSFER_RETRIES", 3),
	}
}

func env(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return fallback
}

func envInt(key string, fallback int) int {
	v, err := strconv.Atoi(os.Getenv(key))
	if err != nil {
		return fallback
	}
	return v
}
