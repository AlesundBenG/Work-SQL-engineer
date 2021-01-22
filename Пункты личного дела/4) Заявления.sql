SELECT 
    CONVERT(DATE, appeal.A_DATE_REG)            AS [Дата регистрации],
    CASE petition.A_PETITION_TYPE --Нет таблицы с типами заявлений. Не порядок.
        WHEN 1 THEN 'На назначение'
        WHEN 2 THEN 'На возобновление выплат/продление'
        WHEN 3 THEN 'На перерасчет'
        ELSE CONVERT(VARCHAR, petition.A_PETITION_TYPE)
    END                                         AS [Тип заявления],
    typeServ.A_NAME                             AS [МСП/Социальное обслуживание],
    typeCategory.A_NAME                         AS [Льготная категория/Форма социального обслуживания],
    personalCardHolder.A_TITLE                  AS [Льготодержатель],
    personalCardChild.A_TITLE                   AS [Лицо, на основании данных ЛД которого запрашивается МСП/СО],
    petitonStatus.A_NAME                        AS [Статус заявления],
    CONVERT(DATE, petition.A_DONEDATE, 104)     AS [Дата подготовки решения],
    petition.A_DECISION_NUM                     AS [Номер решения],
    esrnUser.DESCRIPTION                        AS [Инспектор, подготовивший решение],
    organization.A_NAME1                        AS [Организация, в которую направлено обращение],
    esrnStatusPetition.A_NAME                   AS [Статус заявление в базе данных]
FROM WM_PETITION petition --Заявления.
----Статус заявления.
    INNER JOIN SPR_STATUS_PROCESS petitonStatus
        ON petitonStatus.A_ID = petition.A_STATUSPRIVELEGE --Связка с заявлением. 	
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID --Связка с заявлением.
-----Статус в БД.
     INNER JOIN ESRN_SERV_STATUS esrnStatusPetition
        ON esrnStatusPetition.A_ID = appeal.A_STATUS --Связка с обращением. 
----Личное дело заявителя.	         												
    INNER JOIN WM_PERSONAL_CARD personalCardHolder     
        ON personalCardHolder.OUID = petition.A_MSPHOLDER --Связка с заявлением.  
----Личное дело лица, на основании данных ЛД которого запрашивается МСП/СО.	      
    LEFT JOIN WM_PERSONAL_CARD personalCardChild
        ON personalCardChild.OUID = petition.A_CHILD --Связка с заявлением.          					
----МСП, на которое подано заявление.    														
    INNER JOIN PPR_SERV typeServ
        ON typeServ.A_ID = petition.A_MSP --Связка с заявлением. 	
----Наименования льготных категорий.    															
    LEFT JOIN PPR_CAT typeCategory
        ON typeCategory.A_ID = petition.A_CATEGORY --Связка с заявлением.       											
----Создатель заявления.												
    LEFT JOIN SXUSER esrnUser
        ON esrnUser.OUID = petition.A_REFUSEPERSON --Связка с заявлением.   
----Наименования организаций.	   															
    INNER JOIN SPR_ORG_BASE organization     
        ON organization.OUID = appeal.A_TO_ORG --Связка с обращением.   												