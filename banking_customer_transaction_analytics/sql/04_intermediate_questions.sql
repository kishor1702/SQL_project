-- 04_intermediate_questions.sql
-- Intermediate SQL: CTEs, conditional aggregation, segmentation, dates

-- Q16. Monthly credits, debits and net flow.
SELECT DATE_TRUNC('month', posted_at)::date AS month,
       ROUND(SUM(amount) FILTER (WHERE direction='credit'),2) AS credits,
       ROUND(SUM(amount) FILTER (WHERE direction='debit'),2) AS debits,
       ROUND(SUM(CASE WHEN direction='credit' THEN amount ELSE -amount END),2) AS net_flow
FROM transactions
GROUP BY 1
ORDER BY 1;

-- Q17. Monthly transaction count and average value.
SELECT DATE_TRUNC('month', posted_at)::date AS month,
       COUNT(*) AS transactions,
       ROUND(AVG(amount),2) AS avg_transaction_value
FROM transactions
GROUP BY 1
ORDER BY 1;

-- Q18. Branch-level customer and account KPIs.
SELECT b.branch_id,
       b.branch_name,
       COUNT(DISTINCT c.customer_id) AS customers,
       COUNT(DISTINCT a.account_id) AS accounts
FROM branches b
LEFT JOIN customers c ON c.home_branch_id = b.branch_id
LEFT JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY b.branch_id, b.branch_name
ORDER BY customers DESC;

-- Q19. Branch transaction performance.
SELECT b.branch_id,
       b.branch_name,
       COUNT(t.transaction_id) AS transactions,
       ROUND(SUM(t.amount),2) AS transaction_value,
       ROUND(AVG(t.amount),2) AS avg_transaction
FROM branches b
LEFT JOIN customers c ON c.home_branch_id = b.branch_id
LEFT JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY b.branch_id, b.branch_name
ORDER BY transaction_value DESC NULLS LAST;

-- Q20. Customer transaction summary.
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       COUNT(t.transaction_id) AS transactions,
       ROUND(SUM(t.amount),2) AS total_transaction_value,
       ROUND(AVG(t.amount),2) AS avg_transaction
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_transaction_value DESC NULLS LAST;

-- Q21. Customer credit/debit behavior with conditional aggregation.
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       ROUND(COALESCE(SUM(t.amount) FILTER (WHERE t.direction='credit'),0),2) AS credits,
       ROUND(COALESCE(SUM(t.amount) FILTER (WHERE t.direction='debit'),0),2) AS debits,
       ROUND(COALESCE(SUM(t.amount) FILTER (WHERE t.direction='credit'),0)
            - COALESCE(SUM(t.amount) FILTER (WHERE t.direction='debit'),0),2) AS net_flow
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY net_flow DESC;

-- Q22. Customer segmentation.
WITH customer_metrics AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name AS customer_name,
           COALESCE(SUM(CASE WHEN t.direction='credit' THEN t.amount ELSE -t.amount END),0) AS net_flow,
           COALESCE(SUM(t.amount),0) AS transaction_value,
           COUNT(DISTINCT a.account_id) AS accounts
    FROM customers c
    LEFT JOIN accounts a ON a.customer_id = c.customer_id
    LEFT JOIN transactions t ON t.account_id = a.account_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT *,
       CASE
           WHEN transaction_value >= 250000 AND accounts >= 3 THEN 'Premium'
           WHEN transaction_value >= 100000 OR net_flow >= 50000 THEN 'High Value'
           WHEN transaction_value >= 25000 THEN 'Mass Affluent'
           WHEN transaction_value > 0 THEN 'Standard'
           ELSE 'Dormant'
       END AS customer_segment
FROM customer_metrics
ORDER BY transaction_value DESC;

-- Q23. High-value customers above the bank average transaction value.
WITH customer_value AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name AS customer_name,
           SUM(t.amount) AS total_value
    FROM customers c
    JOIN accounts a ON a.customer_id = c.customer_id
    JOIN transactions t ON t.account_id = a.account_id
    GROUP BY c.customer_id, c.first_name, c.last_name
)
SELECT *
FROM customer_value
WHERE total_value > (SELECT AVG(total_value) FROM customer_value)
ORDER BY total_value DESC;

-- Q24. Accounts with no transaction in the last 90 days.
WITH last_activity AS (
    SELECT a.account_id,
           a.customer_id,
           a.closed_on,
           MAX(t.posted_at) AS last_transaction
    FROM accounts a
    LEFT JOIN transactions t ON t.account_id = a.account_id
    GROUP BY a.account_id, a.customer_id, a.closed_on
)
SELECT *
FROM last_activity
WHERE closed_on IS NULL
  AND (last_transaction IS NULL
       OR last_transaction < (SELECT MAX(posted_at) FROM transactions) - INTERVAL '90 days')
ORDER BY last_transaction NULLS FIRST;

-- Q25. Customers with multiple accounts.
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       COUNT(a.account_id) AS account_count
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(a.account_id) >= 2
ORDER BY account_count DESC;

-- Q26. Monthly active customers.
SELECT DATE_TRUNC('month', t.posted_at)::date AS month,
       COUNT(DISTINCT a.customer_id) AS active_customers
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
GROUP BY 1
ORDER BY 1;

-- Q27. Channel usage by transaction count and value.
SELECT channel,
       COUNT(*) AS transactions,
       ROUND(SUM(amount),2) AS value,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),2) AS pct_of_transactions
FROM transactions
GROUP BY channel
ORDER BY transactions DESC;

-- Q28. Risk-band transaction behavior.
SELECT COALESCE(c.risk_band,'Not Assessed') AS risk_band,
       COUNT(DISTINCT c.customer_id) AS customers,
       COUNT(t.transaction_id) AS transactions,
       ROUND(SUM(t.amount),2) AS transaction_value,
       ROUND(AVG(t.amount),2) AS avg_transaction
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY COALESCE(c.risk_band,'Not Assessed')
ORDER BY transaction_value DESC NULLS LAST;

-- Q29. Account type performance.
SELECT a.account_type,
       COUNT(DISTINCT a.account_id) AS accounts,
       COUNT(t.transaction_id) AS transactions,
       ROUND(SUM(t.amount),2) AS transaction_value,
       ROUND(AVG(t.amount),2) AS avg_transaction
FROM accounts a
LEFT JOIN transactions t ON t.account_id = a.account_id
GROUP BY a.account_type
ORDER BY transaction_value DESC NULLS LAST;

-- Q30. Branches with above-average transaction value.
WITH branch_value AS (
    SELECT b.branch_id,
           b.branch_name,
           COALESCE(SUM(t.amount),0) AS transaction_value
    FROM branches b
    LEFT JOIN customers c ON c.home_branch_id = b.branch_id
    LEFT JOIN accounts a ON a.customer_id = c.customer_id
    LEFT JOIN transactions t ON t.account_id = a.account_id
    GROUP BY b.branch_id, b.branch_name
)
SELECT *
FROM branch_value
WHERE transaction_value > (SELECT AVG(transaction_value) FROM branch_value)
ORDER BY transaction_value DESC;
