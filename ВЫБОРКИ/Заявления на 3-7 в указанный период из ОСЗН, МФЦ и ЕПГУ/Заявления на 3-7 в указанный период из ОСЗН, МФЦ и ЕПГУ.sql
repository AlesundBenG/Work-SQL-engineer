--------------------------------------------------------------------------------------------------------------------------------


DECLARE @dateFrom   DATE = CONVERT (DATE, '01-04-2021')
DECLARE @dateTO     DATE = CONVERT (DATE, '04-04-2021')


--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#EMPLOYEE_MFC')       IS NOT NULL BEGIN DROP TABLE #EMPLOYEE_MFC          END --Работники МФЦ.
IF OBJECT_ID('tempdb..#PETITION_FROM_MFC')  IS NOT NULL BEGIN DROP TABLE #PETITION_FROM_MFC     END --Заявления из МФЦ.
IF OBJECT_ID('tempdb..#PETITION_FROM_OSZN') IS NOT NULL BEGIN DROP TABLE #PETITION_FROM_OSZN    END --Заявления из ОСЗН.
IF OBJECT_ID('tempdb..#PETITION_FROM_EPGU') IS NOT NULL BEGIN DROP TABLE #PETITION_FROM_EPGU    END --Заявления из ОСЗН.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #EMPLOYEE_MFC (
   EMPLOYEE_ACCOUNT INT, --Идентификатор аккаунта сотрудника.
)
CREATE TABLE #PETITION_FROM_MFC (
   PETITION_OUID INT, --Идентификатор заявления.
)
CREATE TABLE #PETITION_FROM_OSZN (
   PETITION_OUID INT, --Идентификатор заявления.
)
CREATE TABLE #PETITION_FROM_EPGU (
   PETITION_OUID INT, --Идентификатор заявления.
)



------------------------------------------------------------------------------------------------------------------------------


--Выборка работником МФЦ.
INSERT #EMPLOYEE_MFC (EMPLOYEE_ACCOUNT)
SELECT
    employee.A_ACCOUNT  AS EMPLOYEE_ACCOUNT
FROM SD_EMPLOYEE employee --Сотрудник организации.
----Штатная единица
    INNER JOIN SD_POSITION position
        ON position.A_EMPLOYEE = employee.OUID
----Подразделения
    INNER JOIN SPR_DEP AS departament			
        ON departament.OUID = position.A_DEPARTMENT 
            AND departament.A_UPPER_DEP IS NOT NULL --Есть вышестоящая организация.
----Наименование подразделения.
    INNER JOIN SPR_ORG_BASE AS departamentName		
        ON departamentName.OUID = position.A_DEPARTMENT
            AND departamentName.A_NAME1 like '%МФЦ%'    --МФЦ.
WHERE employee.A_ACCOUNT IS NOT NULL                                                            --Есть аккаунт у сотрудника.
    AND (CONVERT(DATE, position.A_DATESTART) <= @dateTo OR position.A_DATESTART IS NULL)        --В требуемый период сотрудник работал.
    AND (CONVERT(DATE, position.A_DATEFINISH) >= @dateFrom OR position.A_DATEFINISH IS NULL)    --В требуемый период сотрудник работал.


------------------------------------------------------------------------------------------------------------------------------


--Выборка заявлений МФЦ.
INSERT INTO #PETITION_FROM_MFC (PETITION_OUID)
SELECT
    petition.OUID AS PETITION_OUID
FROM WM_PETITION petition --Заявления.
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID 
            AND appeal.A_STATUS = 10 --Статус в БД "Действует".
WHERE petition.A_MSP = 997                                                  --Ежемесячная социальная выплата на ребенка в возрасте от трех до семи лет включительно.
	AND appeal.A_SOURCE = 'manual'                                          --Создано вручную.
    AND CONVERT(DATE, appeal.A_DATE_REG) BETWEEN @dateFrom AND @dateTO      --Заявление зарегестрировано в нужный период.
	AND appeal.A_CROWNER IN (SELECT EMPLOYEE_ACCOUNT FROM #EMPLOYEE_MFC)    --Заявление созданно сотрудником МФЦ.


------------------------------------------------------------------------------------------------------------------------------


--Выборка заявлений из ОСЗН.
INSERT INTO #PETITION_FROM_OSZN (PETITION_OUID)
SELECT
    petition.OUID AS PETITION_OUID
FROM WM_PETITION petition --Заявления.
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID 
            AND appeal.A_STATUS = 10                                            --Статус в БД "Действует".
WHERE petition.A_MSP = 997                                                      --Ежемесячная социальная выплата на ребенка в возрасте от трех до семи лет включительно.
	AND appeal.A_SOURCE = 'manual'                                              --Создано вручную.
    AND CONVERT(DATE, appeal.A_DATE_REG) BETWEEN @dateFrom AND @dateTO          --Заявление зарегестрировано в нужный период.
	AND appeal.A_CROWNER NOT IN (SELECT EMPLOYEE_ACCOUNT FROM #EMPLOYEE_MFC)    --Заявление созданно сотрудником МФЦ.


------------------------------------------------------------------------------------------------------------------------------


--Выборка заявлений из ЕПГУ.
INSERT INTO #PETITION_FROM_EPGU (PETITION_OUID)
SELECT 
    appeal.A_OUID AS PETITION_OUID
FROM DI_EPGU_APPEAL appeal --Заявика ЕПГУ.
WHERE appeal.A_STATUS = 10                                                  --Статус в БД "Действует".
	AND appeal.A_SERVICE = '10000026169' AND appeal.A_SUBSERVICE = '0000'   --Ежемесячная денежная выплата на ребенка в возрасте от трёх до семи лет.
	AND CONVERT(DATE, appeal.A_SENT_DATE) BETWEEN @dateFrom AND @dateTo     --Заявление зарегестрировано в нужный период.
	
	
------------------------------------------------------------------------------------------------------------------------------


--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
SELECT DISTINCT
    petition.OUID                                               AS [Идентификатор],
    'МФЦ'                                                       AS [Источник],
    CONVERT(VARCHAR, appeal.A_DATE_REG, 104)                    AS [Дата регистрации],
    'Заявитель'                                                 AS [Тип ЛД],
    personalCard.OUID                                           AS [ЛД/Номер заявки],
    personalCard.A_SNILS                                        AS [СНИЛС],
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS [Фамилия],
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS [Имя],
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS [Отчество],
    CONVERT(VARCHAR, personalCard.BIRTHDATE, 104)               AS [Дата рождения],
    organization.A_NAME1                                        AS [Организация, в которую направлено обращение]
FROM #PETITION_FROM_MFC fromMFC
----Заявления.
    INNER JOIN WM_PETITION petition 
        ON petition.OUID = fromMFC.PETITION_OUID
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID
----Личное дело заявителя.	         												
    INNER JOIN WM_PERSONAL_CARD personalCard  
        ON personalCard.OUID = petition.A_MSPHOLDER
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME   
----Наименования организаций.	   															
    LEFT JOIN SPR_ORG_BASE organization     
        ON organization.OUID = appeal.A_TO_ORG
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
UNION
SELECT DISTINCT
    petition.OUID                                                           AS [Идентификатор],
    'МФЦ'                                                                   AS [Источник],
    CONVERT(VARCHAR, appeal.A_DATE_REG, 104)                                AS [Дата регистрации],
    'Родственник'                                                           AS [Тип ЛД],
    joinedPerson.OUID                                                       AS [ЛД/Номер заявки],
    joinedPerson.A_SNILS                                                    AS [СНИЛС],
    ISNULL(joinedPerson.A_SURNAME_STR,    fioSurnameJoinedPerson.A_NAME)    AS [Фамилия],
    ISNULL(joinedPerson.A_NAME_STR,       fioNameJoinedPerson.A_NAME)       AS [Имя],
    ISNULL(joinedPerson.A_SECONDNAME_STR, fioSecondnameJoinedPerson.A_NAME) AS [Отчество],
    CONVERT(VARCHAR, joinedPerson.BIRTHDATE, 104)                           AS [Дата рождения],
    organization.A_NAME1                                                    AS [Организация, в которую направлено обращение]
FROM #PETITION_FROM_MFC fromMFC
----Заявления.
    INNER JOIN WM_PETITION petition 
        ON petition.OUID = fromMFC.PETITION_OUID
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID
----Граждане, по которым проводится расчет СДД
    INNER JOIN SPR_LINK_SDD_PET petition_AND_person
        ON petition_AND_person.FROMID = petition.OUID
----Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD joinedPerson 
        ON joinedPerson.OUID = petition_AND_person.TOID
            AND joinedPerson.OUID <> petition.A_MSPHOLDER
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurnameJoinedPerson 
        ON fioSurnameJoinedPerson.OUID = joinedPerson.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioNameJoinedPerson 
        ON fioNameJoinedPerson.OUID = joinedPerson.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondnameJoinedPerson 
        ON fioSecondnameJoinedPerson.OUID = joinedPerson.A_SECONDNAME --Связка с личным делом.  
----Наименования организаций.	   															
    LEFT JOIN SPR_ORG_BASE organization     
        ON organization.OUID = appeal.A_TO_ORG
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
UNION
SELECT DISTINCT
    petition.OUID                                               AS [Идентификатор],
    'ОСЗН'                                                      AS [Источник],
    CONVERT(VARCHAR, appeal.A_DATE_REG, 104)                    AS [Дата регистрации],
    'Заявитель'                                                 AS [Тип ЛД],
    personalCard.OUID                                           AS [ЛД/Номер заявки],
    personalCard.A_SNILS                                        AS [СНИЛС],
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS [Фамилия],
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS [Имя],
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS [Отчество],
    CONVERT(VARCHAR, personalCard.BIRTHDATE, 104)               AS [Дата рождения],
    organization.A_NAME1                                        AS [Организация, в которую направлено обращение]
FROM #PETITION_FROM_OSZN fromOSZN
----Заявления.
    INNER JOIN WM_PETITION petition 
        ON petition.OUID = fromOSZN.PETITION_OUID
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID
----Личное дело заявителя.	         												
    INNER JOIN WM_PERSONAL_CARD personalCard  
        ON personalCard.OUID = petition.A_MSPHOLDER
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME  
----Наименования организаций.	   															
    LEFT JOIN SPR_ORG_BASE organization     
        ON organization.OUID = appeal.A_TO_ORG 
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
UNION
SELECT DISTINCT
    petition.OUID                                                           AS [Идентификатор],
    'ОСЗН'                                                                  AS [Источник],
    CONVERT(VARCHAR, appeal.A_DATE_REG, 104)                                AS [Дата регистрации],
    'Родственник'                                                           AS [Тип ЛД],
    joinedPerson.OUID                                                       AS [ЛД/Номер заявки],
    joinedPerson.A_SNILS                                                    AS [СНИЛС],
    ISNULL(joinedPerson.A_SURNAME_STR,    fioSurnameJoinedPerson.A_NAME)    AS [Фамилия],
    ISNULL(joinedPerson.A_NAME_STR,       fioNameJoinedPerson.A_NAME)       AS [Имя],
    ISNULL(joinedPerson.A_SECONDNAME_STR, fioSecondnameJoinedPerson.A_NAME) AS [Отчество],
    CONVERT(VARCHAR, joinedPerson.BIRTHDATE, 104)                           AS [Дата рождения],
    organization.A_NAME1                                                    AS [Организация, в которую направлено обращение]
FROM #PETITION_FROM_OSZN fromOSZN
----Заявления.
    INNER JOIN WM_PETITION petition 
        ON petition.OUID = fromOSZN.PETITION_OUID
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID
----Граждане, по которым проводится расчет СДД
    INNER JOIN SPR_LINK_SDD_PET petition_AND_person
        ON petition_AND_person.FROMID = petition.OUID
----Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD joinedPerson 
        ON joinedPerson.OUID = petition_AND_person.TOID
            AND joinedPerson.OUID <> petition.A_MSPHOLDER
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurnameJoinedPerson 
        ON fioSurnameJoinedPerson.OUID = joinedPerson.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioNameJoinedPerson 
        ON fioNameJoinedPerson.OUID = joinedPerson.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondnameJoinedPerson 
        ON fioSecondnameJoinedPerson.OUID = joinedPerson.A_SECONDNAME --Связка с личным делом.  
----Наименования организаций.	   															
    LEFT JOIN SPR_ORG_BASE organization     
        ON organization.OUID = appeal.A_TO_ORG
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
UNION
SELECT DISTINCT
    petition.A_OUID                                     AS [Идентификатор],
    'ЕПГУ'                                              AS [Источник],
     CONVERT(VARCHAR, petition.A_SENT_DATE, 104)        AS [Дата регистрации],
    'Заявитель'                                         AS [Тип ЛД],
    petition.A_ORDERID                                  AS [ЛД/Номер заявки ЕПГУ],
    REPLACE(REPLACE(person.A_SNILS, '-', ''), ' ', '')  AS [СНИЛС],
    person.A_SURNAME COLLATE CYRILLIC_GENERAL_CI_AS     AS [Фамилия],
    person.A_FIRSTNAME COLLATE CYRILLIC_GENERAL_CI_AS   AS [Имя],
    person.A_MIDDLENAME COLLATE CYRILLIC_GENERAL_CI_AS  AS [Отчество],
    CONVERT(VARCHAR, person.A_BIRTHDATE, 104)           AS [Дата рождения],
    organization.A_NAME1                                AS [Организация, в которую направлено обращение]
FROM #PETITION_FROM_EPGU fromEPGU
----Заявика ЕПГУ.
    INNER JOIN DI_EPGU_APPEAL petition 
        ON petition.A_OUID = fromEPGU.PETITION_OUID
----Правообладатель.
    INNER JOIN DI_EPGU_PERSON person
        ON person.A_OUID = petition.A_PERSON
----Организация.
    LEFT JOIN SPR_ORG_BASE organization
        ON organization.OUID = petition.A_ORG
--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
UNION
SELECT DISTINCT
    petition.A_OUID                                             AS [Идентификатор],
    'ЕПГУ'                                                      AS [Источник],
     CONVERT(VARCHAR, petition.A_SENT_DATE, 104)                AS [Дата регистрации],
    'Родственник'                                               AS [Тип ЛД],
    petition.A_ORDERID                                          AS [ЛД/Номер заявки ЕПГУ],
    REPLACE(REPLACE(joinedPerson.A_SNILS, '-', ''), ' ', '')    AS [СНИЛС],
    joinedPerson.A_SURNAME COLLATE CYRILLIC_GENERAL_CI_AS       AS [Фамилия],
    joinedPerson.A_FIRSTNAME COLLATE CYRILLIC_GENERAL_CI_AS     AS [Имя],
    joinedPerson.A_MIDDLENAME COLLATE CYRILLIC_GENERAL_CI_AS    AS [Отчество],
    CONVERT(VARCHAR, joinedPerson.A_BIRTHDATE, 104)             AS [Дата рождения],
    organization.A_NAME1                                        AS [Организация, в которую направлено обращение]
FROM #PETITION_FROM_EPGU fromEPGU
----Заявика ЕПГУ.
    INNER JOIN DI_EPGU_APPEAL petition 
        ON petition.A_OUID = fromEPGU.PETITION_OUID
----Приложенные сведения о человеке.
    INNER JOIN DI_EGPU_RELATIVE_PERSON relative
        ON relative.A_APPEAL = petition.A_OUID
            AND relative.A_STATUS = 10
----Сведения о родственнике.
    INNER JOIN DI_EPGU_PERSON joinedPerson
        ON joinedPerson.A_OUID = relative.A_PERSON
            AND joinedPerson.A_OUID <> petition.A_PERSON
            AND joinedPerson.A_STATUS = 10
----Организация.
    LEFT JOIN SPR_ORG_BASE organization
        ON organization.OUID = petition.A_ORG 
ORDER BY [Источник], [Дата регистрации], [Идентификатор], [Тип ЛД], [Фамилия]