-------------------------------------------------------------------------------------------------------------------------------
--Назначение.
DECLARE @socServOUID INT SET @socServOUID = #socServOUID# --Идентификатор назначения.
--Период, за который предоставляются сведения.
DECLARE @yearReport INT SET @yearReport = #yearReport# --Год
DECLARE @monthReport INT SET @monthReport = (SELECT A_CODE FROM SPR_MONTH WHERE A_NAME = '#monthReport#' OR CONVERT(VARCHAR, A_CODE) = '#monthReport#') --Месяц.
--Сведения о предоставленной услуге.
DECLARE @typeServCode INT SET @typeServCode = #typeServCode# --Код услуги (Идентификатор).
-------------------------------------------------------------------------------------------------------------------------------
--Выбор агрегации по услуге.
SELECT 
    @typeServCode   AS SOC_SERV_CODE,
    socServAGR.A_ID AS SOC_SERV_AGR_OUID
FROM ESRN_SOC_SERV socServ --Назначение социального обслуживания.
----Агрегация по социальной услуге.
    INNER JOIN WM_SOC_SERV_AGR socServAGR 
        ON socServAGR.ESRN_SOC_SERV = socServ.OUID 
            AND socServAGR.A_STATUS = 10 --Статус агрегации в БД "Действует".
----Тарифы на социальные услуги.    
    INNER JOIN SPR_TARIF_SOC_SERV socServTarif
        ON socServTarif.A_ID = socServAGR.A_SOC_SERV
            AND socServTarif.A_STATUS = 10 --Статус тарифа в БД "Действует".
----Социальные услуги.
    INNER JOIN SPR_SOC_SERV typeSocServ
        ON typeSocServ.OUID = socServTarif.A_SOC_SERV
            AND typeSocServ.A_STATUS = 10 --Статус социальной услуги в БД "Действует".
            AND typeSocServ.OUID = @typeServCode --Код услуги совпадает с требуемым.
WHERE socServ.A_STATUS = 10 --Статус назначения в БД "Действует".
    AND socServ.OUID = @socServOUID --Требуемое назначение.
-------------------------------------------------------------------------------------------------------------------------------


