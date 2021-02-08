SELECT 
    typePension.A_NAME                          AS [Вид пенсии],
    CONVERT(DATE, pension.A_PENSION_D_START)    AS [Дата начала предоставления],
    CONVERT(DATE, pension.A_PENSION_D_END)      AS [Дата окончания предоставления],
    pension.SIZE                                AS [Размер пенсии, руб.],
    signWork.A_NAME                             AS [Факт работы],
    pension.A_PRAB_MG                           AS [Месяц, год сведений о работе],
    statusPension.A_NAME                        AS [Статус дела],
    organization.A_NAME1                        AS [Орган пенсионного обеспечения],
    esrnStatusPension.A_NAME                    AS [Статус пенсионных сведений в базе данных]  
FROM WM_PENSION pension --Пенсионные сведения.
----Статус в БД.
    INNER JOIN ESRN_SERV_STATUS esrnStatusPension
        ON esrnStatusPension.A_ID = pension.A_STATUS --Связка с пенсией.
----Статус пенсионного дела.
    INNER JOIN SPR_PENS_STATUS statusPension
        ON statusPension.A_OUID = pension.A_STATUS_NPD --Связка с пенсией.
----Вид пенсии.
    INNER JOIN WM_PENSION_TYPE typePension
        ON typePension.OUID = pension.A_PENSION_TYPE_REF --Связка с пенсией.
----Признак работы.
    LEFT JOIN SPR_WORK signWork
        ON signWork.OUID = pension.A_PRAB --Связка с пенсией.       
----Орган пенсионного обеспечения.
    INNER JOIN SPR_ORG_BASE organization
        ON organization.OUID = pension.A_PENS_ORG --Связка с пенсией.