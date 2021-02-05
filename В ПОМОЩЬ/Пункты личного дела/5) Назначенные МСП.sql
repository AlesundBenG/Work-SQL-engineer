SELECT 
    typeServ.A_NAME                             AS [Меры социальной поддержки],
    typeCategory.A_NAME                         AS [Льготная категория],
    CONVERT(DATE, servServ.A_SERVDATE)          AS [Дата принятия решения о назначении],
    personalCardHolder.A_TITLE                  AS [Льготодержатель],
    personalCardChild.A_TITLE                   AS [Лицо, на основании данных ЛД которого сделано назначение],
    statusServ.A_NAME                           AS [Статус назначения],
    CONVERT(DATE, period.STARTDATE)             AS [Дата начала периода предоставления МСП],
    CONVERT(DATE, period.A_LASTDATE)            AS [Дата окончания периода предоставления МСП],
    servServ.A_SUMP                             AS [Назначенный впервые размер],
    payBook.A_NUMPB                             AS [Выплатное дело],
    CONVERT(DATE, servServ.A_LASTPROLDATE)      AS [Дата последнего продления],
    servServ.OUID                               AS [Идентификатор назначения],
    CONVERT(DATE, servServ.A_LASTRECALCDATE)    AS [Дата последнего перерасчета],
    osznDepartament.A_SHORT_TITLE               AS [Орган социальной защиты населения],
    esrnStatusServ.A_NAME                       AS [Статус назначения в базе данных]
FROM ESRN_SERV_SERV servServ --Назначения МСП.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusServ
        ON esrnStatusServ.A_ID = servServ.A_STATUS --Связка с назначением.	
----Статус назначения.
    INNER JOIN SPR_STATUS_PROCESS statusServ 
        ON statusServ.A_ID = servServ.A_STATUSPRIVELEGE	--Связка с назначением.	
----Наименование МСП.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = servServ.A_SK_MSP --Связка с назначением.		
----Льготная категория.     
    LEFT JOIN PPR_CAT typeCategory 
        ON typeCategory.A_ID = servServ.A_SK_LK --Связка с назначением.	
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCardHolder 
        ON personalCardHolder.OUID = servServ.A_PERSONOUID --Связка с назначением.	
----Личное дело лица, на основании данных ЛД которого сделано назначение				
    LEFT JOIN WM_PERSONAL_CARD personalCardChild 
        ON personalCardChild.OUID = servServ.A_CHILD --Связка с назначением.				
----Период предоставления МСП.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_STATUS = 10                 --Статус в БД "Действует".
            AND period.A_SERV = servServ.OUID   --Связка с назначением.	
----Выплатное дело.
    INNER JOIN WM_PAYMENT_BOOK payBook
        ON payBook.A_STATUS = 10                        --Статус в БД "Действует".
            AND payBook.OUID = servServ.A_PAYMENTBOOK   --Связка с назначением.	
----ОСЗН.
    INNER JOIN ESRN_OSZN_DEP osznDepartament
        ON osznDepartament.OUID = servServ.A_ORGNAME --Связка с назначением.