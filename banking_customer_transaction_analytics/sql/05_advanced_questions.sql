-- 05_advanced_questions.sql
-- Advanced PostgreSQL SQL: window functions, ranking, running totals, CTE pipelines

-- Q31. Reconstruct running balance for every account.
WITH signed_transactions AS (
    SELECT account_id,
           transaction_id,
           posted_at,
           direction,
           amount,
           CASE WHEN direction='debit' THEN -amount ELSE amount END AS signed_amount
    FROM transactions
)
SELECT account_id,
       transaction_id,
       posted_at,
       direction,
       amount,
       ROUND(
           SUM(signed_amount) OVER (
               PARTITION BY account_id
               ORDER BY posted_at, transaction_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ), 2
       ) AS running_balance
FROM signed_transactions
ORDER BY account_id, posted_at, transaction_id;

-- Q32. Find accounts that went below zero.
WITH ledger AS (
    SELECT account_id,
           posted_at,
           transaction_id,
           SUM(CASE WHEN direction='debit' THEN -amount ELSE amount END)
             OVER (PARTITION BY account_id ORDER BY posted_at, transaction_id) AS balance
    FROM transactions
)
SELECT account_id,
       MIN(posted_at) AS first_overdrawn_at,
       ROUND(MIN(balance),2) AS lowest_observed_balance
FROM ledger
WHERE balance < 0
GROUP BY account_id
ORDER BY lowest_observed_balance;

-- Q33. First and latest transaction for each account using ROW_NUMBER.
WITH ranked AS (
    SELECT account_id,
           transaction_id,
           posted_at,
           amount,
           ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY posted_at, transaction_id) AS first_rn,
           ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY posted_at DESC, transaction_id DESC) AS latest_rn
    FROM transactions
)
SELECT account_id,
       MAX(posted_at) FILTER (WHERE first_rn=1) AS first_transaction,
       MAX(posted_at) FILTER (WHERE latest_rn=1) AS latest_transaction
FROM ranked
GROUP BY account_id
ORDER BY account_id;

-- Q34. Rank branches by transaction value.
WITH branch_kpi AS (
    SELECT b.branch_id,
           b.branch_name,
           COALESCE(SUM(t.amount),0) AS transaction_value
    FROM branches b
    LEFT JOIN customers c ON c.home_branch_id=b.branch_id
    LEFT JOIN accounts a ON a.customer_id=c.customer_id
    LEFT JOIN transactions t ON t.account_id=a.account_id
    GROUP BY b.branch_id,b.branch_name
)
SELECT *,
       RANK() OVER (ORDER BY transaction_value DESC) AS branch_rank
FROM branch_kpi
ORDER BY branch_rank;

-- Q35. Rank customers within each branch by transaction value.
WITH customer_value AS (
    SELECT c.home_branch_id,
           c.customer_id,
           c.first_name || ' ' || c.last_name AS customer_name,
           COALESCE(SUM(t.amount),0) AS transaction_value
    FROM customers c
    LEFT JOIN accounts a ON a.customer_id=c.customer_id
    LEFT JOIN transactions t ON t.account_id=a.account_id
    GROUP BY c.home_branch_id,c.customer_id,c.first_name,c.last_name
)
SELECT *,
       DENSE_RANK() OVER (
           PARTITION BY home_branch_id
           ORDER BY transaction_value DESC
       ) AS customer_rank_in_branch
FROM customer_value
ORDER BY home_branch_id, customer_rank_in_branch;

-- Q36. Monthly net flow and month-over-month change.
WITH monthly AS (
    SELECT DATE_TRUNC('month',posted_at)::date AS month,
           SUM(CASE WHEN direction='credit' THEN amount ELSE -amount END) AS net_flow
    FROM transactions
    GROUP BY 1
)
SELECT month,
       ROUND(net_flow,2) AS net_flow,
       ROUND(LAG(net_flow) OVER (ORDER BY month),2) AS prior_month_net,
       ROUND(net_flow - LAG(net_flow) OVER (ORDER BY month),2) AS change_vs_prior_month,
       ROUND(
           100.0 * (net_flow - LAG(net_flow) OVER (ORDER BY month))
           / NULLIF(LAG(net_flow) OVER (ORDER BY month),0), 2
       ) AS pct_change
FROM monthly
ORDER BY month;

-- Q37. Running bank-wide cumulative net flow by month.
WITH monthly AS (
    SELECT DATE_TRUNC('month',posted_at)::date AS month,
           SUM(CASE WHEN direction='credit' THEN amount ELSE -amount END) AS net_flow
    FROM transactions
    GROUP BY 1
)
SELECT month,
       ROUND(net_flow,2) AS monthly_net_flow,
       ROUND(SUM(net_flow) OVER (ORDER BY month),2) AS cumulative_net_flow
FROM monthly
ORDER BY month;

-- Q38. Top 3 customers per branch.
WITH customer_value AS (
    SELECT c.home_branch_id,
           c.customer_id,
           c.first_name || ' ' || c.last_name AS customer_name,
           COALESCE(SUM(t.amount),0) AS transaction_value
    FROM customers c
    LEFT JOIN accounts a ON a.customer_id=c.customer_id
    LEFT JOIN transactions t ON t.account_id=a.account_id
    GROUP BY c.home_branch_id,c.customer_id,c.first_name,c.last_name
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY home_branch_id
               ORDER BY transaction_value DESC, customer_id
           ) AS rn
    FROM customer_value
)
SELECT *
FROM ranked
WHERE rn <= 3
ORDER BY home_branch_id, rn;

-- Q39. Monthly transaction value by account type with MoM change.
WITH monthly AS (
    SELECT a.account_type,
           DATE_TRUNC('month',t.posted_at)::date AS month,
           SUM(t.amount) AS transaction_value
    FROM accounts a
    JOIN transactions t ON t.account_id=a.account_id
    GROUP BY a.account_type,1
)
SELECT account_type,
       month,
       ROUND(transaction_value,2) AS transaction_value,
       ROUND(
           transaction_value
           - LAG(transaction_value) OVER (
               PARTITION BY account_type ORDER BY month
             ),2
       ) AS change_vs_prior_month
FROM monthly
ORDER BY account_type, month;

-- Q40. Customer activity score using recency, frequency and monetary value.
WITH metrics AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name AS customer_name,
           COUNT(t.transaction_id) AS txn_count,
           COALESCE(SUM(t.amount),0) AS txn_value,
           MAX(t.posted_at) AS last_transaction,
           CURRENT_DATE - MAX(t.posted_at)::date AS recency_days
    FROM customers c
    LEFT JOIN accounts a ON a.customer_id=c.customer_id
    LEFT JOIN transactions t ON t.account_id=a.account_id
    GROUP BY c.customer_id,c.first_name,c.last_name
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC NULLS FIRST) AS recency_bucket,
           NTILE(5) OVER (ORDER BY txn_count) AS frequency_bucket,
           NTILE(5) OVER (ORDER BY txn_value) AS monetary_bucket
    FROM metrics
)
SELECT *,
       CASE
           WHEN recency_bucket >= 4 AND frequency_bucket >= 4 AND monetary_bucket >= 4
               THEN 'Champions'
           WHEN recency_bucket >= 3 AND frequency_bucket >= 3
               THEN 'Loyal'
           WHEN recency_bucket <= 2 AND monetary_bucket >= 4
               THEN 'At Risk - High Value'
           WHEN recency_bucket <= 2
               THEN 'Inactive'
           ELSE 'Developing'
       END AS engagement_segment
FROM scored
ORDER BY monetary_bucket DESC, frequency_bucket DESC;

-- Q41. Branch scorecard with relative ranking and contribution to bank value.
WITH branch_kpi AS (
    SELECT b.branch_id,
           b.branch_name,
           COUNT(DISTINCT c.customer_id) AS customers,
           COUNT(DISTINCT a.account_id) AS accounts,
           COUNT(t.transaction_id) AS transactions,
           COALESCE(SUM(t.amount),0) AS transaction_value
    FROM branches b
    LEFT JOIN customers c ON c.home_branch_id=b.branch_id
    LEFT JOIN accounts a ON a.customer_id=c.customer_id
    LEFT JOIN transactions t ON t.account_id=a.account_id
    GROUP BY b.branch_id,b.branch_name
)
SELECT *,
       RANK() OVER (ORDER BY transaction_value DESC) AS value_rank,
       ROUND(100.0 * transaction_value / SUM(transaction_value) OVER (),2) AS pct_bank_value,
       ROUND(transaction_value / NULLIF(customers,0),2) AS value_per_customer
FROM branch_kpi
ORDER BY value_rank;

-- Q42. Detect suspiciously repeated card payments using LAG.
-- The source contains merchant_id but this project intentionally does not
-- create a merchants table, so merchant_id is used only as a transaction key.
WITH card_payments AS (
    SELECT account_id,
           merchant_id,
           amount,
           posted_at,
           LAG(posted_at) OVER (
               PARTITION BY account_id, merchant_id, amount
               ORDER BY posted_at
           ) AS previous_posted_at
    FROM transactions
    WHERE transaction_type='card_payment'
      AND merchant_id IS NOT NULL
)
SELECT account_id,
       merchant_id,
       ROUND(amount,2) AS amount,
       previous_posted_at,
       posted_at,
       ROUND(EXTRACT(EPOCH FROM (posted_at-previous_posted_at))/60.0,2) AS minutes_apart
FROM card_payments
WHERE previous_posted_at IS NOT NULL
  AND posted_at <= previous_posted_at + INTERVAL '15 minutes'
ORDER BY account_id, posted_at;

-- Q43. Identify the largest debit for every customer.
WITH debits AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name AS customer_name,
           t.transaction_id,
           t.posted_at,
           t.amount,
           ROW_NUMBER() OVER (
               PARTITION BY c.customer_id
               ORDER BY t.amount DESC, t.posted_at
           ) AS rn
    FROM customers c
    JOIN accounts a ON a.customer_id=c.customer_id
    JOIN transactions t ON t.account_id=a.account_id
    WHERE t.direction='debit'
)
SELECT *
FROM debits
WHERE rn=1
ORDER BY amount DESC;

-- Q44. Find customers whose latest month is lower than their own previous month.
WITH customer_monthly AS (
    SELECT c.customer_id,
           DATE_TRUNC('month',t.posted_at)::date AS month,
           SUM(t.amount) AS value
    FROM customers c
    JOIN accounts a ON a.customer_id=c.customer_id
    JOIN transactions t ON t.account_id=a.account_id
    GROUP BY c.customer_id,1
),
with_lag AS (
    SELECT *,
           LAG(value) OVER (PARTITION BY customer_id ORDER BY month) AS prior_value,
           MAX(month) OVER (PARTITION BY customer_id) AS latest_month
    FROM customer_monthly
)
SELECT customer_id,
       month,
       ROUND(value,2) AS latest_value,
       ROUND(prior_value,2) AS prior_value,
       ROUND(value-prior_value,2) AS change
FROM with_lag
WHERE month=latest_month
  AND prior_value IS NOT NULL
  AND value < prior_value
ORDER BY change;

-- Q45. Final executive customer value table.
WITH customer_kpi AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name AS customer_name,
           COALESCE(SUM(t.amount),0) AS transaction_value,
           COUNT(t.transaction_id) AS transaction_count,
           COUNT(DISTINCT a.account_id) AS accounts,
           MAX(t.posted_at) AS last_transaction
    FROM customers c
    LEFT JOIN accounts a ON a.customer_id=c.customer_id
    LEFT JOIN transactions t ON t.account_id=a.account_id
    GROUP BY c.customer_id,c.first_name,c.last_name
)
SELECT *,
       CASE
           WHEN transaction_value >= 250000 AND transaction_count >= 50 THEN 'Platinum'
           WHEN transaction_value >= 100000 OR transaction_count >= 25 THEN 'Gold'
           WHEN transaction_value >= 25000 THEN 'Silver'
           WHEN transaction_value > 0 THEN 'Bronze'
           ELSE 'Dormant'
       END AS value_segment,
       RANK() OVER (ORDER BY transaction_value DESC) AS overall_rank
FROM customer_kpi
ORDER BY overall_rank;
