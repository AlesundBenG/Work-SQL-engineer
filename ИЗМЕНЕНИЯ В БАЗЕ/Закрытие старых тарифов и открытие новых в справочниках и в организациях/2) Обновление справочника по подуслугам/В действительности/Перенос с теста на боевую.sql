--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#TEST_DATA') IS NOT NULL BEGIN DROP TABLE #TEST_DATA END --Информация с теста.
IF OBJECT_ID('tempdb..#INSERTED_DATA')  IS NOT NULL BEGIN DROP TABLE #INSERTED_DATA     END --Вставленная информация.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #INSERTED_DATA (
    SUB_SOC_SERV_OUID INT, --ID подуслуги.
)


--------------------------------------------------------------------------------------------------------------------------------


USE test 
GO

SELECT
* 
INTO #TEST_DATA
FROM SPR_SUB_SOC_SERV subSocServ
WHERE CONVERT(DATE, A_TS) = CONVERT(DATE, '19-02-2021')
AND A_STATUS = 10


--------------------------------------------------------------------------------------------------------------------------------


USE esrn
GO

/*
--Закрытие старых.
UPDATE subSocServ
SET subSocServ.A_FIN_DATE = testData.A_FIN_DATE,
    subSocServ.A_TS = testData.A_TS
FROM SPR_SUB_SOC_SERV subSocServ 
    INNER JOIN #TEST_DATA testData
        ON testData.A_OUID = subSocServ.A_OUID
   
--Открытие новых.
INSERT INTO SPR_SUB_SOC_SERV(A_CROWNER,A_TS,A_SYSTEMCLASS,A_CREATEDATE,A_STATUS,A_SOC_SERV,A_TERM_GRANT,A_NAME,A_A_PERIOD,A_START_DATE,A_FIN_DATE,A_DEGREE_1,A_DEGREE_2,A_DEGREE_3,A_DEGREE_4,A_DEGREE_5,A_DEGREE_0,A_DEGREE_NULL)
OUTPUT inserted.A_OUID INTO #INSERTED_DATA(SUB_SOC_SERV_OUID) --Сохранение добавленных подуслуг.
SELECT
    testData.A_CROWNER,
    testData.A_TS,
    testData.A_SYSTEMCLASS,
    testData.A_CREATEDATE,
    testData.A_STATUS,
    testData.A_SOC_SERV,
    testData.A_TERM_GRANT,
    testData.A_NAME,
    testData.A_A_PERIOD,
    testData.A_START_DATE,
    testData.A_FIN_DATE,
    testData.A_DEGREE_1,
    testData.A_DEGREE_2,
    testData.A_DEGREE_3,
    testData.A_DEGREE_4,
    testData.A_DEGREE_5,
    testData.A_DEGREE_0,
    testData.A_DEGREE_NULL
FROM #TEST_DATA testData 
    LEFT JOIN SPR_SUB_SOC_SERV subSocServ 
        ON subSocServ.A_OUID = testData.A_OUID
WHERE subSocServ.A_OUID IS NULL
*/

--------------------------------------------------------------------------------------------------------------------------------


SELECT * FROM #TEST_DATA
SELECT * FROM #INSERTED_DATA


--------------------------------------------------------------------------------------------------------------------------------