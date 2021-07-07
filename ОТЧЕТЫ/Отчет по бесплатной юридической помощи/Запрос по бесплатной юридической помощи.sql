------------------------------------------------------------------------------------------------------------------------------

--Начало периода отчета.
DECLARE @startDateReport DATE
SET @startDateReport = CONVERT(DATE, #startDateReport#)

--Конец периода отчета.
DECLARE @endDateReport DATE
SET @endDateReport = CONVERT(DATE, #endDateReport#)


--------------------------------------------------------------------------------------------------------------------------------


--Малоимущие граждане.
DECLARE @poorCitizens INT
SET @poorCitizens = (
    SELECT
        COUNT(*)
    FROM (
        SELECT DISTINCT 
            servServ.A_PERSONOUID
        FROM ESRN_SERV_SERV servServ --Назначения МСП.
        ----Период предоставления МСП.
            INNER JOIN SPR_SERV_PERIOD period 
                ON period.A_SERV = servServ.OUID
                    AND period.A_STATUS = 10 --Статус в БД "Действует".
                    AND CONVERT(DATE, period.STARTDATE) <= @endDateReport --Начало не выходит за окончание периода.
                    AND CONVERT(DATE, ISNULL(period.A_LASTDATE, '29991231')) >= @startDateReport --Конец выходит за начало периода.
        ----Личное дело льготодержателя.
            INNER JOIN WM_PERSONAL_CARD personalCardHolder 
                ON personalCardHolder.OUID = servServ.A_PERSONOUID
                    AND personalCardHolder.A_STATUS = 10 --Статус в БД "Действует".
        	        AND (personalCardHolder.A_DEATHDATE IS NULL
                        OR CONVERT(DATE, personalCardHolder.A_DEATHDATE) >= @startDateReport
                    )
        WHERE servServ.A_STATUS = 10                    --Статус в БД "Действует".
            AND servServ.A_STATUSPRIVELEGE IN (2, 13)   --Постоянное прекращение или утверждено.
            AND servServ.A_SERV IN (
            ----Ежемесячное пособие на ребенка 
                2012,   --Родитель (усыновитель, опекун, попечитель) совместно проживающего с ним ребенка
                2010,   --Одинокая мать 
            ----Ежемесячная денежная выплата по уходу за третьим и последующими детьми 
                2014,   --Родитель (усыновитель) третьего ребенка или последующих детей 
            ----Ежемесячная социальная выплата на детей из многодетных малообеспеченных семей 
                2017,   --Многодетная малообеспеченная семья
            ----Ежемесячная социальная выплата на детей из многодетных малообеспеченных семей 
                2011,   --Многодетная малообеспеченная семья 
            ----Ежемесячная социальная выплата по уходу за вторым ребенком в возрасте от полутора до трех лет, не посещающим дошкольную образовательную организацию 
                2318,   --Родитель либо лицо, его заменяющее
            ----Социальное пособие на оказание ГСП на основании социального контракта 
                1909,   --Малоимущая семья 
            ----Субсидия на оплату жилого помещения и коммунальных услуг 
                205     --Граждане, расходы которых на оплату жилого помещения и коммунальных услуг превышают величину, соответствующую максимально допустимой доле расходов граждан на оплату жилого помещения и коммунальных услуг в совокупном доходе семьи 
            )
    ) t
)


--------------------------------------------------------------------------------------------------------------------------------


--Ветераны ВОВ и герои.
DECLARE @veteransAndHeroes INT
SET @veteransAndHeroes = (
    SELECT
        COUNT(*)
    FROM (
        /*Ветераны ВОВ*/
        SELECT DISTINCT 
            category.PERSONOUID
        FROM WM_CATEGORY category --Льготная категория.
        ----Личное дело льготодержателя.
            INNER JOIN WM_PERSONAL_CARD personalCard 
                ON personalCard.OUID = category.PERSONOUID 
                    AND personalCard.A_STATUS = 10                                      --Статус в БД "Действует".
                    AND (personalCard.A_DEATHDATE IS NULL                               --Нет даты смерти...
                        OR CONVERT(DATE, personalCard.A_DEATHDATE) >= @startDateReport  --...либо она позде даты начала.
                    )
        ----Отношение ЛК к НПД.
            INNER JOIN PPR_REL_NPD_CAT NPD 
	            ON NPD.A_ID = category.A_NAME
	                AND NPD.A_CAT IN (
                        2177,	--Лица, награжденные знаком "Жителю блокадного Ленинграда"
                        2181,	--Лица, проработавшие в тылу в период с 22.06.1941 по 9.05.1945 не менее 6 месяцев, исключая период работы на временно оккупированных территориях СССР, либо награжденным орденами или медалями СССР за самоотверженный труд в период Великой Отечественной войны
                        2185,	--Участник Великой Отечественной войны
                        2271,	--Лица, работавшие на объектах противовоздушной обороны, местной противовоздушной обороны, строительстве оборонительных сооружений, военно-морских баз, аэродромов и других военных объектов в пределах тыловых границ действующих фронтов, операционных зон действующих флотов, на прифронтовых участках железнодорожных и автомобильных дорог
                        2274,	--Лица, проходившие военную службу в воинских частях, не входивших в состав действ.армии, в период с 22.06.1941 по 3.09.1945 не менее 6 месяцев
                        2400,	--Участник Великой Отечественной войны, ставший инвалидом вследствие общего заболевания, трудового увечья и других причин
                        2410,	--Лица, награжденные медалью "За оборону Ленинграда"
                        2422,	--Лица, награжденные знаком "Жителю блокадного Ленинграда", признанные инвалидами вследствие общего заболевания, трудового увечья и других причин
                        2501	--Лица, проходившие военную службу в воинских частях, не входивших в состав действ.армии, в период с 22.06.1941 по 3.09.1945 не менее 6 месяцев, ставшие инвалидами
                    )
        ----Адрес регистрации.
	        LEFT JOIN WM_ADDRESS addr 
	            ON personalCard.A_REGFLAT = ADDR.OUID 
	                AND ADDR.A_STATUS = 10
        ----Адрес временной регистрации.
            LEFT JOIN WM_ADDRESS addr1 
                ON personalCard.A_TEMPREGFLAT = ADDR1.OUID 
                    AND ADDR1.A_STATUS = 10
        WHERE category.A_STATUS = 10
            AND CONVERT(DATE, category.A_DATE) <= @endDateReport
            AND CONVERT(DATE, ISNULL(category.A_DATELAST, '29991231')) >= @startDateReport
            AND (addr.OUID IS NOT NULL OR addr1.OUID IS NOT NULL)
        UNION
        /*Герои*/
        SELECT DISTINCT
	        o.A_PCS
        FROM PFR_DATA_653_O o --ПФР: Учетные данные (6.5.3)
        ----ПФР: ГСП (6.5.3)
            INNER JOIN PFR_DATA_653_L l 
                ON o.A_OUID = l.A_DATA_O  
                    AND l.A_L2 IN (1, 2, 5, 7)
    ) t
)


--------------------------------------------------------------------------------------------------------------------------------


--Многодетные.
DECLARE @largeFamilies INT
SET @largeFamilies = (
    SELECT  
        COUNT(*)
    FROM (
        SELECT DISTINCT 
            actDocuments.PERSONOUID 
        FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
        ----Личное дело льготодержателя.
            INNER JOIN WM_PERSONAL_CARD personalCardHolder 
                ON personalCardHolder.OUID = actDocuments.PERSONOUID
                    AND personalCardHolder.A_STATUS = 10
                    AND (personalCardHolder.A_DEATHDATE IS NULL
                        OR CONVERT(DATE, personalCardHolder.A_DEATHDATE) >= @startDateReport
                    )
        ----Бланк строгой отчетности
            INNER JOIN WM_BLANK blank 
                ON blank.A_DOC = actDocuments.OUID
                    AND blank.A_STATUS = 10 --Статус в БД "Действует".
        WHERE actDocuments.A_STATUS = 10
            AND CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE) <= @endDateReport
            AND CONVERT(DATE, ISNULL(actDocuments.COMPLETIONSACTIONDATE, '29991231')) >= @startDateReport
            AND actDocuments.DOCUMENTSTYPE IN (
                2814,   --Удостоверение многодетной семьи
                2858    --Удостоверение многодетной малообеспеченной семьи
            )
    ) t
)

--------------------------------------------------------------------------------------------------------------------------------


--Инвалиды.
DECLARE @invalidFirstGroup INT
DECLARE @invalidSecondGroup INT
DECLARE @invalidThirdGroup INT
--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#INVALIDS') IS NOT NULL BEGIN DROP TABLE #INVALIDS END --Таблица назначений.
SELECT
    A_INVALID_GROUP AS INVALID_GROUP, 
    COUNT(*)        AS COUNT_PEOPLE
INTO #INVALIDS
FROM (
    SELECT 
        healthPicture.A_PERS, 
        healthPicture.A_INVALID_GROUP, 
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID ORDER BY healthPicture.A_STARTDATA DESC) AS gnum
    FROM WM_HEALTHPICTURE healthPicture --Состояние здоровья.
    ----Личное дело льготодержателя.
            INNER JOIN WM_PERSONAL_CARD personalCard 
                ON personalCard.OUID = healthPicture.A_PERS 
                    AND personalCard.A_STATUS = 10                                      --Статус в БД "Действует".
                    AND (personalCard.A_DEATHDATE IS NULL                               --Нет даты смерти...
                        OR CONVERT(DATE, personalCard.A_DEATHDATE) >= @startDateReport   --...либо она позде даты начала.
                    )
    WHERE healthPicture.A_STATUS = 10 
        AND healthPicture.A_INVALID_GROUP IS NOT NULL
        AND CONVERT(DATE, healthPicture.A_STARTDATA) <= @endDateReport
        AND CONVERT(DATE, ISNULL(healthPicture.A_ENDDATA, '29991231')) >= @startDateReport
	     --and ((pc.A_STATUSCHANGEDATE is not null and convert(date, pc.A_STATUSCHANGEDATE) > @cd and pc.A_PCSTATUS = 4) or (pc.A_PCSTATUS = 1))
) t
WHERE t.gnum = 1
GROUP BY t.A_INVALID_GROUP
SET @invalidFirstGroup = (SELECT COUNT_PEOPLE FROM #INVALIDS WHERE INVALID_GROUP = 1)
SET @invalidSecondGroup = (SELECT COUNT_PEOPLE FROM #INVALIDS WHERE INVALID_GROUP = 2)
SET @invalidThirdGroup = (SELECT COUNT_PEOPLE FROM #INVALIDS WHERE INVALID_GROUP = 3)


--------------------------------------------------------------------------------------------------------------------------------


--Неполные семьи.
DECLARE @singleParentFamilies INT
--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#SERVICES') IS NOT NULL BEGIN DROP TABLE #SERVICES END --Таблица назначений.
--Выборка назначений.
SELECT DISTINCT 
    servServ.A_PERSONOUID,
    personalCardHolder.A_SEX
INTO #SERVICES
FROM ESRN_SERV_SERV servServ --Назначения МСП.
----Период предоставления МСП.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_SERV = servServ.OUID
            AND period.A_STATUS = 10 --Статус в БД "Действует".
            AND CONVERT(DATE, period.STARTDATE) <= @endDateReport --Начало не выходит за окончание периода.
            AND CONVERT(DATE, ISNULL(period.A_LASTDATE, '29991231')) >= @startDateReport --Конец выходит за начало периода.
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCardHolder 
        ON personalCardHolder.OUID = servServ.A_PERSONOUID
            AND personalCardHolder.A_STATUS = 10 --Статус в БД "Действует".
            AND (personalCardHolder.A_DEATHDATE IS NULL
                OR CONVERT(DATE, personalCardHolder.A_DEATHDATE) >= @startDateReport
            )
WHERE servServ.A_STATUS = 10                    --Статус в БД "Действует".
    AND servServ.A_STATUSPRIVELEGE IN (2, 13)   --Постоянное прекращение или утверждено.
    AND servServ.A_SERV IN (
    ----Ежемесячное пособие на ребенка-инвалида 
        1742,   --Неработающий (работающий на условиях неполного рабочего времени или на дому) родитель (усыновитель, опекун, попечитель) ребенка-инвалида 
        2013,   --Неработающий (работающий на условиях неполного рабочего времени или на дому) родитель (усыновитель, опекун, попечитель) ребенка-инвалида 
    ----Ежемесячное пособие на ребенка 
        1435,   --Одинокая мать 
        2010,   --Одинокая мать 
    ----Ежемесячное пособие на ребенка, родители которого уклоняются от уплаты алиментов 
        1436,   --Родитель (усыновитель, опекун, попечитель) совместно проживающего с ним ребенка, родители которого уклоняются от уплаты алиментов 
        2011,   --Родитель (усыновитель, опекун, попечитель) совместно проживающего с ним ребенка, родители которого уклоняются от уплаты алиментов 
    ----Социальное пособие на оказание ГСП на основании социального контракта 
        1909    --Малоимущая семья 
    )
--Выбор тех людей, у которых в родственных связях нет мужа/жены.
SET @singleParentFamilies = (
    SELECT
        COUNT(*)
    FROM (
        SELECT 
            o.A_PERSONOUID, 
            o.A_SEX,
            SUM(CASE WHEN relationship.A_RELATED_RELATIONSHIP IN (3, 4) THEN 1 ELSE 0 END) AS child,
            MAX(CASE WHEN relationship.A_RELATED_RELATIONSHIP = 8 THEN 1 ELSE 0 END) AS wife,
            MAX(CASE WHEN relationship.A_RELATED_RELATIONSHIP = 9 THEN 1 ELSE 0 END) AS husband
        from #SERVICES o
        ----Родственные связи.
            INNER JOIN WM_RELATEDRELATIONSHIPS relationship  
                ON relationship.A_ID1 = o.A_PERSONOUID
                    AND relationship.A_STATUS = 10
        ----Личное дело ребенка.
            INNER JOIN WM_PERSONAL_CARD personalCardChild
                ON personalCardChild.OUID = relationship.A_ID2
                    AND personalCardChild.A_STATUS = 10 --Статус в БД "Действует".
                    AND CONVERT(DATE, personalCardChild.BIRTHDATE) <= @endDateReport
                    AND (personalCardChild.A_DEATHDATE IS NULL
                        OR CONVERT(DATE, personalCardChild.A_DEATHDATE) >= @startDateReport
                    )
        GROUP BY o.A_PERSONOUID, o.A_SEX
    ) t
    WHERE t.child <> 0 --Есть дети.
        AND (t.A_SEX = 1 AND t.wife = 0 --Мужчина и нет жены.
            OR t.A_SEX = 2 and t.husband = 0 --Женщина и нет мужа.
        ) 
)


--------------------------------------------------------------------------------------------------------------------------------


--Для отчета.
SELECT 
    CONVERT(VARCHAR, @startDateReport, 104) AS [Дата С],
    CONVERT(VARCHAR, @endDateReport, 104)   AS [Дата По],
    @poorCitizens                           AS [Малоимущие граждане],
    @veteransAndHeroes                      AS [Ветераны ВОВ и герои],
    @largeFamilies                          AS [Многодетные],
    @singleParentFamilies                   AS [Неполные семьи],
    @invalidFirstGroup                      AS [Инвалиды I группы],
    @invalidSecondGroup                     AS [Инвалиды II группы],
    @invalidThirdGroup                      AS [Инвалиды III группы]

    
--------------------------------------------------------------------------------------------------------------------------------