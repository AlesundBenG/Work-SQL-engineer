SELECT
    typeServ.A_NAME                         AS [Меры социальной поддержки],
    personalCardHolder.A_TITLE              AS [Льготодержатель],
    CONVERT(DATE, paidAmounts.PAIDDATE)     AS [Дата формирования выплаты],
    paidAmounts.A_YEAR                      AS [Год],
    paidAmounts.A_MONTH                     AS [Месяц],
    paidAmounts.AMOUNT                      AS [Размер выплаты],
    statusPaidAmounts.A_NAME                AS [Статус выплаты],
    esrnStatusPaidAmounts.A_NAME            AS [Статус выплаты в базе данных] 
FROM WM_PAIDAMOUNTS paidAmounts --Выплаты.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusPaidAmounts
        ON esrnStatusPaidAmounts.A_ID = paidAmounts.A_STATUS
----Статус выплат.
    INNER JOIN SPR_STATUS_PAYMENT statusPaidAmounts
        ON statusPaidAmounts.A_ID = paidAmounts.A_STATUSPRIVELEGE
----Начисление.
    INNER JOIN WM_PAY_CALC payCalculation
        ON payCalculation.OUID = paidAmounts.A_PAYCALC
----Назначения МСП.
    INNER JOIN ESRN_SERV_SERV servServ 
        ON servServ.OUID = payCalculation.A_MSP
----Наименование МСП.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = servServ.A_SK_MSP --Связка с назначением.		
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCardHolder 
        ON personalCardHolder.OUID = servServ.A_PERSONOUID --Связка с назначением.