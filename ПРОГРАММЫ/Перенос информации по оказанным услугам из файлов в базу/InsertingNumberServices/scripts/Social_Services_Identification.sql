-------------------------------------------------------------------------------------------------------------------------------
--Период, за который предоставляются сведения.
DECLARE @yearReport INT SET @yearReport = #yearReport#
DECLARE @monthReport INT SET @monthReport = (SELECT A_CODE FROM SPR_MONTH WHERE A_NAME = '#monthReport#' OR CONVERT(VARCHAR, A_CODE) = '#monthReport#')
--Данные об индивидуальной программе получателя социальных услуг (ИППСУ).
DECLARE @dateRegistration VARCHAR(256) SET @dateRegistration = '#dateRegistration#' --Дата оформления.
DECLARE @numberDocument VARCHAR(256) SET @numberDocument = '#numberDocument#' --Номер документа.
DECLARE @formSocServ VARCHAR(256) SET @formSocServ = '#formSocServ#' --Форма социального обслуживания.
-------------------------------------------------------------------------------------------------------------------------------
--Выбор назначений на социальной обслуживание.
SELECT 
 socServ.OUID AS SOC_SERV_OUID,
 personalCard.OUID AS PERSONAL_CARD_OUID,
 personalCard.A_TITLE AS PERSONAL_CARD_TITLE,
 formSocServ.A_NAME AS SOC_SERV_FORM,
 organization.A_NAME1 AS ORGANIZATION,
 departament.A_NAME1 AS DEPARTAMENT,
 CONVERT(VARCHAR, period.STARTDATE) AS SOC_SERV_START_DATE,
 CONVERT(VARCHAR, period.A_LASTDATE) AS SOC_SERV_END_DATE, 
 statusServ.A_NAME AS SOC_SERV_STATUS
FROM ESRN_SOC_SERV socServ --Назначение социального обслуживания.
----Период предоставления МСП.        
 INNER JOIN SPR_SOCSERV_PERIOD period
  ON period.A_STATUS = 10 --Статус в БД "Действует".
   AND period.A_SERV = socServ.OUID --Связка с назначением.   
   AND @yearReport BETWEEN YEAR(period.STARTDATE) AND YEAR(period.A_LASTDATE) --Год отчета входит в период действия назначения.
   AND (@yearReport <> YEAR(period.STARTDATE) AND @yearReport <> YEAR(period.A_LASTDATE) --Год отчета не равен крайнему.
    OR @yearReport = YEAR(period.STARTDATE) AND @monthReport >= MONTH(period.STARTDATE) --Или равен начальному, но месяц позже начала.
    OR @yearReport = YEAR(period.A_LASTDATE) AND @monthReport <= MONTH(period.A_LASTDATE) --Или равен конечному, но месяц раньше конца.
   )
----Индивидуальная программа.
 INNER JOIN INDIVID_PROGRAM individProgram
  ON individProgram.A_OUID = socServ.A_IPPSU
   AND individProgram.A_STATUS = 10 --Статус индивидуальной программы в БД "Действует".
----Действующие документы.
 INNER JOIN WM_ACTDOCUMENTS actDocuments
  ON actDocuments.OUID = individProgram.A_DOC
   AND actDocuments.A_STATUS = 10 --Статус документа в БД "Действует".
   AND actDocuments.DOCUMENTSNUMBER = @numberDocument --Номер документа совпадает с требуемым.
----Личное дело льготодержателя.
 INNER JOIN WM_PERSONAL_CARD personalCard
  ON personalCard.OUID = socServ.A_PERSONOUID
   AND personalCard.A_STATUS = 10 --Статус ЛД в БД "Действует".
----Форма социального обслуживания.
 INNER JOIN SPR_FORM_SOCSERV formSocServ
  ON formSocServ.A_OUID = individProgram.A_FORM_SOCSERV
   AND formSocServ.A_NAME = @formSocServ --Совпадает с формой отчета.
----Органы социальной защиты.
 INNER JOIN SPR_ORG_BASE organization
  ON organization.OUID = socServ.A_ORGNAME
----Департамент.
 INNER JOIN SPR_ORG_BASE departament
  ON departament.OUID = socServ.A_DEPNAME
----Статус назначения.
 INNER JOIN SPR_STATUS_PROCESS statusServ 
  ON statusServ.A_ID = socServ.A_STATUSPRIVELEGE
WHERE socServ.A_STATUS = 10 --Статус назначения в БД "Действует".
-------------------------------------------------------------------------------------------------------------------------------