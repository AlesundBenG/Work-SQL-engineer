------------------------------------------------------------------------------------------------------------------------------


--Начало периода отчета.
DECLARE @startDateReport DATE
SET @startDateReport = CONVERT(DATE, '01-01-2020')

--Конец периода отчета.
DECLARE @endDateReport DATE
SET @endDateReport = CONVERT(DATE, '31-12-2020')


------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL BEGIN DROP TABLE #RESULT END 


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #RESULT (
    REHABILITATION_OUID         INT,    --Идентификатор реабилитационного мероприятия по заболеванию.  
    PERSONOUID                  INT,    --Идентификатор личного дела.
    REHABILITATION_START_DATE   DATE,   --Дата начала мероприятий..
    REHABILITATION_END_DATE     DATE,   --Дата окончания мероприятий.
    EVENT_TYPE                  INT,    --Тип мероприятия.
    SOC_SERV_OUID               INT,    --Идентификатор назначения социального обслуживания.
    SOC_SERV_START_DATE         DATE,   --Дата начала социального обслуживания.
    SOC_SERV_END_DATE           DATE,   --Дата окончания социального обслуживания.
    SOC_SERV_FORM               INT,    --Форма социального обслуживания.
    ORGANIZATION                INT     --Организация предоставления социального обслуживания.
)


------------------------------------------------------------------------------------------------------------------------------


--Сбор данных.
INSERT INTO #RESULT (REHABILITATION_OUID, PERSONOUID, REHABILITATION_START_DATE, REHABILITATION_END_DATE, EVENT_TYPE, SOC_SERV_OUID, SOC_SERV_START_DATE, SOC_SERV_END_DATE, SOC_SERV_FORM, ORGANIZATION)
SELECT 
    rehabilitation.OUID                         AS REHABILITATION_OUID,
    rehabilitation.A_PERSONOUID                 AS PERSONOUID,
    CONVERT(DATE, rehabilitation.A_DATE_START)  AS REHABILITATION_START_DATE,
    CONVERT(DATE, rehabilitation.A_DATE_END)    AS REHABILITATION_END_DATE,
    socialRehabilitation.A_RHB_TYPE             AS EVENT_TYPE,
    socServ.OUID                                AS SOC_SERV_OUID,
    CONVERT(DATE, period.STARTDATE)             AS SOC_SERV_START_DATE,
    CONVERT(DATE, period.A_LASTDATE)            AS SOC_SERV_END_DATE,
    individProgram.A_FORM_SOCSERV               AS SOC_SERV_FORM,
    socServ.A_ORGNAME                           AS ORGANIZATION
FROM WM_REH_REFERENCE rehabilitation --Реабилитационные мероприятия по заболеванию.
----Мероприятие социальной реабилитации.
    INNER JOIN WM_SOCIAL_REHABILITATION socialRehabilitation
        ON socialRehabilitation.A_REHAB_REF = rehabilitation.OUID
            AND socialRehabilitation.A_STATUS = 10                  --Статус в БД "Действует".
            AND socialRehabilitation.A_STATUS_EVENT_IPRA IS NULL    --Статус мероприятия ИПРА пустой.
----Назначение социального обслуживания.
    INNER JOIN ESRN_SOC_SERV socServ
        ON socServ.A_PERSONOUID = rehabilitation.A_PERSONOUID 
            AND socServ.A_STATUS = 10   --Статус в БД "Действует".
----Период предоставления МСП.        
    INNER JOIN SPR_SOCSERV_PERIOD period
        ON period.A_SERV = socServ.OUID  
            AND period.A_STATUS = 10 --Статус в БД "Действует".
            AND CONVERT(DATE, period.STARTDATE) <= @endDateReport --Начало периода не выходит за конец отчета.
            AND CONVERT(DATE, ISNULL(period.A_LASTDATE, '31-12-3000')) >= @startDateReport --Конец периода выходит за начало отчета.
            AND (CONVERT(DATE, period.STARTDATE) BETWEEN CONVERT(DATE, rehabilitation.A_DATE_START) AND CONVERT(DATE, ISNULL(rehabilitation.A_DATE_END, '31-12-3000'))      --Начало лежит в интервале мероприятий.
                OR CONVERT(DATE, period.A_LASTDATE) BETWEEN CONVERT(DATE, rehabilitation.A_DATE_START) AND CONVERT(DATE, ISNULL(rehabilitation.A_DATE_END, '31-12-3000'))   --Или конец лежит в интервале мероприятий.
            )
----Индивидуальная программа.
    INNER JOIN INDIVID_PROGRAM individProgram
        ON individProgram.A_OUID = socServ.A_IPPSU 
WHERE rehabilitation.A_STATUS = 10 --Статус в БД "Действует".
    AND rehabilitation.A_TYPE_IPRA = 'IPRA_child' --Дети инвалиды.
    AND CONVERT(DATE, rehabilitation.A_DATE_START) <= @endDateReport --Начало периода не выходит за конец отчета.
    AND CONVERT(DATE, ISNULL(rehabilitation.A_DATE_END, '31-12-3000')) >= @startDateReport --Конец периода выходит за начало отчета.
ORDER BY rehabilitation.OUID, socServ.OUID


------------------------------------------------------------------------------------------------------------------------------

/*
--Общий список назначений.
SELECT DISTINCT
    result.PERSONOUID                   AS [ЛД],  
    result.REHABILITATION_START_DATE    AS [Начало реабилитации],
    result.REHABILITATION_END_DATE      AS [Конец реабилитации],
    result.SOC_SERV_START_DATE          AS [Начало СО],
    result.SOC_SERV_END_DATE            AS [Конец СО],
    typeEvent.A_NAME                    AS [Тип мероприятия],
    formSocServ.A_NAME                  AS [Форма СО],
    organization.A_NAME1                AS [Организация]
FROM #RESULT result
----Справочник типов мероприятий реабилитации.
    INNER JOIN SPR_TYPE_REHUB_EVENT typeEvent
        ON typeEvent.A_OUID = result.EVENT_TYPE
----Форма социального обслуживания.
    INNER JOIN SPR_FORM_SOCSERV formSocServ
        ON formSocServ.A_OUID = result.SOC_SERV_FORM
----Органы социальной защиты.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = result.ORGANIZATION


------------------------------------------------------------------------------------------------------------------------------      
 

--Информация о численности людей.
SELECT
    typeEvent.A_NAME        AS [Тип мероприятия],
    formSocServ.A_NAME      AS [Форма СО],
    COUNT(*)                AS [Количество людей]
FROM (SELECT DISTINCT PERSONOUID, EVENT_TYPE, SOC_SERV_FORM FROM #RESULT result) result
----Справочник типов мероприятий реабилитации.
    INNER JOIN SPR_TYPE_REHUB_EVENT typeEvent
        ON typeEvent.A_OUID = result.EVENT_TYPE
----Форма социального обслуживания.
    INNER JOIN SPR_FORM_SOCSERV formSocServ
        ON formSocServ.A_OUID = result.SOC_SERV_FORM 
GROUP BY typeEvent.A_NAME, formSocServ.A_NAME
ORDER BY typeEvent.A_NAME, formSocServ.A_NAME


------------------------------------------------------------------------------------------------------------------------------


--Информация о количестве оказанных услуг.
SELECT
    formSocServ.A_NAME                  AS [Форма СО],
    organization.A_NAME1                AS [Организация],
    SUM(countMonth.A_SOC_SERV_MONTH)    AS [Количество услуг]
FROM (SELECT DISTINCT PERSONOUID, SOC_SERV_OUID, SOC_SERV_FORM, ORGANIZATION FROM #RESULT result) result
----Форма социального обслуживания.
    INNER JOIN SPR_FORM_SOCSERV formSocServ
        ON formSocServ.A_OUID = result.SOC_SERV_FORM 
----Органы социальной защиты.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = result.ORGANIZATION
----Агрегация по социальной услуге. 
    INNER JOIN WM_SOC_SERV_AGR agregation
        ON agregation.ESRN_SOC_SERV = result.SOC_SERV_OUID
            AND agregation.A_STATUS = 10
----Стоимость социальных услуг за месяц.
    INNER JOIN WM_COST_SOC_SERV_MONTH countMonth
        ON countMonth.A_AGR_SOC_SERV = agregation.A_ID
            AND countMonth.A_STATUS = 10
            AND (YEAR(@startDateReport) <> YEAR(@endDateReport)             --Если отчет за несколько лет, и если...
                AND (countMonth.A_YEAR = YEAR(@startDateReport)            --Год оказания услуги лежит в начале периода и...
                        AND countMonth.A_MONTH >= MONTH(@startDateReport)  --...месяц оказания услуги больше месяца начала отчета или...
                    OR countMonth.A_YEAR = YEAR(@endDateReport)            --...год оказания услуги лежит в конце периода и...
                        AND countMonth.A_MONTH <= MONTH(@endDateReport)    --...месяц оказания услуги меньше месяца конца отчета или...
                    OR countMonth.A_YEAR > YEAR(@startDateReport)          --...год оказания услуги строго больше года начала отчета и... 
                        AND countMonth.A_YEAR < YEAR(@endDateReport)       --...год оказания услуги строго меньше года конца отчета.
                )
                OR YEAR(@startDateReport) = YEAR(@endDateReport)            --Если отчет за один год и...
                    AND countMonth.A_YEAR = YEAR(@startDateReport)         --...год оказания услуги лежит в периоде отчета и...
                    AND countMonth.A_MONTH BETWEEN MONTH(@startDateReport) AND MONTH(@endDateReport) --...месяц лежит в периоде отчета.
            )  
----Тарифы на социальные услуги.
    INNER JOIN SPR_TARIF_SOC_SERV tarif
        ON tarif.A_ID = agregation.A_SOC_SERV
            AND tarif.A_SOC_SERV IN (
                --2697,   --1.5.01. Содействие в проведении социально-реабилитационных мероприятий в соответствии с индивидуальными программами реабилитации или абилитации инвалидов, в том числе детей-инвалидов.
                --2735,   --2.5.01. Услуги, связанные с социально-трудовой реабилитацией.
                --3144,    --3.5.01. Услуги, связанные с социально-трудовой реабилитацией.
                2697,   --1.5.01. Содействие в проведении социально-реабилитационных мероприятий в соответствии с индивидуальными программами реабилитации или абилитации инвалидов, в том числе детей-инвалидов
                2745,   --2.7.02. Проведение социально-реабилитационных мероприятий в соответствии с индивидуальными программами реабилитации или абилитации инвалидов, в том числе детей-инвалидов
                2795    --3.7.03. Проведение социально-реабилитационных мероприятий в соответствии с индивидуальными программами реабилитации или абилитации инвалидов, в том числе детей-инвалидов
            )
GROUP BY formSocServ.A_NAME, organization.A_NAME1 
ORDER BY formSocServ.A_NAME, organization.A_NAME1 


------------------------------------------------------------------------------------------------------------------------------


--Информация о численности организаций.
SELECT 
    formSocServ.A_NAME  AS SOC_SERV_FORM,
    COUNT(*)            AS COUNT
FROM (SELECT DISTINCT SOC_SERV_FORM, ORGANIZATION FROM #RESULT result) result
----Форма социального обслуживания.
    INNER JOIN SPR_FORM_SOCSERV formSocServ
        ON formSocServ.A_OUID = result.SOC_SERV_FORM 
GROUP BY formSocServ.A_NAME
ORDER BY formSocServ.A_NAME


------------------------------------------------------------------------------------------------------------------------------

SELECT
    formSocServ.A_NAME      AS [Форма СО],
    organization.A_NAME1    AS [Организация],
    COUNT(*)                AS [Количество людей]
FROM (SELECT DISTINCT PERSONOUID, SOC_SERV_FORM, ORGANIZATION FROM #RESULT result) result
----Форма социального обслуживания.
    INNER JOIN SPR_FORM_SOCSERV formSocServ
        ON formSocServ.A_OUID = result.SOC_SERV_FORM 
----Органы социальной защиты.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = result.ORGANIZATION 
GROUP BY formSocServ.A_NAME, organization.A_NAME1
ORDER BY formSocServ.A_NAME, organization.A_NAME1
*/

------------------------------------------------------------------------------------------------------------------------------



SELECT
*
FROM #RESULT result
----Справочник типов мероприятий реабилитации.
    INNER JOIN SPR_TYPE_REHUB_EVENT typeEvent
        ON typeEvent.A_OUID = result.EVENT_TYPE
----Форма социального обслуживания.
    INNER JOIN SPR_FORM_SOCSERV formSocServ
        ON formSocServ.A_OUID = result.SOC_SERV_FORM
----Органы социальной защиты.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = result.ORGANIZATION