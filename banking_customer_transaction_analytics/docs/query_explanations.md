# Query Explanations

## 1. Why LEFT JOIN is important
A `LEFT JOIN` preserves customers or accounts even when there is no matching
transaction. This is essential for finding customers with no accounts and accounts
with no recent activity.

## 2. Why conditional aggregation is useful
Instead of running separate queries for credits and debits, PostgreSQL can calculate
both in one grouped scan:

```sql
SUM(amount) FILTER (WHERE direction='credit')
SUM(amount) FILTER (WHERE direction='debit')
```

This also makes net-flow calculations easy.

## 3. Why CTEs are used
The analysis often has multiple logical stages:
1. calculate customer metrics
2. rank or segment those metrics
3. filter the result

A CTE makes each stage readable and interview-friendly.

## 4. Why window functions matter
The dataset intentionally does not contain stored balances. A running balance must
therefore be calculated in transaction order:

```sql
SUM(signed_amount) OVER (
    PARTITION BY account_id
    ORDER BY posted_at, transaction_id
)
```

The same pattern is useful for cumulative totals, ranking, month-over-month analysis
and top-N analysis.

## 5. Ranking
`RANK()` is appropriate when ties should share a rank. `DENSE_RANK()` avoids gaps
after ties. `ROW_NUMBER()` is useful when exactly one row must be selected.

## 6. Customer segmentation
The segmentation is deliberately rule-based rather than machine learning:
- Platinum / Premium: high monetary value + sustained activity
- Gold / High Value: strong monetary value or transaction frequency
- Silver / Mass Affluent: meaningful engagement
- Bronze / Standard: regular but lower activity
- Dormant: no meaningful transaction activity

The thresholds are portfolio assumptions and should be recalibrated using actual bank
strategy.

## 7. Inactivity
The project defines inactivity as an open account whose latest transaction is more
than 90 days before the final transaction date in the dataset. This avoids making
the result depend on the analyst's current calendar date.

## 8. Business interpretation
SQL results should be translated into actions:
- High-value customers → relationship-manager prioritization
- At-risk high-value customers → retention outreach
- Inactive accounts → reactivation campaigns
- Weak branches → operational benchmarking
- Strong branches → identify repeatable practices
- Monthly net-flow changes → liquidity and campaign monitoring
