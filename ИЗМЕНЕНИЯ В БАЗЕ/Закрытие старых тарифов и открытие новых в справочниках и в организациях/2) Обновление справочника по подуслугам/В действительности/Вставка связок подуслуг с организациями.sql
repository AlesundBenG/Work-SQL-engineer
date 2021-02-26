USE test
GO


--------------------------------------------------------------------------------------------------------------------------------


--�������� ��������� ������.
IF OBJECT_ID('tempdb..#CLOUSED')                    IS NOT NULL BEGIN DROP TABLE #CLOUSED                   END --�������� ���������.
IF OBJECT_ID('tempdb..#INSERTED')                   IS NOT NULL BEGIN DROP TABLE #INSERTED                  END --�������� ���������.
IF OBJECT_ID('tempdb..#ONE_MORE_SUB_IN_SOC_SERV')   IS NOT NULL BEGIN DROP TABLE #ONE_MORE_SUB_IN_SOC_SERV  END --������ � ������ ������ ��������� �����������.


--------------------------------------------------------------------------------------------------------------------------------


--�������� ��������� ������.
CREATE TABLE #CLOUSED (
    SOC_SERV_OUID       INT,    --ID ������.
    SUB_SOC_SERV_OUID   INT,    --ID ���������.
)
CREATE TABLE #INSERTED (
    SOC_SERV_OUID       INT,    --ID ������.
    SUB_SOC_SERV_OUID   INT,    --ID ���������.
)
CREATE TABLE #ONE_MORE_SUB_IN_SOC_SERV (
    SOC_SERV_OUID   INT,    --ID ������.
    COUNT_SUB_SERV  INT     --���������� �������� ��������.
)



--------------------------------------------------------------------------------------------------------------------------------


--�������� ���������.
INSERT INTO #CLOUSED (SOC_SERV_OUID, SUB_SOC_SERV_OUID)
SELECT
    subSocServ.A_SOC_SERV   AS SOC_SERV_OUID,
    subSocServ.A_OUID       AS SUB_SOC_SERV_OUID
FROM SPR_SUB_SOC_SERV subSocServ            --���������.
WHERE subSocServ.A_STATUS = 10              --������ � �� "���������".
    AND subSocServ.A_FIN_DATE IS NOT NULL   --���� ���� ���������.
    AND CONVERT(DATE, subSocServ.A_TS) BETWEEN CONVERT(DATE, '17-02-2021') AND CONVERT(DATE, '24-02-2021')  --����������.
ORDER BY subSocServ.A_SOC_SERV, subSocServ.A_OUID


--------------------------------------------------------------------------------------------------------------------------------


--�������� ���������.
INSERT INTO #INSERTED (SOC_SERV_OUID, SUB_SOC_SERV_OUID)
SELECT
    subSocServ.A_SOC_SERV   AS SOC_SERV_OUID,
    subSocServ.A_OUID       AS SUB_SOC_SERV_OUID
FROM SPR_SUB_SOC_SERV subSocServ        --���������.
WHERE subSocServ.A_STATUS = 10          --������ � �� "���������".
    AND subSocServ.A_FIN_DATE IS NULL   --����������� ���� ���������.
    AND CONVERT(DATE, subSocServ.A_TS) BETWEEN CONVERT(DATE, '17-02-2021') AND CONVERT(DATE, '24-02-2021')  --����������.
ORDER BY subSocServ.A_SOC_SERV, subSocServ.A_OUID


--------------------------------------------------------------------------------------------------------------------------------


--������, ������� ����� ��������� �������� ��������.
INSERT INTO #ONE_MORE_SUB_IN_SOC_SERV(SOC_SERV_OUID, COUNT_SUB_SERV)
SELECT 
    cloused.SOC_SERV_OUID   AS SOC_SERV_OUID,
    COUNT(*)                AS COUNT_SUB_SERV
FROM #CLOUSED cloused   --��������.
GROUP BY cloused.SOC_SERV_OUID
HAVING COUNT(*) > 1


--------------------------------------------------------------------------------------------------------------------------------


--������� ��������� ������.
INSERT INTO LINK_USON_SOC_SERV (A_TS, A_CREATEDATE, A_FROMID, A_TOID)
SELECT
    GETDATE()                   AS A_TS,
    GETDATE()                   AS A_CREATEDATE,
    link.A_FROMID               AS A_FROMID,
    inserted.SUB_SOC_SERV_OUID  AS A_TOID
FROM LINK_USON_SOC_SERV link    --������ ����� ���� - � ��������.
----��������.
    INNER JOIN #CLOUSED closed  
        ON closed.SUB_SOC_SERV_OUID = link.A_TOID --������ � ������������ �������.
----��������.
    INNER JOIN #INSERTED inserted   
        ON inserted.SOC_SERV_OUID = closed.SOC_SERV_OUID    --������ � �������� �������.
WHERE closed.SOC_SERV_OUID NOT IN ( --������ �� ����� ��������� ��������.
    SELECT SOC_SERV_OUID FROM #ONE_MORE_SUB_IN_SOC_SERV
)
    AND inserted.SUB_SOC_SERV_OUID NOT IN (859, 860)    --��� ���������.



--------------------------------------------------------------------------------------------------------------------------------


--������� ������������� ������.
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
        FROM LINK_USON_SOC_SERV link    --������ ����� ���� - � ��������.
        ----��������.
            INNER JOIN #CLOUSED closed  
                ON closed.SUB_SOC_SERV_OUID = link.A_TOID --������ � ������������ �������.
    ) t ON t.SOC_SERV_OUID = inserted.SOC_SERV_OUID
WHERE inserted.SOC_SERV_OUID IN ( --������ ����� ��������� ��������.
    SELECT SOC_SERV_OUID FROM #ONE_MORE_SUB_IN_SOC_SERV
)

--------------------------------------------------------------------------------------------------------------------------------