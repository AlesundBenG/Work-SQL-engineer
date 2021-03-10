declare @newProgId int
declare @form varchar(20)
declare @tmp2 int 
declare @vozr int
declare @pc int
declare @st int
--declare @pet int
declare @sex int

declare @A_EATINH_BARTHEL int
declare @A_BATHING_BARTHEL int
declare @A_WASHING_BARTHEL int
declare @A_CONTROLLING_DEFECATION_BARTHEL int
declare @A_URINATION_BARTHEL int
declare @A_USE_TOILET_BARTHEL int
declare @A_MOVEMENT_BARTHEL int
declare @A_BED_TO_CHAIR_BARTHEL int
declare @A_MOVING_DISTANCEA_LAWTON int
declare @A_COOKING_FOOD_LAWTON int
declare @A_HOUSEKEEPING_LAWTON int
declare @A_USE_MEDICATION_LAWTON int

declare @count_ad int
declare @fl_ad int
declare @fl_ssr int
declare @rodn int
declare @so int
declare @degree int
declare @pre int
declare @TOTAL_POINTS decimal(18,2)

declare @A_MOVE_OUTSIDE_HOME varchar(10)
declare @A_APARTMENT_CLEANING varchar(10)
declare @A_COOKING varchar(10)
declare @A_RECEPTION_EAT_MED varchar(10)
declare @A_DRESSING varchar(10)
declare @A_HYGIENE varchar(10)
declare @A_URINATION_DEFECATION varchar(10)
declare @A_MOVING_HOUSE varchar(10)

declare @cause12 int

declare @V_A_INVALID_GROUP int
declare @V_A_STARTDATA date
declare @V_A_ENDDATA date
declare @V_A_INV_REAS int

set @newProgId = #objectId#
--set @newProgId = 29042


select @st = isnull(ipr.A_STATUSPRIVELEGE, 0)
from INDIVID_PROGRAM ipr
where ipr.A_OUID = @newProgId

if (@st <> 13)
begin

select @pc = ipr.PERSONOUID, @sex = pc.A_SEX,
@vozr = datediff(year, pc.BIRTHDATE, GETDATE()) -
        case
            when month(pc.BIRTHDATE) < month(GETDATE()) then 0
            when month(pc.BIRTHDATE) > month(GETDATE()) then 1
            when day(pc.BIRTHDATE) > day(GETDATE()) then 1
            else 0
        end,
        @form = spr.A_CODE,
        @so = ipr.A_FORM_SOCSERV,
        @degree = isnull(ipr.A_DEGREE, 9999),
        @pre = case when ipr.A_PRE is not null then 1 else 0 end,
        @TOTAL_POINTS = isnull(ipr.A_TOTAL_POINTS, 9999)
	from INDIVID_PROGRAM ipr
		 join WM_PERSONAL_CARD pc on pc.OUID = ipr.PERSONOUID
		 left outer join SPR_FORM_SOCSERV spr on ipr.A_FORM_SOCSERV = spr.A_OUID
	where ipr.A_OUID = @newProgId

/*======================================================================*/
	--set @tmp2 = null
	----- инвалидность на дату перерсмотра 
	--select @tmp2 = igr.A_CODE
	--FROM WM_ACTDOCUMENTS mse
	--join WM_HEALTHPICTURE hp
	--	on mse.OUID = hp.A_REFERENCE 						
	--	and hp.A_STATUS=10
	--	and mse.A_status=10
	--	and mse.PERSONOUID = @pc
	--	and hp.A_PERS = @pc
	--	and datediff(day, hp.A_STARTDATA, GETDATE()) >=0
	--	and ( DATEDIFF(DAY, GETDATE(), hp.A_ENDDATA) >=0 OR hp.A_ENDDATA is null)
	--join SPR_INVALIDGROUP igr
	--	on hp.A_INVALID_GROUP= igr.ouid
	
select @V_A_INVALID_GROUP = A_INVALID_GROUP, @V_A_STARTDATA = A_STARTDATA, @V_A_ENDDATA = A_ENDDATA, @V_A_INV_REAS = A_INV_REAS
from
(
select h.A_INVALID_GROUP, h.A_STARTDATA, h.A_ENDDATA, h.A_INV_REAS,
	row_number() over (order by h.A_STARTDATA DESC, h.OUID DESC) as nn
from WM_HEALTHPICTURE h
	 join INDIVID_PROGRAM ip on ip.A_OUID = @newProgId and ip.PERSONOUID = h.A_PERS
where h.A_STATUS = 10 and h.A_INVALID_GROUP is not null and
	  (h.A_ENDDATA is null or convert(date, h.A_ENDDATA) >= convert(date, GETDATE()))
) a
where nn = 1

update INDIVID_PROGRAM
set A_INVALID_GROUP = @V_A_INVALID_GROUP, A_STARTDATA = @V_A_STARTDATA, A_ENDDATA = @V_A_ENDDATA, A_INV_REAS = @V_A_INV_REAS
where A_OUID = @newProgId

set @tmp2 = @V_A_INVALID_GROUP
/*======================================================================*/

/*-----------Бартел-Лаутон----------*/

--set @A_EATINH_BARTHEL = 99
--set @A_BATHING_BARTHEL = 99
--set @A_WASHING_BARTHEL = 99
--set @A_CONTROLLING_DEFECATION_BARTHEL = 99
--set @A_URINATION_BARTHEL = 99
--set @A_USE_TOILET_BARTHEL = 99
--set @A_MOVEMENT_BARTHEL = 99
--set @A_BED_TO_CHAIR_BARTHEL = 99
--set @A_MOVING_DISTANCEA_LAWTON = 99
--set @A_COOKING_FOOD_LAWTON = 99
--set @A_HOUSEKEEPING_LAWTON = 99
--set @A_USE_MEDICATION_LAWTON = 99

--select @pet = bl.A_PETITION
--from INDIVID_PROGRAM ipr
--	join WM_BLANK bl on bl.A_STATUS = 10 and bl.A_DOC = ipr.A_DOC
--where ipr.A_OUID = @newProgId

/*----------------Зависимость от посторонней помощи-------------*/

				set @count_ad = 0
				set @fl_ad = 0
				set @fl_ssr = 0
				
				set @A_MOVE_OUTSIDE_HOME = '999'
				set @A_APARTMENT_CLEANING = '999'
				set @A_COOKING = '999'
				set @A_RECEPTION_EAT_MED = '999'
				set @A_DRESSING = '999'
				set @A_HYGIENE = '999'
				set @A_URINATION_DEFECATION = '999'
				set @A_MOVING_HOUSE = '999'
				
				IF OBJECT_ID('tempdb..#tmpad') IS NOT NULL BEGIN DROP TABLE #tmpad END
				IF OBJECT_ID('tempdb..#tmpads') IS NOT NULL BEGIN DROP TABLE #tmpads END
				
				if (@so = 4 and @pre = 1)    /*Пересмотр и стационар*/
				 begin
					select ad.A_OUID, ad.A_DEGREE, ad.A_SUM_BALS, CONVERT(date, ad.A_DATE_INSPECT) as A_DATE_INSPECT,
						row_number() over (order by ad.A_DATE_INSPECT DESC) as nn,
						ad.A_MOVE_OUTSIDE_HOME, ad.A_APARTMENT_CLEANING, ad.A_COOKING, ad.A_RECEPTION_EAT_MED, ad.A_DRESSING, ad.A_HYGIENE, ad.A_URINATION_DEFECATION,
						ad.A_MOVING_HOUSE,
						ad.A_PROTECTION
					into #tmpads
					from WM_ASSESSMENT_DEPENDENCE_STAZ ad
					where ad.A_STATUS = 10 and /*DATEDIFF(day, ad.A_DATE_INSPECT, getdate()) <= 15*/ ad.PERSONOUID = @pc and
					CONVERT(date, getdate()) between CONVERT(date, ad.A_DATE_INSPECT) and CONVERT(date, ad.A_DATE_NEXT_INSPECTION)
					and ad.A_DEGREE = @degree and ad.A_SUM_BALS = @TOTAL_POINTS
				
					select
						@A_MOVE_OUTSIDE_HOME = A_MOVE_OUTSIDE_HOME, @A_APARTMENT_CLEANING = A_APARTMENT_CLEANING, @A_COOKING = A_COOKING, @A_RECEPTION_EAT_MED = A_RECEPTION_EAT_MED,
						@A_DRESSING = A_DRESSING, @A_HYGIENE = A_HYGIENE, @A_URINATION_DEFECATION = A_URINATION_DEFECATION,
						@A_MOVING_HOUSE = A_MOVING_HOUSE
					from #tmpads 
					where nn = 1 and A_PROTECTION = 2
					
					select @count_ad = COUNT(*) from #tmpads where nn = 1 and A_PROTECTION = 2
				 end
				else
				 begin
					select ad.A_OUID, ad.A_DEGREE, ad.A_SUM_BALS, CONVERT(date, ad.A_DATE_INSPECT) as A_DATE_INSPECT,
						row_number() over (order by ad.A_DATE_INSPECT DESC) as nn,
						ad.A_MOVE_OUTSIDE_HOME, ad.A_APARTMENT_CLEANING, ad.A_COOKING, ad.A_RECEPTION_EAT_MED, ad.A_DRESSING, ad.A_HYGIENE, ad.A_URINATION_DEFECATION,
						ad.A_MOVING_HOUSE,
						ad.A_PROTECTION
					into #tmpad
					from WM_ASSESSMENT_DEPENDENCE ad
					where ad.A_STATUS = 10 and /*DATEDIFF(day, ad.A_DATE_INSPECT, getdate()) <= 15*/ ad.PERSONOUID = @pc and
					CONVERT(date, getdate()) between CONVERT(date, ad.A_DATE_INSPECT) and CONVERT(date, ad.A_DATE_NEXT_INSPECTION)
					and ad.A_DEGREE = @degree and ad.A_SUM_BALS = @TOTAL_POINTS
				
					select
						@A_MOVE_OUTSIDE_HOME = A_MOVE_OUTSIDE_HOME, @A_APARTMENT_CLEANING = A_APARTMENT_CLEANING, @A_COOKING = A_COOKING, @A_RECEPTION_EAT_MED = A_RECEPTION_EAT_MED,
						@A_DRESSING = A_DRESSING, @A_HYGIENE = A_HYGIENE, @A_URINATION_DEFECATION = A_URINATION_DEFECATION,
						@A_MOVING_HOUSE = A_MOVING_HOUSE
					from #tmpad 
					where nn = 1 and A_PROTECTION = 2
					
					select @count_ad = COUNT(*) from #tmpad where nn = 1 and A_PROTECTION = 2
				 end
				
				--select @fl_ad = case when count(*) <> 0 and count(*) = sum(case when l.A_TOID in (462897, 462898, 477548, 474039) then 1 else 0 end) then 1 else 0 end
				--from WM_PET_ADDIT_SOC_POS_LINK l
				--	 join WM_PETITION p on p.OUID = @pet and p.A_ADVANCED_OBJ = l.A_FROMID
				
				--select @fl_ssr = case when count(*) = 0 or sum(case when ssr.A_CAUSE in (1, 2, 3, 5) then 1 else 0 end) = 0 then 1 else 0 end
				--from SOC_SERV_REASON_STATEMENT ssr
				--	 join WM_PETITION p on p.OUID = @pet and p.A_ADVANCED_OBJ = ssr.A_PET_ADDITIONAL
				--where ssr.A_STATUS = 10 
				
				select @fl_ad = case when count(*) <> 0 and count(*) = sum(case when l.A_TOID in (462897, 462898, 477548, 474039) then 1 else 0 end) then 1 else 0 end
				from LINK_INDIVIDPROGRAM_SPRORGUSON l
				where l.A_FROMID = @newProgId
				
				select @fl_ssr = case when count(*) = 0 or sum(case when ss.A_CAUSE in (1, 2, 3, 5, 13) then 1 else 0 end) = 0 then 1 else 0 end
				from LINK_CAUSE_IPPSU l
					join SOC_SERV_REASON_STATEMENT ss on ss.A_STATUS = 10 and ss.A_OUID = l.A_TO_ID
				where l.A_FROM_ID = @newProgId 
				
/*--------------------------------------------------------------*/


--select @A_EATINH_BARTHEL = isnull(cast(da.A_EATINH_BARTHEL as int), 99),
--	   @A_BATHING_BARTHEL = isnull(cast(da.A_BATHING_BARTHEL as int), 99),
--	   @A_WASHING_BARTHEL = isnull(cast(da.A_WASHING_BARTHEL as int), 99),
--	   @A_CONTROLLING_DEFECATION_BARTHEL = isnull(cast(da.A_CONTROLLING_DEFECATION_BARTHEL as int), 99),
--	   @A_URINATION_BARTHEL = isnull(cast(da.A_URINATION_BARTHEL as int), 99),
--	   @A_USE_TOILET_BARTHEL = isnull(cast(da.A_USE_TOILET_BARTHEL as int), 99),
--	   @A_MOVEMENT_BARTHEL = isnull(cast(da.A_MOVEMENT_BARTHEL as int), 99),
--	   @A_BED_TO_CHAIR_BARTHEL = isnull(cast(da.A_BED_TO_CHAIR_BARTHEL as int), 99),
--	   @A_MOVING_DISTANCEA_LAWTON = isnull(cast(da.A_MOVING_DISTANCEA_LAWTON as int), 99),
--	   @A_COOKING_FOOD_LAWTON = isnull(cast(da.A_COOKING_FOOD_LAWTON as int), 99),
--	   @A_HOUSEKEEPING_LAWTON = isnull(cast(da.A_HOUSEKEEPING_LAWTON as int), 99),
--	   @A_USE_MEDICATION_LAWTON = isnull(cast(da.A_USE_MEDICATION_LAWTON as int), 99)
--FROM WM_ACTDOCUMENTS actDoc
--	JOIN SPR_LINK_APPEAL_DOC ON SPR_LINK_APPEAL_DOC.TOID=actDoc.OUID AND SPR_LINK_APPEAL_DOC.FROMID=@pet
--	join WM_AKT_MATERIAL_LIVING_2017 da on actDoc.OUID = da.A_DOC_2017 and da.A_STATUS = 10
--	 join
--	 (select max(doc.OUID) as ouid
--	 from WM_ACTDOCUMENTS doc
--		join SPR_LINK_APPEAL_DOC ld ON ld.TOID = doc.OUID AND ld.FROMID=@pet
--	 where doc.DOCUMENTSTYPE = 4213 and doc.A_STATUS = 10) doc1 on doc1.ouid = actDoc.OUID
--where actDoc.DOCUMENTSTYPE = 4213 and actDoc.A_STATUS = 10
/*----------------------------------*/

--select @pc, @vozr, @form, @tmp2

if (@count_ad <> 0 or @fl_ad = 1 or @fl_ssr = 1 or @vozr < 18)
begin

if object_id('tempdb..#tmpo') is not null drop table #tmpo


/*Услуги и подуслуги для удаления*/
select A_OUID
into #tmpo
from SOCSERV_INDIVDPROGRAM
where A_INDIVID_PROGRAM = @newProgId

/*Подуслуги*/
delete from LINK_IPPSU_SIZE
where A_FROMID in (select A_OUID from #tmpo)

/*Услуги*/
delete from SOCSERV_INDIVDPROGRAM
where A_OUID in (select A_OUID from #tmpo)

								
/*--------------------Заполнение услуг с подуслугами----------------*/

/*Услуги и подуслуги*/
if object_id('tempdb..#tmpu1') is not null drop table #tmpu1

set @cause12 = 0

select @cause12 = COUNT(*)
from LINK_CAUSE_IPPSU l
	 join SOC_SERV_REASON_STATEMENT ss on ss.A_STATUS = 10 and ss.A_OUID = l.A_TO_ID and ss.A_CAUSE = 12
where l.A_FROM_ID = @newProgId

set @rodn = 0
select @rodn = COUNT(*)
from LINK_INDIVIDPROGRAM_SPRORGUSON l
where l.A_FROMID = @newProgId and l.A_TOID = 474007

/*Учреждения в ИППСУ с учетом подчиненности*/
if object_id('tempdb..#lipu') is not null drop table #lipu

select A_FROMID, A_TOID
into #lipu
from
(
select lipu1.A_FROMID, lipu1.A_TOID
from LINK_INDIVIDPROGRAM_SPRORGUSON lipu1
	join ESRN_OSZN_DEP e on lipu1.A_TOID = e.OUID
	join SPR_ORG_BASE sob on sob.A_STATUS = 10 and sob.OUID = e.OUID
where lipu1.A_FROMID = @newProgId and LEN(e.A_OSZNCODE) = 4
union
select lipu1.A_FROMID, e1.OUID as A_TOID
from LINK_INDIVIDPROGRAM_SPRORGUSON lipu1
	join ESRN_OSZN_DEP e on lipu1.A_TOID = e.OUID
	join SPR_ORG_BASE sob on sob.A_STATUS = 10 and sob.OUID = e.OUID
	join ESRN_OSZN_DEP e1 on e1.A_OVERHEAD = e.OUID
	join SPR_ORG_BASE sob1 on sob1.A_STATUS = 10 and sob1.OUID = e1.OUID
where lipu1.A_FROMID = @newProgId and LEN(e.A_OSZNCODE) = 3
) aaa

/*--Зависимость от посторонней помощи--*/
if (@fl_ad = 1 or @fl_ssr = 1 or @vozr < 18)  /*не учитывается*/
	begin
	 set @A_MOVE_OUTSIDE_HOME = '999'
	 set @A_APARTMENT_CLEANING = '999'
	 set @A_COOKING = '999'
	 set @A_RECEPTION_EAT_MED = '999'
	 set @A_DRESSING = '999'
	 set @A_HYGIENE = '999'
	 set @A_URINATION_DEFECATION = '999'
	 set @A_MOVING_HOUSE = '999'
	end
 else          /*учитывается*/
	begin
	 set @A_MOVE_OUTSIDE_HOME = isnull(@A_MOVE_OUTSIDE_HOME, '999')
	 set @A_APARTMENT_CLEANING = isnull(@A_APARTMENT_CLEANING, '999')
	 set @A_COOKING = isnull(@A_COOKING, '999')
	 set @A_RECEPTION_EAT_MED = isnull(@A_RECEPTION_EAT_MED, '999')
	 set @A_DRESSING = isnull(@A_DRESSING, '999')
	 set @A_HYGIENE = isnull(@A_HYGIENE, '999')
	 set @A_URINATION_DEFECATION = isnull(@A_URINATION_DEFECATION, '999')
	 set @A_MOVING_HOUSE = isnull(@A_MOVING_HOUSE, '999')
	end
/*-----------------------------------------*/

select distinct /*ss.A_SOC_SERV,*/ LEFT(soc.a_name, 1) as fsoc, soc.OUID, soc.A_CODE, ss.A_OUID
into #tmpu1
from (select A_FROMID, A_TOID from #lipu) lipu
	join INDIVID_PROGRAM ipr on ipr.A_OUID = lipu.A_FROMID
	join LINK_SOCSERV_USON lsu on lsu.A_ORG_USON = lipu.A_TOID and lsu.A_STATUS = 10
	join SPR_SOC_SERV soc on soc.OUID = lsu.A_SOC_SERV and soc.A_STATUS = 10
	join LINK_USON_SOC_SERV lpu on lsu.A_OUID = lpu.A_FROMID
	join SPR_SUB_SOC_SERV ss on ss.A_OUID = lpu.A_TOID and ss.A_STATUS = 10
where lipu.A_FROMID = @newProgId and
	  (lsu.A_DATE_FINISH_SERV is null or convert(date, lsu.A_DATE_FINISH_SERV) >= convert(date, GETDATE())) 
	  and (lsu.A_DATE_START_SERV is null or convert(date, lsu.A_DATE_START_SERV) <= convert(date, GETDATE()))
	  and (ss.A_FIN_DATE is null or convert(date, ss.A_FIN_DATE) >= convert(date, GETDATE())) 
	  and (ss.A_START_DATE is null or convert(date, ss.A_START_DATE) <= convert(date, GETDATE()))
          
          ---детям не должны подтягиваться услуги и подуслуги со степенью (26.02.2021, Черепанова К.А)
	  and (@vozr<18 and ss.A_DEGREE_NULL=1 or @vozr>=18)

	--and 
	--(
	--((@sex = 2 or @vozr < 18) and ss.A_OUID not in (31, 141))
	--or
	--(@sex = 1 and @vozr >= 18)
	--)
	
	and 
	(
	((@sex = 2 or @vozr < 18) and soc.OUID not in (2928, 2960, 2987))
	or
	(@sex = 1 and @vozr >= 18)
	)
	
	--and
	--(
	--(@cause12 = 0) or
	--(@cause12 > 0 and lsu.A_ORG_USON in (462898, 477548)
	--	and ss.A_SOC_SERV in (2702, 2704, 2705, 2708, 2713, 2714, 2715, 2718, 2719, 2721, 2723, 2725, 2726, 2729, 2730, 2731, 2739, 2744, 2745)
	--	and ss.A_OUID in (67, 70, 71, 76, 83, 85, 86, 91, 96, 97, 100, 101, 103, 104, 105, 106, 107, 109, 110, 111, 112, 113, 119, 123, 124)) or
	--(@cause12 > 0 and lsu.A_ORG_USON not in (462898, 477548)
	--	and ss.A_SOC_SERV in (2702, 2704, 2705, 2708, 2718, 2719, 2723, 2725, 2726, 2729, 2730, 2731, 2744, 2745, 2746, 2747, 2748)
	--	and ss.A_OUID in (67, 70, 71, 76, 96, 97, 101, 103, 104, 105, 106, 107, 109, 110, 111, 112, 113, 123, 124, 125, 126, 127))
	--)
	
	and
	(
	(@cause12 = 0 or ipr.A_FORM_SOCSERV <> 1) or
	(
	(@cause12 > 0 and ipr.A_FORM_SOCSERV = 1) and
	 soc.OUID in (2702, 2704, 2705, 2963, 2964, 2965, 2713, 2714, 2716, 2717, 2718, 2719, 2970, 2971, /*2972,*/ 2729, 2973, 2974, /*2975,*/ 2977, 2978, 2745, 2748, 2708, 2723, 2726, 2731,
3061	,	--	2.1.01. Предоставление помещений для организации социально-реабилитационных и социокультурных мероприятий
3063	,	--	2.1.03. Предоставление в пользование мебели согласно утвержденным нормативам
3064	,	--	2.1.04. Обеспечение книгами, журналами, газетами, настольными играми, иным инвентарем для организации досуга
3070	,	--	2.1.08.03. Оказание помощи при одевании и (или) раздевании
3071	,	--	2.1.08.04. Оказание помощи в пользовании туалетом
3072	,	--	2.1.09. Оказание помощи в передвижении по помещению и вне помещения
3074	,	--	2.2.01. Проведение первичного медицинского осмотра, первичной санитарной обработки
3075	,	--	2.2.02. Оказание при необходимости первичной медико-санитарной помощи
3076	,	--	2.2.03. Наблюдение за состоянием здоровья получателя социальных услуг
3077	,	--	2.2.04. Содействие в выполнении медицинских процедур по назначению врача, наблюдение за своевременным приемом лекарственных препаратов для медицинского применения, назначенных врачом
3078	,	--	2.2.05. Проведение занятий с использованием методов адаптивной физической культуры
3079	,	--	2.2.06. Проведение оздоровительных мероприятий, в том числе по формированию здорового образа жизни
3081	,	--	2.3.01. Социально-психологическая диагностика
3082	,	--	2.3.02. Социально-психологическая коррекция
3085	,	--	2.4.01. Организация досуга
3086	,	--	2.4.02. Социально-педагогическая диагностика
3087	,	--	2.4.03. Социально-педагогическая коррекция
3089	,	--	2.4.05. Организация помощи законным представителям детей с ограниченными возможностями здоровья, в том числе детей-инвалидов, в обучении детей навыкам самообслуживания, общения и контроля, навыкам поведения в быту и общественных местах
3096	,	--	2.6.01. Обучение навыкам самообслуживания, общения и контроля, навыкам поведения в быту и общественных местах
3097	,	--	2.6.02. Проведение социально-реабилитационных мероприятий в соответствии с индивидуальными программами реабилитации или абилитации инвалидов, в том числе детей-инвалидов
3098		--	2.6.03. Обучение инвалидов, в том числе детей-инвалидов, пользованию техническими средствами реабилитации
	 ) and
	 ss.A_OUID not in (315, 323)
	)
	)
	
	and (@vozr < 18 or (@vozr >= 18 and soc.OUID not in (2708, 2801, 2784)))
/*	
	and (@A_EATINH_BARTHEL <> 10 or (@A_EATINH_BARTHEL = 10 and ss.A_OUID <> 6))
	and (@A_BATHING_BARTHEL <> 5 or (@A_BATHING_BARTHEL = 5 and ss.A_OUID not in (28, 34)))
	and (@A_COOKING_FOOD_LAWTON <> 3 or (@A_COOKING_FOOD_LAWTON = 3 and ss.A_OUID <> 5))
	and (@A_HOUSEKEEPING_LAWTON <> 3 or (@A_HOUSEKEEPING_LAWTON = 3 and ss.A_OUID not in (8, 9, 10, 15)))
	and (@A_USE_MEDICATION_LAWTON <> 3 or (@A_USE_MEDICATION_LAWTON = 3 and ss.A_OUID <> 49))
	and (@A_BED_TO_CHAIR_BARTHEL <> 15 or @A_MOVING_DISTANCEA_LAWTON <> 3 or (@A_BED_TO_CHAIR_BARTHEL = 15 and @A_MOVING_DISTANCEA_LAWTON = 3 and ss.A_OUID <> 45))
	and (@A_MOVEMENT_BARTHEL <> 15 or (@A_MOVEMENT_BARTHEL = 15 and ss.A_OUID <> 24))
	and (@A_BATHING_BARTHEL <> 5 or @A_WASHING_BARTHEL <> 5 or (@A_BATHING_BARTHEL = 5 and @A_WASHING_BARTHEL = 5 and ss.A_OUID not in (29, 30, 31)))
	and (@A_BATHING_BARTHEL <> 5 or @A_CONTROLLING_DEFECATION_BARTHEL <> 10 or @A_URINATION_BARTHEL <> 10 or @A_USE_TOILET_BARTHEL <> 10 or @A_MOVEMENT_BARTHEL <> 15 or
		(@A_BATHING_BARTHEL = 5 and @A_CONTROLLING_DEFECATION_BARTHEL = 10 and @A_URINATION_BARTHEL = 10 and @A_USE_TOILET_BARTHEL = 10 and @A_MOVEMENT_BARTHEL = 15 and ss.A_OUID <> 35))
*/

	and
	(
	(@fl_ad = 1 or @fl_ssr = 1 or @vozr < 18)
	or
	(
	@fl_ad = 0 and @fl_ssr = 0 and @vozr >= 18 and
	(
	(isnull(ss.A_DEGREE_1, 0) = 1 and ipr.A_DEGREE = 1) or
	(isnull(ss.A_DEGREE_2, 0) = 1 and ipr.A_DEGREE = 2) or
	(isnull(ss.A_DEGREE_3, 0) = 1 and ipr.A_DEGREE = 3) or
	(isnull(ss.A_DEGREE_4, 0) = 1 and ipr.A_DEGREE = 4) or
	(isnull(ss.A_DEGREE_5, 0) = 1 and ipr.A_DEGREE = 5) or
	(isnull(ss.A_DEGREE_0, 0) = 1 and ipr.A_DEGREE = 0) or
	(isnull(ss.A_DEGREE_NULL, 0) = 1 and ipr.A_DEGREE is null)
	)
	)
	)
	
	and
	(
	((ipr.A_INVALID_GROUP in (3, 4) or ipr.A_INVALID_GROUP is null) and soc.OUID <> 2941)
	or
	(ipr.A_INVALID_GROUP in (1, 2))
	)
	
	and
	(
	((ipr.A_INVALID_GROUP in (1, 2, 3) or ipr.A_INVALID_GROUP is null) and soc.OUID <> 2955)
	or
	(ipr.A_INVALID_GROUP = 4)
	)
	
	and (@A_MOVE_OUTSIDE_HOME <> '1_0' or @A_MOVE_OUTSIDE_HOME = '1_0' and soc.OUID not in (2672, 2931, 2940, 2681, 2962, 2965, 2980, 2990, 2770))
	and (@A_MOVE_OUTSIDE_HOME <> '5_2' or @A_MOVE_OUTSIDE_HOME = '5_2' and soc.OUID <> 2675)
	and (@A_APARTMENT_CLEANING <> '1_0' or @A_APARTMENT_CLEANING = '1_0' and soc.OUID not in (2667, 2666))
	and (@A_COOKING <> '1_0' or @A_COOKING = '1_0' and soc.OUID <> 2659)
	and (@A_RECEPTION_EAT_MED not in ('1_0') or @A_RECEPTION_EAT_MED in ('1_0') and soc.OUID not in (2660, 2979))
	and (@A_DRESSING <> '1_0' or @A_DRESSING = '1_0' and soc.OUID not in (2929, 2963))
	and (@A_HYGIENE <> '1_0' or @A_HYGIENE = '1_0' and soc.OUID not in (2923, 2924, 2933, 2934, 2956, 2961, 2981, 2982, 3025))
	and (@A_URINATION_DEFECATION <> '1_0' or @A_URINATION_DEFECATION = '1_0' and soc.OUID not in (2935, 2936, 2937, 2964, 2992, 2993, 2994))

	and (@A_HYGIENE not in ('2_0.5', '3_1') or @A_HYGIENE in ('2_0.5', '3_1') and soc.OUID not in (2981, 2982, 2995))
	and (@A_URINATION_DEFECATION <> '2_0.5' or @A_URINATION_DEFECATION = '2_0.5' and soc.OUID not in (2992, 2993))
	and (@A_MOVING_HOUSE not in ('1_0', '2_0', '3_0.5') or @A_MOVING_HOUSE in ('1_0', '2_0', '3_0.5') and soc.OUID <> 2770)
	
	and	(
		(ISNULL(ipr.A_ORG_TYPE, '10') <> '20' or isnull(ipr.A_DEGREE, 0) not in (4, 5)) or 
		ISNULL(ipr.A_ORG_TYPE, '10') = '20' and isnull(ipr.A_DEGREE, 0) in (4, 5) and soc.OUID not in (2783, 2784, 2786, 2787)
		)
		
	and (@vozr < 60 or @vozr >= 60 and soc.OUID not in (2783, 2787))
	
	and (@rodn = 0 and soc.OUID <> 2784 or @rodn <> 0)	
	
	if (@fl_ad = 1 or @fl_ssr = 1 or @vozr < 18) delete from #tmpu1 where A_OUID in (200,202,209,208,266,270,228,231,236,238,255)	
	
/*Только нужные услуги в соответствии со старым алгоритмом*/

if object_id('tempdb..#tmpu') is not null drop table #tmpu
create table #tmpu (ouid int)


					if (@form = 'servStat')
					begin		
						-- стационар
						if (@tmp2 is not null)
						begin	 
						--- инвалиды
							if (@tmp2<>4)
							begin
								-- обычные инвалиды
								insert #tmpu (ouid)
								select distinct OUID
								from #tmpu1
								where fsoc = '3' and A_CODE <> 'socServSComStaz_2794'
							end
							else
							begin
								--- дети инвалиды 
								insert #tmpu (ouid)
								select distinct OUID
								from #tmpu1
								where fsoc = '3'
							end	
						end
						else
						begin
						-- не инвалиды
							insert #tmpu (ouid)
							select distinct OUID
							from #tmpu1
							where fsoc = '3' and A_CODE not in (/*'socServSComStaz_2793',*/ 'socServSComStaz_2795', 'socServSComStaz_2796', 'socServSComStaz_2797', 'socServSComStaz_2798', 'socServRehabSComStaz_3148', 'socServRehabSComStaz_3149', 'socServRehabSComStaz_3150')
								and (@vozr < 18 or (@vozr >= 18 and A_CODE <> 'socServSComStaz_2794'))
						end	
					end
					else					
						if (@form = 'servHome')  
						begin
						-- надомное 											
						if (@tmp2 is not null)
						begin	 
						--- инвалиды
							if (@tmp2<>4)
							begin
							-- обычные инвалиды
								insert #tmpu (ouid)
								select distinct OUID
								from #tmpu1
								where fsoc = '1' and A_CODE <> 'socServSComDom_2699'
							end
							else
							begin
							--- дети инвалиды
								insert #tmpu (ouid) 
								select distinct OUID
								from #tmpu1
								where fsoc = '1'
							end						
						end
						else
						begin
						-- не инвалиды
							insert #tmpu (ouid)
							select distinct OUID
							from #tmpu1
							where fsoc = '1' and A_CODE not in ('socServSComDom_2697', 'socServSComDom_2698', 'socServSComDom_2699')
						end	
						end
					else
/*-------------------------------------------------------*/						
						if (@form = 'serHalfStat')  
						begin
						-- полустационар 					
						if (@tmp2 is not null)
						begin	 
						--- инвалиды
							insert #tmpu (ouid)
							select distinct OUID
							from #tmpu1
							where fsoc = '2'
						end
						else
						begin
						-- не инвалиды
							insert #tmpu (ouid)
							select distinct OUID
							from #tmpu1
							where fsoc = '2' and A_CODE not in ('socServSComPStaz_2744', 'socServSComPStaz_2745', 'socServSComPStaz_2746', 'socServSComPStaz_2747', 'socServSComPStaz_2748', 'socServRehabSComPStaz_3097', 'socServRehabSComPStaz_3098')
						end	
						end
/*--------------------------------------------------------*/	

insert SOCSERV_INDIVDPROGRAM (GUID, A_TS, A_STATUS, A_SYSTEMCLASS, A_CREATEDATE, A_INDIVID_PROGRAM, A_SOC_SERV, A_START_DATE, A_FINISH_DATE)
select newid(), getdate(), 10, 10392185, getdate(), @newProgId, u.OUID, soc.A_DATESTART, soc.A_DATEFINISH
from #tmpu u
	join SPR_SOC_SERV soc on soc.OUID = u.ouid

insert LINK_IPPSU_SIZE (A_FROMID, A_TOID)
select ssip.A_OUID, u1.A_OUID
from #tmpu1 u1
	join SOCSERV_INDIVDPROGRAM ssip on ssip.A_INDIVID_PROGRAM = @newProgId and ssip.A_STATUS = 10 and ssip.A_SOC_SERV = u1.OUID
	
select 'Услуги обновлены' as a
/*-------------------------------------------------------*/
end
else
select 'Нет данных оценки зависимости от посторонней помощи' as a
end
else
select 'ИП уже утверждена' as a