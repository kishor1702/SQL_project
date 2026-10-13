-- 02_data_quality.sql
-- Basic validation before business analysis

-- Q1. Row counts
SELECT 'branches' table_name, COUNT(*) rows FROM branches
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL SELECT 'transactions', COUNT(*) FROM transactions;

-- Q2. Check duplicate primary keys
SELECT customer_id, COUNT(*) FROM customers
GROUP BY customer_id HAVING COUNT(*) > 1;

-- Q3. Check accounts referencing missing customers
SELECT a.account_id
FROM accounts a
LEFT JOIN customers c ON c.customer_id = a.customer_id
WHERE c.customer_id IS NULL;

-- Q4. Check transactions referencing missing accounts
SELECT t.transaction_id
FROM transactions t
LEFT JOIN accounts a ON a.account_id = t.account_id
WHERE a.account_id IS NULL;

-- Q5. Check invalid amounts
SELECT COUNT(*) AS invalid_amounts
FROM transactions
WHERE amount < 0;

-- Q6. Check invalid directions
SELECT direction, COUNT(*)
FROM transactions
GROUP BY direction
ORDER BY direction;

-- Q7. Transaction date range
SELECT MIN(posted_at) AS first_transaction,
       MAX(posted_at) AS last_transaction
FROM transactions;

-- Q8. Accounts with invalid close/open dates
SELECT account_id, opened_on, closed_on
FROM accounts
WHERE closed_on IS NOT NULL
  AND closed_on < opened_on;

-- Q9. Customers without accounts
SELECT COUNT(*) AS customers_without_accounts
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
WHERE a.account_id IS NULL;

-- Q10. Accounts without transactions
SELECT COUNT(*) AS accounts_without_transactions
FROM accounts a
LEFT JOIN transactions t ON t.account_id = a.account_id
WHERE t.transaction_id IS NULL;
