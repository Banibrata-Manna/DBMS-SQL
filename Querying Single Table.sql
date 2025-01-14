SELECT * FROM employees ORDER BY firstName;

SELECT productCode,
		productName, 
        buyPrice, 
        MSRP AS "sellingprice",
        (MSRP*0.90) AS discountedPrice
FROM products;

SELECT * FROM payments;

SELECT * FROM payments WHERE NOT (amount <=40000 AND amount >= 20000);
-- NOT WILL nagate all the operators in the brackets whether it is arithmatic or logical and is not recomended.
-- AND has higher preference.

SELECT * FROM payments WHERE amount >= 40000 OR amount <= 20000;

SELECT * FROM payments WHERE paymentDate >= '2005-06-01' ORDER BY paymentDate DESC;
-- always specify date inside single quotes.

SELECT MIN(creditLimit) AS "Minimum", MAX(creditLimit) AS "Maximum" FROM customers;

SELECT * FROM employees WHERE officeCode NOT IN (1,2,4);

SELECT * FROM customers WHERE creditLimit BETWEEN 4000 AND 40000;

SELECT * FROM payments WHERE paymentDate BETWEEN '2004-06-06' AND '2006-03-03' ORDER BY paymentDate DESC;

SELECT * FROM employees WHERE jobTitle LIKE "%sale%";

SELECT * FROM employees WHERE jobTitle LIKE "s%";


SELECT * FROM employees WHERE firstName LIKE "___y";

SELECT * FROM employees WHERE firstName LIKE "%y";

SELECT * FROM employees WHERE jobTitle REGEXP "^Sale";

--  Regular Expressions

SELECT * FROM employees WHERE jobTitle REGEXP("^sales"); -- ^ is for begining

SELECT * FROM employees WHERE jobTitle REGEXP("rep$"); -- $ id for ending

SELECT * FROM employees WHERE firstName REGEXP("^[abtp]") ORDER BY firstName;

SELECT * FROM employees WHERE firstName REGEXP("^A|^B|^T") ORDER BY firstName;

SELECT * FROM employees WHERE firstName REGEXP("^[a-f]") ORDER BY firstName;

SELECT * FROM employees WHERE firstName REGEXP("^[A-H]|lie$") ORDER BY firstName;

SELECT * FROM customers WHERE phone REGEXP("555$");

-- IS NULL 

SELECT * FROM orders WHERE shippedDate IS NULL OR comments IS NULL;	

SELECT * FROM customers WHERE state IS NOT NULL ORDER BY state;

SELECT customerNumber, contactFirstName, contactLastName, city FROM customers ORDER BY city DESC; -- ORDER BY single column

SELECT customerNumber, contactFirstName, contactLastName, city FROM customers ORDER BY city DESC, contactLastName; -- sorting the tuples at two levels, first sorting desc by city and if multiple customers exist in a city then they will be sorted asc.

SELECT * FROM customers LIMIT 20;

SELECT * FROM customers LIMIT 20 OFFSET 20;

SELECT * FROM customers LIMIT 20,20;

SELECT * FROM customers ORDER BY creditLimit DESC LIMIT 5;

