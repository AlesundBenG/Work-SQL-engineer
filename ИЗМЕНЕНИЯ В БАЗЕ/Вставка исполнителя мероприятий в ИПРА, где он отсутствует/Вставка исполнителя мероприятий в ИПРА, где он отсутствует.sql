UPDATE socialRehabilitation
SET socialRehabilitation.A_ORG = rehabilitation.A_ORG_SOC_REHAB,
    socialRehabilitation.A_TS = GETDATE()
FROM WM_SOCIAL_REHABILITATION socialRehabilitation --Мероприятие социальной реабилитации.
----Реабилитационные мероприятия по заболеванию.
    INNER JOIN WM_REH_REFERENCE rehabilitation
        ON rehabilitation.OUID = socialRehabilitation.A_REHAB_REF
WHERE socialRehabilitation.A_STATUS = 10    --Статус в БД "Действует".
    AND socialRehabilitation.A_ORG IS NULL  --Отсутствует исполнитель мероприятия 
    AND A_RHB_TYPE <> 17                    --Не социально-средовая реабилитация и абилитация.
    AND socialRehabilitation.A_STATUS_EVENT_IPRA IS NOT NULL    --Есть статус ИПРА.
    AND socialRehabilitation.A_OUID NOT IN (                    --Нет пересекающихся социальных обслуживаний.
        SELECT
            socialRehabilitation.A_OUID
        FROM WM_REH_REFERENCE rehabilitation --Реабилитационные мероприятия по заболеванию.
        ----Мероприятие социальной реабилитации.
            INNER JOIN WM_SOCIAL_REHABILITATION socialRehabilitation
                ON socialRehabilitation.A_REHAB_REF = rehabilitation.OUID
                    AND socialRehabilitation.A_STATUS = 10                  --Статус в БД "Действует".
        ----Назначение социального обслуживания.
            INNER JOIN ESRN_SOC_SERV socServ
                ON socServ.A_PERSONOUID = rehabilitation.A_PERSONOUID 
                    AND socServ.A_STATUS = 10   --Статус в БД "Действует".
        ----Период предоставления МСП.        
            INNER JOIN SPR_SOCSERV_PERIOD period
                ON period.A_SERV = socServ.OUID  
                    AND period.A_STATUS = 10 --Статус в БД "Действует".
                    AND (CONVERT(DATE, period.STARTDATE) BETWEEN CONVERT(DATE, rehabilitation.A_DATE_START) AND CONVERT(DATE, ISNULL(rehabilitation.A_DATE_END, '31-12-3000'))      --Начало лежит в интервале мероприятий.
                        OR CONVERT(DATE, period.A_LASTDATE) BETWEEN CONVERT(DATE, rehabilitation.A_DATE_START) AND CONVERT(DATE, ISNULL(rehabilitation.A_DATE_END, '31-12-3000'))   --Или конец лежит в интервале мероприятий.
                    )
    )
    