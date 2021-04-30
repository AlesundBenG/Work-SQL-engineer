---------------------------------------------------------------------

--Идентификатор назначения.
DECLARE @servID INT
SET @servID = 4439067

--Льготодержатель.
DECLARE @personalCardID INT
SET @personalCardID = 1645901  

---------------------------------------------------------------------

--Изменение.
UPDATE servServ
SET servServ.A_PERSONOUID = @personalCardID 
FROM ESRN_SERV_SERV servServ --Назначения МСП.   
WHERE servServ.OUID = @servID

---------------------------------------------------------------------