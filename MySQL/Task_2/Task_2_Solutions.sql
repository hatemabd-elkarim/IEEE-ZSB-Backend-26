-- Recyclable and low fat products
SELECT product_id
FROM Products 
WHERE low_fats = 'Y' AND recyclable = 'Y';

-- Big countries
SELECT name, population, area
FROM World
WHERE area >= 3000000 OR population >= 25000000; 
-- NOTE integer notation is much faster in performance, using 3000000 is faster than using 3e6 beacuase it does not need conversion


-- Find customer referee
SELECT name
FROM Customer
WHERE  referee_id != 2 OR referee_id IS NULL;
