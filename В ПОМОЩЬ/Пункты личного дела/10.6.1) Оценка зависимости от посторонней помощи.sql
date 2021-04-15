SELECT
    CONVERT(DATE, assessmentDependence.A_DATE_INSPECT)          AS [Дата проведения обследования],
    personalCard.A_TITLE                                        AS [Личное дело],
    assessmentDependence.A_DEGREE                               AS [Степень зависимости],
    assessmentDependence.A_SUM_BALS                             AS [Количество баллов],
    CONVERT(DATE, assessmentDependence.A_DATE_NEXT_INSPECTION)  AS [Дата следующего обследования],
    protection.A_NAME                                           AS [Статус блокировки],
    ISNULL(assessmentDependence.A_THERE_INDIVDI_PLANN, 0)       AS [Имеется индивидуальный план ухода],
    ISNULL(assessmentDependence.A_THERE_COMPLEX_PLANN, 0)       AS [Имеется комплексный план ухода],
    moveOutsideHome.A_TITLE                                     AS [Передвижение вне дома],
    apartmentCleaning.A_TITLE                                   AS [Уборка квартиры],
    laundry.A_TITLE                                             AS [Стирка],
    cooking.A_TITLE                                             AS [Приготовление пищи],
    movingHouse.A_TITLE                                         AS [Передвижение по дому],
    falls.A_TITLE                                               AS [Падения в течение последних трех месяцев],
    dressing.A_TITLE                                            AS [Одевание],
    hygiene.A_TITLE                                             AS [Личная гигиена],
    receptionEatMed.A_TITLE                                     AS [Прием пищи и прием лекарств],
    urinationDefecation.A_TITLE                                 AS [Мочеиспускание и дефекация],
    supervision.A_TITLE                                         AS [Присмотр],
    hear.A_TITLE                                                AS [Слух],
    presenceDanger.A_TITLE                                      AS [Наличие опасности в районе проживания или доме],
    support.A_TITLE                                             AS [Наличие внешних ресурсов],
    esrnStatusAssessmentDependence.A_NAME                       AS [Статус оценки зависимости от посторонней помощи в базе данных]  
FROM WM_ASSESSMENT_DEPENDENCE assessmentDependence
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusAssessmentDependence
        ON esrnStatusAssessmentDependence.A_ID = assessmentDependence.A_STATUS
----Личное дело гражданина.
    INNER JOIN WM_PERSONAL_CARD personalCard 
        ON personalCard.OUID = assessmentDependence.PERSONOUID
----Статус блокировки.
    INNER JOIN SPR_PROTECTION protection
        ON protection.A_OUID = assessmentDependence.A_PROTECTION
----Учреждение
    INNER JOIN SPR_ORG_USON organization
        ON organization.OUID = assessmentDependence.A_SPR_ORG_USON
----Оценка зависимости от посторонней помощи.
    LEFT JOIN SXENUM moveOutsideHome
        ON moveOutsideHome.A_ATTR = 11499851 	
            AND moveOutsideHome.A_CODE = assessmentDependence.A_MOVE_OUTSIDE_HOME
    LEFT JOIN SXENUM apartmentCleaning
        ON apartmentCleaning.A_ATTR = 11499858 	
            AND apartmentCleaning.A_CODE = assessmentDependence.A_APARTMENT_CLEANING
    LEFT JOIN SXENUM laundry
        ON laundry.A_ATTR = 11499863 	
            AND laundry.A_CODE = assessmentDependence.A_LAUNDRY
    LEFT JOIN SXENUM cooking
        ON cooking.A_ATTR = 11499867 	
            AND cooking.A_CODE = assessmentDependence.A_COOKING
    LEFT JOIN SXENUM movingHouse
        ON movingHouse.A_ATTR = 11499872 	
            AND movingHouse.A_CODE = assessmentDependence.A_MOVING_HOUSE
    LEFT JOIN SXENUM falls
        ON falls.A_ATTR = 11499880 	
            AND falls.A_CODE = assessmentDependence.A_FALLS
    LEFT JOIN SXENUM dressing
        ON dressing.A_ATTR = 11499886 	
            AND dressing.A_CODE = assessmentDependence.A_DRESSING
    LEFT JOIN SXENUM hygiene
        ON hygiene.A_ATTR = 11499890 	
            AND hygiene.A_CODE = assessmentDependence.A_HYGIENE
    LEFT JOIN SXENUM receptionEatMed
        ON receptionEatMed.A_ATTR = 11499896 	
            AND receptionEatMed.A_CODE = assessmentDependence.A_RECEPTION_EAT_MED
    LEFT JOIN SXENUM urinationDefecation
        ON urinationDefecation.A_ATTR = 11499901 	
            AND urinationDefecation.A_CODE = assessmentDependence.A_URINATION_DEFECATION
    LEFT JOIN SXENUM supervision
        ON supervision.A_ATTR = 11499908 	
            AND supervision.A_CODE = assessmentDependence.A_SUPERVISION
    LEFT JOIN SXENUM hear
        ON hear.A_ATTR = 11499912 	
            AND hear.A_CODE = assessmentDependence.A_HEAR
    LEFT JOIN SXENUM presenceDanger
        ON presenceDanger.A_ATTR = 11499916 	
            AND presenceDanger.A_CODE = assessmentDependence.A_PRESENCE_DANGER
    LEFT JOIN SXENUM support
        ON support.A_ATTR = 11499920 	
            AND support.A_CODE = assessmentDependence.A_SUPPORT