-- HR Workforce Analytics: 50 PostgreSQL Business Questions
-- Assumes schema.sql + load_and_transform.sql have been executed.

-- 01. Employee count by department
SELECT d.department_name, COUNT(*) AS employee_count
FROM employees e JOIN departments d USING(department_id)
GROUP BY d.department_name ORDER BY employee_count DESC;

-- 02. Department headcount with average salary
SELECT d.department_name, COUNT(DISTINCT e.employee_id) AS headcount,
       ROUND(AVG(s.monthly_salary),2) AS avg_monthly_salary
FROM departments d
JOIN employees e USING(department_id)
JOIN salaries s USING(employee_id)
GROUP BY d.department_name ORDER BY headcount DESC;

-- 03. Average salary by job role
SELECT job_role, ROUND(AVG(s.monthly_salary),2) AS avg_salary
FROM employees e JOIN salaries s USING(employee_id)
GROUP BY job_role ORDER BY avg_salary DESC;

-- 04. Salary distribution bands
SELECT CASE
         WHEN s.monthly_salary < 3000 THEN '< 3K'
         WHEN s.monthly_salary < 6000 THEN '3K-6K'
         WHEN s.monthly_salary < 10000 THEN '6K-10K'
         ELSE '10K+'
       END AS salary_band, COUNT(*) AS employees
FROM salaries s
WHERE s.effective_date = DATE '2024-01-01'
GROUP BY 1 ORDER BY MIN(s.monthly_salary);

-- 05. Tenure bands
SELECT CASE
         WHEN years_at_company < 2 THEN '<2 years'
         WHEN years_at_company < 5 THEN '2-4 years'
         WHEN years_at_company < 10 THEN '5-9 years'
         ELSE '10+ years'
       END AS tenure_band, COUNT(*) AS employees
FROM employees GROUP BY 1 ORDER BY MIN(years_at_company);

-- 06. Overall attrition rate
SELECT ROUND(100.0 * AVG(attrition::int),2) AS attrition_rate_pct
FROM employees;

-- 07. Attrition by department
SELECT d.department_name,
       COUNT(*) AS headcount,
       SUM(e.attrition::int) AS leavers,
       ROUND(100.0*AVG(e.attrition::int),2) AS attrition_rate_pct
FROM employees e JOIN departments d USING(department_id)
GROUP BY d.department_name ORDER BY attrition_rate_pct DESC;

-- 08. Attrition by job role
SELECT job_role, COUNT(*) headcount,
       ROUND(100.0*AVG(attrition::int),2) attrition_rate_pct
FROM employees GROUP BY job_role ORDER BY attrition_rate_pct DESC;

-- 09. Attrition by overtime
SELECT overtime, COUNT(*) headcount,
       ROUND(100.0*AVG(attrition::int),2) attrition_rate_pct
FROM employees GROUP BY overtime;

-- 10. Attrition by tenure band
SELECT CASE
         WHEN years_at_company < 2 THEN '<2 years'
         WHEN years_at_company < 5 THEN '2-4 years'
         WHEN years_at_company < 10 THEN '5-9 years'
         ELSE '10+ years'
       END tenure_band,
       ROUND(100.0*AVG(attrition::int),2) attrition_rate_pct
FROM employees GROUP BY 1 ORDER BY MIN(years_at_company);

-- 11. Departments with >10% attrition
SELECT d.department_name, ROUND(100.0*AVG(e.attrition::int),2) attrition_rate
FROM employees e JOIN departments d USING(department_id)
GROUP BY d.department_name
HAVING AVG(e.attrition::int) > 0.10;

-- 12. Employees earning above company average
SELECT e.employee_id, e.job_role, s.monthly_salary
FROM employees e JOIN salaries s USING(employee_id)
WHERE s.effective_date=DATE '2024-01-01'
  AND s.monthly_salary > (
      SELECT AVG(monthly_salary) FROM salaries WHERE effective_date=DATE '2024-01-01'
  )
ORDER BY s.monthly_salary DESC;

-- 13. Employees earning above their department average
SELECT e.employee_id, d.department_name, e.job_role, s.monthly_salary
FROM employees e
JOIN departments d USING(department_id)
JOIN salaries s USING(employee_id)
WHERE s.effective_date=DATE '2024-01-01'
  AND s.monthly_salary > (
      SELECT AVG(s2.monthly_salary)
      FROM employees e2 JOIN salaries s2 USING(employee_id)
      WHERE e2.department_id=e.department_id
        AND s2.effective_date=DATE '2024-01-01'
  );

-- 14. Highest-paid employee
SELECT e.employee_id, e.job_role, s.monthly_salary
FROM employees e JOIN salaries s USING(employee_id)
WHERE s.effective_date=DATE '2024-01-01'
ORDER BY s.monthly_salary DESC LIMIT 1;

-- 15. Employees with no promotion in 3+ years
SELECT employee_id, job_role, years_at_company, years_since_last_promotion
FROM employees
WHERE years_since_last_promotion >= 3
ORDER BY years_since_last_promotion DESC;

-- 16. Promotion-eligible employees
SELECT e.employee_id, d.department_name, e.job_role, pr.rating,
       e.years_since_last_promotion
FROM employees e
JOIN departments d USING(department_id)
JOIN performance_reviews pr USING(employee_id)
WHERE pr.review_date=DATE '2024-12-15'
  AND pr.promotion_eligible
ORDER BY pr.rating DESC, e.years_since_last_promotion DESC;

-- 17. Average attendance rate
SELECT ROUND(100.0*AVG((status IN ('Present','WFH'))::int),2) attendance_rate_pct
FROM attendance;

-- 18. Attendance rate by department
SELECT d.department_name,
       ROUND(100.0*AVG((a.status IN ('Present','WFH'))::int),2) attendance_rate_pct,
       COUNT(*) records
FROM attendance a JOIN employees e USING(employee_id)
JOIN departments d USING(department_id)
GROUP BY d.department_name ORDER BY attendance_rate_pct;

-- 19. Employees with highest absence days
SELECT e.employee_id, e.job_role,
       COUNT(*) FILTER (WHERE a.status='Absent') absent_days
FROM employees e JOIN attendance a USING(employee_id)
GROUP BY e.employee_id, e.job_role
ORDER BY absent_days DESC LIMIT 20;

-- 20. Late-arrival rate by department
SELECT d.department_name,
       ROUND(100.0*AVG((a.status='Late')::int),2) late_rate_pct
FROM attendance a JOIN employees e USING(employee_id)
JOIN departments d USING(department_id)
GROUP BY d.department_name ORDER BY late_rate_pct DESC;

-- 21. Leave days by leave type
SELECT leave_type, SUM(leave_days) total_leave_days, COUNT(*) requests
FROM leaves GROUP BY leave_type ORDER BY total_leave_days DESC;

-- 22. Leave usage by department
SELECT d.department_name, SUM(l.leave_days) leave_days,
       ROUND(AVG(l.leave_days),2) avg_days_per_request
FROM leaves l JOIN employees e USING(employee_id)
JOIN departments d USING(department_id)
GROUP BY d.department_name ORDER BY leave_days DESC;

-- 23. Employees with >8 leave days
SELECT employee_id, SUM(leave_days) leave_days
FROM leaves
WHERE status='Approved'
GROUP BY employee_id
HAVING SUM(leave_days)>8
ORDER BY leave_days DESC;

-- 24. Performance distribution
SELECT rating, COUNT(*) employees
FROM performance_reviews
WHERE review_year=2024
GROUP BY rating ORDER BY rating DESC;

-- 25. Average performance by department
SELECT d.department_name, ROUND(AVG(pr.rating),2) avg_rating
FROM performance_reviews pr
JOIN employees e USING(employee_id)
JOIN departments d USING(department_id)
WHERE pr.review_year=2024
GROUP BY d.department_name ORDER BY avg_rating DESC;

-- 26. Performance vs attrition
SELECT e.attrition, ROUND(AVG(pr.rating),2) avg_rating, COUNT(*) employees
FROM employees e JOIN performance_reviews pr USING(employee_id)
WHERE pr.review_year=2024
GROUP BY e.attrition;

-- 27. Performance CTE: department scorecard
WITH dept AS (
  SELECT d.department_name,
         COUNT(*) employees,
         AVG(pr.rating) avg_rating,
         AVG(e.attrition::int) attrition_rate
  FROM employees e
  JOIN departments d USING(department_id)
  JOIN performance_reviews pr USING(employee_id)
  WHERE pr.review_year=2024
  GROUP BY d.department_name
)
SELECT department_name, employees,
       ROUND(avg_rating,2) avg_rating,
       ROUND(100*attrition_rate,2) attrition_pct
FROM dept ORDER BY avg_rating DESC;

-- 28. Top 3 employees per department by salary
WITH ranked AS (
  SELECT e.employee_id, d.department_name, e.job_role, s.monthly_salary,
         ROW_NUMBER() OVER (
           PARTITION BY e.department_id ORDER BY s.monthly_salary DESC
         ) AS rn
  FROM employees e JOIN departments d USING(department_id)
  JOIN salaries s USING(employee_id)
  WHERE s.effective_date=DATE '2024-01-01'
)
SELECT * FROM ranked WHERE rn<=3 ORDER BY department_name, rn;

-- 29. Salary rank within department
SELECT e.employee_id, d.department_name, s.monthly_salary,
       RANK() OVER (
         PARTITION BY e.department_id ORDER BY s.monthly_salary DESC
       ) salary_rank
FROM employees e JOIN departments d USING(department_id)
JOIN salaries s USING(employee_id)
WHERE s.effective_date=DATE '2024-01-01';

-- 30. Dense rank by salary across company
SELECT employee_id, monthly_salary,
       DENSE_RANK() OVER (ORDER BY monthly_salary DESC) salary_dense_rank
FROM salaries
WHERE effective_date=DATE '2024-01-01';

-- 31. Salary percentile by department
SELECT e.employee_id, d.department_name, s.monthly_salary,
       ROUND(100*PERCENT_RANK() OVER (
         PARTITION BY e.department_id ORDER BY s.monthly_salary
       ),2) percentile_pct
FROM employees e JOIN departments d USING(department_id)
JOIN salaries s USING(employee_id)
WHERE s.effective_date=DATE '2024-01-01';

-- 32. Year-over-year salary change
WITH salary_history AS (
  SELECT employee_id, effective_date, monthly_salary,
         LAG(monthly_salary) OVER (
           PARTITION BY employee_id ORDER BY effective_date
         ) prior_salary
  FROM salaries
)
SELECT employee_id, effective_date, monthly_salary, prior_salary,
       ROUND(100*(monthly_salary-prior_salary)/NULLIF(prior_salary,0),2) yoy_change_pct
FROM salary_history
WHERE prior_salary IS NOT NULL
ORDER BY yoy_change_pct DESC;

-- 33. Running average salary by employee
SELECT employee_id, effective_date, monthly_salary,
       ROUND(AVG(monthly_salary) OVER (
         PARTITION BY employee_id ORDER BY effective_date
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ),2) running_avg_salary
FROM salaries
ORDER BY employee_id, effective_date;

-- 34. Company-wide salary growth by year
WITH yearly AS (
  SELECT EXTRACT(YEAR FROM effective_date)::int year,
         AVG(monthly_salary) avg_salary
  FROM salaries GROUP BY 1
)
SELECT year, ROUND(avg_salary,2) avg_salary,
       ROUND(100*(avg_salary-LAG(avg_salary) OVER(ORDER BY year))
             /NULLIF(LAG(avg_salary) OVER(ORDER BY year),0),2) yoy_pct
FROM yearly ORDER BY year;

-- 35. Review trend with LAG
SELECT employee_id, review_year, rating,
       ROUND(rating-LAG(rating) OVER(
         PARTITION BY employee_id ORDER BY review_year
       ),2) rating_change
FROM performance_reviews
ORDER BY employee_id, review_year;

-- 36. Employees with improving performance
WITH trend AS (
  SELECT employee_id,
         FIRST_VALUE(rating) OVER(PARTITION BY employee_id ORDER BY review_year) first_rating,
         LAST_VALUE(rating) OVER(
           PARTITION BY employee_id ORDER BY review_year
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
         ) latest_rating
  FROM performance_reviews
)
SELECT DISTINCT employee_id, first_rating, latest_rating,
       ROUND(latest_rating-first_rating,2) improvement
FROM trend
WHERE latest_rating > first_rating
ORDER BY improvement DESC;

-- 37. Latest review per employee using ROW_NUMBER
WITH x AS (
  SELECT pr.*, ROW_NUMBER() OVER(
    PARTITION BY employee_id ORDER BY review_date DESC
  ) rn
  FROM performance_reviews pr
)
SELECT * FROM x WHERE rn=1;

-- 38. Top 5 performers company-wide
WITH latest AS (
  SELECT pr.*,
         ROW_NUMBER() OVER(PARTITION BY employee_id ORDER BY review_date DESC) rn
  FROM performance_reviews pr
)
SELECT e.employee_id, e.job_role, latest.rating
FROM latest JOIN employees e USING(employee_id)
WHERE rn=1
ORDER BY rating DESC LIMIT 5;

-- 39. Top 2 performers per department
WITH latest AS (
  SELECT pr.employee_id, pr.rating,
         ROW_NUMBER() OVER(
           PARTITION BY e.department_id ORDER BY pr.rating DESC, pr.goals_score DESC
         ) rn
  FROM performance_reviews pr
  JOIN employees e USING(employee_id)
  WHERE pr.review_year=2024
)
SELECT e.employee_id, d.department_name, latest.rating
FROM latest JOIN employees e USING(employee_id)
JOIN departments d USING(department_id)
WHERE latest.rn<=2
ORDER BY d.department_name, latest.rn;

-- 40. Salary contribution by department
SELECT d.department_name,
       SUM(s.monthly_salary) total_salary,
       ROUND(100*SUM(s.monthly_salary)/SUM(SUM(s.monthly_salary)) OVER(),2) pct_company_salary
FROM departments d JOIN employees e USING(department_id)
JOIN salaries s USING(employee_id)
WHERE s.effective_date=DATE '2024-01-01'
GROUP BY d.department_name
ORDER BY pct_company_salary DESC;

-- 41. Average tenure using date arithmetic from tenure years
SELECT ROUND(AVG(years_at_company),2) avg_tenure_years,
       MIN(years_at_company) min_tenure,
       MAX(years_at_company) max_tenure
FROM employees;

-- 42. Approximate hire year from 2024 snapshot
SELECT employee_id,
       2024-years_at_company AS approximate_hire_year,
       years_at_company
FROM employees
ORDER BY approximate_hire_year;

-- 43. Employees with high performance but low salary
WITH latest AS (
  SELECT DISTINCT ON(employee_id) employee_id, rating
  FROM performance_reviews
  WHERE review_year=2024
  ORDER BY employee_id, review_date DESC
),
bench AS (
  SELECT AVG(monthly_salary) avg_salary
  FROM salaries WHERE effective_date=DATE '2024-01-01'
)
SELECT e.employee_id, e.job_role, latest.rating, s.monthly_salary
FROM employees e JOIN latest USING(employee_id)
JOIN salaries s USING(employee_id) CROSS JOIN bench
WHERE s.effective_date=DATE '2024-01-01'
  AND latest.rating >= 4.0
  AND s.monthly_salary < bench.avg_salary
ORDER BY latest.rating DESC, s.monthly_salary;

-- 44. High-risk retention segment
SELECT e.employee_id, d.department_name, e.job_role,
       e.years_at_company, e.overtime, e.job_satisfaction,
       s.monthly_salary
FROM employees e
JOIN departments d USING(department_id)
JOIN salaries s USING(employee_id)
WHERE e.attrition=false
  AND e.overtime=true
  AND e.job_satisfaction <= 2
  AND e.years_at_company <= 3
  AND s.effective_date=DATE '2024-01-01'
ORDER BY e.years_at_company;

-- 45. Attendance + attrition relationship
WITH att AS (
  SELECT employee_id,
         AVG((status IN ('Present','WFH'))::int) attendance_rate
  FROM attendance GROUP BY employee_id
)
SELECT e.attrition,
       ROUND(100*AVG(att.attendance_rate),2) avg_attendance_pct,
       COUNT(*) employees
FROM employees e JOIN att USING(employee_id)
GROUP BY e.attrition;

-- 46. Leave and performance combined
WITH leave_totals AS (
  SELECT employee_id, SUM(leave_days) leave_days
  FROM leaves WHERE status='Approved' GROUP BY employee_id
),
latest AS (
  SELECT DISTINCT ON(employee_id) employee_id, rating
  FROM performance_reviews
  ORDER BY employee_id, review_date DESC
)
SELECT CASE
         WHEN lt.leave_days >= 10 THEN 'High Leave'
         WHEN lt.leave_days >= 5 THEN 'Medium Leave'
         ELSE 'Low Leave'
       END leave_band,
       ROUND(AVG(latest.rating),2) avg_rating,
       COUNT(*) employees
FROM leave_totals lt JOIN latest USING(employee_id)
GROUP BY 1 ORDER BY avg_rating DESC;

-- 47. Department salary gap vs company average
WITH company AS (
  SELECT AVG(monthly_salary) avg_salary
  FROM salaries WHERE effective_date=DATE '2024-01-01'
),
dept AS (
  SELECT e.department_id, AVG(s.monthly_salary) avg_salary
  FROM employees e JOIN salaries s USING(employee_id)
  WHERE s.effective_date=DATE '2024-01-01'
  GROUP BY e.department_id
)
SELECT d.department_name, ROUND(dept.avg_salary,2) dept_avg,
       ROUND(company.avg_salary,2) company_avg,
       ROUND(100*(dept.avg_salary-company.avg_salary)/company.avg_salary,2) gap_pct
FROM dept JOIN departments d USING(department_id) CROSS JOIN company
ORDER BY gap_pct DESC;

-- 48. Monthly attendance trend
SELECT DATE_TRUNC('month', attendance_date)::date month,
       COUNT(*) workdays,
       ROUND(100*AVG((status IN ('Present','WFH'))::int),2) attendance_rate_pct
FROM attendance
GROUP BY 1 ORDER BY 1;

-- 49. Monthly leave trend
SELECT DATE_TRUNC('month', start_date)::date month,
       SUM(leave_days) leave_days,
       COUNT(*) requests
FROM leaves
GROUP BY 1 ORDER BY 1;

-- 50. Attrition scorecard by role using conditional aggregation
SELECT job_role,
       COUNT(*) headcount,
       SUM((attrition)::int) leavers,
       SUM((overtime)::int) overtime_employees,
       SUM((job_satisfaction<=2)::int) low_satisfaction,
       ROUND(100.0*SUM(attrition::int)/COUNT(*),2) attrition_pct
FROM employees
GROUP BY job_role
HAVING COUNT(*) >= 20
ORDER BY attrition_pct DESC;


-- 51. LEAD: compare each employee's review with the next review
SELECT employee_id,
       review_year,
       rating,
       LEAD(rating) OVER (
         PARTITION BY employee_id ORDER BY review_year
       ) AS next_year_rating,
       ROUND(
         LEAD(rating) OVER (
           PARTITION BY employee_id ORDER BY review_year
         ) - rating, 2
       ) AS next_year_change
FROM performance_reviews
ORDER BY employee_id, review_year;
