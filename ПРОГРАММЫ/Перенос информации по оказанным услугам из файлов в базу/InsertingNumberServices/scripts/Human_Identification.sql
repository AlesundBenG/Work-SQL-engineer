-------------------------------------------------------------------------------------------------------------------------------

--Фамилия.
DECLARE @surname VARCHAR(256)
SET @surname = '#surname#'

--Учитывать фамилию.
DECLARE @considerSurname INT
SET @considerSurname = #considerSurname#

--Имя.
DECLARE @name VARCHAR(256)
SET @name = '#name#'

--Учитывать имя.
DECLARE @considerName INT
SET @considerName = #considerName#

--Отчество.
DECLARE @secondname VARCHAR(256)
SET @secondname = '#secondname#'

--Учитывать отчество.
DECLARE @considerSecondname INT
SET @considerSecondname = #considerSecondname#

--СНИЛС.
DECLARE @SNILS VARCHAR(256)
SET @SNILS = '#SNILS#'

--Учитывать СНИЛС.
DECLARE @considerSNILS INT
SET @considerSNILS = #considerSNILS#

--День рождения.
DECLARE @birthdate VARCHAR(256)
SET @birthdate = '#birthdate#'

--Учитывать день рождения.
DECLARE @considerBirthdate INT
SET @considerBirthdate = #considerBirthdate#


-------------------------------------------------------------------------------------------------------------------------------


--Выбор людей, удовлетворяющих условиям.
SELECT
    personalCard.OUID                                           AS PERSONOUID,
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS SURNAME,
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS NAME,
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS SECONDNAME,
    CONVERT(VARCHAR, personalCard.BIRTHDATE, 104)               AS BIRTHDATE,
    personalCard.A_SNILS                                        AS SNILS
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusPersonalCard
        ON esrnStatusPersonalCard.A_ID = personalCard.A_STATUS --Связка с личным делом.
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME --Связка с личным делом.     
WHERE personalCard.A_STATUS = 10 --Статус личного дела в БД "Действует".
    AND personalCard.A_PCSTATUS = 1 --Статус личного дела "Действует".
    AND (personalCard.A_SNILS = @SNILS AND @considerSNILS = 1 OR @considerSNILS = 0) --СНИЛС совпадает, если нужно.
    AND (ISNULL(personalCard.A_NAME_STR, fioName.A_NAME) = @name AND @considerName = 1 OR @considerName = 0) -- Имя совпадает, если нужно.
    AND (ISNULL(personalCard.A_SURNAME_STR, fioSurname.A_NAME) = @surname AND @considerSurname = 1 OR @considerSurname = 0) --Фамилия совпадает, если нужно.
    AND (CONVERT(DATE, personalCard.BIRTHDATE) = CONVERT(DATE, @birthdate) AND @considerBirthdate = 1 OR @considerBirthdate = 0) --Дата рожденяи совпадает, если нужно.
    AND (ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) = @secondname AND @considerSecondname = 1 OR @considerSecondname = 0) --Отчество совпадает, если нужно.

