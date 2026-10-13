# Banking Customer & Transaction Analytics — PostgreSQL

A GitHub-ready SQL portfolio project analyzing retail banking customers, accounts,
transactions and branch performance using PostgreSQL.

## Project objective

Analyze customer value, account activity, transaction trends and branch performance
using a normalized relational model. The project demonstrates beginner, intermediate
and advanced PostgreSQL SQL:

- INNER JOIN / LEFT JOIN
- WHERE / ORDER BY / DISTINCT
- GROUP BY / HAVING
- CASE WHEN
- subqueries / EXISTS / NOT EXISTS
- CTEs
- conditional aggregation
- window functions
- RANK / DENSE_RANK / ROW_NUMBER
- running totals
- month-over-month analysis
- customer segmentation
- inactivity analysis
- branch benchmarking

## Dataset

Source: SQLShed — Banking Transactions SQL Practice Dataset
https://sqlshed.com/practice-datasets/banking-transactions/

The source describes a synthetic retail-banking dataset with two years of posted
transactions. The full download contains 40 branches, 9,000 customers, 14,000
accounts and 320,000 transactions (343,840 rows across five source tables when
including merchants). It is public-domain CC0 and contains no real people,
accounts or transactions.

This portfolio version uses only these four source tables:
- branches
- customers
- accounts
- transactions

The source's `merchants` table is intentionally excluded to keep the project aligned
with the requested four-table relational model.

## Important modeling note

The source dataset does not store a transaction-level balance. Therefore:
- account balance is reconstructed as a signed running total
- debit amounts are negative in the running-balance calculation
- credit amounts are positive
- `closed_on IS NULL` means the account is currently open
- "inactive" is defined in this project as an open account with no transaction in
  the last 90 days of the dataset

Because the source contains synthetic data and no real customer information, this
project is suitable for a public portfolio.

## Repository structure

```text
banking-customer-transaction-analytics/
│
├── README.md
├── LICENSE
├── requirements.txt
│
├── data/
│   └── README.md
│
├── schema/
│   └── 01_schema.sql
│
├── sql/
│   ├── 02_data_quality.sql
│   ├── 03_beginner_questions.sql
│   ├── 04_intermediate_questions.sql
│   └── 05_advanced_questions.sql
│
├── docs/
│   ├── business_questions.md
│   ├── query_explanations.md
│   └── insights.md
│
└── results/
    └── README.md
```

## PostgreSQL setup

Create the database:

```sql
CREATE DATABASE banking_analytics;
```

Connect to it and run:

```text
schema/01_schema.sql
```

Then load the four CSV files described in `data/README.md`.

After loading, run the analysis scripts in order:

```text
sql/02_data_quality.sql
sql/03_beginner_questions.sql
sql/04_intermediate_questions.sql
sql/05_advanced_questions.sql
```

## Recommended interview story

> "I designed a normalized PostgreSQL banking database from a public synthetic
> transaction dataset. I used SQL from basic aggregation through CTEs and window
> functions to identify high-value customers, inactive accounts, monthly trends and
> branch performance. Since the source does not store balances, I reconstructed
> account balances using signed transaction amounts and window functions."

## Portfolio highlights

### High-value customers
Segment customers using total account balance, transaction value and number of
accounts. A customer with high balances and sustained transaction activity becomes a
priority relationship-management segment.

### Inactive accounts
Identify open accounts whose latest transaction is older than the 90-day inactivity
threshold. These accounts are candidates for re-engagement campaigns.

### Transaction trends
Measure monthly credits, debits, net flow, transaction count and average transaction
value. Use `LAG()` to quantify month-over-month changes.

### Branch performance
Compare branches on customer count, account count, total transaction value, active
accounts and average customer balance. Use `RANK()` to benchmark branches.

## SQL techniques demonstrated

| Technique | Where demonstrated |
|---|---|
| INNER JOIN | Customer/account/transaction analysis |
| LEFT JOIN | Customers with/without accounts; inactive account checks |
| GROUP BY | KPIs, branch and customer summaries |
| HAVING | High-value / high-activity groups |
| CASE WHEN | Customer and account segmentation |
| Subqueries | Threshold-based customer and transaction analysis |
| EXISTS / NOT EXISTS | Account activity and orphan checks |
| CTE | Multi-stage customer and branch analysis |
| Conditional aggregation | Credit/debit/net metrics |
| ROW_NUMBER | Latest transaction per account |
| RANK / DENSE_RANK | Branch and customer rankings |
| LAG | Month-over-month change |
| SUM OVER | Running balances and cumulative totals |
| FILTER | PostgreSQL conditional aggregates |
| DATE_TRUNC | Monthly analysis |
