-- HR Workforce Analytics | PostgreSQL
-- Run after creating a database, e.g. hr_workforce_analytics
-- Source: IBM HR Analytics Employee Attrition & Performance (Kaggle)
-- Attendance, leave and multi-period performance tables are portfolio extensions.

DROP TABLE IF EXISTS performance_reviews, leaves, attendance, salaries, employees, departments CASCADE;

CREATE TABLE departments (
    department_id      SERIAL PRIMARY KEY,
    department_name    VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE employees (
    employee_id                    INTEGER PRIMARY KEY,
    age                            INTEGER NOT NULL CHECK (age BETWEEN 18 AND 80),
    gender                         VARCHAR(20),
    marital_status                 VARCHAR(30),
    education_level                INTEGER,
    education_field                VARCHAR(100),
    department_id                  INTEGER NOT NULL REFERENCES departments(department_id),
    job_role                       VARCHAR(100),
    job_level                      INTEGER CHECK (job_level BETWEEN 1 AND 5),
    business_travel                VARCHAR(30),
    distance_from_home             INTEGER,
    total_working_years            INTEGER,
    years_at_company               INTEGER,
    years_in_current_role          INTEGER,
    years_since_last_promotion     INTEGER,
    years_with_current_manager     INTEGER,
    num_companies_worked           INTEGER,
    overtime                       BOOLEAN,
    job_satisfaction               INTEGER CHECK (job_satisfaction BETWEEN 1 AND 4),
    environment_satisfaction       INTEGER CHECK (environment_satisfaction BETWEEN 1 AND 4),
    relationship_satisfaction      INTEGER CHECK (relationship_satisfaction BETWEEN 1 AND 4),
    work_life_balance               INTEGER CHECK (work_life_balance BETWEEN 1 AND 4),
    job_involvement                 INTEGER CHECK (job_involvement BETWEEN 1 AND 4),
    performance_rating              INTEGER CHECK (performance_rating BETWEEN 1 AND 4),
    attrition                       BOOLEAN NOT NULL
);

CREATE TABLE salaries (
    salary_id             BIGSERIAL PRIMARY KEY,
    employee_id           INTEGER NOT NULL REFERENCES employees(employee_id),
    effective_date        DATE NOT NULL,
    monthly_salary        NUMERIC(12,2) NOT NULL CHECK (monthly_salary > 0),
    salary_hike_pct       NUMERIC(5,2) DEFAULT 0,
    job_level             INTEGER,
    UNIQUE(employee_id, effective_date)
);

CREATE TABLE attendance (
    attendance_id         BIGSERIAL PRIMARY KEY,
    employee_id           INTEGER NOT NULL REFERENCES employees(employee_id),
    attendance_date       DATE NOT NULL,
    status                VARCHAR(20) NOT NULL CHECK (status IN ('Present','Absent','WFH','Late')),
    work_hours            NUMERIC(4,2) CHECK (work_hours BETWEEN 0 AND 24),
    UNIQUE(employee_id, attendance_date)
);

CREATE TABLE leaves (
    leave_id              BIGSERIAL PRIMARY KEY,
    employee_id           INTEGER NOT NULL REFERENCES employees(employee_id),
    leave_type            VARCHAR(30) NOT NULL CHECK (leave_type IN ('Annual','Sick','Personal','Unpaid','Maternity','Other')),
    start_date            DATE NOT NULL,
    end_date              DATE NOT NULL,
    leave_days            INTEGER NOT NULL CHECK (leave_days > 0),
    status                VARCHAR(20) NOT NULL CHECK (status IN ('Approved','Rejected','Pending')),
    CHECK (end_date >= start_date)
);

CREATE TABLE performance_reviews (
    review_id             BIGSERIAL PRIMARY KEY,
    employee_id           INTEGER NOT NULL REFERENCES employees(employee_id),
    review_date           DATE NOT NULL,
    review_year           INTEGER NOT NULL,
    rating                NUMERIC(3,2) CHECK (rating BETWEEN 1 AND 5),
    goals_score           NUMERIC(5,2) CHECK (goals_score BETWEEN 0 AND 100),
    competency_score      NUMERIC(5,2) CHECK (competency_score BETWEEN 0 AND 100),
    manager_rating        NUMERIC(3,2) CHECK (manager_rating BETWEEN 1 AND 5),
    promotion_eligible    BOOLEAN DEFAULT FALSE,
    UNIQUE(employee_id, review_date)
);

CREATE INDEX idx_salaries_employee_date ON salaries(employee_id, effective_date);
CREATE INDEX idx_attendance_employee_date ON attendance(employee_id, attendance_date);
CREATE INDEX idx_leaves_employee_date ON leaves(employee_id, start_date);
CREATE INDEX idx_reviews_employee_date ON performance_reviews(employee_id, review_date);
CREATE INDEX idx_employees_department ON employees(department_id);
