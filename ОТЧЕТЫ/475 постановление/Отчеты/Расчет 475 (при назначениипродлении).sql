





DECLARE @reg int
DECLARE @lg int
DECLARE @docs VARCHAR(100)
DECLARE @docstype VARCHAR(100)
DECLARE @part float

DECLARE @fls int

/*Адрес получателей льготы*/
DECLARE @adrrl int
/*Дата начала действия основания*/
declare @dnosn date


IF OBJECT_ID('tempdb..#tmpl') IS NOT NULL BEGIN DROP TABLE #tmpl END
IF OBJECT_ID('tempdb..#tmps') IS NOT NULL BEGIN DROP TABLE #tmps END
IF OBJECT_ID('tempdb..#tmpspr') IS NOT NULL BEGIN DROP TABLE #tmpspr END
IF OBJECT_ID('tempdb..#tmpr') IS NOT NULL BEGIN DROP TABLE #tmpr END



--Идентификатор заявления отчета.
DECLARE @petitionID INT
--SET @petitionID = #objectID# 
SET @petitionID = 6514261 
--6514261   Мать
--6514276   Дочь
--6514294   Сын






--Информация из заявления.
DECLARE @HolderPetition     INT     --Заявитель.
DECLARE @petitionType       INT     --Тип заявления (На назначение или возобновление).
declare @petitionDateReg    DATE    --Дата регистрации заявления.
DECLARE @HolderMSP          INT     --Льготодержатель.
DECLARE @dateFrom                 DATE
DECLARE @dateTo                 DATE
SELECT 
    @HolderPetition     = appeal.A_PERSONCARD,              
    @petitionType       = petition.A_PETITION_TYPE,         
    @petitionDateReg    = CONVERT(date, appeal.A_DATE_REG),  
    @HolderMSP          = petition.A_MSPHOLDER               
FROM WM_PETITION petition --Заявления.
----Обращение гражданина.
    INNER JOIN WM_APPEAL_NEW appeal 
        ON appeal.OUID = petition.OUID 
            AND appeal.A_STATUS = 10 --Статус в БД "Действует".
WHERE petition.OUID = @petitionID --Заявление отчета.



--Если заявление на назначение.
IF @petitionType = 1 BEGIN
    SET @dateFrom = DATEADD(DAY, 1 - DAY(@petitionDateReg), @petitionDateReg)      
    SET @dateTo = DATEADD(DAY, -1, DATEADD(MONTH, 6, @dateFrom))                             
END
--Если на продление.
ELSE BEGIN
    --Дата окончания продляемого назначения в качестве даты начала.
    SELECT 
        @dateFrom = DATEADD(DAY, 1, CONVERT(DATE, t.SERV_END_DATE))
    FROM (
        SELECT
            period.A_LASTDATE AS SERV_END_DATE,
            ROW_NUMBER() OVER (PARTITION BY petition.OUID ORDER BY period.STARTDATE DESC) AS gnum 
        FROM WM_PETITION petition --Заявления.
        ----Период предоставления МСП.
            INNER JOIN SPR_SERV_PERIOD period
                ON period.A_SERV = petition.A_EXTEND_SERV_BASE --Назначение, которое продлевается.
                    AND period.A_STATUS = 10 --Статус в БД "Действует".
        WHERE petition.OUID = @petitionID
    ) t
    WHERE t.gnum = 1
    SET @dateTo = DATEADD(DAY, -1, DATEADD(MONTH, 6, @dateFrom)) 
END
  
  
--Телефоны.
DECLARE @phones VARCHAR(100)
SET @phones = ''
SELECT @phones = @phones + ' ' + phone.A_NUMBER
FROM WM_PCPHONE phone 
WHERE phone.A_PERSCARD = @HolderPetition	
    AND phone.A_STATUS = 10 --Статус в БД "Действует".
  
  
SELECT @dateFrom, @dateTo, @petitionType
  
  
/*


/*Зарегистрированные*/
select @reg = doc.A_AMOUNT_PERSON, @adrrl = doc.A_REGFLAT, @lg = doc.A_AMOUNT_LGOT
from SPR_LINK_APPEAL_DOC ld 
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.DOCUMENTSTYPE = 2091
	join 
	(select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE
	from SPR_LINK_APPEAL_DOC ld1 
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.DOCUMENTSTYPE = 2091
	where ld1.FROMID = @petitionID) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE
where ld.FROMID = @petitionID



if @reg is null set @reg = @lg

/*Документ о владении*/
select @docs = pprDoc.a_name, @docstype = pprDoc.A_CODE
from SPR_LINK_APPEAL_DOC ld 
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.PERSONOUID = @HolderMSP
	join PPR_DOC pprDoc ON pprDoc.A_ID = doc.DOCUMENTSTYPE and pprDoc.A_PARENT = 2090 and pprDoc.A_STATUS = 10
	join 
	(select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE
	from SPR_LINK_APPEAL_DOC ld1 
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.PERSONOUID = @HolderMSP
		join PPR_DOC pprDoc1 ON pprDoc1.A_ID = doc1.DOCUMENTSTYPE and pprDoc1.A_PARENT = 2090 and pprDoc1.A_STATUS = 10
	where ld1.FROMID = @petitionID) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE
where ld.FROMID = @petitionID

/*Справки о праве*/
select rtrim(ISNULL(SURNAME.A_NAME, '') + ' ' + ISNULL(FIRSTNAME.A_NAME,'') + ' ' + ISNULL(SECONDNAME.A_NAME, '')) as relativeFIO,
	   isnull(doc.DOCUMENTSERIES, '') as ser, isnull(doc.DOCUMENTSNUMBER, '') as num, isnull(sgr.A_NAME, '') as relation,
	   case when doc.A_DOCBASESTARTDATE is not null then convert(char, doc.A_DOCBASESTARTDATE, 104) else '' end as date,
	   doc.PERSONOUID, doc.A_DOCBASESTARTDATE
into #tmpspr	   
from SPR_LINK_APPEAL_DOC ld 
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.DOCUMENTSTYPE in (1796, 2067, 3893, 3894)
	join 
	(select doc1.PERSONOUID, MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE
	from SPR_LINK_APPEAL_DOC ld1 
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.DOCUMENTSTYPE in (1796, 2067, 3893, 3894)
	where ld1.FROMID = @petitionID
	group by doc1.PERSONOUID) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE and doc.PERSONOUID = md.PERSONOUID
	left outer join SPR_GROUP_ROLE sgr on sgr.OUID = doc.A_RELATION
	join WM_PERSONAL_CARD pc on doc.PERSONOUID = pc.OUID and pc.A_STATUS = 10
	left outer join SPR_FIO_SURNAME AS SURNAME on SURNAME.OUID = pc.SURNAME
	left outer join SPR_FIO_NAME AS FIRSTNAME on FIRSTNAME.OUID = pc.A_NAME
	left outer join SPR_FIO_SECONDNAME AS SECONDNAME on SECONDNAME.OUID = pc.A_SECONDNAME
where ld.FROMID = @petitionID

/*Доли собственности*/
select own.A_OUID, own.A_OWNER_ID, own.A_PART
into #tmps
from WM_OWNING own
	join #tmpspr l on l.PERSONOUID = own.A_OWNER_ID
	join
	(select own1.A_OWNER_ID, MAX(own1.A_OUID) as A_OUID
	 from WM_OWNING own1
		join #tmpspr l1 on l1.PERSONOUID = own1.A_OWNER_ID
	 where own1.A_ADDR_ID = @adrrl and own1.A_STATUS = 10
		and (own1.A_START_OWN_DATE is null or CONVERT(date, own1.A_START_OWN_DATE) <= @petitionDateReg)
		and (own1.A_END_OWN_DATE is null or CONVERT(date, own1.A_END_OWN_DATE) >= @petitionDateReg)
	 group by own1.A_OWNER_ID) mo on mo.A_OWNER_ID = own.A_OWNER_ID and mo.A_OUID = own.A_OUID
where own.A_ADDR_ID = @adrrl and own.A_STATUS = 10
	and (own.A_START_OWN_DATE is null or CONVERT(date, own.A_START_OWN_DATE) <= @petitionDateReg)
	and (own.A_END_OWN_DATE is null or CONVERT(date, own.A_END_OWN_DATE) >= @petitionDateReg)

select @part = SUM(A_PART)
from #tmps

/*@fls = 0 - наниматель, @fls = 1 - собственник*/
if (@docs is not null and @docstype in ('naim', 'specNaim', 'contractSocialHire'))
  begin
   set @fls = 0
   set @part = 1
  end
 else
  begin
   set @fls = 1
   if isnull(@part, 0) = 0 set @part = 1
  end

select @dnosn = min(A_DOCBASESTARTDATE) from #tmpspr where PERSONOUID = @HolderMSP





----------------------------------------------------------------------------------------


--Вывод общей информации для отчета.
select convert(char, app.A_DATE_REG, 104) as petitionDate,
	rtrim(ISNULL(SURNAME.A_NAME, '') + ' ' + ISNULL(FIRSTNAME.A_NAME,'') + ' ' + ISNULL(SECONDNAME.A_NAME, '')) as FIO,
	@phones as phone, adr.A_ADRTITLE as address,
	convert(char, @dateFrom, 104) as dateFrom, case when @dateTo is not null then convert(char, @dateTo, 104) else '' end as dateTo,
	@reg as qz, @lg as ql,
	isnull(@docs, '') as doc,
	case
	 when @part = 1 then '1' 
	 else CONVERT(varchar(15), @part) 
	end as qpart
from WM_PETITION pet
	join WM_APPEAL_NEW app on app.OUID = pet.OUID and app.A_STATUS = 10
	join WM_PERSONAL_CARD pc on pc.OUID = app.A_PERSONCARD
	left outer join SPR_FIO_SURNAME AS SURNAME on SURNAME.OUID = pc.SURNAME
	left outer join SPR_FIO_NAME AS FIRSTNAME on FIRSTNAME.OUID = pc.A_NAME
	left outer join SPR_FIO_SECONDNAME AS SECONDNAME on SECONDNAME.OUID = pc.A_SECONDNAME
	left outer join WM_ADDRESS adr on adr.OUID = pc.A_REGFLAT and adr.A_STATUS = 10
where pet.OUID = @petitionID
  
--Вывод справки о праве.
select spr.relativeFIO, spr.ser, spr.num, spr.relation, spr.date,
	case
	 when s.A_PART is null then ''
	 when s.A_PART = 1 then '1' 
	 else CONVERT(varchar(15), s.A_PART) 
	end as part
from #tmpspr spr
	left outer join #tmps s on s.A_OWNER_ID = spr.PERSONOUID
order by 1


----------------------------------------------------------------------------------------

--Расчет.
select reca.A_PAY as ServicePay, reca.A_NAME_AMOUNT,
	 case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else @reg end as qz,
	 case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else @lg end as ql,
	case
	 when @part = 1 then '1' 
	 else CONVERT(varchar(15), @part) 
	end as part,
	s.A_NAME as serviceName,
  ------------------------------------------------------------------------------
    CASE 
        --Старый расчет по долям.
        WHEN CONVERT(DATE, rec.A_PAYMENT_DATE) < CONVERT(DATE, '20200801') THEN CAST (
            CASE
                WHEN A_NAME_AMOUNT IN (68, 69, 70) THEN reca.A_PAY * 0.6
                WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) THEN reca.A_PAY/(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else @reg end)*(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else @lg end) * 0.6
                WHEN A_NAME_AMOUNT IN (162, 38) AND @fls = 0 THEN reca.A_PAY/(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else @reg end)*(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else @lg end) * 0.6
                WHEN A_NAME_AMOUNT IN (162, 38) AND @fls = 1 THEN reca.A_PAY * @part * 0.6
                ELSE 0
            END AS DECIMAL(10, 4)
        ) 
        --Новый расчет по количеству. 
        ELSE CAST (
	        CASE
                WHEN A_NAME_AMOUNT IN (68, 69, 70) THEN reca.A_PAY * 0.6
                WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392, 162, 38) THEN reca.A_PAY/(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else @reg end)*(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else @lg end) * 0.6
                else 0
            END AS DECIMAL(10, 4))
    END AS result,
  ------------------------------------------------------------------------------
	CASE
	    WHEN CONVERT(DATE, rec.A_PAYMENT_DATE) < CONVERT(DATE, '20200801') THEN 1
	    ELSE 0
	END AS OLD_CALCULATION
into #tmpr	
from WM_RECEIPT rec
	join
	(select MAX(convert(date, dateadd("day", 1-DAY(rec1.A_PAYMENT_DATE), rec1.A_PAYMENT_DATE))) as d
	from WM_RECEIPT rec1
	where rec1.A_STATUS = 10 and rec1.A_PAYER = @HolderMSP and rec1.A_ADDR_ID = @adrrl and convert(date, dateadd("day", 1-DAY(rec1.A_PAYMENT_DATE), rec1.A_PAYMENT_DATE)) < convert(date, dateadd("day", 1-DAY(@petitionDateReg), @petitionDateReg))) md
	 on convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) = md.d
	join WM_RECEIPT_AMOUNT reca on reca.A_RECEIPT = rec.A_OUID and reca.A_STATUS = 10 and A_NAME_AMOUNT in (68, 69, 70, 11, 20, 39, 42, 45, 81, 25, 162, 38, 388, 391, 392)
	left outer join SPR_HSC_TYPES s on s.A_STATUS = 10 and s.A_ID = A_NAME_AMOUNT
where rec.A_STATUS = 10 and rec.A_PAYER = @HolderMSP and rec.A_ADDR_ID = @adrrl and convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) < convert(date, dateadd("day", 1-DAY(@petitionDateReg), @petitionDateReg))
	and (@fls = 0 and A_NAME_AMOUNT <> 38 or @fls = 1)
order by s.A_NAME


----------------------------------------------------------------------------------------


--Вывод расчета компенсаций для отчета.
SELECT 
    serviceName         AS serviceName, 
    ServicePay          AS ServicePay, 
  ------------------------------------------------------------------------------
    --Зарегестрировано.
    CASE OLD_CALCULATION
        --Старый расчет по долям.
        WHEN 1 THEN 
            CASE
                WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) THEN CONVERT(VARCHAR(15), qz)
                WHEN A_NAME_AMOUNT = 162 AND @fls = 0 THEN CONVERT(VARCHAR(15), qz) --Содержание и ремонт жилого помещения.
                ELSE '-'
            END 
        --Новый расчет по количеству. 
        ELSE       
            CASE
                WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392, 162, 38) THEN CONVERT(VARCHAR(15), qz)
                ELSE '-'
	        END  
    END AS qz,
  ------------------------------------------------------------------------------
    --Льготники.
    CASE OLD_CALCULATION
        --Старый расчет по долям.
        WHEN 1 THEN 
            CASE
                WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) THEN CONVERT(VARCHAR(15), ql)
                WHEN A_NAME_AMOUNT = 162 AND @fls = 0 THEN CONVERT(VARCHAR(15), ql) --Содержание и ремонт жилого помещения.
                ELSE '-'
            END
        --Новый расчет по количеству. 
        ELSE 
            CASE
                WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392, 162, 38) THEN CONVERT(VARCHAR(15), ql)
                ELSE '-'
            END
    END AS ql,
  ------------------------------------------------------------------------------
    --Доля.
    CASE OLD_CALCULATION
        --Старый расчет по долям.
        WHEN 1 THEN 
            CASE 
                WHEN A_NAME_AMOUNT IN (162, 38) AND @fls = 1 THEN part  --Содержание и ремонт жилого помещения или Капитальный ремонт.
                ELSE '-' 
            END
        --Новый расчет по количеству.
        ELSE '-'
    END AS part,
  ------------------------------------------------------------------------------
    ROUND(result, 2) AS result
FROM #tmpr
*/