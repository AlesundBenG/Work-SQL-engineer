--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#PERSONAL_CARD_DATE_OFF') IS NOT NULL BEGIN DROP TABLE #PERSONAL_CARD_DATE_OFF END --Даты снатия с учетов личных дел.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #PERSONAL_CARD_DATE_OFF (
    OFF_DATE    DATE,   --Дата снятия с учета.
    PERSONOUID  INT,    --Личное дело.
    REASON_OFF  INT,    --Причина снятия с учета (SPR_RES_REMUV).
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка даты снятия с учета личных дел.
INSERT INTO #PERSONAL_CARD_DATE_OFF (OFF_DATE, PERSONOUID, REASON_OFF)
SELECT 
    t.OFF_DATE,
    t.PERSONOUID,
    t.REASON_OFF
FROM (
    SELECT 
        CONVERT(DATE, reasonOff.A_DATE)         AS OFF_DATE,
        personalCard.OUID                       AS PERSONOUID,
        reasonOff.A_NAME                        AS REASON_OFF,
        CONVERT(DATE, reasonOff.A_DATEREPEATIN) AS RETURN_DATE,
        --Для отбора последнего снятия.
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID ORDER BY reasonOff.A_DATE DESC) AS gnum 
    FROM WM_REASON reasonOff --Снятие с учета гражданина.
    ----Таблица связки причин с личными делами.
        INNER JOIN SPR_LINK_PERSON_REASON linkWithPersonalCard
            ON linkWithPersonalCard.TOID = reasonOff.A_OUID
    ----Личное дело гражданина.
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.OUID = linkWithPersonalCard.FROMID
                AND personalCard.A_PCSTATUS IN (3, 4)   --Архивное, либо снятое с учета.
    WHERE reasonOff.A_STATUS = 10                       --Статус в БД "Действует".
) t
WHERE t.gnum = 1                --Последняя запись.
    AND t.RETURN_DATE IS NULL   --Дело еще не было восстановлено.
    
    
------------------------------------------------------------------------------------------------------------------------------


--Проверка.
SELECT * FROM #PERSONAL_CARD_DATE_OFF


------------------------------------------------------------------------------------------------------------------------------