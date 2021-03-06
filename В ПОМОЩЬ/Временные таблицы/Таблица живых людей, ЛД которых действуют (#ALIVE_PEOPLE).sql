/*  Таблица живых людей, личные дела которых действуют (#ALIVE_PEOPLE):
*       Отбираются только те OUID в таблице WM_PERSONAL_CARD, у которых статус личного дела действует,
*       и отсутствует дата смерти.
*/


------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#ALIVE_PEOPLE') IS NOT NULL BEGIN DROP TABLE #ALIVE_PEOPLE END --Таблица живых людей, личные дела которых действуют.


------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #ALIVE_PEOPLE (
    PERSONOUID INT, --Идентификатор личного дела.    
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка действующих личных дел живых людей.
INSERT INTO #ALIVE_PEOPLE (PERSONOUID)
SELECT 
    personalCard.OUID AS PERSONOUID
FROM WM_PERSONAL_CARD personalCard          --Личное дело гражданина.
WHERE personalCard.A_STATUS = 10            --Статус в БД "Действует".
    AND personalCard.A_PCSTATUS = 1         --Действующее личное дело.
    AND personalCard.A_DEATHDATE IS NULL    --Отсутствует дата смерти.
    
    
------------------------------------------------------------------------------------------------------------------------------


--Проверка.
SELECT * FROM #ALIVE_PEOPLE


------------------------------------------------------------------------------------------------------------------------------