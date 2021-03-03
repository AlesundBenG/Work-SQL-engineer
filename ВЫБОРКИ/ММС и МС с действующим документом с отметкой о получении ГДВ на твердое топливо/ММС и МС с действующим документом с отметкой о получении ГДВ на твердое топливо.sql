------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#ALIVE_PEOPLE') IS NOT NULL BEGIN DROP TABLE #ALIVE_PEOPLE END --Таблица живых людей, личные дела которых действуют.
IF OBJECT_ID('tempdb..#MANY_CHILDREN_DOC') IS NOT NULL BEGIN DROP TABLE #MANY_CHILDREN_DOC END --Таблица документов на "Удостоверение многодетной малообеспеченной семьи", которые действуют на 01.03.2021
IF OBJECT_ID('tempdb..#PEOPLE_WHO_HAVE_SOLID_FUEL_MSP') IS NOT NULL BEGIN DROP TABLE #PEOPLE_WHO_HAVE_SOLID_FUEL_MSP END --Наличие ежегодной денежной выплаты на приобретение и доставку твердого топлива при наличии печного отопления за 2020-2021 год.
IF OBJECT_ID('tempdb..#LIVE_ADDRESS_PEOPLE') IS NOT NULL BEGIN DROP TABLE #LIVE_ADDRESS_PEOPLE END --Адреса проживания людей.


------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #ALIVE_PEOPLE (
    PERSONOUID INT, --Идентификатор личного дела.    
)
CREATE TABLE #MANY_CHILDREN_DOC (
    DOC_OUID        INT,    --ID документа.
    DOC_TYPE        INT,    --Тип документа.
    PERSONOUID      INT,    --ID личного дела держателя документа.   
)
CREATE TABLE #LIVE_ADDRESS_PEOPLE (
    PERSONOUID      INT,    --Идентификатор личного дела.    
    ADDRESS_OUID    INT,    --Идентификатор адреса.
    ADDRESS_TYPE    INT,    --Тип адреса (0 - Нет; 1 - Адрес проживания; 2 - Адрес временной регистрации; 3 - Адрес регистрации).
)
CREATE TABLE #PEOPLE_WHO_HAVE_SOLID_FUEL_MSP (
    PERSONOUID INT,    --Идентификатор личного дела. 
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка действующих личных дел живых людей.
INSERT INTO #ALIVE_PEOPLE (PERSONOUID)
SELECT 
    personalCard.OUID AS PERSONOUID
FROM WM_PERSONAL_CARD personalCard          --Личное дело гражданина.
WHERE personalCard.A_STATUS = 10            --Статус в БД "Действует".
    AND personalCard.A_PCSTATUS = 1         --Действующее личное дело.
    AND personalCard.A_DEATHDATE IS NULL    --Отсутствует дата смерти.
    
    
------------------------------------------------------------------------------------------------------------------------------


--Выборка документов, действующих на 01.03.2021
INSERT INTO #MANY_CHILDREN_DOC (DOC_OUID, DOC_TYPE, PERSONOUID)
SELECT
    actDocuments.OUID                                   AS DOC_OUID,
    actDocuments.DOCUMENTSTYPE                          AS DOC_TYPE,
    actDocuments.PERSONOUID                             AS PERSONOUID
FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
----Человек жив и его личное дело действует.
    INNER JOIN #ALIVE_PEOPLE alivePeople
        ON alivePeople.PERSONOUID = actDocuments.PERSONOUID
WHERE actDocuments.A_STATUS = 10 --Статус в БД "Действует".
    AND actDocuments.DOCUMENTSTYPE IN (
        2814,   --Удостоверение многодетной семьи
        2858    --Удостоверение многодетной малообеспеченной семьи.  
    )
    AND CONVERT(DATE, '01-03-2021') BETWEEN CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE) AND CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)


------------------------------------------------------------------------------------------------------------------------------


INSERT INTO #PEOPLE_WHO_HAVE_SOLID_FUEL_MSP (PERSONOUID)
SELECT DISTINCT 
    servServ.A_PERSONOUID AS PERSONOUID
FROM ESRN_SERV_SERV servServ --Назначения МСП.			
----Период предоставления МСП.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_STATUS = 10                 --Статус в БД "Действует".
            AND period.A_SERV = servServ.OUID   --Связка с назначением.	
            AND (CONVERT(DATE, period.A_LASTDATE) >= CONVERT(DATE, '01-01-2020')    --Было за 2020-2021
                OR period.A_LASTDATE IS NULL AND servServ.A_STATUSPRIVELEGE = 13    --Либо даты окончания нет, но статус "Утверждено".
            )
WHERE servServ.A_STATUS = 10 --Статус в БД "Действует".
    AND servServ.A_SK_MSP IN (
        891,    --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления (фед.).
        917,    --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления (регион.).
        989     --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления для многодетных малообеспеченных семей (регион.).
    )

------------------------------------------------------------------------------------------------------------------------------


--Выборка адресов проживания.
INSERT INTO #LIVE_ADDRESS_PEOPLE (PERSONOUID, ADDRESS_OUID, ADDRESS_TYPE)
SELECT 
    personalCard.OUID                                               AS PERSONOUID,
    CASE
        WHEN addressLive.OUID   IS NOT NULL THEN addressLive.OUID
        WHEN addressTemp.OUID   IS NOT NULL THEN addressTemp.OUID
        WHEN addressReg.OUID    IS NOT NULL THEN addressReg.OUID 
        ELSE CAST(NULL AS INT)
    END                                                             AS ADDRESS_OUID,
    CASE
        WHEN addressLive.OUID   IS NOT NULL THEN 1
        WHEN addressTemp.OUID   IS NOT NULL THEN 2
        WHEN addressReg.OUID    IS NOT NULL THEN 3
        ELSE 0
    END                                                             AS ADDRESS_TYPE
FROM WM_PERSONAL_CARD personalCard  --Личное дело гражданина.
----Адрес регистрации. 
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT --Связка с личным делом. 
----Адрес проживания.
    LEFT JOIN WM_ADDRESS addressLive
        ON addressLive.OUID = personalCard.A_LIVEFLAT --Связка с личным делом. 
----Адрес врменной регистрации.
    LEFT JOIN WM_ADDRESS addressTemp
        ON addressTemp.OUID = personalCard.A_TEMPREGFLAT --Связка с личным делом. 


------------------------------------------------------------------------------------------------------------------------------



SELECT DISTINCT
    CASE addressLive.ADDRESS_TYPE
        WHEN 1 THEN 'Адрес проживания'
        WHEN 2 THEN 'Адрес временного проживания'
        WHEN 3 THEN 'Адрес регистрации'
        ELSE 'Не указан'
    END                                                         AS [Тип адреса],
    ISNULL(district.A_NAME, districtCity.A_NAME)                AS [Район],    --Если город Киров, то район Нововятский, Ленинский, Октябрьский, Первомайский.
    town.A_NAME                                                 AS [Населенный пункт],
    address.A_ADRTITLE                                          AS [Адрес],
    personalCard.OUID                                           AS [Личное дело],
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS [Фамилия],
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS [Имя],
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS [Отчество],
    CASE manyChildDOC.DOC_TYPE
        WHEN 2814 THEN 'Многодетная семья'
        WHEN 2858 THEN 'Многодетная малообеспеченная семья'
        ELSE ''
    END                                                         AS [Статус],
    CASE 
        WHEN haveMSP.PERSONOUID IS NOT NULL THEN '+'
        ELSE ''
    END                                                         AS [Наличие ГДВ за 2020-2021 год]
FROM #MANY_CHILDREN_DOC manyChildDOC
----Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = manyChildDOC.PERSONOUID
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME 
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME     
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME 
----Адрес человека. 
    LEFT JOIN #LIVE_ADDRESS_PEOPLE addressLive
        ON addressLive.PERSONOUID = personalCard.OUID
----Информация об адресе.
    LEFT JOIN WM_ADDRESS address
        ON address.OUID = addressLive.ADDRESS_OUID
----Район.
    LEFT JOIN SPR_FEDERATIONBOROUGHT district
        ON district.OUID = address.A_FEDBOROUGH
    ----Районы города Кирова.
    LEFT JOIN SPR_BOROUGH districtCity
        ON districtCity.OUID = address.A_TOWNBOROUGH 
----Населенный пункт.
    LEFT JOIN SPR_TOWN town
        ON town.OUID = address.A_TOWN
----Люи, которые имели назначение на топливо.
    LEFT JOIN #PEOPLE_WHO_HAVE_SOLID_FUEL_MSP haveMSP
        ON haveMSP.PERSONOUID = personalCard.OUID