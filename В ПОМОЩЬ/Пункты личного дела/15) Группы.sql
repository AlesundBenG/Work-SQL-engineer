SELECT 
    personalCard_1.A_TITLE                      AS [Заявитель],
    personalCard_2.A_TITLE                      AS [Член семьи],
    groupRole.A_NAME                            AS [Родственная связь],
    ISNULL(relationship.A_MAINTENANCE, 0)       AS [Иждивение],
    CONVERT(DATE, relationship.A_BEGIN_DATE)    AS [Дата начала действия],
    CONVERT(DATE, relationship.A_END_DATE)      AS [Дата окончания действия],
    esrnStatusRelationship.A_NAME               AS [Статус родственной связи в базе данных]  
FROM WM_RELATEDRELATIONSHIPS relationship --Родственные связи.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusRelationship
        ON esrnStatusRelationship.A_ID = relationship.A_STATUS --Связка с родственными связями.
----Личное дело людей.
    INNER JOIN WM_PERSONAL_CARD personalCard_1
        ON personalCard_1.OUID = relationship.A_ID1 --Связка с родственными связями.
----Личное дело родственника.
    INNER JOIN WM_PERSONAL_CARD personalCard_2
        ON personalCard_2.OUID = relationship.A_ID2 --Связка с родственными связями.
----Тип родсвтенной связи.
    LEFT JOIN SPR_GROUP_ROLE groupRole
        ON groupRole.OUID = relationship.A_RELATED_RELATIONSHIP --Связка с родственными связями.