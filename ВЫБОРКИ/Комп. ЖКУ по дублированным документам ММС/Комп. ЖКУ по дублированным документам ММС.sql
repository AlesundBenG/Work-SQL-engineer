------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#ALIVE_PEOPLE')                       IS NOT NULL BEGIN DROP TABLE #ALIVE_PEOPLE                      END --Таблица живых людей, личные дела которых действуют.
IF OBJECT_ID('tempdb..#HUSBAND_AND_WIFE')                   IS NOT NULL BEGIN DROP TABLE #HUSBAND_AND_WIFE                  END --Таблица мужей и жен.
IF OBJECT_ID('tempdb..#PEOPLE_WHO_HAVE_PETITION_ON_DOC')    IS NOT NULL BEGIN DROP TABLE #PEOPLE_WHO_HAVE_PETITION_ON_DOC   END --Таблица людей, которые имеют заявление на МСП "Удостоверение многодетной малообеспеченной семьи" и "Продление удостоверения многодетной малообеспеченной семьи".
IF OBJECT_ID('tempdb..#MANY_CHILDREN_DOC')                  IS NOT NULL BEGIN DROP TABLE #MANY_CHILDREN_DOC                 END --Таблица действующих документов на данный момент "Удостоверение многодетной малообеспеченной семьи".
IF OBJECT_ID('tempdb..#MANY_CHILDREN_MSP')                  IS NOT NULL BEGIN DROP TABLE #MANY_CHILDREN_MSP                 END --Таблица действующий назначений на данный момент "Ежемесячная социальная выплата на детей из многодетных малообеспеченных семей".
IF OBJECT_ID('tempdb..#JKU_MSP')                            IS NOT NULL BEGIN DROP TABLE #JKU_MSP                           END --Таблица действующий назначений на данный момент "Компенсация расходов на коммунальные услуги (регион.)".


------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #ALIVE_PEOPLE (
    PERSONOUID  INT,    --Идентификатор личного дела.
    SEX         INT,    --Пол.
)
--CREATE TABLE #HUSBAND_AND_WIFE (
--    HUSBAND_OUID    INT,    --Личное дело мужа.
--    WIFE_OUID       INT,    --Личное дело жены.
--)
CREATE TABLE #HUSBAND_AND_WIFE (
    PERSONOUID_1        INT,    --Личное дело.
    PERSONOUID_2        INT,    --Личное дело родственника.
    RELATIONSHIP_TYPE   INT,    --Родсвтенная связь.
)
CREATE TABLE #PEOPLE_WHO_HAVE_PETITION_ON_DOC(
    PETITION_OUID       INT,    --ID заявления.
    PERSONOUID          INT,    --Личное дело заявителя.
    PETITION_DATE_REG   DATE,   --Дата регистрации заявления.
)
CREATE TABLE #MANY_CHILDREN_DOC (
    DOC_OUID        INT,            --ID документа.
    DOC_START_DATE  DATE,           --Дата начала действия документа.
    DOC_END_DATE    DATE,           --Дата окончания действия документа.
    PERSONOUID      INT,            --ID личного дела держателя документа.   
    NUMBER          VARCHAR(100)    --Номер документа.
)
CREATE TABLE #MANY_CHILDREN_MSP (
    SERV_OUID       INT,    --ID назначения.
    SERV_START_DATE DATE,   --Дата начала предоставления МСП.
    SERV_END_DATE   DATE,   --Дата окончания предоставления МСП.
    PERSONOUID      INT,    --ID личного дела льготодержателя.
    CHILD_OUID      INT     --Лицо, на основании которого... 
)
CREATE TABLE #JKU_MSP (
    SERV_OUID       INT,    --ID назначения.
    SERV_START_DATE DATE,   --Дата начала предоставления МСП.
    SERV_END_DATE   DATE,   --Дата окончания предоставления МСП.
    PERSONOUID      INT,    --ID личного дела льготодержателя.
)



------------------------------------------------------------------------------------------------------------------------------


--Выборка действующих личных дел живых людей.
INSERT INTO #ALIVE_PEOPLE (PERSONOUID, SEX)
SELECT 
    personalCard.OUID   AS PERSONOUID,
    personalCard.A_SEX  AS SEX
FROM WM_PERSONAL_CARD personalCard          --Личное дело гражданина.
WHERE personalCard.A_STATUS = 10            --Статус в БД "Действует".
    AND personalCard.A_PCSTATUS = 1         --Действующее личное дело.
    AND personalCard.A_DEATHDATE IS NULL    --Отсутствует дата смерти.
    
    
------------------------------------------------------------------------------------------------------------------------------

/*
--Выборка мужа и жены.
INSERT INTO #HUSBAND_AND_WIFE (HUSBAND_OUID, WIFE_OUID)
--МУЖ -> ЖЕНА.
SELECT 
    alivePeople1.PERSONOUID  AS HUSBAND_OUID,
    alivePeople2.PERSONOUID  AS WIFE_OUID
FROM WM_RELATEDRELATIONSHIPS relationships --Родственные связи.
----Действующее личное дело живого человека.
    INNER JOIN #ALIVE_PEOPLE alivePeople1
        ON alivePeople1.PERSONOUID = relationships.A_ID1    --Связка с родственной связью.
            AND alivePeople1.SEX = 1                        --Мужчна.
----Действующее личное дело живого человека.
    INNER JOIN #ALIVE_PEOPLE alivePeople2
        ON alivePeople2.PERSONOUID = relationships.A_ID2    --Связка с родственной связью.
            AND alivePeople2.SEX = 2                        --Женщина.      
WHERE relationShips.A_STATUS = 10                   --Статус в БД "Действует".
    AND relationships.A_RELATED_RELATIONSHIP = 8    --2 человек относительно первого является женой.
UNION
--ЖЕНА -> МУЖ (На всякий случай, вдруг у одного указана родственная связь, а у другого нет).
SELECT 
    alivePeople2.PERSONOUID  AS HUSBAND_OUID,
    alivePeople1.PERSONOUID  AS WIFE_OUID
FROM WM_RELATEDRELATIONSHIPS relationships --Родственные связи.
----Действующее личное дело живого человека.
    INNER JOIN #ALIVE_PEOPLE alivePeople1
        ON alivePeople1.PERSONOUID = relationships.A_ID1    --Связка с родственной связью.
            AND alivePeople1.SEX = 2                        --Женщина.  
----Действующее личное дело живого человека.
    INNER JOIN #ALIVE_PEOPLE alivePeople2
        ON alivePeople2.PERSONOUID = relationships.A_ID2    --Связка с родственной связью.
            AND alivePeople2.SEX = 1                        --Мужчна.    
WHERE relationShips.A_STATUS = 10                   --Статус в БД "Действует".
    AND relationships.A_RELATED_RELATIONSHIP = 9    --2 человек относительно первого является мужем.
*/
INSERT INTO #HUSBAND_AND_WIFE (PERSONOUID_1, PERSONOUID_2, RELATIONSHIP_TYPE)
SELECT 
    alivePeople1.PERSONOUID                 AS PERSONOUID_1,
    alivePeople2.PERSONOUID                 AS PERSONOUID_2,
    relationships.A_RELATED_RELATIONSHIP    AS RELATIONSHIP_TYPE
FROM WM_RELATEDRELATIONSHIPS relationships --Родственные связи.
----Действующее личное дело живого человека.
    INNER JOIN #ALIVE_PEOPLE alivePeople1
        ON alivePeople1.PERSONOUID = relationships.A_ID1    --Связка с родственной связью.
----Действующее личное дело живого человека.
    INNER JOIN #ALIVE_PEOPLE alivePeople2
        ON alivePeople2.PERSONOUID = relationships.A_ID2    --Связка с родственной связью. 
WHERE relationShips.A_STATUS = 10                       --Статус в БД "Действует".
    AND relationships.A_RELATED_RELATIONSHIP IN (8, 9)  --Муж или жена.
    
------------------------------------------------------------------------------------------------------------------------------


--Выборка людей, которые имеют заявление на МСП "Удостоверение многодетной малообеспеченной семьи" и "Продление удостоверения многодетной малообеспеченной семьи".
INSERT #PEOPLE_WHO_HAVE_PETITION_ON_DOC(PETITION_OUID, PERSONOUID, PETITION_DATE_REG)
SELECT 
    petition.OUID                       AS PETITION_OUID,
    personalCard.PERSONOUID             AS PERSONOUID,
    CONVERT(DATE, appeal.A_DATE_REG)    AS PETITION_DATE_REG
FROM WM_PETITION petition --Заявления.
----Обращение гражданина.	
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID  --Связка с заявленеим.
            AND appeal.A_STATUS = 10    --Статус в БД "Действует".
----Действующее личное дело живого человека.
    INNER JOIN #ALIVE_PEOPLE personalCard
        ON personalCard.PERSONOUID = petition.A_MSPHOLDER --Связка с заявлением.  
WHERE petition.A_MSP IN (913, 963) --Заявленеи на МСП "Удостоверение многодетной малообеспеченной семьи" и "Продление удостоверения многодетной малообеспеченной семьи".
 	
 																																													
------------------------------------------------------------------------------------------------------------------------------


--Выборка действующих документов на данный момент "Удостоверение многодетной малообеспеченной семьи".
INSERT #MANY_CHILDREN_DOC(DOC_OUID, DOC_START_DATE, DOC_END_DATE, PERSONOUID, NUMBER)
SELECT
    t.DOC_OUID,
    t.DOC_START_DATE,
    t.DOC_END_DATE,
    t.PERSONOUID,
    t.NUMBER
FROM (
    SELECT
        actDocuments.OUID                                   AS DOC_OUID,
        CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE)     AS DOC_START_DATE,
        CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)   AS DOC_END_DATE,
        personalCard.PERSONOUID                             AS PERSONOUID,
        actDocuments.DOCUMENTSNUMBER                        AS NUMBER
    FROM WM_ACTDOCUMENTS actDocuments --Действующие документы.
    ----Действующее личное дело живого человека.
        INNER JOIN #ALIVE_PEOPLE personalCard
            ON personalCard.PERSONOUID = actDocuments.PERSONOUID --Связка с документом.
    WHERE actDocuments.A_STATUS = 10            --Статус в БД "Действует".
        AND actDocuments.DOCUMENTSTYPE = 2858   --Удостоверение многодетной малообеспеченной семьи.
        AND actDocuments.A_DOCSTATUS = 1        --Действующий документ.
) t
    WHERE CONVERT(DATE, GETDATE()) BETWEEN DOC_START_DATE AND DOC_END_DATE      --На данный момент действует.
        OR CONVERT(DATE, GETDATE()) >= DOC_START_DATE AND DOC_END_DATE IS NULL  --На данный момент действует.


--------------------------------------------------------------------------------------------------------------------------------


--Выборка действующих МСП на данный момент "Ежемесячная социальная выплата на детей из многодетных малообеспеченных семей".
INSERT #MANY_CHILDREN_MSP (SERV_OUID, SERV_START_DATE, SERV_END_DATE, PERSONOUID, CHILD_OUID)
SELECT
    t.SERV_OUID,
    t.SERV_START_DATE,
    t.SERV_END_DATE,
    t.PERSONOUID,
    t.CHILD_OUID
FROM (
    SELECT 
        servServ.OUID                           AS SERV_OUID,
        CONVERT(DATE, periodServ.STARTDATE)     AS SERV_START_DATE,   
        CONVERT(DATE, periodServ.A_LASTDATE)    AS SERV_END_DATE,     
        personalCardHolder.PERSONOUID           AS PERSONOUID,
        personalCardChild.PERSONOUID            AS CHILD_OUID
    FROM ESRN_SERV_SERV servServ --Назначения МСП. 
    ----Период предоставления МСП. 
            INNER JOIN SPR_SERV_PERIOD periodServ 
            ON periodServ.A_STATUS = 10                 --Статус в БД "Действует".
                AND periodServ.A_SERV = servServ.OUID   --Связка с назначением.
    -----Личное дело льготодержателя.
        INNER JOIN #ALIVE_PEOPLE personalCardHolder 
            ON personalCardHolder.PERSONOUID = servServ.A_PERSONOUID     --Связка с назначением.
    ----Лицо, на основании данных ЛД которого сделано назначение.
        INNER JOIN #ALIVE_PEOPLE personalCardChild
            ON personalCardChild.PERSONOUID = servServ.A_CHILD --Связка с назначением.
    WHERE servServ.A_STATUS = 10    --Статус в БД "Действует".
        AND servServ.A_SK_MSP = 976 --Ежемесячная социальная выплата на детей из многодетных малообеспеченных семей.
) t
    WHERE CONVERT(DATE, GETDATE()) BETWEEN SERV_START_DATE AND SERV_END_DATE      --На данный момент действует.
        OR CONVERT(DATE, GETDATE()) >= SERV_START_DATE AND SERV_END_DATE IS NULL  --На данный момент действует.


--------------------------------------------------------------------------------------------------------------------------------


--Выборка действующих МСП на данный момент "Компенсация расходов на коммунальные услуги (регион.)".
INSERT #JKU_MSP (SERV_OUID, SERV_START_DATE, SERV_END_DATE, PERSONOUID)
SELECT
    t.SERV_OUID,
    t.SERV_START_DATE,
    t.SERV_END_DATE,
    t.PERSONOUID
FROM (
    SELECT 
        servServ.OUID                           AS SERV_OUID,
        CONVERT(DATE, periodServ.STARTDATE)     AS SERV_START_DATE,   
        CONVERT(DATE, periodServ.A_LASTDATE)    AS SERV_END_DATE,     
        personalCardHolder.PERSONOUID           AS PERSONOUID
    FROM ESRN_SERV_SERV servServ --Назначения МСП. 
    ----Период предоставления МСП. 
            INNER JOIN SPR_SERV_PERIOD periodServ 
            ON periodServ.A_STATUS = 10                 --Статус в БД "Действует".
                AND periodServ.A_SERV = servServ.OUID   --Связка с назначением.
    -----Личное дело льготодержателя.
        INNER JOIN #ALIVE_PEOPLE personalCardHolder 
            ON personalCardHolder.PERSONOUID = servServ.A_PERSONOUID     --Связка с назначением.
    WHERE servServ.A_STATUS = 10            --Статус в БД "Действует".
        AND servServ.A_STATUSPRIVELEGE = 13 --Статус назначения "Утверждено".
        AND servServ.A_SK_MSP = 916         --Компенсация расходов на коммунальные услуги (регион.).
        AND servServ.A_SK_LK = 2478         --Льготная категория "Многодетная малообеспеченная семья".
) t
    WHERE CONVERT(DATE, GETDATE()) BETWEEN SERV_START_DATE AND SERV_END_DATE      --На данный момент действует.
        OR CONVERT(DATE, GETDATE()) >= SERV_START_DATE AND SERV_END_DATE IS NULL  --На данный момент действует.


------------------------------------------------------------------------------------------------------------------------------


--Финальная выборка.
SELECT 
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    personalCard.OUID                                                       AS [№ ЛД льготодержателя],
    RTRIM(ISNULL(ISNULL(personalCard.A_SURNAME_STR, fioSurname.A_NAME), '')     + ' ' + 
        ISNULL(ISNULL(personalCard.A_NAME_STR, fioName.A_NAME), '')             + ' ' +   
        ISNULL(ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME), '')
    )                                                                       AS [ФИО льготодержателя],
    petitionOnDoc.PETITION_DATE_REG                                         AS [Дата регистрации заявления],
    manyChildDOC.NUMBER                                                     AS [№ УММС],
    CONVERT(VARCHAR, manyChildDOC.DOC_START_DATE, 104) + ' - ' + 
        ISNULL(CONVERT(VARCHAR, manyChildDOC.DOC_END_DATE, 104), '')        AS [Период УММС льготодержателя],
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    personalCard2.OUID                                                      AS [№ ЛД супруга],
    RTRIM(ISNULL(ISNULL(personalCard2.A_SURNAME_STR, fioSurname2.A_NAME), '')     + ' ' + 
        ISNULL(ISNULL(personalCard2.A_NAME_STR, fioName2.A_NAME), '')             + ' ' +   
        ISNULL(ISNULL(personalCard2.A_SECONDNAME_STR, fioSecondname2.A_NAME), '')
    )                                                                       AS [ФИО супруга],
    osznDepartament.A_SHORT_TITLE                                           AS [ОСЗН владелец],
    manyChildDOC2.NUMBER                                                    AS [№ УММС у супруга],
    CONVERT(VARCHAR, manyChildDOC2.DOC_START_DATE, 104) + ' - ' + 
        ISNULL(CONVERT(VARCHAR, manyChildDOC2.DOC_END_DATE, 104), '')       AS [Период в УММС у супруга],
    jkuMSP.SERV_OUID                                                        AS [Назначенные компенсации на коммун.услуги],
    CONVERT(VARCHAR, jkuMSP.SERV_START_DATE, 104) + ' - ' + 
        CONVERT(VARCHAR, jkuMSP.SERV_END_DATE, 104)                         AS [Период назначения]
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
FROM #PEOPLE_WHO_HAVE_PETITION_ON_DOC petitionOnDoc --Заявление на документ.
----Документ.
    INNER JOIN #MANY_CHILDREN_DOC manyChildDOC
        ON manyChildDOC.PERSONOUID  = petitionOnDOC.PERSONOUID                                                                              --Связка с заявлением.
            AND manyChildDOC.DOC_START_DATE BETWEEN petitionOnDOC.PETITION_DATE_REG AND DATEADD(DAY, 15, petitionOnDOC.PETITION_DATE_REG)   --Документ вблизи с заявлением.
--Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = petitionOnDoc.PERSONOUID  --Связка с назначением.
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME --Связка с личным делом. 
--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
----Муж/Жена.
    INNER JOIN #HUSBAND_AND_WIFE relationship
        ON relationship.PERSONOUID_1 = personalCard.OUID
--Личное дело родственника.
    INNER JOIN WM_PERSONAL_CARD personalCard2 
        ON personalCard2.OUID = relationship.PERSONOUID_2  --Связка с родственником.
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname2
        ON fioSurname2.OUID = personalCard2.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName2
        ON fioName2.OUID = personalCard2.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname2
        ON fioSecondname2.OUID = personalCard2.A_SECONDNAME --Связка с личным делом.  
----Документ у родственника.
    INNER JOIN #MANY_CHILDREN_DOC manyChildDOC2
        ON manyChildDOC2.PERSONOUID  = personalCard2.OUID --Связка с личным делом. 
----Назначение на "Компенсация расходов на коммунальные услуги (регион.)".
    LEFT JOIN #JKU_MSP jkuMSP
        ON jkuMSP.PERSONOUID = personalCard2.OUID --Связка с личным делом. 
----ОСВЗ владелец.
    LEFT JOIN ESRN_OSZN_DEP osznDepartament
        ON osznDepartament.OUID = personalCard2.A_REG_ORGNAME --Связка с личным делом.