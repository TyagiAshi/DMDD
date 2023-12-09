use [Ashi Tyagi];

Q-1:

CREATE FUNCTION dbo.GetTotalSales
(@year smallint, @month smallint)
RETURNS TABLE 
AS
RETURN( SELECT sot.TerritoryID as [TerritoryID], sot.Name as [TerritoryName], CAST(SUM(soh.TotalDue)AS int) as [TotalSale]
		FROM AdventureWorks2008R2.Sales.SalesOrderHeader soh
		JOIN AdventureWorks2008R2.Sales.SalesTerritory sot
		ON soh.TerritoryID= sot.TerritoryID
		WHERE MONTH(soh.OrderDate)=@month AND YEAR(soh.OrderDate)= @year
		GROUP BY sot.TerritoryID, sot.Name
		);
		GO
SELECT * From dbo.GetTotalSales(2005,10);


Q-2:


CREATE TABLE DateRange
(DateID INT IDENTITY, 
DateValue DATE,
DayOfWeek SMALLINT,
Week SMALLINT,
Month SMALLINT,
Quarter SMALLINT,
Year SMALLINT
);

CREATE PROCEDURE GetDateRange
@StartDate date,
@NumberOfDays int
AS BEGIN
	DECLARE @Counter int = 0;
	DECLARE @TempDate Date; 
	WHILE (@Counter < @NumberOfDays)
		BEGIN
			SET @TempDate= DATEADD(day,@Counter,@StartDate);
			INSERT INTO DateRange
			VALUES(
			@TempDate, DATEPART(WEEKDAY,@TempDate), DATEPART(WEEK,@TempDate), MONTH(@TempDate), DATEPART(QUARTER, @TempDate), YEAR(@TempDate));
			SET @Counter += 1;
		END
	RETURN;
END
GO

DECLARE @TheStartdate date;
DECLARE @range int;

SET @TheStartdate= '08/03/2022';
SET @range=3;

EXEC GetDateRange @TheStartDate, @range;

SELECT * FROM DateRange;


Q-3:


CREATE DATABASE University;
USE University;

create table Course
(CourseID int primary key,
CourseName varchar(50),
InstructorID int,
AcademicYear int,
Semester smallint);


create table Student
(StudentID int primary key,
LastName varchar (50),
FirstName varchar (50),
Email varchar(30),
PhoneNumber varchar (20));


create table Enrollment
(CourseID int references Course(CourseID),
StudentID int references Student(StudentID),
RegisterDate date,
primary key (CourseID, StudentID));


create table Fine
(StudentID int references Student(StudentID),
IssueDate date,
Amount money,
PaidDate date
primary key (StudentID, IssueDate));

CREATE OR ALTER FUNCTION CheckFinePayment (@StdID int)
RETURNS smallint
AS
BEGIN
   DECLARE @Count smallint=0;
   SELECT @Count = COUNT(StudentID) 
          FROM Fine
          WHERE StudentID = @StdID
          AND PaidDate = '';
   RETURN @Count;
END;

ALTER TABLE Enrollment ADD CONSTRAINT FineNotPaid CHECK (dbo.CheckFinePayment(StudentID) = 0);

INSERT INTO Student VALUES(5101,'Ashi', 'Tyagi', 'ashityagi@gmail.com', '2130'),
						  (5102,'Neelam', 'Pant', 'neelampant@gmail.com', '2140');

INSERT INTO Course VALUES(3210,'DAMG2160', 201, 2022, 2);

INSERT INTO Fine VALUES (5101, '08-07-2021', 2000, '12-12-2021'),
						(5102,'09-25-2021',2000,'');

INSERT INTO Enrollment VALUES(3210,5102,'11-16-2022');


CREATE TABLE Client
(ClientID INT PRIMARY KEY,
 LastName VARCHAR(50),
 FirsName VARCHAR(50),
 Email VARCHAR(30),
 Phone VARCHAR(20));

CREATE TABLE Seminar
(SeminarID INT PRIMARY KEY,
 Name VARCHAR(50),
 Description VARCHAR(500),
 StartDate DATE,
 EndDAte DATE);

CREATE TABLE Registration
(ClientID INT REFERENCES Client(ClientID),
 SeminarID INT REFERENCES Seminar(SeminarID),
 Notes VARCHAR(1000)
 PRIMARY KEY (ClientID, SeminarID));






Q-4:


USE [Ashi Tyagi];

CREATE TABLE Customer
(CustomerID VARCHAR(20) PRIMARY KEY,
CustomerLName VARCHAR(30),
CustomerFName VARCHAR(30),
CustomerStatus VARCHAR(10));


CREATE TABLE SaleOrder
(OrderID INT IDENTITY PRIMARY KEY,
CustomerID VARCHAR(20) REFERENCES Customer(CustomerID),
OrderDate DATE,
OrderAmountBeforeTax INT);


CREATE TABLE SaleOrderDetail
(OrderID INT REFERENCES SaleOrder(OrderID),
ProductID INT,
Quantity INT,
UnitPrice INT,
PRIMARY KEY (OrderID, ProductID));

GO
CREATE OR ALTER TRIGGER SalesAmount
ON SaleOrderDetail
AFTER INSERT AS
BEGIN
	UPDATE SaleOrder 
	SET OrderAmountBeforeTax = Sod.Quantity * Sod.UnitPrice
	From SaleOrder Sor 
	INNER JOIN SaleOrderDetail Sod
	ON Sor.OrderID = Sod.OrderID
END;
GO

INSERT INTO Customer VALUES(3120,'Gadge','Divya','Frequent');

INSERT INTO SaleOrder VALUES(3120,'11-16-2022',0);

INSERT INTO SaleOrderDetail VALUES(2,2120,4,2000);

SELECT * FROM SaleOrder;