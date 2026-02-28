## 1. Window Functions vs GROUP BY

### Fundamental Difference in Granularity

**GROUP BY** = Collapses rows into groups (reduces output rows)

**Window Functions** = Keeps all original rows (preserves output rows)

### Example

**Data:**
```
Employee | Department | Salary
---------|------------|-------
Alice    | Sales      | 5000
Bob      | Sales      | 6000
Charlie  | IT         | 7000
```

**Using GROUP BY:**
```sql
SELECT Department, MAX(Salary) AS MaxSalary
FROM Employee
GROUP BY Department
```
**Output (2 rows):**
```
Department | MaxSalary
-----------|----------
Sales      | 6000
IT         | 7000
```

**Using Window Function:**
```sql
SELECT Employee, Department, Salary,
       MAX(Salary) OVER(PARTITION BY Department) AS MaxSalary
FROM Employee
```
**Output (3 rows - original rows preserved):**
```
Employee | Department | Salary | MaxSalary
---------|------------|--------|----------
Alice    | Sales      | 5000   | 6000
Bob      | Sales      | 6000   | 6000
Charlie  | IT         | 7000   | 7000
```
---

## 2. Clustered vs Non-Clustered Indexes

### Leaf Nodes Difference

**Clustered Index Leaf Nodes:**
- Contain the **actual data rows** (all columns)
- The table data IS the index
- Like a phone book where names are sorted and you read the full entry directly

**Non-Clustered Index Leaf Nodes:**
- Contain only the **indexed column(s)** + a pointer to the actual data
- Separate structure from the table
- Like a book's index that tells you "go to page 47" to find the actual content

### Visual Example

**Clustered Index (B-Tree):**
```
        [50]
       /    \
    [20]    [80]
    /  \    /  \
[10] [30][60][90] ← Leaf nodes contain FULL rows:
                     [10, "Alice", "Sales", 5000]
                     [30, "Bob", "IT", 6000]
```

**Non-Clustered Index (B-Tree):**
```
        [50]
       /    \
    [20]    [80]
    /  \    /  \
[10] [30][60][90] ← Leaf nodes contain only:
                     [10, →pointer to row]
                     [30, →pointer to row]
```

### Why Only ONE Clustered Index?

**Reason:** The clustered index physically orders the actual data on disk. 

**Analogy:**
- If you sort a table by `EmployeeID` (clustered), the rows are physically stored in that order
- You cannot also physically sort the same rows by `Salary` at the same time
- But you CAN create multiple non-clustered indexes (like multiple book indexes pointing to the same pages) because the tree itself doesn't contain the table data but pointers to it

---

## 3. Filtered & Unique Indexes

### Filtered Index
An index that only includes rows meeting a specific condition.

**Example:**
```sql
CREATE INDEX idx_active_users 
ON Users(LastName)
WHERE IsActive = 1
```

**Advantages**

1. **Storage:** Takes less space (only indexes active users, not all users)
2. **Performance:** Faster queries on filtered data
3. **Maintenance:** Less overhead when updating inactive users

**Real Scenario:**
- Table has 1 million users
- Only 100,000 are active
- Filtered index is 90% smaller and 10x faster for active user queries

### Unique Index on Email Column

**How it SLOWS DOWN INSERT:**

When inserting a new email:
1. Database must check if email already exists (scan the index)
2. If duplicate found, reject the INSERT
3. If unique, insert into both table AND index
4. Index must be rebalanced (B-Tree maintenance)

**Example:**
```sql
INSERT INTO Users(Email) VALUES ('alice@email.com')
-- Step 1: Scan unique index for 'alice@email.com' ← Extra work
-- Step 2: If found, REJECT ← Extra check
-- Step 3: If not found, insert into table AND update index ← Double write
```

**How it SPEEDS UP SELECT:**

```sql
SELECT * FROM Users WHERE Email = 'alice@email.com'
-- Without index: Scan entire table (1 million rows)
-- With index: Jump directly to row via B-Tree (3-4 lookups)
```

**Trade-off:** Slower writes, faster reads.

---

## 4. Choosing the Right Index for Staging Tables

### Scenario
- Insert millions of rows quickly
- Read once
- Delete all rows

### Best Choice: **HEAP STRUCTURE** (No Clustered Index)

**Why?**

**Heap Advantages:**
1. **Fastest Inserts:** No sorting, just append rows to the end
2. **No Index Maintenance:** No B-Tree rebalancing overhead
3. **Minimal Storage:** No index structure to store

**Comparison:**

```
Heap (No Index):
INSERT → [Just append] -> Super fast for insertions

Clustered Index:
INSERT → [Find position] → [Insert] → [Rebalance tree] -> Slow for insertions but very important to cluster a unique_identifier(Ms SQL Server clusters PK by default) if your searches are done by it frequently, since you have only one available cluster to use

Non-Clustered Index:
INSERT → [Insert data] → [Update index] → [Rebalance] -> Slow for insertions but more useful if you make searches frequently with non_unique columns or composites of them, so you can as times as you want
```

**When You DO Need an Index:**
If you need to **search** the staging data before deleting, add a non-clustered index on search columns only.

---

## 5. Database Transactions - ACID (Atomicity)

**Atomicity** means a transaction either completes fully or not at all—no half-finished work.

### Example: Bank Transfer

**Scenario:** Transfer $100 from Alice to Bob

**Without Transaction:**
```sql
UPDATE Accounts SET Balance = Balance - 100 WHERE Name = 'Alice'; -- This runs
UPDATE Accounts SET Balance = Balance + 100 WHERE Name = 'Bob';   -- But for some crash this didn't run
```

**Disastrous Result:**
- Alice lost $100 
- Bob didn't received $100 
- $100 disappeared from the system

**With Transaction:**
```sql
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 100 WHERE Name = 'Alice';
    UPDATE Accounts SET Balance = Balance + 100 WHERE Name = 'Bob';
COMMIT;  -- Both succeed
```

**If Crash Happens:**
```sql
BEGIN TRANSACTION;
    UPDATE Accounts SET Balance = Balance - 100 WHERE Name = 'Alice';
    -- CRASH
    UPDATE Accounts SET Balance = Balance + 100 WHERE Name = 'Bob';
ROLLBACK;  -- Automatic rollback, Alice keeps her $100
```

---

