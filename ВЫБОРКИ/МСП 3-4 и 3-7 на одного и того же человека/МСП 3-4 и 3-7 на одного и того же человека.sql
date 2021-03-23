--------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#THREE_TO_FOUR')  IS NOT NULL BEGIN DROP TABLE #THREE_TO_FOUR     END --Назначения от трех до четырех.
IF OBJECT_ID('tempdb..#THREE_TO_SEVEN') IS NOT NULL BEGIN DROP TABLE #THREE_TO_SEVEN    END --Назначения от трех до семи.


--------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #THREE_TO_FOUR (
    PERSONOUID  INT,    --Личное дело льготодержателя.
    CHILD       INT,    --Личное дело лица, на основании которого...
    MSP         INT,    --Тип МСП.
    START_DATE  DATE,   --Дата начала предоставления.
    LAST_DATE   DATE    --Дата окончания предоставления.
)
CREATE TABLE #THREE_TO_SEVEN (
    PERSONOUID  INT,    --Личное дело льготодержателя.
    CHILD       INT,    --Личное дело лица, на основании которого...
    MSP         INT,    --Тип МСП.
    START_DATE  DATE,   --Дата начала предоставления.
    LAST_DATE   DATE    --Дата окончания предоставления.
)


--------------------------------------------------------------------------------------------------------


--От трех до четырех.
SELECT 
    servServ.A_PERSONOUID               AS PERSONOUID,
    servServ.A_CHILD                    AS CHILD,
    servServ.A_SK_MSP                   AS MSP,
    CONVERT(DATE, period.STARTDATE)     AS START_DATE,
    CONVERT(DATE, period.A_LASTDATE)    AS LAST_DATE  
INTO #THREE_TO_FOUR
FROM ESRN_SERV_SERV servServ --Назначения МСП.
----Срок действия назначения.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_SERV = servServ.OUID  
            AND period.A_STATUS = 10        --Статус в БД "Действует".
            AND CONVERT(DATE, GETDATE()) >= CONVERT(DATE, period.STARTDATE) 
            AND (CONVERT(DATE, GETDATE()) <= CONVERT(DATE, period.A_LASTDATE) OR period.A_LASTDATE IS NULL)
WHERE (ISNULL(servServ.A_STATUS, 10) = 10)  --Статус назначения в БД "Действует".
    AND servServ.A_STATUSPRIVELEGE = 13     --Утвержденное назначение.
    AND servServ.A_SK_MSP = 995             --Ежемесячная социальная выплата на ребенка в возрасте от трех до четырех лет.
    
    
--------------------------------------------------------------------------------------------------------


--От трех до семи.
SELECT 
    servServ.A_PERSONOUID               AS PERSONOUID,
    servServ.A_CHILD                    AS CHILD,
    servServ.A_SK_MSP                   AS MSP,
    CONVERT(DATE, period.STARTDATE)     AS START_DATE,
    CONVERT(DATE, period.A_LASTDATE)    AS LAST_DATE  
INTO #THREE_TO_SEVEN
FROM ESRN_SERV_SERV servServ --Назначения МСП.
----Срок действия назначения.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_SERV = servServ.OUID  
            AND period.A_STATUS = 10        --Статус в БД "Действует".
            AND CONVERT(DATE, GETDATE()) >= CONVERT(DATE, period.STARTDATE) 
            AND (CONVERT(DATE, GETDATE()) <= CONVERT(DATE, period.A_LASTDATE) OR period.A_LASTDATE IS NULL)
WHERE (ISNULL(servServ.A_STATUS, 10) = 10)  --Статус назначения в БД "Действует".
    AND servServ.A_STATUSPRIVELEGE = 13     --Утвержденное назначение.
    AND servServ.A_SK_MSP = 997             --Ежемесячная социальная выплата на ребенка в возрасте от трех до семи лет включительно.
   
    
--------------------------------------------------------------------------------------------------------
    
    
--Выборка.
SELECT 
    ttf.CHILD                                       AS [Лицо на основании данных ЛД которого сделано назначение],
    srf.A_NAME		                                AS [МСП 1],
    ttf.PERSONOUID                                  AS [Личное дело льготодержателя МСП1],
    'c ' + CONVERT(VARCHAR, ttf.START_DATE, 104) +
    ' по ' +CONVERT(VARCHAR, ttf.LAST_DATE, 104)    AS [Период 1],
    srs.A_NAME		                                AS [МСП 2],
    tts.PERSONOUID                                  AS [Личное дело льготодержателя МСП2],
    'c ' + CONVERT(VARCHAR, tts.START_DATE, 104) +
    ' по ' +CONVERT(VARCHAR, tts.LAST_DATE, 104)    AS [Период 2]
FROM #THREE_TO_FOUR ttf --От трех до четырех.
----От трех до семи.
    INNER JOIN #THREE_TO_SEVEN  tts 
        ON tts.CHILD = ttf.CHILD
----Наименование от трех до четырех.
    INNER JOIN PPR_SERV srf
        ON srf.A_ID = ttf.MSP
----Наименование от трех до семи.
    INNER JOIN PPR_SERV srs 
        ON srs.A_ID = tts.MSP
WHERE ttf.MSP <> tts.MSP --МСП разные.
ORDER BY ttf.CHILD 