--part A

-- 1
DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab
  TEMPLATE template0
  ENCODING 'UTF8'
  CONNECTION LIMIT 50;



-- 2
DROP TABLE IF EXISTS employees CASCADE;
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INT DEFAULT 40000,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

-- 3
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INT,
    manager_id INT
);

-- 4
DROP TABLE IF EXISTS projects CASCADE;
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INT,
    start_date DATE,
    end_date DATE,
    budget NUMERIC(12,2)
);


--part B

-- 1
INSERT INTO employees (first_name, last_name, department)
VALUES ('John', 'Smith', 'IT');

-- 2
INSERT INTO employees (first_name, last_name, department, hire_date)
VALUES ('Alice', 'Brown', 'HR', CURRENT_DATE);

-- 3
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
('Bob', 'White', 'Finance', 55000, CURRENT_DATE),
('Emma', 'Green', 'IT', 60000, CURRENT_DATE);

-- 4
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('David', 'Black', 'IT', 50000 * 1.1, CURRENT_DATE);

-- 5
DROP TABLE IF EXISTS temp_employees;
CREATE TABLE temp_employees AS
SELECT emp_id, first_name, last_name, department
FROM employees
WHERE department = 'IT';


--part C

-- 1
UPDATE employees
SET salary = salary * 1.1;

-- 2
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

-- 3
UPDATE employees
SET department = CASE
    WHEN salary > 70000 THEN 'Executive'
    WHEN salary BETWEEN 50000 AND 70000 THEN 'Mid-Level'
    ELSE 'Junior'
END;

-- 4
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 5
UPDATE departments d
SET budget = (SELECT AVG(salary) * 1.2 FROM employees e WHERE e.department = d.dept_name);

-- 6
UPDATE employees
SET salary = salary + 5000,
    status = 'Promoted'
WHERE department = 'IT';


--part D

-- 1
DELETE FROM employees WHERE status = 'Terminated';

-- 2
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 3
DELETE FROM departments d
WHERE NOT EXISTS (
  SELECT 1 FROM employees e WHERE e.department = d.dept_name
);

-- 4
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


--part E

-- 1
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Null', 'Guy', NULL, NULL);

-- 2
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 3
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;


--part F

-- 1
INSERT INTO employees (first_name, last_name, department)
VALUES ('Chris', 'Stone', 'Finance')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 2
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- 3
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


--part G

-- 1
INSERT INTO employees (first_name, last_name, department)
SELECT 'Mark', 'Taylor', 'IT'
WHERE NOT EXISTS (
  SELECT 1 FROM employees WHERE first_name='Mark' AND last_name='Taylor'
);

-- 2
UPDATE employees e
SET salary = salary + 1000
FROM departments d
WHERE e.department = d.dept_name
  AND d.budget > 100000;

-- 3
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
('Ann','Miller','IT',45000,CURRENT_DATE),
('Tom','Clark','Finance',47000,CURRENT_DATE),
('Kate','Wilson','HR',48000,CURRENT_DATE),
('Paul','Moore','IT',49000,CURRENT_DATE),
('Lily','Adams','Finance',50000,CURRENT_DATE);

UPDATE employees
SET salary = salary + 2000
WHERE hire_date = CURRENT_DATE;

-- 4
DROP TABLE IF EXISTS employee_archive;
CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE status='Inactive';

DELETE FROM employees WHERE status='Inactive';

-- 5
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND (SELECT COUNT(*) FROM employees e WHERE e.department = p.dept_id) > 3;

