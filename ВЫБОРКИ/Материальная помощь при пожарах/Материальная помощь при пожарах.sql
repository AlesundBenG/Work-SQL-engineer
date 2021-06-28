-------------------------------------------------------------------------------------------------------------


--Начало периода отчета.
DECLARE @startDateReport DATE
SET @startDateReport = CONVERT(DATE, '01-03-2020')

--Конец периода отчета.
DECLARE @endDateReport DATE
SET @endDateReport = CONVERT(DATE, '31-05-2021')



-------------------------------------------------------------------------------------------------------------



SELECT 
    servServ.A_PERSONOUID                                       AS [Личное дело],
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS [Фамилия],
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS [Имя],
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS [Отчество],
    CONVERT(VARCHAR, personalCard.BIRTHDATE, 104)               AS [Дата рождения],
    personalCard.A_SNILS                                        AS [СНИЛС],
    addressReg.A_ADRTITLE                                       AS [Адрес регистрации],
    typeServ.A_NAME                                             AS [Меры социальной поддержки],
    typeCategory.A_NAME                                         AS [Льготная категория],
    CONVERT(VARCHAR, period.STARTDATE, 104)                     AS [Дата начала периода предоставления МСП],
    CONVERT(VARCHAR, period.A_LASTDATE, 104)                    AS [Дата окончания периода предоставления МСП],
    paidAmounts.A_YEAR                                          AS [Год выплаты],
    paidAmounts.A_MONTH                                         AS [Месяц выплаты],
    CONVERT(VARCHAR, paidAmounts.PAIDDATE, 104)                 AS [Дата формирования выплаты],
    CONVERT(VARCHAR, A_CONFIRMDATE, 104)                        AS [Дата поступления сведений о выплате],
    paidAmounts.AMOUNT                                          AS [Сумма выплаты]
FROM ESRN_SERV_SERV servServ --Назначения МСП.
----Период предоставления МСП.
    INNER JOIN SPR_SERV_PERIOD period 
        ON period.A_STATUS = 10                 --Статус в БД "Действует".
            AND period.A_SERV = servServ.OUID   
----Наименование МСП.	
    INNER JOIN PPR_SERV typeServ 
        ON typeServ.A_ID = servServ.A_SK_MSP 	
----Льготная категория.     
    LEFT JOIN PPR_CAT typeCategory 
        ON typeCategory.A_ID = servServ.A_SK_LK
----Начисления.
    INNER JOIN WM_PAY_CALC payCalc
        ON payCalc.A_MSP = servServ.OUID
            AND payCalc.A_STATUS = 10 --Статус в БД "Действует".         
----Выплаты.
    INNER JOIN WM_PAIDAMOUNTS paidAmounts      
        ON paidAmounts.A_PAYCALC = payCalc.OUID 
            AND paidAmounts.A_STATUS = 10           --Статус в БД "Действует".     
            AND paidAmounts.A_STATUSPRIVELEGE = 1   --Статус выплаты "Выплачено (Закрыто)".
            AND (YEAR(@startDateReport) <> YEAR(@endDateReport)             --Если отчет за несколько лет, и если...
                AND (paidAmounts.A_YEAR = YEAR(@startDateReport)            --Год оказания услуги лежит в начале периода и...
                        AND paidAmounts.A_MONTH >= MONTH(@startDateReport)  --...месяц оказания услуги больше месяца начала отчета или...
                    OR paidAmounts.A_YEAR = YEAR(@endDateReport)            --...год оказания услуги лежит в конце периода и...
                        AND paidAmounts.A_MONTH <= MONTH(@endDateReport)    --...месяц оказания услуги меньше месяца конца отчета или...
                    OR paidAmounts.A_YEAR > YEAR(@startDateReport)          --...год оказания услуги строго больше года начала отчета и... 
                        AND paidAmounts.A_YEAR < YEAR(@endDateReport)       --...год оказания услуги строго меньше года конца отчета.
                )
                OR YEAR(@startDateReport) = YEAR(@endDateReport)            --Если отчет за один год и...
                    AND paidAmounts.A_YEAR = YEAR(@startDateReport)         --...год оказания услуги лежит в периоде отчета и...
                    AND paidAmounts.A_MONTH BETWEEN MONTH(@startDateReport) AND MONTH(@endDateReport) --...месяц лежит в периоде отчета.
            )  
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.A_STATUS = 10     
            AND personalCard.OUID = servServ.A_PERSONOUID 
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME     
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME 
----Адрес регистрации.
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT 
WHERE servServ.A_STATUS = 10      --Статус в БД "Действует".
    AND servServ.A_SERV IN (
    ----МСП "Единовременная денежная выплата гражданам, утратившим имущество вследствие природных пожаров, произошедших на территории Кировской области"
        1548,   --ЛК "Граждане, утратившие имущество вследствие природных пожаров, произошедших на территории Кировской области"
    ----МСП Материальная помощь           
        2372,   --Гражданин, не освобожденный от уплаты государственной пошлины в соответствии с законодательством Российской Федерации, проживающий в жилом помещении, в котором произошел пожар           
        2374,   --Гражданин, проживающий по месту жительства (месту пребывания) в жилом помещении на дату пожара 
        2375,   --Собственник (собственники пропорционально доле в праве общей совместной или долевой собственности) либо наниматель жилого помещения по договору социального найма, проживающий по месту жительства (месту пребывания) в жилом помещении на дату пожара 
        2376,   --Собственник жилого помещения независимо от проживания по месту жительства (месту пребывания) в жилом помещении на дату пожара, а также иные граждане, проживающие по месту жительства (месту пребывания) в жилом помещении на дату пожара 
        2230    --Собственник жилого помещения, либо наниматель жилого помещения по договору социального найма
    )
ORDER BY paidAmounts.A_YEAR, paidAmounts.A_MONTH


