SELECT 
    paymentBook.OUID                            AS [Код],
    paymentBook.A_NUMPB                         AS [Номер дела],
    personalCard.A_TITLE                        AS [ЛД],
    deliveryWay.A_NAME                          AS [Способ доставки],
    requisitStatus.A_NAME                       AS [Статус реквезита],
    deliveryType.NAME                           AS [Способ получения выплаты],
    organization.A_NAME1                        AS [Выплатная организация],
    paymentRequisit.ACCOUNTINGCOUNT             AS [Р/счет],
    CONVERT(DATE, paymentRequisit.A_STARTDATE)  AS [Действует с],
    CONVERT(DATE, paymentRequisit.A_LASTDATE)   AS [Действует по],
    esrnStatusPayBook.A_NAME                    AS [Статус выплатного дела в базе денных],
    typeServ.A_NAME                             AS [Меры социальной поддержки],
    statusServ.A_NAME                           AS [Статус назначения МСП],
   payBookStatus.A_NAME                         AS [Статус выплатного дела в базе данных]
FROM WM_PAYMENT_BOOK paymentBook --Выплатное дело.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusPayBook
        ON esrnStatusPayBook.A_ID = paymentBook.A_STATUS --Связка с выплатным делом.
----Статус выплатного дела
    INNER JOIN SPR_DOC_STATUS payBookStatus
        ON payBookStatus.A_OUID = paymentBook.A_STATUSDOC --Связка с выплатным делом.
----Личное дело держателя выплатного дела.
    INNER JOIN WM_PERSONAL_CARD personalCard
        ON personalCard.OUID = paymentBook.PERSONALOUID  --Связка с выплатным делом.
----Связка выплатных дел с выплатными реквезитами.
    INNER JOIN SPR_PAYBOOK_PAY payBool_link_Requisit
        ON payBool_link_Requisit.FROMID = paymentBook.OUID --Связка с выплатным делом.
----Выплатные реквизиты.
    INNER JOIN WM_PAYMENT paymentRequisit
        ON paymentRequisit.OUID = payBool_link_Requisit.TOID --Связка с выплатным делом.
----Статус реквезита.       
    INNER JOIN SPR_DOC_STATUS requisitStatus
        ON requisitStatus.A_OUID =  paymentRequisit.A_DOCSTATUS --Связка с выплатными реквезитами.
----Наименование способа доставки.
   INNER JOIN SPR_PAY_TYPE deliveryWay    
        ON deliveryWay.A_ID = paymentRequisit.DELIVERYWAY --Связка с выплатными реквезитами.
----Наименоване способа получения выплаты.
    INNER JOIN SPR_DELIVERTYPES deliveryType
        ON deliveryType.OUID = paymentRequisit.A_DELIVERY_TYPES --Связка с выплатными реквезитами.
----Выплатная организация.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = paymentRequisit.A_PAYMENTORG --Связка с выплатными реквезитами.
----Назначения МСП. 
    INNER JOIN ESRN_SERV_SERV servServ    
        ON servServ.A_STATUS = 10                           --Статус в БД "Действует".
            AND servServ.A_PAYMENTBOOK  = paymentBook.OUID  --Связка с выплатным делом.   
----Наименование МСП.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = servServ.A_SK_MSP --Связка с назначением.	
----Статус назначения.
    INNER JOIN SPR_STATUS_PROCESS statusServ 
        ON statusServ.A_ID = servServ.A_STATUSPRIVELEGE	--Связка с назначением.	
