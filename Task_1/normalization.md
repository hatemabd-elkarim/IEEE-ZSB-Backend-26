# Normalization
---
* A way to restructure a pre-designed database schema to reach a well-structured system.  
* A well-structured database is fully functionally dependent on the primary key, where the PK by itself only helps you get the other data rows.  
* Normalization rules involve changing one table into relational tables step by step.  

---

# Functional Dependencies
* Represents relationships between columns. For `A -> B`, for each unique value of `A` you can get a unique value of `B` (i.e., `A` uniquely determines `B`). The existence of `B` depends on the value of `A`.  
* For a not-normalized schema, you can find 3 types of functional dependencies:
  1. **Full functional dependency**: Each column is determined by the whole PK only.  
  2. **Partial functional dependency**: Some columns are determined by a part of the PK (in case of composite PK).  
  3. **Transitive functional dependency**: Some columns are determined by non-PK values.  

---

# Steps of Normalization
Starting with **Zero NF** (a table with multivalued and repeating groups) and by removing them, you reach **1NF**. Then you remove partial functional dependencies to reach **2NF**, and finally, by removing transitive functional dependencies, you reach **3NF**.  

---

# Working Example

### Original Table: Student_Grade_Report

| Student_Name | Student_Phone | Student_Address | Course_Title | Instructor_Name | Instructor_Dept | Dept_Building | Grade |
|--------------|---------------|----------------|-------------|----------------|----------------|--------------|-------|
|              |               |                |             |                |                |              |       |

*Primary Key:* Composite `(Student_Name, Course_Title)`  

---

## Step 1: Remove multivalued attributes (`Student_Phone`)  

### 1NF Tables:

**Student_Grade_Report**

| Student_Name | Student_Address | Course_Title | Instructor_Name | Instructor_Dept | Dept_Building | Grade |
|--------------|----------------|-------------|----------------|----------------|--------------|-------|
|              |                |             |                |                |              |       |

**Student_Phone**

| Student_Name | Student_Phone |
|--------------|---------------|
|              |               |

---

## Step 2: Remove partial dependencies (`Student_Address` depends on `Student_Name` only)  

### 2NF Tables:

**Student_Grade_Report**

| Student_Name | Course_Title | Instructor_Name | Instructor_Dept | Dept_Building | Grade |
|--------------|-------------|----------------|----------------|--------------|-------|
|              |             |                |                |              |       |

**Student_Address**

| Student_Name | City | Street | Zip |
|--------------|------|--------|-----|
|              |      |        |     |

**Student_Phone**

| Student_Name | Student_Phone |
|--------------|---------------|
|              |               |

---

## Step 3: Remove transitive dependencies  

* `Instructor_Dept` depends on `Instructor_Name` (not on `Student_Name` or `Course_Title`)  
* `Dept_Building` depends on `Instructor_Dept`  

### 3NF Tables:

**Student_Grade_Report**

| Student_Name (PK) | Course_Title (PK) | Instructor_Name (FK) | Grade |
|------------------|------------------|--------------------|-------|
|                  |                  |                    |       |

**Instructor_Dept**

| Instructor_Name (PK) | Instructor_Dept |
|---------------------|----------------|
|                     |                |

**Dept_Building**

| Dept_Name (PK) | Dept_Building |
|----------------|---------------|
|                |               |

**Student_Address**

| Student_Name (PK, FK) | City | Street | Zip |
|-----------------------|------|--------|-----|
|                       |      |        |     |

**Student_Phone**

| Student_Name (PK, FK) | Student_Phone |
|-----------------------|---------------|
|                       |               |
