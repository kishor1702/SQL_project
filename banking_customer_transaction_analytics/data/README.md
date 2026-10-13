# Data

## Source

Download the four required Parquet files from:

https://sqlshed.com/practice-datasets/banking-transactions/

Files:
- branches.parquet
- customers.parquet
- accounts.parquet
- transactions.parquet

The source is public domain (CC0).

## Convert Parquet to CSV

PostgreSQL's standard `COPY` workflow is easiest with CSV. Convert the downloaded
files with DuckDB:

```sql
COPY (SELECT * FROM read_parquet('branches.parquet'))
TO 'branches.csv' (HEADER, DELIMITER ',');

COPY (SELECT * FROM read_parquet('customers.parquet'))
TO 'customers.csv' (HEADER, DELIMITER ',');

COPY (SELECT * FROM read_parquet('accounts.parquet'))
TO 'accounts.csv' (HEADER, DELIMITER ',');

COPY (SELECT * FROM read_parquet('transactions.parquet'))
TO 'transactions.csv' (HEADER, DELIMITER ',');
```

Then place the four CSV files in this folder.

## Source columns used

### branches
`branch_id, branch_name, city, country, opened_on`

### customers
`customer_id, first_name, last_name, email, city, country, home_branch_id,
joined_on, risk_band`

### accounts
`account_id, customer_id, account_type, currency, opened_on, closed_on,
overdraft_limit`

### transactions
`transaction_id, account_id, merchant_id, posted_at, transaction_type,
direction, amount, channel, description`

The optional `merchant_id` is retained in the transaction table for source fidelity,
but this project does not create a fifth merchants table.
