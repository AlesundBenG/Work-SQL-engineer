--------------------------------------------------------------------------------------------------------------------------------


--Удаление временных таблиц.
IF OBJECT_ID('tempdb..#OSZN_AND_DISTRICT')              IS NOT NULL BEGIN DROP TABLE #OSZN_AND_DISTRICT             END --Соотношение центра и района.
IF OBJECT_ID('tempdb..#REHABILITATION_WITHOUT_OSZN')    IS NOT NULL BEGIN DROP TABLE #REHABILITATION_WITHOUT_OSZN   END --Реабилитационные мероприятия по заболеванию без КЦСОН.
IF OBJECT_ID('tempdb..#UPDATED')                        IS NOT NULL BEGIN DROP TABLE #UPDATED                       END --Измененные записи.


--------------------------------------------------------------------------------------------------------------------------------


--Создание временных таблиц.
CREATE TABLE #OSZN_AND_DISTRICT (
    OSZN_OUID   INT,            --Идентифиатор центра.
    DISTRICT    VARCHAR(100)    --Район.
)
CREATE TABLE #REHABILITATION_WITHOUT_OSZN (
    REHABILITATION_OUID INT,            --Идентификатор реабилитационного мероприятия по заболеванию.
    PERSONOUID          INT,            --Идентификатор личного дела.
    ADDRESS_TITLE       VARCHAR(256),   --Адрес.
    ADDRESS_TYPE        VARCHAR(256),   --Тип адреса.
    ADDRESS_DISTRICT    VARCHAR(256),   --Район адреса.
)
CREATE TABLE #UPDATED (
    REHABILITATION_OUID INT,    --Идентификатор реабилитационного мероприятия по заболеванию.
    OSZN_OUID           INT,    --Идентифиатор центра.
)


------------------------------------------------------------------------------------------------------------------------------


--Связка района и центра.
INSERT INTO #OSZN_AND_DISTRICT(OSZN_OUID, DISTRICT)
SELECT 
    osznDep.OUID                        AS OSZN_OUID,
    ISNULL(fedBorough.A_NAME, 'Киров')  AS DISTRICT
FROM ESRN_OSZN_DEP osznDep
----Класс связки ОСЗ и районов.
    LEFT JOIN SPR_OSZN_FEDBOR osznFedBorough
        ON osznFedBorough.A_FROMID = osznDep.OUID
----Справочник районов субъектов федерации.
    LEFT JOIN SPR_FEDERATIONBOROUGHT fedBorough
        ON fedBorough.OUID = osznFedBorough.A_TOID
WHERE osznDep.OUID IN (
    462893, --КОГАУСО «Кировский городской комплексный центр социального обслуживания населения»
    474101,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Нолинском районе» (г Нолинск)
    474071,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Нолинском районе» (пгт Нема)
    474013,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Нолинском районе» (пгт Суна)
    474086,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Нолинском районе» (пгт Кильмезь)
    474098,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Вятскополянском районе» (г Вятские Поляны)
    474019,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Вятскополянском районе» (г Малмыж)
    474103,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Зуевском районе» (г Зуевка)
    474083,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Зуевском районе» (пгт Фаленки)
    474035,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Кирово-Чепецком районе» (г. Кирово-Чепецк)
    474037,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Кирово-Чепецком районе» (пгт Кумены)
    474057,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Котельничском районе» (г Котельнич)
    474015,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Котельничском районе» (г Орлов)
    474109,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Котельничском районе» (пгт Арбаж)
    474088,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Котельничском районе» (пгт Даровской)
    474005,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Котельничском районе» (пгт Ленинское)
    474011,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Котельничском районе» (пгт Свеча)
    474082,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Омутнинском районе»  (г. Омутнинск)
    474090,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Омутнинском районе» (пгт Афанасьево)
    474045,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Подосиновском районе» (г Луза)
    474069,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Подосиновском районе» (пгт Опарино)
    474067,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Подосиновском районе» (пгт Подосиновец)
    474063,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Слободском районе» (г Белая Холуница)
    474080,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Слободском районе» (г Слободской)
    474041,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Слободском районе» (пгт Нагорск)
    474093,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Советском районе» (пгт Верхошижемье)
    474084,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Советском районе» (г Советск)
    474095,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Советском районе» (пгт Лебяжье)
    474065,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Советском районе» (пгт Пижанка)
    474060,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Унинском районе» (пгт Богородское)
    474049,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Унинском районе» (пгт Уни)
    474030,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Юрьянском районе» (г Мураши)
    474009,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Юрьянском районе» (пгт Юрья)
    477458,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Яранском районе» (г Яранск)
    473991,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Яранском районе» (пгт Кикнур)
    474107,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Яранском районе» (пгт Санчурск)
    474100,	--КОГАУСО «Межрайонный комплексный центр социального обслуживания населения в Яранском районе» (пгт Тужа)
    474092,	--КОГАУСО "Оричевский комплексный центр социального обслуживания населения"
    474047,	--КОГАУСО «Верхнекамский комплексный центр социального обслуживания населения»
    474051	--КОГАУСО «Уржумский комплексный центр социального обслуживания населения»
)


------------------------------------------------------------------------------------------------------------------------------


--Реабилитационные мероприятия по заболеванию без КЦСОН.
INSERT INTO #REHABILITATION_WITHOUT_OSZN (REHABILITATION_OUID, PERSONOUID, ADDRESS_TITLE, ADDRESS_TYPE, ADDRESS_DISTRICT)
SELECT
    t.REHABILITATION_OUID,
    t.PERSONOUID,
    t.ADDRESS_TITLE,
    t.ADDRESS_TYPE,
    ISNULL(t.ADDRESS_DISTRICT, 'Киров') AS ADDRESS_DISTRICT
FROM (
    SELECT
        rehabilitationReference.OUID            AS REHABILITATION_OUID,
        personalCard.OUID                       AS PERSONOUID,
        CASE
            WHEN mseiIPRA.A_G3LIVINGADDRESSVALUE IS NOT NULL AND mseiIPRA.A_G3REGADDRESSVALUE IS NOT NULL
                THEN mseiIPRA.A_G3LIVINGADDRESSVALUE
            WHEN mseiIPRA.A_G3LIVINGADDRESSVALUE IS NOT NULL
                THEN mseiIPRA.A_G3LIVINGADDRESSVALUE
            ELSE  mseiIPRA.A_G3REGADDRESSVALUE 
        END AS ADDRESS_TITLE,
        CASE
            WHEN mseiIPRA.A_G3LIVINGADDRESSVALUE IS NOT NULL AND mseiIPRA.A_G3REGADDRESSVALUE IS NOT NULL
                THEN mseiIPRA.A_G3LIVINGADDRESSTYPEVALUE
            WHEN mseiIPRA.A_G3LIVINGADDRESSVALUE IS NOT NULL
                THEN mseiIPRA.A_G3LIVINGADDRESSTYPEVALUE
            ELSE mseiIPRA.A_G3REGADDRESSTYPEVALUE 
        END AS ADDRESS_TYPE,
        CASE
            WHEN mseiIPRA.A_G3LIVINGADDRESSVALUE IS NOT NULL AND mseiIPRA.A_G3REGADDRESSVALUE IS NOT NULL
                THEN mseiIPRA.A_G3LIVINGADDRESSDISTRICT
            WHEN mseiIPRA.A_G3LIVINGADDRESSVALUE IS NOT NULL
                THEN mseiIPRA.A_G3LIVINGADDRESSDISTRICT
            ELSE mseiIPRA.A_G3REGADDRESSDISTRICT
        END AS ADDRESS_DISTRICT,
        --Для отбора последней ИПРЫ.
        ROW_NUMBER() OVER (PARTITION BY personalCard.OUID ORDER BY mseiIPRA.A_ISSUEDATE DESC) AS gnum 
    FROM WM_REH_REFERENCE rehabilitationReference   --Реабилитационные мероприятия по заболеванию.
    ----Личное дело гражданина.
        INNER JOIN WM_PERSONAL_CARD personalCard 
            ON personalCard.OUID = rehabilitationReference.A_PERSONOUID
    ----ИПРА (XML МСЭ)
        INNER JOIN MSEI_IPRA mseiIPRA
            ON mseiIPRA.A_REAL_PC = personalCard.OUID
    WHERE rehabilitationReference.A_STATUS = 10             --Статус в БД "Действует".
        AND rehabilitationReference.A_STATUS_IPRA = 1       --Статус ИПРА "Действует".
        AND rehabilitationReference.A_ORG_SOC_REHAB IS NULL --КЦСОН пустой.
        AND (mseiIPRA.A_G3LIVINGADDRESSVALUE IS NOT NULL    --Есть адрес в ИПРА.
            OR mseiIPRA.A_G3REGADDRESSVALUE IS NOT NULL
        )
) t
WHERE t.gnum = 1


------------------------------------------------------------------------------------------------------------------------------


--Обновление.
UPDATE rehabilitationReference
SET rehabilitationReference.A_ORG_SOC_REHAB = oszn.OSZN_OUID
OUTPUT inserted.OUID, Deleted.A_ORG_SOC_REHAB INTO #UPDATED(REHABILITATION_OUID, OSZN_OUID)   --Сохранение во временную таблицу измененных записей.
FROM WM_REH_REFERENCE rehabilitationReference   --Реабилитационные мероприятия по заболеванию.
    INNER JOIN #REHABILITATION_WITHOUT_OSZN rehabilitation
        ON rehabilitation.REHABILITATION_OUID = rehabilitationReference.OUID
    INNER JOIN #OSZN_AND_DISTRICT oszn
        ON CHARINDEX(oszn.DISTRICT, rehabilitation.ADDRESS_DISTRICT) > 0
            AND (rehabilitation.ADDRESS_DISTRICT = 'Кирово-Чепецкий р-н' AND oszn.OSZN_OUID <> 462893 --Киров является подстрокой Кирово-Чепецка.
                OR rehabilitation.ADDRESS_DISTRICT <> 'Кирово-Чепецкий р-н' AND oszn.OSZN_OUID <> 474035
            )


------------------------------------------------------------------------------------------------------------------------------


--Сохранение измененных.
INSERT INTO TEMPORARY_TABLE (VARCHAR_1, VARCHAR_2, VARCHAR_10)
SELECT 
    CONVERT(VARCHAR(256), REHABILITATION_OUID)              AS VARCHAR_1,
    CONVERT(VARCHAR(256), OSZN_OUID)                        AS VARCHAR_2,
    'Реабилитационные мероприятия по заболеванию без КЦСОН' AS VARCHAR_10
FROM #UPDATED


------------------------------------------------------------------------------------------------------------------------------


SELECT * FROM #UPDATED
