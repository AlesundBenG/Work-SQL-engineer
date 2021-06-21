--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#PEOPLE_WHO_HAVE_MORE_ONE_IPRA')  IS NOT NULL BEGIN DROP TABLE #PEOPLE_WHO_HAVE_MORE_ONE_IPRA END --Люди, у которых есть более одной действующей ИПРА.
IF OBJECT_ID('tempdb..#IPRA_FOR_CLOSE')                 IS NOT NULL BEGIN DROP TABLE #IPRA_FOR_CLOSE                END --ИПРА для закрытия.
IF OBJECT_ID('tempdb..#REHABILITATION_FOR_CLOSE')       IS NOT NULL BEGIN DROP TABLE #REHABILITATION_FOR_CLOSE      END --Мероприятия социальной реабилитации для обработки.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #PEOPLE_WHO_HAVE_MORE_ONE_IPRA (
    PERSONOUID INT, --Идентификатор личного дела.
)
CREATE TABLE #IPRA_FOR_CLOSE (
    IPRA_OUID       INT,    --Идентификатор ИПРА.
    DOCUMENT_OUID   INT,    --Идентификатор документа ИПРА.
    PERSONOUID      INT,    --Идентификатор личного дела.
    START_DATE      DATE,   --Дата начала.
    END_DATE        DATE,   --Дата окончания.
    IPRA_INDEX      INT     --Порядковый номер в списке.
)
CREATE TABLE #REHABILITATION_FOR_CLOSE (
    REHABILITATION_OUID INT,    --Идентификатор мероприятия социальной реабилитации.
    IPRA_OUID           INT,    --Идентификатор ИПРА.
    PERSONOUID          INT,    --Идентификатор личного дела.
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка людей, которые имеют более одной действующей ИПРА.
INSERT #PEOPLE_WHO_HAVE_MORE_ONE_IPRA (PERSONOUID)
SELECT 
    w.PERSONOUID AS PERSONOUID
FROM (
    SELECT DISTINCT
        COUNT (DISTINCT actDocuments.OUID)  AS COUNT_IPRA,
        personalCard.OUID                   AS PERSONOUID
    FROM WM_REH_REFERENCE rehabilitation --Реабилитационные мероприятия по заболеванию.
    ----Личное дело гражданина.
        INNER JOIN WM_PERSONAL_CARD personalCard  
            ON personalCard.OUID = rehabilitation.A_PERSONOUID
                AND personalCard.A_STATUS = 10    --Статус в БД "Действует".
                AND personalCard.A_PCSTATUS = 1   --Действующее личное дело.
    ----Действующие документы.      
        INNER JOIN WM_ACTDOCUMENTS actDocuments  
            ON actDocuments.OUID = rehabilitation.A_IPR
                AND actDocuments.A_STATUS = 10          --Статус в БД "Действует".
                AND actDocuments.A_DOCSTATUS = 1        --Действующий документ.
	            AND actDocuments.DOCUMENTSTYPE = 2322   --Индивидуальная программа реабилитации и абилитации.
    WHERE rehabilitation.A_STATUS = 10 --Статус в БД "Действует".
        AND (rehabilitation.A_IDMSE IS NOT NULL         --Из витрины.
            OR rehabilitation.A_FGISFRI_DOC IS NOT NULL --Или из ФГИС ФРИ.
        )
    GROUP BY personalCard.OUID
) w
WHERE w.COUNT_IPRA > 1 --Более одной ИПРА.
;


--------------------------------------------------------------------------------------------------------------------------------


--Оставляем только тех, у кого нет социального обслуживание за любое время, кроме  надомного.
DELETE FROM #PEOPLE_WHO_HAVE_MORE_ONE_IPRA 
WHERE PERSONOUID IN (
    SELECT 
        socServ.A_PERSONOUID
    FROM ESRN_SOC_SERV socServ --Назначение социального обслуживания.
        LEFT JOIN SPR_NPD_MSP_CAT NPD
            ON NPD.A_ID = socServ.A_SERV
                AND NPD.A_STATUS = 10
    WHERE ISNULL(NPD.A_MSP, 806) <> 806
        AND socServ.A_STATUS = 10
)
;


--------------------------------------------------------------------------------------------------------------------------------


--Отбор ИПРА.
INSERT INTO #IPRA_FOR_CLOSE (IPRA_OUID, DOCUMENT_OUID, PERSONOUID, START_DATE, END_DATE, IPRA_INDEX) 
SELECT
    rehabilitation.OUID                         AS IPRA_OUID,
    actDocuments.OUID                           AS DOCUMENT_OUID,
    whoHaveMore.PERSONOUID                      AS PERSONOUID,
    CONVERT(DATE, rehabilitation.A_DATE_START)  AS START_DATE,
    CAST(NULL AS DATE)                          AS END_DATE, 
    ROW_NUMBER() OVER (PARTITION BY whoHaveMore.PERSONOUID order by rehabilitation.A_DATE_START DESC) AS IPRA_INDEX
FROM WM_REH_REFERENCE rehabilitation --Реабилитационные мероприятия по заболеванию.
----Люди, которые имеют более одной ИПРа.
    INNER JOIN #PEOPLE_WHO_HAVE_MORE_ONE_IPRA whoHaveMore  
        ON whoHaveMore.PERSONOUID = rehabilitation.A_PERSONOUID
----Действующие документы.      
    INNER JOIN WM_ACTDOCUMENTS actDocuments  
        ON actDocuments.OUID = rehabilitation.A_IPR
            AND actDocuments.A_STATUS = 10          --Статус в БД "Действует".
            AND actDocuments.A_DOCSTATUS = 1        --Действующий документ.
            AND actDocuments.DOCUMENTSTYPE = 2322   --Индивидуальная программа реабилитации и абилитации.
WHERE rehabilitation.A_STATUS = 10 --Статус в БД "Действует".
    AND (rehabilitation.A_IDMSE IS NOT NULL         --Из витрины.
        OR rehabilitation.A_FGISFRI_DOC IS NOT NULL --Или из ФГИС ФРИ.
    )

--Утановка даты окончания не последних ИПРА, которая равная дате с вычитом одного дня от начала ИПРА идущей после данной.
UPDATE forClose
SET forClose.END_DATE = (SELECT DATEADD(DAY, -1, START_DATE) FROM #IPRA_FOR_CLOSE before WHERE before.IPRA_INDEX = forClose.IPRA_INDEX - 1 AND before.PERSONOUID = forClose.PERSONOUID)
FROM #IPRA_FOR_CLOSE forClose

--Оставляем те, которые будем закрывать.
DELETE FROM #IPRA_FOR_CLOSE
WHERE END_DATE IS NULL


--------------------------------------------------------------------------------------------------------------------------------


--Мероприятия социальной реабилитации для обработки.
INSERT INTO #REHABILITATION_FOR_CLOSE (REHABILITATION_OUID, IPRA_OUID, PERSONOUID)
SELECT 
    rehabilitation.A_OUID   AS REHABILITATION_OUID,
    forClose.IPRA_OUID      AS IPRA_OUID,
    forClose.PERSONOUID     AS PERSONOUID
FROM WM_SOCIAL_REHABILITATION rehabilitation --Мероприятие социальной реабилитации.
----ИПРА для закрытия.
    INNER JOIN #IPRA_FOR_CLOSE forClose 
        ON rehabilitation.A_REHAB_REF = forClose.IPRA_OUID
WHERE rehabilitation.A_STATUS = 10  --Статус в БД "Действует".
    AND rehabilitation.A_STATUS_EVENT_IPRA = 1 --Статус "Сформировано".


--------------------------------------------------------------------------------------------------------------------------------


--Обработка социальной реабилитации.
UPDATE rehabilitation
SET rehabilitation.A_ORG = rehabilitation.A_REC_ORG, 
    rehabilitation.A_STATUS_EVENT_IPRA = 3, --На выгрузку в витрину МСЭ
    rehabilitation.A_REASON_FAILURE = CASE WHEN A_RHB_TYPE = 17 THEN 4 ELSE 3 END, 
    rehabilitation.A_REASON = CASE WHEN A_RHB_TYPE = 17 THEN 'Выполнение мероприятий по социально-средовой реабилитации не входит в компетенцию министерства соц. развития Кировской области' ELSE NULL END,
    rehabilitation.A_NOTE =  'Органами МСЭ взамен настоящей ИПРА выдана новая',
    rehabilitation.A_TS = GETDATE(),
    rehabilitation.A_EDITOR = #curAccount#
    --rehabilitation.A_EDITOR = 10314303
FROM WM_SOCIAL_REHABILITATION rehabilitation
	 INNER JOIN #REHABILITATION_FOR_CLOSE forClose
	    ON forClose.REHABILITATION_OUID = rehabilitation.A_OUID
	 
--Закрытие ИПРА.
UPDATE actDocuments
SET actDocuments.A_DOCSTATUS = 5,
    actDocuments.COMPLETIONSACTIONDATE = forClose.END_DATE, 
    actDocuments.TS = GETDATE(), 
    actDocuments.A_EDITOWNER = #curAccount#
    --actDocuments.A_EDITOWNER = 10314303
FROM WM_ACTDOCUMENTS actDocuments
    INNER JOIN #IPRA_FOR_CLOSE forClose
        ON forClose.DOCUMENT_OUID = actDocuments.OUID
WHERE actDocuments.OUID IN (
    SELECT 
        forClose.DOCUMENT_OUID
    FROM WM_SOCIAL_REHABILITATION rehabilitation --Мероприятие социальной реабилитации.
    ----ИПРА для закрытия.
        INNER JOIN #IPRA_FOR_CLOSE forClose 
            ON rehabilitation.A_REHAB_REF = forClose.IPRA_OUID
    WHERE rehabilitation.A_STATUS = 10 --Статус в БД "Действует".
    GROUP BY forClose.PERSONOUID, forClose.IPRA_OUID, forClose.DOCUMENT_OUID, forClose.START_DATE, forClose.END_DATE
    HAVING MAX(CASE WHEN rehabilitation.A_STATUS_EVENT_IPRA = 1 THEN 1 ELSE 0 END) = 1                      --Есть сформированные мероприятия.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 4) = 4 THEN 1 ELSE 0 END)    --Либо все выгружены в витрину.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 3) = 3 THEN 1 ELSE 0 END)    --Либо все на выгрузку в витрину.
)


--------------------------------------------------------------------------------------------------------------------------------


--Для отчета.
SELECT 
    pc.A_TITLE, 
    doc.DOCUMENTSNUMBER, 
    CONVERT(DATE, r.A_DATE_START) AS A_DATE_START, 
    CONVERT(DATE, r.A_DATE_END) AS A_DATE_END
FROM WM_ACTDOCUMENTS actDocuments
    INNER JOIN #IPRA_FOR_CLOSE forClose
        ON forClose.DOCUMENT_OUID = actDocuments.OUID  
    INNER JOIN WM_PERSONAL_CARD pc 
        ON pc.OUID = forClose.PERSONOUID
    INNER JOIN WM_REH_REFERENCE r 
        ON r.OUID = forClose.IPRA_OUID
    INNER JOIN WM_ACTDOCUMENTS doc 
        ON doc.OUID = forClose.DOCUMENT_OUID
WHERE actDocuments.OUID IN (
    SELECT 
        forClose.DOCUMENT_OUID
    FROM WM_SOCIAL_REHABILITATION rehabilitation --Мероприятие социальной реабилитации.
    ----ИПРА для закрытия.
        INNER JOIN #IPRA_FOR_CLOSE forClose 
            ON rehabilitation.A_REHAB_REF = forClose.IPRA_OUID
    WHERE rehabilitation.A_STATUS = 10 --Статус в БД "Действует".
    GROUP BY forClose.PERSONOUID, forClose.IPRA_OUID, forClose.DOCUMENT_OUID, forClose.START_DATE, forClose.END_DATE
    HAVING MAX(CASE WHEN rehabilitation.A_STATUS_EVENT_IPRA = 1 THEN 1 ELSE 0 END) = 1                      --Есть сформированные мероприятия.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 4) = 4 THEN 1 ELSE 0 END)   --Либо все выгружены в витрину.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 3) = 3 THEN 1 ELSE 0 END)   --Либо все на выгрузку в витрину.
)
order by 1


