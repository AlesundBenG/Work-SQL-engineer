-------------------------------------------------------------------------------------------------------------------------------
--Информация о получателе.
DECLARE @name VARCHAR(256) SET @name = '#name#' --Имя.
DECLARE @SNILS VARCHAR(256) SET @SNILS = '#SNILS#' --СНИЛС.
DECLARE @surname VARCHAR(256) SET @surname = '#surname#' --Фамилия.
DECLARE @birthdate VARCHAR(256) SET @birthdate = '#birthdate#' --День рождения.
DECLARE @secondname VARCHAR(256) SET @secondname = '#secondname#' --Отчество.
--Документ, удостоверяющий личность.
DECLARE @typeDocument VARCHAR(256) SET @typeDocument = '#typeDocument#' --Вид удостоверяющего документа.
DECLARE @seriesDocument VARCHAR(256) SET @seriesDocument = '#seriesDocument#' --Серия документа.
DECLARE @numberDocument VARCHAR(256) SET @numberDocument = '#numberDocument#' --Номер документа.
DECLARE @dateIssueDocument VARCHAR(256) SET @dateIssueDocument = '#dateIssueDocument#' --Дата выдачи документа.
DECLARE @organizationDocument VARCHAR(256) SET @organizationDocument = '#organizationDocument#' --Организация, выдавшая документ.
-------------------------------------------------------------------------------------------------------------------------------
--Учитывать информацию о получателе.
DECLARE @considerName INT SET @considerName = #considerName# --Учитывать имя.
DECLARE @considerSNILS INT SET @considerSNILS = #considerSNILS# --Учитывать СНИЛС.
DECLARE @considerSurname INT SET @considerSurname = #considerSurname# --Учитывать фамилию.
DECLARE @considerBirthdate INT SET @considerBirthdate = #considerBirthdate# --Учитывать день рождения.
DECLARE @considerSecondname INT SET @considerSecondname = #considerSecondname# --Учитывать отчество.
--Учитывать документ, удостоверяющий личность.
DECLARE @considerDocument INT SET @considerDocument = #considerDocument# --Учитывать документ в принципе.
DECLARE @considerTypeDocument INT SET @considerTypeDocument = #considerTypeDocument# --Учитывать вид удостоверяющего документа.
DECLARE @considerSeriesDocument INT SET @considerSeriesDocument = #considerSeriesDocument# --Учитывать серию документа.
DECLARE @considerNumberDocument INT SET @considerNumberDocument = #considerNumberDocument# --Учитывать номер документа.
DECLARE @considerDateIssueDocument INT SET @considerDateIssueDocument = #considerDateIssueDocument# --Учитывать дату выдачи документа.
DECLARE @considerOrganizationDocument INT SET @considerOrganizationDocument = #considerOrganizationDocument# --Учитывать организация, выдавшая документ.
-------------------------------------------------------------------------------------------------------------------------------
--Выбор людей, удовлетворяющих условиям.
SELECT
 personalCard.OUID AS PERSONOUID,
 ISNULL(personalCard.A_SURNAME_STR, fioSurname.A_NAME) AS SURNAME,
 ISNULL(personalCard.A_NAME_STR, fioName.A_NAME) AS NAME,
 ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS SECONDNAME,
 CONVERT(VARCHAR, personalCard.BIRTHDATE, 104) AS BIRTHDATE,
 personalCard.A_SNILS AS SNILS,
 typeDoc.A_NAME AS DOCUMENT_TYPE,
 actDocuments.DOCUMENTSERIES AS DOCUMENT_SERIES,
 actDocuments.DOCUMENTSNUMBER AS DOCUMENT_NUMBER,
 CONVERT(VARCHAR, actDocuments.ISSUEEXTENSIONSDATE, 104) AS DOCUMENT_ISSUE_DATE,
 organization.A_NAME1 AS DOCUMENT_ORGANIZATION,
 docStatus.A_NAME AS DOCUMENT_STATUS
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.
----Статус в БД.
 INNER JOIN ESRN_SERV_STATUS esrnStatusPersonalCard
  ON esrnStatusPersonalCard.A_ID = personalCard.A_STATUS
----Фамилия.
 LEFT JOIN SPR_FIO_SURNAME fioSurname
  ON fioSurname.OUID = personalCard.SURNAME
----Имя.     
 LEFT JOIN SPR_FIO_NAME fioName
  ON fioName.OUID = personalCard.A_NAME 
----Отчество.   
 LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
  ON fioSecondname.OUID = personalCard.A_SECONDNAME
----Действующие документы.    
 LEFT JOIN WM_ACTDOCUMENTS actDocuments 
  ON actDocuments.PERSONOUID = personalCard.OUID
   AND actDocuments.A_STATUS = 10 --Статус документа в БД "Действует".
----Статус документа.
 LEFT JOIN SPR_DOC_STATUS docStatus
  ON docStatus.A_OUID = actDocuments.A_DOCSTATUS --Связка с документом.
----Вид документа.
 LEFT JOIN PPR_DOC typeDoc
  ON typeDoc.A_ID = actDocuments.DOCUMENTSTYPE
   AND typeDoc.A_ISIDENTITYCARD = 1 --Документ является удостоверением личности.
----Базовый класс организаций, выдавшей документ.
 LEFT JOIN SPR_ORG_BASE organization
  ON organization.OUID = actDocuments.GIVEDOCUMENTORG 
   AND @considerDocument= 1 --Подцепляем, если нужно.
WHERE personalCard.A_STATUS = 10 --Статус личного дела в БД "Действует".
 AND personalCard.A_PCSTATUS = 1 --Статус личного дела "Действует".
 AND (personalCard.A_SNILS = @SNILS AND @considerSNILS = 1 OR @considerSNILS = 0) --СНИЛС совпадает, если нужно.
 AND (ISNULL(personalCard.A_NAME_STR, fioName.A_NAME) = @name AND @considerName = 1 OR @considerName = 0) -- Имя совпадает, если нужно.
 AND (ISNULL(personalCard.A_SURNAME_STR, fioSurname.A_NAME) = @surname AND @considerSurname = 1 OR @considerSurname = 0) --Фамилия совпадает, если нужно.
 AND (CONVERT(DATE, personalCard.BIRTHDATE) = CONVERT(DATE, @birthdate) AND @considerBirthdate = 1 OR @considerBirthdate = 0) --Дата рожденяи совпадает, если нужно.
 AND (ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) = @secondname AND @considerSecondname = 1 OR @considerSecondname = 0) --Отчество совпадает, если нужно.
 AND (@considerDocument = 0 --Не учитывается документ, или учитывается, если...
  OR (typeDoc.A_NAME = @typeDocument AND @considerDocument = 1 OR @considerDocument = 0) --Совпадает тип документа, если нужно.
  AND (actDocuments.DOCUMENTSERIES = @seriesDocument AND @considerSeriesDocument = 1 OR @considerSeriesDocument = 0) --Совпадает серия документа, если нужно.
  AND (actDocuments.DOCUMENTSNUMBER = @numberDocument AND @considerNumberDocument = 1 OR @considerNumberDocument = 0) --Совпадает номер документа, если нужно.
  AND (CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE) = CONVERT(DATE, @dateIssueDocument) AND @considerDateIssueDocument = 1 OR @considerDateIssueDocument = 0) --Совпадает дата выдачи документа, если нужно.
  AND (organization.A_NAME1 = @organizationDocument AND @considerOrganizationDocument = 1 OR @considerOrganizationDocument = 0) --Совпадает организация документа, если нужно.
)
-------------------------------------------------------------------------------------------------------------------------------