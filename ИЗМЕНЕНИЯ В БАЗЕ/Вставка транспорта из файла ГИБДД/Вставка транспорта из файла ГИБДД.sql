--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#DATA_FROM_DATABASE') IS NOT NULL BEGIN DROP TABLE #DATA_FROM_DATABASE    END --Данные из базы данных.
IF OBJECT_ID('tempdb..#DATA_FROM_FILE')     IS NOT NULL BEGIN DROP TABLE #DATA_FROM_FILE        END --Данные из файла для идентификации.
IF OBJECT_ID('tempdb..#RESULT')             IS NOT NULL BEGIN DROP TABLE #RESULT                END --Результат идентификации.
IF OBJECT_ID('tempdb..#CODE_CATEGORY')      IS NOT NULL BEGIN DROP TABLE #CODE_CATEGORY         END --Категории транспортов.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #DATA_FROM_DATABASE (
    OUID            INT,            --Идентификатор личного дела.
    SURNAME         VARCHAR(256),   --Фамилия.
    NAME            VARCHAR(256),   --Имя.
    SECONDNAME      VARCHAR(256),   --Отчество.
    BIRTHDATE       DATE,           --Дата рождения.
    SNILS           VARCHAR(256)    --СНИЛС.
)
CREATE TABLE #CODE_CATEGORY (
    CODE        INT,        --Код типа транспорта.
    CATEGORY    VARCHAR(1)  --Категория транспорта.
)


------------------------------------------------------------------------------------------------------------------------------


--Соотношение кода типа транспорта с категорией.
INSERT #CODE_CATEGORY(CODE, CATEGORY)
VALUES
(21	,'B'),
(22	,'B'),
(23	,'B'),
(25	,'B'),
(27	,'B'),
(28	,'B'),
(29	,'B'),
(1	,'C'),
(2	,'C'),
(3	,'C'),
(4	,'C'),
(5	,'C'),
(6	,'C'),
(7	,'C'),
(8	,'C'),
(9	,'C'),
(41	,'D'),
(42	,'D'),
(43	,'D'),
(44	,'D'),
(49	,'D'),
(71	,'A'),
(72	,'A'),
(73	,'A'),
(74	,'A'),
(80	,'E'),
(82	,'E'),
(83	,'E'),
(84	,'E'),
(85	,'E'),
(86	,'E'),
(87	,'E'),
(88	,'E'),
(89	,'E'),
(91	,'E'),
(92	,'E'),
(93	,'E'),
(95	,'E'),
(99	,'E')


------------------------------------------------------------------------------------------------------------------------------


--Выборка данных для сравнения.
INSERT INTO #DATA_FROM_DATABASE (OUID, SURNAME, NAME, SECONDNAME, BIRTHDATE, SNILS)
SELECT
    personalCard.OUID                                                               AS OUID,
    REPLACE(ISNULL(personalCard.A_SURNAME_STR, fioSurname.A_NAME), 'ё', 'е')        AS SURNAME,
    REPLACE(ISNULL(personalCard.A_NAME_STR, fioName.A_NAME), 'ё', 'е')              AS NAME,
    REPLACE(ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME), 'ё', 'е')  AS SECONDNAME,
    CONVERT(DATE, personalCard.BIRTHDATE)                                           AS BIRTHDATE,
    personalCard.A_SNILS                                                            AS SNILS
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
WHERE personalCard.A_STATUS = 10         
     
       
--------------------------------------------------------------------------------------------------------------------------------


--Выборка данных из файла.
SELECT 
    VARCHAR_1                                       AS SNILS,
    REPLACE(REPLACE(VARCHAR_2, ' ', ''), 'ё', 'е')  AS SURNAME,
    REPLACE(REPLACE(VARCHAR_3, ' ', ''), 'ё', 'е')  AS NAME,
    REPLACE(REPLACE(VARCHAR_4, ' ', ''), 'ё', 'е')  AS SECONDNAME,
    CONVERT(DATE, VARCHAR_5)                        AS BIRTHDATE,
    VARCHAR_6,
    VARCHAR_7,
    VARCHAR_8,
    VARCHAR_9,
    VARCHAR_10
INTO #DATA_FROM_FILE
FROM TEMPORARY_TABLE
WHERE VARCHAR_10 = 'Информация из ГИБДД 3'


--------------------------------------------------------------------------------------------------------------------------------


--Результат.
SELECT DISTINCT
    ISNULL(CONVERT(VARCHAR, fromDatabase.OUID), '-')        AS FROM_DATABASE_OUID,
    ISNULL(fromFile.SNILS, '')                              AS FROM_FILE_SNILS,
    ISNULL(fromFile.SURNAME, '')                            AS FROM_FILE_SURNAME,
    ISNULL(fromFile.NAME, '')                               AS FROM_FILE_NAME,
    ISNULL(fromFile.SECONDNAME, '')                         AS FROM_FILE_SECONDNAME,
    ISNULL(fromFile.BIRTHDATE, '')                          AS FROM_FILE_BIRTHDATE,
    typeTransport.A_OUID                                    AS FROM_FILE_TYPE_CAR_OUID, 
    fromFile.VARCHAR_6                                      AS FROM_FILE_TYPE_CAR_CODE, 
    fromFile.VARCHAR_7                                      AS FROM_FILE_YEAR_CAR,
    fromFile.VARCHAR_8                                      AS FROM_FILE_POWER_CAR
INTO #RESULT
FROM #DATA_FROM_FILE fromFile
----Данные из базы данных.
    LEFT JOIN #DATA_FROM_DATABASE fromDatabase
        ON fromFile.SURNAME = fromDatabase.SURNAME COLLATE CYRILLIC_GENERAL_CI_AS               --Фамилия обязательно должна совпадать.
            AND fromFile.NAME = fromDatabase.NAME COLLATE CYRILLIC_GENERAL_CI_AS                --Имя обязательно должно совпадать.
            AND fromFile.SECONDNAME = fromDatabase.SECONDNAME COLLATE CYRILLIC_GENERAL_CI_AS    --Отчество обязательно должно совпадать.
            AND fromFile.BIRTHDATE = fromDatabase.BIRTHDATE                                     --Дата рождения обязательно должна совпадать.
            AND fromFile.SNILS = fromDatabase.SNILS
----В файле хранится код, а не идентификатор типа транспорта из справочника.
    INNER JOIN SPR_TRANSPORTATION_TYPE typeTransport
        ON typeTransport.A_CODE = fromFile.VARCHAR_6 
    

--------------------------------------------------------------------------------------------------------------------------------


--Демонстрация результата до корректировки.  
SELECT * FROM #RESULT

--Удаление не идентифицированных.
DELETE FROM #RESULT
WHERE FROM_DATABASE_OUID = '-'

--Удаляем данные, которые уже есть.
DELETE FROM #RESULT
WHERE EXISTS (
    SELECT 
       transport.A_OUID
    FROM WM_TRANSPORTATION transport
    WHERE transport.A_PC = #RESULT.FROM_DATABASE_OUID
        AND transport.A_YEAR = #RESULT.FROM_FILE_YEAR_CAR
        AND transport.A_TYPE = #RESULT.FROM_FILE_TYPE_CAR_OUID
        AND transport.A_POWER_HORSE = #RESULT.FROM_FILE_POWER_CAR
)

--Демонстрация результата после корректировки.
SELECT * FROM #RESULT


--------------------------------------------------------------------------------------------------------------------------------


--Вставка сведений.
INSERT INTO WM_TRANSPORTATION (GUID, A_PC, A_TYPE, A_CREATEDATE, A_CROWNER, A_TS, A_DOC, A_EDITOR, A_PART, A_PARTNUMPART, A_PARTDENOMPART, A_MARK, A_POWER_HORSE, A_YEAR, A_SOURCE, A_COMMENT, DATE_RECEIPT_INFORMATION, START_OWN_DATE, END_OWN_DATE, A_CATEGORY)
SELECT   
    NEWID()                                 AS GUID,
    FROM_DATABASE_OUID                      AS A_PC,
    FROM_FILE_TYPE_CAR_OUID                 AS A_TYPE,
    GETDATE()                               AS A_CREATEDATE,
    10314303                                AS A_CROWNER, 
    CAST(NULL AS DATE)                      AS A_TS,
    CAST(NULL AS INT)                       AS A_DOC,
    CAST(NULL AS INT)                       AS A_EDITOR,
    CAST(NULL AS FLOAT)                     AS A_PART,
    CAST(NULL AS INT)                       AS A_PARTNUMPART,
    CAST(NULL AS INT)                       AS A_PARTDENOMPART,
    CAST(NULL AS VARCHAR)                   AS A_MARK,
    FROM_FILE_POWER_CAR                     AS A_POWER_HORSE,
    FROM_FILE_YEAR_CAR                      AS A_YEAR,
    CAST(NULL AS INT)                       AS A_SOURCE,
    'Данные из ГИБДД за ' + 
        CONVERT(VARCHAR, GETDATE(), 104)    AS A_COMMENT,
    GETDATE()                               AS DATE_RECEIPT_INFORMATION,
    CAST(NULL AS DATE)                      AS START_OWN_DATE,
    CAST(NULL AS DATE)                      AS END_OWN_DATE,
    category.CATEGORY                       AS A_CATEGORY
FROM #RESULT result
    LEFT JOIN #CODE_CATEGORY category
        ON category.CODE = result.FROM_FILE_TYPE_CAR_CODE


--------------------------------------------------------------------------------------------------------------------------------