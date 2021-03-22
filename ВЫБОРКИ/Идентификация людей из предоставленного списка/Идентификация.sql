--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#DATA_FROM_DATABASE') IS NOT NULL BEGIN DROP TABLE #DATA_FROM_DATABASE    END --Данные из базы данных.
IF OBJECT_ID('tempdb..#DATA_FROM_FILE')     IS NOT NULL BEGIN DROP TABLE #DATA_FROM_FILE        END --Данные из файла для идентификации.
IF OBJECT_ID('tempdb..#RESULT')             IS NOT NULL BEGIN DROP TABLE #RESULT                END --Результат идентификации.
IF OBJECT_ID('tempdb..#LAST_SDD')           IS NOT NULL BEGIN DROP TABLE #LAST_SDD              END --Последнее зарегестрированное СДД.

--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #DATA_FROM_DATABASE (
    OUID            INT,            --Идентификатор личного дела.
    SURNAME         VARCHAR(256),   --Фамилия.
    NAME            VARCHAR(256),   --Имя.
    SECONDNAME      VARCHAR(256),   --Отчество.
    BIRTHDATE       DATE,           --Дата рождения.
    SNILS           VARCHAR(256),   --Снилс без пробелов и тире.
    DOCUMENT_SERIES VARCHAR(256),   --Серия документа, удостоверяющего личность, без пробелов и тире.
    DOCUMENT_NUMBER VARCHAR(256),   --Номер документа, удостоверяющего личность, без пробелов и тире.
    ADDRESS         VARCHAR(256),   --Адрес.
    DISTRICT        VARCHAR(256),   --Район адреса. 
    TOWN            VARCHAR(256),   --Город адреса. 
    STREET          VARCHAR(256),   --Улица адреса.
    HOUSE_NUMBER    VARCHAR(256),   --Дом адреса. 
    FLAT_NUMBER     VARCHAR(256)    --Квартира адреса.
)
CREATE TABLE #DATA_FROM_FILE (
    SURNAME         VARCHAR(256),   --Фамилия.
    NAME            VARCHAR(256),   --Имя.
    SECONDNAME      VARCHAR(256),   --Отчество.
    BIRTHDATE       DATE,           --Дата рождения.
    SNILS           VARCHAR(256),   --Снилс без пробелов и тире.
    DOCUMENT_SERIES VARCHAR(256),   --Серия документа, удостоверяющего личность, без пробелов и тире.
    DOCUMENT_NUMBER VARCHAR(256),   --Номер документа, удостоверяющего личность, без пробелов и тире.
    ADDRESS         VARCHAR(256),   --Адрес.
)
CREATE TABLE #LAST_SDD (
    PERSONOUID  INT,            --ID личного дела.
    SDD         FLOAT,          --СДД.
    DATE_REG    DATE,           --Дата регистрации заявления с СДД.
    MSP         VARCHAR(256)    --МСП, на которое было подано заявление.
)

--------------------------------------------------------------------------------------------------------------------------------

--Выборка данных для сравнения.
INSERT INTO #DATA_FROM_DATABASE (OUID, SURNAME, NAME, SECONDNAME, BIRTHDATE, SNILS, DOCUMENT_SERIES, DOCUMENT_NUMBER, ADDRESS, DISTRICT, TOWN, STREET, HOUSE_NUMBER, FLAT_NUMBER)
SELECT
    personalCard.OUID                                                               AS OUID,
    REPLACE(ISNULL(personalCard.A_SURNAME_STR, fioSurname.A_NAME), 'ё', 'е')        AS SURNAME,
    REPLACE(ISNULL(personalCard.A_NAME_STR, fioName.A_NAME), 'ё', 'е')              AS NAME,
    REPLACE(ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME), 'ё', 'е')  AS SECONDNAME,
    CONVERT(DATE, personalCard.BIRTHDATE)                                           AS BIRTHDATE,
    REPLACE(REPLACE(personalCard.A_SNILS, '-', ''), ' ', '')                        AS SNILS,
    REPLACE(REPLACE(actDocuments.DOCUMENTSERIES, '-', ''), ' ', '')                 AS DOCUMENT_SERIES,
    REPLACE(REPLACE(actDocuments.DOCUMENTSNUMBER, '-', ''), ' ', '')                AS DOCUMENT_NUMBER,
    addressReg.A_ADRTITLE                                                           AS ADDRESS,
    ISNULL(districtReg.A_NAME, districtCity.A_NAME)                                 AS DISTRICT,
    townReg.A_NAME                                                                  AS TOWN,
    street.A_NAME                                                                   AS STREET,
    addressReg.A_HOUSENUMBER                                                        AS HOUSE_NUMBER,
    addressReg.A_FLATNUMBER                                                         AS FLAT_NUMBER
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.  
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME    
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME     
----Действующие документы.
    LEFT JOIN WM_ACTDOCUMENTS actDocuments 
        ON actDocuments.PERSONOUID = personalCard.OUID
            AND actDocuments.A_STATUS = 10
----Вид документа.
    LEFT JOIN PPR_DOC typeDoc
        ON typeDoc.A_ID = actDocuments.DOCUMENTSTYPE    --Связка с документом.      
            AND typeDoc.A_ISIDENTITYCARD = 1            --Документ, удостоверяющий личность.
----Адрес регистрации.
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT  
----Населенный пункт адреса регистрации.
    LEFT JOIN SPR_TOWN townReg
        ON townReg.OUID = addressReg.A_TOWN --Связка с адресом регистрации.
----Район адреса регистрации.   
    LEFT JOIN SPR_FEDERATIONBOROUGHT districtReg
        ON districtReg.OUID = addressReg.A_FEDBOROUGH   --Связка с адресом регистрации.
----Районы города Кирова.
    LEFT JOIN SPR_BOROUGH districtCity
        ON districtCity.OUID = addressReg.A_TOWNBOROUGH --Связка с адресом регистрации.
----Наименование улиц.
    LEFT JOIN SPR_STREET street
        ON street.OUID = addressReg.A_STREET --Связка с адресом регистрации.                
WHERE personalCard.A_STATUS = 10         
     
            
--------------------------------------------------------------------------------------------------------------------------------


--Выборка данных для идентификации.
INSERT INTO #DATA_FROM_FILE (SURNAME, NAME, SECONDNAME, BIRTHDATE, SNILS, DOCUMENT_SERIES, DOCUMENT_NUMBER, ADDRESS)
SELECT 
    REPLACE(REPLACE(VARCHAR_1, ' ', ''), 'ё', 'е')  AS SURNAME,
    REPLACE(REPLACE(VARCHAR_2, ' ', ''), 'ё', 'е')  AS NAME,
    REPLACE(REPLACE(VARCHAR_3, ' ', ''), 'ё', 'е')  AS SECONDNAME,
    CONVERT(DATE, VARCHAR_4)                        AS BIRTHDATE,
    REPLACE(REPLACE(VARCHAR_9, '-', ''), ' ', '')   AS SNILS,
    REPLACE(REPLACE(VARCHAR_7, '-', ''), ' ', '')   AS DOCUMENT_SERIES,
    REPLACE(REPLACE(VARCHAR_8, '-', ''), ' ', '')   AS DOCUMENT_NUMBER,
    VARCHAR_5                                       AS ADDRESS
FROM TEMPORARY_TABLE
WHERE VARCHAR_10 = 'Люди из очереди на жилье'
    AND VARCHAR_6 NOT IN (
        'Октябрьский район',
        'Ленинский район',
        'Нововятский район',
        'Первомайский район'
    )


--------------------------------------------------------------------------------------------------------------------------------


SELECT DISTINCT
    ISNULL(fromFile.SURNAME, '')                            AS FROM_FILE_SURNAME,
    ISNULL(fromFile.NAME, '')                               AS FROM_FILE_NAME,
    ISNULL(fromFile.SECONDNAME, '')                         AS FROM_FILE_SECONDNAME,
    ISNULL(fromFile.BIRTHDATE, '')                          AS FROM_FILE_BIRTHDATE,
    ISNULL(fromFile.SNILS, '')                              AS FROM_FILE_SNILS,
    ISNULL(fromFile.DOCUMENT_SERIES, '')                    AS FROM_FILE_SERIES,
    ISNULL(fromFile.DOCUMENT_NUMBER, '')                    AS FROM_FILE_NUMBER,
    ISNULL(fromFile.ADDRESS, '')                            AS FROM_FILE_ADDRESS,
    ISNULL(fromDataBase.DISTRICT, '-')                      AS FROM_DATABASE_DISTRICT,
    ISNULL(CONVERT(VARCHAR, fromDatabase.OUID), '-')        AS FROM_DATABASE_OUID,
    ISNULL(fromDatabase.SURNAME, '-')                       AS FROM_DATABASE_SURNAME,
    ISNULL(fromDatabase.NAME, '-')                          AS FROM_DATABASE_NAME,
    ISNULL(fromDatabase.SECONDNAME, '-')                    AS FROM_DATABASE_SECONDNAME,
    ISNULL(CONVERT(VARCHAR, fromDatabase.BIRTHDATE), '')    AS FROM_DATABASE_BIRTHDATE,
    ISNULL(fromDatabase.SNILS, '-')                         AS FROM_DATABASE_SNILS,
    ISNULL(fromDatabase.ADDRESS, '-')                       AS FROM_DATABASE_ADDRESS
INTO #RESULT
FROM #DATA_FROM_FILE fromFile
    LEFT JOIN #DATA_FROM_DATABASE fromDatabase
        ON fromFile.SURNAME = fromDatabase.SURNAME COLLATE CYRILLIC_GENERAL_CI_AS               --Фамилия обязательно должна совпадать.
            AND fromFile.NAME = fromDatabase.NAME COLLATE CYRILLIC_GENERAL_CI_AS                --Имя обязательно должно совпадать.
            AND fromFile.SECONDNAME = fromDatabase.SECONDNAME COLLATE CYRILLIC_GENERAL_CI_AS    --Отчество обязательно должно совпадать.
            AND (fromFile.SNILS = fromDatabase.SNILS                                                                    --Если СНИЛС есть, то он должен совпадать.
                OR (fromFile.SNILS IS NULL                                                                              --Если СНИЛСА нет, то...
                    AND (fromFile.BIRTHDATE = fromDatabase.BIRTHDATE OR fromFile.BIRTHDATE IS NULL)                     --Дата рождения должна совпадать.
                    AND (fromFile.DOCUMENT_SERIES = fromDatabase.DOCUMENT_SERIES OR fromFile.DOCUMENT_SERIES IS NULL)   --Серия документа, удостоверяющего личность должна совпадать.
                    AND (fromFile.DOCUMENT_NUMBER = fromDatabase.DOCUMENT_NUMBER OR fromFile.DOCUMENT_NUMBER IS NULL)   --Номер документа, удостоверяющего личность должнен совпадать.
                )
            )

------------------------------------------------------------------------------------------------------------------------------

--Выбор последнего СДД у идентифицированных людей.
INSERT INTO #LAST_SDD(PERSONOUID, SDD, DATE_REG, MSP) 
SELECT  
    t.PERSONOUID,
    t.SDD,
    t.DATE_REG,
    t.MSP
FROM (
    SELECT 
        personalCardHolder.OUID             AS PERSONOUID,
        petition.A_SDD                      AS SDD,
        CONVERT(DATE, appeal.A_DATE_REG)    AS DATE_REG,
        typeServ.A_NAME                     AS MSP,
        ROW_NUMBER() OVER (PARTITION BY personalCardHolder.OUID ORDER BY appeal.A_DATE_REG DESC) AS gnum 
    FROM WM_PETITION petition --Заявления.
    ----Обращение гражданина.		
        INNER JOIN WM_APPEAL_NEW appeal     
            ON appeal.OUID = petition.OUID --Связка с заявлением.
    ----Личное дело заявителя.	         												
        INNER JOIN WM_PERSONAL_CARD personalCardHolder     
            ON personalCardHolder.OUID = petition.A_MSPHOLDER --Связка с заявлением.   
    ----МСП, на которое подано заявление.    														
        INNER JOIN PPR_SERV typeServ
            ON typeServ.A_ID = petition.A_MSP --Связка с заявлением.     											 
    WHERE appeal.A_STATUS = 10 
        AND petition.A_SDD IS NOT NULL AND petition.A_SDD <> 0
        AND personalCardHolder.OUID IN (SELECT FROM_DATABASE_OUID FROM #RESULT)
) t
WHERE t.gnum = 1						

------------------------------------------------------------------------------------------------------------------------------



SELECT 
    '->'                                                                    AS [Из файла],
    CASE 
        WHEN result.FROM_FILE_BIRTHDATE IS NULL
            THEN result.FROM_FILE_SURNAME + ' ' +
                result.FROM_FILE_NAME + ' ' + 
                result.FROM_FILE_SECONDNAME
        ELSE result.FROM_FILE_SURNAME + ' ' +
                result.FROM_FILE_NAME + ' ' + 
                result.FROM_FILE_SECONDNAME + ' (' +
                CONVERT(VARCHAR, result.FROM_FILE_BIRTHDATE, 104) + ' )'    
    END                                                                     AS [ФИО и дата рождения],        
    result.FROM_FILE_SNILS                                                  AS [СНИЛС],
    result.FROM_FILE_SERIES + ' ' + result.FROM_FILE_NUMBER                 AS [Документ],
    result.FROM_FILE_ADDRESS                                                AS [Адрес],
    '->'                                                                    AS [Из БД],  
    result.FROM_DATABASE_DISTRICT                                           AS [Район],
    result.FROM_DATABASE_OUID                                               AS [ЛД],
    result.FROM_DATABASE_SURNAME + ' ' +
        result.FROM_DATABASE_NAME + ' ' +
        result.FROM_DATABASE_SECONDNAME + ' (' +
        CONVERT(VARCHAR, result.FROM_DATABASE_BIRTHDATE, 104) + ' )'        AS [ФИО и дата рождения], 
    result.FROM_DATABASE_SNILS                                              AS [СНИЛС],
    result.FROM_DATABASE_ADDRESS                                            AS [Адрес],
    '->'                                                                    AS [Последнее СДД],
    lastSDD.SDD                                                             AS [Количество],
    lastSDD.DATE_REG                                                        AS [Дата регистрации],
    lastSDD.MSP                                                             AS [МСП],
    '->'                                                                    AS [Родственник],
    personalCard_2.A_TITLE                                                  AS [ЛД],
    groupRole.A_NAME                                                        AS [Родственная связь]
FROM #RESULT result
----Последнее СДД.
    LEFT JOIN #LAST_SDD lastSDD
        ON lastSDD.PERSONOUID = result.FROM_DATABASE_OUID
----Родственные связи.
    LEFT JOIN WM_RELATEDRELATIONSHIPS relationship 
        ON relationship.A_ID1 = result.FROM_DATABASE_OUID
            AND relationship.A_STATUS = 10
----Человек из родственных связей.
    LEFT JOIN WM_PERSONAL_CARD personalCard_2
        ON personalCard_2.OUID = relationship.A_ID2     
            AND personalCard_2.A_STATUS = 10
----Тип родсвтенной связи.
    LEFT JOIN SPR_GROUP_ROLE groupRole
        ON groupRole.OUID = relationship.A_RELATED_RELATIONSHIP
ORDER BY result.FROM_DATABASE_DISTRICT, result.FROM_DATABASE_OUID 