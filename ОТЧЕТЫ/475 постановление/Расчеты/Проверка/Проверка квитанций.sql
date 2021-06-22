--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


--{params.mspLkNpdId}
DECLARE @mspLkNpdId INT
SET @mspLkNpdId = 310

--{ACTIVESTATUS}
DECLARE @ACTIVESTATUS INT
SET @ACTIVESTATUS = 10


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

--{params.startDate}
DECLARE @startDate DATE
SET @startDate = CONVERT(DATE, '01-06-2021')


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


--//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
         
            
            SELECT 
                rec.A_RECEIPT_TYPE AS recType,      rec.A_PAYER AS recPcId,     rec.A_PAYMENT_DATE AS recDate, 
                rec.A_CREATEDATE AS recCreateDate,  rec.A_NUM_LIVING AS regCnt, rec.A_NUM_LGOTA AS lgotCnt,
                recAm.A_NAME_AMOUNT AS recAmType,   recAm.A_PAY AS payAmount,   recAmCalcType.A_CODE AS calcTypeCode,
                wa.A_AMOUNT_PERSON AS registered,   sht.A_NAME AS NameType,
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
                    AND ISNULL(recAm.A_STATUS, @ACTIVESTATUS) = @ACTIVESTATUS
            ----Виды услуг.
                INNER JOIN SPR_HSC_TYPES sht ON recAm.A_NAME_AMOUNT = sht.A_ID
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
                AND ISNULL(rec.A_STATUS, @ACTIVESTATUS)= @ACTIVESTATUS--Статус квитанции в БД "Действует".
                AND recAm.A_NAME_AMOUNT IN (70, 68, 69, 11, 20, 39, 42, 45, 81, 25, 38, 162, 388, 391, 392) --Виды услуг.
                AND (recAm.A_NAME_AMOUNT = 69 AND rec.A_PAYER = @personalCardId OR recAm.A_NAME_AMOUNT <> 69) --За телефон только у плательщика.