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
    esrnStatusDoc.A_NAME                                AS [Статус документа в базе данных]  
 FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
-----Статус в БД.
     INNER JOIN ESRN_SERV_STATUS esrnStatusDoc 
        ON esrnStatusDoc.A_ID = actDocuments.A_STATUS --Связка с документом.
----Статус документа.
    INNER JOIN SPR_DOC_STATUS docStatus
        ON docStatus.A_OUID = actDocuments.A_DOCSTATUS --Связка с документом.
----Вид документа.
    INNER JOIN PPR_DOC typeDoc
        ON typeDoc.A_ID = actDocuments.DOCUMENTSTYPE --Связка с документом.      
----Личное дело держателя документа.
    INNER JOIN WM_PERSONAL_CARD personalCard
        ON personalCard.OUID = actDocuments.PERSONOUID --Связка с документом.
----Базовый класс организаций, выдавшей документ.
    LEFT JOIN SPR_ORG_BASE orgBase
        ON orgBase.OUID = actDocuments.GIVEDOCUMENTORG --Связка с документом.    