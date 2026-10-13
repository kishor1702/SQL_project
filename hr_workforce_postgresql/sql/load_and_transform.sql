-- Load the public IBM HR CSV into staging, normalize it, then generate portfolio extensions.
-- psql usage:
--   \copy stg_hr_ibm FROM 'WA_Fn-UseC_-HR-Employee-Attrition.csv' CSV HEADER
-- The exact CSV can be downloaded from the Kaggle source linked in README.md.

DROP TABLE IF EXISTS stg_hr_ibm;

CREATE TEMP TABLE stg_hr_ibm (
    age int, attrition text, businesstravel text, dailyrate int, department text,
    distancefromhome int, education int, educationfield text, employeecount int,
    employeenumber int, environmentsatisfaction int, gender text, hourlyrate int,
    jobinvolvement int, joblevel int, jobrole text, jobsatisfaction int,
    maritalstatus text, monthlyincome numeric, monthlyrate int, numcompaniesworked int,
    over18 text, overtime text, percentsalaryhike int, performancerating int,
    relationshipsatisfaction int, standardhours int, stockoptionlevel int,
    totalworkingyears int, trainingtimeslastyear int, worklifebalance int,
    yearsatcompany int, yearsincurrentrole int, yearssincelastpromotion int,
    yearswithcurrmanager int
);

-- IMPORTANT: Execute this in psql after creating the temp table:
-- \copy stg_hr_ibm FROM 'WA_Fn-UseC_-HR-Employee-Attrition.csv' CSV HEADER

INSERT INTO departments(department_name)
SELECT DISTINCT department FROM stg_hr_ibm
WHERE department IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO employees (
    employee_id, age, gender, marital_status, education_level, education_field,
    department_id, job_role, job_level, business_travel, distance_from_home,
    total_working_years, years_at_company, years_in_current_role,
    years_since_last_promotion, years_with_current_manager, num_companies_worked,
    overtime, job_satisfaction, environment_satisfaction, relationship_satisfaction,
    work_life_balance, job_involvement, performance_rating, attrition
)
SELECT
    s.employeenumber, s.age, s.gender, s.maritalstatus, s.education, s.educationfield,
    d.department_id, s.jobrole, s.joblevel, s.businesstravel, s.distancefromhome,
    s.totalworkingyears, s.yearsatcompany, s.yearsincurrentrole,
    s.yearssincelastpromotion, s.yearswithcurrmanager, s.numcompaniesworked,
    s.overtime = 'Yes', s.jobsatisfaction, s.environmentsatisfaction,
    s.relationshipsatisfaction, s.worklifebalance, s.jobinvolvement,
    s.performancerating, s.attrition = 'Yes'
FROM stg_hr_ibm s
JOIN departments d ON d.department_name = s.department;

-- Portfolio extension: reconstruct a plausible salary history from current monthly income.
-- This is synthetic and must NOT be presented as source payroll history.
INSERT INTO salaries(employee_id, effective_date, monthly_salary, salary_hike_pct, job_level)
SELECT employee_id,
       DATE '2022-01-01',
       ROUND((monthly_salary / POWER(1 + GREATEST(percent_hike,0)/100.0, 3))::numeric, 2),
       0,
       job_level
FROM (
    SELECT e.employee_id, e.job_level,
           (SELECT s.monthlyincome FROM stg_hr_ibm s WHERE s.employeenumber=e.employee_id) AS monthly_salary,
           (SELECT s.percentsalaryhike FROM stg_hr_ibm s WHERE s.employeenumber=e.employee_id) AS percent_hike
    FROM employees e
) x
WHERE monthly_salary IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO salaries(employee_id, effective_date, monthly_salary, salary_hike_pct, job_level)
SELECT employee_id,
       DATE '2023-01-01',
       ROUND((monthly_salary / POWER(1 + GREATEST(percent_hike,0)/100.0, 2))::numeric, 2),
       percent_hike,
       job_level
FROM (
    SELECT e.employee_id, e.job_level,
           (SELECT s.monthlyincome FROM stg_hr_ibm s WHERE s.employeenumber=e.employee_id) AS monthly_salary,
           (SELECT s.percentsalaryhike FROM stg_hr_ibm s WHERE s.employeenumber=e.employee_id) AS percent_hike
    FROM employees e
) x
WHERE monthly_salary IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO salaries(employee_id, effective_date, monthly_salary, salary_hike_pct, job_level)
SELECT e.employee_id,
       DATE '2024-01-01',
       s.monthlyincome,
       s.percentsalaryhike,
       e.job_level
FROM employees e
JOIN stg_hr_ibm s ON s.employeenumber=e.employee_id
ON CONFLICT DO NOTHING;

-- Synthetic attendance: one record per employee per weekday in 2024.
-- Seeded formulas make results repeatable enough for portfolio analysis.
INSERT INTO attendance(employee_id, attendance_date, status, work_hours)
SELECT e.employee_id,
       d::date,
       CASE
         WHEN ((e.employee_id + EXTRACT(DOY FROM d)::int) % 37) = 0 THEN 'Absent'
         WHEN ((e.employee_id + EXTRACT(DOY FROM d)::int) % 19) = 0 THEN 'Late'
         WHEN ((e.employee_id + EXTRACT(DOY FROM d)::int) % 11) = 0 THEN 'WFH'
         ELSE 'Present'
       END,
       CASE
         WHEN ((e.employee_id + EXTRACT(DOY FROM d)::int) % 37) = 0 THEN 0
         WHEN ((e.employee_id + EXTRACT(DOY FROM d)::int) % 19) = 0 THEN 7.0
         WHEN ((e.employee_id + EXTRACT(DOY FROM d)::int) % 11) = 0 THEN 8.0
         ELSE 8.0 + (((e.employee_id % 5) - 2) * 0.25)
       END
FROM employees e
CROSS JOIN generate_series(DATE '2024-01-01', DATE '2024-12-31', INTERVAL '1 day') d
WHERE EXTRACT(ISODOW FROM d) < 6
ON CONFLICT DO NOTHING;

-- Synthetic leave events for 2024.
INSERT INTO leaves(employee_id, leave_type, start_date, end_date, leave_days, status)
SELECT employee_id,
       CASE (employee_id % 5)
         WHEN 0 THEN 'Sick' WHEN 1 THEN 'Annual' WHEN 2 THEN 'Personal'
         WHEN 3 THEN 'Annual' ELSE 'Other' END,
       start_dt::date,
       (start_dt + (days-1) * INTERVAL '1 day')::date,
       days,
       CASE WHEN employee_id % 13 = 0 THEN 'Pending' ELSE 'Approved' END
FROM (
    SELECT e.employee_id,
           DATE '2024-02-01' + ((e.employee_id * 17) % 300) AS start_dt,
           1 + (e.employee_id % 5) AS days
    FROM employees e
) x;

-- Synthetic annual review history. Base rating is tied to source performance rating,
-- with small deterministic movement to enable trend analysis.
INSERT INTO performance_reviews(
    employee_id, review_date, review_year, rating, goals_score, competency_score,
    manager_rating, promotion_eligible
)
SELECT e.employee_id,
       make_date(y, 12, 15),
       y,
       LEAST(5.0, GREATEST(1.0,
         base_rating + (((e.employee_id + y) % 5) - 2) * 0.20
       )),
       LEAST(100, GREATEST(0, 65 + base_rating*7 + ((e.employee_id+y)%12))),
       LEAST(100, GREATEST(0, 60 + base_rating*8 + ((e.employee_id+y)%15))),
       LEAST(5.0, GREATEST(1.0, base_rating + (((e.employee_id+y*2)%3)-1)*0.15)),
       (base_rating >= 4.0 AND e.years_since_last_promotion >= 2)
FROM employees e
JOIN (
    SELECT employeenumber, performancerating::numeric AS base_rating
    FROM stg_hr_ibm
) s ON s.employeenumber=e.employee_id
CROSS JOIN generate_series(2022, 2024) y
ON CONFLICT DO NOTHING;
