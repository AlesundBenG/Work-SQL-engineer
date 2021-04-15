SELECT
    CONVERT(DATE, assessmentDependenceStaz.A_DATE_INSPECT)          AS [Дата проведения обследования],
    personalCard.A_TITLE                                            AS [Личное дело],
    assessmentDependenceStaz.A_DEGREE                               AS [Степень зависимости],
    assessmentDependenceStaz.A_SUM_BALS                             AS [Количество баллов],
    CONVERT(DATE, assessmentDependenceStaz.A_DATE_NEXT_INSPECTION)  AS [Дата следующего обследования],
    protection.A_NAME                                               AS [Статус блокировки],
    ISNULL(assessmentDependenceStaz.A_THERE_INDIVDI_PLANN, 0)       AS [Имеется индивидуальный план ухода],
    ISNULL(assessmentDependenceStaz.A_THERE_COMPLEX_PLANN, 0)       AS [Имеется комплексный план ухода],
    moveOutsideHome.A_TITLE                                         AS [Передвижение вне помещения, предназначенного для проживания],
    apartmentCleaning.A_TITLE                                       AS [Способность выполнять уборку и поддерживать порядок],
    laundry.A_TITLE                                                 AS [Стирка],
    cooking.A_TITLE                                                 AS [Приготовление пищи],
    movingHouse.A_TITLE                                             AS [Передвижение в помещении, предназначенном для проживания], 
    falls.A_TITLE                                                   AS [Падения в течение последних трех месяцев], 
    dressing.A_TITLE                                                AS [Одевание],
    hygiene.A_TITLE                                                 AS [Личная гигиена],
    receptionEatMed.A_TITLE                                         AS [Прием пищи и прием лекарств],
    urinationDefecation.A_TITLE                                     AS [Мочеиспускание и дефекация],   
    supervision.A_TITLE                                             AS [Присмотр],  
    hear.A_TITLE                                                    AS [Слух],
    presenceDanger.A_TITLE                                          AS [Опасное (пагубное поведение). Наличие зависимостей],
    support.A_TITLE                                                 AS [Наличие внешних ресурсов],
    esrnStatusAssessmentDependenceStaz.A_NAME                       AS [Статус оценки зависимости в стационарной форме в базе данных]  
FROM WM_ASSESSMENT_DEPENDENCE_STAZ assessmentDependenceStaz
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusAssessmentDependenceStaz
        ON esrnStatusAssessmentDependenceStaz.A_ID = assessmentDependenceStaz.A_STATUS
----Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = assessmentDependenceStaz.PERSONOUID
----Статус блокировки.
    INNER JOIN SPR_PROTECTION protection
        ON protection.A_OUID = assessmentDependenceStaz.A_PROTECTION
----Учреждение.
    INNER JOIN SPR_ORG_USON organization
        ON organization.OUID = assessmentDependenceStaz.A_SPR_ORG_USON
----Оценка зависимости в стационарной форме.
    LEFT JOIN SXENUM moveOutsideHome
        ON moveOutsideHome.A_ATTR = 11521290 	
            AND moveOutsideHome.A_CODE = assessmentDependenceStaz.A_MOVE_OUTSIDE_HOME
    LEFT JOIN SXENUM apartmentCleaning
        ON apartmentCleaning.A_ATTR = 11521297 	
            AND apartmentCleaning.A_CODE = assessmentDependenceStaz.A_APARTMENT_CLEANING
    LEFT JOIN SXENUM laundry
        ON laundry.A_ATTR = 11521302 	
            AND laundry.A_CODE = assessmentDependenceStaz.A_LAUNDRY  
    LEFT JOIN SXENUM cooking
        ON cooking.A_ATTR = 11521306 	
            AND cooking.A_CODE = assessmentDependenceStaz.A_COOKING
    LEFT JOIN SXENUM movingHouse
        ON movingHouse.A_ATTR = 11521311 	
            AND movingHouse.A_CODE = assessmentDependenceStaz.A_MOVING_HOUSE     
    LEFT JOIN SXENUM falls
        ON falls.A_ATTR = 11521319 	
            AND falls.A_CODE = assessmentDependenceStaz.A_FALLS          
    LEFT JOIN SXENUM dressing
        ON dressing.A_ATTR = 11521325 	
            AND dressing.A_CODE = assessmentDependenceStaz.A_DRESSING
    LEFT JOIN SXENUM hygiene
        ON hygiene.A_ATTR = 11521329 	
            AND hygiene.A_CODE = assessmentDependenceStaz.A_HYGIENE  
    LEFT JOIN SXENUM receptionEatMed
        ON receptionEatMed.A_ATTR = 11521335 	
            AND receptionEatMed.A_CODE = assessmentDependenceStaz.A_RECEPTION_EAT_MED     
    LEFT JOIN SXENUM urinationDefecation
        ON urinationDefecation.A_ATTR = 11521340 	
            AND urinationDefecation.A_CODE = assessmentDependenceStaz.A_URINATION_DEFECATION     
    LEFT JOIN SXENUM supervision
        ON supervision.A_ATTR = 11521347 	
            AND supervision.A_CODE = assessmentDependenceStaz.A_SUPERVISION    
    LEFT JOIN SXENUM hear
        ON hear.A_ATTR = 11521351 	
            AND hear.A_CODE = assessmentDependenceStaz.A_HEAR        
    LEFT JOIN SXENUM presenceDanger
        ON presenceDanger.A_ATTR = 11521355 	
            AND presenceDanger.A_CODE = assessmentDependenceStaz.A_PRESENCE_DANGER          
    LEFT JOIN SXENUM support
        ON support.A_ATTR = 11521359 	
            AND support.A_CODE = assessmentDependenceStaz.A_SUPPORT

            
            
            












