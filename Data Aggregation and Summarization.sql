-- AGGREGATE FUNCTIONS

SELECT MIN(amount) AS "Minimum amount",
	   MAX(amount) AS "Maximum amount",
       AVG(amount) AS "Average amount",
       SUM(amount) AS "Sum amount"
FROM payments;

-- Counting the numbers of total orders and shipped orders

SELECT COUNT(requiredDate) AS "Total Orders",
	   COUNT(shippedDate) AS "Shipped Orders"
FROM orders; -- COUNT() only counts NOT NULL values.

-- Aggregate Functions on Strings and Dates.

SELECT MAX(paymentDate) AS "Latest Payment Made On",
	   MIN(paymentDate) AS "Oldest Payment Made On"
FROM payments;

SELECT COUNT(status) FROM orders
	WHERE status = "In Process";
    
SELECT MAX(CONCAT(firstName, " ", lastName)), MIN(CONCAT(firstName, " ", lastName)) FROM employees;

SELECT MAX(firstName), MIN(firstName) FROM employees;

-- ----------------------------
-- GROUP BY Clause
-- ----------------------------

SELECT COUNT(*), productLine FROM products GROUP BY productLine;

SELECT COUNT(*) FROM offices;

-- count of employees, office code, location that work in the same office

SELECT 
	COUNT(*), 
    CONCAT(office.addressLine1, " ", office.postalCode)AS "Location", 
    office.officeCode 
    FROM employees emp
JOIN offices office ON emp.officeCode = office.officeCode GROUP BY officeCode;

SELECT COUNT(officeCode), COUNT(*) FROM employees;

-- ----------------------------
-- HAVING Clause
-- ----------------------------

SELECT 
	COUNT(employeeNumber) AS empCount, 
    CONCAT(city)AS "Location", 
    office.officeCode 
    FROM employees emp
JOIN offices office USING(officeCode)
	-- WHERE emp.employeeNumber = (employeenumber % 2 = 0) Filtering before grouping
	GROUP BY officeCode 
    HAVING empCount > 4; -- Filtering after grouping

-- Why not use WHERE clause instead of HAVING clause on groups with agregates functions in conditions 
-- Because grouping is only done after the where clause and WHERE can only filter tuples using attributes in Table
-- and HAVING clause filter out GROUPS after grouping 

-- ORDER OF EXECUTION - FROM--> WHERE--> GROUP BY--> HAVING--> SELECT--> DISTINCT--> ORDER BY--> LIMIT.