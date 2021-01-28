SELECT 
    orgBase.A_NAME1                         AS [Организация],
    personalCard.A_TITLE                    AS [Личное дело работника],
    CONVERT(DATE, workInfo.DATEOFEMP)       AS [Дата приема на работу],
    CONVERT(DATE, workInfo.DATEOFSACKING)   AS [Дата увольнения],
    qualifier.A_NAME                        AS [Должность],
    typeDoc.A_NAME                          AS [Подтверждающий документ],
    esrnStatusWorkInfo.A_NAME               AS [Статус информации о работе в базе данных]
FROM WM_WORKSINFO workInfo --Сведения о работе
-----Статус в БД.
     INNER JOIN ESRN_SERV_STATUS esrnStatusWorkInfo
        ON esrnStatusWorkInfo.A_ID = workInfo.A_STATUS --Связка с информацией о работе.
----Личное дело работника.
    INNER JOIN WM_PERSONAL_CARD personalCard --Личное дело гражданина.
        ON personalCard.OUID = workInfo.PERSONOUID --Связка с информацией о работе.
----Базовый класс организаций.
    LEFT JOIN SPR_ORG_BASE orgBase
        ON orgBase.OUID = workInfo.ORGANISATION --Связка с информацией о работе.  
----Должность.
    LEFT JOIN SPR_QUALIFIER qualifier
        ON qualifier.OUID = workInfo.A_POSITION --Связка с информацией о работе.
----Подтверждающий документ.
    LEFT JOIN WM_ACTDOCUMENTS actDocuments 
        ON actDocuments.OUID = workInfo.A_DOC --Связка с информацией о работе.
----Вид документа.
    LEFT JOIN PPR_DOC typeDoc
        ON typeDoc.A_ID = actDocuments.DOCUMENTSTYPE --Связка с документом.    