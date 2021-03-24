---------------------------------------------------------------------

--Идентификатор назначения.
DECLARE @servID INT
SET @servID = 4384500

--Лицо, на основании которого..., на которого нужно заменить.
DECLARE @personalCardID INT
SET @personalCardID = 465171 

---------------------------------------------------------------------

--Изменение.
UPDATE servServ
SET servServ.A_CHILD = @personalCardID 
FROM ESRN_SERV_SERV servServ --Назначения МСП.   
WHERE servServ.OUID = @servID

---------------------------------------------------------------------