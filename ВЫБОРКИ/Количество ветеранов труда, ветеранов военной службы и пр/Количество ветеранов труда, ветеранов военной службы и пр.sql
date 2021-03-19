DECLARE @dataFrom DATE
SET @dataFrom = CONVERT(DATE, '01-01-2016')

DECLARE @dataTo DATE
SET @dataTo = CONVERT(DATE, '31-12-2016')

--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#CLASS_CATEGORY')     IS NOT NULL BEGIN DROP TABLE #CLASS_CATEGORY    END --Классы, к которым относятся льготные категории и которые считаются по одному разу.
IF OBJECT_ID('tempdb..#DOCUMENT')           IS NOT NULL BEGIN DROP TABLE #DOCUMENT          END --Льготная категория по документу.
IF OBJECT_ID('tempdb..#CATEGORY')           IS NOT NULL BEGIN DROP TABLE #CATEGORY          END --Льготная категория по льготной категории.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #CLASS_CATEGORY (
    CLASS_NAME  VARCHAR(256),   --Наименование класса.
    CLASS_CODE  INT,            --Код класса.
    CATEGORY_ID INT,            --Идентификатор категории.
)

--------------------------------------------------------------------------------------------------------------------------------


--Классы и их категории.
INSERT INTO #CLASS_CATEGORY (CLASS_NAME, CLASS_CODE, CATEGORY_ID)
VALUES
    ('Ветераны труда', 0, 46),                      --Ветеран труда.
    ('Ветеран труда Кировской области', 1, 2459),   --Ветеран труда Кировской области.
    ('Жертвы политических репрессий', 2, 258),      --Лица, признанные пострадавшими от политических репрессий.
    ('Жертвы политических репрессий', 2, 260),      --Реабилитированные лица
	('Лица, проработавшие в тылу в период с 22 июня 1941 года по 9 мая 1945 года не менее шести месяцев', 3 ,2181) --Лица, проработавшие в тылу в период с 22.06.1941 по 9.05.1945 не менее 6 месяцев, исключая период работы на временно оккупированных территориях СССР, либо награжденным орденами или медалями СССР за самоотверженный труд в период Великой Отечественной войны
                
                
--------------------------------------------------------------------------------------------------------------------------------


--Выборка льготных категорий по документу.
SELECT
    t.[Личное дело],
    t.[Вид документа],
    t.[Серия документа],
    t.[Номер документа],
    t.[Организация, выдавшая документ (если нет в справочнике)],
    t.[Дата выдачи (продления, подачи)],
    t.[Дата окончания действия],
    t.[Организация, выдавшая документ],
    t.[Статус документа],
    t.[Статус документа в базе данных]
INTO #DOCUMENT
FROM (
    SELECT 
        personalCard.A_TITLE                                AS [Личное дело],
        typeDoc.A_NAME                                      AS [Вид документа],
        actDocuments.DOCUMENTSERIES                         AS [Серия документа],
        actDocuments.DOCUMENTSNUMBER                        AS [Номер документа],
        actDocuments.A_GIVEDOCUMENTORG_TEXT                 AS [Организация, выдавшая документ (если нет в справочнике)],
        CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE)     AS [Дата выдачи (продления, подачи)],
        CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS [Дата окончания действия],
        orgBase.A_NAME1                                     AS [Организация, выдавшая документ],
        docStatus.A_NAME                                    AS [Статус документа],
        esrnStatusDoc.A_NAME                                AS [Статус документа в базе данных],
        --На случай, если в период входит несколько документов.
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID, typeDoc.A_ID ORDER BY actDocuments.ISSUEEXTENSIONSDATE DESC) AS gnum 	
    FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
    -----Статус в БД.
         INNER JOIN ESRN_SERV_STATUS esrnStatusDoc 
            ON esrnStatusDoc.A_ID = actDocuments.A_STATUS --Связка с документом.
                AND esrnStatusDoc.A_ID = 10                 --Статус в БД "Действует".
    ----Статус документа.
        INNER JOIN SPR_DOC_STATUS docStatus
            ON docStatus.A_OUID = actDocuments.A_DOCSTATUS --Связка с документом.
    ----Вид документа.
        INNER JOIN PPR_DOC typeDoc
            ON typeDoc.A_ID = actDocuments.DOCUMENTSTYPE --Связка с документом.     
                AND typeDoc.A_ID IN (
                    1830    --Удостоверение ветерана военной службы.
                )
    ----Личное дело держателя документа.
        INNER JOIN WM_PERSONAL_CARD personalCard
            ON personalCard.OUID = actDocuments.PERSONOUID  --Связка с документом.
                AND personalCard.A_STATUS = 10              --Статус в БД "Действует".
    ----Базовый класс организаций, выдавшей документ.
        LEFT JOIN SPR_ORG_BASE orgBase
            ON orgBase.OUID = actDocuments.GIVEDOCUMENTORG --Связка с документом.    
    WHERE (@dataFrom <= CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE) OR actDocuments.COMPLETIONSACTIONDATE IS NULL)
        AND @dataTo >= CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE)
) t
WHERE t.gnum = 1


--------------------------------------------------------------------------------------------------------------------------------


SELECT 
    t.[Личное дело],
    t.[Класс категории],
    t.[Льготная категория],
    t.[Дата начала действия],
    t.[Дата снятия с учета],
    t.[Статус льготной категории],
    t.[Статус льготной категории в базе данных]
INTO #CATEGORY
FROM (
    SELECT
        personalCard.A_TITLE                    AS [Личное дело],
        classCategory.CLASS_NAME                AS [Класс категории],
        typeCategory.A_NAME                     AS [Льготная категория],		
        CONVERT(DATE, category.A_DATE)          AS [Дата начала действия],
        CONVERT(DATE, category.A_DATELAST)      AS [Дата снятия с учета],
        categoryStatus.A_NAME                   AS [Статус льготной категории],
        esrnStatusCategory.A_NAME               AS [Статус льготной категории в базе данных],
        --На случай, если в период входит несколько льготных категорий разных классов.
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID, classCategory.CLASS_CODE ORDER BY category.A_DATE DESC) AS gnum 		
    FROM WM_CATEGORY category --Льготная категория.
    -----Статус в БД.
         INNER JOIN ESRN_SERV_STATUS esrnStatusCategory 
            ON esrnStatusCategory.A_ID = category.A_STATUS  --Связка с льготной категорией.
                AND esrnStatusCategory.A_ID = 10            --Статус в БД "Действует".
    ----Статус льготной категории.
        INNER JOIN SPR_DOC_STATUS categoryStatus 
            ON categoryStatus.A_OUID = category.A_LCSTATUS --Связка с льготной категорией.
    ----Личное дело льготодержателя.
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.OUID = category.PERSONOUID                      --Связка с льготной категорией.    
                AND personalCard.A_STATUS = 10                              --Статус в БД "Действует".
                AND (personalCard.A_DEATHDATE IS NULL                       --Нет даты смерти.
                    OR @dataFrom <= CONVERT(DATE, personalCard.A_DEATHDATE) --Либо она позже даты начала периода отчета.
                )
    ----Отношение льготной категории к нормативно правовому документу.      
        INNER JOIN PPR_REL_NPD_CAT regulatoryDocument 
            ON regulatoryDocument.A_ID = category.A_NAME --Связка с льготной категорией. 
    ----Классы категорий.
        INNER JOIN #CLASS_CATEGORY classCategory
            ON classCategory.CATEGORY_ID = regulatoryDocument.A_CAT --Связка с нормативно правовым документом.           
    ----Наименования льготных категорий.
        INNER JOIN PPR_CAT typeCategory 
            ON typeCategory.A_ID = classCategory.CATEGORY_ID --Связка с категорией.
    WHERE (@dataFrom <= CONVERT(DATE, category.A_DATELAST) OR category.A_DATELAST IS NULL)
        AND @dataTo >= CONVERT(DATE, category.A_DATE)
) t
WHERE t.gnum = 1


--------------------------------------------------------------------------------------------------------------------------------


--Особое условие того, что из ветеранов труда вычитаем ветеранов военной службы.
DELETE FROM #CATEGORY 
WHERE [Льготная категория] = (SELECT A_NAME FROM PPR_CAT WHERE A_ID = 46)
    AND [Личное дело] IN (SELECT [Личное дело] FROM #DOCUMENT)


--------------------------------------------------------------------------------------------------------------------------------


--Количество.
SELECT 
    [Класс категории],
    COUNT(*) AS [Кол-во]
FROM #CATEGORY
GROUP BY [Класс категории]
UNION ALL
SELECT
    'Ветеран военной службы' AS [Класс категории],
    COUNT(*)
FROM #DOCUMENT


--------------------------------------------------------------------------------------------------------------------------------


--Список.
SELECT * 
FROM #CATEGORY
UNION ALL
SELECT
    [Личное дело],
    'Ветеран военной службы',
    'Ветеран военной службы',
    [Дата выдачи (продления, подачи)],
    [Дата окончания действия],
    [Статус документа],
    [Статус документа в базе данных]
FROM #DOCUMENT


--------------------------------------------------------------------------------------------------------------------------------