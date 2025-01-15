-- -------------------------
-- Sub Queries
-- -------------------------

-- Find the products that have same product line as of "1917 Grand Touring Sedan"

SELECT * FROM 
		products 
        WHERE productLine IN 
        (SELECT productLine 
			FROM products WHERE productName = "1917 Grand Touring Sedan");
            
SELECT * FROM 
		products 
        WHERE productLine = 
        (SELECT productLine 
			FROM products WHERE productName = "1917 Grand Touring Sedan");
            
-- Q2. Find out cars that are costlier than a praticular model "1936 Mercedes-Benz 500K Special Roadster"

SELECT * FROM 
		products WHERE MSRP > 
			(SELECT MSRP
				FROM products WHERE productName = "1936 Mercedes-Benz 500K Special Roadster") 
					AND productLine LIKE "%car%" ORDER BY MSRP DESC;
                    
SELECT * FROM 
		products WHERE MSRP > 
			(SELECT MSRP
				FROM products WHERE productName = "1936 Mercedes-Benz 500K Special Roadster") 
					AND productLine REGEXP("car") ORDER BY MSRP DESC;
                    
-- ---------------------------------------
-- Sub Queries with AGGREGATION
-- ---------------------------------------

-- Find the cars which are costlier tha the average cost of all cars.

SELECT * FROM 
		products WHERE 
        productLine REGEXP("car") AND 
        MSRP > (SELECT AVG(MSRP) FROM products WHERE productLine REGEXP("car")) ORDER BY MSRP DESC;

-- Customers who have never placed an order (Subqueries and Joins)

-- Using Sub Query 
SELECT * FROM customers 
	WHERE customerNumber 
    NOT IN(SELECT DISTINCT customerNumber FROM orders) 
    ORDER BY customerNumber;
    
-- Using Joins
SELECT c.* FROM customers c 
LEFT JOIN orders o 
	USING(customerNumber) 
	WHERE o.orderNumber IS NULL ORDER BY customerNumber;
    
-- Customer who have ordered the product with productCode "S18_1749"

-- Using SubQueries
SELECT c.*
FROM customers c 
WHERE customerNumber IN 
	(SELECT customerNumber
		FROM orders o WHERE orderNumber IN
			(SELECT DISTINCT orderNumber FROM orderdetails WHERE productCode = "S18_1749")) ORDER BY customerNumber DESC;
            
-- Using Joins
SELECT DISTINCT o.customerNumber
FROM orders o
JOIN orderdetails od ON od.orderNumber = o.orderNumber AND od.productCode = "S18_1749" ORDER BY customerNumber DESC;

-- ------------------------------------
-- ALL Keyword
-- ------------------------------------

-- Find Products that are costlier than all Trucks

SELECT * FROM products WHERE MSRP >
	(SELECT MAX(MSRP) FROM products WHERE productLine REGEXP("truck"))ORDER BY MSRP; -- using MAX()
    
SELECT * FROM products WHERE MSRP > ALL
	(SELECT MSRP FROM products WHERE productLine REGEXP("truck"))ORDER BY MSRP;

-- compare a value with a set of all values, returns true if and only if the value being compared is satifying the condition with each and every value in the set of values.

-- ------------------------
-- ANY keyword
-- ------------------------

-- Find customers who have made atleast two payments

SELECT * FROM customers 
WHERE customerNumber = ANY(SELECT customerNumber FROM payments GROUP BY customerNumber HAVING COUNT(customerNumber) >= 2);
-- compare a value with a set of all values, returns true if and only if the value being compared is satifying the condition with any of the value in the set of values.
