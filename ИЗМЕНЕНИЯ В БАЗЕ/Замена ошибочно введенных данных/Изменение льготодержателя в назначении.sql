---------------------------------------------------------------------

--������������� ����������.
DECLARE @servID INT
SET @servID = 4439067

--���������������.
DECLARE @personalCardID INT
SET @personalCardID = 1645901  

---------------------------------------------------------------------

--���������.
UPDATE servServ
SET servServ.A_PERSONOUID = @personalCardID 
FROM ESRN_SERV_SERV servServ --���������� ���.   
WHERE servServ.OUID = @servID

---------------------------------------------------------------------