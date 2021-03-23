------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#HUSBAND_AND_WIFE') IS NOT NULL BEGIN DROP TABLE #HUSBAND_AND_WIFE END --Таблица мужей и жен.


------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #HUSBAND_AND_WIFE (
    FAMILY_ID   VARCHAR(36),    --Идентификатор семьи.
    HUSBAND     INT,            --Личное дело мужа.
    WIFE        INT,            --Личное дело жены.
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка мужей и жен.
INSERT INTO #HUSBAND_AND_WIFE (FAMILY_ID, HUSBAND, WIFE)
SELECT 
    NEWID()         AS FAMILY_ID,
    husband.A_ID1   AS HUSBAND,
    wife.A_ID1      AS WIFE
FROM WM_RELATEDRELATIONSHIPS husband --Родственные связи.
----Родственная связь.
    INNER JOIN WM_RELATEDRELATIONSHIPS wife
        ON wife.A_ID1 = husband.A_ID2       --Жена у мужа есть в родственных связях.
            AND husband.A_ID1 = wife.A_ID2  --Муж у жены есть в родственных связях.
WHERE wife.A_STATUS = 10        --Статус в БД "Действует".
    AND husband.A_STATUS = 10   --Статус в БД "Действует".
    AND husband.A_RELATED_RELATIONSHIP = 8  --Является женой по отношению к мужчине.
    AND wife.A_RELATED_RELATIONSHIP = 9     --Является мужом по отношению к женщине.
    
--Мужчины без жен.
INSERT INTO #HUSBAND_AND_WIFE (FAMILY_ID, HUSBAND, WIFE)
SELECT 
    NEWID()             AS FAMILY_ID,
    personalCard.OUID   AS HUSBAND,
    CAST(NULL AS INT)   AS WIFE
FROM WM_PERSONAL_CARD personalCard
WHERE personalCard.A_SEX = 1 --Мужчина.
    AND personalCard.OUID NOT IN (SELECT HUSBAND FROM #HUSBAND_AND_WIFE WHERE HUSBAND IS NOT NULL)   
    
--Женщины без мужей.
INSERT INTO #HUSBAND_AND_WIFE (FAMILY_ID, HUSBAND, WIFE)
SELECT 
    NEWID()             AS FAMILY_ID,
    CAST(NULL AS INT)   AS HUSBAND,
    personalCard.OUID   AS WIFE
FROM WM_PERSONAL_CARD personalCard
WHERE personalCard.A_SEX = 2 --Женщина.
    AND personalCard.OUID NOT IN (SELECT WIFE FROM #HUSBAND_AND_WIFE WHERE WIFE IS NOT NULL)


------------------------------------------------------------------------------------------------------------------------------


--Проверка.
SELECT * FROM #HUSBAND_AND_WIFE


------------------------------------------------------------------------------------------------------------------------------