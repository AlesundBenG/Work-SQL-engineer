SELECT
    personalCard.OUID                                           AS [Личное дело],
    persCardStatus.A_NAME                                       AS [Статус личного дела],
    ISNULL(personalCard.A_SURNAME_STR,    fioSurname.A_NAME)    AS [Фамилия],
    ISNULL(personalCard.A_NAME_STR,       fioName.A_NAME)       AS [Имя],
    ISNULL(personalCard.A_SECONDNAME_STR, fioSecondname.A_NAME) AS [Отчество],
    gender.A_NAME                                               AS [Пол],
    сountry.A_NAME                                              AS [Гражданство],
    personalCard.A_INN                                          AS [ИНН],
    personalCard.A_SNILS                                        AS [СНИЛС],
    addressReg.A_ADRTITLE                                       AS [Адрес регистрации],
    CONVERT(VARCHAR, personalCard.A_REGFLATDATE, 104)           AS [Дата регистрации],
    addressTempReg.A_ADRTITLE                                   AS [Адрес временной регистрации],
    addressLive.A_ADRTITLE                                      AS [Адрес проживания],        
    ISNULL(countryBirth.A_NAME,             '-')    + ', ' + 
    ISNULL(federalOkrugBirth.A_NAME,        '-')    + ', ' + 
    ISNULL(subjectFederationBirth.A_NAME,   '-')    + ', ' + 
    ISNULL(federationBoroughBirth.A_NAME,   '-')    + ', ' + 
    ISNULL(townBirth.A_NAME,                '-')                AS [Место рождения],
    CONVERT(VARCHAR, personalCard.BIRTHDATE, 104)               AS [Дата рождения],
    DATEDIFF(YEAR,personalCard.BIRTHDATE, GETDATE()) -                                  --Вычисление разницы между годами.									
        CASE                                                                            --Определение, был ли в этом году день рождения.
            WHEN MONTH(personalCard.BIRTHDATE)    < MONTH(GETDATE())  THEN 0            --День рождения был, и он был не в этом месяце.
            WHEN MONTH(personalCard.BIRTHDATE)    > MONTH(GETDATE())  THEN 1            --День рождения будет в следущих месяцах.
            WHEN DAY(personalCard.BIRTHDATE)      > DAY(GETDATE())    THEN 1            --В этом месяце день рождения, но его еще не было.
            ELSE 0                                                                      --В этом месяце день рождения, и он уже был.
        END                                                     AS [Возраст],
    osznDepartament.A_SHORT_TITLE                               AS [ОСЗН владелец],
    esrnStatusPersonalCard.A_NAME                               AS [Статус личного дела в базе данных]  
FROM WM_PERSONAL_CARD personalCard --Личное дело гражданина.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusPersonalCard
        ON esrnStatusPersonalCard.A_ID = personalCard.A_STATUS --Связка с личным делом.
----Статус личного дела.
    INNER JOIN SPR_PC_STATUS persCardStatus
        ON persCardStatus.OUID = personalCard.A_PCSTATUS --Связка с личным делом.
----Фамилия.
    LEFT JOIN SPR_FIO_SURNAME fioSurname
        ON fioSurname.OUID = personalCard.SURNAME --Связка с личным делом.
----Имя.     
    LEFT JOIN SPR_FIO_NAME fioName
        ON fioName.OUID = personalCard.A_NAME --Связка с личным делом.      
----Отчество.   
    LEFT JOIN SPR_FIO_SECONDNAME fioSecondname
        ON fioSecondname.OUID = personalCard.A_SECONDNAME --Связка с личным делом.     
----Пол.       
    INNER JOIN SPR_GENDER gender
        ON gender.OUID = personalCard.A_SEX --Связка с личным делом.
----ОСВЗ владелец.
    LEFT JOIN ESRN_OSZN_DEP osznDepartament
        ON osznDepartament.OUID = personalCard.A_REG_ORGNAME --Связка с личным делом.
----Страна.
    LEFT JOIN SPR_COUNTRY сountry
        ON сountry.OUID = personalCard.A_CITIZENSHIP --Связка с личным делом.
----Адрес регистрации.
    LEFT JOIN WM_ADDRESS addressReg
        ON addressReg.OUID = personalCard.A_REGFLAT --Связка с личным делом.
----Адрес проживания.
    LEFT JOIN WM_ADDRESS addressLive
        ON addressLive.OUID = personalCard.A_LIVEFLAT --Связка с личным делом.
----Адрес временной регистрации.
    LEFT JOIN WM_ADDRESS addressTempReg
        ON addressTempReg.OUID = personalCard.A_TEMPREGFLAT --Связка с личным делом.
----Место рождения.
    LEFT JOIN WM_BIRTHPLACE             placeBirth              ON  placeBirth.OUID             = personalCard.A_PLACEOFBIRTH   --Справочник мест рождений.
    LEFT JOIN SPR_COUNTRY               countryBirth            ON  countryBirth.OUID           = placeBirth.A_COUNTRY          --Справочник стран.
    LEFT JOIN SPR_FEDOKRRUG             federalOkrugBirth       ON  federalOkrugBirth.OUID      = placeBirth.A_FEDOKRUG         --Справочник федеральных округов.
    LEFT JOIN SPR_SUBJFED               subjectFederationBirth  ON  subjectFederationBirth.OUID = placeBirth.A_SUBFED           --Справочник субъектов федерации.
    LEFT JOIN SPR_FEDERATIONBOROUGHT    federationBoroughBirth  ON  federationBoroughBirth.OUID = placeBirth.A_FEDBOROUGH       --Справочник районов субъектов федерации.
    LEFT JOIN SPR_TOWN                  townBirth               ON  townBirth.OUID              = placeBirth.A_TOWN             --Справочник населенных пунктов.


    
    
