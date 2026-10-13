# Data Dictionary

## departments
- `department_id`: surrogate primary key
- `department_name`: department name

## employees
- `employee_id`: source EmployeeNumber
- `age`: employee age
- `department_id`: FK to departments
- `job_role`: job title/role
- `job_level`: source job level 1–5
- `monthly_salary`: not stored here; use salaries
- `years_at_company`: tenure in years
- `years_since_last_promotion`: years since latest promotion
- `overtime`: source overtime indicator
- `job_satisfaction`: 1–4
- `performance_rating`: source performance rating 1–4
- `attrition`: whether the employee left

## salaries
- `salary_id`: primary key
- `employee_id`: FK
- `effective_date`: salary snapshot date
- `monthly_salary`: monthly compensation
- `salary_hike_pct`: associated salary increase
- `job_level`: level at the snapshot

**Note:** portfolio-generated salary history; not source payroll history.

## attendance
- `attendance_id`: primary key
- `employee_id`: FK
- `attendance_date`: work date
- `status`: Present / Absent / WFH / Late
- `work_hours`: hours recorded

**Note:** synthetic portfolio extension.

## leaves
- `leave_id`: primary key
- `employee_id`: FK
- `leave_type`: Annual / Sick / Personal / Unpaid / Maternity / Other
- `start_date`, `end_date`: leave interval
- `leave_days`: total leave days
- `status`: Approved / Rejected / Pending

**Note:** synthetic portfolio extension.

## performance_reviews
- `review_id`: primary key
- `employee_id`: FK
- `review_date`: review date
- `review_year`: review year
- `rating`: 1–5 review score
- `goals_score`: 0–100
- `competency_score`: 0–100
- `manager_rating`: 1–5
- `promotion_eligible`: derived eligibility flag

**Note:** synthetic multi-period extension designed for trend-analysis SQL.
