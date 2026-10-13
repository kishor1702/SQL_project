-- 03_beginner_questions.sql
-- Beginner SQL: SELECT, WHERE, JOIN, GROUP BY, HAVING, CASE

-- Q1. How many customers are there?
SELECT COUNT(*) AS total_customers FROM customers;

-- Q2. How many branches are there?
SELECT COUNT(*) AS total_branches FROM branches;

-- Q3. How many accounts are open?
SELECT COUNT(*) AS open_accounts
FROM accounts
WHERE closed_on IS NULL;

-- Q4. Count accounts by account type.
SELECT account_type, COUNT(*) AS account_count
FROM accounts
GROUP BY account_type
ORDER BY account_count DESC;

-- Q5. Count customers by risk band.
SELECT COALESCE(risk_band, 'Not Assessed') AS risk_band,
       COUNT(*) AS customers
FROM customers
GROUP BY COALESCE(risk_band, 'Not Assessed')
ORDER BY customers DESC;

-- Q6. Count transactions by direction.
SELECT direction, COUNT(*) AS transaction_count,
       ROUND(SUM(amount),2) AS total_amount
FROM transactions
GROUP BY direction
ORDER BY total_amount DESC;

-- Q7. Average transaction amount by channel.
SELECT channel,
       COUNT(*) AS transactions,
       ROUND(AVG(amount),2) AS avg_amount
FROM transactions
GROUP BY channel
ORDER BY avg_amount DESC;

-- Q8. Total transaction value by transaction type.
SELECT transaction_type,
       COUNT(*) AS transactions,
       ROUND(SUM(amount),2) AS total_value
FROM transactions
GROUP BY transaction_type
ORDER BY total_value DESC;

-- Q9. List customers with their home branch. INNER JOIN.
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       b.branch_name,
       b.city
FROM customers c
INNER JOIN branches b ON b.branch_id = c.home_branch_id
ORDER BY c.customer_id
LIMIT 25;

-- Q10. Show all customers including those without accounts. LEFT JOIN.
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS customer_name,
       COUNT(a.account_id) AS account_count
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY account_count DESC, c.customer_id;

-- Q11. Branches with more than 300 customers. HAVING.
SELECT b.branch_id,
       b.branch_name,
       COUNT(c.customer_id) AS customers
FROM branches b
LEFT JOIN customers c ON c.home_branch_id = b.branch_id
GROUP BY b.branch_id, b.branch_name
HAVING COUNT(c.customer_id) > 300
ORDER BY customers DESC;

-- Q12. Categorize accounts as Open/Closed using CASE WHEN.
SELECT account_id,
       account_type,
       CASE WHEN closed_on IS NULL THEN 'Open' ELSE 'Closed' END AS status
FROM accounts
ORDER BY account_id
LIMIT 50;

-- Q13. Find high-value individual transactions.
SELECT transaction_id, account_id, posted_at, direction, amount, channel
FROM transactions
WHERE amount >= (
    SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY amount)
    FROM transactions
)
ORDER BY amount DESC;

-- Q14. Customers with no accounts using NOT EXISTS.
SELECT c.customer_id,
       c.first_name || ' ' || c.last_name AS customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM accounts a
    WHERE a.customer_id = c.customer_id
)
ORDER BY c.customer_id;

-- Q15. Top 20 accounts by total transaction value.
SELECT a.account_id,
       a.account_type,
       ROUND(SUM(t.amount),2) AS transaction_value
FROM accounts a
INNER JOIN transactions t ON t.account_id = a.account_id
GROUP BY a.account_id, a.account_type
ORDER BY transaction_value DESC
LIMIT 20;
