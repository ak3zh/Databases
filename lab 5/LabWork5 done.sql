-- Bekov Akezhan (24B030289)

-- Task 1.1: Basic CHECK Constraint
CREATE TABLE employees (
    employee_id   INTEGER,
    first_name    TEXT,
    last_name     TEXT,
    age           INTEGER CHECK (age BETWEEN 18 AND 65),
    salary        NUMERIC CHECK (salary > 0)
);

-- Valid inserts (at least 2)
INSERT INTO employees (employee_id, first_name, last_name, age, salary) VALUES
(1, 'Aruzhan', 'Sultan', 28, 350000),
(2, 'Dias', 'Kenzhe', 45, 680000);

-- Task 1.2: Named CHECK Constraint
CREATE TABLE products_catalog (
    product_id     INTEGER,
    product_name   TEXT,
    regular_price  NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Valid inserts
INSERT INTO products_catalog (product_id, product_name, regular_price, discount_price) VALUES
(10, 'Mouse', 10000, 8000),
(11, 'Keyboard', 20000, 15000);

-- Task 1.3: Multiple Column CHECK
CREATE TABLE bookings (
    booking_id     INTEGER,
    check_in_date  DATE,
    check_out_date DATE,
    num_guests     INTEGER,
    CONSTRAINT chk_guests CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT chk_dates  CHECK (check_out_date > check_in_date)
);

-- Valid inserts
INSERT INTO bookings (booking_id, check_in_date, check_out_date, num_guests) VALUES
(101, DATE '2025-11-01', DATE '2025-11-05', 2),
(102, DATE '2025-12-20', DATE '2025-12-25', 4);

-- ============================================================================
-- Part 2: NOT NULL Constraints
-- ============================================================================

-- Task 2.1: NOT NULL Implementation
CREATE TABLE customers (
    customer_id       INTEGER NOT NULL,
    email             TEXT    NOT NULL,
    phone             TEXT,
    registration_date DATE    NOT NULL
);

-- Valid inserts (including NULL in nullable phone)
INSERT INTO customers (customer_id, email, phone, registration_date) VALUES
(1, 'aika@example.com', NULL, DATE '2025-01-05'),
(2, 'batyr@example.com', '+7-700-111-22-33', DATE '2025-02-10');

-- Task 2.2: Combining Constraints
CREATE TABLE inventory (
    item_id      INTEGER NOT NULL,
    item_name    TEXT    NOT NULL,
    quantity     INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price   NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Valid inserts
INSERT INTO inventory (item_id, item_name, quantity, unit_price, last_updated) VALUES
(100, 'SSD 512GB', 25, 29990, NOW()),
(101, 'RAM 16GB', 40, 19990, NOW());

-- Task 2.3: Testing NOT NULL (only successful examples here)
-- Insert with NULL in nullable column (phone) already demonstrated above.

-- ============================================================================
-- Part 3: UNIQUE Constraints
-- ============================================================================

-- Task 3.1: Single Column UNIQUE
-- We create without UNIQUE first, then add named constraints in Task 3.3
CREATE TABLE users (
    user_id    INTEGER,
    username   TEXT,
    email      TEXT,
    created_at TIMESTAMP
);

-- Task 3.3: Named UNIQUE Constraints (on users)
ALTER TABLE users
    ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users
    ADD CONSTRAINT unique_email UNIQUE (email);

-- Valid inserts
INSERT INTO users (user_id, username, email, created_at) VALUES
(1, 'miras', 'miras@example.com', NOW()),
(2, 'aidana', 'aidana@example.com', NOW());

-- Task 3.2: Multi-Column UNIQUE
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id    INTEGER,
    course_code   TEXT,
    semester      TEXT,
    CONSTRAINT uq_student_course_sem UNIQUE (student_id, course_code, semester)
);

-- Valid inserts
INSERT INTO course_enrollments (enrollment_id, student_id, course_code, semester) VALUES
(1, 50026, 'CS101', 'Fall-2025'),
(2, 50026, 'CS102', 'Fall-2025'),
(3, 50026, 'CS101', 'Spring-2026');  -- Allowed due to different semester

-- ============================================================================
-- Part 4: PRIMARY KEY Constraints
-- ============================================================================

-- Task 4.1: Single Column Primary Key
CREATE TABLE departments (
    dept_id   INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location  TEXT
);

-- Valid inserts
INSERT INTO departments (dept_id, dept_name, location) VALUES
(10, 'IT', 'Almaty'),
(20, 'Finance', 'Astana'),
(30, 'HR', 'Shymkent');

-- Task 4.2: Composite Primary Key
CREATE TABLE student_courses (
    student_id      INTEGER,
    course_id       INTEGER,
    enrollment_date DATE,
    grade           TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- Valid inserts
INSERT INTO student_courses (student_id, course_id, enrollment_date, grade) VALUES
(50026, 1, DATE '2025-09-01', 'A'),
(50026, 2, DATE '2025-09-01', 'B'),
(50100, 1, DATE '2025-09-01', 'A-');

-- Task 4.3: Comparison Exercise (documented as comments)
-- UNIQUE vs PRIMARY KEY:
--   * PRIMARY KEY uniquely identifies a row and implies NOT NULL automatically.
--   * UNIQUE enforces uniqueness but allows NULLs (and a table can have many UNIQUEs).
-- Single-column vs Composite PK:
--   * Use single-column PK when a natural or surrogate single identifier exists.
--   * Use composite PK when the logical identity is a combination of columns
--     (e.g., (student_id, course_id) in a join table) to prevent duplicates naturally.
-- Why one PRIMARY KEY but many UNIQUE:
--   * A table can have only one PRIMARY KEY because a row should have a single
--     definitive identity; however, multiple UNIQUE constraints can enforce other
--     candidate keys that must remain unique.

-- ============================================================================
-- Part 5: FOREIGN KEY Constraints
-- ============================================================================

-- Task 5.1: Basic Foreign Key (employees_dept -> departments)
CREATE TABLE employees_dept (
    emp_id    INTEGER PRIMARY KEY,
    emp_name  TEXT NOT NULL,
    dept_id   INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

-- Valid inserts (dept_id must exist in departments)
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date) VALUES
(1001, 'Aruzhan Suleimen', 10, DATE '2025-03-15'),
(1002, 'Dias Yerzhan',     20, DATE '2025-04-01');

-- Task 5.2: Multiple Foreign Keys (Library schema)
CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);

CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,
    title            TEXT NOT NULL,
    author_id        INTEGER REFERENCES authors(author_id),
    publisher_id     INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn             TEXT UNIQUE
);

-- Sample data
INSERT INTO authors (author_id, author_name, country) VALUES
(1, 'Haruki Murakami', 'Japan'),
(2, 'George Orwell',   'UK'),
(3, 'Abai Kunanbayuly','Kazakhstan');

INSERT INTO publishers (publisher_id, publisher_name, city) VALUES
(1, 'Vintage',  'London'),
(2, 'Penguin',  'New York'),
(3, 'AlmatyPress', 'Almaty');

INSERT INTO books (book_id, title, author_id, publisher_id, publication_year, isbn) VALUES
(1, 'Kafka on the Shore', 1, 1, 2002, '9781400079278'),
(2, '1984',               2, 2, 1949, '9780451524935'),
(3, 'Book of Words',      3, 3, 1909, '9786011234567');

-- Task 5.3: ON DELETE Options
CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id   INTEGER PRIMARY KEY,
    order_id  INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity  INTEGER CHECK (quantity > 0)
);

-- Seed data to demonstrate behaviors
INSERT INTO categories (category_id, category_name) VALUES
(1, 'Electronics'),
(2, 'Books');

INSERT INTO products_fk (product_id, product_name, category_id) VALUES
(100, 'USB-C Cable', 1),
(101, 'Novel',       2);

INSERT INTO orders (order_id, order_date) VALUES
(5000, DATE '2025-10-01');

INSERT INTO order_items (item_id, order_id, product_id, quantity) VALUES
(9000, 5000, 100, 2),
(9001, 5000, 101, 1);

-- Notes:
-- 1) Deleting a category with existing products will be restricted due to ON DELETE RESTRICT.
-- 2) Deleting an order removes its order_items automatically due to ON DELETE CASCADE.

-- ============================================================================
-- Part 6: Practical Application — E-commerce Database Design
-- ============================================================================

-- Required tables with constraints and appropriate ON DELETE behavior:
--  - orders_ecom.customer_id REFERENCES customers_ecom(customer_id) ON DELETE RESTRICT
--    (customer_id is NOT NULL: customers with orders cannot be deleted)
--  - order_details references orders_ecom (CASCADE) and products_ecom (RESTRICT)

CREATE TABLE customers_ecom (
    customer_id       INTEGER PRIMARY KEY,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE,
    phone             TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE products_ecom (
    product_id     INTEGER PRIMARY KEY,
    name           TEXT NOT NULL,
    description    TEXT,
    price          NUMERIC NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecom (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers_ecom(customer_id) ON DELETE RESTRICT,
    order_date   DATE NOT NULL,
    total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
    status       TEXT NOT NULL CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id      INTEGER NOT NULL REFERENCES products_ecom(product_id) ON DELETE RESTRICT,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- Sample data: at least 5 rows per table
INSERT INTO customers_ecom (customer_id, name, email, phone, registration_date) VALUES
(1, 'Aruzhan Suleimen', 'aruzhan@example.com', '+7-700-111-22-33', DATE '2025-01-10'),
(2, 'Dias Yerzhan',     'dias@example.com',     NULL,               DATE '2025-02-15'),
(3, 'Miras Bakhytzhan', 'miras@example.com',    '+7-777-222-33-44', DATE '2025-03-05'),
(4, 'Dana Dzhurko',     'dana@example.com',     '+7-705-555-55-55', DATE '2025-04-12'),
(5, 'Aidana A.',        'aidana.a@example.com', NULL,               DATE '2025-05-01');

INSERT INTO products_ecom (product_id, name, description, price, stock_quantity) VALUES
(101, 'Laptop 14"', 'Lightweight laptop with 16GB RAM', 450000, 20),
(102, 'Wireless Mouse', 'Ergonomic wireless mouse', 12000, 200),
(103, 'Mechanical Keyboard', 'RGB mechanical keyboard', 35000, 150),
(104, 'USB-C Hub', '7-in-1 hub', 18000, 80),
(105, 'Monitor 27"', 'IPS 144Hz monitor', 190000, 30);

-- Create orders (ensure totals match details later)
INSERT INTO orders_ecom (order_id, customer_id, order_date, total_amount, status) VALUES
(10001, 1, DATE '2025-06-01',  462000, 'delivered'),
(10002, 2, DATE '2025-06-15',   15000, 'shipped'),
(10003, 3, DATE '2025-07-20',  205000, 'processing'),
(10004, 4, DATE '2025-08-05',  468000, 'pending'),
(10005, 5, DATE '2025-09-09',  452000, 'delivered');

-- Order details (CASCADE on order deletion)
INSERT INTO order_details (order_detail_id, order_id, product_id, quantity, unit_price) VALUES
-- Order 10001: 1x Mouse (12k) + 1x Keyboard (35k) + 1x USB-C Hub (18k) + 1x Laptop 14" (450k) = 515,000
-- Adjusting to meet recorded total 462,000: assume promotional pricing for laptop (397,000) on that order.
(1, 10001, 102, 1, 12000),
(2, 10001, 103, 1, 35000),
(3, 10001, 104, 1, 18000),
(4, 10001, 101, 1, 397000),

-- Order 10002: 1x Mouse (15,000 total) -> unit price 15,000 (promo)
(5, 10002, 102, 1, 15000),

-- Order 10003: 1x Monitor (190,000) + 1x Hub (15,000 promo) = 205,000
(6, 10003, 105, 1, 190000),
(7, 10003, 104, 1, 15000),

-- Order 10004: 1x Laptop (450,000) + 1x Mouse (12,000) + 1x Hub (6,000 promo) = 468,000
(8, 10004, 101, 1, 450000),
(9, 10004, 102, 1, 12000),
(10, 10004, 104, 1, 6000),

-- Order 10005: 1x Laptop (450,000) + 1x Mouse (2,000 promo) = 452,000
(11, 10005, 101, 1, 450000),
(12, 10005, 102, 1, 2000);

-- Simple verification queries (do not violate constraints)
-- 1) Verify UNIQUE on customers_ecom.email
--    SELECT email, COUNT(*) FROM customers_ecom GROUP BY email HAVING COUNT(*) > 1;
-- 2) Verify status domain
--    SELECT DISTINCT status FROM orders_ecom ORDER BY status;
-- 3) Verify totals vs computed details
--    SELECT o.order_id, o.total_amount,
--           SUM(od.quantity * od.unit_price) AS computed_total
--    FROM orders_ecom o
--    JOIN order_details od ON od.order_id = o.order_id
--    GROUP BY o.order_id, o.total_amount
--    ORDER BY o.order_id;