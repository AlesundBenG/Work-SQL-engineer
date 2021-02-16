--------------------------------------------------------------------------------------------------------------------------------


--���� ������� ������� (�������� ������� ������ � �������� ������).
DECLARE @dateLaunch DATETIME
SET @dateLaunch = GETDATE()

--���� ������ �������� ������ ������.
DECLARE @startDateNewTarif DATE
SET @startDateNewTarif = CONVERT(DATE, '15-12-2020')

--���� ��������� ������� ������.
DECLARE @endDateOldTarif DATE
SET @endDateOldTarif = CONVERT(DATE, '31-12-2020')

--���� �������� ������.
DECLARE @dateAcceptance DATE
SET @dateAcceptance = CONVERT(DATE, '15-12-2020')

--���������.
DECLARE @creator INT
SET @creator = 10314303 --��������� �������������.


--------------------------------------------------------------------------------------------------------------------------------


--�������� ��������� ������.
IF OBJECT_ID('tempdb..#NEW_DATA')       IS NOT NULL BEGIN DROP TABLE #NEW_DATA          END --����� ���������� � �������.
IF OBJECT_ID('tempdb..#OLD_DATA')       IS NOT NULL BEGIN DROP TABLE #OLD_DATA          END --������ ���������� � �������.
IF OBJECT_ID('tempdb..#INSERTED_DATA')  IS NOT NULL BEGIN DROP TABLE #INSERTED_DATA     END --����������� ����������.
IF OBJECT_ID('tempdb..#UPDATED_DATA')   IS NOT NULL BEGIN DROP TABLE #UPDATED_DATA      END --���������� ���������� (�������� ������).


--------------------------------------------------------------------------------------------------------------------------------


--�������� ��������� ������.
CREATE TABLE #NEW_DATA (
    SOC_SERV_OUID   INT,            --ID ������.   
    AMOUNT          FLOAT,          --����� �������� ������.
    DISTRICT        VARCHAR(256),   --��������� ��������������� (��������� ���������/�������� ���������/��� ����)
)
CREATE TABLE #OLD_DATA (
    TARIF_OUID      INT,            --ID ������.
    SOC_SERV_OUID   INT,            --ID ���������� ������.
    UNIT            INT,            --������� ���������.
    DISTRICT        VARCHAR(256),   --��������� ���������������.
)
CREATE TABLE #INSERTED_DATA (
    TARIF_OUID INT, --ID ������.
)
CREATE TABLE #UPDATED_DATA (
    TARIF_OUID      INT,    --ID ������.
    FIN_DATE_OLD    DATE,   --������ ���� ���������.
)


--------------------------------------------------------------------------------------------------------------------------------



--������� ����� ��������.
--INSERT INTO #NEW_DATA(SOC_SERV_OUID, AMOUNT, DISTRICT)
--VALUES 
---�������� ��������.
--...


--------------------------------------------------------------------------------------------------------------------------------


--����� ��������� ������� �����.
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
        --��� ������ ��������� ������� �����.
        ROW_NUMBER() OVER (PARTITION BY tarif.A_SOC_SERV, tarif.A_DISTRICT ORDER BY tarif.A_START_DATE DESC) AS gnum
    FROM SPR_REG_SOC_SERV_PERIOD_2018 tarif --������������ ������ �� ���������� ������.
    ----����� ������.
        INNER JOIN #NEW_DATA newData
            ON newData.SOC_SERV_OUID = tarif.A_SOC_SERV --������ �� ������.
                AND newData.DISTRICT = tarif.A_DISTRICT --������ �� ������� ���������������.
    WHERE tarif.A_STATUS = 10 --������ � �� "���������".
) t
WHERE t.gnum = 1                        --��������� �����.
    AND t.TARIF_END_DATE IS NULL        --��� ���� ��������� (�� ������ �����).
    AND t.TARIF_START_DATE < GETDATE()  --���� ������ �� � �������.
    

--------------------------------------------------------------------------------------------------------------------------------


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////������ ����������///////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


BEGIN TRANSACTION


--------------------------------------------------------------------------------------------------------------------------------


--������� ����� �������.
INSERT INTO SPR_REG_SOC_SERV_PERIOD_2018 (GUID, A_CROWNER, A_TS, A_SYSTEMCLASS, A_CREATEDATE, A_STATUS, A_SOC_SERV, A_DATE, A_START_DATE, A_FIN_DATE, A_AMOUNT, A_UNIT, A_DISTRICT)
OUTPUT inserted.A_OUID INTO #INSERTED_DATA(TARIF_OUID) --���������� ����������� �������.
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
    ----����� ������.
    INNER JOIN #NEW_DATA newData
        ON newData.SOC_SERV_OUID = oldData.SOC_SERV_OUID    --������ �� ������.
            AND oldData.DISTRICT = newData.DISTRICT         --������ �� ������� ���������������.


--------------------------------------------------------------------------------------------------------------------------------


--�������� ������ �������.
UPDATE tarif
SET tarif.A_FIN_DATE = @endDateOldTarif
OUTPUT inserted.A_OUID, deleted.A_FIN_DATE INTO #UPDATED_DATA(TARIF_OUID, FIN_DATE_OLD) --���������� ������� ��������.
FROM SPR_REG_SOC_SERV_PERIOD_2018 tarif
WHERE tarif.A_OUID IN (SELECT TARIF_OUID FROM #OLD_DATA)


--------------------------------------------------------------------------------------------------------------------------------


COMMIT 


--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////����� ����������////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


--------------------------------------------------------------------------------------------------------------------------------


--�������� ����������� �������.
SELECT
    tarif.*   
FROM #INSERTED_DATA insertedData
    INNER JOIN SPR_REG_SOC_SERV_PERIOD_2018 tarif
        ON tarif.A_OUID = insertedData.TARIF_OUID


--------------------------------------------------------------------------------------------------------------------------------


--�������� ��������.
SELECT 
    tarif.*,
    updatedData.FIN_DATE_OLD
FROM SPR_REG_SOC_SERV_PERIOD_2018 tarif
    INNER JOIN #UPDATED_DATA updatedData
        ON updatedData.TARIF_OUID = tarif.A_OUID 


--------------------------------------------------------------------------------------------------------------------------------