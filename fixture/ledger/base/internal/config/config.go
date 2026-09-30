package config

import (
	"os"
	"strconv"
)

type Config struct {
	Addr        string
	DatabaseURL string
	FeePercent  float64
}

func Load() Config {
	return Config{
		Addr:        env("LEDGER_ADDR", ":8080"),
		DatabaseURL: env("DATABASE_URL", "postgres://localhost/ledger"),
		FeePercent:  envFloat("LEDGER_FEE_PERCENT", 0),
	}
}

func env(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return fallback
}

func envFloat(key string, fallback float64) float64 {
	v, err := strconv.ParseFloat(os.Getenv(key), 64)
	if err != nil {
		return fallback
	}
	return v
}
