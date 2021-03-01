-------------------------------------------------------------------------------------------------------------------------------

--Фамилия.
DECLARE @personOUID INT
SET @personOUID = #personOUID# 


-------------------------------------------------------------------------------------------------------------------------------


--Выбор назначений на социальной обслуживание.
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
FROM ESRN_SOC_SERV socServ --Назначение социального обслуживания.
----Статус назначения.
    INNER JOIN SPR_STATUS_PROCESS statusServ 
        ON statusServ.A_ID = socServ.A_STATUSPRIVELEGE	--Связка с назначением.	
----Органы социальной защиты.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = socServ.A_ORGNAME --Связка с назначением.
----Департамент.
    INNER JOIN SPR_ORG_BASE departament
        ON departament.OUID = socServ.A_DEPNAME --Связка с назначением.     
----Период предоставления МСП.        
    INNER JOIN SPR_SOCSERV_PERIOD period
        ON period.A_STATUS = 10                 --Статус в БД "Действует".
            AND period.A_SERV = socServ.OUID    --Связка с назначением.   
----Нормативно правовой документ.
    INNER JOIN SPR_NPD_MSP_CAT NPD
        ON NPD.A_ID = socServ.A_SERV --Связка с назначением.
----Наименование МСП.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = NPD.A_MSP --Связка с нормативно правовым документом.
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCard
        ON personalCard.OUID = socServ.A_PERSONOUID --Связка с назначением.
WHERE socServ.A_STATUS = 10 --Статус назначения в БД "Действует".
    AND socServ.A_PERSONOUID = @personOUID 
   

-------------------------------------------------------------------------------------------------------------------------------