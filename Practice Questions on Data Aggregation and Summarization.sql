-- Q1.Total payments from each customer after a certain date

SELECT c.customerName,
		SUM(amount) AS custPayments,
		customerNumber
        FROM customers c 
JOIN payments p USING(customerNumber)
		WHERE paymentDate >= "2003-06-09" 
        GROUP BY customerNumber;
        
SELECT SUM(amount) AS customerPayments,
		customerNumber FROM payments
		WHERE paymentDate >= '2004-08-09'
        GROUP BY customerNumber;

-- SELECT MIN(paymentDate), MAX(paymentDate) FROM payments;
-- SELECT SUM(amount) FROM payments;

-- Q2.Value of each unique order sorted by total order values
-- i.e., To find the total cost of an order.

SELECT orderNumber, 
		SUM(quantityOrdered*priceEach) AS TotalCost
        FROM orderDetails GROUP BY orderNumber ORDER BY TotalCost DESC;

-- SELECT COUNT(*) FROM orderdetails;
-- SELECT count(*) FROM orders;

-- Q3.Value of each unique order sorted by total order values and customer name

SELECT customerName,
		orderNumber, 
		SUM(quantityOrdered*priceEach) AS TotalCost
        FROM orderDetails
JOIN orders USING(orderNumber) 
JOIN customers USING(customerNumber) 
GROUP BY orderNumber 
ORDER BY TotalCost DESC;

-- Q4.Value of each unique order sorted by total order values and customer name, customerNumber and SalesRepEmployee details

SELECT customerNumber, 
		customerName,
		orderNumber, 
		SUM(quantityOrdered*priceEach) AS TotalCost,
        e.employeeNumber AS SalesManNumber,
        CONCAT(e.firstName, " ", e.lastName) AS SalesManName
FROM orderDetails
JOIN orders USING(orderNumber) 
JOIN customers c USING(customerNumber)
JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
GROUP BY orderNumber 
ORDER BY TotalCost DESC;

-- Q5. Count the number of orders per customer

SELECT COUNT(*) AS numberOfOrdersByCust 
    FROM orders 
    GROUP BY customerNumber;
    
-- Q5. Count the number of orders per country
    
SELECT COUNT(*) AS numberOfOrderPerCountry,
		c.country,
        o.orderDate
        FROM orders o JOIN customers c USING(customerNumber)
        GROUP BY c.country, o.orderDate ORDER BY c.country;
        
-- Q6. find customers whose total order value > 80000 across all their orders
		
SELECT SUM(od.priceEach*od.quantityOrdered) AS totalOrderValue,
		customerNumber FROM orderdetails od
JOIN orders o USING(orderNumber)
JOIN customers c USING(customerNumber)
WHERE country = 'France'
GROUP BY customerNumber HAVING totalOrderValue > 80000 ORDER BY totalOrderValue;