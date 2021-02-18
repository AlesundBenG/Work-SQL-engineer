SELECT
    personalCard.A_TITLE        AS [Личное дело],
    phone.A_TYPE                AS [Тип],
    phone.A_NUMBER              AS [Номер],
    CONVERT(DATE, phone.A_DATE) AS [Дата подключения],
    personalCard.A_TEL_NEED     AS [Требуется установка телефона],
    personalCard.A_EMAIL        AS [Адрес электронной почты]
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.
----Телефон.
    LEFT JOIN WM_PCPHONE phone 
        ON phone.A_PERSCARD = personalCard.OUID --Связка с личным делом.