
CREATE DATABASE FinalProject;

USE FinalProject;

CREATE TABLE Address(
	  AddressID VARCHAR(10) PRIMARY KEY NOT NULL,
	  Apt INT NOT NULL,
	  Street VARCHAR(20) NOT NULL,
	  City CHAR(10) NOT NULL,
	  State CHAR(10) NOT NULL,
	  ZipCode INT NOT NULL,
	  Country CHAR(10) NOT NULL
	  );


CREATE TABLE Passenger(
	  PassengerID VARCHAR(10) PRIMARY KEY NOT NULL,
	  FirstName CHAR(15) NOT NULL,
	  LastName CHAR(15) NOT NULL,
	  DOB Date,
	  AddressID VARCHAR(10) NOT NULL REFERENCES Address(AddressID),
	  ContactNo INT NOT NULL,
	  EmailID VARCHAR(30) NOT NULL,
	  PassportNo VARCHAR(10) NOT NULL
      );


CREATE TABLE Runway(
	  RunwayNo INT PRIMARY KEY NOT NULL,
	  Capacity VARCHAR(15) NOT NULL,
	  Length VARCHAR(15) NOT NULL
      );


	   CREATE TABLE Airline(
	  AirlineID CHAR(4) PRIMARY KEY NOT NULL,
	  AirlineName CHAR(20) NOT NULL
	  );


  CREATE TABLE Airport(
	  AirportID CHAR(3) PRIMARY KEY NOT NULL,
	  AirportName CHAR(40) NOT NULL,
	  City CHAR(20) NOT NULL,
	  State CHAR(4) NOT NULL,
	  Country CHAR(10) NOT NULL
      );



CREATE TABLE Flight(
	  FlightID VARCHAR(8) PRIMARY KEY NOT NULL,
	  FlightNo VARCHAR(7) NOT NULL,
	  AirlineID CHAR(4) NOT NULL REFERENCES Airline(AirlineID),
	  RunwayNo INT NOT NULL REFERENCES Runway(RunwayNo),
	  Type CHAR(15) NOT NULL,
	  Origin CHAR(3) NOT NULL REFERENCES Airport(AirportID),
	  Destination CHAR(3) NOT NULL REFERENCES Airport(AirportID),
	  ScheduledDate Date NOT NULL,
	  ScheduledTime Time NOT NULL
	  );


CREATE TABLE Ticket (
      TicketID VARCHAR(20) PRIMARY KEY NOT NULL,
      PassengerID VARCHAR(10) NOT NULL,
      FOREIGN KEY(PassengerID) REFERENCES Passenger (PassengerID),
      FlightID VARCHAR(8) NOT NULL REFERENCES Flight (FlightID),
      Class VARCHAR(40)
   );


CREATE TABLE InboundLuggage (
      LuggageID VARCHAR(20) PRIMARY KEY NOT NULL,
      Weight DECIMAL(8,2),
      TicketID VARCHAR(20) NOT NULL,
      FOREIGN KEY(TicketID) REFERENCES Ticket (TicketID)
  );
   


CREATE TABLE Staff (
     StaffID VARCHAR(20) PRIMARY KEY NOT NULL,
     FirstName VARCHAR(40) NOT NULL,
     LastName VARCHAR(40) NOT NULL,
     DOB date,
     ManagerID VARCHAR(20) NOT NULL,
     Designation VARCHAR(80),
     Department VARCHAR(80),
     ContactNo VARCHAR(20) NOT NULL,
     EmailID VARCHAR(40) NOT NULL
   );
  
  
CREATE TABLE LuggageCheckIn (
       LuggageID VARCHAR(20) PRIMARY KEY NOT NULL,
       StaffID VARCHAR(20) NOT NULL REFERENCES Staff (StaffID),
       TicketID VARCHAR(20) NOT NULL,
       FOREIGN KEY(TicketID) REFERENCES Ticket (TicketID),	
       Weight DECIMAL(8,2),
       CheckInTime TIME NOT NULL
     );
    
 
CREATE TABLE LuggageSorting (
       LuggageID VARCHAR(20) NOT NULL REFERENCES LuggageCheckIn (LuggageID),
       SortingSationNo INT NOT NULL,
       StaffID VARCHAR(20) NOT NULL REFERENCES Staff (StaffID),
       SortingTime TIME NOT NULL,
       PRIMARY KEY (LuggageID)
     );
    
    
    
  CREATE TABLE UnclaimedLuggage (
     LuggageID VARCHAR(20) NOT NULL REFERENCES LuggageCheckIn (LuggageID),
     TicketID VARCHAR(20) NOT NULL REFERENCES Ticket (TicketID),
     CarousalNO VARCHAR(20),
     PRIMARY KEY (LuggageID)
	 );
 
 
CREATE TABLE FlightLuggageLoading (
      LuggageID VARCHAR(20) NOT NULL REFERENCES LuggageSorting (LuggageID),
      StaffID VARCHAR(20) NOT NULL REFERENCES Staff (StaffID),
      LoadingTime TIME NOT NULL,
      PRIMARY KEY (LuggageID)
	  );
 

CREATE TABLE FlightStatus(
      FlightID VARCHAR(8) NOT NULL REFERENCES Flight(FlightID),
	  Status VARCHAR(10) NOT NULL,
	  ActualTime Time NOT NULL,
	  PRIMARY KEY(FlightID)
      );

USE rajput_divyesh;
DROP VIEW LuggageLost;
/*CREATE VIEW LuggageLost
AS
SELECT Pas.FirstName AS [Passenger First Name], Pas.LastName AS [Passenger Last Name], Adr.Apt, Adr.Street, Adr.City, Adr.State, Adr.ZipCode, Adr.Country, Pas.ContactNo AS [Passenger Contact No.],
Tkt.TicketID, LugChkin.StaffID, Tkt.FlightID, staff.FirstName AS [Staff First Name], staff.LastName AS [Staff Last Name], staff.ContactNo AS [Staff Contact No.]
FROM dbo.Address AS Adr INNER JOIN
             dbo.Passenger AS Pas ON Adr.AddressID = Pas.AddressID INNER JOIN
             dbo.Ticket AS Tkt ON Pas.PassengerID = Tkt.PassengerID INNER JOIN
             dbo.LuggageCheckIn AS LugChkin ON Tkt.TicketID = LugChkin.TicketID LEFT OUTER JOIN
             dbo.LuggageSorting AS LugSort ON LugChkin.LuggageID = LugSort.LuggageID LEFT OUTER JOIN
             dbo.FlightLuggageLoading AS LugLoad ON LugChkin.LuggageID = LugLoad.LuggageID INNER JOIN
             dbo.Staff AS staff ON LugChkin.StaffID = staff.StaffID 
WHERE LugChkin.LuggageID NOT IN (
			SELECT LgSort.LuggageID
			FROM dbo.LuggageSorting AS Lgsort
			) OR 
			LugSort.LuggageID NOT IN (
			SELECT  LgLoad.LuggageID
			FROM  dbo.FlightLuggageLoading AS LgLoad
			);

SELECT *
FROM LuggageLost;
*/
CREATE VIEW LuggageLost
AS
SELECT 
Tkt.TicketID, LugChkin.StaffID, Tkt.FlightID, staff.FirstName AS [Staff First Name], staff.LastName AS [Staff Last Name], staff.ContactNo AS [Staff Contact No.]
FROM 
             
             dbo.Ticket AS Tkt INNER JOIN
             dbo.LuggageCheckIn AS LugChkin ON Tkt.TicketID = LugChkin.TicketID LEFT OUTER JOIN
             dbo.LuggageSorting AS LugSort ON LugChkin.LuggageID = LugSort.LuggageID LEFT OUTER JOIN
             dbo.FlightLuggageLoading AS LugLoad ON LugChkin.LuggageID = LugLoad.LuggageID INNER JOIN
             dbo.Staff AS staff ON LugChkin.StaffID = staff.StaffID 
WHERE LugChkin.LuggageID NOT IN (
			SELECT LgSort.LuggageID
			FROM dbo.LuggageSorting AS Lgsort 
			) OR 
			LugSort.LuggageID NOT IN (
			SELECT  LgLoad.LuggageID
			FROM  dbo.FlightLuggageLoading AS LgLoad
			);

SELECT *
FROM LuggageLost;