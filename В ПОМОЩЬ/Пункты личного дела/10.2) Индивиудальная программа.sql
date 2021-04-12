SELECT
    personalCard.A_TITLE                        AS [Личное дело],
    organization.A_NAME1                        AS [Организация],
    CONVERT(DATE, individProgram.A_START_DATE)  AS [Дата оформления],
    CONVERT(DATE, individProgram.A_END_DATE)    AS [Дата пересмотра],
    individProgram.A_DEGREE                     AS [Степень зависимости в посторонней помощи],
    formSocServ.A_NAME                          AS [Форма социального обслуживания],
    individProgramStatus.A_NAME                 AS [Статус программы],
    typeDoc.A_NAME + ' №' 
        + currentDocument.DOCUMENTSNUMBER       AS [Документ],
    typeDocBefore.A_NAME + ' №' 
        + beforeDocument.DOCUMENTSNUMBER        AS [Предыдущая индивидуальная программа],
    typeServ.A_NAME                             AS [Созданные назначения по данной индивидуальной программе],
    esrnStatusIndividProgram.A_NAME             AS [Статус индивидуальной программы в базе данных]  
FROM INDIVID_PROGRAM individProgram --Индивидуальная программа.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusIndividProgram
        ON esrnStatusIndividProgram.A_ID = individProgram.A_STATUS 
----Статус индивидуальной программы.
    INNER JOIN SPR_STATUS_PROCESS individProgramStatus
        ON individProgramStatus.A_ID = individProgram.A_STATUSPRIVELEGE
----Организация.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = individProgram.A_OGR
----Форма социального обслуживания.
    INNER JOIN SPR_FORM_SOCSERV formSocServ
        ON formSocServ.A_OUID = individProgram.A_FORM_SOCSERV
----Документ текущей индивидуальной программы.
    INNER JOIN WM_ACTDOCUMENTS currentDocument
        ON currentDocument.OUID = individProgram.A_DOC
----Вид документа.
    INNER JOIN PPR_DOC typeDoc
        ON typeDoc.A_ID = currentDocument.DOCUMENTSTYPE
----Документ предыдущей индивидуальной программы
    LEFT JOIN WM_ACTDOCUMENTS beforeDocument
        ON beforeDocument.OUID = individProgram.A_PRE
----Вид документа.
    LEFT JOIN PPR_DOC typeDocBefore
        ON typeDocBefore.A_ID = beforeDocument.DOCUMENTSTYPE
----Назначение социального обслуживания.
    LEFT JOIN ESRN_SOC_SERV socServ 
        ON socServ.A_IPPSU = individProgram.A_OUID
----Нормативно правовой документ.
    LEFT JOIN SPR_NPD_MSP_CAT NPD
        ON NPD.A_ID = socServ.A_SERV 
----Наименование МСП.	
    LEFT JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = NPD.A_MSP 
----Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = individProgram.PERSONOUID