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
 SET @petitionId = 6514294
--6514261   Мать
--6514276   Дочь
--6514294   Сын

--{params.personalCardId}
DECLARE @personalCardId INT
SET @personalCardId = 1030196 
--1024106 Мать
--1653802 Дочь
--1030196 Сын

--{params.startDate}
DECLARE @startDate DATE
SET @startDate = CONVERT(DATE, '01-06-2021')


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