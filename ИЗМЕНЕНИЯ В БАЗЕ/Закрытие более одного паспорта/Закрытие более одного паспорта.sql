--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#ACTIVE_PASSPORT') IS NOT NULL BEGIN DROP TABLE #ACTIVE_PASSPORT END --Таблица действующий паспортов.
IF OBJECT_ID('tempdb..#CLOSED_PASSPORT') IS NOT NULL BEGIN DROP TABLE #CLOSED_PASSPORT END --Таблица закрытых паспортов.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #ACTIVE_PASSPORT(
    DOCUMENT_OUID       INT,    --Идентификатор документа.
    DOCUMENT_START_DATE DATE,   --Дата начала действия документа.
    PERSONOUID          INT,    --Идентификатор личного дела.
    NUMBER_INDEX        INT     --Порядковый номер, начиная от новых.
)
CREATE TABLE #CLOSED_PASSPORT(
    DOCUMENT_OUID           INT,    --Идентификатор документа.
    DOCUMENT_END_DATE_OLD   DATE,   --Старая дата окончания.
    STATUS_OLD              INT,    --Старый статус.
    EDITOWNER_OLD           INT,    --Старый редактор.
    TS_OLD                  DATE,   --Старая дата последнего редактирования.
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка документов.
INSERT INTO #ACTIVE_PASSPORT (DOCUMENT_OUID, DOCUMENT_START_DATE, PERSONOUID, NUMBER_INDEX)
SELECT
    actDocuments.OUID                   AS DOCUMENT_OUID,
    actDocuments.ISSUEEXTENSIONSDATE    AS DOCUMENT_START_DATE,
    personalCard.OUID                   AS PERSONOUID,
    ROW_NUMBER() OVER (PARTITION BY personalCard.OUID ORDER BY actDocuments.ISSUEEXTENSIONSDATE DESC) AS NUMBER_INDEX
FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
----Личное дело держателя документа.
    INNER JOIN WM_PERSONAL_CARD personalCard
        ON personalCard.OUID = actDocuments.PERSONOUID 
            AND personalCard.A_STATUS = 10 
WHERE actDocuments.A_STATUS = 10            --Статус в БД "Действует".
	AND actDocuments.A_DOCSTATUS = 1        --Действующий документ.
    AND actDocuments.DOCUMENTSTYPE = 2720   --Паспорт гражданина России.


------------------------------------------------------------------------------------------------------------------------------


--Проверка.
SELECT 
    passportForClose.DOCUMENT_OUID,
    passportForClose.DOCUMENT_START_DATE,
    passportForClose.PERSONOUID,
    DATEADD(DAY, -1, afterPassport.DOCUMENT_START_DATE) AS DOCUMENT_END_DATE,
    afterPassport.DOCUMENT_OUID,
    afterPassport.DOCUMENT_START_DATE,
    afterPassport.PERSONOUID
FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
----Паспорт для закрытия.
    INNER JOIN #ACTIVE_PASSPORT passportForClose 
        ON passportForClose.DOCUMENT_OUID = actDocuments.OUID
----Паспорт, который идет после паспорта, который закрываем.
    INNER JOIN #ACTIVE_PASSPORT afterPassport
        ON afterPassport.PERSONOUID = passportForClose.PERSONOUID
            AND afterPassport.NUMBER_INDEX = passportForClose.NUMBER_INDEX - 1
WHERE passportForClose.NUMBER_INDEX > 1 


------------------------------------------------------------------------------------------------------------------------------


--Закрытие старых паспортов.
UPDATE actDocuments
SET actDocuments.A_DOCSTATUS = 5,
    actDocuments.COMPLETIONSACTIONDATE = DATEADD(DAY, -1, afterPassport.DOCUMENT_START_DATE),
    actDocuments.A_EDITOWNER  = 10314303, 
    actDocuments.TS = GETDATE()
OUTPUT inserted.OUID, deleted.COMPLETIONSACTIONDATE, deleted.A_DOCSTATUS, deleted.A_EDITOWNER, deleted.TS INTO #CLOSED_PASSPORT(DOCUMENT_OUID, DOCUMENT_END_DATE_OLD, STATUS_OLD, EDITOWNER_OLD, TS_OLD)   --Сохранение во временную таблицу измененных документов.
FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
----Паспорт для закрытия.
    INNER JOIN #ACTIVE_PASSPORT passportForClose 
        ON passportForClose.DOCUMENT_OUID = actDocuments.OUID
----Паспорт, который идет после паспорта, который закрываем.
    INNER JOIN #ACTIVE_PASSPORT afterPassport
        ON afterPassport.PERSONOUID = passportForClose.PERSONOUID
            AND afterPassport.NUMBER_INDEX = passportForClose.NUMBER_INDEX - 1
WHERE passportForClose.NUMBER_INDEX > 1 


------------------------------------------------------------------------------------------------------------------------------


--Старые значения.
SELECT * FROM #CLOSED_PASSPORT


------------------------------------------------------------------------------------------------------------------------------

