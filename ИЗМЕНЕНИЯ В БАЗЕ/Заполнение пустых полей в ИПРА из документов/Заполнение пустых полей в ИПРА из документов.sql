--Копирование типа ИПРА из документа.
UPDATE reference
SET reference.A_TYPE_IPRA = actDocuments.A_IPRA
FROM WM_REH_REFERENCE reference
    INNER JOIN WM_ACTDOCUMENTS actDocuments 
        ON actDocuments.OUID = reference.A_IPR
            AND actDocuments.A_STATUS = 10
            AND actDocuments.A_DOCSTATUS = 1
            AND actDocuments.A_IPRA IS NOT NULL
WHERE reference.A_STATUS = 10
    AND reference.A_STATUS_IPRA = 1
    AND reference.A_TYPE_IPRA IS NULL
    
--Копирование номера документа ИПРА из документа.
UPDATE reference
SET reference.A_DOC_NUMBER  = actDocuments.DOCUMENTSNUMBER,
    reference.A_NUMBER_IPRA = actDocuments.DOCUMENTSNUMBER
FROM WM_REH_REFERENCE reference
    INNER JOIN WM_ACTDOCUMENTS actDocuments 
        ON actDocuments.OUID = reference.A_IPR
            AND actDocuments.A_STATUS = 10
            AND actDocuments.A_DOCSTATUS = 1
            AND actDocuments.DOCUMENTSNUMBER IS NOT NULL
WHERE reference.A_STATUS = 10
    AND reference.A_STATUS_IPRA = 1
    AND (reference.A_DOC_NUMBER IS NULL OR reference.A_NUMBER_IPRA IS NULL)
    
--Копирование даты ИПРА из документа.
UPDATE reference
SET reference.A_DATE_IPRA = actDocuments.DOCBASEDATE
FROM WM_REH_REFERENCE reference
    INNER JOIN WM_ACTDOCUMENTS actDocuments 
        ON actDocuments.OUID = reference.A_IPR
            AND actDocuments.A_STATUS = 10
            AND actDocuments.A_DOCSTATUS = 1
            AND actDocuments.DOCBASEDATE IS NOT NULL
WHERE reference.A_STATUS = 10
    AND reference.A_STATUS_IPRA = 1
    AND reference.A_DATE_IPRA IS NULL
    
    