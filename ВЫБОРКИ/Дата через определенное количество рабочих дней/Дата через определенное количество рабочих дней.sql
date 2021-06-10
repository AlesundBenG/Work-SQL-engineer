DECLARE @startDate DATE
SET @startDate = CONVERT(DATE, '15-02-2021')

DECLARE @endDate DATE
SET @endDate = @startDate

--Необходимое количество рабочих дней.
DECLARE @workDays INT
SET @workDays = 10

--Счетчик рабочих дней (итератор).
DECLARE @countWorkDays INT
SET @countWorkDays = 1

WHILE @countWorkDays <> @workDays BEGIN
    SET @endDate = DATEADD(DAY, 1, @endDate)
    --Рабочие дни.
    IF DATEPART(dw, @endDate) NOT IN (6, 7) AND NOT EXISTS(SELECT 1 FROM ESRN_HOLIDAY WHERE CONVERT(DATE, A_DATE) = @endDate AND DAY_TYPE = 'Holiday') BEGIN
        SET @countWorkDays = @countWorkDays + 1
    END
    --Выходные дни.
    IF DATEPART(dw, @endDate) IN (6, 7) AND EXISTS(SELECT 1 FROM ESRN_HOLIDAY WHERE CONVERT(DATE, A_DATE) = @endDate AND DAY_TYPE = 'Work') BEGIN
        SET @countWorkDays = @countWorkDays + 1
    END
END

SELECT 
    @startDate  AS [Начало],
    @workDays   AS [Количество рабочих дней],
    @endDate    AS [Конец]