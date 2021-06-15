--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


--{params.mspLkNpdId}
DECLARE @mspLkNpdId INT
SET @mspLkNpdId = 310

--{ACTIVESTATUS}
DECLARE @ACTIVESTATUS INT
SET @ACTIVESTATUS = 10

 --{PPRCONST.warCompPercent}
DECLARE @warCompPercent FLOAT
SET @warCompPercent = 60
 
 
 --//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


 --{params.petitionId}
 DECLARE @petitionId INT
 SET @petitionId = 6514261
--6514261   Мать
--6514276   Дочь
--6514294   Сын

--{params.personalCardId}
DECLARE @personalCardId INT
SET @personalCardId = 1024106 
--1024106 Мать
--1653802 Дочь
--1030196 Сын

--{params.spherePcId} 
DECLARE @spherePcId INT
SET @spherePcId = 6514261

--{params.startDate}
DECLARE @startDate DATE
SET @startDate = CONVERT(DATE, '01-04-2021')


--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

--{ALG.doc_regFlatPersonList}
DECLARE @doc_regFlatPersonList INT
SELECT 
    @doc_regFlatPersonList  = docId  
FROM (
    SELECT 
        doc.OUID as docId, 
        ROW_NUMBER() OVER(ORDER BY appeal.A_DATE_REG DESC, doc.ISSUEEXTENSIONSDATE DESC, doc.OUID DESC) AS num      
    FROM (
        SELECT @petitionId AS OUID, NULL AS A_PETITION_TYPE
    ) pet 
        INNER JOIN WM_APPEAL_NEW appeal ON pet.OUID = appeal.OUID    
            AND (appeal.A_STATUS IS NULL OR appeal.A_STATUS = @ACTIVESTATUS) 
            AND (pet.A_PETITION_TYPE IS NULL OR pet.A_PETITION_TYPE = 1 OR DATEDIFF(DAY,appeal.A_DATE_REG,@startDate) >= 0)   
        INNER JOIN SPR_LINK_APPEAL_DOC link ON link.FROMID = pet.OUID      
        INNER JOIN WM_ACTDOCUMENTS doc ON link.TOID = doc.OUID    
            AND (doc.A_STATUS = @ACTIVESTATUS OR doc.A_STATUS IS NULL)      
        INNER JOIN PPR_DOC docType ON doc.DOCUMENTSTYPE = docType.A_ID            
            AND docType.A_CODE = 'regFlatPersonList'  
) doc  
 WHERE doc.num = 1

--{ALG.doc_regFlatPersonList_addr}
DECLARE @doc_regFlatPersonList_addr INT
SELECT @doc_regFlatPersonList_addr = A_REGFLAT 
FROM WM_ACTDOCUMENTS 
WHERE OUID = @doc_regFlatPersonList

--{ALG.doc_regFlatPersonListLgot_cnt}
DECLARE @doc_regFlatPersonListLgot_cnt INT
SELECT @doc_regFlatPersonListLgot_cnt = ISNULL(doc.A_AMOUNT_PERSON,COUNT(DISTINCT pc.OUID)) 
FROM WM_ACTDOCUMENTS doc 
    LEFT JOIN LINK_ACTDOC_PC docLink   
    INNER JOIN WM_PERSONAL_CARD pc 
        ON docLink.A_TOID = pc.OUID   
            AND (pc.A_STATUS = @ACTIVESTATUS OR pc.A_STATUS IS NULL) 
                ON doc.OUID = docLink.A_FROMID 
WHERE doc.OUID = @doc_regFlatPersonList 
GROUP BY doc.OUID, doc.A_AMOUNT_PERSON

--{ALG.doc_regFlatPersonList_cnt}
DECLARE @doc_regFlatPersonList_cnt INT
SELECT @doc_regFlatPersonList_cnt = ISNULL(doc.A_AMOUNT_PERSON,COUNT(DISTINCT pc.OUID)) 
FROM WM_ACTDOCUMENTS doc 
    LEFT JOIN LINK_ACTDOC_PC docLink   
    INNER JOIN WM_PERSONAL_CARD pc 
        ON docLink.A_TOID = pc.OUID AND (pc.A_STATUS = @ACTIVESTATUS OR pc.A_STATUS IS NULL) 
        ON doc.OUID = docLink.A_FROMID 
WHERE doc.OUID = @doc_regFlatPersonList 
GROUP BY doc.OUID, doc.A_AMOUNT_PERSON


--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


--{DOC.Military_st24_p4}
IF OBJECT_ID('tempdb..#Military_st24_p4') IS NOT NULL BEGIN DROP TABLE #Military_st24_p4 END 
SELECT A_ID, A_NAME
INTO #Military_st24_p4
FROM PPR_DOC 
WHERE A_CODE = 'Military_st24_p4'

--{DOC.Military_78FZ_st2} 
IF OBJECT_ID('tempdb..#Military_78FZ_st2') IS NOT NULL BEGIN DROP TABLE #Military_78FZ_st2 END 
SELECT A_ID, A_NAME
INTO #Military_78FZ_st2
FROM PPR_DOC 
WHERE A_CODE = 'Military_78FZ_st2'

--DOC.Military_fz247_st10
IF OBJECT_ID('tempdb..#Military_fz247_st10') IS NOT NULL BEGIN DROP TABLE #Military_fz247_st10 END 
SELECT A_ID, A_NAME
INTO #Military_fz247_st10
FROM PPR_DOC 
WHERE A_CODE = 'Military_fz247_st10'

--DOC.Military_fz283
IF OBJECT_ID('tempdb..#Military_fz283') IS NOT NULL BEGIN DROP TABLE #Military_fz283 END 
SELECT A_ID, A_NAME
INTO #Military_fz283
FROM PPR_DOC 
WHERE A_CODE = 'Military_fz283'


--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


SELECT 
    SUM(amount)
FROM (
        SELECT 
            @spherePcId AS pcId, 
            SUM(amount)/COUNT(DISTINCT monthNum) AS amount
        FROM (
                SELECT 
                    CASE 
                        WHEN calcTypeCode = 'point' THEN CASE WHEN recPcId = @personalCardId AND recPcId = @spherePcId THEN 1 ELSE 0 END
                        ELSE 1
                    END AS partNumerator,
                    CASE 
                        WHEN calcTypeCode = 'point' THEN 1 
                        WHEN calcTypeCode IN ('area','livearea') THEN ISNULL(regCnt,@doc_regFlatPersonList_cnt)
                        ELSE ISNULL(regCnt,@doc_regFlatPersonList_cnt) 
                    END AS partDenominator,
            ----------------------------------------------------------------------------------------------
                    CASE 
                        --Старый расчет по долям.
                        WHEN CONVERT(DATE, recDate) < CONVERT(DATE, '20200801') THEN
                            CASE 
                                WHEN recAmType IN (68,69,70) then round(payAmount*@warCompPercent/100,2) 
                                WHEN recAmType IN (11,20,39,42,45,81,25, 388, 391, 392) then round((payAmount/cast(ISNULL(regCnt,registered) AS float))*cast(ISNULL(lgotCnt,@doc_regFlatPersonListLgot_cnt) AS float) *@warCompPercent/100.00,2)
                                WHEN recAmType IN (162) and y.SvedOLd = 'naim' then round((payAmount/cast(ISNULL(regCnt,registered) AS float))*cast(ISNULL(lgotCnt,@doc_regFlatPersonListLgot_cnt) AS float) *@warCompPercent/100.00,2)
                                WHEN recAmType IN (162,38) and y.SvedOLd = 'sobst' then round((payAmount*cast(y.shareSobst AS float))*@warCompPercent/100,2) 
                            END
                        --Новый расчет по количеству. 
                        ELSE 
                            CASE 
                                WHEN recAmType IN (68,69,70) then round(payAmount*@warCompPercent/100,2) 
	                            WHEN recAmType IN (11,20,39,42,45,81,25, 388, 391, 392, 162, 38) then round((payAmount/cast(ISNULL(regCnt,registered) AS float))*cast(ISNULL(lgotCnt,@doc_regFlatPersonListLgot_cnt) AS float) *@warCompPercent/100.00,2)
                            END 
                    END amount,
            ----------------------------------------------------------------------------------------------
                    payAmount,
                    recPcId, recDate, recAmType, DATEDIFF(MONTH,recDate,@startDate) AS monthNum, 
                    MAX(CASE WHEN DATEDIFF(MONTH,recDate,recCreateDate) <= 48 AND recNum = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY recPcId, recType) advance,
                    MAX(recDate) OVER(PARTITION BY recPcId, recType) AS recAmMaxDate
                FROM (
                        SELECT 
                            rec.A_RECEIPT_TYPE AS recType,      rec.A_PAYER AS recPcId,     rec.A_PAYMENT_DATE AS recDate, 
                            rec.A_CREATEDATE AS recCreateDate,  rec.A_NUM_LIVING AS regCnt, rec.A_NUM_LGOTA AS lgotCnt,
                            recAm.A_NAME_AMOUNT AS recAmType,   recAm.A_PAY AS payAmount,   recAmCalcType.A_CODE AS calcTypeCode,
                            wa.A_AMOUNT_PERSON AS registered, 
                            ROW_NUMBER() OVER(PARTITION BY rec.A_OUID, recAm.A_OUID ORDER BY recTypeLink.A_OUID) AS num,
                            DENSE_RANK() OVER(PARTITION BY rec.A_PAYER, rec.A_RECEIPT_TYPE ORDER BY YEAR(rec.A_PAYMENT_DATE) DESC, MONTH(rec.A_PAYMENT_DATE) DESC) AS recNum,
                            DENSE_RANK() OVER(PARTITION BY rec.A_PAYER, recAm.A_NAME_AMOUNT ORDER BY YEAR(rec.A_PAYMENT_DATE) DESC, MONTH(rec.A_PAYMENT_DATE) DESC) AS recAmNum
                        FROM WM_RECEIPT rec --Квитанция.
                        ----Тип платежного документа.
                            INNER JOIN SPR_RECEIPT_TYPE recType ON recType.A_OUID = rec.A_RECEIPT_TYPE
                        ----Связка МСП-ЛК-НПД - тип квитанции.
                            INNER JOIN SPR_LINK_MSP_RTYPE recTypeLink ON recTypeLink.TOID = recType.A_OUID
                                AND recTypeLink.FROMID = @mspLkNpdId
                        ----Детализация платежного документа. 
                            INNER JOIN WM_RECEIPT_AMOUNT recAm ON recAm.A_RECEIPT = rec.A_OUID
                                AND ISNULL(recAm.A_STATUS, @ACTIVESTATUS) = @ACTIVESTATUS --Статус в БД "Действует".
                                AND recAm.A_NAME_AMOUNT IN (70, 68, 69, 11, 20, 39, 42, 45, 81, 25, 38, 162, 388, 391, 392) --Виды услуг.
                                AND (recAm.A_NAME_AMOUNT = 69 AND rec.A_PAYER = @personalCardId OR recAm.A_NAME_AMOUNT <> 69) --За телефон только у плательщика.
                        ----Класс связки МСП-ЛК-НПД - Вид ЖКУ.
                            INNER JOIN SPR_LINK_NPD_MSP_CAT_HCS recAmTypeLink ON recAmTypeLink.TOID = recAm.A_NAME_AMOUNT
                                AND recAmTypeLink.FROMID = @mspLkNpdId
                        ----Справочник видов расчета льгот.
                            LEFT JOIN SPR_CALC_HCSTYPE recAmCalcType ON recAmCalcType.A_OUID = recAmTypeLink.A_CALC_TYPE
                        ----Класс связки перечьня лиц документа и ЛД.
                            LEFT JOIN LINK_ACTDOC_PC docLink ON docLink.A_FROMID = @doc_regFlatPersonList  
                        ----Личное дело гражданина.
                            INNER JOIN WM_PERSONAL_CARD docPc ON docLink.A_TOID = docPc.OUID
                                AND ISNULL(docPc.A_STATUS, @ACTIVESTATUS) = @ACTIVESTATUS
                        ----Действующие документы.
                            LEFT JOIN WM_ACTDOCUMENTS wa ON wa.OUID = @doc_regFlatPersonList 
                                AND ISNULL(wa.A_STATUS, @ACTIVESTATUS) = @ACTIVESTATUS
                        WHERE rec.A_ADDR_ID = @doc_regFlatPersonList_addr --Квитанция по адресу, указанному в документе о совместно зарегистрированных.
                            AND rec.A_FACT = 1 --Фактическая оплата.
                            AND rec.A_PAYER = ISNULL(docPc.OUID, @personalCardId) --Квитанции людей, которые указаны в перечне лиц документа совместно зарегистрированных.
                            AND ISNULL(rec.A_STATUS, @ACTIVESTATUS)= @ACTIVESTATUS --Статус квитанции в БД "Действует".
                ) rec 
                LEFT JOIN (
                        SELECT	
                            --Доли.
		                    ISNULL(SUM(CASE
                                WHEN ISNULL(Sobstv.A_PARTDENOMPART, 0) <> 0 
                                    THEN CAST(Sobstv.A_PARTNUMPART AS FLOAT) / CAST(Sobstv.A_PARTDENOMPART AS FLOAT)	
                                    ELSE Sobstv.A_PART
				                END), 1
                            ) AS shareSobst,
                            --Найм или собственность.
                            CASE 
                                WHEN EXISTS (
					                SELECT 1				
					                FROM SPR_LINK_APPEAL_DOC linkDoc 			
                                        INNER JOIN  WM_ACTDOCUMENTS docNaim ON docNaim.OUID = linkDoc.TOID 
                                            AND docNaim.DOCUMENTSTYPE IN (2130, 2131, 2132) --Договоры найма.
					                WHERE FROMID = @petitionId
                                ) 
                                    THEN 'naim'
					                ELSE 'sobst'
                            END SvedOLd 
		                FROM WM_PETITION pet --Заявление
		                ----Класс связки Обращения-Документы.
                            INNER JOIN SPR_LINK_APPEAL_DOC linkDoc ON pet.OUID = linkDoc.FROMID
                        ----Действующие документы.
                            INNER JOIN WM_ACTDOCUMENTS doc ON doc.OUID = linkDoc.TOID
                                AND doc.A_STATUS = @ACTIVESTATUS   
                                AND (doc.DOCUMENTSTYPE in (SELECT A_ID FROM #Military_st24_p4)
                                    OR doc.DOCUMENTSTYPE in (SELECT A_ID FROM #Military_78FZ_st2)
                                    OR doc.DOCUMENTSTYPE in (SELECT A_ID FROM #Military_fz247_st10)
                                    OR doc.DOCUMENTSTYPE in (SELECT A_ID FROM #Military_fz283)
                                )
                        ----Право собственности.
                            LEFT JOIN (
				                SELECT 
				                    docSobst.OUID, wo.A_START_OWN_DATE, wo.A_END_OWN_DATE,
                                    linkDoc1.FROMID, wo.A_PARTDENOMPART, wo.A_PARTNUMPART,
                                    wo.A_PART, wo.A_OWNER_ID
				                FROM SPR_LINK_APPEAL_DOC linkDoc1 			
                                    INNER JOIN WM_ACTDOCUMENTS docSobst ON docSobst.OUID = linkDoc1.TOID 
                                        AND docSobst.DOCUMENTSTYPE IN (3800, 4196, 4017)
                                    LEFT JOIN WM_OWNING wo ON docSobst.A_ESTATE = wo.A_OUID  
				                WHERE docSobst.A_STATUS = 10				
                            ) Sobstv ON pet.OUID = Sobstv.FROMID AND Sobstv.A_OWNER_ID = doc.PERSONOUID
                                AND (Sobstv.A_START_OWN_DATE IS NULL OR DATEDIFF(DAY, Sobstv.A_START_OWN_DATE, @startDate) >= 0)
                                AND (Sobstv.A_END_OWN_DATE IS NULL OR DATEDIFF(DAY, Sobstv.A_END_OWN_DATE, @startDate) <= 0)
		                WHERE pet.OUID =  @petitionId --Заявление.
                ) y ON 1 = 1
                WHERE rec.num = 1
        ) x 
            --LEFT JOIN (
	           -- SELECT  
	           --     MAX(serv.OUID) servId,
		          --  serv.A_PERSONOUID pcId
	           -- FROM ESRN_SERV_SERV serv
            --        INNER JOIN LINK_ACTDOC_PC docLink ON docLink.A_FROMID = @doc_regFlatPersonList
            --        INNER JOIN WM_PERSONAL_CARD docPc ON docLink.A_TOID = docPc.OUID
            --            AND (docPc.A_STATUS = @ACTIVESTATUS OR docPc.A_STATUS IS NULL)
            --            AND serv.A_PERSONOUID = docPc.OUID
            --        INNER JOIN SPR_NPD_MSP_CAT mcn ON mcn.A_ID = serv.A_SERV
            --        INNER JOIN (
		          --  SELECT A_CATEGORY FROM SPR_NPD_MSP_CAT WHERE A_ID = {params.npdMSPCatId}
            --        ) curMCN ON ISNULL(mcn.A_CATEGORY,0) != ISNULL(curMCN.A_CATEGORY,0) 
            --        INNER JOIN PPR_SERV msp ON msp.A_ID = mcn.A_MSP
            --            AND msp.A_COD IN ('СompensationHousing','compCostsUtilities38FZ','compCostsPaymentHousingReg','compCostsUtilities5FZ','compCostsUtilities181FZ','compCostsUtilities1244FZ','compCostsUtilities175FZ','compCostsUtilities2FZ','compCostsUtilitiesReg','compCostsPaymentHousing')
            --        INNER JOIN SPR_SERV_PERIOD period ON period.A_SERV=serv.OUID
            --            AND (period.A_STATUS = @ACTIVESTATUS OR period.A_STATUS IS NULL)
            --            AND (period.STARTDATE IS NULL OR {SQL.equalBeforeInMonth(period.STARTDATE, params.startDate)})
            --            AND (period.A_LASTDATE IS NULL OR {SQL.equalBeforeInMonth(params.startDate, period.A_LASTDATE)})
            --        WHERE (serv.A_STATUS = @ACTIVESTATUS OR serv.A_STATUS IS NULL)
            --        GROUP BY serv.A_PERSONOUID
            --) servs ON servs.pcId = x.recPcId
        WHERE (DATEDIFF(MONTH,recDate,@startDate) = 0 
            OR (advance = 1 AND DATEDIFF(MONTH,recAmMaxDate,@startDate) BETWEEN 1 AND 24 AND DATEDIFF(MONTH,recDate,recAmMaxDate) = 0))
        GROUP BY recPcId, recAmType
) x
--    LEFT JOIN SPR_LINK_MSP_PERSON sphereLink ON sphereLink.TOID = x.pcId AND sphereLink.FROMID = {params.servServId}
--WHERE ({params.servServId} IS NULL 
--    OR ((sphereLink.A_START_DATE IS NULL OR DATEDIFF(DAY, sphereLink.A_START_DATE, @startDate) >= 0)
--    AND (sphereLink.A_END_DATE IS NULL OR DATEDIFF(DAY, sphereLink.A_END_DATE, @startDate) <= 0))
--)
GROUP BY pcId