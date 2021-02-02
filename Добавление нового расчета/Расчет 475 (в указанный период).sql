DECLARE @pet int
DECLARE @pcpet int
DECLARE @serv int
DECLARE @phones VARCHAR(100)
DECLARE @petType int
declare @d1 date
declare @d2 date
DECLARE @reg int
DECLARE @lg int
DECLARE @docs VARCHAR(100)
DECLARE @docstype VARCHAR(100)
DECLARE @part float
declare @dreg date
DECLARE @fls int
/*Льготополучатель*/
DECLARE @pcpetl int
/*Адрес получателей льготы*/
DECLARE @adrrl int
/*Дата начала действия основания*/
declare @dnosn date
declare @s1 date
declare @s2 date
DECLARE @minpet int
declare @minpetdate date

set @s1 = convert(date, dateadd("day", 1-DAY(#beginDate#), #beginDate#))
set @s2 = convert(date, dateadd("day", 1-DAY(#endDate#), #endDate#))

--set @s1 = CONVERT(date, '2018-12-01')
--set @s2 = CONVERT(date, '2018-12-31')
--set @s1 = CONVERT(date, '2018-09-01')
--set @s2 = CONVERT(date, '2019-02-28')


IF OBJECT_ID('tempdb..#tmpl') IS NOT NULL BEGIN DROP TABLE #tmpl END
IF OBJECT_ID('tempdb..#tmps') IS NOT NULL BEGIN DROP TABLE #tmps END
IF OBJECT_ID('tempdb..#tmpspr') IS NOT NULL BEGIN DROP TABLE #tmpspr END
IF OBJECT_ID('tempdb..#tmpr') IS NOT NULL BEGIN DROP TABLE #tmpr END
IF OBJECT_ID('tempdb..#tmppet') IS NOT NULL BEGIN DROP TABLE #tmppet END
IF OBJECT_ID('tempdb..#tmppet1') IS NOT NULL BEGIN DROP TABLE #tmppet1 END
IF OBJECT_ID('tempdb..#tmppet2') IS NOT NULL BEGIN DROP TABLE #tmppet2 END
IF OBJECT_ID('tempdb..#tmppetreg') IS NOT NULL BEGIN DROP TABLE #tmppetreg END
IF OBJECT_ID('tempdb..#tmppetlg') IS NOT NULL BEGIN DROP TABLE #tmppetlg END
IF OBJECT_ID('tempdb..#tmppetspr') IS NOT NULL BEGIN DROP TABLE #tmppetspr END
IF OBJECT_ID('tempdb..#tmppets') IS NOT NULL BEGIN DROP TABLE #tmppets END
IF OBJECT_ID('tempdb..#tmppetpart') IS NOT NULL BEGIN DROP TABLE #tmppetpart END
IF OBJECT_ID('tempdb..#tmppetdoc') IS NOT NULL BEGIN DROP TABLE #tmppetdoc END
IF OBJECT_ID('tempdb..#tmpf1') IS NOT NULL BEGIN DROP TABLE #tmpf1 END

set @pet = #objectID# /*4687027*/ /*4913434*/ /*4955905*/ /*528472*/ /*4980574*/ /*5036332*/ /*4967518*/ /*5102745*/ /*5039406*/ /*5177517*/ /*5155507*/ /*5411226*/
SET @phones = ''

/*Заявитель, тип заявления, дата регистрации заявления, получатель льготы*/
select @pcpet = app.A_PERSONCARD, @petType = pet.A_PETITION_TYPE, @dreg = CONVERT(date, app.A_DATE_REG), @pcpetl = pet.A_MSPHOLDER
from WM_PETITION pet
	join WM_APPEAL_NEW app on app.OUID = pet.OUID and app.A_STATUS = 10
where pet.OUID = @pet

/*Адрес регистрации заявителя*/
/*
select @adrr = A_REGFLAT
from WM_PERSONAL_CARD
where OUID = @pcpet
*/

/*Назначение*/
if @petType = 1
  begin
   select @serv = ess.OUID
   from ESRN_SERV_SERV ess
	    join WM_PETITION pet on ess.A_REQUEST = @pet
   where ess.A_STATUS = 10 and ess.A_SERV = 310
  end
 else
  begin
   select @serv = A_EXTEND_SERV_BASE
   from WM_PETITION
   where OUID = @pet
  end
  

-- Телефоны
SELECT @phones = @phones + ' ' + phone.A_NUMBER
FROM WM_PCPHONE phone 
WHERE phone.A_PERSCARD = @pcpet	AND phone.A_STATUS = 10

/*Зарегистрированные*/
select @reg = doc.A_AMOUNT_PERSON, @adrrl = doc.A_REGFLAT, @lg = doc.A_AMOUNT_LGOT
from SPR_LINK_APPEAL_DOC ld 
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.DOCUMENTSTYPE = 2091
	join 
	(select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE
	from SPR_LINK_APPEAL_DOC ld1 
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.DOCUMENTSTYPE = 2091
	where ld1.FROMID = @pet) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE
where ld.FROMID = @pet

/*Льготники*/
/*
select @lg = COUNT(*)
from SPR_LINK_APPEAL_DOC ld 
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.DOCUMENTSTYPE = 2091
	join 
	(select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE
	from SPR_LINK_APPEAL_DOC ld1 
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.DOCUMENTSTYPE = 2091
	where ld1.FROMID = @pet) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE
	join LINK_ACTDOC_PC ldpc on ldpc.A_FROMID = doc.OUID
where ld.FROMID = @pet
*/

if @reg is null set @reg = @lg

/*Документ о владении*/
select @docs = pprDoc.a_name, @docstype = pprDoc.A_CODE
from SPR_LINK_APPEAL_DOC ld 
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.PERSONOUID = @pcpetl
	join PPR_DOC pprDoc ON pprDoc.A_ID = doc.DOCUMENTSTYPE and pprDoc.A_PARENT = 2090 and pprDoc.A_STATUS = 10
	join 
	(select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE
	from SPR_LINK_APPEAL_DOC ld1 
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.PERSONOUID = @pcpetl
		join PPR_DOC pprDoc1 ON pprDoc1.A_ID = doc1.DOCUMENTSTYPE and pprDoc1.A_PARENT = 2090 and pprDoc1.A_STATUS = 10
	where ld1.FROMID = @pet) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE
where ld.FROMID = @pet

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
	where ld1.FROMID = @pet
	group by doc1.PERSONOUID) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE and doc.PERSONOUID = md.PERSONOUID
	left outer join SPR_GROUP_ROLE sgr on sgr.OUID = doc.A_RELATION
	join WM_PERSONAL_CARD pc on doc.PERSONOUID = pc.OUID and pc.A_STATUS = 10
	left outer join SPR_FIO_SURNAME AS SURNAME on SURNAME.OUID = pc.SURNAME
	left outer join SPR_FIO_NAME AS FIRSTNAME on FIRSTNAME.OUID = pc.A_NAME
	left outer join SPR_FIO_SECONDNAME AS SECONDNAME on SECONDNAME.OUID = pc.A_SECONDNAME
where ld.FROMID = @pet

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
		and (own1.A_START_OWN_DATE is null or CONVERT(date, own1.A_START_OWN_DATE) <= @dreg)
		and (own1.A_END_OWN_DATE is null or CONVERT(date, own1.A_END_OWN_DATE) >= @dreg)
	 group by own1.A_OWNER_ID) mo on mo.A_OWNER_ID = own.A_OWNER_ID and mo.A_OUID = own.A_OUID
where own.A_ADDR_ID = @adrrl and own.A_STATUS = 10
	and (own.A_START_OWN_DATE is null or CONVERT(date, own.A_START_OWN_DATE) <= @dreg)
	and (own.A_END_OWN_DATE is null or CONVERT(date, own.A_END_OWN_DATE) >= @dreg)

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

select @dnosn = min(A_DOCBASESTARTDATE) from #tmpspr where PERSONOUID = @pcpetl


/*Оформлена с по*/
if @petType = 1     /*Заявление на назначение*/
  begin
   set @d1 = dateadd("day", 1-DAY(@dreg), @dreg)
  end
 else
  begin
   select @d1 = dateadd(day, 1, convert(date, ssp.A_LASTDATE))
   from SPR_SERV_PERIOD ssp
	   join
	    (select MAX(STARTDATE) as sd
		from SPR_SERV_PERIOD
		where A_SERV = @serv and A_STATUS = 10) md on md.sd = ssp.STARTDATE
   where ssp.A_SERV = @serv and ssp.A_STATUS = 10  
  end
set @d2 = DATEADD(DAY, -1, DATEADD(MONTH, 6, @d1))

  
select convert(char, app.A_DATE_REG, 104) as petitionDate,
	rtrim(ISNULL(SURNAME.A_NAME, '') + ' ' + ISNULL(FIRSTNAME.A_NAME,'') + ' ' + ISNULL(SECONDNAME.A_NAME, '')) as FIO,
	@phones as phone, adr.A_ADRTITLE as address,
	convert(char, @d1, 104) as dateFrom, case when @d2 is not null then convert(char, @d2, 104) else '' end as dateTo,
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
where pet.OUID = @pet

select spr.relativeFIO, spr.ser, spr.num, spr.relation, spr.date,
	case
	 when s.A_PART is null then ''
	 when s.A_PART = 1 then '1' 
	 else CONVERT(varchar(15), s.A_PART) 
	end as part
from #tmpspr spr
	left outer join #tmps s on s.A_OWNER_ID = spr.PERSONOUID
order by 1

/*----------------------------------------------------------*/
/*Все заявления*/

/*Заявления на назначения*/
select pet.OUID, convert(date, app.A_DATE_REG) as A_DATE_REG, convert(date, dateadd("day", 1-DAY(app.A_DATE_REG), app.A_DATE_REG)) as d
into #tmpf1
from WM_PETITION pet
	join WM_APPEAL_NEW app on app.OUID = pet.OUID and app.A_STATUS = 10
	join ESRN_SERV_SERV ess on ess.A_REQUEST = pet.OUID and ess.A_STATUS = 10 and ess.A_SERV = 310
where pet.A_STATUSPRIVELEGE = 13 and pet.A_PETITION_TYPE = 1 and pet.A_MSPHOLDER = @pcpetl

/*Самое первое заявление (о назначении)*/
select @minpet = t.OUID
from #tmpf1 t
	join 
	(select MIN(A_DATE_REG) as A_DATE_REG
	from #tmpf1) a on a.A_DATE_REG = t.A_DATE_REG

/*Дата начала действия основания в "Справке о праве..." в самом первом заявлении*/
select @minpetdate = CONVERT(date, doc.A_DOCBASESTARTDATE)
from SPR_LINK_APPEAL_DOC ld
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.DOCUMENTSTYPE in (1796, 2067, 3893, 3894) and doc.PERSONOUID = @pcpetl
	join
	 (select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE
	 from SPR_LINK_APPEAL_DOC ld1
		  join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.DOCUMENTSTYPE in (1796, 2067, 3893, 3894) and doc1.PERSONOUID = @pcpetl
	 where ld1.FROMID = @minpet) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE
where ld.FROMID = @minpet

select *
into #tmppet
from
(
select pet.OUID, convert(date, app.A_DATE_REG) as A_DATE_REG, convert(date, dateadd("day", 1-DAY(app.A_DATE_REG), app.A_DATE_REG)) as d
from WM_PETITION pet
	join WM_APPEAL_NEW app on app.OUID = pet.OUID and app.A_STATUS = 10
	join ESRN_SERV_SERV ess on ess.OUID = pet.A_EXTEND_SERV_BASE and ess.A_STATUS = 10 and ess.A_SERV = 310
where pet.A_EXTEND_SERV_BASE is not null and pet.A_STATUSPRIVELEGE = 13 and pet.A_PETITION_TYPE = 2 and pet.A_MSPHOLDER = @pcpetl
union all
select OUID,
	   case
	    when OUID = @minpet and @minpetdate is not null then @minpetdate
	    else A_DATE_REG
	   end as A_DATE_REG,
	   case
	    when OUID = @minpet and @minpetdate is not null then convert(date, dateadd("day", 1-DAY(@minpetdate), @minpetdate))
	    else d
	   end as d
from #tmpf1
) a

select p1.ouid, p1.a_date_reg, p1.d,
	DATEADD(MONTH, -1,
	isnull(
	(select min(p2.d)
	from #tmppet p2
	where p2.d > p1.d),
	CONVERT(date, '29000101'))
	) as d2
into #tmppet1
from #tmppet p1


/*Зарегистрированные*/
select doc.A_AMOUNT_PERSON as reg, pet.OUID, doc.A_AMOUNT_LGOT as lg
into #tmppetreg
from SPR_LINK_APPEAL_DOC ld 
	join #tmppet1 pet on ld.FROMID = pet.OUID
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.DOCUMENTSTYPE = 2091
	join 
	(select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE, pet1.OUID
	from SPR_LINK_APPEAL_DOC ld1 
		join #tmppet1 pet1 on ld1.FROMID = pet1.OUID
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.DOCUMENTSTYPE = 2091
	group by pet1.OUID) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE and md.OUID = pet.OUID

/*Льготники*/
/*
select pet.OUID, COUNT(*) as lg
into #tmppetlg
from SPR_LINK_APPEAL_DOC ld 
	join #tmppet1 pet on ld.FROMID = pet.OUID
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.DOCUMENTSTYPE = 2091
	join 
	(select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE, pet1.OUID
	from SPR_LINK_APPEAL_DOC ld1 
		join #tmppet1 pet1 on ld1.FROMID = pet1.OUID
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.DOCUMENTSTYPE = 2091
	group by pet1.OUID) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE and md.OUID = pet.OUID
	join LINK_ACTDOC_PC ldpc on ldpc.A_FROMID = doc.OUID
	group by pet.OUID
*/

/*Справки о праве*/
select pet.OUID, doc.PERSONOUID, pet.d, pet.A_DATE_REG
into #tmppetspr
from SPR_LINK_APPEAL_DOC ld 
	join #tmppet1 pet on ld.FROMID = pet.OUID
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.DOCUMENTSTYPE in (1796, 2067, 3893, 3894)
	join 
	(select doc1.PERSONOUID, MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE, pet1.OUID
	from SPR_LINK_APPEAL_DOC ld1 
		join #tmppet1 pet1 on ld1.FROMID = pet1.OUID
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.DOCUMENTSTYPE in (1796, 2067, 3893, 3894)
	group by pet1.OUID, doc1.PERSONOUID) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE and doc.PERSONOUID = md.PERSONOUID and md.OUID = pet.OUID

/*Доли собственности*/
select own.A_OUID, own.A_OWNER_ID, own.A_PART, l.OUID
into #tmppets
from WM_OWNING own
	join #tmppetspr l on l.PERSONOUID = own.A_OWNER_ID and convert(date, own.A_START_OWN_DATE) <= l.d
	join
	(select own1.A_OWNER_ID, MAX(own1.A_START_OWN_DATE) as A_START_OWN_DATE, l1.OUID
	 from WM_OWNING own1
		join #tmppetspr l1 on l1.PERSONOUID = own1.A_OWNER_ID and convert(date, own1.A_START_OWN_DATE) <= l1.d
	 where own1.A_ADDR_ID = @adrrl and own1.A_STATUS = 10
		and (own1.A_START_OWN_DATE is null or CONVERT(date, own1.A_START_OWN_DATE) <= l1.A_DATE_REG)
		and (own1.A_END_OWN_DATE is null or CONVERT(date, own1.A_END_OWN_DATE) >= l1.A_DATE_REG)
	 group by own1.A_OWNER_ID, l1.OUID) mo on mo.A_OWNER_ID = own.A_OWNER_ID and mo.A_START_OWN_DATE = own.A_START_OWN_DATE and l.OUID = mo.OUID
where own.A_ADDR_ID = @adrrl and own.A_STATUS = 10
	and (own.A_START_OWN_DATE is null or CONVERT(date, own.A_START_OWN_DATE) <= l.A_DATE_REG)
	and (own.A_END_OWN_DATE is null or CONVERT(date, own.A_END_OWN_DATE) >= l.A_DATE_REG)

select ouid, SUM(A_PART) as part
into #tmppetpart
from #tmppets
group by OUID


/*Документ о владении*/
select pprDoc.a_name as docs, pprDoc.A_CODE as docstype, pet.OUID
into #tmppetdoc
from SPR_LINK_APPEAL_DOC ld 
	join #tmppet1 pet on ld.FROMID = pet.OUID
	join WM_ACTDOCUMENTS doc on ld.TOID = doc.OUID and doc.A_STATUS = 10 and doc.PERSONOUID = @pcpetl
	join PPR_DOC pprDoc ON pprDoc.A_ID = doc.DOCUMENTSTYPE and pprDoc.A_PARENT = 2090 and pprDoc.A_STATUS = 10
	join 
	(select MAX(doc1.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE, pet1.OUID
	from SPR_LINK_APPEAL_DOC ld1 
		join #tmppet1 pet1 on ld1.FROMID = pet1.OUID
		join WM_ACTDOCUMENTS doc1 on ld1.TOID = doc1.OUID and doc1.A_STATUS = 10 and doc1.PERSONOUID = @pcpetl
		join PPR_DOC pprDoc1 ON pprDoc1.A_ID = doc1.DOCUMENTSTYPE and pprDoc1.A_PARENT = 2090 and pprDoc1.A_STATUS = 10
	group by pet1.OUID) md on md.ISSUEEXTENSIONSDATE = doc.ISSUEEXTENSIONSDATE and md.OUID = pet.ouid


/*Данные для расчета*/
select p.OUID, p.A_DATE_REG, p.d, p.d2, isnull(r.reg, r.lg) as reg, r.lg,
	case when doc.docs is not null and doc.docstype in ('naim', 'specNaim', 'contractSocialHire') then 0 else 1 end as fls,
	case
	 when doc.docs is not null and doc.docstype in ('naim', 'specNaim', 'contractSocialHire') then 1
	 when isnull(part.part, 0) = 0 then 1
	 else part.part 
	end as part
into #tmppet2
from #tmppet1 p
	left outer join #tmppetreg r on r.OUID = p.OUID
--	left outer join #tmppetlg l on l.OUID = p.OUID
	left outer join #tmppetpart part on part.OUID = p.OUID
	left outer join #tmppetdoc doc on doc.OUID = p.OUID

/*----------------------------------------------------------*/


select reca.A_PAY as ServicePay, reca.A_NAME_AMOUNT,
	 case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else pet.reg end as qz,
	 case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else pet.lg end as ql,
	case
	 when pet.part = 1 then '1' 
	 else CONVERT(varchar(15), pet.part) 
	end as part,
	s.A_NAME as serviceName,
	cast(
	case
	 when A_NAME_AMOUNT in (68, 69, 70) then reca.A_PAY * 0.6
	 when A_NAME_AMOUNT in (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) then reca.A_PAY/(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else pet.reg end)*(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else pet.lg end) * 0.6
	 when A_NAME_AMOUNT in (162, 38) and pet.fls = 0 then reca.A_PAY/(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else pet.reg end)*(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else pet.lg end) * 0.6
	 when A_NAME_AMOUNT in (162, 38) and pet.fls = 1 then reca.A_PAY * pet.part * 0.6
	 else 0
	end as decimal(10, 4)) as result, convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) as PAYMENT_DATE, pet.fls
into #tmpr	
from WM_RECEIPT rec
	join #tmppet2 pet on convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) between pet.d and pet.d2
	join WM_RECEIPT_AMOUNT reca on reca.A_RECEIPT = rec.A_OUID and reca.A_STATUS = 10 and A_NAME_AMOUNT in (68, 69, 70, 11, 20, 39, 42, 45, 81, 25, 162, 38, 388, 391, 392)
	left outer join SPR_HSC_TYPES s on s.A_STATUS = 10 and s.A_ID = A_NAME_AMOUNT
where rec.A_STATUS = 10 and rec.A_PAYER = @pcpetl and rec.A_ADDR_ID = @adrrl and convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) < convert(date, dateadd("day", 1-DAY(@dreg), @dreg))
	and (pet.fls = 0 and A_NAME_AMOUNT <> 38 or pet.fls = 1)
	and convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) between @s1 and @s2


select ServicePay, A_NAME_AMOUNT,
	 case
	  when A_NAME_AMOUNT in (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) then CONVERT(varchar(15), qz)
	  when A_NAME_AMOUNT = 162 and fls = 0 then CONVERT(varchar(15), qz)
	  else '-'
	 end as qz,
	 case
	  when A_NAME_AMOUNT in (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) then CONVERT(varchar(15), ql)
	  when A_NAME_AMOUNT = 162 and fls = 0 then CONVERT(varchar(15), ql)
	  else '-'
	 end as ql,
	 case when A_NAME_AMOUNT in (162, 38) and fls = 1 then part else '-' end as part,
	 serviceName, round(result, 2) as result, PAYMENT_DATE, convert(char, PAYMENT_DATE, 104) as pd
from #tmpr
order by PAYMENT_DATE, serviceName