CREATE TABLE accounts (
    id         TEXT PRIMARY KEY,
    owner      TEXT NOT NULL,
    currency   CHAR(3) NOT NULL,
    balance    BIGINT NOT NULL CHECK (balance >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE transfers (
    id           BIGSERIAL PRIMARY KEY,
    from_account TEXT NOT NULL REFERENCES accounts (id),
    to_account   TEXT NOT NULL REFERENCES accounts (id),
    amount       BIGINT NOT NULL CHECK (amount > 0),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
