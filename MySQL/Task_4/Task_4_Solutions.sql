-- 1. Combine two tables
SELECT P.firstName, P.lastName, A.city, A.state
FROM Person AS P LEFT OUTER JOIN Address AS A
ON P.personID = A.personID

-- 2. Replace employee id with unique id
SELECT EU.unique_id, E.name
FROM EmployeeUNI AS EU RIGHT OUTER JOIN Employees AS E
ON EU.id = E.id;

-- 3. 
SELECT customer_id, COUNT(V.customer_id) AS count_no_trans
FROM Visits V LEFT JOIN Transactions T
ON V.visit_id = T.visit_id
WHERE T.transaction_id IS NULL
GROUP BY V.customer_id

-- 4. Project Employees I
SELECT P.project_id, ROUND(AVG(experience_years),2) AS average_years
FROM Project AS P INNER JOIN Employee AS E
ON P.employee_id = E.employee_id
GROUP BY P.project_id

-- 5. Sales Person
SELECT name
FROM SalesPerson
WHERE name not in (
SELECT S.name
FROM SalesPerson AS S INNER JOIN Orders AS O
ON S.sales_id = O.sales_id
INNER JOIN Company AS C
ON O.com_id = C.com_id AND C.name = 'RED')

-- 6. Rising Temperature
Select X.id AS ID
FROM Weather AS X, WEATHER AS Y
WHERE DATEDIFF(X.recordDate, Y.recordDate) = 1 AND X.temperature > Y.temperature

-- 7. Average time of process per machine
SELECT X.machine_id, Round(AVG(Y.timestamp - X.timestamp),3) AS processing_time
FROM Activity X, Activity Y
WHERE X.machine_id = Y.machine_id AND X.process_id = Y.process_id AND X.activity_type = 'start' AND Y.activity_type = 'end'
GROUP BY X.machine_id

-- 8. Students and Examinations
    SELECT St.*, Su.*, COALESCE(E.attended_exams,0) as attended_exams
    FROM Students AS St CROSS JOIN Subjects AS Su
    LEFT OUTER JOIN
    (
        SELECT student_id, subject_name, COUNT(student_id) as attended_exams
        FROM Examinations
        GROUP BY student_id, subject_name
    ) AS E
    ON St.student_id = E.student_id AND Su.subject_name = E.subject_name
    ORDER BY St.student_id, Su.Subject_name

    -- Cleaner version
    SELECT St.*, Su.*, count(E.student_id) as attended_exams
    FROM Students AS St CROSS JOIN Subjects AS Su
    LEFT OUTER JOIN Examinations AS E
    ON St.student_id = E.student_id AND Su.subject_name = E.subject_name
    GROUP BY St.student_id, St.student_name ,Su.Subject_name
    ORDER BY St.student_id ,Su.Subject_name

-- 9. Managers with at least 5
SELECT X.name
FROM Employee X, Employee Y
WHERE X.id = Y.managerId
GROUP BY X.id
HAVING COUNT(Y.id) >= 5

-- 10. Confirmation Rate
SELECT S.user_id, 
ROUND(SUM(CASE WHEN C.action = 'confirmed' THEN 1.0 ELSE 0 END) / COUNT(*),2) AS confirmation_rate
FROM Signups AS S LEFT OUTER JOIN Confirmations C
ON S.user_id = C.user_id
GROUP BY S.user_id

-- 11. Product Sales Analysis
SELECT S.product_id, S.year AS first_year, S.quantity, S.price
FROM Sales S
JOIN (
    SELECT product_id, MIN(year) AS min_year
    FROM Sales
    GROUP BY product_id
) AS T
ON S.product_id = T.product_id AND S.year = T.min_year;

-- 12. Market Analysis I
SELECT U.user_id AS buyer_id, U.join_date, COUNT(O.order_id) AS orders_in_2019
FROM Users AS U LEFT OUTER JOIN Orders O
ON U.user_id = O.buyer_id AND YEAR(O.order_Date) = 2019
GROUP BY U.user_id
