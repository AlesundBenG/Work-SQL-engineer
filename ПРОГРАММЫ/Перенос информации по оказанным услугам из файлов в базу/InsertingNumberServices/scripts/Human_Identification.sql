-------------------------------------------------------------------------------------------------------------------------------

--�������.
DECLARE @surname VARCHAR(256)
SET @surname = '#surname#'

--��������� �������.
DECLARE @considerSurname INT
SET @considerSurname = #considerSurname#

--���.
DECLARE @name VARCHAR(256)
SET @name = '#name#'

--��������� ���.
DECLARE @considerName INT
SET @considerName = #considerName#

--��������.
DECLARE @secondname VARCHAR(256)
SET @secondname = '#secondname#'

--��������� ��������.
DECLARE @considerSecondname INT
SET @considerSecondname = #considerSecondname#

--�����.
DECLARE @SNILS VARCHAR(256)
SET @SNILS = '#SNILS#'

--��������� �����.
DECLARE @considerSNILS INT
SET @considerSNILS = #considerSNILS#

--���� ��������.
DECLARE @birthdate VARCHAR(256)
SET @birthdate = '#birthdate#'

--��������� ���� ��������.
DECLARE @considerBirthdate INT
SET @considerBirthdate = #considerBirthdate#


-------------------------------------------------------------------------------------------------------------------------------


--����� �����, ��������������� ��������.
SELECT
    personalCard.OUID                                           AS PERSONOUID,
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS SURNAME,
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS NAME,
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS SECONDNAME,
    CONVERT(VARCHAR, personalCard.BIRTHDATE, 104)               AS BIRTHDATE,
    personalCard.A_SNILS                                        AS SNILS
FROM WM_PERSONAL_CARD personalCard --������ ���� ����������.
----������ � ��.
    INNER JOIN ESRN_SERV_STATUS esrnStatusPersonalCard
        ON esrnStatusPersonalCard.A_ID = personalCard.A_STATUS --������ � ������ �����.
----�������.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME --������ � ������ �����.
----���.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME --������ � ������ �����.      
----��������.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME --������ � ������ �����.     
WHERE personalCard.A_STATUS = 10 --������ ������� ���� � �� "���������".
    AND personalCard.A_PCSTATUS = 1 --������ ������� ���� "���������".
    AND (personalCard.A_SNILS = @SNILS AND @considerSNILS = 1 OR @considerSNILS = 0) --����� ���������, ���� �����.
    AND (ISNULL(personalCard.A_NAME_STR, fioName.A_NAME) = @name AND @considerName = 1 OR @considerName = 0) -- ��� ���������, ���� �����.
    AND (ISNULL(personalCard.A_SURNAME_STR, fioSurname.A_NAME) = @surname AND @considerSurname = 1 OR @considerSurname = 0) --������� ���������, ���� �����.
    AND (CONVERT(DATE, personalCard.BIRTHDATE) = CONVERT(DATE, @birthdate) AND @considerBirthdate = 1 OR @considerBirthdate = 0) --���� �������� ���������, ���� �����.
    AND (ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) = @secondname AND @considerSecondname = 1 OR @considerSecondname = 0) --�������� ���������, ���� �����.

