SELECT  
    typeReceipt.A_NAME                      AS [Тип платежного документа],
    CONVERT(DATE, receipt.A_PAYMENT_DATE)   AS [К оплате за],
    receipt.A_PAY                           AS [Начислено],
    receipt.A_FACT_PAY                      AS [Фактическая оплата],
    personalCard.A_TITLE                    AS [Плательщик],
    address.A_ADRTITLE                      AS [Адрес],
    receipt.A_NUM_LIVING                    AS [Кол-во проживающих],
    receipt.A_NUM_LGOTA                     AS [Кол-во льготников],
    CONVERT(DATE, receipt.A_REG_DATE)       AS [Дата предоставления квитанции],
    esrnStatusReceipt.A_NAME                AS [Статус квитанции в базе данных]  
FROM WM_RECEIPT receipt --Квитанция.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusReceipt
        ON esrnStatusReceipt.A_ID = receipt.A_STATUS --Связка с квитанцией.
----Тип платежного документа.
    INNER JOIN SPR_RECEIPT_TYPE typeReceipt
        ON typeReceipt.A_OUID = receipt.A_RECEIPT_TYPE --Связка с квитанцией.
----Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = receipt.A_PAYER --Связка с квитанцией.
----Адрес.
    LEFT JOIN WM_ADDRESS address
        ON address.OUID = receipt.A_ADDR_ID --Связка с квитанцией.