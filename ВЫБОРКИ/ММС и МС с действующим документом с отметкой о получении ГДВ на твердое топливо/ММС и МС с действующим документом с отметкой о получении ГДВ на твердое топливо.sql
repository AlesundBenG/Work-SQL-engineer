------------------------------------------------------------------------------------------------------------------------------


--�������� ��������� ������.
IF OBJECT_ID('tempdb..#ALIVE_PEOPLE') IS NOT NULL BEGIN DROP TABLE #ALIVE_PEOPLE END --������� ����� �����, ������ ���� ������� ���������.
IF OBJECT_ID('tempdb..#MANY_CHILDREN_DOC') IS NOT NULL BEGIN DROP TABLE #MANY_CHILDREN_DOC END --������� ���������� �� "������������� ����������� ���������������� �����", ������� ��������� �� 01.03.2021
IF OBJECT_ID('tempdb..#PEOPLE_WHO_HAVE_SOLID_FUEL_MSP') IS NOT NULL BEGIN DROP TABLE #PEOPLE_WHO_HAVE_SOLID_FUEL_MSP END --������� ��������� �������� ������� �� ������������ � �������� �������� ������� ��� ������� ������� ��������� �� 2020-2021 ���.
IF OBJECT_ID('tempdb..#LIVE_ADDRESS_PEOPLE') IS NOT NULL BEGIN DROP TABLE #LIVE_ADDRESS_PEOPLE END --������ ���������� �����.


------------------------------------------------------------------------------------------------------------------------------


--�������� ��������� ������.
CREATE TABLE #ALIVE_PEOPLE (
    PERSONOUID INT, --������������� ������� ����.    
)
CREATE TABLE #MANY_CHILDREN_DOC (
    DOC_OUID        INT,    --ID ���������.
    DOC_TYPE        INT,    --��� ���������.
    PERSONOUID      INT,    --ID ������� ���� ��������� ���������.   
)
CREATE TABLE #LIVE_ADDRESS_PEOPLE (
    PERSONOUID      INT,    --������������� ������� ����.    
    ADDRESS_OUID    INT,    --������������� ������.
    ADDRESS_TYPE    INT,    --��� ������ (0 - ���; 1 - ����� ����������; 2 - ����� ��������� �����������; 3 - ����� �����������).
)
CREATE TABLE #PEOPLE_WHO_HAVE_SOLID_FUEL_MSP (
    PERSONOUID INT,    --������������� ������� ����. 
)


------------------------------------------------------------------------------------------------------------------------------


--������� ����������� ������ ��� ����� �����.
INSERT INTO #ALIVE_PEOPLE (PERSONOUID)
SELECT 
    personalCard.OUID AS PERSONOUID
FROM WM_PERSONAL_CARD personalCard          --������ ���� ����������.
WHERE personalCard.A_STATUS = 10            --������ � �� "���������".
    AND personalCard.A_PCSTATUS = 1         --����������� ������ ����.
    AND personalCard.A_DEATHDATE IS NULL    --����������� ���� ������.
    
    
------------------------------------------------------------------------------------------------------------------------------


--������� ����������, ����������� �� 01.03.2021
INSERT INTO #MANY_CHILDREN_DOC (DOC_OUID, DOC_TYPE, PERSONOUID)
SELECT
    actDocuments.OUID                                   AS DOC_OUID,
    actDocuments.DOCUMENTSTYPE                          AS DOC_TYPE,
    actDocuments.PERSONOUID                             AS PERSONOUID
FROM WM_ACTDOCUMENTS actDocuments --����������� ���������.
----������� ��� � ��� ������ ���� ���������.
    INNER JOIN #ALIVE_PEOPLE alivePeople
        ON alivePeople.PERSONOUID = actDocuments.PERSONOUID
WHERE actDocuments.A_STATUS = 10 --������ � �� "���������".
    AND actDocuments.DOCUMENTSTYPE IN (
        2814,   --������������� ����������� �����
        2858    --������������� ����������� ���������������� �����.  
    )
    AND CONVERT(DATE, '01-03-2021') BETWEEN CONVERT(DATE, actDocuments.ISSUEEXTENSIONSDATE) AND CONVERT(DATE, actDocuments.COMPLETIONSACTIONDATE)


------------------------------------------------------------------------------------------------------------------------------


INSERT INTO #PEOPLE_WHO_HAVE_SOLID_FUEL_MSP (PERSONOUID)
SELECT DISTINCT 
    servServ.A_PERSONOUID AS PERSONOUID
FROM ESRN_SERV_SERV servServ --���������� ���.			
----������ �������������� ���.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_STATUS = 10                 --������ � �� "���������".
            AND period.A_SERV = servServ.OUID   --������ � �����������.	
            AND (CONVERT(DATE, period.A_LASTDATE) >= CONVERT(DATE, '01-01-2020')    --���� �� 2020-2021
                OR period.A_LASTDATE IS NULL AND servServ.A_STATUSPRIVELEGE = 13    --���� ���� ��������� ���, �� ������ "����������".
            )
WHERE servServ.A_STATUS = 10 --������ � �� "���������".
    AND servServ.A_SK_MSP IN (
        891,    --��������� �������� ������� �� ������������ � �������� �������� ������� ��� ������� ������� ��������� (���.).
        917,    --��������� �������� ������� �� ������������ � �������� �������� ������� ��� ������� ������� ��������� (������.).
        989     --��������� �������� ������� �� ������������ � �������� �������� ������� ��� ������� ������� ��������� ��� ����������� ���������������� ����� (������.).
    )

------------------------------------------------------------------------------------------------------------------------------


--������� ������� ����������.
INSERT INTO #LIVE_ADDRESS_PEOPLE (PERSONOUID, ADDRESS_OUID, ADDRESS_TYPE)
SELECT 
    personalCard.OUID                                               AS PERSONOUID,
    CASE
        WHEN addressLive.OUID   IS NOT NULL THEN addressLive.OUID
        WHEN addressTemp.OUID   IS NOT NULL THEN addressTemp.OUID
        WHEN addressReg.OUID    IS NOT NULL THEN addressReg.OUID 
        ELSE CAST(NULL AS INT)
    END                                                             AS ADDRESS_OUID,
    CASE
        WHEN addressLive.OUID   IS NOT NULL THEN 1
        WHEN addressTemp.OUID   IS NOT NULL THEN 2
        WHEN addressReg.OUID    IS NOT NULL THEN 3
        ELSE 0
    END                                                             AS ADDRESS_TYPE
FROM WM_PERSONAL_CARD personalCard  --������ ���� ����������.
----����� �����������. 
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT --������ � ������ �����. 
----����� ����������.
    LEFT JOIN WM_ADDRESS addressLive
        ON addressLive.OUID = personalCard.A_LIVEFLAT --������ � ������ �����. 
----����� �������� �����������.
    LEFT JOIN WM_ADDRESS addressTemp
        ON addressTemp.OUID = personalCard.A_TEMPREGFLAT --������ � ������ �����. 


------------------------------------------------------------------------------------------------------------------------------



SELECT DISTINCT
    CASE addressLive.ADDRESS_TYPE
        WHEN 1 THEN '����� ����������'
        WHEN 2 THEN '����� ���������� ����������'
        WHEN 3 THEN '����� �����������'
        ELSE '�� ������'
    END                                                         AS [��� ������],
    ISNULL(district.A_NAME, districtCity.A_NAME)                AS [�����],    --���� ����� �����, �� ����� �����������, ���������, �����������, ������������.
    town.A_NAME                                                 AS [���������� �����],
    address.A_ADRTITLE                                          AS [�����],
    personalCard.OUID                                           AS [������ ����],
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS [�������],
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS [���],
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS [��������],
    CASE manyChildDOC.DOC_TYPE
        WHEN 2814 THEN '����������� �����'
        WHEN 2858 THEN '����������� ���������������� �����'
        ELSE ''
    END                                                         AS [������],
    CASE 
        WHEN haveMSP.PERSONOUID IS NOT NULL THEN '+'
        ELSE ''
    END                                                         AS [������� ��� �� 2020-2021 ���]
FROM #MANY_CHILDREN_DOC manyChildDOC
----������ ���� ����������.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = manyChildDOC.PERSONOUID
----�������.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME 
----���.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME     
----��������.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME 
----����� ��������. 
    LEFT JOIN #LIVE_ADDRESS_PEOPLE addressLive
        ON addressLive.PERSONOUID = personalCard.OUID
----���������� �� ������.
    LEFT JOIN WM_ADDRESS address
        ON address.OUID = addressLive.ADDRESS_OUID
----�����.
    LEFT JOIN SPR_FEDERATIONBOROUGHT district
        ON district.OUID = address.A_FEDBOROUGH
    ----������ ������ ������.
    LEFT JOIN SPR_BOROUGH districtCity
        ON districtCity.OUID = address.A_TOWNBOROUGH 
----���������� �����.
    LEFT JOIN SPR_TOWN town
        ON town.OUID = address.A_TOWN
----���, ������� ����� ���������� �� �������.
    LEFT JOIN #PEOPLE_WHO_HAVE_SOLID_FUEL_MSP haveMSP
        ON haveMSP.PERSONOUID = personalCard.OUID