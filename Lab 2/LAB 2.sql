
2-1. Retrieve the salesperson ID, the most recent order date
and the total number of orders processed by each salesperson
for each salesperson. Use a column alias to make the report 
more presentable if a column heading is missing. 

Use CAST to display only the date of the order date. Exclude the orders 
which dont have a salesperson specified.

Sort the returned data by the total number of orders in
descending. 

Hints: (a) You need to work with the Sales.SalesOrderHeader table.
       (b) The syntax for CAST is CAST(expression AS data_type),
		   where expression is the column name we want to format and
		   we can use DATE as data_type for this question to display
           just the date. 


USE AdventureWorks2008R2
SELECT DISTINCT oh.SalesPersonID, Max(Cast (OrderDate as Date)) as "Order Date", COUNT(oh.SalesOrderID) as "Total No. of Orders"
FROM  Sales.SalesOrderHeader oh
WHERE oh.SalesPersonID > 0
GROUP BY SalesPersonID
ORDER BY "Total No. Of Orders" DESC;


2-2. Write a query to select the product id, name, and list price
 for the product(s) that have a list price greater than the 
 average list price plus $500. Use a column alias to make the report more presentable
 if a column heading is missing. Sort the returned data by the
 list price in descending.

 Hint: You’ll need to use a simple subquery to get the average
 list price and use it in a WHERE clause. 


SELECT po.ProductID, po.Name, po.ListPrice
FROM Production.Product po
WHERE po.ListPrice > (SELECT AVG(pr.ListPrice)
					  FROM Production.Product pr) + 500
ORDER BY po.ListPrice DESC;



2-3. Write a query to calculate the "orders to customer ratio" 
 (number of orders / unique customers) for each sales territory. 
 Return only the sales territories which have a ratio >= 5.
 Include the Territory ID and Territory Name in the returned data.
 Sort the returned data by TerritoryID. 



SELECT tr.TerritoryID, tr.Name, (CAST(COUNT(Oh.SalesOrderID) AS DECIMAL)/ COUNT (DISTINCT Oh.CustomerID) ) As "Orders to Customers Ratio"
FROM Sales.SalesTerritory tr
INNER JOIN Sales.SalesOrderHeader Oh
ON tr.territoryID = oh.territoryID
GROUP BY tr.TerritoryID, tr.Name
HAVING COUNT(Oh.SalesOrderID)/ CAST(COUNT (DISTINCT Oh.CustomerID) AS DECIMAL)>= 5
ORDER BY tr.TerritoryID;



2-4. Write a query to retrieve the total sold quantity for each product.
 Return only the products that have a total sold quantity greater than 3000
 and have the black color.
 
 Use a column alias to make the report look more presentable if a column
 heading is missing. Sort the returned data by the total sold quantity 
 in the descending order. Include the product ID, product name and 
 total sold quantity columns in the report.


 Hint: Use the Sales.SalesOrderDetail and Production.Product tables. 


SELECT Pr.ProductID, Pr.Name, SUM (sod.OrderQty) AS "Total Sold Quantity"
FROM Sales.SalesOrderDetail sod
INNER JOIN Production.Product Pr
ON sod.ProductID = Pr.ProductID
WHERE Color = 'Black'
GROUP BY Pr.ProductID, Pr.Name
HAVING SUM (sod.OrderQty) >3000
ORDER BY "Total Sold Quantity" DESC;



2-5. Write a query to retrieve the dates in which
 there was at least one order placed but no order
 worth more than $500 was placed. Use TotalDue
 in Sales.SalesOrderHeader as the order value.
 Return the "order date" and "total product quantity sold
 for the date" columns. The order quantity column is 
 in SalesOrderDetail. 
 
 Display only the date part of the 
 order date. Sort the returned data by the
 "total product quantity sold for the date" column in desc. 


SELECT DISTINCT Cast (soh.OrderDate as Date) as "Order Date", SUM(sod.OrderQty) AS "Total Product Quantity Sold for the Date"
FROM Sales.SalesOrderDetail sod
INNER JOIN Sales.SalesOrderHeader soh 
ON  soh.SalesOrderID = sod.SalesOrderID
WHERE soh.OrderDate NOT IN ( SELECT sh.OrderDate
							 FROM Sales.SalesOrderHeader sh
							 WHERE sh.TotalDue > 500 )
GROUP BY OrderDate
HAVING COUNT(soh.SalesOrderID) > 0
ORDER BY "Total Product Quantity Sold for the Date" DESC;




2-6. Write a query to return the year and total sales of orders 
on the new year day for each year. Please keep in mind 
the database has several years data. 

Include only orders which contained 42 or more unique products 
when calculating the total sales. 

Use TotalDue in SalesOrderHeader as an orders value when calculating 
the total sales. Return the total sales as an integer. Sort the 
returned data by year.


SELECT DISTINCT YEAR(soh1.OrderDate) AS "Year", CAST(SUM(soh1.TotalDue) as int) AS "Total Sales"
FROM Sales.SalesOrderHeader soh1 JOIN ( SELECT SalesOrderID 
										FROM Sales.SalesOrderDetail 
										GROUP BY SalesOrderID
										HAVING COUNT(DISTINCT ProductID) >= 42)sod
ON soh1.SalesOrderID= sod.SalesOrderID
WHERE MONTH(soh1.OrderDate)= '01' AND DAY(soh1.OrderDate)= '01'
GROUP BY YEAR(soh1.OrderDate)
ORDER BY YEAR(soh1.OrderDate);
												
 