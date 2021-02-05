SELECT 
    personalCard.A_TITLE            AS [Заявитель],
    invalidGroup.A_NAME             AS [Группа инвалидности],	
    invalidReason.A_NAME            AS [Причина инвалидности],
    healthPicture.A_STARTDATA       AS [Дата начала действия],
    healthPicture.A_ENDDATA         AS [Дата окончания действия],
    healthPicture.A_REMOVING_DATE   AS [Дата снятия инвалидности],
    healthPicture.A_DATE_NEXT       AS [Дата переосвидетельствования],
    esrnStatusHealth.A_NAME         AS [Статус состояния здоровья в базе данных]  
FROM WM_HEALTHPICTURE healthPicture --Состояние здоровья.
-----Статус в БД.
     INNER JOIN ESRN_SERV_STATUS esrnStatusHealth
        ON esrnStatusHealth.A_ID = healthPicture.A_STATUS --Связка с документом.
----Личное дело.
    INNER JOIN WM_PERSONAL_CARD personalCard	
        ON personalCard.OUID = healthPicture.A_PERS --Связка с состоянием здоровья.	
----Справочник групп инвалидности.	
    INNER JOIN SPR_INVALIDGROUP invalidGroup 
        ON invalidGroup.OUID = healthPicture.A_INVALID_GROUP --Связка с состоянием здоровья.
--Причины инвалидности.	
    INNER JOIN SPR_INVALIDREASON invalidReason	
        ON invalidReason.OUID = healthPicture.A_INV_REAS --Связка с состоянием здоровья.			
	
