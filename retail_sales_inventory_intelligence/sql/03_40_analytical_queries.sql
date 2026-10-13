-- 03_40_analytical_queries.sql
-- Retail Sales & Inventory Intelligence
-- All queries are PostgreSQL-compatible.

-- ============================================================
-- BEGINNER
-- ============================================================

-- Q01. What are total sales, units and orders?
SELECT COUNT(DISTINCT order_id) AS orders,
       SUM(quantity) AS units,
       SUM(line_amount) AS revenue
FROM vw_sales;

-- Q02. What is monthly revenue?
SELECT DATE_TRUNC('month', order_date)::date AS month,
       ROUND(SUM(line_amount),2) AS revenue
FROM vw_sales
GROUP BY 1
ORDER BY 1;

-- Q03. What are the top 10 products by revenue?
SELECT p.product_id, p.product_name,
       ROUND(SUM(v.line_amount),2) AS revenue
FROM vw_sales v
JOIN products p ON p.product_id = v.product_id
GROUP BY p.product_id, p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- Q04. Which products sold the most units?
SELECT p.product_id, p.product_name, SUM(v.quantity) AS units_sold
FROM vw_sales v
JOIN products p ON p.product_id = v.product_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC
LIMIT 10;

-- Q05. Which categories generate the most revenue?
SELECT c.category_name, ROUND(SUM(v.line_amount),2) AS revenue
FROM vw_sales v
JOIN categories c ON c.category_id = v.category_id
GROUP BY c.category_name
ORDER BY revenue DESC;

-- Q06. What is average order value?
SELECT ROUND(SUM(line_amount) / NULLIF(COUNT(DISTINCT order_id),0),2) AS avg_order_value
FROM vw_sales;

-- Q07. Which countries/regions have the highest revenue?
SELECT s.region, ROUND(SUM(v.line_amount),2) AS revenue
FROM vw_sales v
JOIN stores s ON s.store_id = v.store_id
GROUP BY s.region
ORDER BY revenue DESC;

-- Q08. How many unique customers purchased?
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM vw_sales
WHERE customer_id IS NOT NULL;

-- Q09. What are average product prices by category?
SELECT c.category_name, ROUND(AVG(p.unit_price),2) AS avg_price
FROM products p
JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY avg_price DESC;

-- Q10. Which customers generated the most revenue?
SELECT customer_id, ROUND(SUM(line_amount),2) AS revenue
FROM vw_sales
WHERE customer_id IS NOT NULL
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 20;

-- ============================================================
-- INTERMEDIATE
-- ============================================================

-- Q11. Revenue by store/virtual region and month.
SELECT s.store_name,
       DATE_TRUNC('month', v.order_date)::date AS month,
       ROUND(SUM(v.line_amount),2) AS revenue
FROM vw_sales v
JOIN stores s ON s.store_id = v.store_id
GROUP BY s.store_name, 2
ORDER BY 2, revenue DESC;

-- Q12. Products with revenue above the average product revenue.
SELECT product_id, revenue
FROM (
    SELECT product_id, SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY product_id
) x
WHERE revenue > (SELECT AVG(revenue)
                 FROM (
                     SELECT product_id, SUM(line_amount) AS revenue
                     FROM vw_sales
                     GROUP BY product_id
                 ) a)
ORDER BY revenue DESC;

-- Q13. CASE: classify products by sales volume.
SELECT p.product_id, p.product_name,
       SUM(v.quantity) AS units_sold,
       CASE
         WHEN SUM(v.quantity) >= 1000 THEN 'High Volume'
         WHEN SUM(v.quantity) >= 250 THEN 'Medium Volume'
         ELSE 'Low Volume'
       END AS volume_segment
FROM vw_sales v
JOIN products p ON p.product_id = v.product_id
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC;

-- Q14. Customers with more than 5 orders.
SELECT customer_id,
       COUNT(DISTINCT order_id) AS order_count,
       ROUND(SUM(line_amount),2) AS revenue
FROM vw_sales
WHERE customer_id IS NOT NULL
GROUP BY customer_id
HAVING COUNT(DISTINCT order_id) > 5
ORDER BY revenue DESC;

-- Q15. Repeat vs one-time customers.
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS orders
    FROM vw_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT CASE WHEN orders = 1 THEN 'One-time' ELSE 'Repeat' END AS segment,
       COUNT(*) AS customers
FROM customer_orders
GROUP BY 1
ORDER BY 2 DESC;

-- Q16. Monthly order count and average order value.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           COUNT(DISTINCT order_id) AS orders,
           SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY 1
)
SELECT month, orders,
       ROUND(revenue,2) AS revenue,
       ROUND(revenue / NULLIF(orders,0),2) AS avg_order_value
FROM monthly
ORDER BY month;

-- Q17. Products with high units but low revenue per unit.
SELECT p.product_id, p.product_name,
       SUM(v.quantity) AS units,
       ROUND(SUM(v.line_amount)/NULLIF(SUM(v.quantity),0),2) AS realized_price
FROM vw_sales v
JOIN products p ON p.product_id = v.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(v.quantity) > 250
   AND SUM(v.line_amount)/NULLIF(SUM(v.quantity),0) < 2
ORDER BY units DESC;

-- Q18. Customers with no activity in the final 90 days of the dataset.
WITH max_date AS (SELECT MAX(order_date)::date AS d FROM orders),
last_orders AS (
    SELECT customer_id, MAX(order_date)::date AS last_order
    FROM orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT l.customer_id, l.last_order
FROM last_orders l
CROSS JOIN max_date m
WHERE l.last_order < m.d - INTERVAL '90 days'
ORDER BY l.last_order;

-- Q19. Customer revenue and customer share of total revenue.
WITH customer_sales AS (
    SELECT customer_id, SUM(line_amount) AS revenue
    FROM vw_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
total AS (SELECT SUM(revenue) AS total_revenue FROM customer_sales)
SELECT customer_id,
       ROUND(revenue,2) AS revenue,
       ROUND(100 * revenue / NULLIF(total_revenue,0),2) AS revenue_pct
FROM customer_sales CROSS JOIN total
ORDER BY revenue DESC;

-- Q20. Category contribution to total revenue.
WITH cat_sales AS (
    SELECT category_id, SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY category_id
)
SELECT c.category_name,
       ROUND(cs.revenue,2) AS revenue,
       ROUND(100 * cs.revenue / SUM(cs.revenue) OVER (),2) AS pct_contribution
FROM cat_sales cs
JOIN categories c ON c.category_id = cs.category_id
ORDER BY revenue DESC;

-- Q21. Store ranking by revenue.
SELECT s.store_name,
       ROUND(SUM(v.line_amount),2) AS revenue,
       RANK() OVER (ORDER BY SUM(v.line_amount) DESC) AS revenue_rank
FROM vw_sales v
JOIN stores s ON s.store_id = v.store_id
GROUP BY s.store_name
ORDER BY revenue_rank;

-- Q22. Product ranking within category using DENSE_RANK.
SELECT c.category_name, p.product_name,
       ROUND(SUM(v.line_amount),2) AS revenue,
       DENSE_RANK() OVER (
           PARTITION BY c.category_id
           ORDER BY SUM(v.line_amount) DESC
       ) AS category_rank
FROM vw_sales v
JOIN products p ON p.product_id = v.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name, p.product_id, p.product_name
ORDER BY c.category_name, category_rank;

-- Q23. Top 3 products in every category using ROW_NUMBER.
WITH ranked AS (
    SELECT c.category_name, p.product_id, p.product_name,
           SUM(v.line_amount) AS revenue,
           ROW_NUMBER() OVER (
               PARTITION BY c.category_id
               ORDER BY SUM(v.line_amount) DESC
           ) AS rn
    FROM vw_sales v
    JOIN products p ON p.product_id = v.product_id
    JOIN categories c ON c.category_id = p.category_id
    GROUP BY c.category_id, c.category_name, p.product_id, p.product_name
)
SELECT category_name, product_id, product_name, ROUND(revenue,2) AS revenue
FROM ranked
WHERE rn <= 3
ORDER BY category_name, revenue DESC;

-- ============================================================
-- ADVANCED
-- ============================================================

-- Q24. Monthly revenue with previous month and MoM growth using LAG.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY 1
),
lagged AS (
    SELECT month, revenue,
           LAG(revenue) OVER (ORDER BY month) AS prev_revenue
    FROM monthly
)
SELECT month,
       ROUND(revenue,2) AS revenue,
       ROUND(prev_revenue,2) AS prev_revenue,
       ROUND(100*(revenue-prev_revenue)/NULLIF(prev_revenue,0),2) AS mom_growth_pct
FROM lagged
ORDER BY month;

-- Q25. Next month's revenue using LEAD.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY 1
)
SELECT month, ROUND(revenue,2) AS revenue,
       ROUND(LEAD(revenue) OVER (ORDER BY month),2) AS next_month_revenue
FROM monthly
ORDER BY month;

-- Q26. Running total of monthly revenue.
WITH monthly AS (
    SELECT DATE_TRUNC('month', order_date)::date AS month,
           SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY 1
)
SELECT month,
       ROUND(revenue,2) AS monthly_revenue,
       ROUND(SUM(revenue) OVER (
           ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ),2) AS running_revenue
FROM monthly
ORDER BY month;

-- Q27. Running revenue by store.
WITH monthly_store AS (
    SELECT store_id, DATE_TRUNC('month', order_date)::date AS month,
           SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY store_id, 2
)
SELECT s.store_name, ms.month,
       ROUND(ms.revenue,2) AS revenue,
       ROUND(SUM(ms.revenue) OVER (
           PARTITION BY ms.store_id ORDER BY ms.month
       ),2) AS store_running_revenue
FROM monthly_store ms
JOIN stores s ON s.store_id = ms.store_id
ORDER BY s.store_name, ms.month;

-- Q28. Pareto analysis: cumulative percentage of product revenue.
WITH product_sales AS (
    SELECT product_id, SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY product_id
),
pareto AS (
    SELECT product_id, revenue,
           SUM(revenue) OVER (ORDER BY revenue DESC) /
           NULLIF(SUM(revenue) OVER (),0) AS cumulative_pct
    FROM product_sales
)
SELECT p.product_id, p.product_name,
       ROUND(pa.revenue,2) AS revenue,
       ROUND(100*pa.cumulative_pct,2) AS cumulative_pct,
       CASE WHEN pa.cumulative_pct <= 0.80 THEN 'Top 80% revenue set'
            ELSE 'Long tail' END AS pareto_group
FROM pareto pa
JOIN products p ON p.product_id = pa.product_id
ORDER BY pa.revenue DESC;

-- Q29. High-value customers using percentile ranking.
WITH customer_sales AS (
    SELECT customer_id, SUM(line_amount) AS revenue
    FROM vw_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT customer_id, ROUND(revenue,2) AS revenue,
       NTILE(10) OVER (ORDER BY revenue DESC) AS decile
FROM customer_sales
ORDER BY revenue DESC;

-- Q30. RFM-style customer segmentation.
WITH snapshot AS (SELECT MAX(order_date)::date AS d FROM orders),
rfm AS (
    SELECT customer_id,
           (SELECT d FROM snapshot) - MAX(order_date)::date AS recency_days,
           COUNT(DISTINCT order_id) AS frequency,
           SUM(line_amount) AS monetary
    FROM vw_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
scored AS (
    SELECT *,
       NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
       NTILE(5) OVER (ORDER BY frequency) AS f_score,
       NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm
)
SELECT customer_id, recency_days, frequency, ROUND(monetary,2) AS monetary,
       r_score, f_score, m_score,
       CASE
         WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
         WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
         WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
         WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
         ELSE 'Potential'
       END AS segment
FROM scored
ORDER BY monetary DESC;

-- Q31. Slow-moving products: low unit velocity but meaningful stock.
WITH product_velocity AS (
    SELECT product_id, SUM(quantity) AS units_sold
    FROM vw_sales
    GROUP BY product_id
)
SELECT p.product_id, p.product_name,
       pv.units_sold,
       SUM(i.closing_stock) AS closing_stock
FROM product_velocity pv
JOIN products p ON p.product_id = pv.product_id
JOIN inventory i ON i.product_id = pv.product_id
GROUP BY p.product_id, p.product_name, pv.units_sold
HAVING pv.units_sold < 100
   AND SUM(i.closing_stock) > 0
ORDER BY closing_stock DESC, units_sold;

-- Q32. Stock-outs by store and product.
SELECT s.store_name, p.product_name,
       i.snapshot_date, i.closing_stock, i.reorder_level
FROM inventory i
JOIN stores s ON s.store_id = i.store_id
JOIN products p ON p.product_id = i.product_id
WHERE i.stock_status = 'OUT_OF_STOCK'
ORDER BY s.store_name, p.product_name;

-- Q33. Low-stock products.
SELECT s.store_name, p.product_name,
       i.closing_stock, i.reorder_level
FROM inventory i
JOIN stores s ON s.store_id = i.store_id
JOIN products p ON p.product_id = i.product_id
WHERE i.stock_status = 'LOW_STOCK'
ORDER BY (i.reorder_level - i.closing_stock) DESC;

-- Q34. Inventory coverage proxy based on monthly sales velocity.
WITH velocity AS (
    SELECT store_id, product_id,
           SUM(quantity)::numeric / NULLIF(COUNT(DISTINCT DATE_TRUNC('month',order_date)),0) AS monthly_units
    FROM vw_sales
    GROUP BY store_id, product_id
)
SELECT s.store_name, p.product_name,
       i.closing_stock,
       ROUND(v.monthly_units,2) AS avg_monthly_units,
       ROUND(i.closing_stock / NULLIF(v.monthly_units,0),2) AS months_of_cover
FROM inventory i
JOIN velocity v USING (store_id, product_id)
JOIN stores s ON s.store_id = i.store_id
JOIN products p ON p.product_id = i.product_id
WHERE v.monthly_units > 0
ORDER BY months_of_cover NULLS LAST;

-- Q35. Month-over-month product growth.
WITH monthly_product AS (
    SELECT product_id,
           DATE_TRUNC('month', order_date)::date AS month,
           SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY product_id, 2
),
x AS (
    SELECT *,
           LAG(revenue) OVER (PARTITION BY product_id ORDER BY month) AS prev_revenue
    FROM monthly_product
)
SELECT p.product_name, month,
       ROUND(revenue,2) AS revenue,
       ROUND(100*(revenue-prev_revenue)/NULLIF(prev_revenue,0),2) AS growth_pct
FROM x
JOIN products p ON p.product_id = x.product_id
WHERE prev_revenue IS NOT NULL
ORDER BY growth_pct DESC NULLS LAST
LIMIT 50;

-- Q36. Best-performing store for each month.
WITH monthly_store AS (
    SELECT store_id, DATE_TRUNC('month', order_date)::date AS month,
           SUM(line_amount) AS revenue
    FROM vw_sales
    GROUP BY store_id, 2
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY month ORDER BY revenue DESC) AS rnk
    FROM monthly_store
)
SELECT month, s.store_name, ROUND(revenue,2) AS revenue
FROM ranked r
JOIN stores s ON s.store_id = r.store_id
WHERE rnk = 1
ORDER BY month;

-- Q37. Customers whose revenue exceeds their country's average customer revenue.
WITH customer_country AS (
    SELECT customer_id, country, SUM(line_amount) AS revenue
    FROM vw_sales v
    JOIN customers c USING (customer_id)
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, country
),
country_avg AS (
    SELECT country, AVG(revenue) AS avg_customer_revenue
    FROM customer_country
    GROUP BY country
)
SELECT cc.customer_id, cc.country,
       ROUND(cc.revenue,2) AS revenue,
       ROUND(ca.avg_customer_revenue,2) AS country_avg
FROM customer_country cc
JOIN country_avg ca USING (country)
WHERE cc.revenue > ca.avg_customer_revenue
ORDER BY cc.revenue DESC;

-- Q38. Order value segmentation using CASE.
WITH orders AS (
    SELECT order_id, SUM(line_amount) AS order_value
    FROM vw_sales
    GROUP BY order_id
)
SELECT CASE
         WHEN order_value < 25 THEN 'Small'
         WHEN order_value < 100 THEN 'Medium'
         WHEN order_value < 500 THEN 'Large'
         ELSE 'Very Large'
       END AS order_segment,
       COUNT(*) AS orders,
       ROUND(AVG(order_value),2) AS avg_order_value,
       ROUND(SUM(order_value),2) AS revenue
FROM orders
GROUP BY 1
ORDER BY revenue DESC;

-- Q39. Product revenue contribution within each category.
WITH product_category AS (
    SELECT p.category_id, p.product_id, p.product_name,
           SUM(v.line_amount) AS revenue
    FROM vw_sales v
    JOIN products p ON p.product_id = v.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
)
SELECT c.category_name, pc.product_name,
       ROUND(pc.revenue,2) AS revenue,
       ROUND(100 * pc.revenue /
             NULLIF(SUM(pc.revenue) OVER (PARTITION BY pc.category_id),0),2)
             AS category_revenue_pct
FROM product_category pc
JOIN categories c ON c.category_id = pc.category_id
ORDER BY c.category_name, revenue DESC;

-- Q40. Executive KPI scorecard.
WITH base AS (
    SELECT
      COUNT(DISTINCT order_id) AS orders,
      COUNT(DISTINCT customer_id) FILTER (WHERE customer_id IS NOT NULL) AS customers,
      SUM(quantity) AS units,
      SUM(line_amount) AS revenue
    FROM vw_sales
),
stock AS (
    SELECT
      COUNT(*) FILTER (WHERE stock_status='OUT_OF_STOCK') AS stockouts,
      COUNT(*) FILTER (WHERE stock_status='LOW_STOCK') AS low_stock
    FROM inventory
)
SELECT orders, customers, units,
       ROUND(revenue,2) AS revenue,
       ROUND(revenue/NULLIF(orders,0),2) AS avg_order_value,
       stockouts, low_stock
FROM base CROSS JOIN stock;

-- ============================================================
-- OPTIONAL DATA QUALITY CHECKS
-- ============================================================

-- DQ1. Null customer rate.
SELECT ROUND(
  100.0 * COUNT(*) FILTER (WHERE customer_id IS NULL) / COUNT(*), 2
) AS null_customer_pct
FROM orders;

-- DQ2. Duplicate order IDs.
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- DQ3. Negative or zero quantities in the final sales view.
SELECT COUNT(*) AS invalid_rows
FROM vw_sales
WHERE quantity <= 0 OR unit_price <= 0;

-- DQ4. Products with no sales.
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN vw_sales v ON v.product_id = p.product_id
WHERE v.product_id IS NULL;
