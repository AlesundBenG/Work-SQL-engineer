/*  Таблица возрастов (#TABLE_AGE):
*       Каждому OUID в таблице WM_PERSONAL_CARD высчитывается возраст относительно определенной даты (@dateForAge), 
        а так же дата следующего дня рождения.
*   Примечания:
*       * Проверка на действительность личных дел не производится.
*       * Если дата рождения NULL, то возраст так же будет NULL.
*/


------------------------------------------------------------------------------------------------------------------------------


--Дата, относительно которой высчитывается возраст.
DECLARE @dateForAge DATE
SET @dateForAge = CONVERT(DATE, GETDATE())


------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#TABLE_AGE') IS NOT NULL BEGIN DROP TABLE #TABLE_AGE END  --Таблица возрастов.


------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #TABLE_AGE (
    PERSONOUID      INT,    --Идентификатор личного дела.  
    AGE             INT,    --Возраст относительно даты @dateForAge.
    NEXT_BIRTHDATE  DATE,   --Дата следующего дня рождения относительно @dateForAge.
)


------------------------------------------------------------------------------------------------------------------------------


--Выборка в таблицу возрастов.
INSERT #TABLE_AGE(PERSONOUID, BIRTHDATE, AGE, NEXT_BIRTHDATE)
SELECT
    personalCard.OUID                       AS PERSONOUID,
    DATEDIFF(YEAR, personalCard.BIRTHDATE, @dateForAge) -                       --Вычисление разницы между годами.									
        CASE                                                                    --Определение, был ли в этом году день рождения.
            WHEN MONTH(personalCard.BIRTHDATE)  < MONTH(@dateForAge)  THEN 0    --День рождения был, и он был не в этом месяце.
            WHEN MONTH(personalCard.BIRTHDATE)  > MONTH(@dateForAge)  THEN 1    --День рождения будет в следущих месяцах.
            WHEN DAY(personalCard.BIRTHDATE)    > DAY(@dateForAge)    THEN 1    --В этом месяце день рождения, но его еще не было.
            ELSE 0                                                              --В этом месяце день рождения, и он уже был.
        END	AS AGE,
    CASE
        WHEN MONTH(personalCard.BIRTHDATE) < MONTH(@dateForAge)																--Месяц даты рождения уже прошел.
            OR (MONTH(personalCard.BIRTHDATE) = MONTH(@dateForAge) AND DAY(personalCard.BIRTHDATE) <= DAY(@dateForAge))	    --Или в текущем месяце день рождения уже прошел.
        THEN DATEADD(YEAR, DATEDIFF(YEAR, personalCard.BIRTHDATE, @dateForAge) + 1, personalCard.BIRTHDATE)					--То следующий день рождения будет в следующем году.
        ELSE DATEADD(YEAR, DATEDIFF(YEAR, personalCard.BIRTHDATE, @dateForAge), personalCard.BIRTHDATE)						--Иначе день рождения будет в этом году.
    END AS NEXT_BIRTHDATE
FROM WM_PERSONAL_CARD personalCard --Личное дело.


------------------------------------------------------------------------------------------------------------------------------



SELECT * FROM #TABLE_AGE