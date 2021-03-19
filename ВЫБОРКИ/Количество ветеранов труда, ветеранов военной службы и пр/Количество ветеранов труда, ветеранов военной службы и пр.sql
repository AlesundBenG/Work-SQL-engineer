DECLARE @dataFrom DATE
SET @dataFrom = CONVERT(DATE, '01-01-2015')

DECLARE @dataTo DATE
SET @dataTo = CONVERT(DATE, '31-12-2015')

--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#CATEGORY') IS NOT NULL BEGIN DROP TABLE #CATEGORY END


--------------------------------------------------------------------------------------------------------------------------------


SELECT 
    t.[Личное дело],
    t.[Льготная категория],
    t.[Дата начала действия],
    t.[Дата снятия с учета],
    t.[Статус льготной категории],
    t.[Статус льготной категории в базе данных]
INTO #CATEGORY
FROM (
    SELECT
        personalCard.A_TITLE                    AS [Личное дело],
        typeCategory.A_NAME                     AS [Льготная категория],		
        CONVERT(DATE, category.A_DATE)          AS [Дата начала действия],
        CONVERT(DATE, category.A_DATELAST)      AS [Дата снятия с учета],
        categoryStatus.A_NAME                   AS [Статус льготной категории],
        esrnStatusCategory.A_NAME               AS [Статус льготной категории в базе данных],
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID, typeCategory.A_ID ORDER BY category.A_DATE DESC) AS gnum 		
    FROM WM_CATEGORY category --Льготная категория.
    -----Статус в БД.
         INNER JOIN ESRN_SERV_STATUS esrnStatusCategory 
            ON esrnStatusCategory.A_ID = category.A_STATUS --Связка с льготной категорией.
                AND esrnStatusCategory.A_ID = 10
    ----Статус льготной категории.
        INNER JOIN SPR_DOC_STATUS categoryStatus 
            ON categoryStatus.A_OUID = category.A_LCSTATUS --Связка с льготной категорией.
    ----Личное дело льготодержателя.
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.OUID = category.PERSONOUID --Связка с льготной категорией.    
                AND personalCard.A_STATUS = 10
                AND (personalCard.A_DEATHDATE IS NULL 
                    OR @dataFrom <= CONVERT(DATE, personalCard.A_DEATHDATE) 
                )
    ----Отношение льготной категории к нормативно правовому документу.      
        INNER JOIN PPR_REL_NPD_CAT regulatoryDocument 
            ON regulatoryDocument.A_ID = category.A_NAME --Связка с льготной категорией. 
    ----Наименования льготных категорий.
        INNER JOIN PPR_CAT typeCategory 
            ON typeCategory.A_ID = regulatoryDocument.A_CAT --Связка с нормативно правовым документом.
                AND typeCategory.A_ID IN (
                    46,     --Ветеран труда.
                    42,     --Ветеран военной службы.
                    2459,   --Ветеран труда Кировской области.
                    258,    --Лица, признанные пострадавшими от политических репрессий.
                    2181    --Лица, проработавшие в тылу в период с 22.06.1941 по 9.05.1945 не менее 6 месяцев, исключая период работы на временно оккупированных территориях СССР, либо награжденным орденами или медалями СССР за самоотверженный труд в период Великой Отечественной войны
                )
    WHERE (@dataFrom <= CONVERT(DATE, category.A_DATELAST) OR category.A_DATELAST IS NULL)
        AND @dataTo >= CONVERT(DATE, category.A_DATE)
) t
WHERE t.gnum = 1


--------------------------------------------------------------------------------------------------------------------------------

--Количество.
SELECT 
    [Льготная категория],
    COUNT(*) AS [Кол-во]
FROM #CATEGORY
GROUP BY [Льготная категория]

--Список.
SELECT * FROM #CATEGORY


--------------------------------------------------------------------------------------------------------------------------------