------------------------------------------------------------------------------------------------------------------------------


--Начало периода отчета.
DECLARE @startDateReport DATE
SET @startDateReport = CONVERT(DATE, '01-01-2020')

--Конец периода отчета.
DECLARE @endDateReport DATE
SET @endDateReport = CONVERT(DATE, '31-12-2020')


------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#PERSONAL_CARD_DATE_OFF')         IS NOT NULL BEGIN DROP TABLE #PERSONAL_CARD_DATE_OFF            END --Даты снатия с учетов личных дел.
IF OBJECT_ID('tempdb..#VALID_PERSONAL_CARD_FOR_REPORT') IS NOT NULL BEGIN DROP TABLE #VALID_PERSONAL_CARD_FOR_REPORT    END --Валидные личные дела для отчета.
IF OBJECT_ID('tempdb..#TABLE_AGE')                      IS NOT NULL BEGIN DROP TABLE #TABLE_AGE                         END --Таблица возрастов.
IF OBJECT_ID('tempdb..#PARENT_AND_CHILD')               IS NOT NULL BEGIN DROP TABLE #PARENT_AND_CHILD                  END --Таблица родителей и их детей.
IF OBJECT_ID('tempdb..#HUSBAND_AND_WIFE')               IS NOT NULL BEGIN DROP TABLE #HUSBAND_AND_WIFE                  END --Таблица мужей и жен.
IF OBJECT_ID('tempdb..#MOTHER_AND_FATHER')              IS NOT NULL BEGIN DROP TABLE #MOTHER_AND_FATHER                 END --Таблица матерей и отцов.
IF OBJECT_ID('tempdb..#MANY_CHILD_FAMILY')              IS NOT NULL BEGIN DROP TABLE #MANY_CHILD_FAMILY                 END --Таблица семей, имеющих 3 и более детей на момент периода.
IF OBJECT_ID('tempdb..#MANY_CHILD_DOC')                 IS NOT NULL BEGIN DROP TABLE #MANY_CHILD_DOC                    END --Таблица удостоверений многодетной семьи и удостоверений многодетной малообеспеченной семьи.
IF OBJECT_ID('tempdb..#WHO_BECAME_MANY_CHILD_FAMILY')   IS NOT NULL BEGIN DROP TABLE #WHO_BECAME_MANY_CHILD_FAMILY      END --Кто стал многодетной семьей в период.
IF OBJECT_ID('tempdb..#WHO_STOPPED_MANY_CHILD_FAMILY')  IS NOT NULL BEGIN DROP TABLE #WHO_STOPPED_MANY_CHILD_FAMILY     END --Кто перестал быть многодетной семьей в период.
IF OBJECT_ID('tempdb..#LAST_SDD')                       IS NOT NULL BEGIN DROP TABLE #LAST_SDD                          END --Последнее зарегестрированное СДД.
IF OBJECT_ID('tempdb..#PASSPORT_PEOPLE')                IS NOT NULL BEGIN DROP TABLE #PASSPORT_PEOPLE                   END --Таблица поспартов людей.
IF OBJECT_ID('tempdb..#LIST_CHILD_IN_FAMILY')           IS NOT NULL BEGIN DROP TABLE #LIST_CHILD_IN_FAMILY              END --Список детей в семье. (Работает медленно)

------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #PERSONAL_CARD_DATE_OFF (
    OFF_DATE    DATE,   --Дата снятия с учета.
    PERSONOUID  INT,    --Личное дело.
    REASON_OFF  INT,    --Причина снятия с учета (SPR_RES_REMUV).
)
CREATE TABLE #VALID_PERSONAL_CARD_FOR_REPORT (
    PERSONOUID INT, --Личное дело.
)
CREATE TABLE #TABLE_AGE (
    PERSONOUID          INT,    --ID личного дела.  
    BIRTHDATE           DATE,   --Дата рождения человека.  
    DEATH_DATE          DATE,   --Дата смерти человека при наличии.
    AGE_IN_DATE_FROM    INT,    --Возраст относительно даты @startDateReport.
    AGE_IN_DATE_TO      INT,    --Возраст относительно даты @endDateReport.
)
CREATE TABLE #PARENT_AND_CHILD (
    PARENT_OUID INT,    --Личное дело.
    CHILD_OUID  INT,    --Личное дело родственника.
)
CREATE TABLE #HUSBAND_AND_WIFE (
    PERSONOUID_1        INT,    --Личное дело 1.
    PERSONOUID_2        INT,    --Личное дело 2.
    RELATIONSHIP_TYPE   INT     --Тип отношения 1 к 2.
)
CREATE TABLE #MOTHER_AND_FATHER (
    MOTHER_OUID INT,    --Личное дело матери.
    FATHER_OUID INT,    --Личное дело отца.
    CHILD_OUID  INT,    --Идентификатор ребенка.
)
CREATE TABLE #MANY_CHILD_FAMILY (   
    FAMILY_ID               INT,    --Идентификатор семьи.
    MOTHER_OUID             INT,    --Личное дело матери.
    FATHER_OUID             INT,    --Личное дело отца.
    COUNT_CHILD             INT,    --Количество детей.
    COUNT_BORN_CHILD        INT,    --Количество рожденных детей в период.
    COUNT_GROWN_UP_CHILD    INT,    --Количество детей, исполнившимся 18 лет в период.
    COUNT_DEATH_CHILD       INT,    --Количество умерших детей в период.
)
CREATE TABLE #MANY_CHILD_DOC (
    FAMILY_ID       INT,    --Идентификатор семьи.
    DOC_TYPE        INT,    --Тип документа.
    DOC_START_DATE  DATE,   --Дата начала действия документа.
    DOC_END_DATE    DATE,   --Дата окончания действия документа.
    DOC_INDEX_INC   INT,    --Порядковый номер по возрастанию даты начала действия.
    DOC_INDEX_DESC  INT     --Порядковый номер по убыванию даты начала действия.
)
CREATE TABLE #WHO_BECAME_MANY_CHILD_FAMILY (
    FAMILY_ID       INT,    --Идентификатор семьи.
    START_DATE      DATE,   --Дата начала.
    TYPE_START_DATE INT,    --Тип даты начала (0 - дата начала действия документа, 1 - дата рождения третьего ребенка, но документа нет).
)
CREATE TABLE #WHO_STOPPED_MANY_CHILD_FAMILY (
    FAMILY_ID       INT,    --Идентификатор семьи.
    STOP_DATE       DATE,   --Дата окончания.
    TYPE_STOP_DATE  INT,    --Тип даты окончания (0 - дата окончание действия документа, 1 - исполнение 18-летия, после чего остается 2 ребенка, 2 - смерть ребенка, после которой остается 2 ребенка).
)
CREATE TABLE #LAST_SDD (
    FAMILY_ID   INT,    --Идентификатор семьи.
    SDD         FLOAT,  --СДД.
    DATE_REG    DATE,   --Дата регистрации заявления с СДД.
    SERV_TYPE   INT     --МСП, на которое было подано заявление.
)
CREATE TABLE #PASSPORT_PEOPLE (
    PERSONOUID      INT,            --Идентификатор личного дела.    
    PASSPORT_SERIES VARCHAR(50),    --Серия паспорта.
    PASSPORT_NUMBER VARCHAR(50),    --Номер паспорта.
)
CREATE TABLE #LIST_CHILD_IN_FAMILY (
    FAMILY_ID   INT,            --Идентификатор семьи.
    LIST_CHILD  VARCHAR(1000),  --Список детей в семье.
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка даты снятия с учета личных дел.
INSERT INTO #PERSONAL_CARD_DATE_OFF (OFF_DATE, PERSONOUID, REASON_OFF)
SELECT 
    t.OFF_DATE,
    t.PERSONOUID,
    t.REASON_OFF
FROM (
    SELECT 
        CONVERT(DATE, ISNULL(reasonOff.A_DATE, reasonOff.A_CREATEDATE)) AS OFF_DATE,
        personalCard.OUID                                               AS PERSONOUID,
        reasonOff.A_NAME                                                AS REASON_OFF,
        CONVERT(DATE, reasonOff.A_DATEREPEATIN)                         AS RETURN_DATE,
        --Для отбора последнего снятия.
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID ORDER BY reasonOff.A_DATE DESC) AS gnum 
    FROM WM_REASON reasonOff --Снятие с учета гражданина.
    ----Таблица связки причин с личными делами.
        INNER JOIN SPR_LINK_PERSON_REASON linkWithPersonalCard
            ON linkWithPersonalCard.TOID = reasonOff.A_OUID
    ----Личное дело гражданина.
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.A_PCSTATUS IN (3, 4) --Архивное, либо снятое с учета.
                AND personalCard.OUID = linkWithPersonalCard.FROMID
    WHERE reasonOff.A_STATUS = 10                       --Статус в БД "Действует".
) t
WHERE t.gnum = 1                --Последняя запись.
    AND t.RETURN_DATE IS NULL   --Дело еще не было восстановлено.
;   


--------------------------------------------------------------------------------------------------------------------------------


--Выборка валидных личных дел для отчета.
INSERT INTO #VALID_PERSONAL_CARD_FOR_REPORT (PERSONOUID)
SELECT
    personalCard.OUID   AS PERSONOUID
FROM WM_PERSONAL_CARD personalCard
----Снятые с учета.
    LEFT JOIN #PERSONAL_CARD_DATE_OFF personalCardOff
        ON personalCardOff.PERSONOUID = personalCard.OUID
WHERE personalCard.A_STATUS = 10                                        --Статус в БД "Действует".
    AND (personalCard.A_DEATHDATE IS NULL                               --Нет даты смерти, или...
        OR @startDateReport <= CONVERT(DATE, personalCard.A_DEATHDATE)  --...она позже даты начала периода отчета.
    )
    AND (personalCard.A_PCSTATUS = 1                            --Личное дело действует, или...
        OR @startDateReport <= personalCardOff.OFF_DATE         --...оно не было снято до начала периода.
    )
    --AND personalCard.OUID IN (
    --    853530,
    --    445883,
    --    1368846,
    --    1429370,
    --    1557529,
    --    1476836
    --)
;


--------------------------------------------------------------------------------------------------------------------------------


--Освобождение памяти.
IF OBJECT_ID('tempdb..#PERSONAL_CARD_DATE_OFF') IS NOT NULL BEGIN DROP TABLE #PERSONAL_CARD_DATE_OFF END 
;


--------------------------------------------------------------------------------------------------------------------------------


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
----Валидные дела.
    INNER JOIN #VALID_PERSONAL_CARD_FOR_REPORT validPersonalCard
        ON validPersonalCard.PERSONOUID = personalCard.OUID
WHERE personalCard.BIRTHDATE IS NOT NULL  --Есть дата рождения.
;

------------------------------------------------------------------------------------------------------------------------------


--Выборка родственных связей людей.
INSERT INTO #PARENT_AND_CHILD (PARENT_OUID, CHILD_OUID)
SELECT 
    relationships.A_ID1 AS PARENT_OUID,
    relationships.A_ID2 AS CHILD_OUID
FROM WM_RELATEDRELATIONSHIPS relationships --Родственные связи.
----Возраст родственника.
    INNER JOIN #TABLE_AGE tableAge
        ON tableAge.AGE_IN_DATE_FROM < 18                       --Меньше 18 лет в начале периода.
            AND tableAge.BIRTHDATE <= @endDateReport            --Родился не позднее конца периода.
            AND (tableAge.DEATH_DATE IS NULL                    --Нет даты смерти.
                OR tableAge.DEATH_DATE >= @startDateReport      --Либо дата смерти после начала периода и...
                AND tableAge.BIRTHDATE != tableAge.DEATH_DATE   --И не мертворожденный.
            )
            AND tableAge.PERSONOUID = relationships.A_ID2       --Связка с родственником.
----Сведения об опеке.
    LEFT JOIN WM_INCAPABLE_CITIZEN guardianship
        ON guardianship.A_STATUS = 10                           --Статус в БД "Действует".
            AND guardianship.A_PC_TUTOR = relationships.A_ID1   --Опекун.
            AND guardianship.A_PC_CITIZEN = relationships.A_ID2 --Опекуемый.
WHERE relationShips.A_STATUS = 10                               --Статус в БД "Действует".
    AND relationships.A_ID1 IN (                                --Дело валидно...
        SELECT PERSONOUID FROM #VALID_PERSONAL_CARD_FOR_REPORT  --...а ребенка не проверяем, так как он отсеется при связке с возрастом...
    )                                                           --...так как в таблице возрастов только валидные дела.
    AND (relationShips.A_RELATED_RELATIONSHIP IN (3, 4, 26, 43) --Сын, Дочь, Пасынок, Падчерица.
        OR                                                      --Или...
        (relationShips.A_RELATED_RELATIONSHIP IN (11, 12, 17)   --Внук, Другая степень родства, Внучка...
            AND guardianship.A_ID IS NOT NULL                   --При наличии опекунства.
        )              
    )
;


------------------------------------------------------------------------------------------------------------------------------


--Выборка мужей и жен.
INSERT INTO #HUSBAND_AND_WIFE (PERSONOUID_1, PERSONOUID_2, RELATIONSHIP_TYPE)
SELECT 
    relationship.A_ID1                      AS PERSONOUID_1,
    relationship.A_ID2                      AS PERSONOUID_2,
    relationship.A_RELATED_RELATIONSHIP     AS RELATIONSHIP_TYPE
FROM WM_RELATEDRELATIONSHIPS relationship --Родственные связи.
WHERE relationship.A_STATUS = 10                        --Статус в БД "Действует".
    AND relationship.A_RELATED_RELATIONSHIP IN (8, 9)   --Жена, Муж.
    AND relationship.A_ID1 IN (SELECT PERSONOUID FROM #VALID_PERSONAL_CARD_FOR_REPORT)    
    AND relationship.A_ID2 IN (SELECT PERSONOUID FROM #VALID_PERSONAL_CARD_FOR_REPORT)    
;


------------------------------------------------------------------------------------------------------------------------------


--Выборка полных семей с детьми.
INSERT INTO #MOTHER_AND_FATHER (MOTHER_OUID, FATHER_OUID, CHILD_OUID)
SELECT
    t.MOTHER_OUID,
    t.FATHER_OUID,
    t.CHILD_OUID
FROM ( 
    --Указанные дети у матери.
    SELECT
        wife.PERSONOUID_1       AS MOTHER_OUID,
        husband.PERSONOUID_1    AS FATHER_OUID,
        child.CHILD_OUID        AS CHILD_OUID
    FROM #HUSBAND_AND_WIFE wife --Жена.
    ----Муж.
        INNER JOIN #HUSBAND_AND_WIFE husband                    --В таблице только валидные ЛД.
            ON husband.PERSONOUID_1 = wife.PERSONOUID_2         --Человек указан как муж у жены.
                AND husband.PERSONOUID_2 = wife.PERSONOUID_1    --Человек указан как жена у мужа.
    ----Таблица родителей и их детей.
        INNER JOIN #PARENT_AND_CHILD child                      --В таблице только валидные ЛД.
            ON child.PARENT_OUID = wife.PERSONOUID_1 
    WHERE wife.RELATIONSHIP_TYPE = 9        --К жене человек относится как муж.
        AND husband.RELATIONSHIP_TYPE = 8   --К мужу человек относится как жена.
    --Объединить без дубликатов.
    UNION 
    --Указанные дети у отца.
    SELECT
        wife.PERSONOUID_1       AS MOTHER_OUID,
        husband.PERSONOUID_1    AS FATHER_OUID,
        child.CHILD_OUID        AS CHILD_OUID
    FROM #HUSBAND_AND_WIFE wife --Жена.
    ----Муж.
        INNER JOIN #HUSBAND_AND_WIFE husband                    --В таблице только валидные ЛД.
            ON husband.PERSONOUID_1 = wife.PERSONOUID_2         --Человек указан как муж у жены.
                AND husband.PERSONOUID_2 = wife.PERSONOUID_1    --Человек указан как жена у мужа.
    ----Таблица родителей и их детей.
        INNER JOIN #PARENT_AND_CHILD child                      --В таблице только валидные ЛД.
            ON child.PARENT_OUID = husband.PERSONOUID_1
    WHERE wife.RELATIONSHIP_TYPE = 9        --К жене человек относится как муж.
        AND husband.RELATIONSHIP_TYPE = 8   --К мужу человек относится как жена.
) t

--Выборка не полных семей с детьми (Только отец).
INSERT INTO #MOTHER_AND_FATHER (MOTHER_OUID, FATHER_OUID, CHILD_OUID)
SELECT
    0                   AS WIFE,
    personalCard.OUID   AS HUSBAND,
    child.CHILD_OUID    AS CHILD_OUID
FROM WM_PERSONAL_CARD personalCard
    INNER JOIN #PARENT_AND_CHILD child  --В таблице только валидные ЛД.
        ON child.PARENT_OUID = personalCard.OUID 
WHERE personalCard.A_SEX = 1 --Мужчина.
    AND personalCard.OUID NOT IN (SELECT FATHER_OUID FROM #MOTHER_AND_FATHER)     

--Выборка не полных семей с детьми (Только мать).
INSERT INTO #MOTHER_AND_FATHER (MOTHER_OUID, FATHER_OUID, CHILD_OUID)
SELECT
    personalCard.OUID   AS WIFE,
    0                   AS HUSBAND,
    child.CHILD_OUID    AS CHILD_OUID
FROM WM_PERSONAL_CARD personalCard
    INNER JOIN #PARENT_AND_CHILD child  --В таблице только валидные ЛД.
        ON child.PARENT_OUID = personalCard.OUID 
WHERE personalCard.A_SEX = 2 --Женщина.
    AND personalCard.OUID NOT IN (SELECT MOTHER_OUID FROM #MOTHER_AND_FATHER)   
;


------------------------------------------------------------------------------------------------------------------------------
 

--Освобождение памяти.
IF OBJECT_ID('tempdb..#HUSBAND_AND_WIFE') IS NOT NULL BEGIN DROP TABLE #HUSBAND_AND_WIFE END 
;


------------------------------------------------------------------------------------------------------------------------------


--Выборка семей, имеющих 3 и более детей на момент периода.
INSERT INTO #MANY_CHILD_FAMILY (FAMILY_ID, MOTHER_OUID, FATHER_OUID, COUNT_CHILD, COUNT_BORN_CHILD, COUNT_GROWN_UP_CHILD, COUNT_DEATH_CHILD)
SELECT
    ROW_NUMBER() OVER (ORDER BY family.MOTHER_OUID, family.FATHER_OUID) AS FAMILY_ID,
    family.MOTHER_OUID                                                  AS MOTHER_OUID, 
    family.FATHER_OUID                                                  AS FATHER_OUID,
    COUNT(*)                                                            AS COUNT_CHILD,
    0                                                                   AS COUNT_BORN_CHILD,
    0                                                                   AS COUNT_GROWN_UP_CHILD,
    0                                                                   AS COUNT_DEATH_CHILD
FROM #MOTHER_AND_FATHER family
GROUP BY family.MOTHER_OUID, family.FATHER_OUID
HAVING COUNT(*) >= 3
;

--Подсчет выросших детей, рожденных и умерших.
UPDATE family
SET family.COUNT_BORN_CHILD = countSpecialSituation.COUNT_BORN_CHILD,
    family.COUNT_GROWN_UP_CHILD = countSpecialSituation.COUNT_GROWN_UP_CHILD,
    family.COUNT_DEATH_CHILD = countSpecialSituation.COUNT_DEATH_CHILD
FROM #MANY_CHILD_FAMILY family
    LEFT JOIN (
    ----Подсчет особых ситуаций.
        SELECT 
            specialSituation.FAMILY_ID              AS FAMILY_ID,
            SUM(specialSituation.BORN_CHILD)        AS COUNT_BORN_CHILD,
            SUM(specialSituation.GROWN_UP_CHILD)    AS COUNT_GROWN_UP_CHILD,
            SUM(specialSituation.DEATH_CHILD)       AS COUNT_DEATH_CHILD
        FROM (
        ----Определение особых ситуаций.
            SELECT
                manyChildFamily.FAMILY_ID                                                                       AS FAMILY_ID,
                CASE WHEN tableAge.AGE_IN_DATE_TO >= 18                                     THEN 1 ELSE 0 END   AS GROWN_UP_CHILD,
                CASE WHEN tableAge.BIRTHDATE BETWEEN @startDateReport AND @endDateReport    THEN 1 ELSE 0 END   AS BORN_CHILD,
                CASE WHEN tableAge.DEATH_DATE BETWEEN @startDateReport AND @endDateReport   THEN 1 ELSE 0 END   AS DEATH_CHILD
            FROM #MANY_CHILD_FAMILY manyChildFamily --Многодетная семья.
            ----Родители и их дети.
                INNER JOIN #MOTHER_AND_FATHER motherAndFather
                    ON motherAndFather.MOTHER_OUID = manyChildFamily.MOTHER_OUID
                        AND motherAndFather.FATHER_OUID = manyChildFamily.FATHER_OUID
            ----Информация о ребенке.
                INNER JOIN #TABLE_AGE tableAge
                    ON tableAge.PERSONOUID = motherAndFather.CHILD_OUID
        ) specialSituation
        GROUP BY specialSituation.FAMILY_ID
) countSpecialSituation
    ON countSpecialSituation.FAMILY_ID = family.FAMILY_ID
;


------------------------------------------------------------------------------------------------------------------------------


--Выборка документов многодетной семьи.
INSERT INTO #MANY_CHILD_DOC (FAMILY_ID, DOC_TYPE, DOC_START_DATE, DOC_END_DATE, DOC_INDEX_INC, DOC_INDEX_DESC)
SELECT 
    t.FAMILY_ID,
    t.DOC_TYPE,
    t.DOC_START_DATE,
    t.DOC_END_DATE,
    ROW_NUMBER() OVER (PARTITION BY t.FAMILY_ID ORDER BY t.DOC_START_DATE)        AS DOC_INDEX_INC,
    ROW_NUMBER() OVER (PARTITION BY t.FAMILY_ID ORDER BY t.DOC_START_DATE DESC)   AS DOC_INDEX_DESC 
FROM (
----Документы у матери.
    SELECT 
        family.FAMILY_ID                                    AS FAMILY_ID,
        actDocuments.DOCUMENTSTYPE                          AS DOC_TYPE,
        CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE)     AS DOC_START_DATE,
        CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS DOC_END_DATE
    FROM #MANY_CHILD_FAMILY family --Многодетные семьи.
    ----Действующие документы.
        INNER JOIN WM_ACTDOCUMENTS actDocuments 
            ON actDocuments.PERSONOUID = family.MOTHER_OUID
    WHERE actDocuments.A_STATUS = 10            --Статус в БД "Действует".
        AND actDocuments.DOCUMENTSTYPE IN (
            2858,   --Удостоверение многодетной семьи или удостоверение многодетной малообеспеченной семьи.
            2814    --Удостоверение многодетной семьи.
        )  
----Объединить без дубликатов
    UNION
----Документы у отца.
    SELECT 
        family.FAMILY_ID                                    AS FAMILY_ID,
        actDocuments.DOCUMENTSTYPE                          AS DOC_TYPE,
        CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE)     AS DOC_START_DATE,
        CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS DOC_END_DATE
    FROM #MANY_CHILD_FAMILY family --Многодетные семьи.
    ----Действующие документы.
        INNER JOIN WM_ACTDOCUMENTS actDocuments 
            ON actDocuments.PERSONOUID = family.FATHER_OUID
    WHERE actDocuments.A_STATUS = 10            --Статус в БД "Действует".
        AND actDocuments.DOCUMENTSTYPE IN (
            2858,   --Удостоверение многодетной семьи или удостоверение многодетной малообеспеченной семьи.
            2814    --Удостоверение многодетной семьи.
        )  
) t

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
    FROM #MANY_CHILD_FAMILY family --Многодетная семья.
    ----Действующие документы.  
        INNER JOIN WM_ACTDOCUMENTS actDocuments 
            ON actDocuments.DOCUMENTSTYPE IN (2720, 2277)   --Паспорт гражданина России, иностранный паспорт.
                AND actDocuments.A_DOCSTATUS = 1            --Действующий документ.
                AND actDocuments.A_STATUS = 10              --Статус в БД "Действует".
                AND (actDocuments.PERSONOUID = family.MOTHER_OUID
                    OR actDocuments.PERSONOUID = family.FATHER_OUID
                )
) t
WHERE t.gnum = 1    
;


------------------------------------------------------------------------------------------------------------------------------


--Те, которые, по идее, получили первый документ в период.
INSERT INTO #WHO_BECAME_MANY_CHILD_FAMILY(FAMILY_ID, START_DATE, TYPE_START_DATE)
SELECT 
    t.FAMILY_ID,
    t.START_DATE,
    0 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.FAMILY_ID            AS FAMILY_ID,
        manyChildDoc.DOC_START_DATE AS START_DATE,
        ROW_NUMBER() OVER (PARTITION BY family.FAMILY_ID ORDER BY manyChildDoc.DOC_END_DATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family --Многодетные семьи.
    ----Документы, подтверждающие многодетность.
        INNER JOIN #MANY_CHILD_DOC manyChildDoc
            ON manyChildDoc.FAMILY_ID = family.FAMILY_ID
    WHERE manyChildDoc.DOC_START_DATE BETWEEN @startDateReport AND @endDateReport --Документ начал действие в период.
        AND (manyChildDoc.DOC_INDEX_INC = 1                     --Первый полученный документ, или...
            OR family.COUNT_CHILD - family.COUNT_BORN_CHILD < 3 --...до рождения ребенков в период было меньше 3 детей в семье. 
        )
        
) t
WHERE t.gnum = 1

--Те, которые, по идее не получили документ, но третий ребенок все-таки родился.
INSERT INTO #WHO_BECAME_MANY_CHILD_FAMILY(FAMILY_ID, START_DATE, TYPE_START_DATE)
SELECT 
    t.FAMILY_ID,
    t.START_DATE,
    1 AS TYPE_START_DATE
FROM (
    SELECT  
        family.FAMILY_ID    AS FAMILY_ID,
        tableAge.BIRTHDATE  AS START_DATE,
        --Самого старшего из родившихся.
        ROW_NUMBER() OVER (PARTITION BY family.FAMILY_ID ORDER BY tableAge.BIRTHDATE) AS gnum 
    FROM #MANY_CHILD_FAMILY family --Многодетные семьи.
    ----Родители и их дети.
        INNER JOIN #MOTHER_AND_FATHER motherAndFather
            ON motherAndFather.MOTHER_OUID = family.MOTHER_OUID
                AND motherAndFather.FATHER_OUID = family.FATHER_OUID
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = motherAndFather.CHILD_OUID
                AND tableAge.BIRTHDATE BETWEEN @startDateReport AND @endDateReport  --Родился в период отчета.
    WHERE family.COUNT_BORN_CHILD > 0                           --Есть рожденный ребенок в период.
        AND family.COUNT_CHILD - family.COUNT_BORN_CHILD < 3    --До рождение ребенков в период было меньше 3 детей в семье. 
        AND family.FAMILY_ID NOT IN (                           --Нет документа, начавшегося в указанный период.
            SELECT 
                FAMILY_ID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_START_DATE BETWEEN @startDateReport AND @endDateReport 
        )
) t
WHERE t.gnum = 1 --Самого старшего из родившихся.
;


------------------------------------------------------------------------------------------------------------------------------


--Те, у которых закончилось действие документа в период.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (FAMILY_ID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.FAMILY_ID,
    t.STOP_DATE,
    0 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.FAMILY_ID            AS FAMILY_ID,
        manyChildDoc.DOC_END_DATE   AS STOP_DATE,
        ROW_NUMBER() OVER (PARTITION BY family.FAMILY_ID ORDER BY manyChildDoc.DOC_END_DATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
    ----Документы, подтверждающие многодетность.
        INNER JOIN #MANY_CHILD_DOC manyChildDoc
            ON manyChildDoc.FAMILY_ID = family.FAMILY_ID
    WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
        AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
) t
WHERE t.gnum = 1

--Те, у которых стало меньше 3 детей из-за исполнения 18-ти летия ребенку.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (FAMILY_ID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.FAMILY_ID,
    t.STOP_DATE,
    1 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.FAMILY_ID AS FAMILY_ID,
        CAST(
            CAST(YEAR(tableAge.BIRTHDATE) + 18 AS VARCHAR) + '-' + 
            CAST(MONTH(tableAge.BIRTHDATE) AS VARCHAR) + '-' + 
            CAST(DAY(tableAge.BIRTHDATE) AS VARCHAR) AS VARCHAR
        ) AS STOP_DATE,
        --Самого младшего из тех, кому исполнилось 18.
        ROW_NUMBER() OVER (PARTITION BY family.FAMILY_ID ORDER BY tableAge.BIRTHDATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
    ----Родители и их дети.
        INNER JOIN #MOTHER_AND_FATHER motherAndFather
            ON motherAndFather.MOTHER_OUID = family.MOTHER_OUID
                AND motherAndFather.FATHER_OUID = family.FATHER_OUID
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = motherAndFather.CHILD_OUID
                AND tableAge.AGE_IN_DATE_FROM <= 17                 --В начале периода меньше 18.
                AND tableAge.AGE_IN_DATE_TO >= 18                   --В конце периода больше 18.
    WHERE family.COUNT_GROWN_UP_CHILD > 0                           --Есть дети, которым исполнилось 18 лет.
        AND family.COUNT_CHILD - family.COUNT_GROWN_UP_CHILD < 3    --После исполнения 18 лет стало меньше трех детей.
        AND family.FAMILY_ID NOT IN (                               --Нет документа, оканчивающихся в указанный период.
            SELECT 
                FAMILY_ID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
                AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
        )
) t
WHERE t.gnum = 1

--Те, у которых стало меньше 3 детей из-за смерти детей.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (FAMILY_ID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.FAMILY_ID,
    t.STOP_DATE,
    2 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.FAMILY_ID    AS FAMILY_ID,
        tableAge.DEATH_DATE AS STOP_DATE,
        --Самого младшего из тех, кому исполнилось 18.
        ROW_NUMBER() OVER (PARTITION BY  family.FAMILY_ID ORDER BY tableAge.DEATH_DATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
    ----Родители и их дети.
        INNER JOIN #MOTHER_AND_FATHER motherAndFather
            ON motherAndFather.MOTHER_OUID = family.MOTHER_OUID
                OR motherAndFather.FATHER_OUID = family.FATHER_OUID
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = motherAndFather.CHILD_OUID
                AND tableAge.DEATH_DATE BETWEEN @startDateReport AND @endDateReport
    WHERE family.COUNT_DEATH_CHILD > 0                          --Есть дети, которым исполнилось 18 лет.
        AND family.COUNT_CHILD - family.COUNT_DEATH_CHILD < 3   --После смерти стало меньше 3 детей.
        AND family.FAMILY_ID NOT IN (                           --Нет документа, оканчивающихся в указанный период.
            SELECT 
                FAMILY_ID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
                AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
        )
) t
WHERE t.gnum = 1
;


------------------------------------------------------------------------------------------------------------------------------

--Выбор последнего СДД из заявлений.
INSERT INTO #LAST_SDD(FAMILY_ID, SDD, DATE_REG, SERV_TYPE) 
SELECT
    lastSDD.FAMILY_ID,
    lastSDD.SDD,
    lastSDD.DATE_REG,
    lastSDD.SERV_TYPE
FROM (
----Отбор последнего СДД.
    SELECT  
        SDD.FAMILY_ID,
        SDD.SDD,
        SDD.DATE_REG,
        SDD.SERV_TYPE,
        ROW_NUMBER() OVER (PARTITION BY SDD.FAMILY_ID ORDER BY SDD.DATE_REG DESC) AS gnum 
    FROM (
    ----СДД у матери.
        SELECT 
            family.FAMILY_ID                    AS FAMILY_ID,
            petition.A_SDD                      AS SDD,
            CONVERT(DATE, appeal.A_DATE_REG)    AS DATE_REG,
            petition.A_MSP                      AS SERV_TYPE
        FROM #MANY_CHILD_FAMILY family --Многодетная семья.
        ----Заявления.
            INNER JOIN WM_PETITION petition --Заявления.
                ON petition.A_MSPHOLDER = family.MOTHER_OUID
        ----Обращение гражданина.		
            INNER JOIN WM_APPEAL_NEW appeal     
                ON appeal.OUID = petition.OUID									 
        WHERE appeal.A_STATUS = 10              --Статус в БД "Действует".
            AND ISNULL(petition.A_SDD, 0) <> 0  --СДД есть и он не нулевой.
        UNION   
    ----СДД у отца.
        SELECT 
            family.FAMILY_ID                    AS FAMILY_ID,
            petition.A_SDD                      AS SDD,
            CONVERT(DATE, appeal.A_DATE_REG)    AS DATE_REG,
            petition.A_MSP                      AS SERV_TYPE
        FROM #MANY_CHILD_FAMILY family --Многодетная семья.
        ----Заявления.
            INNER JOIN WM_PETITION petition --Заявления.
                ON petition.A_MSPHOLDER = family.FATHER_OUID
        ----Обращение гражданина.		
            INNER JOIN WM_APPEAL_NEW appeal     
                ON appeal.OUID = petition.OUID									 
        WHERE appeal.A_STATUS = 10              --Статус в БД "Действует".
            AND ISNULL(petition.A_SDD, 0) <> 0  --СДД есть и он не нулевой.  
    ) SDD
) lastSDD
WHERE lastSDD.gnum = 1	    
;


------------------------------------------------------------------------------------------------------------------------------    


--Формирование списка детей в семье (Лучше закоментировать, если не нужен, так как выполняется долго).
INSERT INTO #LIST_CHILD_IN_FAMILY (FAMILY_ID, LIST_CHILD)
SELECT
    family.FAMILY_ID,
    STUFF((
        SELECT 
            ';' + personalCard.A_TITLE
        FROM #MANY_CHILD_FAMILY family2 
        ----Родители и их дети.
            INNER JOIN #MOTHER_AND_FATHER motherAndFather
                ON motherAndFather.MOTHER_OUID = family2.MOTHER_OUID
                    AND motherAndFather.FATHER_OUID = family2.FATHER_OUID
        ----Личное дело гражданина.
            INNER JOIN WM_PERSONAL_CARD personalCard 
                ON personalCard.OUID = motherAndFather.CHILD_OUID          
        WHERE family.FAMILY_ID = family2.FAMILY_ID 
        FOR XML PATH ('')
        ), 1, 1, ''
    ) AS LIST_CHILD     
FROM #MANY_CHILD_FAMILY family

--Для того, чтобы в Excel выводились дети в одной ячейке но в разных стркоах.
UPDATE listChild
SET listChild.LIST_CHILD = '= "' + REPLACE(listChild.LIST_CHILD, ';', '" & СИМВОЛ(10) & "') + '"'
FROM #LIST_CHILD_IN_FAMILY listChild


------------------------------------------------------------------------------------------------------------------------------


--Финальная выборка.
SELECT 
    family.FAMILY_ID                                                                            AS [Семья],
    CASE
        WHEN EXISTS(
            SELECT 
                manyChildDoc.FAMILY_ID 
            FROM #MANY_CHILD_DOC manyChildDoc 
            WHERE manyChildDoc.FAMILY_ID = family.FAMILY_ID
                AND manyChildDoc.DOC_START_DATE < @endDateReport    --Дата начала не позже конца периода отчета.
                AND manyChildDoc.DOC_END_DATE > @startDateReport    --Дата окончания не раньше начала периода отчета.
                AND manyChildDoc.DOC_TYPE = 2858
        )
        THEN 'Был'
        ELSE 'Нет'
    END                                                                                         AS [Наличие УММС],
        CASE
        WHEN EXISTS(
            SELECT 
                manyChildDoc.FAMILY_ID 
            FROM #MANY_CHILD_DOC manyChildDoc 
            WHERE manyChildDoc.FAMILY_ID = family.FAMILY_ID
                AND manyChildDoc.DOC_START_DATE < @endDateReport    --Дата начала не позже конца периода отчета.
                AND manyChildDoc.DOC_END_DATE > @startDateReport    --Дата окончания не раньше начала периода отчета.
                AND manyChildDoc.DOC_TYPE = 2814
        )
        THEN 'Был'
        ELSE 'Нет'
    END                                                                                         AS [Наличие УМС],
    personalCard.OUID                                                                           AS [Личное дело],
    ISNULL(ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME),    '')                     AS [Фамилия],
    ISNULL(ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME),       '')                     AS [Имя],
    ISNULL(ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME), '')                     AS [Отчество],
    ISNULL(CONVERT(VARCHAR, personalCard.BIRTHDATE, 104), '')                                   AS [Дата рождения], 
    ISNULL(personalCard.A_INN, '')                                                              AS [ИНН],
    ISNULL(personalCard.A_SNILS, '')                                                            AS [СНИЛС],  
    ISNULL(addressReg.A_ADRTITLE, '')                                                           AS [Адрес регистрации], 
    ISNULL(passport.PASSPORT_SERIES, '')                                                        AS [Серия паспорта],
    ISNULL(passport.PASSPORT_NUMBER, '')                                                        AS [Номер паспорта],
    family.COUNT_CHILD                                                                          AS [Количество несовершеннолетних детей в 2020],
    ISNULL(listChild.LIST_CHILD, 'Показ отключен')                                              AS [Список детей],
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
    END                                                                                         AS [Причина окончания],
    ISNULL(CONVERT(VARCHAR, lastSDD.SDD), '')                                                   AS [Размер последнего зарегистрированного СДД],
    ISNULL(CONVERT(VARCHAR, lastSDD.DATE_REG), '')                                              AS [Дата регистрации последнего СДД],
    ISNULL(typeServ.A_NAME, '')                                                                 AS [МСП, в котором указано последнее СДД]
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.
----Многодетные семья.
    INNER JOIN #MANY_CHILD_FAMILY family
        ON family.MOTHER_OUID = personalCard.OUID
            OR family.FATHER_OUID = personalCard.OUID
----Кто получил статус многодетной семьи.
    LEFT JOIN #WHO_BECAME_MANY_CHILD_FAMILY becameManyChildFamily
        ON becameManyChildFamily.FAMILY_ID = family.FAMILY_ID
----Кто потерял статус многодетной семьи.
    LEFT JOIN #WHO_STOPPED_MANY_CHILD_FAMILY stoppedManyChildFamily
        ON stoppedManyChildFamily.FAMILY_ID = family.FAMILY_ID
----Последнее СДД.
    LEFT JOIN #LAST_SDD lastSDD
        ON lastSDD.FAMILY_ID = family.FAMILY_ID
----Наименование МСП.	
    LEFT JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = lastSDD.SERV_TYPE 
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME 
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME    
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME 
----Паспорта людей.
    LEFT JOIN #PASSPORT_PEOPLE passport
        ON passport.PERSONOUID = personalCard.OUID
----Адрес регистрации. 
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT
----Список детей в семье.
    LEFT JOIN #LIST_CHILD_IN_FAMILY listChild
        ON listChild.FAMILY_ID = family.FAMILY_ID
;       
        
        
------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#PERSONAL_CARD_DATE_OFF')         IS NOT NULL BEGIN DROP TABLE #PERSONAL_CARD_DATE_OFF            END --Даты снатия с учетов личных дел.
IF OBJECT_ID('tempdb..#VALID_PERSONAL_CARD_FOR_REPORT') IS NOT NULL BEGIN DROP TABLE #VALID_PERSONAL_CARD_FOR_REPORT    END --Валидные личные дела для отчета.
IF OBJECT_ID('tempdb..#TABLE_AGE')                      IS NOT NULL BEGIN DROP TABLE #TABLE_AGE                         END --Таблица возрастов.
IF OBJECT_ID('tempdb..#PARENT_AND_CHILD')               IS NOT NULL BEGIN DROP TABLE #PARENT_AND_CHILD                  END --Таблица родственных связей людей.
IF OBJECT_ID('tempdb..#HUSBAND_AND_WIFE')               IS NOT NULL BEGIN DROP TABLE #HUSBAND_AND_WIFE                  END --Таблица мужей и жен.
IF OBJECT_ID('tempdb..#MOTHER_AND_FATHER')              IS NOT NULL BEGIN DROP TABLE #MOTHER_AND_FATHER                 END --Матерей и отцов.
IF OBJECT_ID('tempdb..#MANY_CHILD_FAMILY')              IS NOT NULL BEGIN DROP TABLE #MANY_CHILD_FAMILY                 END --Таблица семей, имеющих 3 и более детей на момент периода.
IF OBJECT_ID('tempdb..#MANY_CHILD_DOC')                 IS NOT NULL BEGIN DROP TABLE #MANY_CHILD_DOC                    END --Таблица удостоверений многодетной семьи и удостоверений многодетной малообеспеченной семьи.
IF OBJECT_ID('tempdb..#WHO_BECAME_MANY_CHILD_FAMILY')   IS NOT NULL BEGIN DROP TABLE #WHO_BECAME_MANY_CHILD_FAMILY      END --Кто стал многодетной семьей в период.
IF OBJECT_ID('tempdb..#WHO_STOPPED_MANY_CHILD_FAMILY')  IS NOT NULL BEGIN DROP TABLE #WHO_STOPPED_MANY_CHILD_FAMILY     END --Кто перестал быть многодетной семьей в период.
IF OBJECT_ID('tempdb..#LAST_SDD')                       IS NOT NULL BEGIN DROP TABLE #LAST_SDD                          END --Последнее зарегестрированное СДД.
IF OBJECT_ID('tempdb..#PASSPORT_PEOPLE')                IS NOT NULL BEGIN DROP TABLE #PASSPORT_PEOPLE                   END --Таблица поспартов людей.
IF OBJECT_ID('tempdb..#LIST_CHILD_IN_FAMILY')           IS NOT NULL BEGIN DROP TABLE #LIST_CHILD_IN_FAMILY              END --Список детей в семье. (Работает медленно)

------------------------------------------------------------------------------------------------------------------------------ 
