--------------------------------------------------------------------------------------------------------------------------------


--Дата запуска скрипта (закрытия старого тарифа и открытие нового).
DECLARE @dateLaunch DATETIME
SET @dateLaunch = GETDATE()

--Дата начала действия нового тарифа.
DECLARE @startDateNewSubServ DATE
SET @startDateNewSubServ = CONVERT(DATE, '31-01-2021')

--Дата окончания старого тарифа.
DECLARE @endDateOldSubServ DATE
SET @endDateOldSubServ = CONVERT(DATE, '31-12-2020')

--Создатель.
DECLARE @creator INT
SET @creator = 10314303 --Системный администратор.


--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#NEW_DATA')       IS NOT NULL BEGIN DROP TABLE #NEW_DATA          END --Новая информация о подуслуге (Объем предоставления социальной услуги).
IF OBJECT_ID('tempdb..#OLD_DATA')       IS NOT NULL BEGIN DROP TABLE #OLD_DATA          END --Старая информация о подуслуге (Объем предоставления социальной услуги).
IF OBJECT_ID('tempdb..#INSERTED_DATA')  IS NOT NULL BEGIN DROP TABLE #INSERTED_DATA     END --Вставленная информация.
IF OBJECT_ID('tempdb..#UPDATED_DATA')   IS NOT NULL BEGIN DROP TABLE #UPDATED_DATA      END --Измененная информация (Закрытие подуслуги).


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #NEW_DATA (
    SOC_SERV_OUID           INT,            --ID социальной услуги. 
    SUB_SOC_SERV_NAME       VARCHAR(256),   --Наименование подуслуги (описание).
    SUB_SOC_SERV_PERIOD     VARCHAR(256),   --Периодичность предоставления услуги.
    SUB_SOC_SERV_DEADLINE   VARCHAR(256)    --Срок предоставления услуги.
)
CREATE TABLE #OLD_DATA (
    SUB_SOC_SERV_OUID   INT,            --ID подуслуги.
    SOC_SERV_OUID       INT,            --ID социальной услуги.
    SUB_SOC_SERV_NAME   VARCHAR(256),   --Наименование подуслуги (описание).
    DEGREE_0            INT,            --Степень 0.
    DEGREE_1            INT,            --Степень 1.
    DEGREE_2            INT,            --Степень 2.
    DEGREE_3            INT,            --Степень 3.
    DEGREE_4            INT,            --Степень 4.
    DEGREE_5            INT,            --Степень 5.
    DEGREE_NULL         INT,            --Без степени.
)
CREATE TABLE #INSERTED_DATA (
    SUB_SOC_SERV_OUID INT, --ID подуслуги.
)
CREATE TABLE #UPDATED_DATA (
    SUB_SOC_SERV_OUID   INT,    --ID подуслуги.
    FIN_DATE_OLD        DATE,   --Старая дата окончания.
)


--------------------------------------------------------------------------------------------------------------------------------



--Выборка новых значений.
--INSERT INTO #NEW_DATA(SOC_SERV_OUID, SUB_SOC_SERV_NAME, SUB_SOC_SERV_PERIOD, SUB_SOC_SERV_DEADLINE)
--VALUES 
---Вставить значения.
--...


--------------------------------------------------------------------------------------------------------------------------------


--Выборка подуслуг, которые будут закрыты.
INSERT INTO #OLD_DATA (SUB_SOC_SERV_OUID, SOC_SERV_OUID, SUB_SOC_SERV_NAME, DEGREE_0, DEGREE_1, DEGREE_2, DEGREE_3, DEGREE_4, DEGREE_5, DEGREE_NULL)
SELECT
    t.SUB_SOC_SERV_OUID,
    t.SOC_SERV_OUID,    
    t.SUB_SOC_SERV_NAME,
    t.DEGREE_0,
    t.DEGREE_1,
    t.DEGREE_2,
    t.DEGREE_3,
    t.DEGREE_4,
    t.DEGREE_5,
    t.DEGREE_NULL
FROM (
    SELECT
        subSocServ.A_OUID                       AS SUB_SOC_SERV_OUID,
        subSocServ.A_SOC_SERV                   AS SOC_SERV_OUID,
        subSocServ.A_NAME                       AS SUB_SOC_SERV_NAME,
        CONVERT(DATE, subSocServ.A_START_DATE)  AS SUB_SOC_SERV_START_DATE,
        CONVERT(DATE, subSocServ.A_FIN_DATE)    AS SUB_SOC_SERV_END_DATE,
        subSocServ.A_DEGREE_0                   AS DEGREE_0,
        subSocServ.A_DEGREE_1                   AS DEGREE_1,
        subSocServ.A_DEGREE_2                   AS DEGREE_2,
        subSocServ.A_DEGREE_3                   AS DEGREE_3,
        subSocServ.A_DEGREE_4                   AS DEGREE_4,
        subSocServ.A_DEGREE_5                   AS DEGREE_5,
        subSocServ.A_DEGREE_NULL                AS DEGREE_NULL,
        --Для выбора последней подуслуги данной подуслуги.
        ROW_NUMBER() OVER (PARTITION BY subSocServ.A_SOC_SERV, subSocServ.A_SOC_SERV ORDER BY subSocServ.A_START_DATE DESC) AS gnum
    FROM SPR_SUB_SOC_SERV subSocServ --Справочник подуслуг.
    ----Новые данные.
        INNER JOIN #NEW_DATA newData
            ON newData.SOC_SERV_OUID = subSocServ.A_SOC_SERV        --К одной услуге относятся.
                AND newData.SUB_SOC_SERV_NAME = subSocServ.A_NAME   --Совпадают наименование подуслуги.
    WHERE subSocServ.A_STATUS = 10 --Статус в БД "Действует".
) t
WHERE t.gnum = 1                                        --Последний тариф.
    AND t.SUB_SOC_SERV_END_DATE IS NULL                 --Нет даты окончания (Не закрыт тариф).
    AND t.SUB_SOC_SERV_START_DATE < @endDateOldSubServ  --Дата начала не в будущем.


--------------------------------------------------------------------------------------------------------------------------------


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////Начало транзакции///////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


BEGIN TRANSACTION


--------------------------------------------------------------------------------------------------------------------------------


--Вставка новых подууслуг.
INSERT INTO SPR_SUB_SOC_SERV (A_CROWNER, A_TS, A_SYSTEMCLASS, A_CREATEDATE, A_STATUS, A_SOC_SERV, A_TERM_GRANT, A_NAME, A_A_PERIOD, A_START_DATE, A_FIN_DATE, A_DEGREE_0, A_DEGREE_1, A_DEGREE_2, A_DEGREE_3, A_DEGREE_4, A_DEGREE_5, A_DEGREE_NULL)
OUTPUT inserted.A_OUID INTO #INSERTED_DATA(SUB_SOC_SERV_OUID) --Сохранение добавленных подуслуг.
SELECT
    @creator                        AS A_CROWNER,      --Создатель.
    @dateLaunch                     AS A_TS,           --Время изменения.
    11352013                        AS A_SYSTEMCLASS,  --Класс объекта.
    @dateLaunch                     AS A_CREATEDATE,   --Дата создания.
    10                              AS A_STATUS,       --Статус.
    newData.SOC_SERV_OUID           AS A_SOC_SERV,     --Социальная услуга.
    newData.SUB_SOC_SERV_DEADLINE   AS A_TERM_GRANT,   --Срок предоставления услуги.
    newData.SUB_SOC_SERV_NAME       AS A_NAME,         --Наименование подуслуги (описание).
    newData.SUB_SOC_SERV_PERIOD     AS A_A_PERIOD,     --Периодичность предоставления услуги.
    @startDateNewSubServ            AS A_START_DATE,   --Дата начала действия.
    CAST(NULL AS DATE)              AS A_FIN_DATE,     --Дата окончания действия.
    oldData.DEGREE_0                AS A_DEGREE_0,     --Степень 0.
    oldData.DEGREE_1                AS A_DEGREE_1,     --Степень 1.
    oldData.DEGREE_2                AS A_DEGREE_2,     --Степень 2.
    oldData.DEGREE_3                AS A_DEGREE_3,     --Степень 3.
    oldData.DEGREE_4                AS A_DEGREE_4,     --Степень 4.
    oldData.DEGREE_5                AS A_DEGREE_5,     --Степень 5.
    oldData.DEGREE_NULL             AS A_DEGREE_NULL   --Без степени.
FROM #OLD_DATA oldData
    ----Новые данные.
        INNER JOIN #NEW_DATA newData
            ON newData.SOC_SERV_OUID = oldData.SUB_SOC_SERV_OUID            --К одной услуге относятся.
                AND newData.SUB_SOC_SERV_NAME = oldData.SUB_SOC_SERV_NAME   --Совпадают наименование подуслуги.


--------------------------------------------------------------------------------------------------------------------------------


--Закрытие старых подуслуг.
UPDATE subSocServ
SET subSocServ.A_FIN_DATE = @endDateOldSubServ
OUTPUT inserted.A_OUID, deleted.A_FIN_DATE INTO #UPDATED_DATA(SUB_SOC_SERV_OUID, FIN_DATE_OLD) --Сохранение старого значения.
FROM SPR_SUB_SOC_SERV subSocServ --Справочник подуслуг.
WHERE subSocServ.A_OUID IN (SELECT SUB_SOC_SERV_OUID FROM #OLD_DATA)


--------------------------------------------------------------------------------------------------------------------------------


COMMIT 


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////Конец транзакции////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


--------------------------------------------------------------------------------------------------------------------------------


--Проверка вставленных подуслуг.
SELECT
    subSocServ.*   
FROM #INSERTED_DATA insertedData
--Справочник подуслуг.
    INNER JOIN SPR_SUB_SOC_SERV subSocServ 
        ON subSocServ.A_OUID = insertedData.SUB_SOC_SERV_OUID


--------------------------------------------------------------------------------------------------------------------------------


--Проверка закрытия.
SELECT 
    subSocServ.*,
    updatedData.FIN_DATE_OLD
FROM SPR_SUB_SOC_SERV subSocServ 
    INNER JOIN #UPDATED_DATA updatedData
        ON updatedData.SUB_SOC_SERV_OUID = subSocServ.A_OUID


--------------------------------------------------------------------------------------------------------------------------------