// PART A

CREATE DATABASE "Ashi Tyagi";
GO

Use "Ashi Tyagi";

CREATE TABLE Term(
TermID int NOT NULL PRIMARY KEY,
Year varchar(10) NOT NULL,
Term varchar(50) NOT NULL);

CREATE TABLE Student (
StudentID int NOT NULL PRIMARY KEY,
LastName varchar(50) NOT NULL,
FirstName varchar(50) NOT NULL,
DateofBirth Date NOT NULL);

CREATE TABLE Course (
CourseID int NOT NULL PRIMARY KEY,
Name varchar(50) NOT NULL,
Description varchar(50) NOT NULL);


CREATE TABLE Enrollment(
StudentID int NOT NULL References Student(StudentID),
CourseID int NOT NULL References Course(CourseID),
TermID int NOT NULL References Term(TermID)
PRIMARY KEY (StudentID, CourseID, TermID)
);


//PART B-1

USE AdventureWorks2008R2;

With CTE
AS
(
SELECT Year(soh.OrderDate) as [Year], SUM(sod.OrderQty) as [Total Sales], sod.ProductID, DENSE_RANK() OVER (PARTITION BY Year(soh.OrderDate) ORDER BY SUM(sod.OrderQty) Desc) AS [RANK]
FROM sales.SalesOrderDetail sod
JOIN sales.SalesOrderHeader soh
ON sod.SalesOrderID= soh.SalesOrderID
GROUP BY Year(soh.OrderDate), ProductID
)
 

SELECT c.[Year], SUM (c.[Total Sales]) As [Total Sales Quantity],
STUFF(( SELECT ', ' +RTRIM(CAST(ProductID as char))
		FROM CTE c1
		WHERE c1.[RANK]<4 AND c1.[Year]= c.[Year]
		FOR XML PATH('')), 1, 2,'') AS [Product IDs]
FROM CTE c
WHERE c.[RANK]<4
GROUP BY c.[Year]
ORDER BY c.[Year];



//PART B-2


WITH CTE 
AS
(
SELECT soh.TerritoryID, sod.SalesOrderID,
DENSE_RANK() OVER (PARTITION BY soh.TerritoryID ORDER BY SUM(sod.OrderQty) Desc) AS [RANK]
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh
ON sod.SalesOrderID= soh.SalesOrderID
GROUP BY soh.TerritoryID, sod.SalesOrderID, soh.TotalDue
)

SELECT soh.TerritoryID, COUNT( DISTINCT sod.ProductID) AS [Unique Products Sold], CAST(MAX(soh.TotalDue) as int) AS [Highest Order Value] ,Cast(SUM(soh.TotalDue)as int) AS [Total Sales Amount], 
STUFF(( SELECT ', ' +RTRIM(CAST(c1.SalesOrderID as char))
		FROM CTE c1
		WHERE c1.[RANK]<4 AND c1.TerritoryID= soh.TerritoryID
		FOR XML PATH('')), 1, 2,' ') AS [Top 3 Orders]
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh
ON sod.SalesOrderID= soh.SalesOrderID
WHERE soh.SalesPersonID IS NOT NULL
GROUP BY soh.TerritoryID
Having SUM(soh.TotalDue)>1200000
ORDER BY soh.TerritoryID;





USE AdventureWorks2008R2

select (p.LastName + ', ' + p.FirstName) FullName, datepart(dw, sh.OrderDate) Weekday, count(SalesOrderID) TotalOrder
from Sales.SalesOrderHeader sh
join Person.Person p
on sh.SalesPersonID = p.BusinessEntityID
group by p.LastName + ', ' + p.FirstName, datepart(dw, sh.OrderDate)
order by FullName;

select FullName, [1], [2], [3], [4], [5], [6], [7]
FROM (select (p.LastName + ', ' + p.FirstName) AS FullName, datepart(dw, sh.OrderDate) as "Weekday", SalesOrderID
from Sales.SalesOrderHeader sh
join Person.Person p
on sh.SalesPersonID = p.BusinessEntityID) SourceTable
PIVOT
(count(SalesOrderID) 
 FOR "Weekday" IN
 ([1], [2], [3], [4], [5], [6], [7])) AS PivotTable;



//PART C


WITH Parts(AssemblyID, ComponentID, PerAssemblyQty, EndDate, ComponentLevel) AS
(
 SELECT b.ProductAssemblyID, b.ComponentID, b.PerAssemblyQty,
 b.EndDate, 0 AS ComponentLevel
 FROM Production.BillOfMaterials AS b
 WHERE b.ProductAssemblyID = 992 AND b.EndDate IS NULL
 UNION ALL
 SELECT bom.ProductAssemblyID, bom.ComponentID, bom.PerAssemblyQty,
 bom.EndDate, ComponentLevel + 1
 FROM Production.BillOfMaterials AS bom 
 INNER JOIN Parts AS p
 ON bom.ProductAssemblyID = p.ComponentID AND bom.EndDate IS NULL
)
SELECT AssemblyID, ComponentID, Name, PerAssemblyQty, ComponentLevel 
FROM ( SELECT AssemblyID, ComponentID, Name, PerAssemblyQty, ComponentLevel,
		DENSE_RANK() OVER (ORDER BY ListPrice Desc) AS [RANK]
		FROM Parts as P
		INNER JOIN Production.Product AS pr
		ON p.ComponentID = pr.ProductID
		WHERE p.ComponentID NOT IN ( SELECT p.AssemblyID FROM Parts P)
		AND ListPrice IS NOT NULL) t

WHERE t.[Rank]=1
ORDER BY ComponentLevel, AssemblyID, ComponentID;
