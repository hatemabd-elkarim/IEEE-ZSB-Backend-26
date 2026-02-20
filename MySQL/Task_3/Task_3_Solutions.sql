-- 1. Invalid Tweets
SELECT tweet_id
FROM Tweets
WHERE LENGTH(content) > 15

-- 2. Fix Names
SELECT 
    user_id,
    CONCAT(
        UPPER(SUBSTRING(name, 1, 1)),
        LOWER(SUBSTRING(name, 2))
    ) AS name
FROM Users
ORDER BY user_id;

-- 3. Special Bonus
SELECT 
    employee_id,
    IF(MOD(employee_id,2) AND LEFT(name,1) != 'M', salary, 0)
    AS Bonus
FROM Employees
ORDER BY employee_id

-- 4. Patients with conditions (first sol with string methods, second sol with regex)
SELECT *
FROM Patients
WHERE LEFT(conditions, 5) = 'DIAB1' 
    OR INSTR(conditions, ' DIAB1');

SELECT *
FROM Patients
WHERE conditions LIKE 'DIAB1%'
    OR conditions LIKE '% DIAB1%'

-- 5. Total time spent
SELECT event_day AS day, emp_id, SUM(out_time - in_time) AS total_time
FROM Employees
GROUP BY event_day, emp_id

-- 6. Followers
SELECT user_id, count(follower_id) AS followers_count
FROM Followers
GROUP BY user_id
ORDER BY user_id

-- 7. Daily leads and partners
SELECT date_id, make_name, COUNT(DISTINCT lead_id) AS unique_leads, COUNT(DISTINCT partner_id) AS unique_partners
FROM DailySales
GROUP BY date_id, make_name

-- 8. Actors and Directors
SELECT actor_id, director_id
FROM ActorDirector
GROUP BY actor_id, director_id
HAVING COUNT(timestamp) >= 3

-- 9. Classes with at least 5 students
SELECT class
FROM Courses
GROUP BY class
HAVING COUNT(student) >= 5

-- 10. Game Analysis
SELECT player_id, MIN(event_date) AS first_login
FROM Activity
GROUP BY player_id

-- 11. Capital gain/loss
SELECT 
    stock_name,
    SUM(CASE 
            WHEN operation = 'Sell' THEN price
            WHEN operation = 'Buy'  THEN -price
        END) AS capital_gain_loss
FROM Stocks
GROUP BY stock_name;

-- 12. Second highest salary
SELECT MAX(salary) AS SecondHighestSalary
FROM Employee
WHERE salary < (
    Select Max(Salary)
    FROM Employee
)