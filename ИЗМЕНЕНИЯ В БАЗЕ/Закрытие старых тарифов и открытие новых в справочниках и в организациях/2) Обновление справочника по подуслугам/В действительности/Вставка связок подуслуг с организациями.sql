USE test
GO


--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#CLOUSED')                    IS NOT NULL BEGIN DROP TABLE #CLOUSED                   END --Закрытые подуслуги.
IF OBJECT_ID('tempdb..#INSERTED')                   IS NOT NULL BEGIN DROP TABLE #INSERTED                  END --Открытые подуслуги.
IF OBJECT_ID('tempdb..#ONE_MORE_SUB_IN_SOC_SERV')   IS NOT NULL BEGIN DROP TABLE #ONE_MORE_SUB_IN_SOC_SERV  END --Услуги с больше одного закрытыми подуслугами.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #CLOUSED (
    SOC_SERV_OUID       INT,    --ID услуги.
    SUB_SOC_SERV_OUID   INT,    --ID подуслуги.
)
CREATE TABLE #INSERTED (
    SOC_SERV_OUID       INT,    --ID услуги.
    SUB_SOC_SERV_OUID   INT,    --ID подуслуги.
)
CREATE TABLE #ONE_MORE_SUB_IN_SOC_SERV (
    SOC_SERV_OUID   INT,    --ID услуги.
    COUNT_SUB_SERV  INT     --Количество закрытых подуслуг.
)



--------------------------------------------------------------------------------------------------------------------------------


--Закрытые подуслуги.
INSERT INTO #CLOUSED (SOC_SERV_OUID, SUB_SOC_SERV_OUID)
SELECT
    subSocServ.A_SOC_SERV   AS SOC_SERV_OUID,
    subSocServ.A_OUID       AS SUB_SOC_SERV_OUID
FROM SPR_SUB_SOC_SERV subSocServ            --Подуслуги.
WHERE subSocServ.A_STATUS = 10              --Статус в БД "Действует".
    AND subSocServ.A_FIN_DATE IS NOT NULL   --Есть дата окончания.
    AND CONVERT(DATE, subSocServ.A_TS) BETWEEN CONVERT(DATE, '17-02-2021') AND CONVERT(DATE, '24-02-2021')  --Измененные.
ORDER BY subSocServ.A_SOC_SERV, subSocServ.A_OUID


--------------------------------------------------------------------------------------------------------------------------------


--Открытые подуслуги.
INSERT INTO #INSERTED (SOC_SERV_OUID, SUB_SOC_SERV_OUID)
SELECT
    subSocServ.A_SOC_SERV   AS SOC_SERV_OUID,
    subSocServ.A_OUID       AS SUB_SOC_SERV_OUID
FROM SPR_SUB_SOC_SERV subSocServ        --Подуслуги.
WHERE subSocServ.A_STATUS = 10          --Статус в БД "Действует".
    AND subSocServ.A_FIN_DATE IS NULL   --Отсутствует дата окончания.
    AND CONVERT(DATE, subSocServ.A_TS) BETWEEN CONVERT(DATE, '17-02-2021') AND CONVERT(DATE, '24-02-2021')  --Измененные.
ORDER BY subSocServ.A_SOC_SERV, subSocServ.A_OUID


--------------------------------------------------------------------------------------------------------------------------------


--Услуги, которые имеют несколько закрытых подуслуг.
INSERT INTO #ONE_MORE_SUB_IN_SOC_SERV(SOC_SERV_OUID, COUNT_SUB_SERV)
SELECT 
    cloused.SOC_SERV_OUID   AS SOC_SERV_OUID,
    COUNT(*)                AS COUNT_SUB_SERV
FROM #CLOUSED cloused   --Закрытые.
GROUP BY cloused.SOC_SERV_OUID
HAVING COUNT(*) > 1


--------------------------------------------------------------------------------------------------------------------------------


--Вставка одиночных связок.
INSERT INTO LINK_USON_SOC_SERV (A_TS, A_CREATEDATE, A_FROMID, A_TOID)
SELECT
    GETDATE()                   AS A_TS,
    GETDATE()                   AS A_CREATEDATE,
    link.A_FROMID               AS A_FROMID,
    inserted.SUB_SOC_SERV_OUID  AS A_TOID
FROM LINK_USON_SOC_SERV link    --Связка Услуг УСОН - и подуслуг.
----Закрытые.
    INNER JOIN #CLOUSED closed  
        ON closed.SUB_SOC_SERV_OUID = link.A_TOID --Связка с существующей связкой.
----Открытые.
    INNER JOIN #INSERTED inserted   
        ON inserted.SOC_SERV_OUID = closed.SOC_SERV_OUID    --Связка с закрытой услугой.
WHERE closed.SOC_SERV_OUID NOT IN ( --Услуга не имеет несколько подуслуг.
    SELECT SOC_SERV_OUID FROM #ONE_MORE_SUB_IN_SOC_SERV
)
    AND inserted.SUB_SOC_SERV_OUID NOT IN (859, 860)    --Уже вставлено.



--------------------------------------------------------------------------------------------------------------------------------


--Вставка множественных связок.
INSERT INTO LINK_USON_SOC_SERV (A_TS, A_CREATEDATE, A_FROMID, A_TOID)
SELECT
    GETDATE()                   AS A_TS,
    GETDATE()                   AS A_CREATEDATE,
    t.ORGANIZATION              AS A_FROMID,
    inserted.SUB_SOC_SERV_OUID  AS A_TOID
FROM #INSERTED inserted   
    INNER JOIN (
        SELECT DISTINCT
            closed.SOC_SERV_OUID    AS SOC_SERV_OUID,
            link.A_FROMID           AS ORGANIZATION
        FROM LINK_USON_SOC_SERV link    --Связка Услуг УСОН - и подуслуг.
        ----Закрытые.
            INNER JOIN #CLOUSED closed  
                ON closed.SUB_SOC_SERV_OUID = link.A_TOID --Связка с существующей связкой.
    ) t ON t.SOC_SERV_OUID = inserted.SOC_SERV_OUID
WHERE inserted.SOC_SERV_OUID IN ( --Услуга имеет несколько подуслуг.
    SELECT SOC_SERV_OUID FROM #ONE_MORE_SUB_IN_SOC_SERV
)

--------------------------------------------------------------------------------------------------------------------------------