--/////////////////////////////////////////////////////////////////////////////////////////////////////
--Стоит не корректный статус в БД.
SELECT 
    personalCard.OUID           AS PERSONOUID,
    personalCard.TS             AS TS,
    'Не корректный статус в БД' AS REASON,
    personalCard.A_STATUS       AS STATUS
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.
----Статус в БД.
    LEFT JOIN ESRN_SERV_STATUS esrnStatusPersonalCard
        ON esrnStatusPersonalCard.A_ID = personalCard.A_STATUS --Связка с личным делом.
WHERE esrnStatusPersonalCard.A_ID IS NULL
--/////////////////////////////////////////////////////////////////////////////////////////////////////
--Стоит не корректный статус личного дела.
SELECT 
    personalCard.OUID                   AS PERSONOUID,
    personalCard.TS                     AS TS,
    personalCard.A_STATUS               AS STATUS,
    'Не корректный статус личного дела' AS REASON,
    personalCard.A_PCSTATUS             AS PC_STATUS
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.
----Статус личного дела.
    LEFT JOIN SPR_PC_STATUS persCardStatus
        ON persCardStatus.OUID = personalCard.A_PCSTATUS --Связка с личным делом.
WHERE persCardStatus.OUID IS NULL
--/////////////////////////////////////////////////////////////////////////////////////////////////////
--Стоит не корректный пол.
SELECT 
    personalCard.OUID       AS PERSONOUID,
    personalCard.TS         AS TS,
    personalCard.A_STATUS   AS STATUS,
    'Не корректный пол'     AS REASON,
    personalCard.A_SEX      AS SEX
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.
----Пол.       
    LEFT JOIN SPR_GENDER gender
        ON gender.OUID = personalCard.A_SEX --Связка с личным делом.
WHERE gender.OUID IS NULL
--/////////////////////////////////////////////////////////////////////////////////////////////////////