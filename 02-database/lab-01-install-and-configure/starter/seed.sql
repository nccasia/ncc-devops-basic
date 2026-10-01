-- Sample data for the trainingdb database
-- Run as the database owner:
--   psql -h localhost -U training_owner -d trainingdb -f seed.sql

BEGIN;

DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    location    VARCHAR(100),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE employees (
    id             SERIAL PRIMARY KEY,
    full_name      VARCHAR(150) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    department_id  INT REFERENCES departments(id) ON DELETE SET NULL,
    position       VARCHAR(100),
    salary         NUMERIC(12, 2) CHECK (salary >= 0),
    hired_on       DATE NOT NULL DEFAULT CURRENT_DATE,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_employees_department ON employees(department_id);

INSERT INTO departments (name, location) VALUES
    ('DevOps',      'Ha Noi'),
    ('Backend',     'Ha Noi'),
    ('Frontend',    'Da Nang'),
    ('QA',          'Vinh'),
    ('HR',          'Ha Noi');

INSERT INTO employees (full_name, email, department_id, position, salary, hired_on, is_active) VALUES
    ('Nguyen Van An',    'an.nguyen@example.com',    1, 'DevOps Engineer',    25000000, '2022-03-01', TRUE),
    ('Tran Thi Binh',    'binh.tran@example.com',    1, 'DevOps Intern',       5000000, '2026-09-01', TRUE),
    ('Le Van Cuong',     'cuong.le@example.com',     2, 'Backend Developer',  22000000, '2021-07-15', TRUE),
    ('Pham Thi Dung',    'dung.pham@example.com',    2, 'Tech Lead',          40000000, '2019-01-10', TRUE),
    ('Hoang Van Em',     'em.hoang@example.com',     3, 'Frontend Developer', 20000000, '2023-05-20', TRUE),
    ('Vu Thi Giang',     'giang.vu@example.com',     3, 'UI/UX Designer',     18000000, '2024-02-01', TRUE),
    ('Do Van Hai',       'hai.do@example.com',       4, 'QA Engineer',        17000000, '2022-11-11', TRUE),
    ('Bui Thi Lan',      'lan.bui@example.com',      4, 'QA Intern',           4500000, '2026-09-01', TRUE),
    ('Dang Van Minh',    'minh.dang@example.com',    5, 'HR Executive',       15000000, '2020-08-08', FALSE),
    ('Ngo Thi Ngoc',     'ngoc.ngo@example.com',  NULL, 'Freelancer',         10000000, '2025-12-01', TRUE);

COMMIT;

-- Quick check
SELECT d.name AS department, count(e.id) AS headcount
FROM departments d
LEFT JOIN employees e ON e.department_id = d.id
GROUP BY d.name
ORDER BY d.name;
