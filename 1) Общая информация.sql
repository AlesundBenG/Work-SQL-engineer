SELECT
    personalCard.OUID                                           AS [������ ����],
    persCardStatus.A_NAME                                       AS [������ ������� ����],
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS [�������],
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS [���],
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS [��������],
    gender.A_NAME                                               AS [���],
    �ountry.A_NAME                                              AS [�����������],
    personalCard.A_INN                                          AS [���],
    personalCard.A_SNILS                                        AS [�����],
    addressReg.A_ADRTITLE                                       AS [����� �����������],
    CONVERT(VARCHAR, personalCard.A_REGFLATDATE, 104)           AS [���� �����������],
    addressTempReg.A_ADRTITLE                                   AS [����� ��������� �����������],
    addressLive.A_ADRTITLE                                      AS [����� ����������],        
    ISNULL(countryBirth.A_NAME,             '-')    + ', ' + 
    ISNULL(federalOkrugBirth.A_NAME,        '-')    + ', ' + 
    ISNULL(subjectFederationBirth.A_NAME,   '-')    + ', ' + 
    ISNULL(federationBoroughBirth.A_NAME,   '-')    + ', ' + 
    ISNULL(townBirth.A_NAME,                '-')                AS [����� ��������],
    CONVERT(VARCHAR, personalCard.BIRTHDATE, 104)               AS [���� ��������],
    DATEDIFF(YEAR,personalCard.BIRTHDATE, GETDATE()) -                                  --���������� ������� ����� ������.									
        CASE                                                                            --�����������, ��� �� � ���� ���� ���� ��������.
            WHEN MONTH(personalCard.BIRTHDATE)    < MONTH(GETDATE())  THEN 0            --���� �������� ���, � �� ��� �� � ���� ������.
            WHEN MONTH(personalCard.BIRTHDATE)    > MONTH(GETDATE())  THEN 1            --���� �������� ����� � �������� �������.
            WHEN DAY(personalCard.BIRTHDATE)      > DAY(GETDATE())    THEN 1            --� ���� ������ ���� ��������, �� ��� ��� �� ����.
            ELSE 0                                                                      --� ���� ������ ���� ��������, � �� ��� ���.
        END                                                     AS [�������],
    osznDepartament.A_SHORT_TITLE                               AS [���� ��������],
    esrnStatusPersonalCard.A_NAME                               AS [������ ������� ���� � ���� ������]  
FROM WM_PERSONAL_CARD personalCard --������ ���� ����������.
----������ � ��.
    INNER JOIN ESRN_SERV_STATUS esrnStatusPersonalCard
        ON esrnStatusPersonalCard.A_ID = personalCard.A_STATUS --������ � ������ �����.
----������ ������� ����.
    INNER JOIN SPR_PC_STATUS persCardStatus
        ON persCardStatus.OUID = personalCard.A_PCSTATUS --������ � ������ �����.
----�������.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME --������ � ������ �����.
----���.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME --������ � ������ �����.      
----��������.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME --������ � ������ �����.     
----���.       
    INNER JOIN SPR_GENDER gender
        ON gender.OUID = personalCard.A_SEX --������ � ������ �����.
----���� ��������.
    LEFT JOIN ESRN_OSZN_DEP osznDepartament
        ON osznDepartament.OUID = personalCard.A_REG_ORGNAME --������ � ������ �����.
----������.
    LEFT JOIN SPR_COUNTRY �ountry
        ON �ountry.OUID = personalCard.A_CITIZENSHIP --������ � ������ �����.
----����� �����������.
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT --������ � ������ �����.
----����� ����������.
    LEFT JOIN WM_ADDRESS addressLive
        ON addressLive.OUID = personalCard.A_LIVEFLAT --������ � ������ �����.
----����� ��������� �����������.
    LEFT JOIN WM_ADDRESS addressTempReg
        ON addressTempReg.OUID = personalCard.A_TEMPREGFLAT --������ � ������ �����.
----����� ��������.
    LEFT JOIN WM_BIRTHPLACE             placeBirth              ON  placeBirth.OUID             = personalCard.A_PLACEOFBIRTH   --���������� ���� ��������.
    LEFT JOIN SPR_COUNTRY               countryBirth            ON  countryBirth.OUID           = placeBirth.A_COUNTRY          --���������� �����.
    LEFT JOIN SPR_FEDOKRRUG             federalOkrugBirth       ON  federalOkrugBirth.OUID      = placeBirth.A_FEDOKRUG         --���������� ����������� �������.
    LEFT JOIN SPR_SUBJFED               subjectFederationBirth  ON  subjectFederationBirth.OUID = placeBirth.A_SUBFED           --���������� ��������� ���������.
    LEFT JOIN SPR_FEDERATIONBOROUGHT    federationBoroughBirth  ON  federationBoroughBirth.OUID = placeBirth.A_FEDBOROUGH       --���������� ������� ��������� ���������.
    LEFT JOIN SPR_TOWN                  townBirth               ON  townBirth.OUID              = placeBirth.A_TOWN             --���������� ���������� �������.


    
    
