-- -------------------
-- INNER JOIN
-- -------------------

SELECT * FROM customers INNER JOIN payments ON customers.customerNumber = payments.customerNumber;

-- Use alias to table names

SELECT * FROM customers c INNER JOIN payments p ON c.customerNumber = p.customerNumber;

SELECT * FROM customers c INNER JOIN payments p ON c.customerNumber = p.customerNumber;

SELECT c.customerNumber, c.customerName, p.paymentDate, p.amount FROM customers c INNER JOIN payments p ON c.customerNumber = p.customerNumber;

-- --------------------------
-- Joining Multiple Tables
-- --------------------------

SELECT 
	o.orderNumber,
    o.status,
    c.customerName,
    c.salesRepEmployeeNumber,
    CONCAT(e.firstName, " ", e.lastName) AS "Sales Employee Name"
    FROM orders o 
JOIN customers c 
	ON c.customerNumber = o.customerNumber
JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber;

-- ---------------------------------------------
-- Self Join
-- ---------------------------------------------

SELECT 
	emp.employeeNumber,
    CONCAT(emp.firstName, " ", emp.lastName) AS "Employee Name",
    emp.jobTitle AS "Employee Role", 
	CONCAT(mgr.firstName, " ", mgr.lastName) AS "Manager Name",
    mgr.jobTitle AS "Manager Role"
    FROM employees emp
JOIN employees mgr ON emp.reportsTo= mgr.employeeNumber;

-- ------------------------------
--  Implicit Join
-- ------------------------------

SELECT p.customerNumber,
paymentDate,
amount,
customername
	FROM customers c, payments p
WHERE c.customerNumber = p.customerNumber;

-- Implicit Joins are not recomended since at a first glance it is not clear that it is Join query. 
-- And without WHERE clause the resultant Join will be a Cross Join having every tuple joined with every tuple in another table.

-- --------------------------------
-- Outer Join
-- --------------------------------

SELECT c.customerNumber, customerName, orderNumber  FROM customers c 
LEFT JOIN orders o ON c.customerNumber = o.customerNumber ORDER BY c.customerNumber, orderNumber;

-- --------------------------------
-- Self Outer Join
-- --------------------------------

SELECT emp.employeeNumber,
    CONCAT(emp.firstName, " ", emp.lastName) AS "Employee Name",
    emp.jobTitle AS "Employee Role", 
	CONCAT(mgr.firstName, " ", mgr.lastName) AS "Manager Name",
    mgr.jobTitle AS "Manager Role"  
	FROM employees emp
LEFT JOIN employees mgr ON emp.reportsTo = mgr.employeeNumber;

-- SELECT COUNT(employeeNumber) FROM employees WHERE reportsTo IS NULL;

-- -----------------------------------
-- USING Clause
-- -----------------------------------

SELECT 
	o.orderNumber,
    o.status,
    c.customerName,
    c.salesRepEmployeeNumber,
    CONCAT(e.firstName, " ", e.lastName) AS "Sales Employee Name"
    FROM orders o 
JOIN customers c 
	-- ON c.customerNumber = o.customerNumber
    USING (customerNumber)
JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber; -- USING clause can only be used when tables being joined have similar name of columns.

-- -----------------------------
-- NATURAL JOIN
-- -----------------------------

SELECT * FROM customers NATURAL JOIN orders;

SELECT customerNumber, customerName, orderNumber FROM customers NATURAL JOIN orders;
