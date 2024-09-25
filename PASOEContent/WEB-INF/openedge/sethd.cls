 
 /*------------------------------------------------------------------------
    File        : sethd
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : nm01
    Created     : Wed Nov 10 03:38:24 BOT 2021
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS sethd: 
    
    DEFINE PUBLIC VARIABLE cToken      AS CHARACTER NO-UNDO.
    
    DEFINE TEMP-TABLE sethd_header NO-UNDO
          FIELD set_no           AS CHARACTER 
          FIELD set_DESCRIPTION  AS CHARACTER 
          FIELD set_base_price   AS DECIMAL .
          
    DEFINE TEMP-TABLE setdt_detail NO-UNDO
          FIELD set_no           AS CHARACTER 
          FIELD item_number      AS CHARACTER 
          FIELD set_qty          AS DECIMAL
          FIELD item_description AS CHARACTER.  
          
    DEFINE TEMP-TABLE LeyDetail NO-UNDO
          FIELD company_code     AS CHARACTER 
          FIELD class_code       AS CHARACTER 
          FIELD item-number      AS CHARACTER 
          FIELD item-description AS CHARACTER 
          FIELD quantity         AS DECIMAL 
          FIELD unit_price       AS DECIMAL.
            
    CONSTRUCTOR PUBLIC sethd():
    END CONSTRUCTOR.
    
    CONSTRUCTOR PUBLIC sethd (INPUT ipcToken AS CHARACTER):
        cToken = ipcToken.
    END CONSTRUCTOR.
    
    METHOD PUBLIC VOID getsetinfo(INPUT ipcCompanyCode AS CHARACTER,
                                  OUTPUT TABLE sethd_header,
                                  OUTPUT TABLE setdt_detail,
                                  OUTPUT TABLE LeyDetail):
         
         DEFINE VARIABLE Listclass_code AS CHARACTER NO-UNDO.   
         DEFINE VARIABLE cntr           AS INTEGER   NO-UNDO.  
         DEFINE VARIABLE lCdescription  AS CHARACTER NO-UNDO.                      
         FOR EACH sethd NO-LOCK:
             CREATE sethd_header.
             ASSIGN sethd_header.set_no          = sethd.set-no
                    //sethd_header.set_DESCRIPTION = REPLACE(sethd.DESCRIPTION,"'","")
                    sethd_header.set_base_price  = sethd.base-price.
            lcDescription = REPLACE(sethd.DESCRIPTION,"'", "").
            lcDescription = REPLACE(lcDescription,'"', '').
            lcDescription = REPLACE(lcDescription,"/", "").
            lcDescription = REPLACE(lcDescription,"\", "").      
             sethd_header.set_DESCRIPTION =  lcDescription.  
         END. 
         FOR EACH setdt NO-LOCK:
             FIND FIRST cinv1 WHERE cinv1.item-number EQ setdt.item-number NO-LOCK NO-ERROR.
             
             CREATE setdt_detail.
             ASSIGN setdt_detail.set_no           = setdt.set-no
                    setdt_detail.item_number      = setdt.item-number 
                    setdt_detail.set_qty          = setdt.QTY.
                    lCdescription                 = IF AVAILABLE CINV1 THEN REPLACE(CINV1.DESCRIPTION,"'", "") ELSE "Not Available".
                    
            lcDescription = REPLACE(lCdescription,"'", "").
            lcDescription = REPLACE(lcDescription,'"', '').
            lcDescription = REPLACE(lcDescription,"/", "").
            lcDescription = REPLACE(lcDescription,"\", "").   
            
            setdt_detail.item_description = lcDescription.
            
         END.                                           
    
         FIND FIRST paramfl WHERE PARAMFL.PARAM-ID = "LEY172-FAMILY" 
                              AND PARAMFL.COMPANY-CODE = ipcCompanyCode 
                              AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.  
          IF AVAILABLE paramfl THEN 
          DO:
              Listclass_code = PARAMFL.PARAM-VALUE1.
              DO cntr = 1 TO NUM-ENTRIES(PARAMFL.PARAM-VALUE1,","):
                  FIND FIRST cinv1 WHERE cinv1.item-number EQ PARAMFL.PARAM-VALUE2 NO-LOCK NO-ERROR.
                  CREATE LeyDetail.
                  ASSIGN LeyDetail.company_code      = ipcCompanyCode
                         LeyDetail.class_code        = ENTRY(cntr,PARAMFL.PARAM-VALUE1)
                         LeyDetail.item-description  = IF AVAILABLE CINV1 THEN REPLACE(CINV1.DESCRIPTION,"'", "") ELSE "Not Available" 
                         LeyDetail.item-number       = PARAMFL.PARAM-VALUE2
                         LeyDetail.quantity          = 1
                         LeyDetail.unit_price        = IF AVAILABLE CINV1 THEN cinv1.ACCTING-COST ELSE 0.
                         
                lcDescription = REPLACE(LeyDetail.item-description,"'", "").
                lcDescription = REPLACE(lcDescription,'"', '').
                lcDescription = REPLACE(lcDescription,"/", "").
                lcDescription = REPLACE(lcDescription,"\", "").    
                LeyDetail.item-description = lcDescription.      
            END.                     
          END.                                                                   
    END. 
    
    
                                       

END CLASS.