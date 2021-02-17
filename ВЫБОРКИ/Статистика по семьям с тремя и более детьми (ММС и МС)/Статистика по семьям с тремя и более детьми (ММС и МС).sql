------------------------------------------------------------------------------------------------------------------------------


--Начало периода отчета.
DECLARE @startDateReport DATE
SET @startDateReport = CONVERT(DATE, '01-01-2020')

--Конец периода отчета.
DECLARE @endDateReport DATE
SET @endDateReport = CONVERT(DATE, '31-12-2020')


------------------------------------------------------------------------------------------------------------------------------



--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#TABLE_AGE')          IS NOT NULL BEGIN DROP TABLE #TABLE_AGE         END --Таблица возрастов.
IF OBJECT_ID('tempdb..#RELATIONSHIP')       IS NOT NULL BEGIN DROP TABLE #RELATIONSHIP      END --Таблица родственных связей людей.
IF OBJECT_ID('tempdb..#MANY_CHILD_FAMILY')  IS NOT NULL BEGIN DROP TABLE #MANY_CHILD_FAMILY END --Таблица людей, имеющих 3 и более детей на момент периода.
IF OBJECT_ID('tempdb..#PASSPORT_PEOPLE')    IS NOT NULL BEGIN DROP TABLE #PASSPORT_PEOPLE   END --Таблица поспартов людей.
IF OBJECT_ID('tempdb..#MANY_CHILD_DOC')     IS NOT NULL BEGIN DROP TABLE #MANY_CHILD_DOC    END --Таблица удостоверений многодетной семьи и удостоверений многодетной малообеспеченной семьи.

IF OBJECT_ID('tempdb..#WHO_BECAME_MANY_CHILD_FAMILY')   IS NOT NULL BEGIN DROP TABLE #WHO_BECAME_MANY_CHILD_FAMILY      END --Кто стал многодетной семьей в период.
IF OBJECT_ID('tempdb..#WHO_STOPPED_MANY_CHILD_FAMILY')  IS NOT NULL BEGIN DROP TABLE #WHO_STOPPED_MANY_CHILD_FAMILY     END --Кто перестал быть многодетной семьей в период.

------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #TABLE_AGE (
    PERSONOUID          INT,    --ID личного дела.  
    BIRTHDATE           DATE,   --Дата рождения человека.  
    DEATH_DATE          DATE,   --Дата смерти человека при наличии.
    AGE_IN_DATE_FROM    INT,    --Возраст относительно даты @startDateReport.
    AGE_IN_DATE_TO      INT,    --Возраст относительно даты @@endDateReport.
)
CREATE TABLE #RELATIONSHIP (
    PERSONOUID_1        INT,    --Личное дело.
    PERSONOUID_2        INT,    --Личное дело родственника.
    RELATIONSHIP_TYPE   INT,    --Родсвтенная связь.
)
CREATE TABLE #MANY_CHILD_FAMILY (
    PERSONOUID              INT,    --Идентификатор личного дела родителя.  
    COUNT_CHILD             INT,    --Количество детей.
    COUNT_BORN_CHILD        INT,    --Количество рожденных детей в период.
    COUNT_GROWN_UP_CHILD    INT,    --Количество детей, исполнившимся 18 лет в период.
    COUNT_DEATH_CHILD       INT,    --Количество умерших детей в период.
)
CREATE TABLE #PASSPORT_PEOPLE (
    PERSONOUID      INT,            --Идентификатор личного дела.    
    PASSPORT_SERIES VARCHAR(50),    --Серия паспорта.
    PASSPORT_NUMBER VARCHAR(50),    --Номер паспорта.
)
--Создание временных таблиц.
CREATE TABLE #MANY_CHILD_DOC (
    PERSONOUID      INT,    --Идентификатор личного дела.  
    DOC_OUID        INT,    --Идентификатор документа.
    DOC_TYPE        INT,    --Тип документа.
    DOC_START_DATE  DATE,   --Дата начала действия документа.
    DOC_END_DATE    DATE,   --Дата окончания действия документа.
    DOC_INDEX_INC   INT,    --Порядковый номер по возрастанию даты начала действия.
    DOC_INDEX_DESC  INT     --Порядковый номер по убыванию даты начала действия.
)

CREATE TABLE #WHO_BECAME_MANY_CHILD_FAMILY (
    PERSONOUID      INT,    --Идентификатор личного дела.  
    START_DATE      DATE,   --Дата начала.
    TYPE_START_DATE INT,    --Тип даты начала (0 - дата начала действия документа, 1 - дата рождения третьего ребенка, но документа нет).
)
CREATE TABLE #WHO_STOPPED_MANY_CHILD_FAMILY (
    PERSONOUID      INT,    --Идентификатор личного дела.  
    STOP_DATE       DATE,   --Дата окончания.
    TYPE_STOP_DATE  INT,    --Тип даты окончания (0 - дата окончание действия документа, 1 - исполнение 18-летия, после чего остается 2 ребенка, 2 - смерть ребенка, после которой остается 2 ребенка).
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка в таблицу возрастов.
INSERT INTO #TABLE_AGE (PERSONOUID, BIRTHDATE, DEATH_DATE, AGE_IN_DATE_FROM, AGE_IN_DATE_TO)
SELECT
    personalCard.OUID                       AS PERSONOUID,
    CONVERT(DATE, personalCard.BIRTHDATE)   AS BIRTHDATE,
    CONVERT(DATE, personalCard.A_DEATHDATE) AS DEATH_DATE,
    DATEDIFF(YEAR, personalCard.BIRTHDATE, @startDateReport) -                      --Вычисление разницы между годами.									
        CASE                                                                        --Определение, был ли в этом году день рождения.
            WHEN MONTH(personalCard.BIRTHDATE)  < MONTH(@startDateReport)  THEN 0   --День рождения был, и он был не в этом месяце.
            WHEN MONTH(personalCard.BIRTHDATE)  > MONTH(@startDateReport)  THEN 1   --День рождения будет в следущих месяцах.
            WHEN DAY(personalCard.BIRTHDATE)    > DAY(@startDateReport)    THEN 1   --В этом месяце день рождения, но его еще не было.
            ELSE 0                                                                  --В этом месяце день рождения, и он уже был.
        END	AS AGE_IN_DATE_FROM,
    DATEDIFF(YEAR, personalCard.BIRTHDATE, @endDateReport) -                        --Вычисление разницы между годами.									
        CASE                                                                        --Определение, был ли в этом году день рождения.
            WHEN MONTH(personalCard.BIRTHDATE)  < MONTH(@endDateReport)  THEN 0     --День рождения был, и он был не в этом месяце.
            WHEN MONTH(personalCard.BIRTHDATE)  > MONTH(@endDateReport)  THEN 1     --День рождения будет в следущих месяцах.
            WHEN DAY(personalCard.BIRTHDATE)    > DAY(@endDateReport)    THEN 1     --В этом месяце день рождения, но его еще не было.
            ELSE 0                                                                  --В этом месяце день рождения, и он уже был.
        END	AS AGE_IN_DATE_TO
FROM WM_PERSONAL_CARD personalCard --Личное дело.


------------------------------------------------------------------------------------------------------------------------------


--Выборка родственных связей людей.
INSERT INTO #RELATIONSHIP (PERSONOUID_1, PERSONOUID_2, RELATIONSHIP_TYPE)
SELECT 
    relationships.A_ID1                     AS PERSONOUID_1,
    relationships.A_ID2                     AS PERSONOUID_2,
    relationships.A_RELATED_RELATIONSHIP    AS RELATIONSHIP_TYPE
FROM WM_RELATEDRELATIONSHIPS relationships --Родственные связи.
----Личное дело родственника.
    INNER JOIN WM_PERSONAL_CARD personalCardChild
        ON personalCardChild.A_STATUS = 10                      --Статусв в БД "Действует".
            AND personalCardChild.OUID = relationships.A_ID2    --Связка с родственной связью.
----Возраст родственника.
    INNER JOIN #TABLE_AGE tableAge
        ON tableAge.AGE_IN_DATE_FROM < 18                       --Меньше 18 лет в начале периода.
            AND tableAge.BIRTHDATE <= @endDateReport            --Родился не позднее конца периода.
            AND (tableAge.DEATH_DATE IS NULL                    --Нет даты смерти.
                OR tableAge.DEATH_DATE >= @startDateReport      --Либо дата смерти после начала периода и...
                AND tableAge.BIRTHDATE != tableAge.DEATH_DATE   --И не мертворожденный.
            )
            AND tableAge.PERSONOUID = personalCardChild.OUID    --Связка с родственником.
----Сведения об опеке.
    LEFT JOIN WM_INCAPABLE_CITIZEN guardianship
        ON guardianship.A_STATUS = 10                           --Статус в БД "Действует".
            AND guardianship.A_PC_TUTOR = relationships.A_ID1   --Опекун.
            AND guardianship.A_PC_CITIZEN = relationships.A_ID2 --Опекуемый.
WHERE relationShips.A_STATUS = 10                               --Статус в БД "Действует".
    AND (relationShips.A_RELATED_RELATIONSHIP IN (3, 4, 26, 43) --Сын, Дочь, Пасынок, Падчерица.
        OR                                                      --Или...
        (relationShips.A_RELATED_RELATIONSHIP IN (11, 12, 17)   --Внук, Другая степень родства, Внучка...
            AND guardianship.A_ID IS NOT NULL                   --При наличии опекунства.
        )              
    )


------------------------------------------------------------------------------------------------------------------------------


--Выборка людей, имеющих 3 и более детей на момент периода.
INSERT INTO #MANY_CHILD_FAMILY (PERSONOUID, COUNT_CHILD, COUNT_BORN_CHILD, COUNT_GROWN_UP_CHILD, COUNT_DEATH_CHILD)
SELECT
    relationship.PERSONOUID_1   AS PERSONOUID,
    COUNT(*)                    AS COUNT_CHILD,
    CAST(NULL AS INT)           AS COUNT_BORN_CHILD,
    CAST(NULL AS INT)           AS COUNT_GROWN_UP_CHILD,
    CAST(NULL AS INT)           AS COUNT_DEATH_CHILD
FROM #RELATIONSHIP relationship --Родственные связи.
GROUP BY PERSONOUID_1
HAVING COUNT(*) >= 3

--Подсчет рожденных детей в период.
UPDATE family
SET family.COUNT_BORN_CHILD = t.COUNT_BORN_CHILD
FROM (
    SELECT
        family.PERSONOUID   AS PERSONOUID,
        COUNT(*)            AS COUNT_BORN_CHILD
    FROM #MANY_CHILD_FAMILY family --Семьи, имеющие 3 и более детей.
    ----Родственные связи.
        INNER JOIN #RELATIONSHIP relationship
            ON relationship.PERSONOUID_1 = family.PERSONOUID
    ----Личное дело родственника.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.BIRTHDATE BETWEEN @startDateReport AND @endDateReport   --Дата рождения в период.
                AND tableAge.PERSONOUID = relationship.PERSONOUID_2             --Связка с родственными связями.  
    GROUP BY family.PERSONOUID
) t
    INNER JOIN #MANY_CHILD_FAMILY family
        ON t.PERSONOUID = family.PERSONOUID

--Подсчет детей, исполнившихся 18 в период.
UPDATE family
SET family.COUNT_GROWN_UP_CHILD = t.COUNT_GROWN_UP_CHILD
FROM (
    SELECT
        family.PERSONOUID   AS PERSONOUID,
        COUNT(*)            AS COUNT_GROWN_UP_CHILD
    FROM #MANY_CHILD_FAMILY family --Семьи, имеющие 3 и более детей.
    ----Родственные связи.
        INNER JOIN #RELATIONSHIP relationship
            ON relationship.PERSONOUID_1 = family.PERSONOUID
    ----Личное дело родственника.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.AGE_IN_DATE_TO >= 18                            --18 и более лет в конце периода.
                AND tableAge.PERSONOUID = relationship.PERSONOUID_2     --Связка с родственными связями.  
    GROUP BY family.PERSONOUID
) t
    INNER JOIN #MANY_CHILD_FAMILY family
        ON t.PERSONOUID = family.PERSONOUID

--Подсчет умерших детей в период.
UPDATE family
SET family.COUNT_DEATH_CHILD = t.COUNT_DEATH_CHILD
FROM (
    SELECT
        family.PERSONOUID   AS PERSONOUID,
        COUNT(*)            AS COUNT_DEATH_CHILD
    FROM #MANY_CHILD_FAMILY family --Семьи, имеющие 3 и более детей.
    ----Родственные связи.
        INNER JOIN #RELATIONSHIP relationship
            ON relationship.PERSONOUID_1 = family.PERSONOUID
    ----Личное дело родственника.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.DEATH_DATE BETWEEN @startDateReport AND @endDateReport  --Умер в период.
                AND tableAge.PERSONOUID = relationship.PERSONOUID_2             --Связка с родственными связями.  
    GROUP BY family.PERSONOUID
) t
    INNER JOIN #MANY_CHILD_FAMILY family
        ON t.PERSONOUID = family.PERSONOUID

--Убираем NULL.
UPDATE family
SET family.COUNT_BORN_CHILD = 0
FROM #MANY_CHILD_FAMILY family --Семьи, имеющие 3 и более детей.
WHERE COUNT_BORN_CHILD IS NULL

--Убираем NULL.
UPDATE family
SET family.COUNT_GROWN_UP_CHILD = 0
FROM #MANY_CHILD_FAMILY family --Семьи, имеющие 3 и более детей.
WHERE COUNT_GROWN_UP_CHILD IS NULL

--Убираем NULL.
UPDATE family
SET family.COUNT_DEATH_CHILD = 0
FROM #MANY_CHILD_FAMILY family --Семьи, имеющие 3 и более детей.
WHERE COUNT_DEATH_CHILD IS NULL

--Выбираем супруга/супруги, если по какой-то причине у него/нее не указаны дети.
INSERT INTO #MANY_CHILD_FAMILY (PERSONOUID, COUNT_CHILD, COUNT_BORN_CHILD, COUNT_GROWN_UP_CHILD, COUNT_DEATH_CHILD)
SELECT 
    relationships.A_ID2         AS PERSONOUID,
    family.COUNT_CHILD          AS COUNT_CHILD,
    family.COUNT_BORN_CHILD     AS COUNT_BORN_CHILD,
    family.COUNT_GROWN_UP_CHILD AS COUNT_GROWN_UP_CHILD,
    family.COUNT_DEATH_CHILD    AS COUNT_DEATH_CHILD
FROM #MANY_CHILD_FAMILY family --Многодетная семья.
----Родственные связи.
    INNER JOIN WM_RELATEDRELATIONSHIPS relationships
        ON relationships.A_ID1 = family.PERSONOUID              --Связка с многодетной семьей.
            AND relationships.A_STATUS = 10                     --Статус в БД "Действует".
            AND relationships.A_RELATED_RELATIONSHIP IN (8, 9)  --Муж, Жена.
WHERE relationships.A_ID2 NOT IN (  --Супруга/Супруги нет в списке многодетных.
    SELECT 
        PERSONOUID 
    FROM #MANY_CHILD_FAMILY 
    WHERE PERSONOUID IS NOT NULL
) 


------------------------------------------------------------------------------------------------------------------------------    
    

--Выборка поспартов людей.
INSERT INTO #PASSPORT_PEOPLE (PERSONOUID, PASSPORT_SERIES, PASSPORT_NUMBER)
SELECT 
    t.PERSONOUID, 
    t.PASSPORT_SERIES,
    t.PASSPORT_NUMBER
FROM (
    SELECT 
        actDocuments.PERSONOUID         AS PERSONOUID,
        actDocuments.DOCUMENTSERIES     AS PASSPORT_SERIES,
        actDocuments.DOCUMENTSNUMBER    AS PASSPORT_NUMBER,
        ROW_NUMBER() OVER (PARTITION BY actDocuments.PERSONOUID ORDER BY actDocuments.ISSUEEXTENSIONSDATE DESC) AS gnum 
    FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.     
    WHERE actDocuments.A_STATUS = 10                    --Статус в БД "Действует".
        AND actDocuments.A_DOCSTATUS = 1                --Действующий документ.
        AND actDocuments.DOCUMENTSTYPE IN (2720, 2277)  --Паспорт гражданина России, иностранный паспорт.
) t
WHERE t.gnum = 1    
    
    
------------------------------------------------------------------------------------------------------------------------------


--Выборка документов многодетной семьи.
INSERT INTO #MANY_CHILD_DOC (PERSONOUID, DOC_OUID, DOC_TYPE, DOC_START_DATE, DOC_END_DATE, DOC_INDEX_INC, DOC_INDEX_DESC)
SELECT 
    actDocuments.PERSONOUID                             AS PERSONOUID,
    actDocuments.OUID                                   AS DOC_OUID,
    actDocuments.DOCUMENTSTYPE                          AS DOC_TYPE,
    CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE)     AS DOC_START_DATE,
    CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS DOC_END_DATE,
    ROW_NUMBER() OVER (PARTITION BY actDocuments.PERSONOUID ORDER BY actDocuments.ISSUEEXTENSIONSDATE)      AS DOC_INDEX_INC,
    ROW_NUMBER() OVER (PARTITION BY actDocuments.PERSONOUID ORDER BY actDocuments.ISSUEEXTENSIONSDATE DESC) AS DOC_INDEX_DESC 
FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
WHERE actDocuments.A_STATUS = 10                    --Статус в БД "Действует".
    AND actDocuments.DOCUMENTSTYPE IN (2858, 2814)  --Удостоверение многодетной семьи или удостоверение многодетной малообеспеченной семьи.


------------------------------------------------------------------------------------------------------------------------------    


--Те, которые, по идее, получили первый документ в период.
INSERT INTO #WHO_BECAME_MANY_CHILD_FAMILY(PERSONOUID, START_DATE, TYPE_START_DATE)
SELECT 
    t.PERSONOUID,
    t.START_DATE,
    0 AS TYPE_START_DATE
FROM (
    SELECT  
        manyChildDoc.PERSONOUID     AS PERSONOUID,
        manyChildDoc.DOC_START_DATE AS START_DATE,
        ROW_NUMBER() OVER (PARTITION BY manyChildDoc.PERSONOUID ORDER BY manyChildDoc.DOC_START_DATE) AS gnum 
    FROM #MANY_CHILD_FAMILY family
        INNER JOIN #MANY_CHILD_DOC manyChildDoc
            ON manyChildDoc.PERSONOUID = family.PERSONOUID
    WHERE family.COUNT_BORN_CHILD > 0                                               --Есть рожденный ребенок в период.
        AND family.COUNT_CHILD - family.COUNT_BORN_CHILD < 3                        --До рождение ребенков в период было меньше 3 детей в семье. 
        AND manyChildDoc.DOC_START_DATE BETWEEN @startDateReport AND @endDateReport --Документ начал действие в период.
) t
WHERE t.gnum = 1

--Те, которые, по идее не получили документ, но третий ребенок все-таки родился.
INSERT INTO #WHO_BECAME_MANY_CHILD_FAMILY(PERSONOUID, START_DATE, TYPE_START_DATE)
SELECT 
    t.PERSONOUID,
    t.START_DATE,
    1 AS TYPE_START_DATE
FROM (
    SELECT  
        family.PERSONOUID   AS PERSONOUID,
        tableAge.BIRTHDATE  AS START_DATE,
        --Самого старшего из родившихся.
        ROW_NUMBER() OVER (PARTITION BY family.PERSONOUID ORDER BY tableAge.BIRTHDATE) AS gnum 
    FROM #MANY_CHILD_FAMILY family
    ----Ребенок.
        INNER JOIN #RELATIONSHIP relationship
            ON relationship.PERSONOUID_1 = family.PERSONOUID
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = relationship.PERSONOUID_2
                AND tableAge.BIRTHDATE BETWEEN @startDateReport AND @endDateReport  --Родился в период отчета.
    WHERE family.COUNT_BORN_CHILD > 0                           --Есть рожденный ребенок в период.
        AND family.COUNT_CHILD - family.COUNT_BORN_CHILD < 3    --До рождение ребенков в период было меньше 3 детей в семье. 
        AND family.PERSONOUID NOT IN (                          --Нет документа, начавшегося в указанный период.
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_START_DATE BETWEEN @startDateReport AND @endDateReport 
        )
) t
WHERE t.gnum = 1 --Самого старшего из родившихся.


------------------------------------------------------------------------------------------------------------------------------


--Те, у которых закончилось действие документа в период.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (PERSONOUID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.PERSONOUID,
    t.STOP_DATE,
    0 AS TYPE_STOP_DATE
FROM (
    SELECT
        manyChildDoc.PERSONOUID     AS PERSONOUID,
        manyChildDoc.DOC_END_DATE   AS STOP_DATE,
        ROW_NUMBER() OVER (PARTITION BY manyChildDoc.PERSONOUID ORDER BY manyChildDoc.DOC_END_DATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
        INNER JOIN #MANY_CHILD_DOC manyChildDoc
            ON manyChildDoc.PERSONOUID = family.PERSONOUID
    WHERE family.COUNT_GROWN_UP_CHILD > 0                                           --Есть дети, которым исполнилось 18 лет.
        AND family.COUNT_CHILD - family.COUNT_GROWN_UP_CHILD < 3                    --После исполнения 18 лет стало меньше трех детей.
        AND manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport   --Документ окончил действие в период.
        AND manyChildDoc.DOC_INDEX_DESC = 1                                         --Больше документов не было.
) t
WHERE t.gnum = 1

--Те, у которых стало меньше 3 детей из-за исполнения 18-ти летия ребенку.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (PERSONOUID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.PERSONOUID,
    t.STOP_DATE,
    1 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.PERSONOUID AS PERSONOUID,
        CAST(
            CAST(YEAR(tableAge.BIRTHDATE) + 18 AS VARCHAR) + '-' + 
            CAST(MONTH(tableAge.BIRTHDATE) AS VARCHAR) + '-' + 
            CAST(DAY(tableAge.BIRTHDATE) AS VARCHAR) AS VARCHAR
        ) AS STOP_DATE,
        --Самого младшего из тех, кому исполнилось 18.
        ROW_NUMBER() OVER (PARTITION BY family.PERSONOUID ORDER BY tableAge.BIRTHDATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
    ----Ребенок.
        INNER JOIN #RELATIONSHIP relationship
            ON relationship.PERSONOUID_1 = family.PERSONOUID
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = relationship.PERSONOUID_2
                AND tableAge.AGE_IN_DATE_FROM <= 17                 --В начале периода меньше 18.
                AND tableAge.AGE_IN_DATE_TO >= 18                   --В конце периода больше 18.
    WHERE family.COUNT_GROWN_UP_CHILD > 0                           --Есть дети, которым исполнилось 18 лет.
        AND family.COUNT_CHILD - family.COUNT_GROWN_UP_CHILD < 3    --После исполнения 18 лет стало меньше трех детей.
        AND family.PERSONOUID NOT IN (                              --Нет документа, оканчивающихся в указанный период.
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
                AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
        )
) t
WHERE t.gnum = 1

--Те, у которых стало меньше 3 детей из-за смерти детей.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (PERSONOUID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.PERSONOUID,
    t.STOP_DATE,
    2 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.PERSONOUID   AS PERSONOUID,
        tableAge.DEATH_DATE AS STOP_DATE,
        --Самого младшего из тех, кому исполнилось 18.
        ROW_NUMBER() OVER (PARTITION BY family.PERSONOUID ORDER BY tableAge.DEATH_DATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
    ----Ребенок.
        INNER JOIN #RELATIONSHIP relationship
            ON relationship.PERSONOUID_1 = family.PERSONOUID
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = relationship.PERSONOUID_2
                AND tableAge.DEATH_DATE BETWEEN @startDateReport AND @endDateReport
    WHERE family.COUNT_DEATH_CHILD > 0                          --Есть дети, которым исполнилось 18 лет.
        AND family.COUNT_CHILD - family.COUNT_DEATH_CHILD < 3   --После смерти стало меньше 3 детей.
        AND family.PERSONOUID NOT IN (                          --Нет документа, оканчивающихся в указанный период.
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
                AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
        )
) t
WHERE t.gnum = 1

------------------------------------------------------------------------------------------------------------------------------


SELECT 
    CASE
        WHEN EXISTS(
            SELECT 
                manyChildDoc.PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc 
            WHERE manyChildDoc.PERSONOUID = personalCard.OUID       --СВязка с запросом извне. 
                AND manyChildDoc.DOC_START_DATE < @endDateReport    --Дата начала не позже конца периода отчета.
                AND manyChildDoc.DOC_END_DATE > @startDateReport    --Дата окончания не раньше начала периода отчета.
        )
        THEN 'Был'
        ELSE 'Нет'
    END                                                                                         AS [Наличие УММС, УМС],
    personalCard.OUID                                                                           AS [Личное дело],
    ISNULL(ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME),    '')                     AS [Фамилия],
    ISNULL(ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME),       '')                     AS [Имя],
    ISNULL(ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME), '')                     AS [Отчество],
    ISNULL(CONVERT(VARCHAR, personalCard.BIRTHDATE, 104), '')                                   AS [Дата рождения],        
    ISNULL(personalCard.A_INN, '')                                                              AS [ИНН],
    ISNULL(personalCard.A_SNILS, '')                                                            AS [СНИЛС],
    CASE
        WHEN addressLive.OUID   IS NOT NULL THEN addressLive.A_ADRTITLE
        WHEN addressTemp.OUID   IS NOT NULL THEN addressTemp.A_ADRTITLE
        WHEN addressReg.OUID    IS NOT NULL THEN addressReg.A_ADRTITLE
        ELSE 'Нет'
    END                                                                                         AS [Адрес],
    ISNULL(passport.PASSPORT_SERIES, '')                                                        AS [Серия паспорта],
    ISNULL(passport.PASSPORT_NUMBER, '')                                                        AS [Номер паспорта],
    family.COUNT_CHILD                                                                          AS [Количество несовершеннолетних детей в 2020],
    family.COUNT_BORN_CHILD                                                                     AS [Количество рожденных детей в 2020],
    family.COUNT_GROWN_UP_CHILD                                                                 AS [Количество детей, достигших 18 летия в 2020],
    family.COUNT_DEATH_CHILD                                                                    AS [Количество умерших детей в 2020],
    ISNULL(CONVERT(VARCHAR, becameManyChildFamily.START_DATE, 104), '')                         AS [Дата начала признания многодетной семьей, в случае рождения ребенка в течение 2020 года],
    CASE becameManyChildFamily.TYPE_START_DATE
        WHEN 0 THEN 'По документу'
        WHEN 1 THEN 'По фактическому рождению'
        ELSE ''
    END                                                                                         AS [Причина начала],                                  
    ISNULL(CONVERT(VARCHAR, stoppedManyChildFamily.STOP_DATE, 104), '')                         AS [Дата окончания признания многодетной семьи, в случае исполнения ребенку совершеннолетия в течение 2020 года],
        CASE stoppedManyChildFamily.TYPE_STOP_DATE
        WHEN 0 THEN 'По документу'
        WHEN 1 THEN 'По фактическому исполнению 18-летия'
        WHEN 2 THEN 'По фактической смерти'
        ELSE ''
    END                                                                                         AS [Причина окончания]
    
    --CASE becameManyChildFamily.TYPE_START_DATE
    --    WHEN 0 THEN ISNULL(CONVERT(VARCHAR, becameManyChildFamily.START_DATE, 104), '') + ' (0)'
    --    WHEN 1 THEN ISNULL(CONVERT(VARCHAR, becameManyChildFamily.START_DATE, 104), '') + ' (1)'
    --END                                                                                         AS [Дата начала признания многодетной семьей, в случае рождения ребенка в течение 2020 года],
    --CASE stoppedManyChildFamily.TYPE_STOP_DATE
    --    WHEN 0 THEN ISNULL(CONVERT(VARCHAR, stoppedManyChildFamily.STOP_DATE, 104), '') + ' (0)'
    --    WHEN 1 THEN ISNULL(CONVERT(VARCHAR, stoppedManyChildFamily.STOP_DATE, 104), '') + ' (1)'
    --    WHEN 2 THEN ISNULL(CONVERT(VARCHAR, stoppedManyChildFamily.STOP_DATE, 104), '') + ' (2)'
    --END                                                                                         AS [Дата окончания признания многодетной семьи, в случае исполнения ребенку совершеннолетия в течение 2020 года]
FROM #MANY_CHILD_FAMILY family
----Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = family.PERSONOUID
        
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME --Связка с личным делом. 
 
----Адрес регистрации. 
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT --Связка с личным делом. 
----Адрес проживания.
    LEFT JOIN WM_ADDRESS addressLive
        ON addressLive.OUID = personalCard.A_LIVEFLAT --Связка с личным делом. 
----Адрес врменной регистрации.
    LEFT JOIN WM_ADDRESS addressTemp
        ON addressTemp.OUID = personalCard.A_TEMPREGFLAT --Связка с личным делом.
        
----Паспорта людей.
    LEFT JOIN #PASSPORT_PEOPLE passport
        ON passport.PERSONOUID = personalCard.OUID --Связка с личным делом.
        
----Кто получил статус многодетной семьи.
    LEFT JOIN #WHO_BECAME_MANY_CHILD_FAMILY becameManyChildFamily
        ON becameManyChildFamily.PERSONOUID = personalCard.OUID --Связка с личным делом.
----Кто потерял статус многодетной семьи.
    LEFT JOIN #WHO_STOPPED_MANY_CHILD_FAMILY stoppedManyChildFamily
        ON stoppedManyChildFamily.PERSONOUID= personalCard.OUID --Связка с личным делом.
ORDER BY ISNULL(ISNULL(personalCard.A_SURNAME_STR, fioSurname.A_NAME), ''),
    ISNULL(ISNULL(personalCard.A_NAME_STR, fioName.A_NAME), ''),
    ISNULL(ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME), '')
