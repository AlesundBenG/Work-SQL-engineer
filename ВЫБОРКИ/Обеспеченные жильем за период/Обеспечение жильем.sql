------------------------------------------------------------------------------------------------------------------------------


--Начало периода отчета.
DECLARE @startDateReport DATE
SET @startDateReport = CONVERT(DATE, '01-01-2020')

--Конец периода отчета.
DECLARE @endDateReport DATE
SET @endDateReport = CONVERT(DATE, '31-12-2020')


--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#CATEGORY_PRIORITY')      IS NOT NULL BEGIN DROP TABLE #CATEGORY_PRIORITY     END --Таблица приоритетов льготных категорий.
IF OBJECT_ID('tempdb..#PROVIDED_WITH_HOUSING')  IS NOT NULL BEGIN DROP TABLE #PROVIDED_WITH_HOUSING END --Таблица людей, которые получили поддержку по обеспечению жильем.
IF OBJECT_ID('tempdb..#RESULT')                 IS NOT NULL BEGIN DROP TABLE #RESULT                END --Результат.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #CATEGORY_PRIORITY (
    CATEGORY    INT,    --Категория.
    PRIORITY    INT,    --Приоритет.
)
CREATE TABLE #PROVIDED_WITH_HOUSING (
    PERSONOUID      INT,            --Личное дело.
    END_DATE_NEED   DATE,           --Дата предоставления жилья.
    PRICE           FLOAT,          --Объем средств на одного получателя. 
    CATEGORY        VARCHAR(256),   --Льготная категория. 
    DISTRICT        VARCHAR(256)    --Район.
)


------------------------------------------------------------------------------------------------------------------------------


--Установка приоритетов.
INSERT INTO #CATEGORY_PRIORITY(CATEGORY, PRIORITY)
VALUES
    (2406, 0),
    (2400, 1),
    (2185, 1),
    (2177, 2),
    (2492, 3),
    (2489, 3),
    (2352, 3),
    (40, 4),
    (2348, 4),
    (2493, 5),
    (2494, 5),
    (2490, 5),
    (2491, 5),
    (2421, 6),
    (2044, 7),
    (242, 8),
    (243, 8),
    (245, 8),
    (2471, 9)


------------------------------------------------------------------------------------------------------------------------------


--Выборка людей, которые получили поддержку по обеспечению жильем.
INSERT INTO #PROVIDED_WITH_HOUSING (PERSONOUID, END_DATE_NEED, PRICE, CATEGORY, DISTRICT)
SELECT 
    houseNeed.PERSONOUID                    AS PERSONOUID,
    CONVERT(DATE, houseNeed.A_ENDDATANEED)  AS END_DATE_NEED,
    houseNeed.A_PERS_PRICE                  AS PRICE,
    CAST(NULL AS VARCHAR)                   AS CATEGORY,
    CAST(NULL AS VARCHAR)                   AS DISTRICT
FROM WM_HOUSENEED houseNeed --Обеспеченность жильем.
----Действующие документы.
    INNER JOIN WM_ACTDOCUMENTS actDocuments 
        ON actDocuments.OUID = houseNeed.A_DOC
            AND actDocuments.A_STATUS = 10          --Статус в БД "Действует".
            AND actDocuments.DOCUMENTSTYPE = 2894   --Документ органов местного самоуправления муниципальных образований области о нуждаемости заявителя в жилом помещении.                 
WHERE houseNeed.A_STATUS = 10                                                               --Статус в БД "Действует".
    AND CONVERT(DATE, houseNeed.A_ENDDATANEED) BETWEEN @startDateReport AND @endDateReport  --Дата снятия с учета на период отчета.
    AND houseNeed.A_REASON_EXCL = 6 AND houseNeed.A_STATUSNEEDS = 1                         --Причина снятия с учета "МСП в форме социальной выплаты жилье предоставлены".
    
    
------------------------------------------------------------------------------------------------------------------------------


--Установка категории.
UPDATE providedHousing
SET providedHousing.CATEGORY = t.CATEGORY
FROM #PROVIDED_WITH_HOUSING providedHousing
    INNER JOIN (
        SELECT DISTINCT
            personalCard.OUID               AS PERSONOUID,
            CASE
                WHEN typeCategory.A_ID IN (2406)                    THEN 'Инвалиды ВОВ'
                WHEN typeCategory.A_ID IN (2400, 2185)              THEN 'Участники ВОВ'
                WHEN typeCategory.A_ID IN (2177)                    THEN 'Жители блокадного Ленинграда и жители осажденного Севастополя'
                WHEN typeCategory.A_ID IN (2492, 2489, 2352)        THEN 'Члены семей ветеранов ВОВ'
                WHEN typeCategory.A_ID IN (40, 2348)                THEN 'Ветераны боевых действий'
                WHEN typeCategory.A_ID IN (2493, 2494, 2490, 2491)  THEN 'Члены семей ВБД'
                WHEN typeCategory.A_ID IN (2421)                    THEN 'Узники, имеющие инвалидность'
                WHEN typeCategory.A_ID IN (2044)                    THEN 'Узники, не имеющие инвалидность'
                WHEN typeCategory.A_ID IN (242, 243, 245)           THEN 'Инвалиды'
                WHEN typeCategory.A_ID IN (2471)                    THEN 'Семьи, имеющие детей-инвалидов'
                ELSE typeCategory.A_NAME
            END AS CATEGORY,
            ROW_NUMBER() OVER (PARTITION BY personalCard.OUID ORDER BY priority.PRIORITY) AS gnum 
        FROM #PROVIDED_WITH_HOUSING providedHouse
        ----Личное дело гражданина.
            INNER JOIN WM_PERSONAL_CARD personalCard 
                ON personalCard.OUID = providedHouse.PERSONOUID
                    AND personalCard.A_STATUS = 10
        ----Льготная категория.
            INNER JOIN WM_CATEGORY category 
                ON category.PERSONOUID = personalCard.OUID
                    AND category.A_STATUS = 10
                    AND CONVERT(DATE, category.A_DATE) < @endDateReport
                    AND (CONVERT(DATE, category.A_DATELAST) > @startDateReport OR category.A_DATELAST IS NULL)
        ------Отношение льготной категории к нормативно правовому документу.    
            INNER JOIN PPR_REL_NPD_CAT regulatoryDocument 
                ON regulatoryDocument.A_ID = category.A_NAME
        ----Наименования льготных категорий.
            INNER JOIN PPR_CAT typeCategory 
                ON typeCategory.A_ID = regulatoryDocument.A_CAT
        ----Действующие документы.
            INNER JOIN WM_ACTDOCUMENTS actDocuments 
                ON actDocuments.PERSONOUID = personalCard.OUID
                    AND actDocuments.A_STATUS = 10 --Статус в БД "Действует".
        ----Приоритеты категорий.
            INNER JOIN #CATEGORY_PRIORITY priority
                ON priority.CATEGORY = typeCategory.A_ID
        WHERE (typeCategory.A_ID = 2406 --Инвалид Великой Отечественной войны.
                AND actDocuments.DOCUMENTSTYPE = 2691 --Удостоверение инвалида ВОВ (отметка - ст.14).
            )
            OR (typeCategory.A_ID = 2185 --Участник Великой Отечественной войны.
                AND actDocuments.DOCUMENTSTYPE IN (
                    1838,   --Удостоверение ветерана ВОВ (отметка - ст.15).
                    2695    --Удостоверение участника войны (отметка - ст.15)
                )   
            )
            OR (typeCategory.A_ID = 2400 --Участник Великой Отечественной войны, ставший инвалидом вследствие общего заболевания, трудового увечья и других причин.
                AND actDocuments.DOCUMENTSTYPE IN (
                    1838,   --Удостоверение ветерана ВОВ (отметка - ст.15)
                    2758,   --Удостоверение участника войны (отметки - ст.15, ст.14)
                    2762,   --Удостоверение о праве на льготы (отметки - ст.14, ст.17)
                    2761,   --Удостоверение ветерана ВОВ (отметки - ст.17, ст.14)
                    2759    --Удостоверение ветерана ВОВ (отметки - ст.15, ст.14)
                )
            )
            OR (typeCategory.A_ID = 2177 --Лица, награжденные знаком "Жителю блокадного Ленинграда"
                AND actDocuments.DOCUMENTSTYPE = 1839 --Удостоверение ветерана ВОВ (отметка - ст.18)
            )
            OR (actDocuments.DOCUMENTSTYPE = 2687 --Удостоверение о праве на льготы  (отметка - ст.21)
                AND typeCategory.A_ID IN (
                    2492,   --Члены семей погибшего (умершего) инвалида войны, участника войны, состоявшие на его иждивении и получающие пенсию по случаю потери кормильца
                    2489,   --Члены семей погибшего (умершего) инвалида войны, участника войны
                    2352    --Члены семей погибших в Великой Отечественной войне лиц из числа личного состава групп самозащиты объектовых и аварийных команд местной противовоздушной обороны
                )
            )
            OR (typeCategory.A_ID = 2407 --Инвалид боевых действий.    
                AND actDocuments.DOCUMENTSTYPE IN (
                    2782,   --Удостоверение инвалида о праве на льготы.
                    1837    --Удостоверение инвалида о праве на льготы (отметка - ст.14)
                )
            )
            OR (typeCategory.A_ID = 40    --Ветеран боевых действий ФЗ "О ветеранах" Статья 3 пп.1 -4 
                AND actDocuments.DOCUMENTSTYPE IN (
                    2952,   --Свидетельство о праве на льготы ветерана боевых действий (отметка - ст.16 п.1).
                    1793    --Удостоверение ветерана боевых действий (отметка - ст.16 п.1)
                )
            )
            OR (typeCategory.A_ID = 2348    --Ветеран боевых действий ФЗ "О ветеранах" Статья 3 пп.5
                AND actDocuments.DOCUMENTSTYPE IN (
                    2038,   --Удостоверение ветерана боевых действий (отметка - ст.16 п.2)
                    2953    --Удостоверение о праве на льготы ветерана боевых действий (отметка - ст.16 п.2)
                )
            )
            OR (typeCategory.A_ID = 2493 --Члены семей погибшего (умершего) ветерана боевых действий.
                AND actDocuments.DOCUMENTSTYPE = 2687 --Удостоверение о праве на льготы  (отметка - ст.21).
            )
            OR (typeCategory.A_ID = 2494 --Члены семей погибшего (умершего) ветерана боевых действий, состоявшие на его иждивении и получающие пенсию по случаю потери кормильца
                AND actDocuments.DOCUMENTSTYPE IN (
                    2954,   --Справка о праве на льготы  по ст. 21 (для несовершеннолетних детей или детей, не достигших возраста 23 лет и обучающихся в образовательных учреждениях по очной форме обучения)
                    2687    --Удостоверение о праве на льготы  (отметка - ст.21)
                )
            )
            OR (typeCategory.A_ID = 2490 --Члены семей погибших военнослужащих, лиц рядового и начальствующего состава органов внутренних дел, Государственной противопожарной службы, учреждений и органов уголовно-исполнительной системы и органов государственной безопасности, погибших при исполнении обязанностей военной службы, состоявшие на его иждивении и получающие пенсию по потере кормильца (НЕ родители и НЕ вдовы/вдовцы)
                AND actDocuments.DOCUMENTSTYPE IN (
                    2954,   --Справка о праве на льготы  по ст. 21 (для несовершеннолетних детей или детей, не достигших возраста 23 лет и обучающихся в образовательных учреждениях по очной форме обучения)
                    2687    --Удостоверение о праве на льготы  (отметка - ст.21)
                )
            )
            OR (typeCategory.A_ID = 2491 --Члены семей погибших военнослужащих, лиц рядового и начальствующего состава органов внутренних дел, Государственной противопожарной службы, учреждений и органов уголовно-исполнительной системы и органов государственной безопасности, погибших при исполнении обязанностей военной службы, состоявшие на его иждивении и получающие пенсию по потере кормильца (родители и вдовы/вдовцы)
                AND actDocuments.DOCUMENTSTYPE IN (
                    2689,   --Пенсионное удостоверение с отметкой "Вдова(мать,отец) погибшего воина"
                    2687    --Удостоверение о праве на льготы  (отметка - ст.21)
                )
            )
            OR (typeCategory.A_ID = 2044 --Бывшие несовершеннолетние узники фашистских концлагерей.
                AND actDocuments.DOCUMENTSTYPE = 205 --Удостоверение о праве на льготы бывших несовершеннолетних узников фашистских концентрационных лагерей (Указ Президента РФ № 1235 от 15.10.1992г)
            )
            OR (typeCategory.A_ID = 2421 --Бывшие несовершеннолетние узники фашистских концлагерей, признанные инвалидами вследствие общего заболевания, трудового увечья и других причин
                AND actDocuments.DOCUMENTSTYPE = 205 --Удостоверение о праве на льготы бывших несовершеннолетних узников фашистских концентрационных лагерей (Указ Президента РФ № 1235 от 15.10.1992г)
            )
            OR (typeCategory.A_ID IN (242, 243, 245, 2471) --Инвалиды.
                AND actDocuments.DOCUMENTSTYPE IN (
                    2701,   --Справка ВТЭК,
                    1799    --Справка МСЭ
                )
            )
) t
    ON t.PERSONOUID = providedHousing.PERSONOUID
WHERE t.gnum = 1


------------------------------------------------------------------------------------------------------------------------------


UPDATE providedHousing
SET providedHousing.DISTRICT = 'Киров'
FROM #PROVIDED_WITH_HOUSING providedHousing
WHERE DISTRICT IS NULL


------------------------------------------------------------------------------------------------------------------------------


--Установка района.
UPDATE providedHousing
SET providedHousing.DISTRICT = t.DISTRICT,
    providedHousing.PRICE = t.AMOUNT
FROM #PROVIDED_WITH_HOUSING providedHousing
    INNER JOIN (
        SELECT 
            providedHousing.PERSONOUID,
            servServ.A_SUMP AS AMOUNT,
            CASE 
                WHEN federationBorought.A_NAME IS NULL THEN 'Киров'
                ELSE federationBorought.A_NAME
            END AS DISTRICT
        FROM #PROVIDED_WITH_HOUSING providedHousing
        ----Назначения МСП.
            INNER JOIN ESRN_SERV_SERV servServ 
                ON providedHousing.PERSONOUID = servServ.A_PERSONOUID
                    AND servServ.A_STATUS = 10
                    AND servServ.A_SK_MSP IN (
                        901, --Единовременная денежная выплата на строительство или приобретение жилого помещения.
                        902  --Социальная выплата на приобретение жилого помещения.
                    )
        ----Период предоставления МСП.
            INNER JOIN SPR_SERV_PERIOD period 
                ON period.A_SERV = servServ.OUID 
                    AND period.A_STATUS = 10    --Статус в БД "Действует".
                    AND CONVERT(DATE, period.STARTDATE) < @endDateReport
                    AND (CONVERT(DATE, period.A_LASTDATE) > @startDateReport OR period.A_LASTDATE IS NULL)
        ----ОСЗН.
            INNER JOIN ESRN_OSZN_DEP osznDepartament
                ON osznDepartament.OUID = servServ.A_ORGNAME --Связка с назначением.
        ----Связка ОСЗН и района.
            LEFT JOIN SPR_OSZN_FEDBOR oszn_federationBorought
                ON oszn_federationBorought.A_FROMID = osznDepartament.OUID
        ----Районы
            LEFT JOIN SPR_FEDERATIONBOROUGHT federationBorought
                ON federationBorought.OUID = oszn_federationBorought.A_TOID
) t 
    ON t.PERSONOUID = providedHousing.PERSONOUID    
  
  
------------------------------------------------------------------------------------------------------------------------------  
   
   
SELECT * FROM #PROVIDED_WITH_HOUSING
WHERE DISTRICT IS NULL
  
  
------------------------------------------------------------------------------------------------------------------------------
  
  
--Расчеты
SELECT 
    t.DISTRICT,
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Инвалиды ВОВ')                                                     AS [Инвалиды ВОВ],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Участники ВОВ')                                                    AS [Участники ВОВ],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Жители блокадного Ленинграда и жители осажденного Севастополя')    AS [Жители блокадного Ленинграда и жители осажденного Севастополя],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Члены семей ветеранов ВОВ')                                        AS [Члены семей ветеранов ВОВ],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY IN ('Инвалиды ВОВ', 
                                                                                                'Участники ВОВ', 
                                                                                                'Жители блокадного Ленинграда и жители осажденного Севастополя', 
                                                                                                'Члены семей ветеранов ВОВ'
    ))                                                                                                                                                          AS [Всего],
    (SELECT ISNULL(SUM(PRICE), 0) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY IN ('Инвалиды ВОВ', 
                                                                                                'Участники ВОВ', 
                                                                                                'Жители блокадного Ленинграда и жители осажденного Севастополя', 
                                                                                                'Члены семей ветеранов ВОВ'                                     
    ))                                                                                                                                                          AS [Сумма предоставленной меры социальной поддержки],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Ветераны боевых действий')                                         AS [Ветераны боевых действий],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Члены семей ВБД')                                                  AS [Члены семей ВБД],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Узники, имеющие инвалидность')                                     AS [Узники, имеющие инвалидность],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Узники, не имеющие инвалидность')                                  AS [Узники, не имеющие инвалидность],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY IN ('Ветераны боевых действий', 
                                                                                                'Члены семей ВБД', 
                                                                                                'Узники, имеющие инвалидность', 
                                                                                                'Узники, не имеющие инвалидность'
    ))                                                                                                                                                          AS [Всего],
    (SELECT ISNULL(SUM(PRICE), 0) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY IN ('Ветераны боевых действий', 
                                                                                                'Члены семей ВБД', 
                                                                                                'Узники, имеющие инвалидность', 
                                                                                                'Узники, не имеющие инвалидность'
    ))                                                                                                                                                          AS [Сумма предоставленной меры социальной поддержки],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Инвалиды')                                                         AS [Инвалиды],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY = 'Семьи, имеющие детей-инвалидов')                                   AS [Семьи, имеющие детей-инвалидов],
    (SELECT COUNT(*) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY IN ('Инвалиды', 'Семьи, имеющие детей-инвалидов'))                    AS [Всего],
    (SELECT ISNULL(SUM(PRICE), 0) FROM #PROVIDED_WITH_HOUSING WHERE DISTRICT = t.DISTRICT AND CATEGORY IN ('Инвалиды', 'Семьи, имеющие детей-инвалидов'))       AS [Сумма предоставленной меры социальной поддержки]
FROM (SELECT DISTINCT DISTRICT FROM #PROVIDED_WITH_HOUSING) t


------------------------------------------------------------------------------------------------------------------------------


SELECT * FROM #PROVIDED_WITH_HOUSING