select  left(stuff(
(	SELECT '('+ amountStr + ')' +'/'+cast(COUNT(DISTINCT monthNum) as varchar(10))


from(
   SELECT 
    CASE 
     WHEN calcTypeCode = 'point' THEN CASE WHEN recPcId = {params.personalCardId} AND recPcId = {params.spherePcId}  THEN 1 ELSE 0 END
     ELSE 1
    END as partNumerator,
    CASE 
     WHEN calcTypeCode = 'point' THEN 1 
     WHEN calcTypeCode IN('area','livearea') THEN ISNULL(regCnt,{ALG.doc_regFlatPersonList_cnt})
     ELSE ISNULL(regCnt,{ALG.doc_regFlatPersonList_cnt}) 
    END as partDenominator,
    payAmount, calcAmount,regTypeCode,
----------------------------------------------------------------------------------------------
    CASE 
        --Старый расчет по долям.
        WHEN CONVERT(DATE, recDate) < CONVERT(DATE, '20200801') THEN
            CASE 
                WHEN recAmType IN (68,69,70) then '{'+left(NameType,1)+'}: '+replace(replace(convert(varchar(20), cast(round(payAmount,2)as money), 1), ',', ' '), '.00', '')+'*'+cast({PPRCONST.warCompPercent} as varchar(50))+'%='+ replace(replace(convert(varchar(20), cast(round(payAmount*60/100,2)as money), 1), ',', ' '), '.00', '')  
                WHEN recAmType IN (11,20,39,42,45,81,25, 388, 391, 392) then '{'+left(NameType,1)+'}: '+replace(replace(convert(varchar(20), cast(round(payAmount,2)as money), 1), ',', ' '), '.00', '')+'/'+cast(ISNULL(regCnt,registered) as varchar(50))+'*'+cast(ISNULL(lgotCnt,{ALG.doc_regFlatPersonListLgot_cnt}) as varchar(50))+'*'+cast({PPRCONST.warCompPercent} as varchar(50))+'%='+replace(replace(convert(varchar(20), cast(round((payAmount/cast(ISNULL(regCnt,registered) as float))*cast(ISNULL(lgotCnt,{ALG.doc_regFlatPersonListLgot_cnt}) as float) *{PPRCONST.warCompPercent}/100.00,2)as money), 1), ',', ' '), '.00', '')  
                WHEN recAmType IN (162) and y.SvedOLd = 'naim' then  '{'+left(NameType,1)+'}: '+replace(replace(convert(varchar(20), cast(round(payAmount,2)as money), 1), ',', ' '), '.00', '')+'/'+cast(ISNULL(regCnt,registered) as varchar(50))+'*'+cast(ISNULL(lgotCnt,{ALG.doc_regFlatPersonListLgot_cnt}) as varchar(50))+'*'+cast({PPRCONST.warCompPercent} as varchar(50))+'%='+ replace(replace(convert(varchar(20), cast(round((payAmount/cast(ISNULL(regCnt,registered) as float))*cast(ISNULL(lgotCnt,{ALG.doc_regFlatPersonListLgot_cnt}) as float) *{PPRCONST.warCompPercent}/100.00,2)as money), 1), ',', ' '), '.00', '')
                WHEN recAmType IN (162,38) and y.SvedOLd = 'sobst' then '{'+left(NameType,1)+'}: '+replace(replace(convert(varchar(20), cast(round(payAmount,2)as money), 1), ',', ' '), '.00', '')+'*'+cast(y.shareSobst as varchar(50))+'*'+cast({PPRCONST.warCompPercent} as varchar(50))+'%='+ replace(replace(convert(varchar(20), cast(round((payAmount*cast(y.shareSobst as float))*{PPRCONST.warCompPercent}/100,2) as money), 1), ',', ' '), '.00', '')
            END
        ELSE 
        --Новый расчет по количеству. 
            CASE 
                WHEN recAmType IN (68,69,70) then '{'+left(NameType,1)+'}: '+replace(replace(convert(varchar(20), cast(round(payAmount,2)as money), 1), ',', ' '), '.00', '')+'*'+cast({PPRCONST.warCompPercent} as varchar(50))+'%='+ replace(replace(convert(varchar(20), cast(round(payAmount*60/100,2)as money), 1), ',', ' '), '.00', '')  
                WHEN recAmType IN (11,20,39,42,45,81,25, 388, 391, 392, 162,38) then '{'+left(NameType,1)+'}: '+replace(replace(convert(varchar(20), cast(round(payAmount,2)as money), 1), ',', ' '), '.00', '')+'/'+cast(ISNULL(regCnt,registered) as varchar(50))+'*'+cast(ISNULL(lgotCnt,{ALG.doc_regFlatPersonListLgot_cnt}) as varchar(50))+'*'+cast({PPRCONST.warCompPercent} as varchar(50))+'%='+replace(replace(convert(varchar(20), cast(round((payAmount/cast(ISNULL(regCnt,registered) as float))*cast(ISNULL(lgotCnt,{ALG.doc_regFlatPersonListLgot_cnt}) as float) *{PPRCONST.warCompPercent}/100.00,2)as money), 1), ',', ' '), '.00', '')  
            END    
   END amountStr,
----------------------------------------------------------------------------------------------
    recPcId, recDate, recAmType, DATEDIFF(MONTH,recDate,{params.startDate}) as monthNum, 
-- CASE WHEN DATEDIFF(MONTH,recDate,recCreateDate) <= 6 and DATEDIFF(MONTH,recDate,recCreateDate) >0 AND recNum = 1 THEN 1 ELSE 0 END  advance,
    MAX(CASE WHEN DATEDIFF(MONTH,recDate,recCreateDate) <= 6 AND recNum = 1 THEN 1 ELSE 0 END) OVER(PARTITION BY recPcId, recType) advance,
    MAX(recDate) OVER(PARTITION BY recPcId, recType) as recAmMaxDate
   FROM (
    SELECT rec.A_OUID as recId, rec.A_RECEIPT_TYPE as recType, recType.A_CODE regTypeCode, rec.A_PAYER as recPcId, rec.A_PAYMENT_DATE as recDate, rec.A_CREATEDATE as recCreateDate, rec.A_NUM_LIVING as regCnt, 
     recAm.A_OUID as recAmId, recAm.A_NAME_AMOUNT as recAmType, recAm.A_PAY as payAmount, recAm.A_PAY as calcAmount,
     recAmTypeLink.A_HCV_AREA_OF_DISTRIB as hcsSphere, recAmCalcType.A_CODE as calcTypeCode,
     ROW_NUMBER() OVER(PARTITION BY rec.A_OUID, recAm.A_OUID ORDER BY recTypeLink.A_OUID) as num,
     wa.A_AMOUNT_PERSON registered, rec.A_NUM_LGOTA lgotCnt,sht.A_NAME NameType,
     DENSE_RANK() OVER(PARTITION BY rec.A_PAYER, rec.A_RECEIPT_TYPE ORDER BY YEAR(rec.A_PAYMENT_DATE) DESC, MONTH(rec.A_PAYMENT_DATE) DESC) as recNum,
     DENSE_RANK() OVER(PARTITION BY rec.A_PAYER, recAm.A_NAME_AMOUNT ORDER BY YEAR(rec.A_PAYMENT_DATE) DESC, MONTH(rec.A_PAYMENT_DATE) DESC) as recAmNum
    FROM WM_RECEIPT rec
    INNER JOIN SPR_RECEIPT_TYPE recType ON recType.A_OUID = rec.A_RECEIPT_TYPE
    INNER JOIN SPR_LINK_MSP_RTYPE recTypeLink ON recTypeLink.TOID = recType.A_OUID
     AND recTypeLink.FROMID = {params.mspLkNpdId}
    INNER JOIN WM_RECEIPT_AMOUNT recAm 
    join SPR_HSC_TYPES sht on recAm.A_NAME_AMOUNT=sht.A_ID
    ON recAm.A_RECEIPT = rec.A_OUID
     AND (recAm.A_STATUS = {ACTIVESTATUS} OR recAm.A_STATUS IS NULL)
    INNER JOIN SPR_LINK_NPD_MSP_CAT_HCS recAmTypeLink 
     LEFT JOIN SPR_CALC_HCSTYPE recAmCalcType ON recAmTypeLink.A_CALC_TYPE = recAmCalcType.A_OUID
    ON recAmTypeLink.TOID = recAm.A_NAME_AMOUNT AND recAmTypeLink.FROMID = {params.mspLkNpdId}
    LEFT JOIN LINK_ACTDOC_PC docLink 
         INNER JOIN WM_PERSONAL_CARD docPc ON docLink.A_TOID = docPc.OUID
                 AND (docPc.A_STATUS = {ACTIVESTATUS} OR docPc.A_STATUS IS NULL)
    ON docLink.A_FROMID = {ALG.doc_regFlatPersonList}
    left join WM_ACTDOCUMENTS wa on wa.OUID = {ALG.doc_regFlatPersonList} and wa.A_STATUS = {ACTIVESTATUS}
    WHERE rec.A_ADDR_ID = {ALG.doc_regFlatPersonList_addr} AND rec.A_FACT = 1
     AND rec.A_PAYER = ISNULL(docPc.OUID,{params.personalCardId})
     AND (rec.A_STATUS = {ACTIVESTATUS} OR rec.A_STATUS IS NULL)
     and recAm.A_NAME_AMOUNT in (70,68,69,11,20,39,42,45,81,25,38,162, 388, 391, 392)
     AND (recAm.A_NAME_AMOUNT = 69 AND rec.A_PAYER = {params.personalCardId} OR recAm.A_NAME_AMOUNT <> 69) --За телефон только у плательщика.
   ) rec 
    left join 
  (select	
		isnull(sum(
				case
					when ISNULL(Sobstv.A_PARTDENOMPART,0)<>0 
						then cast(Sobstv.A_PARTNUMPART AS float)/cast(Sobstv.A_PARTDENOMPART AS float)	
					else Sobstv.A_PART
				end),1)shareSobst,
		
				case 
					when exists (
					select 1				
					from	SPR_LINK_APPEAL_DOC linkDoc 			
							join WM_ACTDOCUMENTS docNaim 
							on docNaim.OUID = linkDoc.TOID and docNaim.DOCUMENTSTYPE in (2130,2131,2132)
					where FROMID = {params.petitionId}
					) 
						then 'naim'
					else 'sobst'
				end SvedOLd 
		from	WM_PETITION pet
				join SPR_LINK_APPEAL_DOC linkDoc 
					join WM_ACTDOCUMENTS doc on doc.OUID = linkDoc.TOID 
				on pet.OUID = linkDoc.FROMID
				left join(
				select  docSobst.OUID,
				wo.A_START_OWN_DATE,
				wo.A_END_OWN_DATE,
				linkDoc1.FROMID,
				wo.A_PARTDENOMPART,
				wo.A_PARTNUMPART,
				wo.A_PART,
				wo.A_OWNER_ID
				from	SPR_LINK_APPEAL_DOC linkDoc1 			
						join WM_ACTDOCUMENTS docSobst 
							left join WM_OWNING wo on docSobst.A_ESTATE = wo.A_OUID  
						on docSobst.OUID = linkDoc1.TOID and docSobst.DOCUMENTSTYPE in (3800,4196,4017)
				where docSobst.A_STATUS=10				
				)Sobstv on pet.OUID = Sobstv.FROMID and Sobstv.A_OWNER_ID = doc.PERSONOUID
		where	pet.OUID =  {params.petitionId}
				and doc.A_STATUS = {ACTIVESTATUS}
				and (doc.DOCUMENTSTYPE in {DOC.Military_st24_p4}
				or doc.DOCUMENTSTYPE in {DOC.Military_78FZ_st2}
				or doc.DOCUMENTSTYPE in {DOC.Military_fz247_st10}
				or doc.DOCUMENTSTYPE in {DOC.Military_fz283})
				and (Sobstv.A_START_OWN_DATE is null or datediff(day,Sobstv.A_START_OWN_DATE,{params.startDate})>=0)
				and (Sobstv.A_END_OWN_DATE is null or datediff(day,Sobstv.A_END_OWN_DATE,{params.startDate})<=0)
)y on 1 = 1
   WHERE rec.num = 1
  ) x 
  
/*  WHERE      (DATEDIFF(MONTH,recDate,{params.startDate}(SELECT  max(rec.A_PAYMENT_DATE) 
     FROM WM_RECEIPT rec
    INNER JOIN SPR_RECEIPT_TYPE recType ON recType.A_OUID = rec.A_RECEIPT_TYPE
    INNER JOIN SPR_LINK_MSP_RTYPE recTypeLink ON recTypeLink.TOID = recType.A_OUID
     AND recTypeLink.FROMID = {params.mspLkNpdId}
    INNER JOIN WM_RECEIPT_AMOUNT recAm ON recAm.A_RECEIPT = rec.A_OUID
     AND (recAm.A_STATUS = {ACTIVESTATUS} OR recAm.A_STATUS IS NULL)
    INNER JOIN SPR_LINK_NPD_MSP_CAT_HCS recAmTypeLink 
     LEFT JOIN SPR_CALC_HCSTYPE recAmCalcType ON recAmTypeLink.A_CALC_TYPE = recAmCalcType.A_OUID
    ON recAmTypeLink.TOID = recAm.A_NAME_AMOUNT AND recAmTypeLink.FROMID = {params.mspLkNpdId}
    LEFT JOIN LINK_ACTDOC_PC docLink 
         INNER JOIN WM_PERSONAL_CARD docPc ON docLink.A_TOID = docPc.OUID
                 AND (docPc.A_STATUS = {ACTIVESTATUS} OR docPc.A_STATUS IS NULL)
    ON docLink.A_FROMID = {ALG.doc_regFlatPersonList}
    left join WM_ACTDOCUMENTS wa on wa.OUID = {ALG.doc_regFlatPersonList} and wa.A_STATUS = {ACTIVESTATUS}
    WHERE rec.A_ADDR_ID = {ALG.doc_regFlatPersonList_addr} AND rec.A_FACT = 1
     AND rec.A_PAYER = ISNULL(docPc.OUID,{params.personalCardId})
     AND (rec.A_STATUS = {ACTIVESTATUS} OR rec.A_STATUS IS NULL)
     and recAm.A_NAME_AMOUNT in (70,68,69,11,20,39,42,45,81,25,38,162) 
     and rec.A_PAYMENT_DATE<={params.petitionReg})) = 0 
  --   OR (advance = 1 AND DATEDIFF(MONTH,recAmMaxDate,'20180901') BETWEEN 1 AND 6 AND DATEDIFF(MONTH,recDate,recAmMaxDate) = 0)
      )*/
      where (DATEDIFF(MONTH,recDate,{params.startDate}) = 0 
      OR (advance = 1 AND DATEDIFF(MONTH,recAmMaxDate,{params.startDate}) BETWEEN 1 AND 12 AND DATEDIFF(MONTH,recDate,recAmMaxDate) = 0))
  GROUP BY recPcId, amountStr
   for xml path('')),1,1,''),255)