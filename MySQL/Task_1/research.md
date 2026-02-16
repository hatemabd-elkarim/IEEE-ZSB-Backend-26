# DBMS vs RDBMS Comparison

| Feature                | DBMS (Database Management System)                                         | RDBMS (Relational DBMS)                                                    |
| ---------------------- | ------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| **Data Storage**       | Stores data in files (delimited/fixed-width/CSV).                         | Stores data in **tables with rows and columns**.                           |
| **Relationships**      | No enforced relationships; data in separate files, difficult integration. | Supports **primary keys, foreign keys**, and relationships between tables. |
| **Normalization**      | Usually not supported; duplication is common.                             | Supports **normalization**, reduces redundancy, ensures consistency.       |
| **Integrity**          | No integrity enforcement; data can be inconsistent.                       | Integrity constraints: primary key, foreign key, unique, check, etc.       |
| **ACID Compliance**    | Often not ACID compliant.                                                 | Fully **ACID compliant** (Atomicity, Consistency, Isolation, Durability).  |
| **Data Types**         | Often all data stored as strings; poor data quality.                      | Supports **strong typing** for each column.                                |
| **Performance**        | Low performance for large datasets; searches slow.                        | Optimized queries with indexing and relational operations.                 |
| **Security**           | File systems may have weak or no security.                                | Advanced security with user roles, permissions, and access control.        |
| **Backup & Restore**   | Manual backup and restore required.                                       | Automated backup and recovery mechanisms.                                  |
| **Standardization**    | No standard query language.                                               | SQL is standardized across RDBMS systems.                                  |
| **Development Effort** | Long development time due to manual handling of files.                    | Faster development due to relational model, integrity, and query language. |
| **Examples**           | File-based systems, simple DBMS like early Microsoft Access.              | MySQL, PostgreSQL, Oracle, SQL Server.                                     |

---

# Difference between DDL and DML

## DDL (Data Definition Language)

- **Purpose:** Defines or modifies the **structure/Metadata** of the database (tables, schemas, indexes).
- **Common Commands:** `CREATE`, `ALTER`, `DROP`, `TRUNCATE`
- **Example:**

```sql
CREATE TABLE Students (
    StudentID INT PRIMARY KEY,
    Name VARCHAR(50),
    Age INT
);
```

## DML (Data Manipulation Language)

- **Purpose:** Manipulates the data stored in the database (insert, update, delete, select).
- **Common Commands:** `INSERT`, `UPDATE`, `DELETE`, `SELECT`

- **Example:**

```sql
INSERT INTO Students (StudentID, Name, Age)
VALUES (1, 'Hatem', 22);
```

---

## Why is normalization important in large systems?
Normalization is the process of **restructuring a database** to make it **well-organized and efficient**. For a large system like a university, normalization is important because it:  

- **Reduces duplication** of data and prevents inconsistencies.  
- **Organizes data into relational tables**, making the database easier to manage.  
- **Prevents DML anomalies** (logical errors):
  - **Insertion anomaly:** Adding new data may force duplicate or unnecessary entries.  
  - **Deletion anomaly:** Deleting a record might unintentionally remove other important data.  
  - **Modification anomaly:** Updating a value in one row can affect other rows.  

