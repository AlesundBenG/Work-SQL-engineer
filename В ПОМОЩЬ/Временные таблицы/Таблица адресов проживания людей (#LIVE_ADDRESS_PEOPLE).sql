/*  Таблица адресов проживания людей (#LIVE_ADDRESS_PEOPLE):
*       Каждому OUID в таблице WM_PERSONAL_CARD определяется адрес проживания.
*       Адреса выбираются в приоритете: 1. Адрес проживания. 2. Адрес временной регистрации. 3. Адрес регистрации.
*   Примечания:
*       * Проверка на действительность личных дел не производится.
*       * Если нет ни одного адреса в деле, то адрес будет NULL.
*/


------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#LIVE_ADDRESS_PEOPLE') IS NOT NULL BEGIN DROP TABLE #LIVE_ADDRESS_PEOPLE END --Адреса проживания людей.


------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #LIVE_ADDRESS_PEOPLE (
    PERSONOUID      INT,    --Идентификатор личного дела.    
    ADDRESS_OUID    INT,    --Идентификатор адреса.
    ADDRESS_TYPE    INT,    --Тип адреса (0 - Нет; 1 - Адрес проживания; 2 - Адрес временной регистрации; 3 - Адрес регистрации).
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка адресов проживания.
INSERT INTO #LIVE_ADDRESS_PEOPLE (PERSONOUID, ADDRESS_OUID, ADDRESS_TYPE)
SELECT 
    personalCard.OUID                                               AS PERSONOUID,
    CASE
        WHEN addressLive.OUID   IS NOT NULL THEN addressLive.OUID
        WHEN addressTemp.OUID   IS NOT NULL THEN addressTemp.OUID
        WHEN addressReg.OUID    IS NOT NULL THEN addressReg.OUID 
        ELSE CAST(NULL AS INT)
    END                                                             AS ADDRESS_OUID,
    CASE
        WHEN addressLive.OUID   IS NOT NULL THEN 1
        WHEN addressTemp.OUID   IS NOT NULL THEN 2
        WHEN addressReg.OUID    IS NOT NULL THEN 3
        ELSE 0
    END                                                             AS ADDRESS_TYPE
FROM WM_PERSONAL_CARD personalCard  --Личное дело гражданина.
----Адрес регистрации. 
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT --Связка с личным делом. 
----Адрес проживания.
    LEFT JOIN WM_ADDRESS addressLive
        ON addressLive.OUID = personalCard.A_LIVEFLAT --Связка с личным делом. 
----Адрес врменной регистрации.
    LEFT JOIN WM_ADDRESS addressTemp
        ON addressTemp.OUID = personalCard.A_TEMPREGFLAT --Связка с личным делом. 


------------------------------------------------------------------------------------------------------------------------------


--Проверка.
SELECT * FROM #LIVE_ADDRESS_PEOPLE


------------------------------------------------------------------------------------------------------------------------------