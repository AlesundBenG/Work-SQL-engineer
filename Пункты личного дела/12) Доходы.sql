SELECT 
    personalCard.A_TITLE                AS [Личное дело],
    typeProfit.A_NAME                   AS [Вид дохода],
    profit.A_AMOUNT                     AS [Размер совокупного дохода за период, руб.],
    CONVERT(DATE, profit.A_STARTDATE)   AS [Дата начала периода],
    CONVERT(DATE, profit.A_LAST_DATE)   AS [Дата окончания периода],
    profit.A_AVERAGE                    AS [Средний доход в месяц, руб.],
    esrnStatusProfit.A_NAME             AS [Статус дохода в базе данных]
FROM WM_PROFIT_ADD profit --Доходы гражданина.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusProfit
        ON esrnStatusProfit.A_ID = profit.A_STATUS --Связка с доходом гражданина.
----Вид дохода.
    INNER JOIN SPR_PROFIT typeProfit
        ON typeProfit.OUID = profit.A_PROFIT_TYPE --Связка с доходом гражданина.
----Личное дело человека.
    INNER JOIN WM_PERSONAL_CARD personalCard
        ON personalCard.OUID = profit.A_PERSONUOID  --Связка с доходом гражданина.