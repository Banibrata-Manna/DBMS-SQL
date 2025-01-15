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