SELECT 
    personalCard.A_TITLE                                                                                                        AS [Личное дело],
    socServ.A_DEGREE                                                                                                            AS [Степень зависимости в посторонней помощи],
        '"' + typeServ.A_NAME + '" ' + 
        'на основании ЛК ' + typeCategory.A_NAME + '" ' + 
        'и НПД "' + typeNPD.A_NAME + ' ' + sourseNPD.A_NAME + ' от ' + CONVERT(VARCHAR, articleNPD.A_NPD_DATE, 104) + ' г. ' +
        '№ ' + articleNPD.A_NPD_NUM + ' "' + articleNPD.A_NAME  + '""'                                                          AS [Назначенная помощь], 
    typeDoc.A_NAME + ' №' + actDocuments.DOCUMENTSNUMBER +' ' + CONVERT(VARCHAR, individProgram.A_START_DATE, 104) + ' ' + 
    formSocServ.A_NAME + ' ' + statusProgram.A_NAME                                                                             AS [Индивидуальная программа получателя социальных услуг],
    organization.A_NAME1                                                                                                        AS [Учреждение],
    departament.A_NAME1                                                                                                         AS [Подразделение],
    CONVERT(DATE, period.STARTDATE)                                                                                             AS [Дата начала периода предоставления МСП],
    CONVERT(DATE, period.A_LASTDATE)                                                                                            AS [Дата окончания периода предоставления МСП], 
    statusServ.A_NAME                                                                                                           AS [Статус назначения],
    esrnStatusServ.A_NAME                                                                                                       AS [Статус назначения в базе данных]
FROM ESRN_SOC_SERV socServ --Назначение социального обслуживания.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusServ
        ON esrnStatusServ.A_ID = socServ.A_STATUS --Связка с назначением.	
----Статус назначения.
    INNER JOIN SPR_STATUS_PROCESS statusServ 
        ON statusServ.A_ID = socServ.A_STATUSPRIVELEGE	--Связка с назначением.	
----Органы социальной защиты.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = socServ.A_ORGNAME --Связка с назначением.
----Департамент.
    INNER JOIN SPR_ORG_BASE departament
        ON departament.OUID = socServ.A_DEPNAME --Связка с назначением.     
----Период предоставления МСП.        
    INNER JOIN SPR_SOCSERV_PERIOD period
        ON period.A_STATUS = 10                 --Статус в БД "Действует".
            AND period.A_SERV = socServ.OUID    --Связка с назначением.   
----Нормативно правовой документ.
    INNER JOIN SPR_NPD_MSP_CAT NPD
        ON NPD.A_ID = socServ.A_SERV --Связка с назначением.
----Наименование МСП.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = NPD.A_MSP --Связка с нормативно правовым документом.
----Льготная категория.
    INNER JOIN PPR_CAT typeCategory
        ON typeCategory.A_ID = NPD.A_CATEGORY --Связка с нормативно правовым документом.
----Статья НПД.
    INNER JOIN PPR_NPD_ARTICLE articleNPD
        ON articleNPD.A_ID = NPD.A_DOC --Связка с нормативно правовым документом.
----НПД вид.
    INNER JOIN PPR_NPD_TYPE typeNPD
        ON typeNPD.A_ID = articleNPD.A_NPD_TYPE --Связка со статьей НПД.
----НПД источник.
    INNER JOIN PPR_NPD_SOURCE sourseNPD
        ON sourseNPD.A_ID = articleNPD.A_NPD_SOURCE --Связка со статьей НПД.   
----Индивидуальная программа.
    INNER JOIN INDIVID_PROGRAM individProgram
        ON individProgram.A_OUID = socServ.A_IPPSU --Связка с назначением.
----Форма социального обслуживания.
    INNER JOIN SPR_FORM_SOCSERV formSocServ
        ON formSocServ.A_OUID = individProgram.A_FORM_SOCSERV --Связка с индивидуальной программой.
----Статус индивидуальной программы.
    INNER JOIN SPR_STATUS_PROCESS statusProgram
        ON statusProgram.A_ID = individProgram.A_STATUSPRIVELEGE --Связка с индивидуальной программой.
----Действующие документы.
    INNER JOIN WM_ACTDOCUMENTS actDocuments
        ON actDocuments.OUID = individProgram.A_DOC --Связка с индивидуальной программой.
----Вид документа.
    INNER JOIN PPR_DOC typeDoc
        ON typeDoc.A_ID = actDocuments.DOCUMENTSTYPE --Связка с документом.    
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCard
        ON personalCard.OUID = socServ.A_PERSONOUID --Связка с назначением.	 