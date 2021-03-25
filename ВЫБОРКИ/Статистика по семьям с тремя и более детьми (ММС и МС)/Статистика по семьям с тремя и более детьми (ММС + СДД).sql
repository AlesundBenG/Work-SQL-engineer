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
IF OBJECT_ID('tempdb..#PARENT_AND_CHILD')               IS NOT NULL BEGIN DROP TABLE #PARENT_AND_CHILD                  END --Таблица родственных связей людей.
IF OBJECT_ID('tempdb..#HUSBAND_AND_WIFE')               IS NOT NULL BEGIN DROP TABLE #HUSBAND_AND_WIFE                  END --Таблица мужей и жен.
IF OBJECT_ID('tempdb..#MOTHER_AND_FATHER')              IS NOT NULL BEGIN DROP TABLE #MOTHER_AND_FATHER                 END --Матерей и отцов.
IF OBJECT_ID('tempdb..#MANY_CHILD_FAMILY')              IS NOT NULL BEGIN DROP TABLE #MANY_CHILD_FAMILY                 END --Таблица семей, имеющих 3 и более детей на момент периода.
IF OBJECT_ID('tempdb..#MANY_CHILD_DOC')                 IS NOT NULL BEGIN DROP TABLE #MANY_CHILD_DOC                    END --Таблица удостоверений многодетной семьи и удостоверений многодетной малообеспеченной семьи.
IF OBJECT_ID('tempdb..#WHO_BECAME_MANY_CHILD_FAMILY')   IS NOT NULL BEGIN DROP TABLE #WHO_BECAME_MANY_CHILD_FAMILY      END --Кто стал многодетной семьей в период.
IF OBJECT_ID('tempdb..#WHO_STOPPED_MANY_CHILD_FAMILY')  IS NOT NULL BEGIN DROP TABLE #WHO_STOPPED_MANY_CHILD_FAMILY     END --Кто перестал быть многодетной семьей в период.
IF OBJECT_ID('tempdb..#LAST_SDD')                       IS NOT NULL BEGIN DROP TABLE #LAST_SDD                          END --Последнее зарегестрированное СДД.
IF OBJECT_ID('tempdb..#PASSPORT_PEOPLE')                IS NOT NULL BEGIN DROP TABLE #PASSPORT_PEOPLE                   END --Таблица поспартов людей.


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
    MOTHER_OUID             INT,    --Личное дело матери.
    FATHER_OUID             INT,    --Личное дело отца.
    COUNT_CHILD             INT,    --Количество детей.
    COUNT_BORN_CHILD        INT,    --Количество рожденных детей в период.
    COUNT_GROWN_UP_CHILD    INT,    --Количество детей, исполнившимся 18 лет в период.
    COUNT_DEATH_CHILD       INT,    --Количество умерших детей в период.
)
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
    MOTHER_OUID     INT,    --Личное дело матери.
    FATHER_OUID     INT,    --Личное дело отца.
    START_DATE      DATE,   --Дата начала.
    TYPE_START_DATE INT,    --Тип даты начала (0 - дата начала действия документа, 1 - дата рождения третьего ребенка, но документа нет).
)
CREATE TABLE #WHO_STOPPED_MANY_CHILD_FAMILY (
    MOTHER_OUID     INT,    --Личное дело матери.
    FATHER_OUID     INT,    --Личное дело отца.
    STOP_DATE       DATE,   --Дата окончания.
    TYPE_STOP_DATE  INT,    --Тип даты окончания (0 - дата окончание действия документа, 1 - исполнение 18-летия, после чего остается 2 ребенка, 2 - смерть ребенка, после которой остается 2 ребенка).
)
CREATE TABLE #LAST_SDD (
    MOTHER_OUID INT,    --Личное дело матери.
    FATHER_OUID INT,    --Личное дело отца.
    SDD         FLOAT,  --СДД.
    DATE_REG    DATE,   --Дата регистрации заявления с СДД.
    SERV_TYPE   INT     --МСП, на которое было подано заявление.
)
CREATE TABLE #PASSPORT_PEOPLE (
    PERSONOUID      INT,            --Идентификатор личного дела.    
    PASSPORT_SERIES VARCHAR(50),    --Серия паспорта.
    PASSPORT_NUMBER VARCHAR(50),    --Номер паспорта.
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
        CONVERT(DATE, reasonOff.A_DATE)         AS OFF_DATE,
        personalCard.OUID                       AS PERSONOUID,
        reasonOff.A_NAME                        AS REASON_OFF,
        CONVERT(DATE, reasonOff.A_DATEREPEATIN) AS RETURN_DATE,
        --Для отбора последнего снятия.
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID ORDER BY reasonOff.A_DATE DESC) AS gnum 
    FROM WM_REASON reasonOff --Снятие с учета гражданина.
    ----Таблица связки причин с личными делами.
        INNER JOIN SPR_LINK_PERSON_REASON linkWithPersonalCard
            ON linkWithPersonalCard.TOID = reasonOff.A_OUID
    ----Личное дело гражданина.
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.OUID = linkWithPersonalCard.FROMID
                AND personalCard.A_PCSTATUS IN (3, 4)   --Архивное, либо снятое с учета.
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
    AND personalCard.OUID IS NOT NULL                                   --Есть дело.
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
WHERE personalCard.OUID IN (SELECT PERSONOUID FROM #VALID_PERSONAL_CARD_FOR_REPORT)
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
            --OR child.PARENT_OUID = husband.PERSONOUID_1   --Бесконечное выполнение с этим условием, хотя желательно подцепить еще на всякий случай детей мужа, вдруг у жены они не указаны.
WHERE wife.RELATIONSHIP_TYPE = 9        --К жене человек относится как муж.
    AND husband.RELATIONSHIP_TYPE = 8   --К мужу человек относится как жена.
;

--Выборка не полных семей с детьми (Только отец).
INSERT INTO #MOTHER_AND_FATHER (MOTHER_OUID, FATHER_OUID, CHILD_OUID)
SELECT
    CAST(NULL AS INT)   AS WIFE,
    personalCard.OUID   AS HUSBAND,
    child.CHILD_OUID    AS CHILD_OUID
FROM WM_PERSONAL_CARD personalCard
    INNER JOIN #PARENT_AND_CHILD child  --В таблице только валидные ЛД.
        ON child.PARENT_OUID = personalCard.OUID 
WHERE personalCard.A_SEX = 1 --Мужчина.
    AND personalCard.OUID NOT IN (SELECT FATHER_OUID FROM #MOTHER_AND_FATHER WHERE FATHER_OUID IS NOT NULL)     

--Выборка не полных семей с детьми (Только мать).
INSERT INTO #MOTHER_AND_FATHER (MOTHER_OUID, FATHER_OUID, CHILD_OUID)
SELECT
    personalCard.OUID   AS WIFE,
    CAST(NULL AS INT)   AS HUSBAND,
    child.CHILD_OUID    AS CHILD_OUID
FROM WM_PERSONAL_CARD personalCard
    INNER JOIN #PARENT_AND_CHILD child  --В таблице только валидные ЛД.
        ON child.PARENT_OUID = personalCard.OUID 
WHERE personalCard.A_SEX = 2 --Женщина.
    AND personalCard.OUID NOT IN (SELECT MOTHER_OUID FROM #MOTHER_AND_FATHER WHERE MOTHER_OUID IS NOT NULL)   
;


------------------------------------------------------------------------------------------------------------------------------
 

--Освобождение памяти.
IF OBJECT_ID('tempdb..#HUSBAND_AND_WIFE') IS NOT NULL BEGIN DROP TABLE #HUSBAND_AND_WIFE END 
;


------------------------------------------------------------------------------------------------------------------------------


--Выборка семей, имеющих 3 и более детей на момент периода.
INSERT INTO #MANY_CHILD_FAMILY (MOTHER_OUID, FATHER_OUID, COUNT_CHILD, COUNT_BORN_CHILD, COUNT_GROWN_UP_CHILD, COUNT_DEATH_CHILD)
SELECT
    family.MOTHER_OUID  AS MOTHER_OUID,
    family.FATHER_OUID  AS FATHER_OUID,
    COUNT(*)            AS COUNT_CHILD,
    0                   AS COUNT_BORN_CHILD,
    0                   AS COUNT_GROWN_UP_CHILD,
    0                   AS COUNT_DEATH_CHILD
FROM #MOTHER_AND_FATHER family
GROUP BY family.MOTHER_OUID, family.FATHER_OUID
HAVING COUNT(*) >= 3
;

--Подсчет выросших детей, рожденных и умерших.
UPDATE family
SET family.COUNT_BORN_CHILD = t.COUNT_BORN_CHILD,
    family.COUNT_GROWN_UP_CHILD = t.COUNT_GROWN_UP_CHILD,
    family.COUNT_DEATH_CHILD = t.COUNT_DEATH_CHILD
FROM #MANY_CHILD_FAMILY family
    LEFT JOIN (
    ----Подсчет особых ситуаций.
        SELECT 
            t.MOTHER_OUID           AS MOTHER_OUID,
            t.FATHER_OUID           AS FATHER_OUID,
            SUM(t.BORN_CHILD)       AS COUNT_BORN_CHILD,
            SUM(t.GROWN_UP_CHILD)   AS COUNT_GROWN_UP_CHILD,
            SUM(t.DEATH_CHILD)      AS COUNT_DEATH_CHILD
        FROM (
        ----Определение особых ситуаций.
            SELECT
                manyChildFamily.MOTHER_OUID     AS MOTHER_OUID,
                manyChildFamily.FATHER_OUID     AS FATHER_OUID, 
                motherAndFather.CHILD_OUID      AS CHILD_OUID,
                CASE WHEN tableAge.AGE_IN_DATE_TO >= 18                                     THEN 1 ELSE 0 END  AS GROWN_UP_CHILD,
                CASE WHEN tableAge.BIRTHDATE BETWEEN @startDateReport AND @endDateReport    THEN 1 ELSE 0 END  AS BORN_CHILD,
                CASE WHEN tableAge.DEATH_DATE BETWEEN @startDateReport AND @endDateReport   THEN 1 ELSE 0 END  AS DEATH_CHILD
            FROM #MANY_CHILD_FAMILY manyChildFamily --Многодетная семья.
            ----Родители и их дети.
                INNER JOIN #MOTHER_AND_FATHER motherAndFather
                    ON ISNULL(motherAndFather.MOTHER_OUID, 0) = ISNULL(manyChildFamily.MOTHER_OUID, 0)
                        AND ISNULL(motherAndFather.FATHER_OUID, 0) = ISNULL(manyChildFamily.FATHER_OUID, 0)
            ----Информация о ребенке.
                INNER JOIN #TABLE_AGE tableAge
                    ON tableAge.PERSONOUID = motherAndFather.CHILD_OUID
        ) t
        GROUP BY t.MOTHER_OUID, t.FATHER_OUID
) t
    ON ISNULL(t.MOTHER_OUID, 0) = ISNULL(family.MOTHER_OUID, 0)
        AND ISNULL(t.FATHER_OUID, 0) = ISNULL(family.FATHER_OUID, 0)
;


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
WHERE actDocuments.A_STATUS = 10    --Статус в БД "Действует".
    AND actDocuments.DOCUMENTSTYPE IN (
        2858,   --Удостоверение многодетной семьи или удостоверение многодетной малообеспеченной семьи.
        2814    --Удостоверение многодетной семьи.
    )  
;

------------------------------------------------------------------------------------------------------------------------------


--Те, которые, по идее, получили первый документ в период.
INSERT INTO #WHO_BECAME_MANY_CHILD_FAMILY(MOTHER_OUID, FATHER_OUID, START_DATE, TYPE_START_DATE)
SELECT 
    t.MOTHER_OUID,
    t.FATHER_OUID,
    t.STOP_DATE,
    0 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.MOTHER_OUID          AS MOTHER_OUID,
        family.FATHER_OUID          AS FATHER_OUID,
        manyChildDoc.DOC_END_DATE   AS STOP_DATE,
        ROW_NUMBER() OVER (PARTITION BY family.MOTHER_OUID, family.FATHER_OUID ORDER BY manyChildDoc.DOC_END_DATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family --Многодетные семьи.
    ----Документы, подтверждающие многодетность.
        INNER JOIN #MANY_CHILD_DOC manyChildDoc
            ON manyChildDoc.PERSONOUID = ISNULL(family.MOTHER_OUID, 0)
                OR manyChildDoc.PERSONOUID = ISNULL(family.FATHER_OUID, 0)
    WHERE family.COUNT_CHILD - family.COUNT_BORN_CHILD < 3                          --До рождение ребенков в период было меньше 3 детей в семье. 
        AND manyChildDoc.DOC_START_DATE BETWEEN @startDateReport AND @endDateReport --Документ начал действие в период.
) t
WHERE t.gnum = 1

--Те, которые, по идее не получили документ, но третий ребенок все-таки родился.
INSERT INTO #WHO_BECAME_MANY_CHILD_FAMILY(MOTHER_OUID, FATHER_OUID, START_DATE, TYPE_START_DATE)
SELECT 
    t.MOTHER_OUID,
    t.FATHER_OUID,
    t.START_DATE,
    1 AS TYPE_START_DATE
FROM (
    SELECT  
        family.MOTHER_OUID  AS MOTHER_OUID,
        family.FATHER_OUID  AS FATHER_OUID,
        tableAge.BIRTHDATE  AS START_DATE,
        --Самого старшего из родившихся.
        ROW_NUMBER() OVER (PARTITION BY family.MOTHER_OUID, family.FATHER_OUID ORDER BY tableAge.BIRTHDATE) AS gnum 
    FROM #MANY_CHILD_FAMILY family --Многодетные семьи.
    ----Родители и их дети.
        INNER JOIN #MOTHER_AND_FATHER motherAndFather
            ON ISNULL(motherAndFather.MOTHER_OUID, 0) = ISNULL(family.MOTHER_OUID, 0)
                OR ISNULL(motherAndFather.FATHER_OUID, 0) = ISNULL(family.FATHER_OUID, 0)
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = motherAndFather.CHILD_OUID
                AND tableAge.BIRTHDATE BETWEEN @startDateReport AND @endDateReport  --Родился в период отчета.
    WHERE family.COUNT_BORN_CHILD > 0                           --Есть рожденный ребенок в период.
        AND family.COUNT_CHILD - family.COUNT_BORN_CHILD < 3    --До рождение ребенков в период было меньше 3 детей в семье. 
        AND motherAndFather.MOTHER_OUID NOT IN (                --Нет документа, начавшегося в указанный период.
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_START_DATE BETWEEN @startDateReport AND @endDateReport 
        )
        AND motherAndFather.FATHER_OUID NOT IN (            
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_START_DATE BETWEEN @startDateReport AND @endDateReport 
        )
) t
WHERE t.gnum = 1 --Самого старшего из родившихся.
;


------------------------------------------------------------------------------------------------------------------------------


--Те, у которых закончилось действие документа в период.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (MOTHER_OUID, FATHER_OUID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.MOTHER_OUID,
    t.FATHER_OUID,
    t.STOP_DATE,
    0 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.MOTHER_OUID          AS MOTHER_OUID,
        family.FATHER_OUID          AS FATHER_OUID,
        manyChildDoc.DOC_END_DATE   AS STOP_DATE,
        ROW_NUMBER() OVER (PARTITION BY family.MOTHER_OUID, family.FATHER_OUID ORDER BY manyChildDoc.DOC_END_DATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
        INNER JOIN #MANY_CHILD_DOC manyChildDoc
            ON manyChildDoc.PERSONOUID = ISNULL(family.MOTHER_OUID, 0)
                OR manyChildDoc.PERSONOUID = ISNULL(family.FATHER_OUID, 0)
    WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
        AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
) t
WHERE t.gnum = 1


--Те, у которых стало меньше 3 детей из-за исполнения 18-ти летия ребенку.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (MOTHER_OUID, FATHER_OUID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.MOTHER_OUID,
    t.FATHER_OUID,
    t.STOP_DATE,
    1 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.MOTHER_OUID  AS MOTHER_OUID,
        family.FATHER_OUID  AS FATHER_OUID,
        CAST(
            CAST(YEAR(tableAge.BIRTHDATE) + 18 AS VARCHAR) + '-' + 
            CAST(MONTH(tableAge.BIRTHDATE) AS VARCHAR) + '-' + 
            CAST(DAY(tableAge.BIRTHDATE) AS VARCHAR) AS VARCHAR
        ) AS STOP_DATE,
        --Самого младшего из тех, кому исполнилось 18.
        ROW_NUMBER() OVER (PARTITION BY family.MOTHER_OUID, family.FATHER_OUID ORDER BY tableAge.BIRTHDATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
    ----Родители и их дети.
        INNER JOIN #MOTHER_AND_FATHER motherAndFather
            ON ISNULL(motherAndFather.MOTHER_OUID, 0) = ISNULL(family.MOTHER_OUID, 0)
                OR ISNULL(motherAndFather.FATHER_OUID, 0) = ISNULL(family.FATHER_OUID, 0)
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = motherAndFather.CHILD_OUID
                AND tableAge.AGE_IN_DATE_FROM <= 17                 --В начале периода меньше 18.
                AND tableAge.AGE_IN_DATE_TO >= 18                   --В конце периода больше 18.
    WHERE family.COUNT_GROWN_UP_CHILD > 0                           --Есть дети, которым исполнилось 18 лет.
        AND family.COUNT_CHILD - family.COUNT_GROWN_UP_CHILD < 3    --После исполнения 18 лет стало меньше трех детей.
        AND family.MOTHER_OUID NOT IN (                              --Нет документа, оканчивающихся в указанный период.
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
                AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
        )
        AND family.FATHER_OUID NOT IN (                              --Нет документа, оканчивающихся в указанный период.
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
                AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
        )
) t
WHERE t.gnum = 1

--Те, у которых стало меньше 3 детей из-за смерти детей.
INSERT INTO #WHO_STOPPED_MANY_CHILD_FAMILY (MOTHER_OUID, FATHER_OUID, STOP_DATE, TYPE_STOP_DATE)
SELECT 
    t.MOTHER_OUID,
    t.FATHER_OUID,
    t.STOP_DATE,
    2 AS TYPE_STOP_DATE
FROM (
    SELECT
        family.MOTHER_OUID  AS MOTHER_OUID,
        family.FATHER_OUID  AS FATHER_OUID,
        tableAge.DEATH_DATE AS STOP_DATE,
        --Самого младшего из тех, кому исполнилось 18.
        ROW_NUMBER() OVER (PARTITION BY family.MOTHER_OUID, family.FATHER_OUID ORDER BY tableAge.DEATH_DATE DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family
    ----Родители и их дети.
        INNER JOIN #MOTHER_AND_FATHER motherAndFather
            ON ISNULL(motherAndFather.MOTHER_OUID, 0) = ISNULL(family.MOTHER_OUID, 0)
                OR ISNULL(motherAndFather.FATHER_OUID, 0) = ISNULL(family.FATHER_OUID, 0)
    ----Возраст ребенка.
        INNER JOIN #TABLE_AGE tableAge
            ON tableAge.PERSONOUID = motherAndFather.CHILD_OUID
                AND tableAge.DEATH_DATE BETWEEN @startDateReport AND @endDateReport
    WHERE family.COUNT_DEATH_CHILD > 0                          --Есть дети, которым исполнилось 18 лет.
        AND family.COUNT_CHILD - family.COUNT_DEATH_CHILD < 3   --После смерти стало меньше 3 детей.
        AND family.MOTHER_OUID NOT IN (                              --Нет документа, оканчивающихся в указанный период.
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
                AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
        )
        AND family.FATHER_OUID NOT IN (                              --Нет документа, оканчивающихся в указанный период.
            SELECT 
                PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc
            WHERE manyChildDoc.DOC_END_DATE BETWEEN @startDateReport AND @endDateReport --Документ окончил действие в период.
                AND manyChildDoc.DOC_INDEX_DESC = 1                                     --Больше документов не было.
        )
) t
WHERE t.gnum = 1
;


------------------------------------------------------------------------------------------------------------------------------

--Выбор последнего СДД из заявлений.
INSERT INTO #LAST_SDD(MOTHER_OUID, FATHER_OUID, SDD, DATE_REG, SERV_TYPE) 
SELECT  
    t.MOTHER_OUID,
    t.FATHER_OUID,
    t.SDD,
    t.DATE_REG,
    t.SERV_TYPE
FROM (
    SELECT 
        family.MOTHER_OUID                  AS MOTHER_OUID,
        family.FATHER_OUID                  AS FATHER_OUID,
        petition.A_SDD                      AS SDD,
        CONVERT(DATE, appeal.A_DATE_REG)    AS DATE_REG,
        petition.A_MSP                      AS SERV_TYPE,
        --Для отбора последнего.
        ROW_NUMBER() OVER (PARTITION BY family.MOTHER_OUID, family.FATHER_OUID ORDER BY appeal.A_DATE_REG DESC) AS gnum 
    FROM #MANY_CHILD_FAMILY family --Многодетная семья.
    ----Заявления.
        INNER JOIN WM_PETITION petition --Заявления.
            ON petition.A_MSPHOLDER = ISNULL(family.MOTHER_OUID, 0)
                OR petition.A_MSPHOLDER = ISNULL(family.FATHER_OUID, 0)
    ----Обращение гражданина.		
        INNER JOIN WM_APPEAL_NEW appeal     
            ON appeal.OUID = petition.OUID --Связка с заявлением.										 
    WHERE appeal.A_STATUS = 10              --Статус в БД "Действует".
        AND ISNULL(petition.A_SDD, 0) <> 0  --СДД есть и он не нулевой.
) t
WHERE t.gnum = 1	    
;


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
        INNER JOIN #MANY_CHILD_FAMILY family --Многодетная семья.
            ON family.MOTHER_OUID = actDocuments.PERSONOUID
                OR family.FATHER_OUID = actDocuments.PERSONOUID
    WHERE actDocuments.A_STATUS = 10                    --Статус в БД "Действует".
        AND actDocuments.A_DOCSTATUS = 1                --Действующий документ.
        AND actDocuments.DOCUMENTSTYPE IN (2720, 2277)  --Паспорт гражданина России, иностранный паспорт.
) t
WHERE t.gnum = 1    
;
    
    
------------------------------------------------------------------------------------------------------------------------------


--Финальная выборка.
SELECT 
    DENSE_RANK() OVER (ORDER BY family.MOTHER_OUID, family.FATHER_OUID )                        AS [Семья],
    CASE
        WHEN EXISTS(
            SELECT 
                manyChildDoc.PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc 
            WHERE (manyChildDoc.PERSONOUID = family.MOTHER_OUID
                    OR manyChildDoc.PERSONOUID = family.FATHER_OUID
                )
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
                manyChildDoc.PERSONOUID 
            FROM #MANY_CHILD_DOC manyChildDoc 
            WHERE (manyChildDoc.PERSONOUID = family.MOTHER_OUID
                    OR manyChildDoc.PERSONOUID = family.FATHER_OUID
                )
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
        ON ISNULL(becameManyChildFamily.MOTHER_OUID, 0) = ISNULL(family.MOTHER_OUID, 0)
            AND ISNULL(becameManyChildFamily.FATHER_OUID, 0) = ISNULL(family.FATHER_OUID, 0)
----Кто потерял статус многодетной семьи.
    LEFT JOIN #WHO_STOPPED_MANY_CHILD_FAMILY stoppedManyChildFamily
        ON ISNULL(stoppedManyChildFamily.MOTHER_OUID, 0) = ISNULL(family.MOTHER_OUID, 0)
            AND ISNULL(stoppedManyChildFamily.FATHER_OUID, 0) = ISNULL(family.FATHER_OUID, 0)
----Последнее СДД.
    LEFT JOIN #LAST_SDD lastSDD
        ON ISNULL(lastSDD.MOTHER_OUID, 0) = ISNULL(family.MOTHER_OUID, 0)
            AND ISNULL(lastSDD.FATHER_OUID, 0) = ISNULL(family.FATHER_OUID, 0)
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
        ON passport.PERSONOUID = personalCard.OUID --Связка с личным делом.
----Адрес регистрации. 
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT --Связка с личным делом.
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


------------------------------------------------------------------------------------------------------------------------------ 