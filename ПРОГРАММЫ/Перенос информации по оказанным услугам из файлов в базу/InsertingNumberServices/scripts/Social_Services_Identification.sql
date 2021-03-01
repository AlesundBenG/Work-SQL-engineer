-------------------------------------------------------------------------------------------------------------------------------

--�������.
DECLARE @personOUID INT
SET @personOUID = #personOUID# 


-------------------------------------------------------------------------------------------------------------------------------


--����� ���������� �� ���������� ������������.
SELECT 
    socServ.OUID                        AS SOC_SERV_OUID,
    personalCard.A_TITLE                AS PERSONAL_CARD_TITLE,
    socServ.A_DEGREE                    AS DEGREE,
    typeServ.A_NAME                     AS SOC_SERV_TYPE,
    organization.A_NAME1                AS ORGANIZATION,
    departament.A_NAME1                 AS DEPARTAMENT,
    CONVERT(DATE, period.STARTDATE)     AS SOC_SERV_START_DATE,
    CONVERT(DATE, period.A_LASTDATE)    AS SOC_SERV_END_DATE, 
    statusServ.A_NAME                   AS SOC_SERV_STATUS
FROM ESRN_SOC_SERV socServ --���������� ����������� ������������.
----������ ����������.
    INNER JOIN SPR_STATUS_PROCESS statusServ 
        ON statusServ.A_ID = socServ.A_STATUSPRIVELEGE	--������ � �����������.	
----������ ���������� ������.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = socServ.A_ORGNAME --������ � �����������.
----�����������.
    INNER JOIN SPR_ORG_BASE departament
        ON departament.OUID = socServ.A_DEPNAME --������ � �����������.     
----������ �������������� ���.        
    INNER JOIN SPR_SOCSERV_PERIOD period
        ON period.A_STATUS = 10                 --������ � �� "���������".
            AND period.A_SERV = socServ.OUID    --������ � �����������.   
----���������� �������� ��������.
    INNER JOIN SPR_NPD_MSP_CAT NPD
        ON NPD.A_ID = socServ.A_SERV --������ � �����������.
----������������ ���.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = NPD.A_MSP --������ � ���������� �������� ����������.
----������ ���� ���������������.
    INNER JOIN WM_PERSONAL_CARD personalCard
        ON personalCard.OUID = socServ.A_PERSONOUID --������ � �����������.
WHERE socServ.A_STATUS = 10 --������ ���������� � �� "���������".
    AND socServ.A_PERSONOUID = @personOUID 
   

-------------------------------------------------------------------------------------------------------------------------------