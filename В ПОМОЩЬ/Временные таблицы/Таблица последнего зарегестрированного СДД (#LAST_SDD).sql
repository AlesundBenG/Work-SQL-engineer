--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#LAST_SDD') IS NOT NULL BEGIN DROP TABLE #LAST_SDD END --Последнее зарегестрированное СДД.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #LAST_SDD (
    PERSONOUID  INT,    --ID личного дела.
    SDD         FLOAT,  --СДД.
    DATE_REG    DATE,   --Дата регистрации заявления с СДД.
    SERV_TYPE   INT     --МСП, на которое было подано заявление.
)


------------------------------------------------------------------------------------------------------------------------------

--Выбор последнего СДД у идентифицированных людей.
INSERT INTO #LAST_SDD(PERSONOUID, SDD, DATE_REG, SERV_TYPE) 
SELECT  
    t.PERSONOUID,
    t.SDD,
    t.DATE_REG,
    t.SERV_TYPE
FROM (
    SELECT 
        personalCardHolder.OUID             AS PERSONOUID,
        petition.A_SDD                      AS SDD,
        CONVERT(DATE, appeal.A_DATE_REG)    AS DATE_REG,
        petition.A_MSP                      AS SERV_TYPE,
        --Для отбора последнего.
        ROW_NUMBER() OVER (PARTITION BY personalCardHolder.OUID ORDER BY appeal.A_DATE_REG DESC) AS gnum 
    FROM WM_PETITION petition --Заявления.
    ----Обращение гражданина.		
        INNER JOIN WM_APPEAL_NEW appeal     
            ON appeal.OUID = petition.OUID --Связка с заявлением.
    ----Личное дело заявителя.	         												
        INNER JOIN WM_PERSONAL_CARD personalCardHolder     
            ON personalCardHolder.OUID = petition.A_MSPHOLDER --Связка с заявлением.   											 
    WHERE appeal.A_STATUS = 10                                  --Статус в БД "Действует".
        AND petition.A_SDD IS NOT NULL AND petition.A_SDD <> 0  --СДД есть и он не нулевой.
) t
WHERE t.gnum = 1						

------------------------------------------------------------------------------------------------------------------------------


--Проверка.
SELECT * FROM #LAST_SDD


------------------------------------------------------------------------------------------------------------------------------