------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL BEGIN DROP TABLE #RESULT END    --Заявления, признанные на социальное обслуживание.


------------------------------------------------------------------------------------------------------------------------------


--Выборка заявлений.
SELECT 
    personalCardHolder.A_TITLE          AS [Льготодержатель],
    gender.A_NAME                       AS [Пол],
    DATEDIFF(YEAR, personalCardHolder.BIRTHDATE, appeal.A_DATE_REG) -                   --Вычисление разницы между годами.									
        CASE                                                                            --Определение, был ли в этом году день рождения.
            WHEN MONTH(personalCardHolder.BIRTHDATE) < MONTH(appeal.A_DATE_REG)  THEN 0 --День рождения был, и он был не в этом месяце.
            WHEN MONTH(personalCardHolder.BIRTHDATE) > MONTH(appeal.A_DATE_REG)  THEN 1 --День рождения будет в следущих месяцах.
            WHEN DAY(personalCardHolder.BIRTHDATE)   > DAY(appeal.A_DATE_REG)    THEN 1 --В этом месяце день рождения, но его еще не было.
            ELSE 0                                                                      --В этом месяце день рождения, и он уже был.
    END	                                AS [Возраст в момент регистрации заявления],
    CONVERT(DATE, appeal.A_DATE_REG)    AS [Дата регистрации заявления],
    petitionType.A_TITLE                AS [Тип заявления], 
    typeCategory.A_NAME                 AS [Льготная категория/Форма социального обслуживания],
    CONVERT(DATE, petition.A_DONEDATE)  AS [Дата подготовки решения],
    petition.A_DECISION_NUM             AS [Номер решения],
    organization.A_NAME1                AS [Организация, в которую направлено обращение]
INTO #RESULT
FROM WM_PETITION petition --Заявления.
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID
            AND appeal.A_STATUS = 10 --Статус в БД "Действует".
----Личное дело заявителя.	         												
    INNER JOIN WM_PERSONAL_CARD personalCardHolder     
        ON personalCardHolder.OUID = petition.A_MSPHOLDER
            AND personalCardHolder.A_STATUS = 10 --Статус в БД "Действует".   		
----Пол.       
    INNER JOIN SPR_GENDER gender
        ON gender.OUID = personalCardHolder.A_SEX		
----Наименования льготных категорий.    															
    LEFT JOIN PPR_CAT typeCategory
        ON typeCategory.A_ID = petition.A_CATEGORY    											
----Наименования организаций.	   															
    INNER JOIN SPR_ORG_BASE organization     
        ON organization.OUID = appeal.A_TO_ORG 
----Тип заявления через перечисление, указанное в свойстве атрибута.
    LEFT JOIN SXENUM petitionType
        ON petitionType.A_ATTR = 10315368   --Атрибут "Тип заявления" в таблице "Заявления".		
            AND petitionType.A_CODE = petition.A_PETITION_TYPE
WHERE petition.A_STATUSPRIVELEGE = 13   --Статус Утверждено.
    AND petition.A_MSP = 974            --Признание нуждающимся в социальном обслуживании.
    AND DATEDIFF(YEAR, personalCardHolder.BIRTHDATE, appeal.A_DATE_REG) -               ---Вычисление разницы между годами.									
        CASE                                                                            --Определение, был ли в этом году день рождения.
            WHEN MONTH(personalCardHolder.BIRTHDATE) < MONTH(appeal.A_DATE_REG)  THEN 0 --День рождения был, и он был не в этом месяце.
            WHEN MONTH(personalCardHolder.BIRTHDATE) > MONTH(appeal.A_DATE_REG)  THEN 1 --День рождения будет в следущих месяцах.
            WHEN DAY(personalCardHolder.BIRTHDATE)   > DAY(appeal.A_DATE_REG)    THEN 1 --В этом месяце день рождения, но его еще не было.
            ELSE 0                                                                      --В этом месяце день рождения, и он уже был.
        END >= 18   --Больше 18 лет в момент подачи заявления.
   
   
----------------------------------------------------------------------------------------------------------
--Список.
SELECT * FROM #RESULT
----------------------------------------------------------------------------------------------------------
--Количество поданных.
SELECT 
    Льготодержатель,
    [Пол],
    COUNT(*) [Количество поданных заявлений]
FROM #RESULT
GROUP BY [Льготодержатель], [Пол]
----------------------------------------------------------------------------------------------------------
--Количество поданных.
SELECT 
    Льготодержатель,
    [Пол],
    [Льготная категория/Форма социального обслуживания],
    COUNT(*) [Количество поданных заявлений]
FROM #RESULT
GROUP BY [Льготодержатель], [Пол], [Льготная категория/Форма социального обслуживания]
----------------------------------------------------------------------------------------------------------