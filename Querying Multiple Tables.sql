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


