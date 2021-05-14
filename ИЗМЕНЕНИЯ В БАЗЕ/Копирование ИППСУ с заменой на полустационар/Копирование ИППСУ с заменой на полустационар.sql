--------------------------------------------------------------------------------------------------------------------------------


--Индивидуальная программа для копирования.
DECLARE @individProgramForCopy INT
SET @individProgramForCopy = 76068

--Флаг о том, что человек трудоспособного возраста.
DECLARE @workingAge INT
SET @workingAge = CASE WHEN EXISTS(
    SELECT 
        personalCard.OUID
    FROM INDIVID_PROGRAM individProgram
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.OUID = individProgram.PERSONOUID
    WHERE individProgram.A_OUID = @individProgramForCopy
        AND (personalCard.A_SEX = 1
            AND DATEDIFF(YEAR, personalCard.BIRTHDATE, GETDATE()) - CASE                                                                
                WHEN MONTH(personalCard.BIRTHDATE)  < MONTH(GETDATE())  THEN 0   
                WHEN MONTH(personalCard.BIRTHDATE)  > MONTH(GETDATE())  THEN 1   
                WHEN DAY(personalCard.BIRTHDATE)    > DAY(GETDATE())    THEN 1    
                ELSE 0                                                          
            END	BETWEEN 18 AND 64 
            OR personalCard.A_SEX = 2
            AND DATEDIFF(YEAR, personalCard.BIRTHDATE, GETDATE()) - CASE                                                                
                WHEN MONTH(personalCard.BIRTHDATE)  < MONTH(GETDATE())  THEN 0   
                WHEN MONTH(personalCard.BIRTHDATE)  > MONTH(GETDATE())  THEN 1   
                WHEN DAY(personalCard.BIRTHDATE)    > DAY(GETDATE())    THEN 1    
                ELSE 0                                                          
            END	BETWEEN 18 AND 59
        )
) THEN 1 ELSE 0 END


--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#CREATED_DOCUMENT')           IS NOT NULL BEGIN DROP TABLE #CREATED_DOCUMENT          END  --Созданный документ. 
IF OBJECT_ID('tempdb..#SERVICES_FOR_INSERT')        IS NOT NULL BEGIN DROP TABLE #SERVICES_FOR_INSERT       END  --Перечень социальных услуг.
IF OBJECT_ID('tempdb..#CREATED_INDIVID_PROGRAM')    IS NOT NULL BEGIN DROP TABLE #CREATED_INDIVID_PROGRAM   END  --Созданная индивидуальная программа.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #CREATED_DOCUMENT (
    DOCUMENT_OUID INT, --ID документа.
)
CREATE TABLE #SERVICES_FOR_INSERT (
    SERVICES_OUID INT, --ID услуги.
)
CREATE TABLE #CREATED_INDIVID_PROGRAM (
    INDIVID_PROGRAM_OUID INT, --ID индивидуальной программы.
)


--------------------------------------------------------------------------------------------------------------------------------


--Создание документа.
INSERT INTO WM_ACTDOCUMENTS (PERSONOUID, DOCUMENTSTYPE, ISSUEEXTENSIONSDATE, GIVEDOCUMENTORG, GUID, A_CREATEDATE, A_STATUS, A_DOCSTATUS, A_CROWNER)
OUTPUT inserted.OUID INTO #CREATED_DOCUMENT (DOCUMENT_OUID)
SELECT
    beforeDocument.PERSONOUID       AS PERSONOUID,  
    beforeDocument.DOCUMENTSTYPE    AS DOCUMENTSTYPE,
    GETDATE()                       AS ISSUEEXTENSIONSDATE,
    beforeDocument.GIVEDOCUMENTORG  AS GIVEDOCUMENTORG,
    NEWID()                         AS GUID,
    GETDATE()                       AS A_CREATEDATE,
    10                              AS A_STATUS,
    1                               AS A_DOCSTATUS,
    10314303                        AS A_CROWNER
FROM INDIVID_PROGRAM individProgram --Копируемая индивидуальная программа.
----Документ копируемой индивидуальной программы.
    INNER JOIN WM_ACTDOCUMENTS beforeDocument
        ON beforeDocument.OUID = individProgram.A_DOC
WHERE individProgram.A_OUID = @individProgramForCopy

--Созданный документ.
DECLARE @createdDocument INT
SET @createdDocument = (SELECT TOP 1 DOCUMENT_OUID FROM #CREATED_DOCUMENT)


--------------------------------------------------------------------------------------------------------------------------------


--Услуги, вставляемые в качестве переченя социальных услуг.
INSERT INTO #SERVICES_FOR_INSERT (SERVICES_OUID)
SELECT 
    OUID AS SERVICES_OUID
FROM SPR_SOC_SERV
WHERE OUID IN (
----1. Социально-бытовые услуги: 
    2702,	--2.1.01. Предоставление помещений для организации социально-реабилитационных и социокультурных мероприятий
    2703,	--2.1.02. Обеспечение питанием согласно утвержденным нормативам
    2704,	--2.1.03. Предоставление в пользование мебели согласно утвержденным нормативам
    2705,	--2.1.04. Обеспечение книгами, журналами, газетами, настольными играми, иным инвентарем для организации досуга
    2706,	--2.1.05. Предоставление постельных принадлежностей, спального места в специальном помещении
    2707,	--2.1.06. Стирка постельного белья, чистка одежды
    2709,	--2.1.08. Предоставление транспорта для перевозки получателей социальных услуг в медицинские организации, на обучение и для участия в социокультурных мероприятиях
    2956,	--2.1.10.01. Умывание
    2962,	--2.1.10.02. Оказание помощи при вставании с постели, укладывании в постель
    2963,	--2.1.10.03. Оказание помощи при одевании и (или) раздевании
    2964,	--2.1.10.04. Оказание помощи в пользовании туалетом
    2965,	--2.1.11. Оказание помощи в передвижении по помещению и вне помещения
----2. Социально-медицинские услуги: 
    2966,	--2.2.01. Запись на прием к врачу
    2716,	--2.2.02. Наблюдение за состоянием здоровья получателя социальных услуг
    2718,	--2.2.03. Проведение занятий с использованием методов адаптивной физической культуры
    2719,	--2.2.04. Проведение оздоровительных мероприятий, в том числе по формированию здорового образа жизни
----3. Социально-психологические услуги:
    2724,	--2.3.02. Проведение бесед, направленных на формирование у получателя социальных услуг позитивного психологического состояния, поддержание активного образа жизни
    2970,	--2.3.03. Социально-психологическая диагностика
    2971,	--2.3.04. Социально-психологическая коррекция
    2972,	--2.3.05. Социально-психологическое консультирование
    2726,	--2.3.06. Социально-психологический патронаж
----4. Социально-педагогические услуги:  
    2729,	--2.4.01. Организация досуга
    2973,	--2.4.02. Социально-педагогическая диагностика
    2974,	--2.4.03. Социально-педагогическая коррекция
    2975,	--2.4.04. Социально-педагогическое консультирование
----5. Социально-трудовые услуги:   
    2735,	--2.5.01. Услуги, связанные с социально-трудовой реабилитацией (только для инвалидов трудоспособного возраста: женщина 18-60 лет, мужчины 18-65)
----7. Услуги, предоставляемые в целях повышения коммуникативного потенциала получателей социальных услуг, имеющих ограничения жизнедеятельности, в том числе детей-инвалидов:
    2978,	--2.7.01. Обучение навыкам самообслуживания, общения и контроля, навыкам поведения в быту и общественных местах
    2745,	--2.7.02. Проведение социально-реабилитационных мероприятий в соответствии с индивидуальными программами реабилитации или абилитации инвалидов, в том числе детей-инвалидов
    2747,	--2.7.04. Оказание помощи инвалидам, в том числе детям-инвалидам, в пользовании техническими средствами реабилитации, специальными приспособлениями, приборами и оборудованием
    2749	--2.7.06. Оказание помощи в обучении навыкам компьютерной грамотности
)

--Удаляем услуги, если человек не трудоспособного возраста: женщина 18-60 лет, мужчины 18-65
DELETE FROM #SERVICES_FOR_INSERT 
WHERE SERVICES_OUID = 2735  --2.5.01. Услуги, связанные с социально-трудовой реабилитацией
    AND @workingAge = 0     --Человек не трудоспособного возраста.


--------------------------------------------------------------------------------------------------------------------------------


--Копирование индивидуальной программы.
INSERT INTO INDIVID_PROGRAM (GUID, A_CROWNER, A_STATUS, A_SYSTEMCLASS, A_CREATEDATE, A_OGR, A_FORM_SOCSERV, A_FAILURE, A_REASON, PERSONOUID, 
    A_NOTES, A_DOC, A_CONCLUSION, A_STATUSPRIVELEGE, A_PET_REG_DATE, A_PRE, 
    A_RATING_SOC_LIFE, A_RATING_SOC_MED, A_RATING_SOC_PSIH, A_RATING_SOC_PED, A_RATING_SOC_WORK, A_RATING_SOC_LAW, A_RATING_SOC_MEINTEN, A_RATING_TALK, 
    A_SUM_BALS_BARTHEL, A_SUM_BALS_LAWTON, A_ORG_TYPE, A_INVALID_GROUP, A_INV_REAS, A_STARTDATA, A_ENDDATA, A_NUM_IPPSU, A_PROTECTION, A_TOTAL_POINTS, A_DEGREE
)
OUTPUT inserted.A_OUID INTO #CREATED_INDIVID_PROGRAM (INDIVID_PROGRAM_OUID)
SELECT 
    NEWID()                     AS GUID,
    10314303                    AS A_CROWNER,
    10                          AS A_STATUS,
    10392121                    AS A_SYSTEMCLASS,
    GETDATE()                   AS A_CREATEDATE,
    individProgram.A_OGR        AS A_OGR, 
    1                           AS A_FORM_SOCSERV,
    individProgram.A_FAILURE    AS A_FAILURE,
    individProgram.A_REASON     AS A_REASON,
    individProgram.PERSONOUID   AS PERSONOUID,
    
    individProgram.A_NOTES          AS A_NOTES,
    @createdDocument                AS A_DOC, 
    individProgram.A_CONCLUSION     AS A_CONCLUSION,
    27                              AS A_STATUSPRIVELEGE,
    individProgram.A_PET_REG_DATE   AS A_PET_REG_DATE,
    individProgram.A_DOC            AS A_PRE,
    
    individProgram.A_RATING_SOC_LIFE    AS A_RATING_SOC_LIFE,
    individProgram.A_RATING_SOC_MED     AS A_RATING_SOC_MED,
    individProgram.A_RATING_SOC_PSIH    AS A_RATING_SOC_PSIH,
    individProgram.A_RATING_SOC_PED     AS A_RATING_SOC_PED,
    individProgram.A_RATING_SOC_WORK    AS A_RATING_SOC_WORK,
    individProgram.A_RATING_SOC_LAW     AS A_RATING_SOC_LAW,
    individProgram.A_RATING_SOC_MEINTEN AS A_RATING_SOC_MEINTEN,
    individProgram.A_RATING_TALK        AS A_RATING_TALK,
    
    individProgram.A_SUM_BALS_BARTHEL   AS A_SUM_BALS_BARTHEL,
    individProgram.A_SUM_BALS_LAWTON    AS A_SUM_BALS_LAWTON,
    individProgram.A_ORG_TYPE           AS A_ORG_TYPE,
    individProgram.A_INVALID_GROUP      AS A_INVALID_GROUP,
    individProgram.A_INV_REAS           AS A_INV_REAS,
    individProgram.A_STARTDATA          AS A_STARTDATA,
    individProgram.A_ENDDATA            AS A_ENDDATA,
    individProgram.A_NUM_IPPSU          AS A_NUM_IPPSU,
    individProgram.A_PROTECTION         AS A_PROTECTION,
    individProgram.A_TOTAL_POINTS       AS A_TOTAL_POINTS,
    individProgram.A_DEGREE             AS A_DEGREE
FROM INDIVID_PROGRAM individProgram
WHERE individProgram.A_OUID = @individProgramForCopy

--Созданная индивиудальная программа.
DECLARE @createdIndividProgram INT
SET @createdIndividProgram = (SELECT TOP 1 INDIVID_PROGRAM_OUID FROM #CREATED_INDIVID_PROGRAM)


--------------------------------------------------------------------------------------------------------------------------------


--Перечень рекомендуемых поставщиков услуг.
INSERT INTO LINK_INDIVIDPROGRAM_SPRORGUSON (A_FROMID, A_TOID)
SELECT
    @createdIndividProgram  AS A_FROMID,
    A_TOID
FROM LINK_INDIVIDPROGRAM_SPRORGUSON
WHERE A_FROMID = @individProgramForCopy


--------------------------------------------------------------------------------------------------------------------------------


--Обстоятельства.
INSERT INTO LINK_CAUSE_IPPSU (A_FROM_ID, A_TO_ID)
SELECT
    @createdIndividProgram  AS A_FROM_ID,
    A_TO_ID
FROM LINK_CAUSE_IPPSU
WHERE A_FROM_ID = @individProgramForCopy


--------------------------------------------------------------------------------------------------------------------------------


--Социальные услуги по индивидуальной программе.
INSERT INTO SOCSERV_INDIVDPROGRAM (GUID, A_TS, A_STATUS, A_SYSTEMCLASS, A_CREATEDATE, A_INDIVID_PROGRAM, A_SOC_SERV, A_START_DATE, A_FINISH_DATE)
SELECT 
    NEWID()                     AS GUID, 
    GETDATE()                   AS A_TS, 
    10                          AS A_STATUS, 
    10392185                    AS A_SYSTEMCLASS, 
    GETDATE()                   AS A_CREATEDATE, 
    @createdIndividProgram      AS A_INDIVID_PROGRAM, 
    socServices.OUID            AS A_SOC_SERV, 
    socServices.A_DATESTART     AS A_START_DATE, 
    socServices.A_DATEFINISH    AS A_FINISH_DATE
FROM #SERVICES_FOR_INSERT forInsert
	INNER JOIN SPR_SOC_SERV socServices 
	    ON socServices.OUID = forInsert.SERVICES_OUID


--------------------------------------------------------------------------------------------------------------------------------


--Заполнение услуг с подуслугами. (Код взять из "Обновление услуг ИП" esrn/admin/edit.htm?id=11396870@SXObjQuery)
if object_id('tempdb..#lipu') is not null drop table #lipu
if object_id('tempdb..#tmpu1') is not null drop table #tmpu1

select A_FROMID, A_TOID
into #lipu
from
(
select lipu1.A_FROMID, lipu1.A_TOID
from LINK_INDIVIDPROGRAM_SPRORGUSON lipu1
	join ESRN_OSZN_DEP e on lipu1.A_TOID = e.OUID
	join SPR_ORG_BASE sob on sob.A_STATUS = 10 and sob.OUID = e.OUID
where lipu1.A_FROMID = @createdIndividProgram and LEN(e.A_OSZNCODE) = 4
union
select lipu1.A_FROMID, e1.OUID as A_TOID
from LINK_INDIVIDPROGRAM_SPRORGUSON lipu1
	join ESRN_OSZN_DEP e on lipu1.A_TOID = e.OUID
	join SPR_ORG_BASE sob on sob.A_STATUS = 10 and sob.OUID = e.OUID
	join ESRN_OSZN_DEP e1 on e1.A_OVERHEAD = e.OUID
	join SPR_ORG_BASE sob1 on sob1.A_STATUS = 10 and sob1.OUID = e1.OUID
where lipu1.A_FROMID = @createdIndividProgram and LEN(e.A_OSZNCODE) = 3
) aaa

select distinct /*ss.A_SOC_SERV,*/ LEFT(soc.a_name, 1) as fsoc, soc.OUID, soc.A_CODE, ss.A_OUID
into #tmpu1
from (select A_FROMID, A_TOID from #lipu) lipu
	join INDIVID_PROGRAM ipr on ipr.A_OUID = lipu.A_FROMID
	join LINK_SOCSERV_USON lsu on lsu.A_ORG_USON = lipu.A_TOID and lsu.A_STATUS = 10
	join SPR_SOC_SERV soc on soc.OUID = lsu.A_SOC_SERV and soc.A_STATUS = 10
	join LINK_USON_SOC_SERV lpu on lsu.A_OUID = lpu.A_FROMID
	join SPR_SUB_SOC_SERV ss on ss.A_OUID = lpu.A_TOID and ss.A_STATUS = 10
where lipu.A_FROMID = @createdIndividProgram and
	  (lsu.A_DATE_FINISH_SERV is null or convert(date, lsu.A_DATE_FINISH_SERV) >= convert(date, GETDATE())) 
	  and (lsu.A_DATE_START_SERV is null or convert(date, lsu.A_DATE_START_SERV) <= convert(date, GETDATE()))
	  and (ss.A_FIN_DATE is null or convert(date, ss.A_FIN_DATE) >= convert(date, GETDATE())) 
	  and (ss.A_START_DATE is null or convert(date, ss.A_START_DATE) <= convert(date, GETDATE()))

insert LINK_IPPSU_SIZE (A_FROMID, A_TOID)
select ssip.A_OUID, u1.A_OUID
from #tmpu1 u1
	join SOCSERV_INDIVDPROGRAM ssip on ssip.A_INDIVID_PROGRAM = @createdIndividProgram and ssip.A_STATUS = 10 and ssip.A_SOC_SERV = u1.OUID


--------------------------------------------------------------------------------------------------------------------------------


--Ссылка.
SELECT 'http://esrn/admin/edit.htm?id=' + CONVERT(VARCHAR, @createdIndividProgram) + '@individProgram'


--------------------------------------------------------------------------------------------------------------------------------



















