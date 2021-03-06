--------------------------------------------------------------------------------------------------------------------------------


--Дата начала периода отчета.
DECLARE @dataFrom DATE
SET @dataFrom = CONVERT(DATE, '01-01-2020')

--Дата окончания периода отчета.
DECLARE @dataTo DATE
SET @dataTo = CONVERT(DATE, '31-12-2020')


--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#CATEGORY_PRIORITY')              IS NOT NULL BEGIN DROP TABLE #CATEGORY_PRIORITY                 END --Таблица приоритетов льготных категорий ВОВ.
IF OBJECT_ID('tempdb..#REPORT_CATEGORY')                IS NOT NULL BEGIN DROP TABLE #REPORT_CATEGORY                   END --Таблица льготных категорий, необходимых для отчета.
IF OBJECT_ID('tempdb..#PERSONAL_CARD_DATE_OFF')         IS NOT NULL BEGIN DROP TABLE #PERSONAL_CARD_DATE_OFF            END --Даты снатия с учетов личных дел.
IF OBJECT_ID('tempdb..#VALID_PERSONAL_CARD_FOR_REPORT') IS NOT NULL BEGIN DROP TABLE #VALID_PERSONAL_CARD_FOR_REPORT    END --Валидные личные дела для отчета.
IF OBJECT_ID('tempdb..#RESULT_CATEGORY')                IS NOT NULL BEGIN DROP TABLE #RESULT_CATEGORY                   END --Результат, основанный на категориях.
IF OBJECT_ID('tempdb..#RESULT_DOCUMENT')                IS NOT NULL BEGIN DROP TABLE #RESULT_DOCUMENT                   END --Результат, основанный на документах.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #CATEGORY_PRIORITY (
    CATEGORY    INT,    --Категория.
    PRIORITY    INT,    --Приоритет.
)
CREATE TABLE #REPORT_CATEGORY (
    CATEGORY    INT,    --Категория.
)
CREATE TABLE #PERSONAL_CARD_DATE_OFF (
    OFF_DATE    DATE,   --Дата снятия с учета.
    PERSONOUID  INT,    --Личное дело.
    REASON_OFF  INT,    --Причина снятия с учета (SPR_RES_REMUV).
)
CREATE TABLE #VALID_PERSONAL_CARD_FOR_REPORT (
    PERSONOUID INT, --Личное дело.
)
CREATE TABLE #RESULT_CATEGORY (
    PERSONOUID  INT,    --Личное дело.
    CATEGORY    INT,    --Категория.
)
CREATE TABLE #RESULT_DOCUMENT (
    PERSONOUID      INT,    --Личное дело.
    DOCUMENT_TYPE   INT,    --Тип документа.
)


--------------------------------------------------------------------------------------------------------------------------------


--Установка приоритетов.
INSERT INTO #CATEGORY_PRIORITY(CATEGORY, PRIORITY)
VALUES
    (2406,1),   --Инвалид Великой Отечественной войны
    (2400,2),   --Участник Великой Отечественной войны, ставший инвалидом вследствие общего заболевания, трудового увечья и других причин
    (2501,3),   --Лица, проходившие военную службу в воинских частях, не входивших в состав действ.армии, в период с 22.06.1941 по 3.09.1945 не менее 6 месяцев, ставшие инвалидами
    (2185,4),   --Участник Великой Отечественной войны
    (2410,5),   --Лица, награжденные медалью "За оборону Ленинграда"
    (2274,6),   --Лица, проходившие военную службу в воинских частях, не входивших в состав действ.армии, в период с 22.06.1941 по 3.09.1945 не менее 6 месяцев
    (2422,7),   --Лица, награжденные знаком "Жителю блокадного Ленинграда", признанные инвалидами вследствие общего заболевания, трудового увечья и других причин
    (2177,8),   --Лица, награжденные знаком "Жителю блокадного Ленинграда"
    (2271,9),   --Лица, работавшие на объектах противовоздушной обороны, местной противовоздушной обороны, строительстве оборонительных сооружений, военно-морских баз, аэродромов и других военных объектов в пределах тыловых границ действующих фронтов, операционных зон действующих флотов, на прифронтовых участках железнодорожных и автомобильных дорог
    (2044,11),  --Бывшие несовершеннолетние узники фашистских концлагерей, признанные инвалидами вследствие общего заболевания, трудового увечья и других причин
    (2421,10),  --Бывшие несовершеннолетние узники фашистских концлагерей
    (2181,12),  --Лица, проработавшие в тылу в период с 22.06.1941 по 9.05.1945 не менее 6 месяцев, исключая период работы на временно оккупированных территориях СССР, либо награжденным орденами или медалями СССР за самоотверженный труд в период Великой Отечественной войны
    (2420,13),  --Супруга (супруг) погибшего (умершего) инвалида Великой Отечественной войны
    (2404,14),  --Супруга (супруг) умершего участника Великой Отечественной войны, ставшего инвалидом вследствие общего заболевания, трудового увечья и других причин
    (2492,15),  --Члены семей погибшего (умершего) инвалида войны, участника войны, состоявшие на его иждивении и получающие пенсию по случаю потери кормильца
    (2489,16),  --Члены семей погибшего (умершего) инвалида войны, участника войны
    (2403,17),  --Супруга (супруг) погибшего (умершего) инвалида войны
    (2352,18),  --Члены семей погибших в Великой Отечественной войне лиц из числа личного состава групп самозащиты объектовых и аварийных команд местной противовоздушной обороны
    (2353,19),  --Члены семей погибших работников госпиталей и больниц города Ленинграда
    (2351,20),  --Члены семьи погибших в ВОВ лиц из числа личного состава групп самозащиты объектовых и аварийных команд местной противовоздушной обороны, члены семей погибших работников госпиталей и больниц Ленинграда
    (2401,21),  --Члены семей погибшего (умершего) инвалида войны, участника ВОВ, ветерана боевых действий, состоявшие на его иждивении и получающие пенсию по случаю потери кормильца
    (167,22),   --Члены семьи погибшего (умершего) инвалида войны, участника ВОВ, ветерана боевых действий
    (2413,23),  --Члены семей военнослужащих, лиц рядового и начальствующего состава органов внутренних дел, Государственной противопожарной службы, учреждений и органов уголовно-исполнительной системы и органов государственной безопасности, погибших при исполнении обязанностей военной службы (служебных обязанностей)
    (2402,24),  --Родитель погибшего (умершего) инвалида войны, участника ВОВ, ветерана боевых действий
    (2405,25),  --Супруга (супруг) умершего участника Великой Отечественной войны или ветерана боевых действий
    (2493,26),  --Члены семей погибшего (умершего) ветерана боевых действий
    (2494,27),  --Члены семей погибшего (умершего) ветерана боевых действий, состоявшие на его иждивении и получающие пенсию по случаю потери кормильца
    (2414,28),  --Члены семей военнослужащих, погибших в плену, признанных в установленном порядке пропавшими без вести в районах боевых действий, со времени исключения указанных военнослужащих из списков воинских частей
    (2490,29),  --Члены семей погибших военнослужащих, лиц рядового и начальствующего состава органов внутренних дел, Государственной противопожарной службы, учреждений и органов уголовно-исполнительной системы и органов государственной безопасности, погибших при исполнении обязанностей военной службы, состоявшие на его иждивении и получающие пенсию по потере кормильца (НЕ родители и НЕ вдовы/вдовцы)
    (2491,30),  --Члены семей погибших военнослужащих, лиц рядового и начальствующего состава органов внутренних дел, Государственной противопожарной службы, учреждений и органов уголовно-исполнительной системы и органов государственной безопасности, погибших при исполнении обязанностей военной службы, состоявшие на его иждивении и получающие пенсию по потере кормильца (родители и вдовы/вдовцы)
    (2407,31),  --Инвалид боевых действий
    (2417,32),  --Военнослужащие и лица рядового и начальствующего состава органов внутренних дел, Государственной противопожарной службы, учреждений и органов уголовно-исполнительной системы, ставшие инвалидами вследствие ранения, контузии и увечья, полученных при исполнении обязанностей военной службы (служебных обязанностей)
    (40,33),    --Ветеран боевых действий ФЗ "О ветеранах" Статья 3 пп.1 -4
    (2348,34),  --Ветеран боевых действий ФЗ "О ветеранах" Статья 3 пп.5
    (2347,35),  --Ветеран боевых действий ФЗ "О ветеранах" Статья 3 пп.6-7
    (46,36),    --Ветеран труда
    (42,37),    --Ветеран военной службы
    (2459,38),  --Ветеран труда Кировской области
    (258,39),   --Лица, признанные пострадавшими от политических репрессий
    (260,39)    --Реабилитированные лица
    

--------------------------------------------------------------------------------------------------------------------------------


--Установка льготных категорий для отчета.
INSERT INTO #REPORT_CATEGORY(CATEGORY)
VALUES
    (46),   --Ветеран труда
    (2459), --Ветеран труда Кировской области
    (258),  --Лица, признанные пострадавшими от политических репрессий
    (260),  --Реабилитированные лица
    (2181)  --Лица, проработавшие в тылу в период с 22.06.1941 по 9.05.1945 не менее 6 месяцев, исключая период работы на временно оккупированных территориях СССР, либо награжденным орденами или медалями СССР за самоотверженный труд в период Великой Отечественной войны
    
    
------------------------------------------------------------------------------------------------------------------------------


--Выборка даты снятия с учета личных дел.
INSERT INTO #PERSONAL_CARD_DATE_OFF (OFF_DATE, PERSONOUID, REASON_OFF)
SELECT 
    t.OFF_DATE,
    t.PERSONOUID,
    t.REASON_OFF
FROM (
    SELECT 
        CONVERT(DATE, reasonOff.A_DATE)         AS OFF_DATE,
        personalCard.OUID                       AS PERSONOUID,
        reasonOff.A_NAME                        AS REASON_OFF,
        CONVERT(DATE, reasonOff.A_DATEREPEATIN) AS RETURN_DATE,
        --Для отбора последнего снятия.
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID ORDER BY reasonOff.A_DATE DESC) AS gnum 
    FROM WM_REASON reasonOff --Снятие с учета гражданина.
    ----Таблица связки причин с личными делами.
        INNER JOIN SPR_LINK_PERSON_REASON linkWithPersonalCard
            ON linkWithPersonalCard.TOID = reasonOff.A_OUID
    ----Личное дело гражданина.
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.OUID = linkWithPersonalCard.FROMID
                AND personalCard.A_PCSTATUS IN (3, 4)   --Архивное, либо снятое с учета.
    WHERE reasonOff.A_STATUS = 10                       --Статус в БД "Действует".
) t
WHERE t.gnum = 1                --Последняя запись.
    AND t.RETURN_DATE IS NULL   --Дело еще не было восстановлено.
    
    
--------------------------------------------------------------------------------------------------------------------------------


--Выборка валидных личных дел для отчета.
INSERT INTO #VALID_PERSONAL_CARD_FOR_REPORT (PERSONOUID)
SELECT
    personalCard.OUID   AS PERSONOUID
FROM WM_PERSONAL_CARD personalCard
----Снятые с учета.
    LEFT JOIN #PERSONAL_CARD_DATE_OFF personalCardOff
        ON personalCardOff.PERSONOUID = personalCard.OUID
WHERE personalCard.A_STATUS = 10                                --Статус в БД "Действует".
    AND (personalCard.A_DEATHDATE IS NULL                       --Нет даты смерти, или...
        OR @dataFrom <= CONVERT(DATE, personalCard.A_DEATHDATE) --...она позже даты начала периода отчета.
    )
    AND (personalCard.A_PCSTATUS = 1                            --Личное дело действует, или...
        OR @dataFrom <= personalCardOff.OFF_DATE                --...оно не было снято до начала периода.
    )


--------------------------------------------------------------------------------------------------------------------------------


--Результат.
INSERT INTO #RESULT_CATEGORY(PERSONOUID, CATEGORY)
SELECT 
    t.PERSONOUID,
    t.CATEGORY
FROM (
    SELECT
        personalCard.PERSONOUID AS PERSONOUID,
        reportCategory.CATEGORY AS CATEGORY,
        --На случай, если в период входит несколько льготных категорий разных классов.
        ROW_NUMBER() OVER (PARTITION BY personalCard.PERSONOUID ORDER BY priorityCategory.PRIORITY) AS gnum 		
    FROM WM_CATEGORY category --Льготная категория.
    ----Личное дело льготодержателя.
        INNER JOIN #VALID_PERSONAL_CARD_FOR_REPORT personalCard 
            ON personalCard.PERSONOUID = category.PERSONOUID   
    ----Отношение льготной категории к нормативно правовому документу.      
        INNER JOIN PPR_REL_NPD_CAT regulatoryDocument 
            ON regulatoryDocument.A_ID = category.A_NAME 
    ----Категории отчета.
        INNER JOIN #REPORT_CATEGORY reportCategory
            ON reportCategory.CATEGORY = regulatoryDocument.A_CAT   
    ----Приоритеты льготных категорий.
        INNER JOIN #CATEGORY_PRIORITY priorityCategory
            ON priorityCategory.CATEGORY = reportCategory.CATEGORY 
    WHERE category.A_STATUS = 10                                --Статус в БД "Действует".
        AND @dataTo >= CONVERT(DATE, category.A_DATE)           --Дата начала действия льготной категории не позже конца периода отчета.
        AND (@dataFrom <= CONVERT(DATE, category.A_DATELAST)    --Дата окончания действия льготной категории не раньше начала периода отчета, или...
            OR category.A_DATELAST IS NULL                      --...дата окончания отсутствует.
        )
) t
WHERE t.gnum = 1


--------------------------------------------------------------------------------------------------------------------------------


--Выборка льготных категорий по документу.
INSERT INTO #RESULT_DOCUMENT(PERSONOUID, DOCUMENT_TYPE)
SELECT
    t.PERSONOUID,
    t.DOCUMENT_TYPE
FROM (
    SELECT 
        personalCard.PERSONOUID     AS PERSONOUID,
        actDocuments.DOCUMENTSTYPE  AS DOCUMENT_TYPE,
        --На случай, если в период входит несколько документов.
        ROW_NUMBER() OVER (PARTITION BY personalCard.PERSONOUID, actDocuments.DOCUMENTSTYPE ORDER BY actDocuments.ISSUEEXTENSIONSDATE DESC) AS gnum 	
    FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
    ----Личное дело льготодержателя.
        INNER JOIN #VALID_PERSONAL_CARD_FOR_REPORT personalCard 
            ON personalCard.PERSONOUID = actDocuments.PERSONOUID        
    WHERE actDocuments.A_STATUS = 10                                        --Статус в БД "Действует".
        AND @dataTo >= CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE)      --Дата начала действия документа не позже конца периода отчета.
        AND (@dataFrom <= CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE) --Дата окончания действия документа не раньше начала периода отчета, или...
            OR actDocuments.COMPLETIONSACTIONDATE IS NULL                   --...дата окончания отсутствует.
        )
        AND actDocuments.DOCUMENTSTYPE IN (
            1830 --Удостоверение ветерана военной службы.
        )
) t
WHERE t.gnum = 1


--------------------------------------------------------------------------------------------------------------------------------


--Особое условие того, что из ветеранов труда вычитаем ветеранов военной службы.
DELETE FROM #RESULT_CATEGORY 
WHERE CATEGORY = 46
    AND PERSONOUID IN (SELECT PERSONOUID FROM #RESULT_DOCUMENT)


--------------------------------------------------------------------------------------------------------------------------------


--Количество.
SELECT 
    typeCategory.A_NAME AS [Класс категории],
    COUNT(*)            AS [Кол-во]
FROM #RESULT_CATEGORY result
    INNER JOIN PPR_CAT typeCategory 
        ON typeCategory.A_ID = result.CATEGORY
GROUP BY typeCategory.A_NAME
UNION ALL
SELECT
    'Ветеран военной службы'    AS [Класс категории],
    COUNT(*)                    AS [Кол-во]     
FROM #RESULT_DOCUMENT


--------------------------------------------------------------------------------------------------------------------------------