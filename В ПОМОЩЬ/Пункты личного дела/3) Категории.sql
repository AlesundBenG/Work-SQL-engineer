SELECT
    personalCard.A_TITLE                    AS [Личное дело],
    typeCategory.A_NAME                     AS [Льготная категория],		
    CONVERT(DATE, category.A_DATE)          AS [Дата начала действия],
    CONVERT(DATE, category.A_DATELAST)      AS [Дата снятия с учета],
    categoryStatus.A_NAME                   AS [Статус льготной категории],
    esrnStatusCategory.A_NAME               AS [Статус льготной категории в базе данных]  			
FROM WM_CATEGORY category --Льготная категория.
-----Статус в БД.
     INNER JOIN ESRN_SERV_STATUS esrnStatusCategory 
        ON esrnStatusCategory.A_ID = category.A_STATUS --Связка с льготной категорией.
----Статус льготной категории.
    INNER JOIN SPR_DOC_STATUS categoryStatus 
        ON categoryStatus.A_OUID = category.A_LCSTATUS --Связка с льготной категорией.
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = category.PERSONOUID --Связка с льготной категорией.      
----Отношение льготной категории к нормативно правовому документу.      
    INNER JOIN PPR_REL_NPD_CAT regulatoryDocument 
        ON regulatoryDocument.A_ID = category.A_NAME --Связка с льготной категорией. 
----Наименования льготных категорий.
    INNER JOIN PPR_CAT typeCategory 
        ON typeCategory.A_ID = regulatoryDocument.A_CAT --Связка с нормативно правовым документом.