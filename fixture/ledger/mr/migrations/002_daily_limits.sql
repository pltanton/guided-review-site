ALTER TABLE accounts ADD COLUMN daily_limit BIGINT NOT NULL;

CREATE TABLE transfer_totals (
    account_id TEXT   NOT NULL REFERENCES accounts (id),
    day        DATE   NOT NULL,
    spent      BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (account_id, day)
);
