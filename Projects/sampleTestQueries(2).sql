--Hi, this is Divyesh.

--Welcome to DAMG 6210 Fall'22 Semester. How are we doing today? 
--Go through my comments and call me if you have some doubts. 
-- I haven't gone through the encryption part yet. 

--insert into UnclaimedLuggage values ('L005208', 001234, 23);

--------------------------------------------------------------------------------------------------------------------
-- trigger to prevent performing delete operation directly on the db table
----change table names and use this same trigger logic to stop unnecessary deletion on any table or to enforce integrity
Create trigger tr_prevent_delete on UnclaimedLuggage
instead of delete
as
Raiserror('Trigger preventing delete operation on table', 16,1)
Rollback transaction
return



--delete from UnclaimedLuggage;
-------------------------------------------------------------------------------------------------------------------
--preventing insert
--change table names and use this same trigger logic to stop unnecessary insertion on any table or to enforce integrity
Create trigger tr_prevent_insert on UnclaimedLuggage
instead of insert
as
Raiserror('Trigger preventing insert operation on table', 16,1)
Rollback transaction
return

------------------------------------------------------------------------------------------------------------------
--Trigger created to stop entering luggages > 3 for a particular TicketID as per the business Rules on inbound luggage

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
            RAISERROR('Failed. Luggage Count > 3',16,1)
            RETURN
        END 
		else
		begin
		insert into InboundLuggage (LuggageID, TicketID, Weight) select * from Inserted i
		COMMIT TRANSACTION
		end
END
GO
drop trigger tr_restrict_bag;

insert into InboundLuggage values ('L001234', 741371, 23);
---------------------------------------------------------------------------------------------------------------------


use team_harvard;

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


alter table Flight drop column Type;

select * from Staff;
---------------------------------------------------------------------------------------------------------------------
--Create Computed Column, --v01_divyesh
create function fn_CalcType (@Origin varchar(20))
returns varchar(20)
as 
begin 
declare @type varchar(30); 
	select @type = case @Origin
				when 'JFK' then 'Departing'
				else 'Arriving'
				end;
	return @type;
end

alter table Flight 
add Type as (dbo.fn_CalcType(Origin));


--------------------------------------------------------------------------------------------------------------------
--3rd choice. not exactly useful in my point of view. feel free to jump in and make changes to it.
--view created to combine Runway and Flights
create view vw_Utilization_score
as 
select f.RunwayNo, rn.Capacity, count(FlightID) as "Total_Flights"
from Flight f inner join Runway rn 
on f.RunwayNo = rn.RunwayNo
group by f.RunwayNo, rn.Capacity;

--function + view inside to calculate efficieny;
CREATE FUNCTION fn_viewUtilization
(@runwayNo int)
returns float
as 
begin 
declare @util float;
select @util = (Total_flights / Capacity) * 100
		from vw_Utilization_score
		where RunwayNo = @runwayNo;
return @util;
end
GO

-- Execute the new function
SELECT dbo.fn_viewUtilization(2) as "Utilization Score";

drop function fn_viewUtilization;
--------------------------------------------------------------------------------------------------------------------


--vinan's code
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

----------------------------------------------------------------------------------------------------------
--2nd main view according to me. Feel free to update it and let me know.
--2nd view
use team_harvard;
create view vw_AirlineName_Status
as 
select f.FlightID, f.AirlineID, AirlineName, f.Origin, f.Destination, f.ScheduleTime, fs.ActualTime, fs.Status
from Flight f inner join Airline ar 
on f.AirlineID = ar.AirlineID inner join FlightStatus fs 
on f.FlightID = fs.FlightID;

select * from UnclaimedLuggage;
select * from InboundLuggage;

select * from Flight;

--view inside a function which 
CREATE FUNCTION fn_viewStatus
(@airlineID varchar (20), @status varchar (15))
returns table
as 
return (select * 
			from vw_AirlineName_Status
			where AirlineID = @airlineID and Status = @status);
GO

-- enter airline ID and status to view different flights based on the status entered
select * from dbo.fn_viewStatus('AS', 'early');

select * from vw_AirlineName_Status;

drop function fn_viewStatus;

----------------------------------------------------------------------------------------------------'
use rajput_divyesh;

select * from flight;
select * from Passenger;
select * from Address; 
select * from Airline;
select * from Airport; 
select * from Ticket;
select * from FlightStatus;

drop table Passenger;


--------------------------------------------------------------------------------------------------------

select luggageID
from InboundLuggage il inner join Unclaimed
