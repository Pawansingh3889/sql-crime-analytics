# SQL Complete Reference — From Zero to Production Database

A single reference to write, query, optimise, and manage any SQL database. Organised by what you're trying to do, not by syntax.

---

## Table of Contents

1. [Database Design](#1-database-design)
2. [Table Creation & Constraints](#2-table-creation--constraints)
3. [Data Types](#3-data-types)
4. [CRUD — Insert, Read, Update, Delete](#4-crud)
5. [Filtering & Sorting](#5-filtering--sorting)
6. [Joins](#6-joins)
7. [Aggregations](#7-aggregations)
8. [Window Functions](#8-window-functions)
9. [CTEs & Subqueries](#9-ctes--subqueries)
10. [String Functions](#10-string-functions)
11. [Date Functions](#11-date-functions)
12. [CASE WHEN — Conditional Logic](#12-case-when)
13. [Views & Materialised Views](#13-views)
14. [Indexes & Performance](#14-indexes--performance)
15. [Transactions](#15-transactions)
16. [Database Admin](#16-database-admin)
17. [Anti-Patterns — What NOT to Do](#17-anti-patterns)
18. [Interview Quick Reference](#18-interview-quick-reference)

---

## 1. Database Design

### Normalization — When to Split Tables

| Form | Rule | Example |
|---|---|---|
| **1NF** | No repeating groups. Each cell has one value | Don't store `"London,Hull,Leeds"` in one cell |
| **2NF** | Every non-key column depends on the FULL primary key | If PK is (order_id, product_id), don't store customer_name here |
| **3NF** | No column depends on another non-key column | Don't store city AND country — city determines country |

### When NOT to Normalise

- Reporting/analytics tables — denormalise for speed
- Read-heavy dashboards — pre-join into fact tables
- Small lookup tables — keep them simple

### Star Schema (Analytics Standard)

```
         dim_date
            |
dim_city -- fact_sales -- dim_product
            |
        dim_customer
```

- **Fact table:** Metrics (sales_amount, quantity, count)
- **Dimension tables:** Attributes (city_name, product_category, date_parts)
- **Always JOIN fact to dimensions, never dimension to dimension**

---

## 2. Table Creation & Constraints

### Create Table — Full Template

```sql
CREATE TABLE employees (
    employee_id    SERIAL PRIMARY KEY,              -- Auto-increment ID
    first_name     VARCHAR(50) NOT NULL,             -- Required text
    last_name      VARCHAR(50) NOT NULL,
    email          VARCHAR(100) UNIQUE NOT NULL,     -- Must be unique
    department_id  INT REFERENCES departments(id),   -- Foreign key
    salary         DECIMAL(10,2) CHECK (salary > 0), -- Must be positive
    hire_date      DATE DEFAULT CURRENT_DATE,        -- Default value
    is_active      BOOLEAN DEFAULT TRUE,
    created_at     TIMESTAMP DEFAULT NOW()
);
```

### Constraints Cheatsheet

| Constraint | What It Does | When to Use |
|---|---|---|
| `PRIMARY KEY` | Unique + NOT NULL identifier | Every table needs one |
| `FOREIGN KEY` | Links to another table's PK | Relationships between tables |
| `NOT NULL` | Cannot be empty | Required fields (name, email) |
| `UNIQUE` | No duplicates allowed | Email, username, phone |
| `CHECK` | Custom validation rule | salary > 0, age BETWEEN 18 AND 120 |
| `DEFAULT` | Auto-fill if not provided | created_at, is_active |

### Composite Primary Key

```sql
CREATE TABLE order_items (
    order_id    INT REFERENCES orders(id),
    product_id  INT REFERENCES products(id),
    quantity    INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)       -- Two columns together = unique
);
```

### Add/Remove Constraints Later

```sql
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary > 0);
ALTER TABLE employees DROP CONSTRAINT chk_salary;
ALTER TABLE employees ADD COLUMN phone VARCHAR(20);
ALTER TABLE employees ALTER COLUMN email SET NOT NULL;
```

---

## 3. Data Types

### Use the Right Type

| Data | Use | Don't Use |
|---|---|---|
| Money | `DECIMAL(10,2)` | FLOAT (rounding errors) |
| True/False | `BOOLEAN` | VARCHAR, INT |
| Short text | `VARCHAR(100)` | TEXT (unless unlimited needed) |
| Long text | `TEXT` | VARCHAR(10000) |
| Date only | `DATE` | VARCHAR, TIMESTAMP |
| Date + time | `TIMESTAMP` | VARCHAR |
| Auto ID | `SERIAL` (Postgres) / `AUTO_INCREMENT` (MySQL) | Manual IDs |
| UUID | `UUID` | VARCHAR(36) |
| Whole numbers | `INT` or `BIGINT` | DECIMAL |
| Percentages | `DECIMAL(5,2)` | INT |

---

## 4. CRUD

### INSERT

```sql
-- Single row
INSERT INTO employees (first_name, last_name, email, salary)
VALUES ('Pawan', 'Kapkoti', 'pawan@email.com', 29000);

-- Multiple rows
INSERT INTO employees (first_name, last_name, email, salary)
VALUES
    ('Alice', 'Smith', 'alice@email.com', 32000),
    ('Bob', 'Jones', 'bob@email.com', 28000);

-- Insert from another table
INSERT INTO archive_employees
SELECT * FROM employees WHERE is_active = FALSE;

-- Upsert (insert or update if exists) — PostgreSQL
INSERT INTO employees (email, salary)
VALUES ('pawan@email.com', 30000)
ON CONFLICT (email) DO UPDATE SET salary = EXCLUDED.salary;
```

### SELECT

```sql
SELECT * FROM employees;                          -- All columns (avoid in production)
SELECT first_name, salary FROM employees;         -- Specific columns
SELECT DISTINCT department_id FROM employees;     -- Unique values only
SELECT COUNT(*) FROM employees;                   -- Row count
```

### UPDATE

```sql
UPDATE employees SET salary = 31000 WHERE email = 'pawan@email.com';
UPDATE employees SET is_active = FALSE WHERE hire_date < '2020-01-01';

-- Update from another table
UPDATE employees e
SET department_id = d.id
FROM departments d
WHERE d.name = 'Data' AND e.department_id IS NULL;
```

### DELETE

```sql
DELETE FROM employees WHERE is_active = FALSE;
DELETE FROM employees WHERE hire_date < '2020-01-01';
TRUNCATE TABLE employees;     -- Delete ALL rows (faster, no logging)
```

---

## 5. Filtering & Sorting

### WHERE Clause Patterns

```sql
WHERE salary > 30000                              -- Comparison
WHERE salary BETWEEN 25000 AND 40000              -- Range (inclusive)
WHERE department_id IN (1, 3, 5)                  -- List match
WHERE department_id NOT IN (2, 4)                 -- Exclude list
WHERE first_name LIKE 'P%'                        -- Starts with P
WHERE first_name LIKE '%an'                       -- Ends with an
WHERE first_name ILIKE '%pawan%'                  -- Case-insensitive (Postgres)
WHERE email IS NULL                               -- Check for NULL
WHERE email IS NOT NULL                           -- Has a value
WHERE salary > 30000 AND department_id = 1        -- Both conditions
WHERE salary > 50000 OR department_id = 1         -- Either condition
```

### ORDER BY

```sql
ORDER BY salary DESC                              -- Highest first
ORDER BY department_id ASC, salary DESC           -- Sort by two columns
ORDER BY hire_date DESC NULLS LAST                -- NULLs at the end
```

### LIMIT & OFFSET

```sql
LIMIT 10                                          -- First 10 rows
LIMIT 10 OFFSET 20                                -- Rows 21-30 (pagination)
FETCH FIRST 10 ROWS ONLY                          -- SQL standard (same as LIMIT)
```

---

## 6. Joins

### Visual Guide

```
INNER JOIN       LEFT JOIN        RIGHT JOIN       FULL JOIN
  A ∩ B          A + (A ∩ B)      (A ∩ B) + B     A + (A ∩ B) + B
```

### Syntax

```sql
-- INNER JOIN — only matching rows from both tables
SELECT e.name, d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.id;

-- LEFT JOIN — all from left table + matches from right
SELECT e.name, d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.id;

-- RIGHT JOIN — all from right table + matches from left (rarely used)
SELECT e.name, d.department_name
FROM employees e
RIGHT JOIN departments d ON e.department_id = d.id;

-- FULL OUTER JOIN — all rows from both tables
SELECT e.name, d.department_name
FROM employees e
FULL OUTER JOIN departments d ON e.department_id = d.id;

-- CROSS JOIN — every row from A paired with every row from B (cartesian product)
SELECT e.name, p.project_name
FROM employees e
CROSS JOIN projects p;

-- Self-join — join table to itself
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

### When to Use Which Join

| Join | Use When |
|---|---|
| INNER | You only want rows that exist in BOTH tables |
| LEFT | You want ALL rows from the main table even if no match |
| FULL OUTER | You want to find orphaned records in both tables |
| CROSS | You need every possible combination (rare) |
| Self-join | Hierarchies (employee → manager), comparisons within same table |

### Join Anti-Pattern Detection

```sql
-- Find employees with NO department (orphaned records)
SELECT e.* FROM employees e
LEFT JOIN departments d ON e.department_id = d.id
WHERE d.id IS NULL;

-- Find departments with NO employees
SELECT d.* FROM departments d
LEFT JOIN employees e ON d.id = e.department_id
WHERE e.id IS NULL;
```

---

## 7. Aggregations

### Basic Aggregates

```sql
SELECT
    department_id,
    COUNT(*)                    AS employee_count,
    SUM(salary)                 AS total_salary,
    AVG(salary)                 AS avg_salary,
    MIN(salary)                 AS min_salary,
    MAX(salary)                 AS max_salary,
    COUNT(DISTINCT job_title)   AS unique_titles
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 5              -- Filter AFTER grouping
ORDER BY avg_salary DESC;
```

### WHERE vs HAVING

| Clause | Filters | Runs |
|---|---|---|
| WHERE | Individual rows BEFORE grouping | Before GROUP BY |
| HAVING | Groups AFTER aggregation | After GROUP BY |

```sql
-- WHERE: filter rows first, then group
SELECT department_id, AVG(salary)
FROM employees
WHERE hire_date > '2023-01-01'    -- Filter rows first
GROUP BY department_id;

-- HAVING: group first, then filter groups
SELECT department_id, AVG(salary) AS avg_sal
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 30000;       -- Filter groups after
```

### FILTER Clause (PostgreSQL)

```sql
SELECT
    department_id,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE salary > 30000) AS high_earners,
    COUNT(*) FILTER (WHERE hire_date > '2024-01-01') AS recent_hires,
    AVG(salary) FILTER (WHERE is_active = TRUE) AS active_avg_salary
FROM employees
GROUP BY department_id;
```

**MySQL/SQL Server:** Use `SUM(CASE WHEN condition THEN 1 ELSE 0 END)` instead.

---

## 8. Window Functions

### Anatomy

```sql
function_name() OVER (
    PARTITION BY column       -- Split into groups (like GROUP BY but keeps rows)
    ORDER BY column           -- Sort within each group
    ROWS BETWEEN ...          -- Frame: which rows to include
)
```

### All Window Functions

| Function | Returns | Use Case |
|---|---|---|
| `ROW_NUMBER()` | 1, 2, 3, 4 | Unique rank, top-N per group |
| `RANK()` | 1, 2, 2, 4 | Ranking with gaps after ties |
| `DENSE_RANK()` | 1, 2, 2, 3 | Ranking without gaps |
| `NTILE(4)` | 1, 1, 2, 2, 3, 3, 4, 4 | Split into quartiles/buckets |
| `LAG(col, 1)` | Previous row's value | MoM/YoY change |
| `LEAD(col, 1)` | Next row's value | Spike detection |
| `FIRST_VALUE(col)` | First in window | Baseline comparison |
| `LAST_VALUE(col)` | Last in window | Latest value |
| `SUM() OVER()` | Running/total sum | Cumulative totals, % of total |
| `AVG() OVER()` | Running/total average | Moving averages |
| `COUNT() OVER()` | Running/total count | Running count |

### Common Patterns

```sql
-- Percentage of total (no GROUP BY needed)
SELECT name, salary,
       ROUND(salary * 100.0 / SUM(salary) OVER (), 1) AS pct_of_total
FROM employees;

-- Running total
SELECT name, salary,
       SUM(salary) OVER (ORDER BY hire_date) AS running_total
FROM employees;

-- Moving average (last 3 rows)
SELECT month, revenue,
       AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS ma_3
FROM monthly_sales;

-- Rank within department
SELECT name, department_id, salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) AS dept_rank
FROM employees;

-- Top 1 per group
WITH ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn
    FROM employees
)
SELECT * FROM ranked WHERE rn = 1;

-- Month-over-month change
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev,
       revenue - LAG(revenue) OVER (ORDER BY month) AS change
FROM monthly_sales;
```

---

## 9. CTEs & Subqueries

### CTE (Common Table Expression)

```sql
-- Single CTE
WITH high_earners AS (
    SELECT * FROM employees WHERE salary > 40000
)
SELECT department_id, COUNT(*) FROM high_earners GROUP BY department_id;

-- Multiple CTEs
WITH
dept_totals AS (
    SELECT department_id, SUM(salary) AS total_salary
    FROM employees GROUP BY department_id
),
dept_avg AS (
    SELECT AVG(total_salary) AS company_avg FROM dept_totals
)
SELECT dt.*, da.company_avg,
       dt.total_salary - da.company_avg AS diff_from_avg
FROM dept_totals dt, dept_avg da;

-- Recursive CTE (org chart / hierarchy)
WITH RECURSIVE org_chart AS (
    SELECT id, name, manager_id, 1 AS level
    FROM employees WHERE manager_id IS NULL           -- Start: CEO
    UNION ALL
    SELECT e.id, e.name, e.manager_id, oc.level + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.id         -- Recurse down
)
SELECT * FROM org_chart ORDER BY level, name;
```

### CTE vs Subquery — When to Use Which

| Use CTE When | Use Subquery When |
|---|---|
| Query is referenced more than once | Used only once |
| Complex logic needs named steps | Simple filter or lookup |
| Recursive (hierarchies) | EXISTS/NOT EXISTS check |
| Readability matters | Performance matters (sometimes faster) |

### Subquery Patterns

```sql
-- Scalar subquery (returns single value)
SELECT name, salary,
       salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM employees;

-- IN subquery (returns list)
SELECT * FROM employees
WHERE department_id IN (SELECT id FROM departments WHERE location = 'London');

-- EXISTS subquery (returns TRUE/FALSE)
SELECT d.name FROM departments d
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department_id = d.id);

-- Correlated subquery (references outer query)
SELECT e.name, e.salary
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary) FROM employees WHERE department_id = e.department_id
);
```

---

## 10. String Functions

```sql
UPPER('hello')                          -- 'HELLO'
LOWER('HELLO')                          -- 'hello'
INITCAP('hello world')                  -- 'Hello World' (Postgres)
TRIM('  hello  ')                       -- 'hello'
LTRIM('  hello')                        -- 'hello'
RTRIM('hello  ')                        -- 'hello'
LENGTH('hello')                         -- 5
LEFT('hello', 3)                        -- 'hel'
RIGHT('hello', 2)                       -- 'lo'
SUBSTRING('hello' FROM 2 FOR 3)         -- 'ell'
REPLACE('hello world', 'world', 'SQL')  -- 'hello SQL'
CONCAT(first_name, ' ', last_name)      -- 'Pawan Kapkoti'
first_name || ' ' || last_name          -- Same (Postgres)
SPLIT_PART('a,b,c', ',', 2)            -- 'b' (Postgres)
POSITION('lo' IN 'hello')              -- 4
REGEXP_REPLACE('abc123', '[0-9]', '', 'g')  -- 'abc' (Postgres)

-- STRING_AGG — combine multiple rows into one string
SELECT department_id,
       STRING_AGG(first_name, ', ' ORDER BY first_name) AS team
FROM employees GROUP BY department_id;
```

---

## 11. Date Functions

### PostgreSQL

```sql
CURRENT_DATE                                     -- 2026-03-19
CURRENT_TIMESTAMP                                -- 2026-03-19 10:30:00
NOW()                                            -- Same as CURRENT_TIMESTAMP
DATE_TRUNC('month', timestamp_col)               -- 2026-03-01 00:00:00
EXTRACT(YEAR FROM date_col)                      -- 2026
EXTRACT(MONTH FROM date_col)                     -- 3
EXTRACT(DOW FROM date_col)                       -- 0=Sun, 6=Sat
date_col + INTERVAL '7 days'                     -- Add 7 days
date_col - INTERVAL '1 month'                    -- Subtract 1 month
AGE(end_date, start_date)                        -- Interval between dates
TO_CHAR(date_col, 'DD Mon YYYY')                 -- '19 Mar 2026'
TO_DATE('19/03/2026', 'DD/MM/YYYY')             -- String to date
```

### Common Date Patterns

```sql
-- Records from last 30 days
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'

-- Group by month
SELECT DATE_TRUNC('month', order_date) AS month, SUM(amount)
FROM orders GROUP BY 1 ORDER BY 1;

-- Day of week analysis
SELECT EXTRACT(DOW FROM order_date) AS day_of_week, COUNT(*)
FROM orders GROUP BY 1 ORDER BY 1;

-- Year-over-year comparison
SELECT
    EXTRACT(MONTH FROM order_date) AS month,
    SUM(amount) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2025) AS revenue_2025,
    SUM(amount) FILTER (WHERE EXTRACT(YEAR FROM order_date) = 2026) AS revenue_2026
FROM orders GROUP BY 1 ORDER BY 1;
```

---

## 12. CASE WHEN

```sql
-- Simple categorisation
SELECT name, salary,
    CASE
        WHEN salary > 50000 THEN 'Senior'
        WHEN salary > 30000 THEN 'Mid'
        ELSE 'Junior'
    END AS level
FROM employees;

-- Pivot / conditional aggregation
SELECT
    department_id,
    SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM employees GROUP BY department_id;

-- Conditional ORDER BY
SELECT * FROM employees
ORDER BY CASE WHEN is_active THEN 0 ELSE 1 END, salary DESC;

-- NULL handling
SELECT name, COALESCE(phone, email, 'No contact') AS contact
FROM employees;
```

---

## 13. Views

### Regular View (Virtual Table)

```sql
CREATE VIEW active_employees AS
SELECT id, name, department_id, salary
FROM employees WHERE is_active = TRUE;

-- Use it like a table
SELECT * FROM active_employees WHERE salary > 30000;
```

### Materialised View (Cached — PostgreSQL)

```sql
CREATE MATERIALIZED VIEW monthly_summary AS
SELECT DATE_TRUNC('month', order_date) AS month,
       SUM(amount) AS revenue, COUNT(*) AS orders
FROM orders GROUP BY 1;

-- Must refresh manually
REFRESH MATERIALIZED VIEW monthly_summary;
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_summary;  -- No locks
```

| Type | Data | Speed | Use |
|---|---|---|---|
| View | Always fresh (re-runs query) | Slower | Real-time reports |
| Materialised View | Snapshot (stale until refreshed) | Faster | Dashboards, heavy queries |

---

## 14. Indexes & Performance

### Create Indexes

```sql
CREATE INDEX idx_employees_dept ON employees(department_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE UNIQUE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_orders_composite ON orders(customer_id, order_date);

-- Partial index (only index active rows)
CREATE INDEX idx_active_employees ON employees(department_id) WHERE is_active = TRUE;

-- Drop index
DROP INDEX idx_employees_dept;
```

### When to Index

| Index When | Don't Index When |
|---|---|
| Column appears in WHERE frequently | Table has < 1000 rows |
| Column is used in JOIN conditions | Column is rarely queried |
| Column is used in ORDER BY | Column has very few distinct values (boolean) |
| Column is a foreign key | Table has heavy INSERT/UPDATE |

### EXPLAIN ANALYZE — See How Your Query Runs

```sql
EXPLAIN ANALYZE
SELECT * FROM employees WHERE department_id = 3;
```

**What to look for:**
- `Seq Scan` = Full table scan (bad for large tables)
- `Index Scan` = Using index (good)
- `cost=` = Lower is better
- `actual time=` = Real execution time
- `rows=` = Actual rows processed

### Performance Rules

1. **SELECT only columns you need** — never `SELECT *` in production
2. **Filter early** — put WHERE conditions to reduce rows ASAP
3. **Use EXISTS instead of IN** for large subqueries
4. **Avoid functions on indexed columns** — `WHERE UPPER(name) = 'PAWAN'` won't use index
5. **Use LIMIT** for exploratory queries
6. **Batch large INSERTs** — insert 1000 rows at once, not 1 at a time

---

## 15. Transactions

```sql
BEGIN;                                    -- Start transaction
    UPDATE accounts SET balance = balance - 100 WHERE id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;                                   -- Save changes

-- If something goes wrong
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE id = 1;
    -- Oops, error detected
ROLLBACK;                                 -- Undo everything

-- Savepoint (partial rollback)
BEGIN;
    INSERT INTO orders VALUES (...);
    SAVEPOINT sp1;
    INSERT INTO order_items VALUES (...);  -- This fails
    ROLLBACK TO sp1;                       -- Undo only order_items
COMMIT;                                   -- orders insert is saved
```

---

## 16. Database Admin

### Users & Permissions

```sql
CREATE USER analyst WITH PASSWORD 'secure123';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst;
GRANT SELECT, INSERT ON employees TO analyst;
REVOKE INSERT ON employees FROM analyst;
```

### Schemas

```sql
CREATE SCHEMA raw;
CREATE SCHEMA analytics;
CREATE TABLE raw.crimes (...);
CREATE TABLE analytics.fct_crimes_by_city (...);
```

### Backup & Restore (PostgreSQL CLI)

```bash
pg_dump dbname > backup.sql                    # Backup
psql dbname < backup.sql                       # Restore
pg_dump -Fc dbname > backup.dump               # Compressed backup
pg_restore -d dbname backup.dump               # Restore compressed
```

---

## 17. Anti-Patterns — What NOT to Do

| Bad Practice | Why | Do This Instead |
|---|---|---|
| `SELECT *` | Pulls unnecessary data, breaks if schema changes | List specific columns |
| Storing CSV in one column | Breaks 1NF, can't query efficiently | Separate table with rows |
| No primary key | No way to uniquely identify rows | Always add a PK |
| Using FLOAT for money | Rounding errors (0.1 + 0.2 != 0.3) | Use DECIMAL(10,2) |
| Soft deletes everywhere | Table grows forever, queries slow | Archive table + hard delete |
| N+1 queries | 1 query for list + 1 per item = 1000 queries | Single JOIN query |
| No indexes on FK columns | JOINs become full table scans | Index every foreign key |
| `WHERE function(column)` | Prevents index usage | Rewrite to avoid function on column |
| Storing dates as strings | Can't compare, sort, or do date math | Use DATE/TIMESTAMP types |
| No constraints | Bad data gets in | CHECK, NOT NULL, FK constraints |

---

## 18. Interview Quick Reference

### "Design a database for X" Template

```
1. Identify entities (users, orders, products)
2. Define relationships (user HAS MANY orders, order HAS MANY items)
3. Create tables with PKs and FKs
4. Add constraints (NOT NULL, CHECK, UNIQUE)
5. Add indexes on FKs and frequently queried columns
6. Create views for common queries
```

### SQL Execution Order (not the order you write it)

```
1. FROM + JOINs     (which tables)
2. WHERE             (filter rows)
3. GROUP BY          (group rows)
4. HAVING            (filter groups)
5. SELECT            (pick columns)
6. DISTINCT          (remove duplicates)
7. ORDER BY          (sort)
8. LIMIT/OFFSET      (paginate)
```

### Common Interview Questions — One-Liners

```sql
-- Second highest salary
SELECT DISTINCT salary FROM employees ORDER BY salary DESC LIMIT 1 OFFSET 1;

-- Nth highest salary
SELECT DISTINCT salary FROM employees ORDER BY salary DESC LIMIT 1 OFFSET N-1;

-- Duplicate rows
SELECT email, COUNT(*) FROM employees GROUP BY email HAVING COUNT(*) > 1;

-- Delete duplicates (keep lowest ID)
DELETE FROM employees WHERE id NOT IN (
    SELECT MIN(id) FROM employees GROUP BY email
);

-- Running total
SELECT id, amount, SUM(amount) OVER (ORDER BY id) AS running_total FROM orders;

-- Employees earning more than their manager
SELECT e.name FROM employees e
JOIN employees m ON e.manager_id = m.id
WHERE e.salary > m.salary;

-- Department with highest average salary
SELECT department_id, AVG(salary) AS avg_sal
FROM employees GROUP BY department_id
ORDER BY avg_sal DESC LIMIT 1;

-- Consecutive days login (gaps and islands)
WITH numbered AS (
    SELECT user_id, login_date,
           login_date - ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date) * INTERVAL '1 day' AS grp
    FROM logins
)
SELECT user_id, MIN(login_date) AS streak_start, MAX(login_date) AS streak_end,
       COUNT(*) AS streak_days
FROM numbered GROUP BY user_id, grp HAVING COUNT(*) >= 3;
```

---

## Sources

- [DataLemur SQL Interview Cheat Sheet](https://datalemur.com/blog/sql-interview-cheat-sheet)
- [LearnSQL Window Functions Cheat Sheet](https://learnsql.com/blog/sql-window-functions-cheat-sheet/)
- [GeeksforGeeks SQL Cheat Sheet](https://www.geeksforgeeks.org/sql/sql-cheat-sheet/)
- [DataCamp SQL Query Optimization](https://www.datacamp.com/blog/sql-query-optimization)
- [SqlCheat Normalization Cheat Sheet](https://sqlcheat.com/cheat-sheets/sql-normalization-cheat-sheet/)
- [AlmaBetter SQL Cheat Sheet 2026](https://www.almabetter.com/bytes/cheat-sheet/sql)
