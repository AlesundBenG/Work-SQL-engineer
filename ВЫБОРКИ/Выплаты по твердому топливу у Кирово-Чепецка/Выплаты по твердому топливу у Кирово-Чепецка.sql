SELECT 
    servServ.A_PERSONOUID               AS [Личное дело],
    personalCardHolder.A_TITLE          AS [ФИО],
    addressReg.A_ADRTITLE               AS [Адрес регистрации],
    addressLive.A_ADRTITLE              AS [Адрес проживания],
    addressTemp.A_ADRTITLE              AS [Адрес врменной регистрации],
    typeServ.A_NAME                     AS [Меры социальной поддержки],
    CONVERT(DATE, period.STARTDATE)     AS [Дата начала периода предоставления МСП],
    CONVERT(DATE, period.A_LASTDATE)    AS [Дата окончания периода предоставления МСП],
    paidAmounts.A_YEAR                  AS [Год],
    paidAmounts.A_MONTH                 AS [Месяц],
    CONVERT(DATE, paidAmounts.PAIDDATE) AS [Дата формирования выплаты],
    paidAmounts.AMOUNT                  AS [Сумма выплаты]
FROM ESRN_SERV_SERV servServ --Назначения МСП.
----Наименование МСП.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = servServ.A_SK_MSP 	
            AND servServ.A_STATUS = 10      --Статус в БД "Действует".
            AND servServ.A_ORGNAME = 173825 --КОГКУ "Межрайонное управление социальной защиты населения в Кирово-Чепецком районе" (г. Кирово-Чепецк).
            AND typeServ.A_ID IN (
                891,    --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления (фед.).
                917,    --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления (регион.).
                989     --Ежегодная денежная выплата на приобретение и доставку твердого топлива при наличии печного отопления для многодетных малообеспеченных семей (регион.).
            )
----Период предоставления МСП.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_SERV = servServ.OUID
            AND period.A_STATUS = 10 --Статус в БД "Действует".
            AND (CONVERT(DATE, period.A_LASTDATE) >= CONVERT(DATE, '01-01-2020') OR period.A_LASTDATE IS NULL)  --Было с 2020 года.
----Начисления.
    INNER JOIN WM_PAY_CALC payCalc
        ON payCalc.A_MSP = servServ.OUID
            AND payCalc.A_STATUS = 10 --Статус в БД "Действует". 
----Выплаты.
    INNER JOIN WM_PAIDAMOUNTS paidAmounts      
        ON paidAmounts.A_PAYCALC = payCalc.OUID 
            AND paidAmounts.A_STATUS = 10               --Статус в БД "Действует".     
            AND paidAmounts.A_STATUSPRIVELEGE NOT IN (  --Статус выплаты не из..
                2,  --Неоплата.
                3,  --Неоплата с запретом.
                9   --Отменено, не положено.
            ) 
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCardHolder 
        ON personalCardHolder.A_STATUS = 10     
            AND personalCardHolder.OUID = servServ.A_PERSONOUID 
----Адрес регистрации. 
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCardHolder.A_REGFLAT
----Адрес проживания.
    LEFT JOIN WM_ADDRESS addressLive
        ON addressLive.OUID = personalCardHolder.A_LIVEFLAT
----Адрес врменной регистрации.
    LEFT JOIN WM_ADDRESS addressTemp
        ON addressTemp.OUID = personalCardHolder.A_TEMPREGFLAT
ORDER BY servServ.A_PERSONOUID, CONVERT(DATE, period.STARTDATE)


