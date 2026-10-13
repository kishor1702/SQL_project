# Final Insights Framework

Run `sql/03_beginner_questions.sql`, `sql/04_intermediate_questions.sql` and
`sql/05_advanced_questions.sql` in PostgreSQL and capture the actual result values
before publishing numeric claims.

## Expected insight categories

### 1. High-value customers
Use Q22, Q23, Q40 and Q45 to identify customers with high transaction value,
multiple accounts and sustained activity. These customers are candidates for
relationship-management programs, premium products and retention offers.

### 2. Inactive accounts
Use Q24 to identify open accounts without activity for 90+ days. Break them down by
account type and branch to determine whether inactivity is concentrated in specific
products or locations.

### 3. Transaction trends
Use Q16, Q17, Q26, Q36 and Q37 to identify:
- peak transaction months
- strongest/weakest net-flow periods
- changes in active-customer count
- month-over-month growth/decline
- cumulative money flow

### 4. Branch performance
Use Q18, Q19, Q30, Q34 and Q41. Do not judge branches on transaction value alone.
Compare customers, accounts, transactions, value per customer and share of bank-wide
value.

### 5. Risk and engagement
Use Q28 and Q40 to compare risk bands with transaction behavior. A high-value customer
with declining activity is more strategically important than a low-value dormant
customer.

### 6. Operational recommendations

1. Create a high-value customer watchlist from the top-ranked customer segment.
2. Launch a 90-day reactivation workflow for inactive open accounts.
3. Monitor monthly net flow and transaction value with an executive trend report.
4. Benchmark low-performing branches against top-ranked branches.
5. Prioritize digital channels where transaction adoption is strong, while retaining
   branch support for customers who depend on assisted service.
6. Review unusually repeated card payments as potential duplicate-charge signals.
7. Revisit segmentation thresholds quarterly using business targets rather than
   treating portfolio thresholds as permanent rules.

## Portfolio note

Do not fabricate numeric insights. After running the SQL against the downloaded
dataset, replace this document with the actual top customers, top branches, inactive
account counts and monthly trend values.
