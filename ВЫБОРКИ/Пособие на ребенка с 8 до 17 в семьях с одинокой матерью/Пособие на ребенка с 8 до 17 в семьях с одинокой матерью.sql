DECLARE @currentDate DATE
SET @currentDate = CONVERT(DATE, GETDATE())

SELECT
    servServ.OUID                       AS [Назначение],
    statusServ.A_NAME                   AS [Статус назначения],
    CONVERT(DATE, period.STARTDATE)     AS [Дата начала периода предоставления МСП],
    CONVERT(DATE, period.A_LASTDATE)    AS [Дата окончания периода предоставления МСП],
    servServ.A_PERSONOUID               AS [Льготодержатель],
    servServ.A_CHILD                    AS [Ребенок],
    payAmount.A_AMOUNT                  AS [Размер начисления],
    CASE
        WHEN DATEDIFF(YEAR,personalCardChild.BIRTHDATE, @currentDate) -                                  --Вычисление разницы между годами.									
                CASE                                                                            --Определение, был ли в этом году день рождения.
                    WHEN MONTH(personalCardChild.BIRTHDATE)    < MONTH(@currentDate)  THEN 0            --День рождения был, и он был не в этом месяце.
                    WHEN MONTH(personalCardChild.BIRTHDATE)    > MONTH(@currentDate)  THEN 1            --День рождения будет в следущих месяцах.
                    WHEN DAY(personalCardChild.BIRTHDATE)      > DAY(@currentDate)    THEN 1            --В этом месяце день рождения, но его еще не было.
                    ELSE 0                                                                      --В этом месяце день рождения, и он уже был.
                END BETWEEN 8 AND 16
            THEN '+'
            ELSE '-'
    END                     AS [В возрасте с 8 до 17 лет],
    CASE
        WHEN DATEDIFF(YEAR,personalCardChild.BIRTHDATE, @currentDate) -                                  --Вычисление разницы между годами.									
                CASE                                                                            --Определение, был ли в этом году день рождения.
                    WHEN MONTH(personalCardChild.BIRTHDATE)    < MONTH(@currentDate)  THEN 0            --День рождения был, и он был не в этом месяце.
                    WHEN MONTH(personalCardChild.BIRTHDATE)    > MONTH(@currentDate)  THEN 1            --День рождения будет в следущих месяцах.
                    WHEN DAY(personalCardChild.BIRTHDATE)      > DAY(@currentDate)    THEN 1            --В этом месяце день рождения, но его еще не было.
                    ELSE 0                                                                      --В этом месяце день рождения, и он уже был.
                END BETWEEN 8 AND 16 AND payAmount.A_AMOUNT IN (382, 439.3) 
            THEN '+'
            ELSE '-'
    END                     AS [В возрасте с 8 до 17 лет и одинокие матери]
FROM ESRN_SERV_SERV servServ --Назначения МСП.
----Назначение к начислению.   
    INNER JOIN WM_SERVPAYAMOUNT payAmount
        ON payAmount.A_MSP = servServ.OUID
            AND payAmount.A_STATUS = 10 --Статус в БД "Действует".
            AND @currentDate >= CONVERT(DATE, payAmount.A_DATESTART)
            AND @currentDate <= CONVERT(DATE, ISNULL(payAmount.A_DATELAST, '31-12-3000'))
----Период предоставления МСП.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_STATUS = 10                 --Статус в БД "Действует".
            AND period.A_SERV = servServ.OUID   --Связка с назначением.	
            AND @currentDate >= CONVERT(DATE, period.STARTDATE)
            AND @currentDate <= CONVERT(DATE, ISNULL(period.A_LASTDATE, '31-12-3000'))
----Личное дело лица, на основании данных ЛД которого сделано назначение        
    INNER JOIN WM_PERSONAL_CARD personalCardChild 
        ON personalCardChild.OUID = servServ.A_CHILD 
----Статус назначения.
    INNER JOIN SPR_STATUS_PROCESS statusServ 
        ON statusServ.A_ID = servServ.A_STATUSPRIVELEGE	--Связка с назначением.	
WHERE servServ.A_STATUS = 10            --Статус в БД "Действует".
    AND servServ.A_STATUSPRIVELEGE = 13 --Действующее назначение.
    AND servServ.A_SK_MSP = 892         --Ежемесячное пособие на ребенка.