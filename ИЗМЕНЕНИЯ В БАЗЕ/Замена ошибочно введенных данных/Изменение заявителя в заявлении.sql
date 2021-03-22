---------------------------------------------------------------------

--Идентификатор заявления.
DECLARE @petitionID INT
SET @petitionID = 6440195

--Заявитель, на которого нужно заменить.
DECLARE @personalCardID INT
SET @personalCardID = 6440195

---------------------------------------------------------------------

--Изменение.
UPDATE appeal
SET appeal.A_PERSONCARD = @personalCardID 
FROM WM_APPEAL_NEW appeal     
WHERE appeal.OUID = @petitionID

---------------------------------------------------------------------