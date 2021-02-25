--------------------------------------------------------------------------------------------


--Объявление переменных.
DECLARE @pet        INT         --Идентификатор заявления.
DECLARE @pcpet      INT         --Личное дело заявителя.
DECLARE @petType    INT         --Тип заявления.
DECLARE @dreg       DATE        --Дата регистрации заявления.
DECLARE @serv       INT         --Назначение.
DECLARE @phones     VARCHAR(100)--Телефоны.
DECLARE @reg        INT         --Количество лиц.
DECLARE @lg         INT         --Количество членов семьи, на которых распространяется льгота.
DECLARE @docs       VARCHAR(100)--Наименование документа о владении.
DECLARE @docstype   VARCHAR(100)--Код документа о владении.
DECLARE @d1         DATE
DECLARE @d2         DATE
DECLARE @part       FLOAT       --Доля собственности.
DECLARE @fls        INT         --@fls = 0 - наниматель, @fls = 1 - собственник.
DECLARE @pcpetl     INT         --Льготополучатель.
DECLARE @adrrl      INT         --Адрес жилого помещения.
DECLARE @dnosn      DATE        --Дата начала действия основания.
DECLARE @s1         DATE
DECLARE @s2         DATE
DECLARE @minpet     INT
DECLARE @minpetdate DATE


--------------------------------------------------------------------------------------------

--Входные параметры отчета.
SET @pet = #objectID#                                                       --Заявление.
SET @s1 = CONVERT(DATE, DATEADD(DAY, 1 - DAY(#beginDate#), #beginDate#))    --Начало отчетной недели. 
SET @s2 = CONVERT(DATE, DATEADD(DAY, 1 - DAY(#endDate#), #endDate#))        --Конец отчетной недели. 


--------------------------------------------------------------------------------------------


--Информация о заявлении.
SELECT 
    @pcpet = appeal.A_PERSONCARD, 
    @petType = petition.A_PETITION_TYPE, 
    @dreg = CONVERT(DATE, appeal.A_DATE_REG), 
    @pcpetl = petition.A_MSPHOLDER
FROM WM_PETITION petition --Заявления.
----Обращение гражданина.		
    INNER JOIN WM_APPEAL_NEW appeal     
        ON appeal.OUID = petition.OUID --Связка с заявлением.
            AND appeal.A_STATUS = 10    --Статус в БД "Действует".
WHERE petition.OUID = @pet --Заявление отчета.

--Если заявление на назначение, то берем привязанное назначение к заявлению.
IF @petType = 1 BEGIN
    SELECT 
        @serv = servServ.OUID
    FROM ESRN_SERV_SERV servServ        --Назначение.
    WHERE servServ.A_STATUS = 10        --Статус в БД "Действует".
        AND servServ.A_SERV = 310       --"Компенсационная выплата в связи с расходами по оплате жилых помещений, коммунальных и других видов услуг" для "Члены семей погибших (умерших) военнослужащих"
        AND servServ.A_REQUEST = @pet   --Назначение по заявлению отчета. 
END
--Если на возобновление или перерасчет, то берем назначение на перерасчета/продления/возобновления выплат.
ELSE BEGIN
    SELECT 
        @serv = A_EXTEND_SERV_BASE --Назначение для перерасчета/продления/возобновления выплат.
    FROM WM_PETITION
    WHERE OUID = @pet
END

--Если заявление на назначение, то берем в качестве даты начала первый день месяца даты регистрации заявления.
IF @petType = 1 BEGIN
   SET @d1 = DATEADD("day", 1 - DAY(@dreg), @dreg) 
END
--Если заявление на возобновление или перерасчет, то берем в качестве даты начала следующий день после окончания действия назначения.
ELSE BEGIN
    SELECT 
        @d1 = DATEADD(DAY, 1, CONVERT(DATE, period.A_LASTDATE))
    FROM SPR_SERV_PERIOD period --Период предоставления МСП.
    ----Подзапрос для выбора последего периода.
        INNER JOIN (
            SELECT
                MAX(STARTDATE) as sd
		    FROM SPR_SERV_PERIOD    --Период предоставления МСП.
		    WHERE A_SERV = @serv    --Связка с назначением.
		        AND  A_STATUS = 10  --Статус в БД "Действует". 
	    ) md 
	        ON md.sd = period.STARTDATE
    WHERE period.A_SERV = @serv     --Связка с назначением.
        AND period.A_STATUS = 10    --Статус в БД "Действует". 
END

--В качестве даты окончания берем +6 месяцев - 1 день от даты начала.
SET @d2 = DATEADD(DAY, -1, DATEADD(MONTH, 6, @d1))


--------------------------------------------------------------------------------------------


--Телефоны.
SET @phones = '' --Подготовка для цикла.
SELECT 
    @phones = @phones + ' ' + phone.A_NUMBER --Запись всех телефонов заявителя.
FROM WM_PCPHONE phone 
WHERE phone.A_PERSCARD = @pcpet	--Заявитель отчета.
    AND phone.A_STATUS = 10     --Статус в БД "Действует".


--------------------------------------------------------------------------------------------


--Зарегистрированные.
SELECT 
    @reg = actDocuments.A_AMOUNT_PERSON, 
    @adrrl = actDocuments.A_REGFLAT, 
    @lg = actDocuments.A_AMOUNT_LGOT
FROM SPR_LINK_APPEAL_DOC appeal_doc --Связка обращения с документами.
----Действующие документы.
    INNER JOIN WM_ACTDOCUMENTS actDocuments         
        ON actDocuments.OUID = appeal_doc.TOID      --Связка с обращением.
            AND actDocuments.A_STATUS = 10          --Статус в БД "Действует".
            AND actDocuments.DOCUMENTSTYPE = 2091   --Документ, содержащий сведения о лицах, зарегистрированных совместно с заявителем по месту его постоянного жительства.
----Подзапрос для взятия последнего документа.
    INNER JOIN (
        SELECT 
            MAX(doc.ISSUEEXTENSIONSDATE) AS ISSUEEXTENSIONSDATE
        FROM SPR_LINK_APPEAL_DOC ld
        ----Действующие документ.
            INNER JOIN WM_ACTDOCUMENTS doc 
                ON doc.OUID  = ld.TOID              --Связка с обращением.
                    AND doc.A_STATUS = 10           --Статус в БД "Действует".
                    AND doc.DOCUMENTSTYPE = 2091    --Документ, содержащий сведения о лицах, зарегистрированных совместно с заявителем по месту его постоянного жительства.
        WHERE ld.FROMID = @pet                      --Обращение отчета.
    ) md 
        ON md.ISSUEEXTENSIONSDATE = actDocuments.ISSUEEXTENSIONSDATE --Документ с последней датой.
WHERE appeal_doc.FROMID = @pet --Обращение отчета.

--Если нет количества лиц, то устанваливается количество членов семьи, на которых распространяется льгота.
IF @reg IS NULL 
    SET @reg = @lg


--------------------------------------------------------------------------------------------


--Документ о владении (c 01-08-2020 не обязателен).
SELECT 
    @docs = typeDoc.a_name, 
    @docstype = typeDoc.A_CODE
FROM SPR_LINK_APPEAL_DOC appeal_doc --Связка обращения с документами.
----Действующие документы.
    INNER JOIN WM_ACTDOCUMENTS actDocuments   
        ON actDocuments.OUID = appeal_doc.TOID      --Связка с обращением.
            AND actDocuments.A_STATUS = 10          --Статус в БД "Действует".
            AND actDocuments.PERSONOUID = @pcpetl   --Связка с льготодержателем.
----Вид документа.
    INNER JOIN PPR_DOC typeDoc
        ON typeDoc.A_ID = actDocuments.DOCUMENTSTYPE    --Cвязка с документом.
            and typeDoc.A_PARENT = 2090                 --Документ из разряда подтверждающих правовые основания владения и пользования заявителем жилым помещением.
            and typeDoc.A_STATUS = 10                   --Статус типа документа в БД "Действует".
----Подзапрос для взятия последнего документа.
    INNER JOIN (
        SELECT 
            MAX(doc.ISSUEEXTENSIONSDATE) as ISSUEEXTENSIONSDATE
        FROM SPR_LINK_APPEAL_DOC ld
        ----Действующие документы.
            INNER JOIN WM_ACTDOCUMENTS doc 
                ON doc.OUID = ld.TOID              --Связка с обращением.
                    AND doc.A_STATUS = 10          --Статус в БД "Действует".
                    AND doc.PERSONOUID = @pcpetl   --Связка с льготодержателем.
        ----Вид документа.
            INNER JOIN PPR_DOC pprDoc1 
                ON pprDoc1.A_ID = doc.DOCUMENTSTYPE --Cвязка с документом.
                    AND pprDoc1.A_PARENT = 2090     --Документ из разряда подтверждающих правовые основания владения и пользования заявителем жилым помещением.
                    AND pprDoc1.A_STATUS = 10       --Статус типа документа в БД "Действует".
        WHERE ld.FROMID = @pet                      --Обращение отчета.
    ) md 
        ON md.ISSUEEXTENSIONSDATE = actDocuments.ISSUEEXTENSIONSDATE --Документ с последней датой.
WHERE appeal_doc.FROMID = @pet --Обращение отчета.

--Есть документ о владении и он относится к "Договор социального найма жилого помещения" или "Договор найма жилого помещения" или "Договор найма специализированного жилого помещения".
IF (@docs IS NOT NULL AND @docstype IN ('naim', 'specNaim', 'contractSocialHire'))
BEGIN
    SET @fls = 0    --Наниматель.
    SET @part = 1   --Доля 1.
END
ELSE
BEGIN
    SET @fls = 1 --Собственник.
    --Доли нет, или она равна 0.
    IF isnull(@part, 0) = 0 
        SET @part = 1 --Доля 1.
END


--------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#tmpspr') IS NOT NULL BEGIN DROP TABLE #tmpspr    END --Справка о праве.
IF OBJECT_ID('tempdb..#tmps')   IS NOT NULL BEGIN DROP TABLE #tmps      END --Доля собственности.


IF OBJECT_ID('tempdb..#tmpl') IS NOT NULL BEGIN DROP TABLE #tmpl END

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


--------------------------------------------------------------------------------------------


--Справки о праве.
SELECT 
    RTRIM(ISNULL(fioSurname.A_NAME, '') + ' ' + ISNULL(fioName.A_NAME,'') + ' ' + ISNULL(fioSecondname.A_NAME, '')) AS relativeFIO,
    ISNULL(actDocuments.DOCUMENTSERIES, '')                                                                         AS ser, 
    ISNULL(actDocuments.DOCUMENTSNUMBER, '')                                                                        AS num, 
    ISNULL(groupRole.A_NAME, '')                                                                                    AS relation,
    CASE 
        WHEN actDocuments.A_DOCBASESTARTDATE IS NOT NULL THEN CONVERT(CHAR, actDocuments.A_DOCBASESTARTDATE, 104) 
        ELSE '' 
    END                                                                                                             AS date,
    actDocuments.PERSONOUID, 
    actDocuments.A_DOCBASESTARTDATE
INTO #tmpspr	   
FROM SPR_LINK_APPEAL_DOC appeal_doc --Связка обращения с документами.
----Действующие документы.
    INNER JOIN WM_ACTDOCUMENTS actDocuments   
        ON actDocuments.OUID  = appeal_doc.TOID --Связка с обращением.
            AND actDocuments.A_STATUS = 10      --Статус в БД "Действует".
            AND actDocuments.DOCUMENTSTYPE IN (
                1796,	--Справка о праве на получение компенсационных выплат в связи с расходами по оплате жилого помещения, коммунальных и других видов услуг (ФЗ "О статусе военнослужащего", ст.24 п.4)
                2067,	--Справка о праве на получение компенсационных выплат в связи с расходами по оплате жилого помещения, коммунальных и др. видов услуг (78-ФЗ ст.2)
                3893,	--Справка о праве на получение компенсационных выплат в связи с расходами по оплате жилого помещения, коммунальных и других видов услуг (247-ФЗ, ст.10 п.1-3, п.5)
                3894	--Справка о праве на получение компенсационных выплат в связи с расходами по оплате жилого помещения, коммунальных и других видов услуг (283-ФЗ, п.1-3)
            )
----Подзапрос для выбора последнего документа.
    INNER JOIN (
        SELECT 
            doc.PERSONOUID, 
            MAX(doc.ISSUEEXTENSIONSDATE) AS ISSUEEXTENSIONSDATE
        FROM SPR_LINK_APPEAL_DOC ld --Связка обращения с документами.
        ----Действующие документы.
            INNER JOIN WM_ACTDOCUMENTS doc
                ON ld.TOID = doc.OUID                                   --Связка с обращением.
                    AND doc.A_STATUS = 10                               --Статус в БД "Действует".
                    AND doc.DOCUMENTSTYPE IN (1796, 2067, 3893, 3894)   --Нужный вид документа.       
        WHERE ld.FROMID = @pet --Обращение отчета.
        GROUP BY doc.PERSONOUID
    ) md 
        ON md.ISSUEEXTENSIONSDATE = actDocuments.ISSUEEXTENSIONSDATE    --Связка по дате.
            AND md.PERSONOUID = actDocuments.PERSONOUID                 --Связка по личному делу.
----Тип родсвтенной связи.
    LEFT JOIN SPR_GROUP_ROLE groupRole
        ON groupRole.OUID = actDocuments.A_RELATION --Связка с документом.
----Личное дело держателя документа.
	INNER JOIN WM_PERSONAL_CARD personalCard  
	    ON personalCard .OUID = actDocuments.PERSONOUID --Связка с документом.
	        AND personalCard.A_STATUS = 10              --Статус в БД "Действует".
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME --Связка с личным делом.     
WHERE appeal_doc.FROMID = @pet --Обращение отчета.

--Дата начала действия основания.
SELECT 
    @dnosn = MIN(A_DOCBASESTARTDATE) 
FROM #tmpspr 
WHERE PERSONOUID = @pcpetl


--------------------------------------------------------------------------------------------


--Доли собственности (c 01-08-2020 не учитывается).
SELECT 
    own.A_OUID, 
    own.A_OWNER_ID, 
    own.A_PART
INTO #tmps
FROM WM_OWNING own --Владельцы недвижимости.
----Справка о праве.
    INNER JOIN #tmpspr l 
        ON l.PERSONOUID = own.A_OWNER_ID
----Для выбора нужного имущества.
    INNER JOIN (
        SELECT 
	        own1.A_OWNER_ID, 
	        MAX(own1.A_OUID) AS A_OUID
        FROM WM_OWNING own1 --Владельцы недвижимости.
        ----Справка о праве.
            INNER JOIN #tmpspr l1 
                ON l1.PERSONOUID = own1.A_OWNER_ID --СВязка с недвижимостью.
        WHERE own1.A_ADDR_ID = @adrrl                                                               --Адрес такой же, как и в документе.
            AND own1.A_STATUS = 10                                                                  --Статус в БД "Действует".
            AND (own1.A_START_OWN_DATE IS NULL OR CONVERT(DATE, own1.A_START_OWN_DATE) <= @dreg)    --Дата возникновения права собственности раньше, чем дата заявления.
            AND (own1.A_END_OWN_DATE IS NULL OR CONVERT(DATE, own1.A_END_OWN_DATE) >= @dreg)        --Дата прекращения права собственности позже, чем дата заявления.
        GROUP BY own1.A_OWNER_ID
    ) mo 
        ON mo.A_OWNER_ID = own.A_OWNER_ID   --Связка с недвижимостью.
            AND mo.A_OUID = own.A_OUID      --Связка с недвижимостью.
WHERE own.A_ADDR_ID = @adrrl                                                            --Адрес такой же, как и в документе.
    AND own.A_STATUS = 10                                                               --Статус в БД "Действует".
    AND (own.A_START_OWN_DATE IS NULL OR CONVERT(DATE, own.A_START_OWN_DATE) <= @dreg)  --Дата возникновения права собственности раньше, чем дата заявления.
    AND (own.A_END_OWN_DATE IS NULL OR CONVERT(DATE, own.A_END_OWN_DATE) >= @dreg)      --Дата прекращения права собственности позже, чем дата заявления.

--Подсчет доли.
SELECT @part = SUM(A_PART)
FROM #tmps


--------------------------------------------------------------------------------------------------------------------------------


--Личное дело заявителя.
DECLARE @personalCardId INT
SET @personalCardId = @pcpetl

--Идентификатор заявления.
DECLARE @petitionId INT
SET @petitionId = @pet


--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#REALTY_DOC')     IS NOT NULL BEGIN DROP TABLE #REALTY_DOC    END --Документы о имуществе.
IF OBJECT_ID('tempdb..#REALTY_PART')    IS NOT NULL BEGIN DROP TABLE #REALTY_PART   END --Доли собственности по периодам.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #REALTY_DOC (
    DOC_OUID            INT,    --Идентификатор документа.
    PERSONOUID          INT,    --Идентификатор личного дела владельца недвижимости.
    REALTY_START_DATE   DATE,   --Дата возникновения права собственности.
    REALTY_END_DATE     DATE,   --Дата прекращения права собственности.
    PART                FLOAT,  --Доля.
)
CREATE TABLE #REALTY_PART (
    PERSONOUID          INT,    --Идентификатор личного дела владельца недвижимости.
    REALTY_START_DATE   DATE,       --Дата возникновения права собственности.
    REALTY_END_DATE     DATE,       --Дата прекращения права собственности.
    PART                FLOAT,      --Доля.
    OWNING_TYPE         VARCHAR(10) --Тип собственности.
)

------------------------------------------------------------------------------------------------------------------------------


--Выборка документов о имуществе.
INSERT INTO #REALTY_DOC (DOC_OUID, PERSONOUID, REALTY_START_DATE, REALTY_END_DATE, PART)
SELECT 
    actDocument.OUID                        AS DOC_OUID, 
    realty.A_OWNER_ID                       AS PERSONOUID,
    CONVERT(DATE, realty.A_START_OWN_DATE)  AS REALTY_START_DATE, 
    CONVERT(DATE, realty.A_END_OWN_DATE)    AS REALTY_END_DATE, 
    ISNULL(CASE 
        WHEN ISNULL(realty.A_PARTDENOMPART , 0)<> 0 
            THEN CAST(realty.A_PARTNUMPART AS FLOAT) / CAST(realty.A_PARTDENOMPART  AS FLOAT)
            ELSE realty.A_PART 
        END, 1 
    )   AS PART
FROM SPR_LINK_APPEAL_DOC appeal_doc --Класс связки Обращения-Документы.
----Действующие документы.
    INNER JOIN WM_ACTDOCUMENTS actDocument 
        ON actDocument.OUID = appeal_doc.TOID   --Связка с обращением.
            AND actDocument.A_STATUS = 10       --Статус в БД "Действует".	
            AND actDocument.DOCUMENTSTYPE IN (  --Тип документа.
                3800,   --Свидетельство о государственной регистрации права собственности.
                4017,   --Выписка из единого государственного реестра прав на недвижимое имущество.
                4196    --Документ о регистрации права собственности.
            )		
----Имущество.
    LEFT JOIN WM_OWNING realty 
        ON realty.A_OUID = actDocument.A_ESTATE     --Связка с документом.
            AND realty.A_OWNER_ID = @personalCardId --Связка с личным делом отчета.
WHERE appeal_doc.FROMID =  @petitionId   --Заявление отчета.
   
   
------------------------------------------------------------------------------------------------------------------------------       


--Доли собственности.
INSERT INTO #REALTY_PART (PERSONOUID, REALTY_START_DATE, REALTY_END_DATE, PART, OWNING_TYPE)
SELECT	
    realtyDoc.PERSONOUID,
    realtyDoc.REALTY_START_DATE,
    realtyDoc.REALTY_END_DATE, 
    realtyDoc.PART,
    CASE WHEN EXISTS (
        SELECT 1 
        FROM SPR_LINK_APPEAL_DOC linkDoc 
            INNER JOIN WM_ACTDOCUMENTS docNaim 
                ON docNaim.OUID = linkDoc.TOID 
                    AND docNaim.DOCUMENTSTYPE in (2130,2131,2132) 
        WHERE FROMID = @petitionId
    )   
        THEN 'naim' 
        ELSE 'sobst' 
    END OWNING_TYPE 
FROM WM_PETITION petition --Заявление.
----Класс связки Обращения-Документы.
    INNER JOIN SPR_LINK_APPEAL_DOC appeal_doc 
        ON appeal_doc.FROMID = petition.OUID --Связка с документом.
----Действующие документы.
    INNER JOIN WM_ACTDOCUMENTS actDocument 
        ON actDocument.OUID = appeal_doc.TOID --Связка с заявлением.
----Документы об имуществе.
    LEFT JOIN #REALTY_DOC realtyDoc
        ON realtyDoc.PERSONOUID = actDocument.PERSONOUID   --Связка с личным делом.
WHERE petition.OUID = @petitionId   --Заявление отчета.
    AND actDocument.A_STATUS = 10   --Статус в БД "Действует".
    AND actDocument.DOCUMENTSTYPE IN (
        1796,   --Справка о праве на получение компенсационных выплат в связи с расходами по оплате жилого помещения, коммунальных и других видов услуг (ФЗ "О статусе военнослужащего", ст.24 п.4)
        2067,   --Справка о праве на получение компенсационных выплат в связи с расходами по оплате жилого помещения, коммунальных и др. видов услуг (78-ФЗ ст.2)
        3893,   --Справка о праве на получение компенсационных выплат в связи с расходами по оплате жилого помещения, коммунальных и других видов услуг (247-ФЗ, ст.10 п.1-3, п.5)
        3894    --Справка о праве на получение компенсационных выплат в связи с расходами по оплате жилого помещения, коммунальных и других видов услуг (283-ФЗ, п.1-3)
	)


------------------------------------------------------------------------------------------------------------------------------


--Интерфейс с результатом отчета.
select 
    --p.OUID, 
    --p.A_DATE_REG, 
    realtyPart.REALTY_START_DATE AS d, 
    realtyPart.REALTY_END_DATE AS d2, 
    --isnull(realtyPart.COUNT_PEOPLE, realtyPart.COUNT_BENIFICIARY) as reg,
    NULL AS reg, 
    NULL AS lg,
    case when realtyPart.OWNING_TYPE = 'naim' then 0 else 1 end as fls,
    case
        when realtyPart.OWNING_TYPE = 'naim' then 1
        when isnull(realtyPart.PART, 0) = 0 then 1
        else realtyPart.PART 
    end as part
into #tmppet2
from #REALTY_PART realtyPart


----------------------------------------------------------------------------------------


--Расчет.
select reca.A_PAY as ServicePay, reca.A_NAME_AMOUNT,
	 case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else pet.reg end as qz,
	 case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else pet.lg end as ql,
	case
	 when pet.part = 1 then '1' 
	 else CONVERT(varchar(15), pet.part) 
	end as part,
	s.A_NAME as serviceName,
  ------------------------------------------------------------------------------
    CASE 
        --Старый расчет по долям.
        WHEN CONVERT(DATE, rec.A_PAYMENT_DATE) < CONVERT(DATE, '20200801') THEN CAST (
            CASE
                WHEN A_NAME_AMOUNT IN (68, 69, 70) THEN reca.A_PAY * 0.6
                WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) THEN reca.A_PAY/(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else pet.reg end)*(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else pet.lg end) * 0.6
                WHEN A_NAME_AMOUNT IN (162, 38) AND @fls = 0 THEN reca.A_PAY/(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else pet.reg end)*(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else pet.lg end) * 0.6
                WHEN A_NAME_AMOUNT IN (162, 38) AND @fls = 1 THEN reca.A_PAY * pet.part * 0.6
                ELSE 0
            END AS DECIMAL(10, 4)
        ) 
        --Новый расчет по количеству. 
        ELSE CAST (
	        CASE
                WHEN A_NAME_AMOUNT IN (68, 69, 70) THEN reca.A_PAY * 0.6
                WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392, 162, 38) THEN reca.A_PAY/(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LIVING else pet.reg end)*(case when isnull(rec.A_NUM_LIVING, 0) <> 0 and isnull(rec.A_NUM_LGOTA, 0) <> 0 then rec.A_NUM_LGOTA else pet.lg end) * 0.6
                else 0
            END AS DECIMAL(10, 4))
    END AS result,
    convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) as PAYMENT_DATE, 
    pet.fls,
  ------------------------------------------------------------------------------
    CASE
        WHEN CONVERT(DATE, rec.A_PAYMENT_DATE) < CONVERT(DATE, '20200801') THEN 1
        ELSE 0
    END AS OLD_CALCULATION
  ------------------------------------------------------------------------------
into #tmpr	
from WM_RECEIPT rec
	join #tmppet2 pet on convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) between pet.d and ISNULL(pet.d2, CONVERT(DATE, '29991231'))
	join WM_RECEIPT_AMOUNT reca on reca.A_RECEIPT = rec.A_OUID and reca.A_STATUS = 10 and A_NAME_AMOUNT in (68, 69, 70, 11, 20, 39, 42, 45, 81, 25, 162, 38, 388, 391, 392)
	left outer join SPR_HSC_TYPES s on s.A_STATUS = 10 and s.A_ID = A_NAME_AMOUNT
where rec.A_STATUS = 10 and rec.A_PAYER = @pcpetl and rec.A_ADDR_ID = @adrrl and convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) < convert(date, dateadd("day", 1-DAY(@dreg), @dreg))
	--and (pet.fls = 0 and A_NAME_AMOUNT <> 38 or pet.fls = 1)
	and convert(date, dateadd("day", 1-DAY(rec.A_PAYMENT_DATE), rec.A_PAYMENT_DATE)) between @s1 and @s2


----------------------------------------------------------------------------------------


--Вывод общей информации для отчета.
SELECT 
    CONVERT(VARCHAR, appeal.A_DATE_REG, 104)                                       AS PETITION_DATE,
	RTRIM(
        ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)     + ' ' + 
        ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)        + ' ' + 
        ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) 
	)                                                                               AS FIO,
	@phones                                                                         AS PHONE, 
	address.A_ADRTITLE                                                              AS ADDRESS,
	CONVERT(VARCHAR, @d1, 104)                                                      AS DATE_FROM, 
	ISNULL(CONVERT(VARCHAR, @d2, 104), '')                                          AS DATE_TO,
	@reg                                                                            AS COUNT_PEOPLE, 
	@lg                                                                             AS COUNT_BENIFICIARY,
	ISNULL(@docs, '')                                                               AS DOCUMENT,
    CASE
        WHEN @part = 1 THEN '1' 
        ELSE ISNULL(CONVERT(varchar(15), @part), '')
    END                                                                             AS PART
FROM WM_PETITION petition   --Заявление.
----Обращение.
    INNER JOIN WM_APPEAL_NEW appeal 
        ON appeal.OUID = petition.OUID      --Связка с заявлением.
            AND appeal.A_STATUS = 10        --Статус в БД "Действует".
------Личное дело гражданина.
	INNER JOIN WM_PERSONAL_CARD personalCard 
	    ON personalCard.OUID = appeal.A_PERSONCARD --Связка с обращением.
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME --Связка с личным делом.   
----Адрес. 
	LEFT JOIN WM_ADDRESS address 
	    ON address.OUID = personalCard.A_REGFLAT    --Связка с личным делом.
	        AND address.A_STATUS = 10               --Статус в БД "Действует".
WHERE petition.OUID = @pet --Заявление отчета.


----------------------------------------------------------------------------------------


--Вывод справок о праве.
SELECT
    --Сведения о человеке. 
    spr.relativeFIO                                                 AS FIO, 
    spr.relation                                                    AS RELATION, 
    --Последняя справка о праве.
    spr.ser                                                         AS DOC_SERIES, 
    spr.num                                                         AS DOC_NUMBER, 
    spr.date                                                        AS DOC_BASE_DATE,
    --Информация о собственности.
    CASE
        WHEN realtyPart.PART = 1 THEN '1'
        ELSE ISNULL(CONVERT(VARCHAR, realtyPart.PART), '') 
	END                                                             AS PART,
    CONVERT(VARCHAR, realtyPart.REALTY_START_DATE, 104)             AS REALTY_START_DATE,
    ISNULL(CONVERT(VARCHAR, realtyPart.REALTY_END_DATE, 104), '')   AS REALTY_END_DATE
FROM #tmpspr spr
	LEFT JOIN #REALTY_PART realtyPart ON realtyPart.PERSONOUID = spr.PERSONOUID
ORDER BY realtyPart.REALTY_START_DATE


----------------------------------------------------------------------------------------


--Вывод расчета компенсаций для отчета.
SELECT 
    serviceName         AS SERVICE_NAME, 
    ServicePay          AS PAY, 
  ------------------------------------------------------------------------------
    --Зарегестрировано.
    CASE OLD_CALCULATION
        --Старый расчет по долям.
        WHEN 1 THEN CASE
            WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) THEN CONVERT(VARCHAR(15), qz)
            WHEN A_NAME_AMOUNT = 162 AND fls = 0 THEN CONVERT(VARCHAR(15), qz) --Содержание и ремонт жилого помещения.
            ELSE '-'
        END 
        --Новый расчет по количеству. 
        ELSE CASE
            WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392, 162, 38) THEN CONVERT(VARCHAR(15), qz)
            ELSE '-'
        END  
    END AS COUNT_PEOPLE,
  ------------------------------------------------------------------------------
    --Льготники.
    CASE OLD_CALCULATION
        --Старый расчет по долям.
        WHEN 1 THEN CASE
            WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392) THEN CONVERT(VARCHAR(15), ql)
            WHEN A_NAME_AMOUNT = 162 AND fls = 0 THEN CONVERT(VARCHAR(15), ql) --Содержание и ремонт жилого помещения.
            ELSE '-'
        END
        --Новый расчет по количеству. 
        ELSE CASE
            WHEN A_NAME_AMOUNT IN (11, 20, 39, 42, 45, 81, 25, 388, 391, 392, 162, 38) THEN CONVERT(VARCHAR(15), ql)
            ELSE '-'
        END
    END AS COUNT_BENIFICIARY,
  ------------------------------------------------------------------------------
    --Доля.
    CASE OLD_CALCULATION
        --Старый расчет по долям.
        WHEN 1 THEN CASE 
            WHEN A_NAME_AMOUNT IN (162, 38) AND fls = 1 THEN part  --Содержание и ремонт жилого помещения или Капитальный ремонт.
            ELSE '-' 
        END
        --Новый расчет по количеству.
        ELSE '-'
    END AS PART,
  ------------------------------------------------------------------------------
    ROUND(result, 2) AS RESULT,
    CONVERT(CHAR, PAYMENT_DATE, 104) AS PAYMENT_DATE
FROM #tmpr
ORDER BY #tmpr.PAYMENT_DATE, serviceName
