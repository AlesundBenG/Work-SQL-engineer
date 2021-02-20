-------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#DOC_TYPE')           IS NOT NULL BEGIN DROP TABLE #DOC_TYPE          END --Типы закрываемых документов.
IF OBJECT_ID('tempdb..#SERV_TYPE')          IS NOT NULL BEGIN DROP TABLE #SERV_TYPE         END --Типы закрываемых назначений.
IF OBJECT_ID('tempdb..#UPDATED_DOC')        IS NOT NULL BEGIN DROP TABLE #UPDATED_DOC       END --Обновляемые документы.
IF OBJECT_ID('tempdb..#UPDATED_SOC_SERV')   IS NOT NULL BEGIN DROP TABLE #UPDATED_SOC_SERV  END --Обновляемые назначения на соц. обслуживание.
IF OBJECT_ID('tempdb..#UPDATE_LOG')         IS NOT NULL BEGIN DROP TABLE #UPDATE_LOG        END --Журнал старых значений.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #DOC_TYPE (
    TYPE_DOC INT, --Идентификатор типа документа.
)
CREATE TABLE #SERV_TYPE (
    TYPE_SERV INT, --Идентификатор типа назначения..
)
CREATE TABLE #UPDATED_DOC (
    DOC_OUID INT, --Идентификатор документа.
)
CREATE TABLE #UPDATED_SOC_SERV (
    SOC_SERV_OUID   INT, --Идентификатор назначения.
    PERIOD_OUID     INT, --Идентификатор периода. 
    CONDITION_OUID  INT, --Идентификатор условия предоставления.
)
CREATE TABLE #UPDATE_LOG (
    OUID        INT,        --Идентификатор.
    TS          DATETIME,   --Время изменения.
    STATUS      INT,        --Статус.
    EDITOR      INT,        --Редактор.
    STOP_DATE   DATETIME,   --Время окончания.
    MARK        VARCHAR(50), --Метка (Докумнет, Назначение, Период, Условие).
)


--------------------------------------------------------------------------------------------------------------------------------


--Организация, относительно которой закрываются договоры.
DECLARE @organizationID INT
SET @organizationID = #organizationID#

--Дата окончания прошлого периода.
DECLARE @endDatePastPeriod DATE
SET @endDatePastPeriod = CONVERT(DATE, '31-12-2020')

--Дата изменения.
DECLARE @dateChange DATETIME
SET @dateChange = GETDATE()

--Автор изменения.
DECLARE @editor INT
SET @editor = 10314303 --Системный администратор.

--Выбранные типы документов.
INSERT INTO #DOC_TYPE(TYPE_DOC)
VALUES
    (2734),   --Договор о надомном социальном обслуживании.
    (2765),   --Договор о полустационарном социальном обслуживании.
    (2766)    --Договор о стационарном социальном обслуживании.

--Выбранные типы назначений.
INSERT INTO #SERV_TYPE(TYPE_SERV)
VALUES
    (827),  --Полустационарное социальное обслуживание.
    (806),  --Социальное обслуживание на дому.
    (953),  --Срочное социальное обслуживание
    (826)   --Стационарное социальное обслуживание.


--------------------------------------------------------------------------------------------------------------------------------


--Выборка документов.
INSERT INTO #UPDATED_DOC (DOC_OUID)
SELECT
    actDocuments.OUID AS DOC_OUID
FROM WM_ACTDOCUMENTS actDocuments                                                   --Действующие документы.
WHERE actDocuments.A_STATUS = 10                                                    --Статус в БД "Действует".
    AND actDocuments.A_DOCSTATUS = 1                                                --Действующий документ.
    AND (actDocuments.COMPLETIONSACTIONDATE IS NULL                                 --Не закрыт.
        OR CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE) >= @endDatePastPeriod  --Или дата окончания стоит в новом периоде.
    ) 
    AND CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE) <= @endDatePastPeriod       --Дата начала в старом периоде.
    AND actDocuments.GIVEDOCUMENTORG = @organizationID                              --Организация, относительно которой закрываются договоры.  
    AND actDocuments.DOCUMENTSTYPE IN (SELECT TYPE_DOC FROM #DOC_TYPE)              --Нужный тип документа.
    
    
------------------------------------------------------------------------------------------------------------------------------


--Выборка назначений.
INSERT INTO #UPDATED_SOC_SERV (SOC_SERV_OUID, PERIOD_OUID, CONDITION_OUID)
SELECT 
    socServ.OUID        AS SOC_SERV_OUID,
    period.A_OUID       AS PERIOD_OUID,
    condition.A_OUID    AS CONDITION_OUID
FROM ESRN_SOC_SERV socServ --Назначение социального обслуживания.
----Период предоставления МСП.        
    INNER JOIN SPR_SOCSERV_PERIOD period
        ON period.A_SERV = socServ.OUID --Связка с назначением.    
----Условие оказания социальных услуг за период.   
    INNER JOIN WM_COND_SOC_SERV condition
        ON condition.A_SOC_SERV = socServ.OUID --Связка с назначением.
----Нормативно правовой документ.
    INNER JOIN SPR_NPD_MSP_CAT NPD
        ON NPD.A_ID = socServ.A_SERV --Связка с назначением.
WHERE socServ.A_STATUS = 10                                             --Статус в БД "Действует".
    AND period.A_STATUS = 10                                            --Статус в БД "Действует".
    AND condition.A_STATUS = 10                                         --Статус в БД "Действует".
    AND (period.A_LASTDATE IS NULL                                      --Не закрыт период назначения.
        OR CONVERT(DATE, period.A_LASTDATE) >= @endDatePastPeriod       --Или дата окончания стоит в новом периоде.
    )
    AND (condition.A_LASTDATE IS NULL                                   --Не закрыто условие.
        OR CONVERT(DATE, condition.A_LASTDATE) >= @endDatePastPeriod    --Или дата окончания стоит в новом периоде.
    )
    AND CONVERT(DATE, period.STARTDATE) <= @endDatePastPeriod           --Дата начала назначения в прошлом периоде.
    AND CONVERT(DATE, condition.A_STARTDATE) <= @endDatePastPeriod      --Дата начала условия в прошлом периоде.
    AND socServ.A_ORGNAME = @organizationID                             --Организация, относительно которой закрываются договоры.       
    AND socServ.A_STATUSPRIVELEGE = 13                                  --Статус "Утверждено".
    AND NPD.A_MSP IN (SELECT TYPE_SERV FROM #SERV_TYPE)                 --Нужный тип назначения..


------------------------------------------------------------------------------------------------------------------------------


--Документы, которые будут закрыты.
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
----Изменяемые документы.  
    INNER JOIN #UPDATED_DOC updatedDoc
        ON updatedDoc.DOC_OUID = actDocuments.OUID --Связка с документом.


------------------------------------------------------------------------------------------------------------------------------


--Назначения, которые будут закрыты.
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
    esrnStatusServ.A_NAME                                                                                                       AS [Статус назначения в базе данных],
    condition.A_COND_SOC_SERV                                                                                                   AS [Условие оказания социальных услуг],
    CONVERT(DATE, condition.A_STARTDATE)                                                                                        AS [Дата начала условия],
    CONVERT(DATE, condition.A_LASTDATE)                                                                                         AS [Дата окончания условия]
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
----Изменяемые назначения.
    INNER JOIN #UPDATED_SOC_SERV updatedServ
        ON updatedServ.SOC_SERV_OUID = socServ.OUID     --Связка с назначением.
            AND updatedServ.PERIOD_OUID = period.A_OUID --Связка с периодом.
----Условие оказания социальных услуг за период.   
    INNER JOIN WM_COND_SOC_SERV condition
        ON condition.A_OUID = updatedServ.CONDITION_OUID --Связка с изменяемым назначением.

    
------------------------------------------------------------------------------------------------------------------------------


--Начало транзакции.
BEGIN TRANSACTION

--Закрытие документов.
UPDATE actDocuments
SET actDocuments.TS = @dateChange,                          --Отмечаем время изменения.
    actDocuments.A_DOCSTATUS = 5,                           --Меняем статус.
    actDocuments.A_EDITOWNER = @editor,                     --Ставим пользователя, изменившего запись.
    actDocuments.A_DOCBASEFINISHDATE = @endDatePastPeriod,  --Ставим дату окончания действия основания.
    actDocuments.COMPLETIONSACTIONDATE = @endDatePastPeriod --Ставим дату окончания.
OUTPUT inserted.OUID, deleted.TS, deleted.A_DOCSTATUS, deleted.A_EDITOWNER, deleted.COMPLETIONSACTIONDATE, 'actDocuments' INTO #UPDATE_LOG(OUID, TS, STATUS, EDITOR, STOP_DATE, MARK) --Сохранение.
FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
----Обновляемые документы.
    INNER JOIN #UPDATED_DOC updatedDoc
        ON updatedDoc.DOC_OUID = actDocuments.OUID --Связка с документом.
        
--Закрытие назначений.
UPDATE socServ
SET socServ.A_TS = @dateChange,             --Отмечаем время изменения.
    socServ.A_EDITOR = @editor,             --Ставим пользователя, изменившего запись.
    socServ.A_STATUSPRIVELEGE = 2,          --Меняем статус.
    socServ.A_STOPDATE = @endDatePastPeriod --Ставим время постоянного прекращения.
OUTPUT inserted.OUID, deleted.A_TS, deleted.A_STATUSPRIVELEGE, deleted.A_EDITOR, deleted.A_STOPDATE, 'socServ' INTO #UPDATE_LOG(OUID, TS, STATUS, EDITOR, STOP_DATE, MARK) --Сохранение.
FROM ESRN_SOC_SERV socServ --Назначение социального обслуживания.
----Обновляемые назначения.
    INNER JOIN #UPDATED_SOC_SERV updatedSocServ
        ON updatedSocServ.SOC_SERV_OUID = socServ.OUID --Связка с назначением.

--Закрытие периода.
UPDATE period
SET period.A_TS = @dateChange,              --Отмечаем время изменения.
    period.A_EDITOR = @editor,              --Ставим пользователя, изменившего запись.
    period.A_LASTDATE = @endDatePastPeriod  --Ставим дату окончания.
OUTPUT inserted.A_OUID, deleted.A_TS, 13, deleted.A_EDITOR, deleted.A_LASTDATE, 'period' INTO #UPDATE_LOG(OUID, TS, STATUS, EDITOR, STOP_DATE, MARK) --Сохранение.
FROM SPR_SOCSERV_PERIOD period --Период действия назначения.
----Обновляемые назначения.
    INNER JOIN #UPDATED_SOC_SERV updatedSocServ
        ON updatedSocServ.PERIOD_OUID = period.A_OUID --Связка с периодом.
     
--Закрытие условия.
UPDATE condition
SET condition.A_TS = @dateChange,               --Отмечаем время изменения.
    condition.A_EDITOWNER = @editor,            --Ставим пользователя, изменившего запись.
    condition.A_LASTDATE = @endDatePastPeriod   --Ставим дату окончания.
OUTPUT inserted.A_OUID, deleted.A_TS, 13, deleted.A_EDITOWNER, deleted.A_LASTDATE, 'condition' INTO #UPDATE_LOG(OUID, TS, STATUS, EDITOR, STOP_DATE, MARK) --Сохранение.
FROM WM_COND_SOC_SERV condition --Условие оказания социальных услуг за период.   
----Обновляемые назначения.
    INNER JOIN #UPDATED_SOC_SERV updatedSocServ
        ON updatedSocServ.CONDITION_OUID = condition.A_OUID --Связка с условием..  
   
--Конец транзакции.    
COMMIT


------------------------------------------------------------------------------------------------------------------------------


--Вывести старые значения.
SELECT * FROM #UPDATE_LOG


------------------------------------------------------------------------------------------------------------------------------