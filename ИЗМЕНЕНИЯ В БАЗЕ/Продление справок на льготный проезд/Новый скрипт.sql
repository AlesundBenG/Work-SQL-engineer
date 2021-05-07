/*
*   Скрипт по беззаявительнмоу продлению льготного проезда.
*   Автор: Баташев Павел.
*   Дата последнего изменения: 23.12.2020
*/


--------------------------------------------------------------------------------------------------------------------------------


--Дата генерации (Чтобы везде стояла одна и та же).
DECLARE @dateGeneration DATETIME
SET @dateGeneration = GETDATE()

--Дата начала периода продления.
DECLARE @dateFrom DATE
SET @dateFrom = CONVERT(DATE, #dateFrom#)

--Дата окончания периода продления.
DECLARE @dateTo DATE
SET @dateTo = CONVERT(DATE, #dateTo#)

--Проверка корректности периода.
IF (@dateFrom IS NULL OR @dateTo IS NULL OR DATEDIFF(MONTH, @dateFrom, @dateTo) >= 12 OR DATEDIFF(DAY, @dateTo, @dateFrom) > 0)
BEGIN
	RAISERROR ('Ошибка: указан некорректный период для выборки', 16, 1)
	RETURN
END


--------------------------------------------------------------------------------------------------------------------------------


--Дата начала прошлого учебного года (Для проверки справки, относящейся к прошлому учебному году).
DECLARE @dateStart_LastSchoolYear DATE
SET @dateStart_LastSchoolYear = CONVERT(DATE, '20190601')

--Дата конца прошлого учебного года (Для проверки справки, относящейся к прошлому учебному году).
DECLARE @dateEnd_LastSchoolYear DATE
SET @dateEnd_LastSchoolYear = CONVERT(DATE, '20200531')

--Дата начала текущего учебного года (Для проверки справки, относящейся к текущему учебному году).
DECLARE @dateStart_CurrentSchoolYear DATE
SET @dateStart_CurrentSchoolYear = CONVERT(DATE, '20200601')

--Дата конца текущего учебного года (Для проверки справки, относящейся к текущему учебному году).
DECLARE @dateEnd_CurrentSchoolYear DATE
SET @dateEnd_CurrentSchoolYear = CONVERT(DATE, '20210531')



--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#TRANSPORT_DOC_THAT_END')                     IS NOT NULL BEGIN DROP TABLE #TRANSPORT_DOC_THAT_END                    END --Таблица документов на льготный проезд, которые заканчиваются в указанный период.
IF OBJECT_ID('tempdb..#DOC_ABOUT_INVALID')                          IS NOT NULL BEGIN DROP TABLE #DOC_ABOUT_INVALID                         END --Документы об инвалидности (МСЭ или ВТЭК).
IF OBJECT_ID('tempdb..#INVALID_WHO_NOT_HAVE_DOC_ABOUT_INVALID')     IS NOT NULL BEGIN DROP TABLE #INVALID_WHO_NOT_HAVE_DOC_ABOUT_INVALID    END --Люди, которые не имеют документа об инвалидности (МСЭ или ВТЭК), но у которых заканчивается справка о льготном проезде.
IF OBJECT_ID('tempdb..#SCHOOL_STUDENTS')                            IS NOT NULL BEGIN DROP TABLE #SCHOOL_STUDENTS                           END --Таблица школьников, имеющих справки об обучении за указанный период. 
IF OBJECT_ID('tempdb..#PEOPLE_WHO_HAVE_PETITION_ON_DOC_IN_PERIOD')  IS NOT NULL BEGIN DROP TABLE #PEOPLE_WHO_HAVE_PETITION_ON_DOC_IN_PERIOD END --Таблица людей, которые имеют заявление в указанный период на льготный проезд. Тип справки и тип документа, указанного должны совпадать.
IF OBJECT_ID('tempdb..#INFORMATION_FROM_PFR')                       IS NOT NULL BEGIN DROP TABLE #INFORMATION_FROM_PFR                      END --Данные из ПФР.
IF OBJECT_ID('tempdb..#INFORMATION_ABOUT_INVALID')                  IS NOT NULL BEGIN DROP TABLE #INFORMATION_ABOUT_INVALID                 END --Информация об инвалидности из ПФР.
IF OBJECT_ID('tempdb..#CREATED_DOC_ABOUT_INVALID')                  IS NOT NULL BEGIN DROP TABLE #CREATED_DOC_ABOUT_INVALID                 END --Созданные справки МСЭ.
IF OBJECT_ID('tempdb..#CREATED_HEALTH_PICTURE')                     IS NOT NULL BEGIN DROP TABLE #CREATED_HEALTH_PICTURE                    END --Созданные записи о состоянии здоровья, при создании справки МСЭ.
IF OBJECT_ID('tempdb..#RESULT')                                     IS NOT NULL BEGIN DROP TABLE #RESULT                                    END --Таблица результата.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #TRANSPORT_DOC_THAT_END (
    DOC_OUID        INT,    --ID документа.     
    DOC_STATUS      INT,    --Статус документа (Действует/не действует).
    DOC_END_DATE    DATE,   --Дата окончания действия документа.
    DOC_TYPE        INT,    --Тип документа.
    PERSONOUID      INT,    --ID личного дела держателя документа. 
    CATEGORY        INT,    --Льготная категория, по которому был создан льготный проезд.
)
CREATE TABLE #DOC_ABOUT_INVALID (
    DOC_OUID        INT,    --ID документа.     
    DOC_STATUS      INT,    --Статус документа (Действует/не действует).
    DOC_END_DATE    DATE,   --Дата окончания действия документа.
    DOC_TYPE        INT,    --Тип документа.   
    PERSONOUID      INT,    --ID личного дела держателя документа. 
)
CREATE TABLE #INVALID_WHO_NOT_HAVE_DOC_ABOUT_INVALID (
    PERSONOUID INT, --ID личного дела человека, у которого нет документа об инвалидности (МСЭ или ВТЭК), и у которых заканчивается льготный проезд.
)
CREATE TABLE #SCHOOL_STUDENTS(
    PERSONOUID          INT,            --ID личного дела школьника.
    DOC_START_DATE      DATE,           --Дата начала дейсвтия документа.
    DOC_END_DATE        DATE,           --Дата окончания дейсвтия основания об учебе за прошлый учебный год.
    GRADE               VARCHAR(50),    --Класс в справке об учебе за прошлый учебный год.
    LAST_SCHOOL_YEAR    INT,            --Справка за прошлый учебный год (ФЛАГ).
    CURRENT_SCHOOL_YEAR INT,            --Справка за текущий учебный год (ФЛАГ).
)
CREATE TABLE #PEOPLE_WHO_HAVE_PETITION_ON_DOC_IN_PERIOD (
    PETITION_OUID           INT,    --ID заявления.
    PETITION_TYPE           INT,    --Тип МСП, на которое подано заявление.
    PETITION_FOR_DOC_TYPE   INT,    --Тип документа, на который подано заявление.
    PERSONOUID              INT,    --Личное дело заявителя.
    PETITION_DATE_REG       DATE,   --Дата регистрации заявления.
)
CREATE TABLE #INFORMATION_FROM_PFR (
    PERSONOUID              INT,            --Личное дело гражданина.
    INVALID_GROUP           INT,            --Группа инвалидности.
    EDV_CATEGORY            INT,            --Код категории, в соответствии с которой гражданин имеет право на ЕДВ (п. 30 примечаний)
    INVALID_START_DATE      DATE,           --Дата установления инвалидности.
    INVALID_END_DATE        DATE,           --Инвалидность установлена на срок до...
    INVALID_DATE_NEXT_CHECK DATE,           --Дата очередного освидетельствования.
    INVALID_REASON          INT,            --Причина инвалидности по данным МСЭ.
    EDV_DOC_SERIES          VARCHAR(256),   --Серия документа, подтверждающего право на ЕДВ.
    EDV_DOC_NUMBER          VARCHAR(256),   --Номер документа, подтверждающего право на ЕДВ.
    EDV_DOC_START           DATE,           --Дата выдачи документа, подтверждающего право на ЕДВ.
    EDV_ORGANIZATION_NAME   VARCHAR(256),   --Наименование организации, выдавшего документ, подтверждающего право на ЕДВ.
    INVALID_DATE_CREATE     DATE            --Дата создания.
)
CREATE TABLE #INFORMATION_ABOUT_INVALID (
    GUID                    VARCHAR(50),    --ID информации.
    PERSONOUID              INT,            --ID личного дела держателя документа. 
    DOC_OUID                INT,            --ID документа.   
    INVALID_DATE_CREATE     DATE,           --Дата создания информации об инвалидности.
    INVALID_START_DATE      DATE,           --Дата начала действия инвалидности.
    INVALID_END_DATE        DATE,           --Дата окончания действия инвалидности..
    INVALID_GROUP           INT,            --Группа инвалидности.
    INVALID_REASON          INT,            --Причина инвалидности.
    INVALID_DATE_NEXT_CHECK DATE,           --Дата переосвидетельствования. 
    EDV_DOC_SERIES          VARCHAR(256),   --Серия документа, подтверждающего право на ЕДВ.
    EDV_DOC_NUMBER          VARCHAR(256),   --Номер документа, подтверждающего право на ЕДВ.
    EDV_ORGANIZATION_NAME   VARCHAR(256),   --Наименование организации, выдавшего документ, подтверждающего право на ЕДВ.
)
CREATE TABLE #CREATED_DOC_ABOUT_INVALID (
    DOC_OUID    INT,        --ID созданного документа.   
    PERSONOUID  INT,        --ID личного дела держателя документа.
    GUID        VARCHAR(36) --Глобальный идентификатор документа.
)
CREATE TABLE #CREATED_HEALTH_PICTURE (
    OUID            INT,    --ID созданной записи о здоровье.
    REFERENCE       INT,    --ID соданной справки МСЭ.
)
CREATE TABLE #RESULT(
    DOC_OUID        INT,            --ID документа.
    DOC_STATUS      INT,            --Статус документа (Действует/не действует).
    DOC_END_DATE    DATE,           --Дата окончания действия документа.
    DOC_TYPE        INT,            --Тип документа.
    CATEGORY        INT,            --Льготная категория, по которому был создан льготный проезд.
    PERSONOUID      INT,            --ID личного дела держателя документа.
    UPDATE_DOC      INT,            --Продляем или нет.
    REASON          VARCHAR(256),   --Причина продления (новой даты) / не продления.
    NEW_DATE        DATE,           --Новая дата.
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка транспортных справок, которые завершаются в указанный период.
INSERT #TRANSPORT_DOC_THAT_END(DOC_OUID, DOC_STATUS, DOC_END_DATE, DOC_TYPE, PERSONOUID, CATEGORY)
SELECT 
    t.DOC_OUID,
    t.DOC_STATUS,
    t.DOC_END_DATE,
    t.DOC_TYPE,
    t.PERSONOUID,
    t.CATEGORY
FROM (
    SELECT 
        actDocuments.OUID                                   AS DOC_OUID, 
        actDocuments.A_DOCSTATUS                            AS DOC_STATUS,
        CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS DOC_END_DATE,
        actDocuments.DOCUMENTSTYPE                          AS DOC_TYPE,            
        actDocuments.PERSONOUID                             AS PERSONOUID, 
        petition.A_CATEGORY                                 AS CATEGORY,
        --Для отбора последней справки определенного типа (Последний документ определяется по дате начала действия документа).
        ROW_NUMBER() OVER (PARTITION BY actDocuments.PERSONOUID, actDocuments.DOCUMENTSTYPE ORDER BY actDocuments.ISSUEEXTENSIONSDATE DESC) AS nn
    FROM WM_ACTDOCUMENTS actDocuments   --Действующие документы.
    ----Статус в БД.
        INNER JOIN ESRN_SERV_STATUS esrnStatus
            ON esrnStatus.A_ID = 10                         --Статус в БД "Действует".
                AND esrnStatus.A_ID = actDocuments.A_STATUS --Связка с документом.
    ----Личное дело держателя документа.
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.A_STATUS = 10                       --Статус в БД "Действует".
                AND personalCard.A_PCSTATUS = 1                 --Действующее личное дело.
                AND personalCard.A_DEATHDATE IS NULL            --Человек жив.
                AND personalCard.OUID = actDocuments.PERSONOUID --Связка с документом.
    ----Бланк строгой отчетности.           
        INNER JOIN WM_BLANK blank 
            ON blank.A_STATUS = 10                  --Статус в БД "Дейтвует".
                AND blank.A_DOC = actDocuments.OUID --Связка с документом.
    ----Заявление.
        INNER JOIN WM_PETITION petition 
            ON petition.OUID = blank.A_PETITION --Связка с бланком строгой отчетности.
    ----Обращение.
        INNER JOIN WM_APPEAL_NEW appeal 
            ON appeal.A_STATUS = 10             --Статус в БД "Дейтвует".  
                AND appeal.OUID = petition.OUID --Связка с заявлением.
    WHERE actDocuments.COMPLETIONSACTIONDATE IS NOT NULL --Есть дата окончания.
        AND (actDocuments.DOCUMENTSTYPE IN (
                3971,	--Справка о праве на льготный проезд в автомобильном и электрифицированном транспорте городского сообщения.
                3973,	--Справка о праве на льготный проезд в автомобильном и электрифицированном транспорте городского сообщения учащимся.
                3970,	--Справка о праве на льготный проезд в автомобильном транспорте пригородного сообщения.
                3974,	--Справка о праве на льготный проезд в автомобильном транспорте пригородного сообщения учащимся
                3972	--Справка о праве на бесплатный проезд в автомобильном и электрифицированном транспорте городского сообщения учащимся.
		    )						 
		    OR actDocuments.DOCUMENTSTYPE = 4190    --Справка о праве на льготный проезд на железнодорожном транспорте пригородного сообщения.
            AND petition.A_CATEGORY = 2557          --Дети в возрасте от 5 до 7 лет.
        )
        AND petition.A_CATEGORY  IN (  --Но льготный проезд инвалиду.
            242,    -- Инвалид I группы.
            243,    -- Инвалид II группы.
            244,    -- Дети - инвалиды.
            245,    -- Инвалид III группы.
            1246,   -- ЧАЭС - инвалиды вследствие радиационного воздействия.
            2081,   -- Граждане, ставшие инвалидами вследствие поствакцинального осложнения.
            2162,   -- ПОР - гражданин из подразделения особого риска группы "Б".
            2406,   -- Инвалид Великой Отечественной войны.
            2407,   -- Инвалид боевых действий.
            2417,   -- Военнослужащие и лица рядового и начальствующего состава органов внутренних дел, Государственной противопожарной службы, учреждений и органов уголовно-исполнительной системы, ставшие инвалидами вследствие ранения, контузии и увечья, полученных при исполнении обязанностей военной службы (служебных обязанностей).
            2422,   -- Лица, награжденные знаком "Жителю блокадного Ленинграда", признанные инвалидами вследствие общего заболевания, трудового увечья и других причин.
            2471    -- Семьи, имеющие детей-инвалидов.
        )
) t
WHERE t.nn = 1                                          --Последний документ.\
    AND t.DOC_END_DATE BETWEEN @dateFrom AND @dateTo    --Дата окончания последнего документа входит в период продляемых документов.
	 
	 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Выборка справок МСЭ и ВТЭК.
INSERT #DOC_ABOUT_INVALID (DOC_OUID, DOC_STATUS, DOC_END_DATE, DOC_TYPE, PERSONOUID)
SELECT
    t.DOC_OUID,
    t.DOC_STATUS,
    t.DOC_END_DATE,
    t.DOC_TYPE,
    t.PERSONOUID
FROM ( 
    SELECT
        actDocuments.OUID                                   AS DOC_OUID, 
        actDocuments.A_DOCSTATUS                            AS DOC_STATUS,
        CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS DOC_END_DATE,   
        actDocuments.DOCUMENTSTYPE                          AS DOC_TYPE, 
        actDocuments.PERSONOUID                             AS PERSONOUID, 
        --Для отбора последней справки (Последний документ определяется по дате начала действия документа).
        ROW_NUMBER() OVER (PARTITION BY actDocuments.PERSONOUID ORDER BY actDocuments.ISSUEEXTENSIONSDATE DESC) AS nn
    FROM WM_ACTDOCUMENTS actDocuments   --Действующие документы.
    WHERE (actDocuments.A_STATUS = 10 AND actDocuments.A_DOCSTATUS = 1) --Действующая справка. 
        AND actDocuments.PERSONOUID IS NOT NULL                         --Есть владелец.
        AND actDocuments.DOCUMENTSTYPE IN (
            1799,   --Справка МСЭ.
            2701    --Справка ВТЭК.
        )
) t 
WHERE t.nn = 1                                                  --Берем последний документ.
    AND (t.DOC_END_DATE > @dateTo OR t.DOC_END_DATE IS NULL)    --Дата окончания должна выходить за период продления, либо быть бессрочной.


--------------------------------------------------------------------------------------------------------------------------------


--Выборка людей, которым нужно создать справку МСЭ.
INSERT #INVALID_WHO_NOT_HAVE_DOC_ABOUT_INVALID (PERSONOUID)
SELECT 
    docTransport.PERSONOUID
FROM #TRANSPORT_DOC_THAT_END docTransport --Заканчивающиеся справки о льготном проезде.
----Справки МСЭ и ВТЭК.
    LEFT JOIN #DOC_ABOUT_INVALID docInvalid
        ON docInvalid.PERSONOUID = docTransport.PERSONOUID --Связка со справкой.
WHERE docInvalid.DOC_OUID IS NULL   --Нет справки МСЭ и ВТЭК.
    AND docTransport.CATEGORY IN (  --Но льготный проезд инвалиду.
        242,    -- Инвалид I группы.
        243,    -- Инвалид II группы.
        244,    -- Дети - инвалиды.
        245,    -- Инвалид III группы.
        1246,   -- ЧАЭС - инвалиды вследствие радиационного воздействия.
        2081,   -- Граждане, ставшие инвалидами вследствие поствакцинального осложнения.
        2162,   -- ПОР - гражданин из подразделения особого риска группы "Б".
        2406,   -- Инвалид Великой Отечественной войны.
        2407,   -- Инвалид боевых действий.
        2417,   -- Военнослужащие и лица рядового и начальствующего состава органов внутренних дел, Государственной противопожарной службы, учреждений и органов уголовно-исполнительной системы, ставшие инвалидами вследствие ранения, контузии и увечья, полученных при исполнении обязанностей военной службы (служебных обязанностей).
        2422,   -- Лица, награжденные знаком "Жителю блокадного Ленинграда", признанные инвалидами вследствие общего заболевания, трудового увечья и других причин.
        2471    -- Семьи, имеющие детей-инвалидов.
    )


--------------------------------------------------------------------------------------------------------------------------------


--Выборка учеников школ, имеющих справки об обучении за текущий или прошлый учебный год.
INSERT #SCHOOL_STUDENTS(PERSONOUID, DOC_START_DATE, DOC_END_DATE, GRADE, LAST_SCHOOL_YEAR, CURRENT_SCHOOL_YEAR)
SELECT
    t.PERSONOUID,
    t.DOC_START_DATE,
    t.DOC_END_DATE,
    t.GRADE,
    t.LAST_SCHOOL_YEAR,
    t.CURRENT_SCHOOL_YEAR
FROM (
    SELECT
        actDocuments.PERSONOUID		                        AS PERSONOUID,
        CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE)     AS DOC_START_DATE,
        CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS DOC_END_DATE,
        studyInfo.A_GRADE			                        AS GRADE,
        CASE
            WHEN CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE) BETWEEN @dateStart_LastSchoolYear AND @dateEnd_LastSchoolYear THEN 1
            ELSE 0
        END AS LAST_SCHOOL_YEAR,
        CASE
            WHEN CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE) BETWEEN @dateStart_CurrentSchoolYear AND @dateEnd_CurrentSchoolYear THEN 1
            ELSE 0
        END AS CURRENT_SCHOOL_YEAR,
        --Для выбора последней справки (Последний документ определяется по дате начала действия документа).
        ROW_NUMBER() OVER (PARTITION BY actDocuments.PERSONOUID ORDER BY actDocuments.ISSUEEXTENSIONSDATE DESC) AS nn
    FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
    ----Статус в БД.
        INNER JOIN ESRN_SERV_STATUS esrnStatus                  
            ON actDocuments.A_STATUS = 10                   --Статус документа в БД "Действует".
                AND esrnStatus.A_ID = actDocuments.A_STATUS --Связка с документом.   
    ----Информация об учебе.
        INNER JOIN WM_STUDY studyInfo                   
            ON studyInfo.A_STATUS = 10                      --Статус информации об учебе в БД "Действует".
                AND studyInfo.OUID = actDocuments.A_STUDY   --Связка с документом.
    WHERE actDocuments.DOCUMENTSTYPE = 2083 --Справка об учебе в общеобразовательном учреждении.
) t
WHERE t.nn = 1                                                  --Последняя справка.
    AND (t.LAST_SCHOOL_YEAR = 1 OR t.CURRENT_SCHOOL_YEAR = 1)   --Справка за текущий или прошлый учебный год.


------------------------------------------------------------------------------------------------------------------------------


--Выборка людей, которые имеют заявление в указанный период на льготный проезд.
INSERT #PEOPLE_WHO_HAVE_PETITION_ON_DOC_IN_PERIOD(PETITION_OUID, PETITION_TYPE, PETITION_FOR_DOC_TYPE, PERSONOUID, PETITION_DATE_REG)
SELECT    
    t.PETITION_OUID,
    t.PETITION_TYPE,
    t.PETITION_FOR_DOC_TYPE,
    t.PERSONOUID,
    t.PETITION_DATE_REG
FROM (
    SELECT 
        petition.OUID                       AS PETITION_OUID,
        petition.A_MSP                      AS PETITION_TYPE,
        CASE petition.A_MSP 
            WHEN 970 THEN 3970  --Льготный проезд в автомобильном транспорте пригородного сообщения.
            WHEN 969 THEN 3971  --Льготный проезд в автомобильном и электрифицированном транспорте городского сообщения.
            WHEN 972 THEN 3973  --Льготный проезд в автомобильном и электрифицированном транспорте городского сообщения учащимся.
            WHEN 973 THEN 3974	--Льготный проезд в автомобильном транспорте пригородного сообщения учащимся.
            WHEN 979 THEN 4190	--Льготный проезд на железнодорожном транспорте пригородного сообщения.
            WHEN 971 THEN 3972  --Бесплатный проезд в автомобильном и электрифицированном транспорте городского сообщения учащимся.
            WHEN 979 THEN 4190  --Льготный проезд на железнодорожном транспорте пригородного сообщения.
        END                                 AS PETITION_FOR_DOC_TYPE,
        petition.A_MSPHOLDER                AS PERSONOUID,
        CONVERT(DATE, appeal.A_DATE_REG)    AS PETITION_DATE_REG,
        --Для выбора последнего заявления на данные документы.
        ROW_NUMBER() OVER (PARTITION BY petition.A_MSPHOLDER  ORDER BY appeal.A_DATE_REG DESC) AS gnum 
    FROM WM_PETITION petition --Заявления.
    ----Обращение гражданина.	
        INNER JOIN WM_APPEAL_NEW appeal     
            ON appeal.A_STATUS = 10             --Статус в БД "Действует".
                AND appeal.OUID = petition.OUID --Связка с заявленеим.
    WHERE petition.A_MSP IN (
        970,	--Льготный проезд в автомобильном транспорте пригородного сообщения.
        969,	--Льготный проезд в автомобильном и электрифицированном транспорте городского сообщения.
        972,	--Льготный проезд в автомобильном и электрифицированном транспорте городского сообщения учащимся.
        973,	--Льготный проезд в автомобильном транспорте пригородного сообщения учащимся.
        979,	--Льготный проезд на железнодорожном транспорте пригородного сообщения.
        971,    --Бесплатный проезд в автомобильном и электрифицированном транспорте городского сообщения учащимся.
        979     --Льготный проезд на железнодорожном транспорте пригородного сообщения.
    )	
) t
WHERE t.gnum = 1                                                                --Последнее завяление.
    AND t.PETITION_DATE_REG BETWEEN DATEADD(MONTH, -1, @dateFrom) AND @dateTo   --Дата регистрации в период продления (Подхватываем еще прошлый месяц, вдруг в конце месяца приходили)


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Вставка информации из ПФР.
INSERT INTO #INFORMATION_FROM_PFR (PERSONOUID,INVALID_GROUP,EDV_CATEGORY ,INVALID_START_DATE,INVALID_END_DATE,INVALID_DATE_NEXT_CHECK,INVALID_REASON,EDV_DOC_SERIES,EDV_DOC_NUMBER,EDV_DOC_START,EDV_ORGANIZATION_NAME,INVALID_DATE_CREATE)
SELECT 
----Личное дело гражданина.
    p.A_PCS AS PERSONOUID,
----Группа инвалидности (возможные значения: 0 – нет группы инвалидности, 1- первая группа, 2 – вторая группа, 3 – третья группа, Р – «ребенок-инвалид») (п. 49 примечаний)
    CASE
        WHEN i.A_I8 = '1' THEN 1
        WHEN i.A_I8 = '2' THEN 2
        WHEN i.A_I8 = '3' THEN 3
        WHEN i.A_I8 = 'Р' THEN 4
        ELSE 0
    END AS INVALID_GROUP,
----Код категории, в соответствии с которой гражданин имеет право на ЕДВ (п. 30 примечаний)
    CASE
        WHEN l.A_L2 = 81 THEN 3
        WHEN l.A_L2 = 82 THEN 2
        WHEN l.A_L2 = 83 THEN 1
        WHEN l.A_L2 = 84 THEN 4
        ELSE 9999
    END AS EDV_CATEGORY,
----Дата установления инвалидности – ГГГГ/ММ/ДД(п.56 примечаний)
    CONVERT(DATE, i.A_I2) AS INVALID_START_DATE,	
----Инвалидность установлена на срок до – ГГГГ/ММ/ДД(п.57 примечаний)
    CONVERT(DATE, DATEADD(DAY, -1, i.A_I3)) AS INVALID_END_DATE,   
----Дата очередного освидетельствования – ГГГГ/ММ/ДД
    CONVERT(DATE, i.A_I4) AS INVALID_DATE_NEXT_CHECK,	
----Причина инвалидности по данным МСЭ (таблица 29).
    CASE
        WHEN i.A_I6 = 1 THEN 53
        WHEN i.A_I6 = 2 THEN 55
        WHEN i.A_I6 = 3 THEN 54
        WHEN i.A_I6 = 4 THEN 39
        WHEN i.A_I6 = 5 THEN 41
        WHEN i.A_I6 = 6 THEN 42
        WHEN i.A_I6 = 7 THEN 43
        WHEN i.A_I6 = 8 THEN 48
        WHEN i.A_I6 = 9 THEN 44
        WHEN i.A_I6 = 10 THEN 47
        WHEN i.A_I6 = 11 THEN 46
        WHEN i.A_I6 = 12 THEN 40
        WHEN i.A_I6 = 13 THEN 59
        WHEN i.A_I6 = 14 THEN 49
        WHEN i.A_I6 = 15 THEN 62
        WHEN i.A_I6 = 16 THEN 45
        ELSE null
    END AS INVALID_REASON,
----Серия документа, подтверждающего право на ЕДВ.
    l.A_L4 AS EDV_DOC_SERIES,	
----Номер документа, подтверждающего право на ЕДВ.
    l.A_L5 AS EDV_DOC_NUMBER,	
----Дата выдачи документа, подтверждающего право на ЕДВ:ГГГГ/ММ/ДД  (п. 31 примечаний)
    CONVERT(DATE, l.A_L6) AS EDV_DOC_START,	
----Наименование организации, выдавшего документ, подтверждающего право на ЕДВ.
    l.A_L7 AS EDV_ORGANIZATION_NAME,	
----Дата создания.
    CONVERT(DATE, p.A_CREATEDATE) AS INVALID_DATE_CREATE
FROM PFR_DATA_653_O p --ПФР: Учетные данные (6.5.3).
----ПФР: Инвалидность (6.5.3).
	    INNER JOIN PFR_DATA_653_I i 
	        ON i.A_DATA_O = p.A_OUID
----ПФР: ГСП (6.5.3).
	    INNER JOIN PFR_DATA_653_L l 
	        ON l.A_DATA_O = p.A_OUID 
	            AND l.A_L2 IN (81, 82, 83, 84) 
	            AND l.A_L3 = 'Справка МСЭК об инвалидности'
WHERE (
        CASE
            WHEN i.A_I8 = '1' THEN 1
            WHEN i.A_I8 = '2' THEN 2
            WHEN i.A_I8 = '3' THEN 3
            WHEN i.A_I8 = 'Р' THEN 4
            ELSE 0
        END
        ) = (
        CASE
            WHEN l.A_L2 = 81 THEN 3
            WHEN l.A_L2 = 82 THEN 2
            WHEN l.A_L2 = 83 THEN 1
            WHEN l.A_L2 = 84 THEN 4
            ELSE 9999
        END
    )
    
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Сбор информации для создания справок (МСЭ или ВТЭК).
INSERT #INFORMATION_ABOUT_INVALID (GUID, PERSONOUID,  DOC_OUID, INVALID_DATE_CREATE, INVALID_START_DATE, INVALID_END_DATE, INVALID_GROUP, INVALID_REASON, INVALID_DATE_NEXT_CHECK, EDV_DOC_SERIES, EDV_DOC_NUMBER, EDV_ORGANIZATION_NAME)
SELECT
    t.GUID, 
    t.PERSONOUID,
    t.DOC_OUID,
    t.INVALID_DATE_CREATE,
    t.INVALID_START_DATE,
    t.INVALID_END_DATE,
    t.INVALID_GROUP,
    t.INVALID_REASON,
    t.INVALID_DATE_NEXT_CHECK,
    t.EDV_DOC_SERIES,
    t.EDV_DOC_NUMBER,
    t.EDV_ORGANIZATION_NAME
FROM (
    SELECT
        NEWID() AS GUID, 
        PERSONOUID,
        CAST(NULL AS INT) AS DOC_OUID,
        INVALID_DATE_CREATE,
        INVALID_START_DATE,
        INVALID_END_DATE,
        INVALID_GROUP,
        INVALID_REASON,
        INVALID_DATE_NEXT_CHECK,
        EDV_DOC_SERIES,
        EDV_DOC_NUMBER,
        EDV_ORGANIZATION_NAME,
        --Для отбора последней информации.
        ROW_NUMBER() OVER (PARTITION BY PERSONOUID ORDER BY INVALID_START_DATE DESC) AS nn
    FROM #INFORMATION_FROM_PFR
    WHERE INVALID_END_DATE > @dateTo                                                        --Дата окончания инвалидности выходит за дату конца периода отчета.
        AND PERSONOUID IN (SELECT PERSONOUID FROM #INVALID_WHO_NOT_HAVE_DOC_ABOUT_INVALID)  --У человека есть заканчивающся справка о льготном проезде, но нет документа МСЭ.
) t
WHERE t.nn = 1 --Самая последняя информация об инвалидности.


-----------------------------------------------------------------------------------------------------------------------------------


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////Начало транзакции///////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


BEGIN TRANSACTION   


-----------------------------------------------------------------------------------------------------------------------------------


--Вставка справок МСЭ.
INSERT INTO WM_ACTDOCUMENTS (GUID, PERSONOUID, DOCUMENTSTYPE, A_DOCSTATUS, A_STATUS, ISSUEEXTENSIONSDATE, COMPLETIONSACTIONDATE, A_INV_REAS, DOCUMENTSERIES, DOCUMENTSNUMBER, A_GIVEDOCUMENTORG_TEXT, A_DOPINFO, A_CROWNER, A_CREATEDATE, A_EDITOWNER, TS)
OUTPUT inserted.OUID, inserted.PERSONOUID, inserted.[GUID] INTO #CREATED_DOC_ABOUT_INVALID(DOC_OUID, PERSONOUID, GUID)   --Сохранение во временную таблицу добавленных документов.
SELECT 
    GUID                                                                AS GUID, 
    PERSONOUID                                                          AS PERSONOUID, 
    1799                                                                AS DOCUMENTSTYPE, 
    1                                                                   AS A_DOCSTATUS, 
    10                                                                  AS A_STATUS, 
    INVALID_START_DATE                                                  AS ISSUEEXTENSIONSDATE, 
    INVALID_END_DATE                                                    AS COMPLETIONSACTIONDATE, 
    INVALID_REASON                                                      AS A_INV_REAS, 
    EDV_DOC_SERIES                                                      AS DOCUMENTSERIES, 
    EDV_DOC_NUMBER                                                      AS DOCUMENTSNUMBER, 
    EDV_ORGANIZATION_NAME                                               AS A_GIVEDOCUMENTORG_TEXT, 
    'Из данных ПФР от ' + CONVERT(VARCHAR, INVALID_DATE_CREATE, 104)    AS A_DOPINFO, 
    10314303                                                            AS A_CROWNER, 
    @dateGeneration                                                     AS A_CREATEDATE,        
    10314303                                                            AS A_EDITOWNER, 
    @dateGeneration                                                     AS TS
FROM #INFORMATION_ABOUT_INVALID --Информация об инвалидности.			


-----------------------------------------------------------------------------------------------------------------------------------


--Запись ID созданных документов.
UPDATE #INFORMATION_ABOUT_INVALID
SET DOC_OUID = docCreated.DOC_OUID
FROM #CREATED_DOC_ABOUT_INVALID docCreated --Созданные документы.
WHERE #INFORMATION_ABOUT_INVALID.GUID = docCreated.GUID


-----------------------------------------------------------------------------------------------------------------------------------


--Добавление записи о состоянии здоровья.
INSERT INTO WM_HEALTHPICTURE (GUID, A_PERS, A_REFERENCE, A_STATUS, A_STARTDATA, A_ENDDATA, A_INVALID_GROUP, A_INV_REAS, A_DETERMINATIONS_DATE, A_REMOVING_DATE, A_DATE_NEXT, A_INV_REAS_OTHER, A_CROWNER, A_CREATEDATE, A_EDITOWNER, TS)
OUTPUT inserted.OUID, inserted.A_REFERENCE INTO #CREATED_HEALTH_PICTURE(OUID, REFERENCE) --Сохранение во временную таблицу добавленных запией.
SELECT 
    NEWID()                                                             AS GUID, 
    PERSONOUID                                                          AS A_PERS, 
    DOC_OUID                                                            AS A_REFERENCE, 
    10                                                                  AS A_STATUS, 
    INVALID_START_DATE                                                  AS A_STARTDATA, 
    INVALID_END_DATE                                                    AS A_ENDDATA, 
    INVALID_GROUP                                                       AS A_INVALID_GROUP, 
    INVALID_REASON                                                      AS A_INV_REAS, 
    INVALID_START_DATE                                                  AS A_DETERMINATIONS_DATE, 
    INVALID_END_DATE                                                    AS A_REMOVING_DATE, 
    INVALID_DATE_NEXT_CHECK                                             AS A_DATE_NEXT, 
    'Из данных ПФР от ' + CONVERT(VARCHAR, INVALID_DATE_CREATE, 104)    AS A_INV_REAS_OTHER,
    10314303                                                            AS A_CROWNER, 
    @dateGeneration                                                     AS A_CREATEDATE, 
    10314303                                                            AS A_EDITOWNER, 
    @dateGeneration                                                     AS TS
FROM #INFORMATION_ABOUT_INVALID --Информация об инвалидности.


-----------------------------------------------------------------------------------------------------------------------------------


--Добавление связки Действующие документы - Состояние здоровья.
INSERT INTO LINK_ACTDOC_HEALTH (A_FROMID, A_TOID)
SELECT 
    REFERENCE   AS A_FROMID,    --Действующий документ.
    OUID        AS A_TOID       --Состояние здоровья.
FROM #CREATED_HEALTH_PICTURE --Созданные записи о сосотоянии здоровья.


-----------------------------------------------------------------------------------------------------------------------------------


--Добавление созданных документов во временную таблицу документов об инвалидности.
INSERT #DOC_ABOUT_INVALID (DOC_OUID, DOC_STATUS, DOC_END_DATE, DOC_TYPE, PERSONOUID)
SELECT
    docCreated.DOC_OUID                                 AS DOC_OUID,
    1                                                   AS DOC_STATUS,
    CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS DOC_END_DATE,
    1799                                                AS DOC_TYPE,
    docCreated.PERSONOUID                               AS PERSONOUID
FROM #CREATED_DOC_ABOUT_INVALID docCreated
    INNER JOIN WM_ACTDOCUMENTS actDocuments         --Действующие документы.
        ON actDocuments.OUID = docCreated.DOC_OUID  --Связка с созданным документом.
    
    
-----------------------------------------------------------------------------------------------------------------------------------


--Результат
INSERT #RESULT(DOC_OUID, DOC_STATUS, DOC_END_DATE, DOC_TYPE, CATEGORY, PERSONOUID, UPDATE_DOC, REASON, NEW_DATE)
SELECT
    transportDoc.DOC_OUID       AS DOC_OUID,
    transportDoc.DOC_STATUS     AS DOC_STATUS,
    transportDoc.DOC_END_DATE   AS DOC_END_DATE,
    transportDoc.DOC_TYPE       AS DOC_TYPE,
    transportDoc.CATEGORY       AS CATEGORY,
    transportDoc.PERSONOUID     AS PERSONOUID,
    CASE
        WHEN transportDoc.DOC_TYPE  = 3972 AND (schoolStudent.GRADE IN ('4grade', '5grade', '6grade', '7grade', '8grade', '9grade', '10grade','11grade') AND schoolStudent.LAST_SCHOOL_YEAR = 1)
            THEN 0
        WHEN transportDoc.DOC_TYPE  = 3972 AND (schoolStudent.GRADE IN ('5grade', '6grade', '7grade', '8grade', '9grade', '10grade','11grade') AND schoolStudent.CURRENT_SCHOOL_YEAR = 1) 
            THEN 0     
        WHEN havePetition.PETITION_OUID IS NOT NULL
            THEN 0    
        WHEN transportDoc.CATEGORY IN (242, 243, 244, 245, 1246, 2081, 2162, 2406, 2407, 2417, 2422, 2471) AND docInvalid.DOC_OUID IS NULL
            THEN 0
        ELSE 1
    END AS UPDATE_DOC,
    CASE
        WHEN transportDoc.DOC_TYPE  = 3972 AND (schoolStudent.GRADE IN ('4grade', '5grade', '6grade', '7grade', '8grade', '9grade', '10grade','11grade') AND schoolStudent.LAST_SCHOOL_YEAR = 1)
            THEN 'Справка на беслпатный проезд и человек имеет справку об учебе в ' + schoolStudent.GRADE + ' за прошлый учебный год (' + CONVERT(VARCHAR, @dateStart_LastSchoolYear, 104) + '-' + CONVERT(VARCHAR, @dateEnd_LastSchoolYear, 104) + ')'
        WHEN transportDoc.DOC_TYPE  = 3972 AND (schoolStudent.GRADE IN ('5grade', '6grade', '7grade', '8grade', '9grade', '10grade','11grade') AND schoolStudent.CURRENT_SCHOOL_YEAR = 1) 
            THEN 'Справка на беслпатный проезд и человек имеет справку об учебе в ' + schoolStudent.GRADE + ' за текущий учебный год (' + CONVERT(VARCHAR, @dateStart_CurrentSchoolYear, 104) + '-' + CONVERT(VARCHAR, @dateEnd_CurrentSchoolYear, 104) + ')'
        WHEN havePetition.PETITION_OUID IS NOT NULL
            THEN 'Есть заявление на справку за ' + CONVERT(VARCHAR, havePetition.PETITION_DATE_REG)    
        WHEN transportDoc.CATEGORY IN (242, 243, 244, 245, 1246, 2081, 2162, 2406, 2407, 2417, 2422, 2471) AND docInvalid.DOC_OUID IS NULL   
            THEN 'Льготная категория инвалида, но нет справки МСЭ, дата окончания которой выходит за  ' + CONVERT(VARCHAR, @dateTo, 104)
        WHEN DATEADD(YEAR, 1, transportDoc.DOC_END_DATE) > ISNULL(docInvalid.DOC_END_DATE, CONVERT(DATE, '29991231')) --Если справка МСЭ или ВТЭК заканчивается раньше, чем пройдет год, то ставим дату окончания справки МСЭ или ВТЭК.
            THEN 'По справке МСЭ или ВТЭК'     
        WHEN transportDoc.DOC_TYPE  = 3972 AND ((schoolStudent.LAST_SCHOOL_YEAR = 1 AND schoolStudent.GRADE = '3grade') OR (schoolStudent.CURRENT_SCHOOL_YEAR = 1 AND schoolStudent.GRADE = '4grade')) 
            THEN 'По окончанию 4 класса'         
        ELSE 'На 1 год'
    END AS REASON,
    CASE
        WHEN transportDoc.DOC_TYPE  = 3972 AND (schoolStudent.GRADE IN ('4grade', '5grade', '6grade', '7grade', '8grade', '9grade', '10grade','11grade') AND schoolStudent.LAST_SCHOOL_YEAR = 1)
            THEN CAST(NULL AS DATE)
        WHEN transportDoc.DOC_TYPE  = 3972 AND (schoolStudent.GRADE IN ('5grade', '6grade', '7grade', '8grade', '9grade', '10grade','11grade') AND schoolStudent.CURRENT_SCHOOL_YEAR = 1) 
            THEN CAST(NULL AS DATE)
        WHEN havePetition.PETITION_OUID IS NOT NULL
            THEN CAST(NULL AS DATE)
        WHEN transportDoc.CATEGORY IN (242, 243, 244, 245, 1246, 2081, 2162, 2406, 2407, 2417, 2422, 2471) AND docInvalid.DOC_OUID IS NULL   
            THEN CAST(NULL AS DATE)
        WHEN DATEADD(YEAR, 1, transportDoc.DOC_END_DATE) > ISNULL(docInvalid.DOC_END_DATE, CONVERT(DATE, '29991231')) --Если справка МСЭ или ВТЭК заканчивается раньше, чем пройдет год, то ставим дату окончания справки МСЭ или ВТЭК.
            THEN docInvalid.DOC_END_DATE   
        WHEN transportDoc.DOC_TYPE  = 3972 AND ((schoolStudent.LAST_SCHOOL_YEAR = 1 AND schoolStudent.GRADE = '3grade') OR (schoolStudent.CURRENT_SCHOOL_YEAR = 1 AND schoolStudent.GRADE = '4grade')) 
            THEN DATEADD(MONTH, 1, CONVERT(DATE, @dateEnd_CurrentSchoolYear)) --Мол, если учебный год кончается 31-05-2021, то справка действует до 30-06-2021, то есть, +1 месяц.
        ELSE DATEADD(YEAR, 1, transportDoc.DOC_END_DATE)  
    END AS NEW_DATE
FROM #TRANSPORT_DOC_THAT_END transportDoc    --Справки льготного проезда, которые заканчиваются в указанный период.
----Справки из школы.
    LEFT JOIN #SCHOOL_STUDENTS schoolStudent
        ON schoolStudent.PERSONOUID = transportDoc.PERSONOUID   --Связка со справкой льготного проезда.
----Заявления.
    LEFT JOIN #PEOPLE_WHO_HAVE_PETITION_ON_DOC_IN_PERIOD havePetition
        ON havePetition.PERSONOUID = transportDoc.PERSONOUID                --Связка со справкой льготного проезда.
            AND havePetition.PETITION_FOR_DOC_TYPE = transportDoc.DOC_TYPE  --Тип заявления должен совпадать с типом справки.
----Документы об инвалидности (Справки МСЭ).
    LEFT JOIN #DOC_ABOUT_INVALID docInvalid
        ON docInvalid.PERSONOUID = transportDoc.PERSONOUID --Связка со справкой льготного проезда.

--Установка последнего дня месяца, если установленная дата не является последним днем месяца.
--UPDATE #RESULT
--SET NEW_DATE = DATEADD(MONTH, ((YEAR(NEW_DATE) - 1900) * 12) + MONTH(NEW_DATE), -1)
--FROM #RESULT    


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Фиксация изменений для отображения в папке беззаявительно продленных документов.
INSERT INTO TRANSPORT_DOCUMENT_PROLONGATION (A_DATE_GEN, A_DOC)
SELECT 
    @dateGeneration AS A_DATE_GEN,
    result.DOC_OUID AS A_DOC
FROM #RESULT result
WHERE (result.UPDATE_DOC = 1 AND result.NEW_DATE IS NOT NULL)   --Продление тех, у кого стоит флаг продления и есть новая дата.

--Подробная фиксация изменений.
INSERT INTO TRANSPORT_DOC_PROLONGATION (GENERATION_DATE, DOC_OUID, DOC_STATUS, DOC_TYPE, DOC_END_DATE, CATEGORY, PERSONOUID, UPDATE_DOC, REASON, NEW_DATE)
SELECT
    @dateGeneration     AS GENERATION_DATE,
    result.DOC_OUID     AS DOC_OUID,
    result.DOC_STATUS   AS DOC_STATUS,
    result.DOC_TYPE     AS DOC_TYPE,
    result.DOC_END_DATE AS DOC_END_DATE,
    result.CATEGORY     AS CATEGORY,
    result.PERSONOUID   AS PERSONOUID,
    result.UPDATE_DOC   AS UPDATE_DOC,
    result.REASON       AS REASON,
    result.NEW_DATE     AS NEW_DATE
FROM #RESULT result

--Фиксация созданных справок МСЭ.
INSERT INTO MSE_DOC_CREATED (GENERATION_DATE, DOC_OUID, OUID_HEALTH_PICTURE, PERSONOUID)
SELECT
    @dateGeneration         AS GENERATION_DATE,
    docCreated.DOC_OUID     AS DOC_OUID,
    halthCreated.OUID       AS OUID_HEALTH_PICTURE,
    docCreated.PERSONOUID   AS PERSONOUID
FROM #CREATED_DOC_ABOUT_INVALID docCreated
    INNER JOIN #CREATED_HEALTH_PICTURE halthCreated
        ON halthCreated.REFERENCE = docCreated.DOC_OUID

--Фиксация изменений.
INSERT bnl_lg (pc, doc, d)
SELECT 
    PERSONOUID, 
    DOC_OUID, 
    @dateGeneration
FROM #RESULT result
WHERE (result.UPDATE_DOC = 1 AND result.NEW_DATE IS NOT NULL)   --Продление тех, у кого стоит флаг продления и есть новая дата.

--Продление.
UPDATE actDocuments
SET 
    COMPLETIONSACTIONDATE = result.NEW_DATE, 
    A_DOCSTATUS = 1, 
    A_EDITOWNER = 10314303, 
    TS = @dateGeneration
FROM WM_ACTDOCUMENTS actDocuments	
----Продлеваемые документы.
    INNER JOIN #RESULT result 
        ON result.DOC_OUID = actDocuments.OUID --Связка с документом.
WHERE (result.UPDATE_DOC = 1 AND result.NEW_DATE IS NOT NULL)   --Продление тех, у кого стоит флаг продления и есть новая дата.

COMMIT  


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////Конец транзакции////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


----------------------------------------------------------------------------------------------------------------------------


SELECT * FROM #INVALID_WHO_NOT_HAVE_DOC_ABOUT_INVALID        
SELECT * FROM #INFORMATION_ABOUT_INVALID
SELECT * FROM #CREATED_DOC_ABOUT_INVALID
SELECT * FROM #CREATED_HEALTH_PICTURE
SELECT * FROM #RESULT


----------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#TRANSPORT_DOC_THAT_END')                     IS NOT NULL BEGIN DROP TABLE #TRANSPORT_DOC_THAT_END                    END --Таблица документов на льготный проезд, которые заканчиваются в указанный период.
IF OBJECT_ID('tempdb..#DOC_ABOUT_INVALID')                          IS NOT NULL BEGIN DROP TABLE #DOC_ABOUT_INVALID                         END --Документы об инвалидности (МСЭ или ВТЭК).
IF OBJECT_ID('tempdb..#INVALID_WHO_NOT_HAVE_DOC_ABOUT_INVALID')     IS NOT NULL BEGIN DROP TABLE #INVALID_WHO_NOT_HAVE_DOC_ABOUT_INVALID    END --Люди, которые не имеют документа об инвалидности (МСЭ или ВТЭК), но у которых заканчивается справка о льготном проезде.
IF OBJECT_ID('tempdb..#SCHOOL_STUDENTS')                            IS NOT NULL BEGIN DROP TABLE #SCHOOL_STUDENTS                           END --Таблица школьников, имеющих справки об обучении за указанный период. 
IF OBJECT_ID('tempdb..#PEOPLE_WHO_HAVE_PETITION_ON_DOC_IN_PERIOD')  IS NOT NULL BEGIN DROP TABLE #PEOPLE_WHO_HAVE_PETITION_ON_DOC_IN_PERIOD END --Таблица людей, которые имеют заявление в указанный период на льготный проезд. Тип справки и тип документа, указанного должны совпадать.
IF OBJECT_ID('tempdb..#INFORMATION_FROM_PFR')                       IS NOT NULL BEGIN DROP TABLE #INFORMATION_FROM_PFR                      END --Данные из ПФР.
IF OBJECT_ID('tempdb..#INFORMATION_ABOUT_INVALID')                  IS NOT NULL BEGIN DROP TABLE #INFORMATION_ABOUT_INVALID                 END --Информация об инвалидности из ПФР.
IF OBJECT_ID('tempdb..#CREATED_DOC_ABOUT_INVALID')                  IS NOT NULL BEGIN DROP TABLE #CREATED_DOC_ABOUT_INVALID                 END --Созданные справки МСЭ.
IF OBJECT_ID('tempdb..#CREATED_HEALTH_PICTURE')                     IS NOT NULL BEGIN DROP TABLE #CREATED_HEALTH_PICTURE                    END --Созданные записи о состоянии здоровья, при создании справки МСЭ.
IF OBJECT_ID('tempdb..#RESULT')                                     IS NOT NULL BEGIN DROP TABLE #RESULT                                    END --Таблица результата.


--------------------------------------------------------------------------------------------------------------------------------