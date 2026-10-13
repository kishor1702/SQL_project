# Business Questions

| # | Business question | SQL technique |
|---|---|---|
| 1 | What are total orders, units and revenue? | Aggregation |
| 2 | What is monthly revenue? | DATE_TRUNC |
| 3 | What are the top products by revenue? | JOIN + GROUP BY |
| 4 | Which products sell the most units? | Aggregation |
| 5 | Which categories generate the most revenue? | JOIN |
| 6 | What is average order value? | Aggregation |
| 7 | Which regions perform best? | JOIN + GROUP BY |
| 8 | How many unique customers purchased? | COUNT DISTINCT |
| 9 | What are average prices by category? | JOIN |
| 10 | Which customers generate the most revenue? | GROUP BY |
| 11 | How does each store perform monthly? | JOIN + DATE_TRUNC |
| 12 | Which products outperform average revenue? | Subquery |
| 13 | How can products be classified by volume? | CASE |
| 14 | Which customers place more than 5 orders? | HAVING |
| 15 | How many customers are repeat buyers? | CTE + CASE |
| 16 | What are monthly orders and AOV? | CTE |
| 17 | Which products are high-volume but low-value? | HAVING |
| 18 | Which customers became inactive? | Date arithmetic |
| 19 | What percentage of revenue comes from each customer? | Conditional contribution |
| 20 | What percentage of revenue comes from each category? | Window function |
| 21 | How do stores rank by revenue? | RANK |
| 22 | How do products rank within categories? | DENSE_RANK |
| 23 | What are the top 3 products in each category? | ROW_NUMBER |
| 24 | What is month-over-month growth? | LAG |
| 25 | What is next month's revenue? | LEAD |
| 26 | What is cumulative revenue? | Running total |
| 27 | What is cumulative revenue by store? | Partitioned running total |
| 28 | Which products drive the first 80% of revenue? | Pareto |
| 29 | Which customers are top-decile value customers? | NTILE |
| 30 | How can customers be segmented with RFM? | CTE + NTILE + CASE |
| 31 | Which products are slow-moving with remaining stock? | Inventory JOIN |
| 32 | Which products are out of stock? | Inventory filter |
| 33 | Which products need replenishment? | Inventory filter |
| 34 | How many months of stock cover remain? | CTE + calculation |
| 35 | Which products have strong monthly growth? | LAG |
| 36 | Which store wins each month? | RANK + CTE |
| 37 | Which customers beat their country average? | CTE + JOIN |
| 38 | How are orders distributed by value? | CASE |
| 39 | Which products contribute most within category? | Window percentage |
| 40 | What should an executive KPI scorecard show? | CTE + FILTER |

## Recommended business actions

1. **Prioritize high-value customers:** Build retention campaigns around Champions and Loyal segments.
2. **Protect top products:** Products in the top revenue contribution tiers deserve stronger replenishment controls.
3. **Reduce dead stock:** Review slow-moving products for bundles, promotions, markdowns or assortment rationalization.
4. **Use regional performance:** Allocate marketing and inventory planning according to store/region revenue and growth.
5. **Monitor stock risk:** Reorder products below the derived reorder threshold and investigate recurring stock-outs.
6. **Track monthly growth:** Use MoM revenue and product growth to identify emerging demand before it becomes a large inventory problem.
7. **Manage the long tail:** Products contributing little revenue but consuming inventory should be reviewed regularly.
8. **Increase AOV:** Test cross-sell bundles around high-volume, low-realized-price products.
