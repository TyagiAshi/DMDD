--DAMG 6210 CRN: 16152, Northeastern University
--Airport Operation and Luggage Management System
--Project Group 16
--Student Name      NU ID
--Ashi Tyagi		002706544
--Divyesh Rajput	002788618
--Roshani Thakor	002968251
--Vinan Patwa		002772842
--Data Import wizard was used to populate the database tables. 
--Passenger table is populated using INSERT Statement.


CREATE DATABASE team_harvard;

USE team_harvard;

CREATE TABLE Address(
	  AddressID VARCHAR(10) PRIMARY KEY NOT NULL,
	  Apt INT NOT NULL,
	  Street VARCHAR(20) NOT NULL,
	  City VARCHAR(20) NOT NULL,
	  State VARCHAR(20) NOT NULL,
	  ZipCode INT NOT NULL,
	  Country VARCHAR(20) NOT NULL
	  );

CREATE TABLE Passenger(
	  PassengerID VARCHAR(10) PRIMARY KEY NOT NULL,
	  FirstName VARCHAR(40) NOT NULL,
	  LastName VARCHAR(40) NOT NULL,
	  DOB Date,
	  AddressID VARCHAR(10) NOT NULL REFERENCES Address(AddressID),
	  ContactNo BIGINT NOT NULL,
	  EmailID VARCHAR(40),
	  PassportNo VARBINARY(500) NOT NULL
      );


CREATE TABLE Runway(
	  RunwayNo INT PRIMARY KEY NOT NULL,
	  Capacity varchar(10) NOT NULL,
	  RunwayLength varchar(10) NOT NULL
      );

CREATE TABLE Airline(
	  AirlineID VARCHAR(10) PRIMARY KEY NOT NULL,
	  AirlineName VARCHAR(40) NOT NULL
	  );


 CREATE TABLE Airport(
	  AirportID VARCHAR(10) PRIMARY KEY NOT NULL,
	  AirportName VARCHAR(40) NOT NULL,
	  City VARCHAR(40) NOT NULL,
	  State VARCHAR(20) NOT NULL,
	  Country VARCHAR(20) NOT NULL
      );

CREATE TABLE Flight(
	  FlightID VARCHAR(10) PRIMARY KEY NOT NULL,
	  FlightNo VARCHAR(10) NOT NULL,
	  AirlineID VARCHAR(10) NOT NULL REFERENCES Airline(AirlineID),
	  RunwayNo INT NOT NULL REFERENCES Runway(RunwayNo),
	  Origin VARCHAR(10) NOT NULL REFERENCES Airport(AirportID),
	  Destination VARCHAR(10) NOT NULL REFERENCES Airport(AirportID),
	  ScheduleDate Date NOT NULL,
	  ScheduleTime Time NOT NULL
	  );

CREATE TABLE Ticket(
      TicketID VARCHAR(10) PRIMARY KEY NOT NULL,
      PassengerID VARCHAR(10) NOT NULL,
      FOREIGN KEY(PassengerID) REFERENCES Passenger (PassengerID),
      FlightID VARCHAR(10) NOT NULL REFERENCES Flight(FlightID),
      Class VARCHAR(20)
      );


CREATE TABLE InboundLuggage(
      LuggageID VARCHAR(10) PRIMARY KEY NOT NULL,
      Weight DECIMAL(8,2) NOT NULL,
      TicketID VARCHAR(10) NOT NULL,
      FOREIGN KEY(TicketID) REFERENCES Ticket(TicketID)
      );

CREATE TABLE Staff(
     StaffID VARCHAR(10) PRIMARY KEY NOT NULL,
     FirstName VARCHAR(40) NOT NULL,
     LastName VARCHAR(40) NOT NULL,
     DOB DATE NOT NULL,
     ManagerID VARCHAR(20),
     Designation VARCHAR(40) NOT NULL,
     Department VARCHAR(40) NOT NULL,
     ContactNo VARCHAR(20) NOT NULL,
     EmailID VARCHAR(40) NOT NULL
     );

CREATE TABLE LuggageCheckIn(
       LuggageID VARCHAR(10) PRIMARY KEY NOT NULL,
       StaffID VARCHAR(10) NOT NULL REFERENCES Staff(StaffID),
       TicketID VARCHAR(10) NOT NULL,
       FOREIGN KEY(TicketID) REFERENCES Ticket(TicketID),	
       Weight DECIMAL(8,2) NOT NULL,
       CheckInTime TIME NOT NULL
       );
    
 
CREATE TABLE LuggageSorting (
       LuggageID VARCHAR(10) NOT NULL REFERENCES LuggageCheckIn(LuggageID),
       SortingStationNo INT NOT NULL,
       StaffID VARCHAR(10) NOT NULL REFERENCES Staff(StaffID),
       SortingTime TIME NOT NULL,
       PRIMARY KEY (LuggageID)
       );
    
    
    
CREATE TABLE UnclaimedLuggage(
       LuggageID VARCHAR(10) NOT NULL REFERENCES InboundLuggage(LuggageID),
       TicketID VARCHAR(10) NOT NULL REFERENCES Ticket(TicketID),
       CarouselNo INT,
       PRIMARY KEY (LuggageID)
	   );
 
CREATE TABLE FlightLuggageLoading(
      LuggageID VARCHAR(10) NOT NULL REFERENCES LuggageSorting(LuggageID),
      StaffID VARCHAR(10) NOT NULL REFERENCES Staff(StaffID),
      LoadingTime TIME NOT NULL,
      PRIMARY KEY (LuggageID)
	  );
 

CREATE TABLE FlightStatus(
      FlightID VARCHAR(10) NOT NULL REFERENCES Flight(FlightID),
	  ActualTime TIME NOT NULL,
	  PRIMARY KEY(FlightID)
      );


--Table-level CHECK Constraint---------------------------------------------------------------------------- 
CREATE FUNCTION fn_checkLuggageCount(@TicketID varchar(10))
RETURNS smallint
AS
BEGIN


   DECLARE @Counter smallint = 0;
   DECLARE @Count int
   SELECT @Count = COUNT(LuggageID) 
          FROM LuggageCheckIn lc 
          WHERE lc.TicketID = @TicketID
		  GROUP BY lc.TicketID

   IF (@Count > 3 )
       SET @Counter = 1;
   
   RETURN @Counter;

END;

-- Add table-level CHECK constraint based on the new function for the LuggageCheckIn table
ALTER TABLE LuggageCheckIn ADD CONSTRAINT LimitLuggageQty CHECK (dbo.fn_checkLuggageCount(TicketID) = 0);

----------------------------------------------------------------------------------------------------------
--Computed Column #1 
--to calculate Flight Status: Early, On Time, Late

CREATE OR ALTER FUNCTION fn_CalcStatus( @FlightID VARCHAR(10))
RETURNS VARCHAR(10)
AS 
  BEGIN 
       DECLARE @Status varchar(10),
	           @ScheduleTime time,
			   @ActualTime time;

			   SELECT @ScheduleTime = ScheduleTime from Flight where FlightID = @FlightID;
			   SELECT @ActualTime = ActualTime from FlightStatus where FlightID = @FlightID;

			   IF (@ActualTime > @ScheduleTime)
			       SET @Status = 'Late';
			   ELSE 
			       BEGIN 
				         IF (@ActualTime < @ScheduleTime)
						    SET @Status = 'Early';
						 ELSE 
						    SET @Status = 'On Time';
				   END
               RETURN @Status;
  END

  
  ALTER TABLE FlightStatus
  ADD Status AS (dbo.fn_CalcStatus(flightID));
----------------------------------------------------------------------------------------------
--Computed Column #2
--Computing whether the flight is arriving or departing based on origin of the flight
  CREATE OR ALTER FUNCTION fn_flighttype( @FlightID varchar(10))
  RETURNS varchar(10)
  AS
    BEGIN
	     DECLARE @Type varchar(10),
		         @Origin varchar(10),
				 @Destination varchar(10)

				 SELECT @Origin = Origin from Flight where FlightID = @FlightID;
				 SELECT @Destination = Destination from Flight where FlightID = @FlightID;

				 IF (@Origin = 'JFK')
				     SET @Type = 'Departing';
				 ELSE 
				     SET @Type = 'Arriving';

		  RETURN @Type;
	END

	ALTER TABLE Flight
	ADD Type AS (dbo.fn_flighttype(FlightID));

------------------------------------------------------------------------------------------------------------
--1st View
-- Major tables used: LuggageCheckIn, Staff, FlightLuggageLoading, Passenger
--Purpose: To identify the lost luggage for a passenger and the associated staff personnel(checkin) with the missing luggage, so as to help expedite the inquiry process.
create view vwLostLuggageInformation 
as 
select LuggageID, lc.ticketID "Ticket ID" , tc.FlightID, ar.AirlineName, tc.PassengerID, ps.FirstName "Passenger First Name", ps.ContactNo "Passenger Contact No", ps.EmailID "Passenger EmailID", lc.StaffID, sf.firstname "Staff FirstName", sf.ContactNo "Staff ContactNo", Sf.EmailID "Staff EmailID"
from LuggageCheckIn lc inner join Staff sf 
on lc.StaffID = sf.StaffID inner join Ticket tc on lc.ticketID = tc.TicketID 
inner join Passenger ps on tc.passengerID = ps.PassengerID 
inner join flight f on f.FlightID = tc.FlightID 
inner join airline ar on ar.AirlineID = f.AirlineID 
where luggageID not in (select luggageID
							from FlightLuggageLoading); 

select * from vwLostLuggageInformation ;
------------------------------------------------------------------------------------------------------------
--view #2
--Major tables involved: Flight, FlightStatus, Airline 
--Purpose: To display all the information related to a flight and its current status

use team_harvard;
create view vw_AirlineName_Status
as 
select f.FlightID, f.AirlineID, AirlineName, f.Origin, f.Destination, f.ScheduleTime, fs.ActualTime, fs.Status
from Flight f inner join Airline ar 
on f.AirlineID = ar.AirlineID inner join FlightStatus fs 
on f.FlightID = fs.FlightID;


--view vw_AirlineName_Status inside a function 
CREATE FUNCTION fn_viewStatus
(@airlineID varchar (20), @status varchar (15))
returns table
as 
return (select * 
			from vw_AirlineName_Status
			where AirlineID = @airlineID and Status = @status);
GO

-- enter airline ID and status to view different flights based on the status entered
select * from dbo.fn_viewStatus('AS', 'Early'); --pass as arguments
select * from dbo.fn_viewStatus('G4', 'On Time');
select * from dbo.fn_viewStatus('AA', 'Late');

--select from view
select * from vw_AirlineName_Status;

drop function fn_viewStatus;

--------------------------------------------------------------------------------------------------------
--view #3
--Major tables involved: InboundLuggage, UnclaimedLuggage
--Purpose: To report the luggage bags which were unclaimed. These bags will have a ticket associated with it, which will 
-- in turn belong to a passenger. So, in this view we are focusing more on the passenger side and displaying their address.


create view vw_unclaimedLuggage_Passenger
as
select il.luggageID "Luggage ID",tc.FlightID, il.TicketID "Ticket ID" , ps.FirstName "Passenger First Name" , ps.LastName "Passenger Last Name", ps.ContactNo "Contact No", ps.EmailID, ad.apt "Apt" , ad.Street, ad.City, ad.State
from InboundLuggage il inner join UnclaimedLuggage ul
on il.LuggageID = ul.LuggageID inner join ticket tc on il.TicketID = tc.TicketID
inner join passenger ps on tc.PassengerID = ps.PassengerID 
inner join address ad on ps.AddressID = ad.AddressID;

select * from vw_unclaimedLuggage_Passenger;
--------------------------------------------------------------------------------------------------------------------------------------------------
--Trigger to prevent performing delete operation directly on the database table
Create trigger tr_prevent_delete on UnclaimedLuggage
instead of delete
as
Raiserror('Trigger preventing delete operation on table Unclaimed Luggage Table', 16,1)
Rollback transaction
return

--drop trigger tr_prevent_delete;
--------------------------------------------------------------------------------------------------------------------------------------------------
--Trigger created to stop entering luggages > 3 for a particular TicketID as per the business rules on inbound luggage

CREATE TRIGGER tr_restrict_bag
   ON  InboundLuggage
   INSTEAD OF INSERT
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION
        DECLARE @TicketID INT
		DECLARE @countLugg INT
        SELECT @TicketID=I.TicketId FROM inserted I

        SELECT @countLugg = count(LuggageID) from InboundLuggage where TicketID = @TicketID
		IF (@countLugg =3)
        BEGIN
            ROLLBACK TRANSACTION
            RAISERROR('Failed. Luggage Count cannot be more than 3 for a passenger!!!',16,1)
            RETURN
        END 
		else
		begin
		insert into InboundLuggage (LuggageID, TicketID, Weight) select * from Inserted i
		COMMIT TRANSACTION
		end
END
GO
----------------------------------------------------------------------------------------------------------------------------------------------------
--Encrypting PassportNo column in Passenger Table
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'Demo_P@sswOrd';

CREATE CERTIFICATE DemoCertificate
WITH SUBJECT = 'Final Project Demo Certificate',
EXPIRY_DATE = '2027-10-30';

CREATE SYMMETRIC KEY DemoSymmetricKey
WITH ALGORITHM = AES_128
ENCRYPTION BY CERTIFICATE DemoCertificate;

GO

CREATE TRIGGER encrypt_passport
ON Passenger
FOR INSERT
AS 
BEGIN

     OPEN SYMMETRIC KEY DemoSymmetricKey

     DECRYPTION BY CERTIFICATE DemoCertificate;
    

     UPDATE Passenger 
	 SET PassportNo = EncryptByKey(Key_GUID(N'DemoSymmetricKey'), convert(varbinary, PassportNo))

	CLOSE SYMMETRIC KEY DemoSymmetricKey;
	                    
END
------------------------------------------------------------------------------------------------------------------------------------------------
--Insert statement for Passenger Table

INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001101','Andres','Shaffer','2015-10-18','ADR1103',7718640915,'Andres.Shaffer@gmail.com',convert(varbinary, 'W413203'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001102','Shari','Hampton','2009-02-04','ADR1104',9899034650,'Shari.Hampton@gmail.com',convert(varbinary,'F247122'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001103','Vickie','Fuentes','1975-12-15','ADR1105',2978644136,'Vickie.Fuentes@gmail.com', convert(varbinary, 'X492241'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001104','Michelle','Marshall','2017-09-28','ADR1106',7501858023,'Michelle.Marshall@gmail.com',convert(varbinary,'S655843'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001105','Carol','Martinez','1988-04-20','ADR1107',2143605055,'Carol.Martinez@gmail.com',convert(varbinary,'F589378'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001106','Erica','Miller','1988-10-06','ADR1108',6302829867,'Erica.Miller@gmail.com',convert(varbinary,'G335366'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001107','Mason','Dalton','1971-05-16','ADR1109',5488830067,'Mason.Dalton@gmail.com',convert(varbinary,'E513455'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001108','Leslie','Miller','2007-12-26','ADR1110',1956996886,'Leslie.Miller@gmail.com',convert(varbinary,'J646888'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001109','Deborah','Hamilton','1982-11-15','ADR1111',8964390357,'Deborah.Hamilton@gmail.com',convert(varbinary,'Y823160'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001110','Johnathan','Cox','1994-01-04','ADR1112',1926002286,'Johnathan.Cox@gmail.com',convert(varbinary,'Z281392'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001111','Christopher','Williams','1982-06-05','ADR1113',2238847345,'Christopher.Williams@gmail.com',convert(varbinary,'B278310'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001112','Paul','Lopez','1964-05-16','ADR1114',4869225135,'Paul.Lopez@gmail.com',convert(varbinary,'S275511'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001113','Jennifer','Sparks','1986-01-19','ADR1115',8010914124,'Jennifer.Sparks@gmail.com',convert(varbinary,'X987013'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001114','Shelley','Thomas','1975-03-22','ADR1116',4875177182,'Shelley.Thomas@gmail.com',convert(varbinary,'B889407'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001115','Shirley','Edwards','1986-12-24','ADR1117',3791505298,'Shirley.Edwards@gmail.com',convert(varbinary,'D364863'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001116','Spencer','Carlson','1971-12-31','ADR1118',3692175682,'Spencer.Carlson@gmail.com',convert(varbinary,'Y954748'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001117','Gary','Baker','1987-11-05','ADR1119',4637849150,'Gary.Baker@gmail.com',convert(varbinary,'J922884'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001118','Elizabeth','Cantrell','2007-06-01','ADR1120',4853413136,'Elizabeth.Cantrell@gmail.com',convert(varbinary,'J356625'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001119','Alyssa','Marshall','2001-08-07','ADR1121',5741580826,'Alyssa.Marshall@gmail.com',convert(varbinary,'R298748'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001120','Sarah','Johnson','1966-08-15','ADR1122',2216437831,'Sarah.Johnson@gmail.com',convert(varbinary,'R845583'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001121','Ashley','Wyatt','1983-05-12','ADR1123',9125902647,'Ashley.Wyatt@gmail.com',convert(varbinary,'E827166'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001122','Yvonne','Robinson','2014-05-29','ADR1124',8502765752,'Yvonne.Robinson@gmail.com',convert(varbinary,'U907876'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001123','Joseph','Sullivan','1981-09-08','ADR1125',1648526213,'Joseph.Sullivan@gmail.com',convert(varbinary,'T625821'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001124','Kyle','Robertson','2005-03-09','ADR1126',5900054519,'Kyle.Robertson@gmail.com',convert(varbinary,'X204947'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001125','James','Jackson','1967-10-06','ADR1127',7439490455,'James.Jackson@gmail.com',convert(varbinary,'Z828565'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001126','Cameron','Campbell','2000-04-19','ADR1128',7361722777,'Cameron.Campbell@gmail.com',convert(varbinary,'E792919'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001127','Bryan','Garner','1991-04-21','ADR1129',1127536108,'Bryan.Garner@gmail.com',convert(varbinary,'P435511'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001128','Robert','Campbell','2012-07-19','ADR1130',4967069377,'Robert.Campbell@gmail.com',convert(varbinary,'H964108'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001129','David','Campbell','1992-03-21','ADR1131',2114843443,'David.Campbell@gmail.com',convert(varbinary,'B480683'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001130','Chelsea','Little','1989-07-22','ADR1132',2086179830,'Chelsea.Little@gmail.com',convert(varbinary,'E548231'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001131','Sean','Woods','1981-06-05','ADR1133',2615106445,'Sean.Woods@gmail.com',convert(varbinary,'K905217'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001132','Michelle','Grant','2006-01-29','ADR1134',5268569385,'Michelle.Grant@gmail.com',convert(varbinary,'A464265'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001133','Patrick','Hawkins','1972-07-15','ADR1135',9189418748,'Patrick.Hawkins@gmail.com',convert(varbinary,'F455127'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001134','John','Whitney','2015-09-14','ADR1136',5765583044,'John.Whitney@gmail.com',convert(varbinary,'N471313'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001135','Jose','Patterson','1992-06-10','ADR1137',6106118469,'Jose.Patterson@gmail.com',convert(varbinary,'K790857'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001136','Amy','Bradley','1976-02-10','ADR1138',7470385266,'Amy.Bradley@gmail.com',convert(varbinary,'Q838396'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001137','Richard','Burton','1995-01-24','ADR1139',8784003352,'Richard.Burton@gmail.com',convert(varbinary,'U428513'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001138','Martin','Ayala','1989-03-08','ADR1140',2875395357,'Martin.Ayala@gmail.com',convert(varbinary,'Y494333'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001139','Sonia','Silva','1965-03-14','ADR1141',7134171040,'Sonia.Silva@gmail.com',convert(varbinary,'K787562'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001140','Terry','Marshall','2011-03-26','ADR1142',9967619774,'Terry.Marshall@gmail.com',convert(varbinary,'K501806'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001141','Courtney','Schultz','1993-11-04','ADR1143',1597247683,'Courtney.Schultz@gmail.com',convert(varbinary,'K409287'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001142','April','Mercer','2002-02-11','ADR1144',3088117765,'April.Mercer@gmail.com',convert(varbinary,'N502676'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001143','Evan','Dominguez','1975-01-18','ADR1145',5202927007,'Evan.Dominguez@gmail.com',convert(varbinary,'K970734'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001144','Anne','Smith','2004-09-08','ADR1146',9434904854,'Anne.Smith@gmail.com',convert(varbinary,'E599176'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001145','Richard','Berry','1975-07-07','ADR1147',7629328920,'Richard.Berry@gmail.com',convert(varbinary,'O145133'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001146','Amy','Hanson','2017-09-11','ADR1148',6327443100,'Amy.Hanson@gmail.com',convert(varbinary,'S781865'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001147','Debra','Gutierrez','2000-03-24','ADR1149',2419555241,'Debra.Gutierrez@gmail.com',convert(varbinary,'P355312'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001148','Christina','Allen','1979-01-23','ADR1150',5606408848,'Christina.Allen@gmail.com',convert(varbinary,'T835453'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001149','Gina','Mccann','1987-04-28','ADR1151',3291104753,'Gina.Mccann@gmail.com',convert(varbinary,'J435062'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001150','Patrick','Thompson','2005-12-10','ADR1152',8164086634,'Patrick.Thompson@gmail.com',convert(varbinary,'P366003'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001151','Michael','James','2004-07-23','ADR1153',8683005323,'Michael.James@gmail.com',convert(varbinary,'Q104439'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001152','Martin','Arnold','1989-07-14','ADR1154',8027704617,'Martin.Arnold@gmail.com',convert(varbinary,'M103039'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001153','Alan','Hudson','1984-09-21','ADR1133',8636514633,'Alan.Hudson@gmail.com',convert(varbinary,'M384253'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001154','Diane','Ryan','1971-09-26','ADR1134',6304354358,'Diane.Ryan@gmail.com',convert(varbinary,'E797621'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001155','Sara','Cowan','1978-01-30','ADR1135',5189875479,'Sara.Cowan@gmail.com',convert(varbinary,'K121170'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001156','Erica','Rios','1993-01-24','ADR1136',3003018219,'Erica.Rios@gmail.com',convert(varbinary,'D570051'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001157','Gregory','Jordan','1985-10-08','ADR1137',6990591957,'Gregory.Jordan@gmail.com',convert(varbinary,'Y322799'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001158','Jeffrey','Dixon','1967-08-09','ADR1138',4795989953,'Jeffrey.Dixon@gmail.com',convert(varbinary,'H426844'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001159','David','Jacobs','1993-04-14','ADR1139',9888571972,'David.Jacobs@gmail.com',convert(varbinary,'J500573'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001160','Michele','Foster','2013-10-21','ADR1140',3534099190,'Michele.Foster@gmail.com',convert(varbinary,'D670017'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001161','Maria','Ortega','1980-04-04','ADR1141',4547587337,'Maria.Ortega@gmail.com',convert(varbinary,'L749087'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001162','Lauren','Castillo','1979-10-07','ADR1142',6534485246,'Lauren.Castillo@gmail.com',convert(varbinary,'Y976025'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001163','Rebecca','Steele','1982-08-18','ADR1143',8800306103,'Rebecca.Steele@gmail.com',convert(varbinary,'U942885'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001164','Jessica','Duncan','1968-03-24','ADR1144',7210452058,'Jessica.Duncan@gmail.com',convert(varbinary,'L318230'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001165','Ashley','Arnold','1996-04-17','ADR1105',3818418251,'Ashley.Arnold@gmail.com',convert(varbinary,'A348441'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001166','Rebekah','Hoffman','2011-04-13','ADR1106',7946509607,'Rebekah.Hoffman@gmail.com',convert(varbinary,'R246063'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001167','Todd','Esparza','1982-04-05','ADR1107',2241751511,'Todd.Esparza@gmail.com',convert(varbinary,'S691422'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001168','Brenda','Chang','1983-06-20','ADR1108',4963571520,'Brenda.Chang@gmail.com',convert(varbinary,'X293333'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001169','Michael','Brown','1979-03-04','ADR1123',6280007150,'Michael.Brown@gmail.com',convert(varbinary,'G417167'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001170','Jeffrey','Campbell','2001-11-08','ADR1124',4910191516,'Jeffrey.Campbell@gmail.com',convert(varbinary,'X105440'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001171','Lisa','Vaughan','1979-04-06','ADR1125',4468607107,'Lisa.Vaughan@gmail.com',convert(varbinary,'N628337'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001172','Kristy','Hoffman','1971-05-16','ADR1126',3952201696,'Kristy.Hoffman@gmail.com',convert(varbinary,'A521988'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001173','James','Archer','2001-11-01','ADR1127',1077821477,'James.Archer@gmail.com',convert(varbinary,'I853202'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001174','Samantha','Meyer','1965-12-08','ADR1125',5304776093,'Samantha.Meyer@gmail.com',convert(varbinary,'W117886'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001175','Jason','Deleon','2014-05-04','ADR1124',9068882771,'Jason.Deleon@gmail.com',convert(varbinary,'A544719'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001176','Katie','Cox','1992-03-24','ADR1125',2431241382,'Katie.Cox@gmail.com',convert(varbinary,'I409556'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001177','Michael','Smith','1988-11-29','ADR1126',5789434003,'Michael.Smith@gmail.com',convert(varbinary,'X340639'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001178','Julie','Patterson','2015-10-25','ADR1127',4748532693,'Julie.Patterson@gmail.com',convert(varbinary,'Z903511'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001179','Donald','Harris','1993-07-27','ADR1128',5268606938,'Donald.Harris@gmail.com',convert(varbinary,'T367204'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001180','Jennifer','Thomas','1976-08-20','ADR1123',8667474351,'Jennifer.Thomas@gmail.com',convert(varbinary,'P171144'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001181','Debbie','Burton','1981-07-28','ADR1124',2558268002,'Debbie.Burton@gmail.com',convert(varbinary,'Z669516'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001182','Mariah','Davis','1979-08-11','ADR1125',5456923249,'Mariah.Davis@gmail.com',convert(varbinary,'C996535'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001183','Nicole','Harrell','2006-12-12','ADR1126',9622327342,'Nicole.Harrell@gmail.com',convert(varbinary,'D384576'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001184','Brandon','Green','2010-08-26','ADR1127',9448758101,'Brandon.Green@gmail.com',convert(varbinary,'N829169'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001185','Lindsey','Moore','2017-06-06','ADR1128',1172609812,'Lindsey.Moore@gmail.com',convert(varbinary,'Y605201'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001186','Jennifer','Brown','1994-10-17','ADR1129',2660489388,'Jennifer.Brown@gmail.com',convert(varbinary,'M224247'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001187','Collin','Parker','1994-08-12','ADR1113',6143073580,'Collin.Parker@gmail.com',convert(varbinary,'T289521'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001188','Amy','Henson','2002-08-25','ADR1114',1701496196,'Amy.Henson@gmail.com',convert(varbinary,'D785093'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001189','Brian','Vasquez','1968-07-05','ADR1115',5988977832,'Brian.Vasquez@gmail.com',convert(varbinary,'Z238269'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001190','Sean','Howell','1975-06-15','ADR1109',2035942999,'Sean.Howell@gmail.com',convert(varbinary,'P488255'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001191','Jason','Holloway','1992-08-04','ADR1110',5598901950,'Jason.Holloway@gmail.com',convert(varbinary,'S479809'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001192','Patricia','Adams','1965-12-14','ADR1111',9433984649,'Patricia.Adams@gmail.com',convert(varbinary,'T938326'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001193','Ronald','Klein','1964-06-05','ADR1112',4440756506,'Ronald.Klein@gmail.com',convert(varbinary,'O437733'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001194','Yvonne','Arnold','1971-12-16','ADR1113',5843963998,'Yvonne.Arnold@gmail.com',convert(varbinary,'Q917894'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001195','Donald','Franklin','2007-04-17','ADR1114',3711420060,'Donald.Franklin@gmail.com',convert(varbinary,'E147700'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001196','Jessica','Johnson','2010-05-08','ADR1115',3352986669,'Jessica.Johnson@gmail.com',convert(varbinary,'I177884'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001197','James','Williams','1969-01-29','ADR1139',1760479211,'James.Williams@gmail.com',convert(varbinary,'N157099'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001198','Shannon','Dawson','1963-09-15','ADR1140',1882813307,'Shannon.Dawson@gmail.com',convert(varbinary,'N386647'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001199','Jennifer','Clark','1967-02-22','ADR1141',7191762844,'Jennifer.Clark@gmail.com',convert(varbinary,'S504833'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001200','William','Kramer','1997-05-02','ADR1142',6534735081,'William.Kramer@gmail.com',convert(varbinary,'D291427'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001201','Daniel','Wilson','1965-06-09','ADR1155',7112960742,'Daniel.Wilson@gmail.com',convert(varbinary,'A598507'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001202','Karen','Ho','1999-12-29','ADR1155',8339129238,'Karen.Ho@gmail.com',convert(varbinary,'Z613213'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001203','Obama','Michelle','2008-11-14','ADR1157',4077169197,'Obama.Michelle@gmail.com',convert(varbinary,'F903746'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001204','Johnny','Walsh','1997-05-06','ADR1158',7145121778,'Johnny.Walsh@gmail.com',convert(varbinary,'O797852'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001205','Charles','Atkins','1985-06-26','ADR1159',3592952932,'Charles.Atkins@gmail.com',convert(varbinary,'E645646'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001206','James','Torres','1966-09-24','ADR1158',4303235593,'James.Torres@gmail.com',convert(varbinary,'X414170'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001208','Kimberly','Hopkins','1989-05-09','ADR1159',8447912721,'Kimberly.Hopkins@gmail.com',convert(varbinary,'J480773'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001209','Jaime','Herman','1986-09-24','ADR1162',8614810363,'Jaime.Herman@gmail.com',convert(varbinary,'H189547'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001210','Charles','Bowman','2017-12-24','ADR1163',1653892027,'Charles.Bowman@gmail.com',convert(varbinary,'E897900'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001211','Gary','Tran','1966-01-18','ADR1164',5351832880,'Gary.Tran@gmail.com',convert(varbinary,'C871011'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001212','Paul','Calhoun','1978-07-01','ADR1162',3814957938,'Paul.Calhoun@gmail.com',convert(varbinary,'L701161'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001213','Benjamin','Ferguson','1987-03-15','ADR1159',1059957132,'Benjamin.Ferguson@gmail.com',convert(varbinary,'I247899'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001214','Nicholas','Carpenter','1978-05-14','ADR1159',8826229314,'Nicholas.Carpenter@gmail.com',convert(varbinary,'O124879'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001215','Lisa','Henderson','1968-09-14','ADR1164',1799938878,'Lisa.Henderson@gmail.com',convert(varbinary,'Q797194'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001216','Robert','Summers','1964-04-16','ADR1157',8743416817,'Robert.Summers@gmail.com',convert(varbinary,'V543905'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001217','Michael','Park','2001-08-06','ADR1156',7978301726,'Michael.Park@gmail.com',convert(varbinary,'T819163'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001218','David','Moore','1977-12-27','ADR1157',3421701010,'David.Moore@gmail.com',convert(varbinary,'Q566328'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001219','Jonathan','Adams','1993-06-02','ADR1159',6220598800,'Jonathan.Adams@gmail.com',convert(varbinary,'G670672'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001220','Megan','Parrish','2003-04-20','ADR1156',6824198728,'Megan.Parrish@gmail.com',convert(varbinary,'T966402'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001221','Robert','Jimenez','1968-08-16','ADR1159',1321264523,'Robert.Jimenez@gmail.com',convert(varbinary,'U185484'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001222','Stacey','Bright','1980-01-02','ADR1164',5055772808,'Stacey.Bright@gmail.com',convert(varbinary,'Y239693'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001223','Shawn','Fisher','2009-07-11','ADR1163',3095025843,'Shawn.Fisher@gmail.com',convert(varbinary,'T760586'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001224','Kenneth','Marks','1991-11-27','ADR1164',1791167670,'Kenneth.Marks@gmail.com',convert(varbinary,'D947821'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001225','Donna','Wallace','1980-05-22','ADR1163',5820781444,'Donna.Wallace@gmail.com',convert(varbinary,'C565187'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001226','Sarah','Ramos','1976-11-22','ADR1156',1635655072,'Sarah.Ramos@gmail.com',convert(varbinary,'X850843'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001227','Russell','Douglas','2003-05-19','ADR1157',9100276939,'Russell.Douglas@gmail.com',convert(varbinary,'C975408'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001228','Carol','Christensen','1976-06-11','ADR1156',6768035675,'Carol.Christensen@gmail.com',convert(varbinary,'I892212'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001229','Todd','Phillips','1981-06-27','ADR1159',9570597524,'Todd.Phillips@gmail.com',convert(varbinary,'S328532'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001230','Megan','Reed','1969-08-04','ADR1156',6950250904,'Megan.Reed@gmail.com',convert(varbinary,'G923456'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001231','Mrs.','Heather','1963-03-15','ADR1157',4269351654,'Mrs..Heather@gmail.com',convert(varbinary,'E376682'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001232','Joe','Cowan','2003-09-08','ADR1143',5910549026,'Joe.Cowan@gmail.com',convert(varbinary,'D931498'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001233','Anthony','Maddox','1964-01-05','ADR1156',5775200873,'Anthony.Maddox@gmail.com',convert(varbinary,'J966431'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001234','Sharon','Jimenez','1982-09-17','ADR1157',9501099072,'Sharon.Jimenez@gmail.com',convert(varbinary,'D814443'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001235','Julia','Gomez','1999-07-27','ADR1142',8305681693,'Julia.Gomez@gmail.com',convert(varbinary,'S971063'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001236','Melvin','Jackson','1980-08-07','ADR1143',6751800615,'Melvin.Jackson@gmail.com',convert(varbinary,'B855624'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001237','Tyler','Allen','2005-05-18','ADR1144',2444221731,'Tyler.Allen@gmail.com',convert(varbinary,'B643632'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001238','Tiffany','Weaver','2010-02-03','ADR1155',6154724657,'Tiffany.Weaver@gmail.com',convert(varbinary,'A196355'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001239','Chelsey','Holmes','2016-09-10','ADR1156',2432422394,'Chelsey.Holmes@gmail.com',convert(varbinary,'E263880'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001240','Theresa','Flowers','2009-09-25','ADR1157',8015616756,'Theresa.Flowers@gmail.com',convert(varbinary,'Q608278'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001241','Brandon','Jackson','1973-01-23','ADR1108',9212746416,'Brandon.Jackson@gmail.com',convert(varbinary,'E937220'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001242','Sally','Moore','1990-08-23','ADR1123',7149644777,'Sally.Moore@gmail.com',convert(varbinary,'T900285'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001243','Charlene','Chen','1974-08-16','ADR1124',3995357897,'Charlene.Chen@gmail.com',convert(varbinary,'I341200'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001244','Shannon','Wise','1988-10-01','ADR1125',4050488904,'Shannon.Wise@gmail.com',convert(varbinary,'L932905'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001245','Paul','Pace','1990-05-25','ADR1126',4251027852,'Paul.Pace@gmail.com',convert(varbinary,'Z418903'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001246','Timothy','Garner','1993-06-08','ADR1127',7757956107,'Timothy.Garner@gmail.com',convert(varbinary,'F596901'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001247','Jason','Kennedy','1995-04-27','ADR1123',1616285770,'Jason.Kennedy@gmail.com',convert(varbinary,'A921701'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001248','Thomas','Ferguson','1994-10-13','ADR1124',2646107640,'Thomas.Ferguson@gmail.com',convert(varbinary,'F772833'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001249','Renee','Martinez','2011-07-04','ADR1125',6353070094,'Renee.Martinez@gmail.com',convert(varbinary,'G301037'));
INSERT INTO Passenger(PassengerID,FirstName,LastName,DOB,AddressID,ContactNo,EmailID,PassportNo) VALUES ('P001250','Bradley','Henderson','2006-11-22','ADR1126',5024768320,'Bradley.Henderson@gmail.com',convert(varbinary,'A116768'));

