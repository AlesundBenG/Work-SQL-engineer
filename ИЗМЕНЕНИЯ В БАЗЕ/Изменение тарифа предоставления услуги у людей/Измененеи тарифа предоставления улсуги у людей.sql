--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#NEW_DATA')       IS NOT NULL BEGIN DROP TABLE #NEW_DATA      END --Изменяемые тарифы.
IF OBJECT_ID('tempdb..#UPDATED_DATA')   IS NOT NULL BEGIN DROP TABLE #UPDATED_DATA  END --Обновленные данные.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #NEW_DATA (
    SOC_SERV_OUID   INT,            --ID услуги.   
    AMOUNT          FLOAT,          --Новое значение тарифа.
    DISTRICT        VARCHAR(256),   --Местность распространения (Городская местность/Сельская местность/Для всех)
)
CREATE TABLE #UPDATED_DATA (
    AGR_OUID    INT,    --ID периода.
    OLD_AMOUNT  FLOAT,  --Старое значение.
    NEW_AMOUNT  FLOAT,  --Вставленное значение.
)


--------------------------------------------------------------------------------------------------------------------------------


--Выборка новых значений.
INSERT INTO #NEW_DATA(SOC_SERV_OUID, AMOUNT, DISTRICT)
VALUES 
---Вставить значения.
    (2681, 0.00, 'Городская местность '),
    (2681, 0.00, 'Сельская местность '),
    (2682, 0.00, 'Городская местность '),
    (2682, 0.00, 'Сельская местность '),
    (2683, 0.00, 'Городская местность '),
    (2683, 0.00, 'Сельская местность '),
    (2686, 0.00, 'Городская местность '),
    (2686, 0.00, 'Сельская местность '),
    (2690, 0.00, 'Городская местность '),
    (2690, 0.00, 'Сельская местность '),
    (2697, 0.00, 'Городская местность '),
    (2697, 0.00, 'Сельская местность '),
    (2941, 0.00, 'Городская местность '),
    (2941, 0.00, 'Сельская местность '),
    (2948, 0.00, 'Городская местность '),
    (2948, 0.00, 'Сельская местность '),
    (2949, 0.00, 'Городская местность '),
    (2949, 0.00, 'Сельская местность '),
    (2709, 0.00, 'Для всех '),
    (2716, 0.00, 'Для всех '),
    (2717, 0.00, 'Для всех '),
    (2724, 0.00, 'Для всех '),
    (2745, 0.00, 'Для всех '),
    (2757, 0.00, 'Для всех '),
    (2767, 0.00, 'Для всех '),
    (3008, 0.00, 'Для всех '),
    (3009, 0.00, 'Для всех '),
    (3011, 0.00, 'Для всех '),
    (2776, 0.00, 'Для всех '),
    (2795, 0.00, 'Для всех ')


--------------------------------------------------------------------------------------------------------------------------------


/*
--Проверка.
SELECT
    personalCardHolder.A_TITLE          AS [Льготодержатель],
    socServAgr.A_ID                     AS AGR_OUID,
    typeSocServ.A_NAME                  AS [Социальная услуга],                 --AS SOC_SERV_TYPE,
    direct.A_NAME                       AS [Местность распространения услуги],  --DIRECT,
    socServAgr.A_TARIF_SOC_SERV         AS [Тариф предоставления услуги],       --AMOUNT  
    CONVERT(DATE, period.A_STARTDATE)   AS [Дата начала периода],
    CONVERT(DATE, period.A_LASTDATE)    AS [Дата окончания периода],
    period.A_COND_SOC_SERV              AS [Условие оказания социальных услуг]
FROM WM_SOC_SERV_AGR socServAgr --Агрегация по социальной услуге.
----Тарифы на социальные услуги.
    INNER JOIN SPR_TARIF_SOC_SERV tarif
        ON tarif.A_ID = socServAgr.A_SOC_SERV --Связка с агрегацией.
-----Справочник социальных услуг.
    INNER JOIN SPR_SOC_SERV typeSocServ 
        ON typeSocServ.OUID = tarif.A_SOC_SERV --Связка с тарифом.
----Местность распространения.
        INNER JOIN SPR_DIRECT direct
            ON direct.A_OUID = tarif.A_DISTRICT
----Обнавляемые услуги.
    INNER JOIN #NEW_DATA newData
        ON newData.SOC_SERV_OUID = typeSocServ.OUID --Связка со справочником услуги.
            AND newData.DISTRICT = direct.A_NAME    --Связка с областью распространения.
----Период предоставления.
    INNER JOIN WM_COND_SOC_SERV_ONE period
        ON period.A_SOC_SERV_AGR = socServAgr.A_ID                                  --Связка с агрегацией по социальной услуги.
            AND period.A_STATUS = 10                                                --Статус в БД "Действует".
            AND CONVERT(DATE, period.A_STARTDATE) >= CONVERT(DATE, '01-01-2021')    --Новые назначенные.
            AND (CONVERT(DATE, period.A_LASTDATE) >= GETDATE()                      --Не закрытые назначения.
                OR period.A_LASTDATE IS NULL
            )
--Назначение социального обслуживания.
    INNER JOIN ESRN_SOC_SERV socServ 
        ON socServ.OUID = socServAgr.ESRN_SOC_SERV --Связка с агрегацией по социальной услуге.
----Личное дело льготодержателя.
    INNER JOIN WM_PERSONAL_CARD personalCardHolder 
        ON personalCardHolder.OUID = socServ.A_PERSONOUID --Связка с назначением.	
WHERE socServAgr.A_STATUS = 10                          --Статус в БД "Действует".
    AND socServAgr.A_TARIF_SOC_SERV <> newData.AMOUNT   --Новое значение не установлено.
ORDER BY personalCardHolder.OUID, typeSocServ.A_NAME
*/


--------------------------------------------------------------------------------------------------------------------------------


--Начало транзакции.
BEGIN TRANSACTION

--Обновление.
UPDATE socServAgr
SET socServAgr.A_TARIF_SOC_SERV = newData.AMOUNT
OUTPUT inserted.A_ID, deleted.A_TARIF_SOC_SERV, inserted.A_TARIF_SOC_SERV INTO #UPDATED_DATA(AGR_OUID, OLD_AMOUNT, NEW_AMOUNT) --Сохранение измененных периодов.
FROM WM_SOC_SERV_AGR socServAgr --Агрегация по социальной услуге.
----Тарифы на социальные услуги.
    INNER JOIN SPR_TARIF_SOC_SERV tarif
        ON tarif.A_ID = socServAgr.A_SOC_SERV --Связка с агрегацией.
-----Справочник социальных услуг.
    INNER JOIN SPR_SOC_SERV typeSocServ 
        ON typeSocServ.OUID = tarif.A_SOC_SERV --Связка с тарифом.
----Местность распространения.
        INNER JOIN SPR_DIRECT direct
            ON direct.A_OUID = tarif.A_DISTRICT
----Обнавляемые услуги.
    INNER JOIN #NEW_DATA newData
        ON newData.SOC_SERV_OUID = typeSocServ.OUID --Связка со справочником услуги.
            AND newData.DISTRICT = direct.A_NAME    --Связка с областью распространения.
----Период предоставления.
    INNER JOIN WM_COND_SOC_SERV_ONE period
        ON period.A_SOC_SERV_AGR = socServAgr.A_ID                                  --Связка с агрегацией по социальной услуги.
            AND period.A_STATUS = 10                                                --Статус в БД "Действует".
            AND CONVERT(DATE, period.A_STARTDATE) >= CONVERT(DATE, '01-01-2021')    --Новые назначенные.
            AND (CONVERT(DATE, period.A_LASTDATE) >= GETDATE()                      --Не закрытые назначения.
                OR period.A_LASTDATE IS NULL
            )
WHERE socServAgr.A_STATUS = 10                          --Статус в БД "Действует".
    AND socServAgr.A_TARIF_SOC_SERV <> newData.AMOUNT   --Новое значение не установлено.
    
--Завершение транзакции.
COMMIT
    
    
--------------------------------------------------------------------------------------------------------------------------------


--Результат.
SELECT * FROM #UPDATED_DATA


--------------------------------------------------------------------------------------------------------------------------------