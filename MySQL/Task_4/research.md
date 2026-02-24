# SQL Research Questions

---

## 1. UNION vs UNION ALL

Assume two tables:

**table_a**
| city |
|----------|
| Cairo |
| London |

**table_b**
| city |
|----------|
| London |
| Tokyo |

---

### UNION — removes duplicates (slower)

Performs a sort/distinct step after combining, similar to running `DISTINCT` on the full result.

```sql
SELECT city FROM table_a
UNION
SELECT city FROM table_b;
```

**Output:**
| city |
|--------|
| Cairo |
| London |
| Tokyo |

> "London" appears only once even though it's in both tables.

---

### UNION ALL — keeps duplicates (faster)

Simply concatenates both result sets with no extra processing.

```sql
SELECT city FROM table_a
UNION ALL
SELECT city FROM table_b;
```

**Output:**
| city |
|--------|
| Cairo |
| London |
| London |
| Tokyo |

> "London" appears twice. No deduplication, no sorting overhead.

**Rule of thumb:** Use `UNION ALL` by default for better performance. Only use `UNION` when removing duplicates is required.

---

## 2. Subquery vs JOIN

Both queries below return the same result — employees who belong to the "Engineering" department.

**employees**
| id | name | dept_id |
|----|-------|---------|
| 1 | Alice | 10 |
| 2 | Bob | 20 |
| 3 | Carol | 10 |

**departments**
| id | name |
|----|-------------|
| 10 | Engineering |
| 20 | Marketing |

---

### Subquery

```sql
SELECT name
FROM employees
WHERE dept_id IN (
    SELECT id FROM departments WHERE name = 'Engineering'
);
```

**Output:**
| name |
|-------|
| Alice |
| Carol |

---

### JOIN (preferred in production)

```sql
SELECT e.name
FROM employees e
JOIN departments d ON e.dept_id = d.id
WHERE d.name = 'Engineering';
```

**Output:**
| name |
|-------|
| Alice |
| Carol |

---

### Why prefer JOIN in production?

---

#### 1. Performance — Subqueries can re-run for every single row

With a subquery, the inner query may execute once **per row** in the outer table. On a table with 1 million rows, that's 1 million extra queries.

```sql
-- Subquery: the inner SELECT may run once per employee row
SELECT name
FROM employees
WHERE dept_id IN (
    SELECT id FROM departments WHERE name = 'Engineering'
);
```

```sql
-- JOIN: the database links both tables in ONE pass
SELECT e.name
FROM employees e
JOIN departments d ON e.dept_id = d.id
WHERE d.name = 'Engineering';
```

> JOINs let the query optimizer choose the fastest strategy (hash join, merge join, etc.) across the whole dataset at once instead of row by row.

---

#### 2. Scalability — Subqueries get slow as data grows

| Rows in table | Subquery time (approx) | JOIN time (approx) |
| ------------- | ---------------------- | ------------------ |
| 1,000         | fast                   | fast               |
| 100,000       | noticeable             | fast               |
| 1,000,000     | slow                   | fast               |

> Subqueries that feel fine in development can become production bottlenecks when real data volumes hit.

---

#### 3. Column access — Subqueries limit what you can select

A subquery in `WHERE` locks you to columns from the **outer table only**. If you want data from the second table, you're stuck.

```sql
-- Subquery: can only SELECT from employees, NOT from departments
SELECT name  -- works
-- SELECT d.name  -- impossible, d doesn't exist here
FROM employees
WHERE dept_id IN (SELECT id FROM departments WHERE name = 'Engineering');
```

```sql
-- JOIN: freely select from BOTH tables
SELECT e.name, d.name AS department  -- both columns available
FROM employees e
JOIN departments d ON e.dept_id = d.id
WHERE d.name = 'Engineering';
```

**Output:**
| name | department |
|-------|-------------|
| Alice | Engineering |
| Carol | Engineering |

---

#### 4. Readability — Subqueries nest, JOINs stay flat

```sql
-- Subquery: gets hard to follow as logic grows
SELECT name FROM employees
WHERE dept_id IN (
    SELECT id FROM departments
    WHERE location_id IN (
        SELECT id FROM locations WHERE country = 'Egypt'
    )
);
```

```sql
-- JOIN: relationships are clear and flat, easy to scan
SELECT e.name
FROM employees e
JOIN departments d ON e.dept_id = d.id
JOIN locations l ON d.location_id = l.id
WHERE l.country = 'Egypt';
```

> Each JOIN clearly states "connect this table on this condition" — no mental unwrapping required.

---

**Rule of thumb:** Default to JOINs. Use subqueries only when you need a scalar aggregate (e.g., `WHERE salary > (SELECT AVG(salary) FROM employees)`) or when the logic is genuinely clearer that way.
