## 1. WHERE vs HAVING

Both `WHERE` and `HAVING` are used to filter data, but they work at different stages of a SQL query, each with a different use-case.

### WHERE

- Filters rows before grouping happens.
- Cannot use aggregate functions like `SUM()` or `COUNT()` directly.
- Used to filter individuals.

### HAVING

- Filters groups after `GROUP BY`.
- Used with aggregate functions.
- Filters summarized results.

### Example

Suppose we have this table:

| id  | department | salary |
| --- | ---------- | ------ |
| 1   | IT         | 3000   |
| 2   | IT         | 4000   |
| 3   | HR         | 2000   |
| 4   | HR         | 2500   |

Using WHERE:

```sql
SELECT *
FROM Employees
WHERE salary > 2500;
```

This filters individual employees whose salary is greater than 2500.

Using HAVING:

```sql
SELECT department, COUNT(eid)
FROM Employees
GROUP BY department
HAVING COUNT(eid) > 20;
```

This filters departments that have more than 20 employees

---

## 2. DELETE vs TRUNCATE vs DROP

### DELETE

- Removes selected rows.
- Can use `WHERE`.
- Can be rolled back.
- Slower because it deletes row by row.

```sql
DELETE FROM Employees WHERE id = 1;
```

### TRUNCATE

- Removes all rows from a table.
- Cannot use `WHERE`.
- Faster than DELETE.
- Usually cannot be rolled back.

```sql
TRUNCATE TABLE Employees;
```

### DROP

- Deletes the entire table.
- Removes both data and table structure.
- Cannot be rolled back.

```sql
DROP TABLE Employees;
```

---

## 3. Logical Order of Execution

Even though we write SQL queries like this:

```sql
SELECT ...
FROM ...
WHERE ...
GROUP BY ...
HAVING ...
ORDER BY ...
```

The database does NOT execute them in this order.

### Actual Logical Order of Execution:

1. FROM
2. WHERE
3. GROUP BY
4. HAVING
5. SELECT
6. ORDER BY

### Example

```sql
SELECT department, SUM(salary)
FROM Employees
WHERE salary > 2000
GROUP BY department
HAVING SUM(salary) > 5000
ORDER BY department;
```

Execution steps:

- Read table (FROM)
- Filter rows (WHERE)
- Group rows (GROUP BY)
- Filter groups (HAVING)
- Select columns (SELECT)
- Sort results (ORDER BY)

---

## 4. COUNT(\*) vs COUNT(column_name)

Both count rows, but they treat NULL values differently.

### COUNT(\*)

- Counts all rows.
- Includes rows where columns contain NULL.

### COUNT(column_name)

- Counts only non-NULL values in that specific column.
- Ignores NULL values.

### Example

| id  | name  |
| --- | ----- |
| 1   | Hatem |
| 2   | NULL  |
| 3   | Ali   |

```sql
SELECT COUNT(*) FROM Students;
```

Result: 3

```sql
SELECT COUNT(name) FROM Students;
```

Result: 2 (NULL is ignored)

---

## 5. CHAR vs VARCHAR

Both store text, but they handle storage space differently.

### CHAR(10)

- Fixed length.
- Always stores exactly 10 characters.
- Adds spaces if the word is shorter.

If we store "Cat" in `CHAR(10)`:

```
"Cat       "
```

It stores 10 characters (7 extra spaces added).

### VARCHAR(10)

- Variable length.
- Stores only the actual characters.
- Uses only the needed space.

If we store "Cat" in `VARCHAR(10)`:

```
"Cat"
```

It stores only 3 characters (plus a small extra byte for length).
