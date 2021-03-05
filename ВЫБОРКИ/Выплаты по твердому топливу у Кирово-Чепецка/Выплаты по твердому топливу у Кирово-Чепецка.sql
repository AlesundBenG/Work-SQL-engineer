SELECT 
    servServ.A_PERSONOUID               AS [Личное дело],
    personalCardHolder.A_TITLE          AS [ФИО],
    addressReg.A_ADRTITLE               AS [Адрес регистрации],
    addressLive.A_ADRTITLE              AS [Адрес проживания],
    addressTemp.A_ADRTITLE              AS [Адрес врменной регистрации],
    typeServ.A_NAME                     AS [Меры социальной поддержки],
    CONVERT(DATE, period.STARTDATE)     AS [Дата начала периода предоставления МСП],
    CONVERT(DATE, period.A_LASTDATE)    AS [Дата окончания периода предоставления МСП],
    COUNT(*)                            AS [Кол-во выплат],
    SUM(AMOUNT)                         AS [Сумма выплат]
FROM ESRN_SERV_SERV servServ --Назначения МСП.
----Наименование МСП.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = servServ.A_SK_MSP 	
            AND typeServ.A_ID IN (
                891,    --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления (фед.).
                917,    --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления (регион.).
                989     --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления для многодетных малообеспеченных семей (регион.).
            )
----Период предоставления МСП.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_STATUS = 10 --Статус в БД "Действует".
            AND period.A_SERV = servServ.OUID
            AND (CONVERT(DATE, period.A_LASTDATE) >= CONVERT(DATE, '01-01-2020') OR period.A_LASTDATE IS NULL)  --Было с 2020 года.
----Выплатное дело.
    INNER JOIN WM_PAYMENT_BOOK payBook
        ON payBook.A_STATUS = 10 --Статус в БД "Действует".
            AND payBook.OUID = servServ.A_PAYMENTBOOK
----Выплаты.
    INNER JOIN WM_PAIDAMOUNTS paidAmounts      
        ON paidAmounts.A_STATUS = 10        --Статус в БД "Действует".     
            AND paidAmounts.A_YEAR >= 2020  --С 2020 года выплаты.
            AND paidAmounts.A_PAYACCOUNT = payBook.OUID       
            AND paidAmounts.A_PAYNAME = servServ.A_SK_MSP
            AND paidAmounts.A_STATUSPRIVELEGE NOT IN (  --Статус выплаты не из..
                2,  --Неоплата.
                3,  --Неоплата с запретом.
                9   --Отменено, не положено.
            ) 
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCardHolder 
        ON personalCardHolder.OUID = servServ.A_PERSONOUID 
            AND personalCardHolder.A_STATUS = 10     
----Адрес регистрации. 
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCardHolder.A_REGFLAT
----Адрес проживания.
    LEFT JOIN WM_ADDRESS addressLive
        ON addressLive.OUID = personalCardHolder.A_LIVEFLAT
----Адрес врменной регистрации.
    LEFT JOIN WM_ADDRESS addressTemp
        ON addressTemp.OUID = personalCardHolder.A_TEMPREGFLAT
WHERE servServ.A_STATUS = 10        --Статус в БД "Действует".
    AND servServ.A_ORGNAME = 173825 --КОГКУ "Межрайонное управление социальной защиты населения в Кирово-Чепецком районе" (г. Кирово-Чепецк).
    AND CONVERT(DATE, paidAmounts.PAIDDATE) BETWEEN CONVERT(DATE, period.STARTDATE) AND CONVERT(DATE, period.A_LASTDATE)
GROUP BY servServ.A_PERSONOUID, personalCardHolder.A_TITLE, addressReg.A_ADRTITLE, addressLive.A_ADRTITLE, addressTemp.A_ADRTITLE, CONVERT(DATE, period.STARTDATE), CONVERT(DATE, period.A_LASTDATE), typeServ.A_NAME  
ORDER BY servServ.A_PERSONOUID, CONVERT(DATE, period.STARTDATE)


