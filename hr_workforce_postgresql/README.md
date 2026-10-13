# HR Workforce Analytics — PostgreSQL

A GitHub-ready SQL portfolio project for analyzing workforce structure, compensation, attendance, leave utilization, performance, promotions and employee attrition using PostgreSQL.

## 1. Business Problem

HR teams need to understand:

- Where headcount is concentrated
- How salaries vary by department, role and employee level
- Which employee groups show higher attrition
- Whether tenure, overtime, satisfaction and attendance are associated with attrition
- Which employees are strong promotion candidates
- How performance changes over time
- Which departments have salary or retention risks

## 2. Dataset

**Primary source:** IBM HR Analytics Employee Attrition & Performance, published on Kaggle by pavansubhasht.

The source dataset contains 1,470 employee records and 35 fields covering demographics, job information, compensation, satisfaction, performance and attrition. IBM describes it as a fictional dataset created by IBM data scientists.

Dataset page:
https://www.kaggle.com/datasets/pavansubhasht/ibm-hr-analytics-attrition-dataset

A public GitHub copy of the CSV is also available:
https://github.com/shantanu1109/IBM-HR-Analytics-Employee-Attrition-and-Performance-Prediction/blob/main/DATASET/IBM-HR-Analytics-Employee-Attrition-and-Performance.csv

### Data honesty / modeling note

The source dataset does **not** contain true attendance records, leave transactions, historical salary snapshots, hire dates, or dated multi-year performance reviews.

To make the SQL portfolio project relational and suitable for advanced SQL practice:

- `employees` is normalized from the source CSV.
- `departments` is derived from the source department values.
- `salaries`, `attendance`, `leaves`, and multi-period `performance_reviews` are **synthetic analytical extensions** generated deterministically from source employee attributes.
- Do not present synthetic records as real company HR history.

## 3. Schema

```text
departments
    │
    └──< employees
             ├──< salaries
             ├──< attendance
             ├──< leaves
             └──< performance_reviews
```

### Tables

| Table | Purpose |
|---|---|
| departments | Department master |
| employees | Employee master and source HR attributes |
| salaries | Salary history / compensation snapshots |
| attendance | Daily attendance extension |
| leaves | Leave transactions |
| performance_reviews | Annual performance-review extension |

## 4. SQL Skills Demonstrated

This project contains **50 business questions** covering:

- SELECT / WHERE / ORDER BY
- INNER JOIN / LEFT JOIN
- GROUP BY / HAVING
- CASE WHEN
- Conditional aggregation
- Subqueries
- CTEs
- Date functions
- DATE_TRUNC
- DATE arithmetic
- ROW_NUMBER
- RANK
- DENSE_RANK
- PERCENT_RANK
- LAG / LEAD-style time analysis
- FIRST_VALUE / LAST_VALUE
- Running averages
- Running contribution percentages
- Top-N per department
- Year-over-year salary change
- Performance trends
- Attrition analysis
- Salary benchmarking
- Attendance and leave analysis

## 5. Project Structure

```text
hr-workforce-postgresql/
│
├── README.md
├── sql/
│   ├── schema.sql
│   ├── load_and_transform.sql
│   └── hr_workforce_queries.sql
│
└── docs/
    └── data_dictionary.md
```

## 6. Setup

### Step 1 — Create PostgreSQL database

```sql
CREATE DATABASE hr_workforce_analytics;
```

Connect to it:

```bash
psql -d hr_workforce_analytics
```

### Step 2 — Create schema

```bash
psql -d hr_workforce_analytics -f sql/schema.sql
```

### Step 3 — Download the CSV

Download `WA_Fn-UseC_-HR-Employee-Attrition.csv` from the Kaggle dataset page.

### Step 4 — Load and normalize

Open `sql/load_and_transform.sql`.

Create the staging table, then use psql's `\copy` command:

```sql
\copy stg_hr_ibm FROM 'WA_Fn-UseC_-HR-Employee-Attrition.csv' CSV HEADER
```

Then execute the remaining INSERT statements in the file.

### Step 5 — Run analytics

```bash
psql -d hr_workforce_analytics -f sql/hr_workforce_queries.sql
```

## 7. Portfolio Questions

### Workforce
1. What is headcount by department?
2. Which departments have the highest average salary?
3. What is the salary distribution?
4. How many employees fall into each tenure band?
5. Which roles have the highest average compensation?

### Attrition
6. What is the overall attrition rate?
7. Which departments have the highest attrition?
8. Which job roles have the highest attrition?
9. Does overtime correlate with attrition?
10. Does tenure correlate with attrition?

### Compensation
11. Who earns above the company average?
12. Who earns above their department average?
13. Who is the highest-paid employee?
14. What is each employee's salary rank?
15. What is the year-over-year salary change?
16. Which departments account for the largest share of payroll?

### Attendance & Leave
17. What is the overall attendance rate?
18. Which department has the lowest attendance?
19. Which employees have the most absence days?
20. Which departments have the highest late-arrival rate?
21. Which leave types are used most?
22. Which employees use unusually high amounts of leave?

### Performance & Promotions
23. What is the performance distribution?
24. Which departments have the strongest average performance?
25. Does performance differ between leavers and retained employees?
26. Which employees are promotion eligible?
27. Who are the top performers?
28. Who has improved performance year over year?

### Advanced SQL
29. Top 3 employees by salary per department
30. Salary ranking within department
31. Dense salary ranking
32. Salary percentile by department
33. Running average salary
34. Company-wide year-over-year salary growth
35. Performance trend using LAG
36. Latest review using ROW_NUMBER
37. Top 2 performers per department
38. Salary contribution percentage
39. High-performance / low-pay employees
40. High-risk retention segment
41. Attendance vs attrition
42. Leave vs performance
43. Department salary gap vs company average
44. Monthly attendance trend
45. Monthly leave trend
46. Role-level attrition scorecard
47–50. Additional ranking, benchmarking and conditional aggregation questions are included in the SQL file.

## 8. Example Executive Insights to Look For

After running the queries, the analyst should be able to answer questions such as:

- Which departments combine high attrition with low attendance?
- Are employees with frequent overtime more likely to leave?
- Are high-performing employees being paid below their department benchmark?
- Which roles have a high concentration of employees waiting multiple years for promotion?
- Which departments contribute the largest share of payroll?
- Are performance ratings improving or declining over time?
- Which employees belong to a high-risk retention segment?

Do not hard-code these conclusions in the portfolio. Generate the actual findings from the database output.

## 9. Recommended GitHub Presentation

Add screenshots of:

1. ER diagram
2. PostgreSQL table structure
3. Department headcount query
4. Attrition by department
5. Salary ranking
6. Top-N employees per department
7. YOY salary analysis
8. Performance trend
9. Attendance/leave analysis

## 10. Resume Bullet

> **HR Workforce Analytics — PostgreSQL:** Designed a normalized HR analytics database covering employees, departments, salaries, attendance, leaves and performance reviews; developed 50+ PostgreSQL queries using CTEs, subqueries, CASE logic, date functions and window functions to analyze compensation, tenure, performance, promotions, attendance and attrition.

## 11. Interview Talking Points

Be ready to explain:

- Why the employee table is separated from department and transaction/event tables
- When to use `RANK()` vs `DENSE_RANK()` vs `ROW_NUMBER()`
- How `LAG()` calculates year-over-year change
- How to solve Top-N per department
- Why a CTE improves readability
- How conditional aggregation calculates attrition rates
- Why synthetic extensions must be disclosed
- How you would replace synthetic attendance/leave data with production HRIS data

## 12. Limitations

This is a portfolio analytics project, not an actual HRIS. The source dataset is fictional and the attendance, leave, salary-history and multi-period review tables are synthetic extensions. Real production analysis should use validated HRIS/payroll/timekeeping data and documented definitions for headcount, attrition, attendance and leave.
