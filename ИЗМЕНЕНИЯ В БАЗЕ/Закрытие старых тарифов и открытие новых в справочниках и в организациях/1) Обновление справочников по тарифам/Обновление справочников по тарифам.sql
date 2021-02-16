--------------------------------------------------------------------------------------------------------------------------------

--Дата запуска скрипта (закрытия старого тарифа и открытие нового).
DECLARE @dateLaunch DATETIME
SET @dateLaunch = GETDATE()

--Дата начала действия нового тарифа.
DECLARE @startDateNewTarif DATE
SET @startDateNewTarif = CONVERT(DATE, '15-12-2020')

--Дата окончания старого тарифа.
DECLARE @endDateOldTarif DATE
SET @endDateOldTarif = CONVERT(DATE, '31-12-2020')

--Дата принятия тарифа.
DECLARE @dateAcceptance DATE
SET @dateAcceptance = CONVERT(DATE, '15-12-2020')

--Создатель.
DECLARE @creator INT
SET @creator = 10314303 --Системный администратор.



--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#NEW_DATA')       IS NOT NULL BEGIN DROP TABLE #NEW_DATA          END --Новая информация о тарифах.
IF OBJECT_ID('tempdb..#OLD_DATA')       IS NOT NULL BEGIN DROP TABLE #OLD_DATA          END --Старая информация о тарифах.
IF OBJECT_ID('tempdb..#INSERTED_DATA')  IS NOT NULL BEGIN DROP TABLE #INSERTED_DATA     END --Вставленная информация.
IF OBJECT_ID('tempdb..#UPDATED_DATA')   IS NOT NULL BEGIN DROP TABLE #UPDATED_DATA      END --Измененная информация (Закрытие тарифы).


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #NEW_DATA (
    SOC_SERV_OUID   INT,            --ID услуги.   
    AMOUNT          FLOAT,          --Новое значение тарифа.
    DISTRICT        VARCHAR(256),   --Местность распространения (Городская местность/Сельская местность/Для всех)
)
CREATE TABLE #OLD_DATA (
    TARIF_OUID      INT,            --ID тарифа.
    SOC_SERV_OUID   INT,            --ID социальной услуги.
    UNIT            INT,            --Единица измерения.
    DISTRICT        VARCHAR(256),   --Местность распространения.
)
CREATE TABLE #INSERTED_DATA (
    TARIF_OUID INT, --ID тарифа.
)
CREATE TABLE #UPDATED_DATA (
    TARIF_OUID      INT,    --ID тарифа.
    FIN_DATE_OLD    DATE,   --Старая дата окончания.
)


--------------------------------------------------------------------------------------------------------------------------------



--Выборка новых значений.
--INSERT INTO #NEW_DATA(SOC_SERV_OUID, AMOUNT, DISTRICT)
--VALUES 
---Вставить значения.
--...


--------------------------------------------------------------------------------------------------------------------------------


--Выбор последних тарифов услуг.
INSERT INTO #OLD_DATA (TARIF_OUID, SOC_SERV_OUID, UNIT, DISTRICT)
SELECT 
    t.TARIF_OUID,
    t.SOC_SERV_OUID,
    t.UNIT,
    t.DISTRICT
FROM (
    SELECT 
        tarif.A_OUID                        AS TARIF_OUID,
        CONVERT(DATE, tarif.A_START_DATE)   AS TARIF_START_DATE,
        CONVERT(DATE, tarif.A_FIN_DATE)     AS TARIF_END_DATE,
        tarif.A_SOC_SERV                    AS SOC_SERV_OUID,
        tarif.A_UNIT                        AS UNIT,
        tarif.A_DISTRICT                    AS DISTRICT,
        --Для выбора последних тарифов услуг.
        ROW_NUMBER() OVER (PARTITION BY tarif.A_SOC_SERV, tarif.A_DISTRICT ORDER BY tarif.A_START_DATE DESC) AS gnum
    FROM SPR_REG_SOC_SERV_PERIOD_2018 tarif --Региональные тарифы на социальные услуги.
    ----Новые данные.
        INNER JOIN #NEW_DATA newData
            ON newData.SOC_SERV_OUID = tarif.A_SOC_SERV --Связка по услуге.
                AND newData.DISTRICT = tarif.A_DISTRICT --Связка по области распространения.
    WHERE tarif.A_STATUS = 10 --Статус в БД "Действует".
) t
WHERE t.gnum = 1                        	--Последний тариф.
    AND t.TARIF_END_DATE IS NULL        	--Нет даты окончания (Не закрыт тариф).
    AND t.TARIF_START_DATE < @endDateOldTarif	--Дата начала не в будущем.
    

--------------------------------------------------------------------------------------------------------------------------------


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////Начало транзакции///////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


BEGIN TRANSACTION


--------------------------------------------------------------------------------------------------------------------------------


--Вставка новых тарифов.
INSERT INTO SPR_REG_SOC_SERV_PERIOD_2018 (GUID, A_CROWNER, A_TS, A_SYSTEMCLASS, A_CREATEDATE, A_STATUS, A_SOC_SERV, A_DATE, A_START_DATE, A_FIN_DATE, A_AMOUNT, A_UNIT, A_DISTRICT)
OUTPUT inserted.A_OUID INTO #INSERTED_DATA(TARIF_OUID) --Сохранение добавленных тарифов.
SELECT
    NEWID()                     AS GUID,
    @creator                    AS A_CROWNER,
    @dateLaunch                 AS A_TS,
    11332477                    AS A_SYSTEMCLASS,
    @dateLaunch                 AS A_CREATEDATE,
    10                          AS A_STATUS,
    oldData.SOC_SERV_OUID       AS A_SOC_SERV,
    @dateAcceptance             AS A_DATE,
    @startDateNewTarif          AS A_START_DATE,
    CAST(NULL AS DATE)          AS A_FIN_DATE,
    newData.AMOUNT              AS AMOUNT,
    oldData.UNIT                AS A_UNIT,
    oldData.DISTRICT            AS A_DISTRICT
FROM #OLD_DATA oldData
    ----Новые данные.
    INNER JOIN #NEW_DATA newData
        ON newData.SOC_SERV_OUID = oldData.SOC_SERV_OUID    --Связка по услуге.
            AND oldData.DISTRICT = newData.DISTRICT         --Связка по области распространения.


--------------------------------------------------------------------------------------------------------------------------------


--Закрытие старых тарифов.
UPDATE tarif
SET tarif.A_FIN_DATE = @endDateOldTarif
OUTPUT inserted.A_OUID, deleted.A_FIN_DATE INTO #UPDATED_DATA(TARIF_OUID, FIN_DATE_OLD) --Сохранение старого значения.
FROM SPR_REG_SOC_SERV_PERIOD_2018 tarif
WHERE tarif.A_OUID IN (SELECT TARIF_OUID FROM #OLD_DATA)


--------------------------------------------------------------------------------------------------------------------------------


COMMIT 


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////Конец транзакции////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


--------------------------------------------------------------------------------------------------------------------------------


--Проверка вставленных тарифов.
SELECT
    tarif.*   
FROM #INSERTED_DATA insertedData
    INNER JOIN SPR_REG_SOC_SERV_PERIOD_2018 tarif
        ON tarif.A_OUID = insertedData.TARIF_OUID


--------------------------------------------------------------------------------------------------------------------------------


--Проверка закрытия.
SELECT 
    tarif.*,
    updatedData.FIN_DATE_OLD
FROM SPR_REG_SOC_SERV_PERIOD_2018 tarif
    INNER JOIN #UPDATED_DATA updatedData
        ON updatedData.TARIF_OUID = tarif.A_OUID 


--------------------------------------------------------------------------------------------------------------------------------