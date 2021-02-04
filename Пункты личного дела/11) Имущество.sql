SELECT 
    realtyAddress.A_ADRTITLE                AS [Недвижимость],
    personalCard.A_TITLE                    AS [Владелец недвижимости],
    typeOwning.NAME                         AS [Тип собственности],
    CASE
        WHEN ISNULL(realty.A_PARTDENOMPART,0) <> 0 
	        THEN CAST(realty.A_PARTNUMPART AS FLOAT) / CAST(realty.A_PARTDENOMPART AS FLOAT)	
        ELSE realty.A_PART
    END                                     AS [Доля собственности],
    realty.A_TOTAL_AREA                     AS [Общая площадь],
    CONVERT(DATE, realty.A_START_OWN_DATE)  AS [Дата возникновения права собственности],
    CONVERT(DATE, realty.A_END_OWN_DATE)    AS [Дата прекращения права собственности],
    esrnStatusRealty.A_NAME                 AS [Статус личного дела в базе данных] 
FROM WM_OWNING realty --Владельцы недвижимости.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusRealty
        ON esrnStatusRealty.A_ID = realty.A_STATUS --Связка с недвижиостью.
----Адрес недвижимости.
    INNER JOIN WM_ADDRESS realtyAddress
        ON realtyAddress.OUID = realty.A_ADDR_ID --Связка с владельцом недвижимости.
--Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = realty.A_OWNER_ID --Связка с владельцом недвижимости.
----Тип собственности.
    INNER JOIN SPR_OWNINGTYPES typeOwning
        ON typeOwning.OUID = realty.A_OWNING_TYPE --Связка с владельцом недвижимости.