--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#ALL_IPRA_FROM_BASE')             IS NOT NULL BEGIN DROP TABLE #ALL_IPRA_FROM_BASE            END --Информация о всех ИПРА.
IF OBJECT_ID('tempdb..#PEOPLE_WHO_HAVE_MORE_ONE_IPRA')  IS NOT NULL BEGIN DROP TABLE #PEOPLE_WHO_HAVE_MORE_ONE_IPRA END --Люди, у которых есть более одной действующей ИПРА.
IF OBJECT_ID('tempdb..#IPRA_FOR_CLOSE')                 IS NOT NULL BEGIN DROP TABLE #IPRA_FOR_CLOSE                END --ИПРА для закрытия.
IF OBJECT_ID('tempdb..#REHABILITATION_FOR_CLOSE')       IS NOT NULL BEGIN DROP TABLE #REHABILITATION_FOR_CLOSE      END --Мероприятия социальной реабилитации для обработки.



--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #ALL_IPRA_FROM_BASE (
    IPRA_OUID                   INT,    --Идентификатор ИПРА.
    DOCUMENT_OUID               INT,    --Идентификатор документа ИПРА.
    DOCUMENT_STATUS             INT,    --Статус ИПРА.
    PERSONOUID                  INT,    --Идентификатор личного дела.
    REHABILITATION_START_DATE   DATE,   --Дата начала ИПРА.
    REHABILITATION_END_DATE     DATE,   --Дата окончания ИПРА.
    MSE                         INT,    --Из витрины.
    FGISFRI                     INT,    --Из ФГИС ФРИ.
    SOC_SERV_IN_THAT_PERIOD     INT,    --Наличие СО, с которым пересекаются периоды.
    IPRA_INDEX                  INT,    --Порядковый номер ИПРА, от новых к старым.
)
CREATE TABLE #PEOPLE_WHO_HAVE_MORE_ONE_IPRA (
    PERSONOUID INT, --Идентификатор личного дела.
)
CREATE TABLE #IPRA_FOR_CLOSE (
    IPRA_OUID       INT,    --Идентификатор ИПРА.
    DOCUMENT_OUID   INT,    --Идентификатор документа ИПРА.
    PERSONOUID      INT,    --Идентификатор личного дела.
    START_DATE      DATE,   --Дата начала.
    NEW_END_DATE    DATE,   --Новая дата окончания.
)
CREATE TABLE #REHABILITATION_FOR_CLOSE (
    REHABILITATION_OUID INT,    --Идентификатор мероприятия социальной реабилитации.
    IPRA_OUID           INT,    --Идентификатор ИПРА.
    PERSONOUID          INT,    --Идентификатор личного дела.
)


--------------------------------------------------------------------------------------------------------------------------------


--Выборка информации о всех ИПРА.
INSERT INTO #ALL_IPRA_FROM_BASE (IPRA_OUID, DOCUMENT_OUID, DOCUMENT_STATUS, PERSONOUID, REHABILITATION_START_DATE, REHABILITATION_END_DATE, MSE, FGISFRI, SOC_SERV_IN_THAT_PERIOD, IPRA_INDEX)
SELECT DISTINCT
    rehabilitation.OUID                         AS IPRA_OUID,
    actDocuments.OUID                           AS DOCUMENT_OUID,
    actDocuments.A_DOCSTATUS                    AS DOCUMENT_STATUS,
    personalCard.OUID                           AS PERSONOUID,
    CONVERT(DATE, rehabilitation.A_DATE_START)  AS REHABILITATION_START_DATE,
    CONVERT(DATE, rehabilitation.A_DATE_END)    AS REHABILITATION_END_DATE, 
    CASE WHEN rehabilitation.A_IDMSE IS NOT NULL THEN 1 ELSE 0 END          AS MSE,
    CASE WHEN rehabilitation.A_FGISFRI_DOC IS NOT NULL THEN 1 ELSE 0 END    AS FGISFRI,
    CASE WHEN Serv.OUID IS NOT NULL THEN 1 ELSE 0 END                       AS SOC_SERV_IN_THAT_PERIOD,
    ROW_NUMBER() OVER (PARTITION BY personalCard.OUID order by rehabilitation.A_DATE_START DESC) AS IPRA_INDEX
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
            AND actDocuments.DOCUMENTSTYPE = 2322   --Индивидуальная программа реабилитации и абилитации.
---Социальное обслуживание
	LEFT JOIN (
        SELECT socServ.OUID,socServ.A_PERSONOUID,SocPer.STARTDATE,SocPer.A_LASTDATE
        FROM ESRN_SOC_SERV socServ
            INNER JOIN SPR_SOCSERV_PERIOD SocPer
                ON SocPer.A_SERV=socServ.OUID
                    AND SocPer.A_STATUS=10
        WHERE socServ.A_STATUS=10
    ) Serv
        ON Serv.A_PERSONOUID = personalCard.OUID
		    AND CONVERT(DATE,ISNULL(rehabilitation.A_DATE_START,'1900-01-01')) <= CONVERT(DATE,ISNULL(Serv.A_LASTDATE,'2500-01-01')) 
		    AND CONVERT(DATE,ISNULL(Serv.STARTDATE,'1900-01-01')) <= CONVERT(DATE,ISNULL(rehabilitation.A_DATE_END,'2500-01-01'))
WHERE rehabilitation.A_STATUS = 10 --Статус в БД "Действует".


------------------------------------------------------------------------------------------------------------------------------


--Выборка людей, которые имеют более одной действующей ИПРА.
INSERT #PEOPLE_WHO_HAVE_MORE_ONE_IPRA (PERSONOUID)
SELECT 
    w.PERSONOUID AS PERSONOUID
FROM (
    SELECT DISTINCT
        COUNT (DISTINCT fromBaseIPRA.DOCUMENT_OUID)    AS COUNT_IPRA,
        fromBaseIPRA.PERSONOUID                     AS PERSONOUID
    FROM #ALL_IPRA_FROM_BASE fromBaseIPRA
    WHERE fromBaseIPRA.DOCUMENT_STATUS = 1  --Действующий документ.
        AND (fromBaseIPRA.MSE = 1           --Из витрины или...
            OR fromBaseIPRA.FGISFRI = 1     --...или из ФГИС ФРИ.
        )
    GROUP BY fromBaseIPRA.PERSONOUID
) w
WHERE w.COUNT_IPRA > 1 --Более одной действующей ИПРА.
;


--------------------------------------------------------------------------------------------------------------------------------


--Отбор ИПРА для закрытия.
INSERT INTO #IPRA_FOR_CLOSE (IPRA_OUID, DOCUMENT_OUID, PERSONOUID, START_DATE, NEW_END_DATE)     
SELECT
    fromBaseIPRA.IPRA_OUID                  AS IPRA_OUID,
    fromBaseIPRA.DOCUMENT_OUID              AS DOCUMENT_OUID,
    fromBaseIPRA.PERSONOUID                 AS PERSONOUID,
    fromBaseIPRA.REHABILITATION_START_DATE  AS START_DATE,
    (SELECT DATEADD(DAY, -1, REHABILITATION_START_DATE) 
        FROM #ALL_IPRA_FROM_BASE before 
        WHERE before.IPRA_INDEX = fromBaseIPRA.IPRA_INDEX - 1 
            AND before.PERSONOUID = fromBaseIPRA.PERSONOUID
    ) AS NEW_END_DATE
FROM #ALL_IPRA_FROM_BASE fromBaseIPRA
----Люди, которые имеют более одной ИПРа.
    INNER JOIN #PEOPLE_WHO_HAVE_MORE_ONE_IPRA whoHaveMore  
        ON whoHaveMore.PERSONOUID = fromBaseIPRA.PERSONOUID
WHERE fromBaseIPRA.DOCUMENT_STATUS = 1              --Действующий документ.
    AND fromBaseIPRA.SOC_SERV_IN_THAT_PERIOD = 0    --Нет пересекающихся СО.
    AND fromBaseIPRA.IPRA_INDEX <> 1                --Не последняя ИПРА.
    AND (fromBaseIPRA.MSE = 1                       --Из витрины или...
        OR fromBaseIPRA.FGISFRI = 1                 --...или из ФГИС ФРИ.
    )
  
    
--------------------------------------------------------------------------------------------------------------------------------


--Формирование мероприятий для отправки в витрину, если они еще не сформированы.
INSERT INTO WM_SOCIAL_REHABILITATION (A_GUID, A_CROWNER, A_TS, A_STATUS, A_STATUS_EVENT_IPRA,/*A_EDITOR*/A_CREATEDATE, A_DATE_START, A_DATE_END, A_REHAB_REF, A_NEED, A_RHB_TYPE, A_RHB_EVNT)
SELECT 
    NEWID()                     AS A_GUID,					---Глобальный идентификатор
    10314303                    AS A_CROWNER,               ---Автор
    GETDATE()                   AS A_TS,					---Дата модификации
    10                          AS A_STATUS,				---Статус в БД
    1                           AS A_STATUS_EVENT_IPRA,		---Статус мероприятия ИПРА
    GETDATE()                   AS A_CREATEDATE,			---Дата создания
    Docs.ISSUEEXTENSIONSDATE    AS A_DATE_START,			---Дата начала
    Docs.COMPLETIONSACTIONDATE  AS A_DATE_END,				---Дата окончания
    Ipra.OUID                   AS A_REHAB_REF,				---Реабилитационные мероприятия
    1                           AS A_NEED,					---Нуждается
    Reh.A_RHB_TYPE              AS A_RHB_TYPE,				---Тип мероприятия
    SubTypeReh.A_OUID           AS A_RHB_EVNT				---Подтип мероприятия
FROM WM_REH_REFERENCE Ipra --Реабилитационные мероприятия по заболеванию
----Действующие документы
    INNER JOIN WM_ACTDOCUMENTS Doc
        ON Ipra.A_IPR = Doc.OUID 
            AND Doc.A_STATUS = 10 --Документ не удален из БД
----Рекомендованные мероприятия
	INNER JOIN WM_SOCIAL_REHABILITATION Reh
        ON Reh.A_REHAB_REF = Ipra.OUID       
            and Reh.A_STATUS = 10               --Статус в БД - действует
            AND Reh.A_STATUS_EVENT_IPRA is NULL --Нет статуса мероприятия
            AND Reh.A_RHB_EVNT is NULL          --Не указан подтип мероприятия
----Подтипы мероприятий из справочника ЕСРН
		LEFT JOIN SPR_subTYPE_SOC_REHUB SubTypeReh
			ON SubTypeReh.a_type_of_event = Reh.A_RHB_TYPE
			    AND SubTypeReh.a_type_of_event IN (20, 21, 18, 17)
----Рекомендованные мероприятия, которые уже имеются.    
    LEFT JOIN WM_SOCIAL_REHABILITATION Reh2
        ON Reh2.A_REHAB_REF = Ipra.OUID 
            AND Reh2.A_STATUS = 10
            AND Reh2.A_RHB_TYPE = Reh.A_RHB_TYPE
            AND Reh2.A_RHB_EVNT = SubTypeReh.A_OUID
----Документ ИПРА.
    INNER JOIN WM_ACTDOCUMENTS Docs
        ON Ipra.A_IPR = Docs.ouid
WHERE Ipra.A_STATUS = 10 ---ИПРА не удалена из БД
    AND Ipra.OUID IN (SELECT IPRA_OUID FROM #IPRA_FOR_CLOSE) --Вставляем в те, которые собираемся закрывать.
    AND Reh2.A_OUID IS NULL --Мероприятие, которое мы хотим добавить, отсутствует.


--------------------------------------------------------------------------------------------------------------------------------


--Мероприятия социальной реабилитации для обработки.
INSERT INTO #REHABILITATION_FOR_CLOSE (REHABILITATION_OUID, IPRA_OUID)
SELECT 
    rehabilitation.A_OUID   AS REHABILITATION_OUID,
    forClose.IPRA_OUID      AS IPRA_OUID
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
    --rehabilitation.A_EDITOR = #curAccount#
    rehabilitation.A_EDITOR = 10314303
FROM WM_SOCIAL_REHABILITATION rehabilitation
	 INNER JOIN #REHABILITATION_FOR_CLOSE forClose
	    ON forClose.REHABILITATION_OUID = rehabilitation.A_OUID
	 
--Закрытие ИПРА.
UPDATE actDocuments
SET actDocuments.A_DOCSTATUS = 5,
    actDocuments.COMPLETIONSACTIONDATE = forClose.NEW_END_DATE, 
    actDocuments.TS = GETDATE(), 
    --actDocuments.A_EDITOWNER = #curAccount#
    actDocuments.A_EDITOWNER = 10314303
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
    GROUP BY forClose.PERSONOUID, forClose.IPRA_OUID, forClose.DOCUMENT_OUID, forClose.START_DATE, forClose.NEW_END_DATE
    HAVING MAX(CASE WHEN rehabilitation.A_STATUS_EVENT_IPRA = 1 THEN 1 ELSE 0 END) = 1          --Есть сформированные мероприятия.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 4) = 4 THEN 1 ELSE 0 END)   --Либо все выгружены в витрину.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 3) = 3 THEN 1 ELSE 0 END)   --Либо все на выгрузку в витрину.
)

--Фиксация изменений.
INSERT INTO TEMPORARY_TABLE(VARCHAR_1, VARCHAR_2, VARCHAR_3, VARCHAR_4, VARCHAR_5, VARCHAR_6, VARCHAR_7, VARCHAR_8, VARCHAR_10)
SELECT
    'Дата выполнения:'              AS VARCHAR_1,
    GETDATE()                       AS VARCHAR_2,
    'Идентификатор ИПРА:'           AS VARCHAR_3,
    forClose.IPRA_OUID              AS VARCHAR_4,
    'Идентификатор документа ИПРА:' AS VARCHAR_5,
    forClose.DOCUMENT_OUID          AS VARCHAR_6,
    'Идентификатор личного дела:'   AS VARCHAR_7,
    forClose.PERSONOUID             AS VARCHAR_8,
    'Закрытие двойных ИПРА'         AS VARCHAR_10
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
    GROUP BY forClose.PERSONOUID, forClose.IPRA_OUID, forClose.DOCUMENT_OUID, forClose.START_DATE, forClose.NEW_END_DATE
    HAVING MAX(CASE WHEN rehabilitation.A_STATUS_EVENT_IPRA = 1 THEN 1 ELSE 0 END) = 1          --Есть сформированные мероприятия.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 4) = 4 THEN 1 ELSE 0 END)   --Либо все выгружены в витрину.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 3) = 3 THEN 1 ELSE 0 END)   --Либо все на выгрузку в витрину.
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
    GROUP BY forClose.PERSONOUID, forClose.IPRA_OUID, forClose.DOCUMENT_OUID, forClose.START_DATE, forClose.NEW_END_DATE
    HAVING MAX(CASE WHEN rehabilitation.A_STATUS_EVENT_IPRA = 1 THEN 1 ELSE 0 END) = 1                      --Есть сформированные мероприятия.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 4) = 4 THEN 1 ELSE 0 END)   --Либо все выгружены в витрину.
        OR COUNT(*) = SUM(CASE WHEN ISNULL(rehabilitation.A_STATUS_EVENT_IPRA, 3) = 3 THEN 1 ELSE 0 END)   --Либо все на выгрузку в витрину.
)
order by 1