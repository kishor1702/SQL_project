-- 01_schema.sql
-- PostgreSQL schema for Banking Customer & Transaction Analytics

DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS branches CASCADE;

CREATE TABLE branches (
    branch_id       INTEGER PRIMARY KEY,
    branch_name     TEXT NOT NULL,
    city            TEXT NOT NULL,
    country         TEXT NOT NULL,
    opened_on       DATE NOT NULL
);

CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    email           TEXT,
    city            TEXT,
    country         TEXT,
    home_branch_id  INTEGER NOT NULL REFERENCES branches(branch_id),
    joined_on       DATE NOT NULL,
    risk_band       TEXT
);

CREATE TABLE accounts (
    account_id       INTEGER PRIMARY KEY,
    customer_id      INTEGER NOT NULL REFERENCES customers(customer_id),
    account_type     TEXT NOT NULL,
    currency         TEXT NOT NULL,
    opened_on        DATE NOT NULL,
    closed_on        DATE,
    overdraft_limit  NUMERIC(18,2) NOT NULL DEFAULT 0
);

CREATE TABLE transactions (
    transaction_id   INTEGER PRIMARY KEY,
    account_id      INTEGER NOT NULL REFERENCES accounts(account_id),
    merchant_id     INTEGER,
    posted_at       TIMESTAMP NOT NULL,
    transaction_type TEXT NOT NULL,
    direction       TEXT NOT NULL CHECK (direction IN ('debit','credit')),
    amount          NUMERIC(18,2) NOT NULL CHECK (amount >= 0),
    channel         TEXT,
    description     TEXT
);

CREATE INDEX idx_customers_branch
    ON customers(home_branch_id);

CREATE INDEX idx_accounts_customer
    ON accounts(customer_id);

CREATE INDEX idx_accounts_closed
    ON accounts(closed_on);

CREATE INDEX idx_transactions_account_date
    ON transactions(account_id, posted_at);

CREATE INDEX idx_transactions_date
    ON transactions(posted_at);

CREATE INDEX idx_transactions_direction
    ON transactions(direction);

-- Optional validation
SELECT 'branches' AS table_name, COUNT(*) AS rows FROM branches
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions;
