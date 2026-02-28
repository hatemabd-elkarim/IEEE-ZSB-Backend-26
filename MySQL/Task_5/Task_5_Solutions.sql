-- 1. Duplicate emails
SELECT email
FROM Person
GROUP BY email
HAVING COUNT(id) > 1

-- 2. Remove Duplicate emails
DELETE FROM Person
WHERE id NOT IN (
    SELECT id FROM ( -- MySQL does NOT allow modifying a table while selecting from the same table in a subquery.
        SELECT MIN(id) AS id
        FROM Person
        GROUP BY email
    ) AS temp -- wrap the subquery in another SELECT
);

-- 3. Nth Highest Salary
CREATE FUNCTION getNthHighestSalary(N INT) RETURNS INT
BEGIN
    RETURN (
        SELECT DISTINCT salary
        FROM (
            SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
            FROM Employee
        ) AS ranked
        WHERE rnk = N
    );
END;

-- 4. Rank Scores
SELECT score,
DENSE_RANK() OVER(ORDER BY score DESC) AS 'rank'
FROM Scores

-- 5. Department Highest Salary
SELECT D.name AS Department, 
E.name AS Employee, 
E.salary AS Salary
FROM Department AS D 
INNER JOIN Employee AS E 
ON D.id = E.departmentId
INNER JOIN (
    SELECT departmentId, MAX(salary) AS maxSalary
    FROM Employee
    GROUP BY departmentId
) AS temp 
ON E.departmentId = temp.departmentId AND E.salary = temp.maxSalary