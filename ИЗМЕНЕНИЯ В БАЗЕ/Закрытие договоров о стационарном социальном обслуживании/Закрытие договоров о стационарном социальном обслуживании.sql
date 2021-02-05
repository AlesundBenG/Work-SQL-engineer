--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#UPDATED_DOC')        IS NOT NULL BEGIN DROP TABLE #UPDATED_DOC       END --Обновляемые документы.
IF OBJECT_ID('tempdb..#UPDATED_SOC_SERV')   IS NOT NULL BEGIN DROP TABLE #UPDATED_SOC_SERV  END --Обновляемые назначения на соц. обслуживание.
IF OBJECT_ID('tempdb..#UPDATE_LOG')         IS NOT NULL BEGIN DROP TABLE #UPDATE_LOG        END --Журнал старых значений.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
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


------------------------------------------------------------------------------------------------------------------------------


--Выборка документов.
INSERT INTO #UPDATED_DOC (DOC_OUID)
SELECT
    actDocuments.OUID AS DOC_OUID
FROM WM_ACTDOCUMENTS actDocuments                       --Действующие документы.
WHERE actDocuments.A_STATUS = 10                        --Статус в БД "Действует".
    AND actDocuments.A_DOCSTATUS = 1                    --Действующий документ.
    AND actDocuments.DOCUMENTSTYPE  = 2766              --Договор о стационарном социальном обслуживании.
    AND actDocuments.GIVEDOCUMENTORG = 474079           --Кировское областное государственное бюджетное учреждение социального обслуживания  «Климковский психоневрологический интернат».
    AND YEAR(actDocuments.ISSUEEXTENSIONSDATE) < 2021   --Год даты начала до 2021 (То бишь старое).
    AND actDocuments.COMPLETIONSACTIONDATE IS NULL      --Не закрыт.
    
    
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
WHERE socServ.A_STATUS = 10             --Статус в БД "Действует".
    AND period.A_STATUS = 10            --Статус в БД "Действует".
    AND condition.A_STATUS = 10         --Статус в БД "Действует".
    AND period.A_LASTDATE IS NULL       --Не закрыт.
    AND YEAR(period.STARTDATE) < 2021   --Год даты начала до 2021 (То бишь старое).
    AND socServ.A_ORGNAME = 474079      --Кировское областное государственное бюджетное учреждение социального обслуживания  «Климковский психоневрологический интернат». 
    AND socServ.A_STATUSPRIVELEGE = 13  --Статус "Утверждено".


------------------------------------------------------------------------------------------------------------------------------


--Начало транзакции.
BEGIN TRANSACTION

--Закрытие документов.
UPDATE actDocuments
SET actDocuments.TS = GETDATE(),                                        --Отмечаем время изменения.
    actDocuments.A_DOCSTATUS = 5,                                       --Меняем статус.
    actDocuments.A_EDITOWNER = 10314303,                                --Ставим пользователя, изменившего запись (Системный администратор).
    actDocuments.COMPLETIONSACTIONDATE = CONVERT(DATE, '31-12-2020')    --Ставим дату окончания.
OUTPUT inserted.OUID, deleted.TS, deleted.A_DOCSTATUS, deleted.A_EDITOWNER, deleted.COMPLETIONSACTIONDATE, 'actDocuments' INTO #UPDATE_LOG(OUID, TS, STATUS, EDITOR, STOP_DATE, MARK) --Сохранение.
FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
----Обновляемые документы.
    INNER JOIN #UPDATED_DOC updatedDoc
        ON updatedDoc.DOC_OUID = actDocuments.OUID --Связка с документом.
        
--Закрытие назначений.
UPDATE socServ
SET socServ.A_TS = GETDATE(),                           --Отмечаем время изменения.
    socServ.A_EDITOR = 10314303,                        --Ставим пользователя, изменившего запись (Системный администратор).
    socServ.A_STATUSPRIVELEGE = 2,                      --Меняем статус.
    socServ.A_STOPDATE = CONVERT(DATE, '31-12-2020')    --Ставим время постоянного прекращения.
OUTPUT inserted.OUID, deleted.A_TS, deleted.A_STATUSPRIVELEGE, deleted.A_EDITOR, deleted.A_STOPDATE, 'socServ' INTO #UPDATE_LOG(OUID, TS, STATUS, EDITOR, STOP_DATE, MARK) --Сохранение.
FROM ESRN_SOC_SERV socServ --Назначение социального обслуживания.
----Обновляемые назначения.
    INNER JOIN #UPDATED_SOC_SERV updatedSocServ
        ON updatedSocServ.SOC_SERV_OUID = socServ.OUID --Связка с назначением.

--Закрытие периода.
UPDATE period
SET period.A_TS = GETDATE(),                        --Отмечаем время изменения.
    period.A_EDITOR = 10314303,                     --Ставим пользователя, изменившего запись (Системный администратор).
    period.A_LASTDATE = CONVERT(DATE, '31-12-2020') --Ставим дату окончания.
OUTPUT inserted.A_OUID, deleted.A_TS, 13, deleted.A_EDITOR, deleted.A_LASTDATE, 'period' INTO #UPDATE_LOG(OUID, TS, STATUS, EDITOR, STOP_DATE, MARK) --Сохранение.
FROM SPR_SOCSERV_PERIOD period --Период действия назначения.
----Обновляемые назначения.
    INNER JOIN #UPDATED_SOC_SERV updatedSocServ
        ON updatedSocServ.PERIOD_OUID = period.A_OUID --Связка с периодом.
     
--Закрытие условия.
UPDATE condition
SET condition.A_TS = GETDATE(),                         --Отмечаем время изменения.
    condition.A_EDITOWNER = 10314303,                   --Ставим пользователя, изменившего запись (Системный администратор).
    condition.A_LASTDATE = CONVERT(DATE, '31-12-2020')  --Ставим дату окончания.
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