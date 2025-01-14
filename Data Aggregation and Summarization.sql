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