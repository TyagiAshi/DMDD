

3-1. Modify the following query to add a column that identifies the
 frequency of repeat customers and contains the following values
 based on the number of orders:
 'No Order' for count = 0
 'One Time' for count = 1
 'Regular' for count range of 2-5
 'Often' for count range of 6-10
 'Loyal' for count greater than 10
 Give the new column an alias to make the report more readable.


USE AdventureWorks2008R2;
SELECT c.CustomerID, c.TerritoryID, FirstName, LastName,
COUNT(o.SalesOrderid) [Total Orders],
CASE 
	WHEN COUNT(o.SalesOrderid) =0
	THEN 'No Order'
	WHEN COUNT(o.SalesOrderid) =1
	THEN 'One Order'
	WHEN COUNT(o.SalesOrderid) BETWEEN 2 and 5
	THEN 'Regular'
	WHEN COUNT(o.SalesOrderid) BETWEEN 6 and 10
	THEN 'Often'
	WHEN COUNT(o.SalesOrderid) >10
	THEN 'Loyal'
END AS [Customer Loyalty]
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader o
 ON c.CustomerID = o.CustomerID
JOIN Person.Person p
 ON p.BusinessEntityID = c.PersonID
WHERE c.CustomerID > 25000
GROUP BY c.TerritoryID, c.CustomerID, FirstName, LastName;



 3-2. Modify the following query to add a rank without gaps in the
 ranking based on total orders in the descending order. Also
 partition by territory.

SELECT c.CustomerID, c.TerritoryID, FirstName, LastName,COUNT(o.SalesOrderid)  [Total Orders]
,DENSE_RANK() OVER
 (PARTITION BY c.TerritoryID ORDER BY COUNT(o.SalesOrderid)  DESC) AS Rank

FROM Sales.Customer c
JOIN Sales.SalesOrderHeader o
 ON c.CustomerID = o.CustomerID
JOIN Person.Person p
 ON p.BusinessEntityID = c.PersonID
WHERE c.CustomerID > 25000
GROUP BY c.TerritoryID, c.CustomerID, FirstName, LastName;




3-3. Retrieve the date, product id, product name, and the total
 sold quantity of the worst selling (by total quantity sold) 
 product of each date. If there is a tie for a date, it needs
 to be retrieved.
 
 Sort the returned data by date in descending.

WITH CTE 
AS
(
SELECT p.ProductID, CAST(Oh.OrderDate AS Date) AS OrderDate , p.Name, SUM(s.OrderQty) AS [Total Sold Quantity], DENSE_RANK() OVER (PARTITION BY Oh.OrderDate ORDER BY SUM(s.OrderQty)) AS RANK
FROM Production.Product p
JOIN Sales.SalesOrderDetail s
ON s.ProductID= p.ProductID
JOIN Sales.SalesOrderHeader Oh
ON s.SalesOrderID= oh.SalesOrderID
GROUP BY oh.OrderDate,  p.ProductID, p.Name

)

SELECT c.ProductID, c.Name,c.OrderDate, c.[Total Sold Quantity]
FROM CTE c
WHERE c.RANK= 1
ORDER BY c.OrderDate DESC;



3-4. Write a query to retrieve the most valuable salesperson of each year.
 The most valuable salesperson for each year is the salesperson who has
 made most sales for AdventureWorks in the year. 
 
 Calculate the yearly total of the TotalDue column of SalesOrderHeader 
 as the yearly total sales for each salesperson. If there is a tie 
 for the most valuable salesperson, your solution should retrieve it.
 Exclude the orders which didnt have a salesperson specified.
 Include the salesperson id, the bonus the salesperson earned,
 and the most valuable salespersons total sales for the year
 columns in the report. Display the total sales as an integer.
 Sort the returned data by the year.


WITH CTE4
AS
(
SELECT SUM(Soh.TotalDue) [Yearly Sales], Soh.SalesPersonID, Sp.Bonus, YEAR(Soh.OrderDate) AS [Year], DENSE_RANK () OVER (PARTITION BY YEAR(Soh.OrderDate) ORDER BY SUM(Soh.TotalDue) DESC) AS [RANK]
FROM Sales.SalesOrderHeader Soh
JOIN Sales.SalesPerson Sp
ON Soh.SalesPersonID = Sp.BusinessEntityID
WHERE Soh.SalesPersonID IS NOT NULL
GROUP BY YEAR(Soh.OrderDate),Soh.SalesPersonID,Sp.Bonus
)

SELECT CAST(CTE4.[Yearly Sales] As INTEGER) [Yearly Sales], CTE4.Bonus, CTE4.SalesPersonID, CTE4.Year
FROM CTE4
WHERE CTE4.RANK=1 
ORDER BY Year DESC;



3-5. Write a query to return the salesperson id, the most sold product id,
and the order id that contained the highest total order quantity for
each salesperson. The most sold product had the highest total order quantity.
Return only the salesperson(s) who had at least one order that contained
a total sold quantity greater than 450.

Exclude orders which dont have a salesperson for this query.
Sort the returned data by the salesperson id.


SELECT  x.SalesPersonID, ProductID, SalesOrderID
FROM (SELECT cd.SalesPersonID, cd.ProductID
	FROM(SELECT DENSE_RANK() OVER (PARTITION BY soh.SalesPersonID ORDER BY (SUM(OrderQty)) DESC) [RANK_2], SUM(OrderQty) [TotalQT], ProductID, SalesPersonID
		 FROM Sales.SalesOrderDetail sod
		 JOIN Sales.SalesOrderHeader soh
		 ON sod.SalesOrderID= Soh.SalesOrderID
		 WHERE sod.SalesOrderID IS NOT NULL
		 GROUP BY soh.SalesPersonID, sod.ProductId) cd
	Where cd.Rank_2 = 1)x
JOIN
(SELECT cp.SalesPersonId, cp.SalesOrderID
 FROM ( SELECT SUM (OrderQty) [TotalQt1], DENSE_RANK() OVER (PARTITION BY soh.SalesPersonID ORDER BY (SUM(OrderQty)) DESC) [Rank_1],
       SalesPersonId,soh.SalesOrderID
       FROM Sales.SalesOrderDetail sod
		JOIN Sales.SalesOrderHeader soh
		 ON sod.SalesOrderID= Soh.SalesOrderID
		 WHERE SalesPersonID IS NOT NULL
		GROUP BY soh.SalesPersonID, soh.SalesOrderID
		HAVING SUM(OrderQty)> 450) cp
	WHERE cp.Rank_1 =1) y
	ON x.SalesPersonID = y.SalesPersonID;


