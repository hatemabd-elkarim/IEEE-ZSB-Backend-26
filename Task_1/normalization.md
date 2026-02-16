# Normalization
---
* A way to restructure a pre-designed database schema to reach well-structured system
* A well-structured database is fully functional dependent to the primary key, where pk by itself only help you get the other data rows
* Normalization rules involves changing one table into relational tables at each step
---
# Functional dependencies
* Represents relationships between columns where, For A -> B and for each unique value of A you can get a new value of B, i.e A uniquely determines the value of B, existing of B depends on the value of A
* For a not normalized schema you can find 3 types of functional dependencies:
1. Full functional dependencies: if each column is determined by the whole pk only
2. Partial functional dependencies: if you find some columns determined by a part of the pk (in case of composite pk)
3. Transitive functional dependencies: if you find some columns determined by non-pk values
---
# Steps of Normalization
 Starting with **Zero NF**, a table with multivalued and repeating groups and by removing them you reach **1NF**, then you remove partial functional dependencies to reach **2NF** and at last by removing transitive functional dependencies you get **3NF**
---
# Working example
Student_Grade__Report
| Student_Name | Student_Phone | Student_Address | Course_Title | Instructor_Name | Instructor_Dept | Dept_Building | Grade |
|--------------|--------------|----------------|-------------|------------------|----------------|--------------|-------|
|              |              |                |             |                  |                |              |       |
where pk is a composite(Student_Name, Course_title)

**Step 1:** remove multivalued attributes(student_phone) to a separate table with a foreign key of student_name
then we got 2 relational tables in 1NF
* Student_Grade_Report
| Student_Name | Student_Address | Course_Title | Instructor_Name | Instructor_Dept | Dept_Building | Grade |
|--------------|----------------|-------------|------------------|----------------|--------------|-------|
|              |                |             |                  |                |              |       |

* Student_Phone
| Student_Name | Student_Phone |
|--------------|--------------|
|              |              |

**Step 2:** remove partial dependencies (Student_Address depends on Student_Name only) to a separate table with a foreign key of student_name
then we got a third relational table in 2NF and one previoues table would be updated
* Student_Grade_Report
| Student_Name | Course_Title | Instructor_Name | Instructor_Dept | Dept_Building | Grade |
|--------------|-------------|------------------|----------------|--------------|-------|
|              |             |                  |                |              |       |

* Student_Address
| student_name | city | street | zip |
|--------------|------|--------|-----|
|              |      |        |     |

* Student_Phone
| Student_Name | Student_Phone |
|--------------|---------------|
|              |               |

**Step 3:** remove transitive dependencies (Instuctor_Dept depends on Instructor but not Student_name or course_title, Dept_Building depends on Instructor_Dept) and we keep foreign for Instructor_Name in the main table
then we got 2 more relational tables in 3NF and one previous table would be updated
* Student_Grade_Report
| Student_Name (pk) | Course_Title (pk) | Instructor_Name (fk) | Grade |
|-------------------|-------------------|----------------------|--------|
|                   |                   |                      |        |
Here each of instructor_name and grade depends on both of student_name, course_title as a whole pk
a fk for instructor_name is taken from instructor_dept table


* Instrcutor_dept
| Instructor_Name (pk) | Instructor_Dept (fk)|
|----------------------|---------------------|
|                      |                     |

* Dept_Building
| Dept_Name (pk) | Dept_Building (fk)|
|----------------|-------------------|
|                |                   |

* Student_Address
| student_Name (pk, fk) | city | street | zip |
|-----------------------|------|--------|-----|
|                       |      |        |     |

* Student_Phone
| Student_Name (pk, fk) | Student_Phone |
|-----------------------|---------------|
|                       |               |

