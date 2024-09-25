 
 /*------------------------------------------------------------------------
    File        : ProductPrices
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : jkt-1
    Created     : Mon May 28 07:42:40 BOT 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProductPrices: 
 
  /*------------------------------------------------------------------------------
   Purpose: It calculates the prices of items. 
   Notes: It is replica of the program, D:\CDIPREMIUM-JKT\oeprice20180613.p
          which was suggested by Hugo in call on dated 06-13-2018.
  ------------------------------------------------------------------------------*/
  
    
  CONSTRUCTOR PUBLIC ProductPrices (  ):   
    
   /*DEFINE VARIABLE SELLING-PRC  AS DECIMAL NO-UNDO.
   DEFINE VARIABLE BASE-PRC     AS DECIMAL NO-UNDO.
   
   FIND FIRST CCSMS WHERE CUST-NUMBER EQ "n00075" NO-LOCK NO-ERROR.
   
   THIS-OBJECT:getProductPrices(INPUT '0',
                                INPUT CCSMS.CUST-NUMBER,
                                INPUT "N94034",
                                INPUT YES,
                                INPUT CCSMS.DISC-PERC, 
                                OUTPUT SELLING-PRC,
                                OUTPUT BASE-PRC,
                                INPUT  "", /* ship-no   */
                                INPUT  0, /* QTY-FULL  */ 
                                INPUT 0, /* QTY-UNIT  */
                                INPUT CCSMS.PRICE-LIST,
                                INPUT "n").
    
    /* qty-full in existing application is cart qty multiplied by 100 
       QTY-UNIT  is populated as 0 */       
       
    
    */                                                                                                 
    
  END CONSTRUCTOR.
  
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC ProductPrices (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
  END CONSTRUCTOR.
    /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID FIND-PARAMFL(INPUT P-PARAM-ID AS CHARACTER,
                                  INPUT COMPANY    AS CHARACTER):
      
    FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = COMPANY
                   AND PARAMFL.PARAM-ID     = P-PARAM-ID
                   AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
    RETURN.

  END METHOD.


  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID getProductPrices(INPUT ipcLangID    AS CHARACTER,
                                      INPUT CUST-NUMBER  AS CHARACTER,
                                      INPUT ITEM-NUMBER  AS CHARACTER,
                                      INPUT LOOKUP-LIST  AS LOGICAL,
                                      INPUT PERCENT      AS DECIMAL, 
                                      OUTPUT SELLING-PRC AS DECIMAL,
                                      OUTPUT BASE-PRC    AS DECIMAL,
                                      INPUT  SHIP-NO     AS CHARACTER,
                                      INPUT  QTY-FULL    AS INTEGER,
                                      INPUT QTY-UNIT     AS INTEGER,
                                      INPUT p-list       AS CHARACTER,
                                      INPUT COMPANY      AS CHARACTER):
    
    DEFINE VARIABLE objCommonSrc    AS CLASS CommonSource  NO-UNDO.
    DEFINE VARIABLE cError          AS CHARACTER           NO-UNDO.
    DEFINE VARIABLE opiStatusCode   AS INTEGER             NO-UNDO.
    
    DEFINE VARIABLE TMP-SPEC-DICT-I LIKE CCSMS.SPEC-DICT-I      NO-UNDO.    
    DEFINE VARIABLE TMP-CUST-TYPE   LIKE CCSMS.CUST-TYPE        NO-UNDO.     
     
    DEFINE VARIABLE used-cost       AS DECIMAL                  NO-UNDO.
    DEFINE VARIABLE BLANK-LIST      AS LOGICAL                  NO-UNDO.
    
    DEFINE VARIABLE contract-ind    LIKE ccsms.contract-ind     NO-UNDO.
    DEFINE VARIABLE price-list      LIKE ccsms.price-list       NO-UNDO.
    DEFINE VARIABLE spec-dict-i     LIKE ccsms.spec-dict-i      NO-UNDO.
    DEFINE VARIABLE disc-perc       LIKE ccsms.disc-perc        NO-UNDO.
    DEFINE VARIABLE qty-brk-cd      LIKE ccsms.qty-brk-cd       NO-UNDO.
     
    DEFINE VARIABLE USE-SLSMN-COST  AS LOGICAL                  NO-UNDO.    
    
    objCommonSrc  = NEW CommonSource(INPUT cToken).
    
    /*** 07/02/2016 wam start Nunez ***/ 
    DEF VAR msg-sin-parar AS LOG NO-UNDO.
    ASSIGN msg-sin-parar = NO.
    IF item-number MATCHES "*|*" THEN 
        ASSIGN 
        item-number = ENTRY(1,item-number,"|")
        msg-sin-parar = YES.
 
    /*** 07/02/2016 wam end Nunez ***/ 
    
    DEF VAR cclist          AS LOGICAL                  NO-UNDO. /* 06/08/2016 nunez*/ 
 
    /*20170809 mfa berrios*/     
    DEF VAR oeprecio-use-cost AS LOGICAL                  NO-UNDO.    /*20170809 mfa*/          
    DEF VAR cost-to-use       AS CHAR                     NO-UNDO.
    /*20170809 mfa berrios*/     
     
     /*20160628 MFA NUNEZ*/ 
    DEF VAR PARAM-ROUND     AS LOGICAL                  NO-UNDO. 
    DEF VAR V-POS           AS INTEGER                  NO-UNDO.
    /*20160628 MFA NUNEZ*/ 
     
    /*20180529 MFA TOLEDO COMO NO TIENE LIBRARY SE FUERZA LA
    VARIABLE*/
    
    COMPANY = SUBSTRING(CUST-NUMBER,1,1).
     
    /*****----------------------------------------------*****/
    /* DEFINE BUFFERS                                       */
    /*****----------------------------------------------*****/
    DEF  BUFFER b-cinv1 FOR cinv1. /*2017-731 mfa*/
     
    /*****----------------------------------------------*****/
    /* P R O C - P A R A M S                                */
    /* READ ALL PARAMFL   PARAMETROS                        */
    /*****----------------------------------------------*****/
        
    FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = COMPANY
                   AND PARAMFL.PARAM-ID     = "oeprecio-use-cost"
                   AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.  
    /*20170809 mfa Berrios. Validar que costo desean utilizar*/     
    
    oeprecio-use-cost = AVAILABLE paramfl.
    IF oeprecio-use-cost  THEN
       ASSIGN cost-to-use = paramfl.param-value1.
    
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     = "BLANK-LIST":U
                   AND PARAMFL.COMPANY-CODE = COMPANY 
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    IF AVAILABLE PARAMFL THEN 
       BLANK-LIST = YES. 
    ELSE 
       BLANK-LIST = NO.
         
    /********************************************************/
    /* use salesman cost for price calculations             */
    /********************************************************/
    
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "PRICE-USE-SLSMN-COST":U 
                   AND PARAMFL.COMPANY-CODE EQ COMPANY 
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    ASSIGN USE-SLSMN-COST = AVAILABLE PARAMFL.
    
    /********************************************************/
    /* para redondear a x posiciones  20160628 MFA          */
    /********************************************************/
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     = "PARAM-ROUND" 
                   AND PARAMFL.COMPANY-CODE = COMPANY 
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    ASSIGN PARAM-ROUND = AVAILABLE PARAMFL.
    IF PARAM-ROUND THEN
       V-POS = INTEGER(PARAMFL.PARAM-VALUE1).
       
    /*******************************************************06/08/2016 nunez*/
    FIND cdi.PARAMFL WHERE PARAMFL.PARAM-ID     = "cclist"   
                       AND PARAMFL.COMPANY-CODE = COMPANY
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    cclist = AVAILABLE PARAMFL.
    /*******************************************************06/08/2016 nunez*/
     
    FIND FIRST CINV1 WHERE CINV1.ITEM-NUMBER = ITEM-NUMBER NO-LOCK NO-ERROR.
     
    FIND CCSMS WHERE CCSMS.CUST-NUMBER = CUST-NUMBER NO-LOCK NO-ERROR.
    IF AVAILABLE ccsms  THEN
      ASSIGN 
       contract-ind     = ccsms.contract-ind
       price-list       = p-list 
       spec-dict-i      = ccsms.spec-dict-i
       disc-perc        = ccsms.disc-perc
       qty-brk-cd       = ccsms.qty-brk-cd
       TMP-SPEC-DICT-I  = CCSMS.SPEC-DICT-I        
       TMP-CUST-TYPE    = CCSMS.CUST-TYPE .         
    
    ELSE
      ASSIGN 
       contract-ind     = "":U
       price-list       = cust-number
       spec-dict-i      = "":U
       disc-perc        = 0
       qty-brk-cd       = "":U
       TMP-SPEC-DICT-I  = " ":U        
       TMP-CUST-TYPE    = " ":U.     
       
    IF cclist THEN   /*06/08/2016 nunez*/
      ASSIGN price-list = p-list.   
     
    FIND FIRST SETHD USE-INDEX SETHD-KEY WHERE SETHD.SET-NO = ITEM-NUMBER NO-LOCK NO-ERROR.
    
    IF AVAILABLE SETHD THEN                       
    DO:
     
        /*20170731 mfa bERRIOS PARA BUSCAR EL PRECIO DEL SET*/
        /*used-cost = qty-unit / 100.*/
        FOR EACH setdt WHERE setdt.set-no = SETHD.SET-NO NO-LOCK:
     
            FIND b-cinv1 WHERE b-cinv1.item-number = setdt.item-number 
            NO-LOCK NO-ERROR.
               IF AVAILABLE b-cinv1 THEN
               DO:  
                   IF oeprecio-use-cost THEN
                      DO:
                          CASE cost-to-use:
                              WHEN "ACCTING-COST" THEN
                                 used-cost =  used-cost + (setdt.QTY * b-cinv1.accting-cost).
                              WHEN "LANDED-COST" THEN
                                 used-cost =  used-cost + (setdt.QTY * b-cinv1.landed-cost).
                              WHEN "HIGHEST" THEN 
                                 DO:
                                     IF cinv1.accting-cost > cinv1.landed-cost THEN
                                        used-cost =  used-cost + (setdt.QTY * b-cinv1.accting-cost).
                                     ELSE
                                        used-cost =  used-cost + (setdt.QTY * b-cinv1.landed-cost).
                                 END.
                               WHEN "LOWEST" THEN 
                                 DO:
                                     IF cinv1.accting-cost < cinv1.landed-cost THEN
                                        used-cost =  used-cost + (setdt.QTY * b-cinv1.accting-cost).
                                     ELSE
                                        used-cost =  used-cost + (setdt.QTY * b-cinv1.landed-cost).
                                 END.
     
                          END CASE.
                      END.
                   ELSE
                      DO:
                          IF b-cinv1.accting-cost > b-cinv1.landed-cost THEN
                             used-cost =  used-cost + (setdt.QTY * b-cinv1.accting-cost).
                          ELSE
                            used-cost =  used-cost + (setdt.QTY * b-cinv1.landed-cost).
                      END.
     
     
     
               END.
        END. /*20170731 mfa bERRIOS PARA BUSCAR EL PRECIO DEL SET*/
    END. /* IF AVAILABLE SETHD THEN */
    
    ELSE
    DO: /*20170809 MFA BERRIOS PARA DEFINIR QUE COSTO
            SE DESEA USAR
           */
     IF  oeprecio-use-cost THEN
     DO:
            CASE cost-to-use:
                WHEN "ACCTING-COST" THEN
                   used-cost = cinv1.accting-cost. 
                WHEN "LANDED-COST" THEN
                   used-cost = cinv1.landed-cost. 
                WHEN "HIGHEST" THEN 
                DO:
                       IF cinv1.accting-cost > cinv1.landed-cost THEN
                         used-cost = cinv1.accting-cost. 
                       ELSE
                         used-cost = cinv1.landed-cost.
                END.
                
                WHEN "LOWEST" THEN 
                DO:
                             IF cinv1.accting-cost < cinv1.landed-cost THEN
                                used-cost = cinv1.accting-cost. 
                             ELSE
                                used-cost = cinv1.landed-cost.
                END.
     
            END CASE.
     END. /* IF  oeprecio-use-cost THEN */
     
     ELSE
     DO: 
       IF cinv1.accting-cost > cinv1.landed-cost THEN
         used-cost = cinv1.accting-cost.
       ELSE
         used-cost = cinv1.landed-cost.
     END. /* ELSE */
     
    END. /* ELSE  */
    
    /* Commented as per the latest code  
    IF AVAILABLE SETHD THEN 
       used-cost = qty-unit / 100.
    ELSE
       IF cinv1.accting-cost > cinv1.landed-cost THEN
          used-cost = cinv1.accting-cost.
       ELSE
          used-cost = cinv1.landed-cost.
    */
    
    /* en garcia freight-pct tiene el trade-cost de ford*/
    IF blank-list AND cinv1.freight-pct > 0  THEN 
      ASSIGN USED-COST = CINV1.FREIGHT-PCT.
     
   
    IF USE-SLSMN-COST THEN   
      ASSIGN USED-COST = CINV1.SLSMN-COST.
     
    ASSIGN SELLING-PRC = CINV1.BASE-PRICE.
      
    IF LOOKUP-LIST THEN
    DO:
        IF CONTRACT-IND = "S":U AND 
           CAN-FIND (CINV3 WHERE CINV3.ITEM-NUMBER EQ ITEM-NUMBER
                             AND CINV3.PRICE-LIST  EQ "S":U) THEN
        DO:
            FIND CINV3 WHERE CINV3.ITEM-NUMBER  EQ ITEM-NUMBER
                         AND CINV3.PRICE-LIST   EQ "S":U NO-LOCK NO-ERROR.
            IF AVAILABLE CINV3 THEN
              ASSIGN 
                SELLING-PRC = CINV3.BREAK-PRICE
                BASE-PRC    = SELLING-PRC.
                             
              
        END. /* IF CONTRACT-IND = "S" AND CAN-FIND */
        
        ELSE
        DO:
            IF PRICE-LIST <> " " OR BLANK-LIST THEN
            DO:
            
                FIND CINV3 WHERE CINV3.ITEM-NUMBER EQ ITEM-NUMBER
                             AND CINV3.PRICE-LIST  EQ ccsms.cust-number NO-LOCK NO-ERROR.
                
                IF AVAILABLE cinv3 THEN     /*11/29/2016 nunez*/
                  ASSIGN p-list = cinv3.price-list. 
     
                IF NOT AVAILABLE CINV3 THEN
                FIND CINV3 WHERE CINV3.ITEM-NUMBER EQ ITEM-NUMBER
                             AND CINV3.PRICE-LIST  EQ PRICE-LIST NO-LOCK NO-ERROR.
     
                IF NOT AVAILABLE CINV3 AND (CONTRACT-IND = "E"  OR CONTRACT-IND = "A") THEN
                DO:
                    ASSIGN LOOKUP-LIST = NO.
                    
                    IF msg-sin-parar = NO THEN  /* 07/02/2016 wam Nunez */
                    DO:
                    /*MESSAGE 
                    "PRODUCT NOT ON CONTRACT" 
                       ITEM-NUMBER
                       VIEW-AS ALERT-BOX
                       TITLE "(oeprice)".*/
                      UNDO, RETRY.
                    END.
                    /*ELSE
                      MESSAGE  "PRODUCT NOT ON CONTRACT(oeprice) "
                      ITEM-NUMBER.*/
                    
                    /* Give message product not on contract */                    
                    objCommonSrc:getMessages(INPUT  ipcLangID,
                                             INPUT  ConstantInitializer:c200ProductNotOnContract,                                                              
                                             OUTPUT cError,
                                             OUTPUT opiStatusCode).
                                                  
                    IF cError NE "":U THEN 
                      UNDO,THROW NEW AppError(cError,1).
                                                              
                END. /* IF NOT AVAILABLE CINV3..  */
     
                IF AVAILABLE CINV3                                AND 
                   CONTRACT-IND = "E":U                           AND  
                   SHIP-NO <> " ":U                               AND  
                   CINV3.PRC-BREAK-ID <> " ":U                    AND 
                   ((SUBSTRING(CINV3.PRC-BREAK-ID,1,3) = "NOT":U  AND 
                    SUBSTRING(CINV3.PRC-BREAK-ID,5) = SHIP-NO)    OR 
                   (SUBSTRING(CINV3.PRC-BREAK-ID,1,3) <> "NOT":U  AND 
                    CINV3.PRC-BREAK-ID <> SHIP-NO))               THEN
                DO:
                    ASSIGN LOOKUP-LIST = NO.
                    
                    /* Give message "Product not on contract for that Ship To" */                    
                    objCommonSrc:getMessages(INPUT  ipcLangID,
                                             INPUT  ConstantInitializer:c200ProductNotOnContractShpTo,                                                              
                                             OUTPUT cError,
                                             OUTPUT opiStatusCode).
                                                  
                    IF cError NE "":U THEN 
                      UNDO,THROW NEW AppError(cError,1).    
                    
                END.
                
                /********************************************************/
                /* CHECK FOR RECORD BY CLASS CODE                       */
                /********************************************************/
                
                IF NOT AVAILABLE cinv3 THEN 
                   FIND CINV3 WHERE CINV3.ITEM-NUMBER  EQ cinv1.class-code 
                                AND CINV3.PRICE-LIST   EQ PRICE-LIST 
                                AND cinv3.PRC-BREAK-ID EQ "C":U NO-LOCK NO-ERROR.
     
                IF NOT AVAILABLE cinv3 THEN 
                   FIND CINV3 WHERE CINV3.ITEM-NUMBER  EQ cinv1.class-code 
                                AND CINV3.PRICE-LIST   EQ PRICE-LIST 
                                AND cinv3.PRC-BREAK-ID EQ "F":U NO-LOCK NO-ERROR.
     
                IF NOT AVAILABLE cinv3 THEN 
                   FIND CINV3 WHERE CINV3.ITEM-NUMBER  EQ cinv1.class-code 
                                AND CINV3.PRICE-LIST   EQ PRICE-LIST 
                                AND cinv3.PRC-BREAK-ID EQ "%":U NO-LOCK NO-ERROR.
     
                
                /********************************************************/
                /* RECORD TO APPLY MARK UP PERCENT TO THE COST          */
                /********************************************************/
                
                IF NOT AVAILABLE cinv3 THEN 
                   FIND CINV3 WHERE CINV3.ITEM-NUMBER  EQ cinv1.class-code 
                                AND CINV3.PRICE-LIST   EQ PRICE-LIST 
                                AND cinv3.PRC-BREAK-ID EQ "M":U NO-LOCK NO-ERROR.
     
                            /*20180525 MFA TOLEDO*/
                            
            /********************************************************/
            /* RECORD TO APPLY MARK UP PERCENT TO THE VENDOR COST   */
            /* CAMBIO DE TOLEDO                                     */
            /********************************************************/
              IF NOT AVAILABLE cinv3 THEN 
                 FIND CINV3 WHERE CINV3.ITEM-NUMBER = cinv1.class-code 
                              AND CINV3.PRICE-LIST  = PRICE-LIST 
                              AND cinv3.PRC-BREAK-ID = "MV" NO-LOCK NO-ERROR.
                /*20180525 MFA TOLEDO*/
                 
                /********************************************************/
                /* LISTA de precio para todos los items de un cliente   */
                /********************************************************/
                
                IF NOT AVAILABLE cinv3 THEN 
                   FIND CINV3 WHERE CINV3.ITEM-NUMBER   EQ CUST-NUMBER 
                                AND CINV3.PRICE-LIST    EQ PRICE-LIST NO-LOCK NO-ERROR.                
     
                IF NOT AVAILABLE CINV3 THEN
                DO:
                    /*MESSAGE 
                    "Price List "      PRICE-LIST
                    " For Item Number " ITEM-NUMBER
                    " Not Found".
     
                     MESSAGE  "Base Price of Inventory File Will Be Used".*/
     
                    IF SPEC-DICT-I EQ "":U THEN
                    DO:
                       SELLING-PRC = CINV1.BASE-PRICE * (1 - (PERCENT / 100)).
                       IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                         ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                   
                    END. /* IF SPEC-DICT-I EQ "":U */                         

                    ELSE                    
                       SELLING-PRC = CINV1.BASE-PRICE.
                    
     
                    IF SPEC-DICT-I EQ "A":U THEN

                       SELLING-PRC = CINV1.BASE-PRICE.                       
     
                    ASSIGN BASE-PRC    = SELLING-PRC.
                END. /* IF NOT AVAILABLE CINV3 */
                ELSE
                DO:
                    IF SPEC-DICT-I = "":U THEN
                    DO:
                        IF cinv3.prc-break-id = "c":U THEN  
                        DO:                      
                           ASSIGN selling-prc = used-cost / (1 - cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                           
                           IF PARAM-ROUND THEN
                             ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                        END. 
                                                    
                        
                        ELSE
                         /*-------------------------------*/
                        /*20180611 mfa toledo necesitaba que fuera por el vendor cost*/
                        IF cinv3.prc-break-id = "FV" THEN
                        DO:
                              selling-prc = 
                              CINV1.VENDOR-COST / (1 - cinv3.break-price / 100) * (1 - (PERCENT / 100)).
     
                              IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                 ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).                       
                        END.
                        
                        ELSE   
                     /*20180611 mfa toledo necesitaba que fuera por el vendor cost*/
                    /*-------------------------------*/
                        IF cinv3.prc-break-id = "F":U THEN
                        DO:
                           ASSIGN selling-prc = used-cost / (1 - cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                           
                           IF PARAM-ROUND THEN
                             ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                        END.                            
                        
                        
                        ELSE
                        IF CINV3.PRC-BREAK-ID  = "%" THEN
                        DO:
                        
                           ASSIGN SELLING-PRC  = CINV1.BASE-PRICE 
                                               - (CINV3.BREAK-PRICE * CINV1.BASE-PRICE / 100)
                                               * (1 - (PERCENT / 100)).
                           
                           IF PARAM-ROUND THEN
                             ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).                    
                        END.                             
                        
                        ELSE
                        
                        /********************************************************/
                        /* APPLY MARK UP PERCENT TO THE COST                    */
                        /********************************************************/
                        
                        IF cinv3.prc-break-id = "M":U THEN 
                        DO:
                           ASSIGN selling-prc = used-cost * (1 + cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                           IF PARAM-ROUND THEN
                             ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos). 
                        END.                           
                        
                        /*** blanks or any other value ****/
                        ELSE
                        /*20180525 MFA TOLEDO*/
                        /********************************************************/
                        /* APPLY MARK UP PERCENT TO THE  VENDOR COST            */
                        /********************************************************/
                        IF cinv3.prc-break-id = "MV" THEN 
                        DO:
     
                           ASSIGN
                           selling-prc = 
                           CINV1.VENDOR-COST * (1 + cinv3.break-price / 100) * (1 - (PERCENT / 100)).
     
                           IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                              ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).                         
     
                        END.
                        ELSE   
                    /*20180525 MFA TOLEDO*/
                        IF CINV3.PRC-BREAK-ID <> "%":U THEN
                        DO:
                           ASSIGN SELLING-PRC = CINV3.BREAK-PRICE * (1 - (PERCENT / 100)).
                           
                           IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                              ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos). 
                        END.                            
                        
                    END. /*  IF SPEC-DICT-I = "" */
                    
                    ELSE
                    DO:
                        IF CINV3.PRC-BREAK-ID <> "%":U THEN
                        DO:
                            IF CINV3.PRC-BREAK-ID = "C":U THEN
                            DO:
                              IF spec-dict-i = "G" THEN
                              DO:                             
                                   ASSIGN SELLING-PRC = cinv1.accting-cost / (1 - (HOUSE-PAYMENT / 100)).
                              END.
                              
                              ELSE
                                ASSIGN selling-prc = used-cost / ( 1 - cinv3.break-price * 100).
                              
                              IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                                 
                            END. /* IF CINV3.PRC-BREAK-ID = "C" */

                            ELSE
                            IF CINV3.PRC-BREAK-ID = "F":U THEN
                            DO:
                                ASSIGN selling-prc = used-cost / ( 1 - cinv3.break-price * 100).
                                IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                  ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                                 
                            END.  /* IF CINV3.PRC-BREAK-ID = "F" */

                            ELSE
                            /*-------------------------------*/
                           /*20180611 mfa toledo necesitaba que fuera por el vendor cost*/
                            IF cinv3.prc-break-id = "FV" THEN
                            DO:
                              selling-prc = 
                                CINV1.VENDOR-COST / (1 - cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                     
                              IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).                                             
                            END.
                            
                            ELSE   
                           /*20180611 mfa toledo necesitaba que fuera por el vendor cost*/
                             /*-------------------------------*/  
                            DO:
                                
                                /********************************************************/
                                /* APPLY MARK UP PERCENT TO THE COST                    */
                                /********************************************************/
                                
                                IF cinv3.prc-break-id = "M":U THEN
                                DO:
                                   ASSIGN selling-prc = used-cost * (1 + cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                                   IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                    ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                                END.
                                
                            ELSE
                                /*20180525 MFA TOLEDO*/
                            /********************************************************/
                            /* APPLY MARK UP PERCENT TO THE  VENDOR COST            */
                            /********************************************************/
                            IF cinv3.prc-break-id = "MV" THEN 
                            DO:
                              ASSIGN
                               selling-prc = 
                               CINV1.VENDOR-COST * (1 + cinv3.break-price / 100) * (1 - (PERCENT / 100)).                            
 
                               IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                  ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).                         
 
                            END.
                            ELSE   
                            /*20180525 MFA TOLEDO*/                            
                            DO:
                                    ASSIGN SELLING-PRC = CINV3.BREAK-PRICE.
                                    
     
                                    IF TMP-SPEC-DICT-I = "A":U THEN
                                    
                                      ASSIGN 
                                        SELLING-PRC = CINV3.BREAK-PRICE
                                        BASE-PRC    = SELLING-PRC. 
                                      IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                        ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).                                        
                                       
                                END. /*  IF cinv3.prc-break-id = "M" */
     
                            END. /* else IF CINV3.PRC-BREAK-ID = "F" */
                        END. /* IF CINV3.PRC-BREAK-ID <> "%" */
                        
                        ELSE
                        DO:
                            ASSIGN 
                            SELLING-PRC = CINV1.BASE-PRICE 
                                        - (CINV3.BREAK-PRICE * CINV1.BASE-PRICE / 100) 
                                        * (1 - (PERCENT / 100)).
                              
                            IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                              ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                              
                            IF TMP-SPEC-DICT-I = "A":U THEN
                            DO:
                            
                               ASSIGN 
                                 SELLING-PRC  = CINV1.BASE-PRICE 
                                              -(CINV3.BREAK-PRICE * CINV1.BASE-PRICE / 100) 
                                              * (1 - (PERCENT / 100)).
                                              
                               IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                                             
                               BASE-PRC     = SELLING-PRC.
                            END.                               
                               
                        END. /* else IF CINV3.PRC-BREAK-ID <> "%" */
                    END. /* else IF SPEC-DICT-I = "" */
                END. /* IF NOT AVAILABLE CINV3 */
            END. /* IF PRICE-LIST <> " " OR BLANK-LIST */
            
            ELSE
            DO:
              /* victor 070616 */
              IF spec-dict-i = "G" THEN
              DO:
                   ASSIGN SELLING-PRC = cinv1.accting-cost / (1 - (HOUSE-PAYMENT / 100)).
   
                   IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                     ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                     
              END.
              
              ELSE /* victor 070616 */
                IF SPEC-DICT-I = "" THEN
                DO:
                   ASSIGN SELLING-PRC = CINV1.BASE-PRICE * (1 - (PERCENT / 100)).
                   IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                     ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                END.
                    
                ELSE
                   ASSIGN SELLING-PRC = CINV1.BASE-PRICE.
                                   
     
                IF SPEC-DICT-I = "A" THEN
               
                   ASSIGN 
                   SELLING-PRC = CINV1.BASE-PRICE
                   BASE-PRC    = SELLING-PRC.                    
                
     
                IF SPEC-DICT-I = "" AND DISC-PERC <> 0 THEN
                    ASSIGN PERCENT = DISC-PERC.
                     
                IF DISC-PERC < 0 AND qty-brk-cd = "" THEN
                DO:
                      SELLING-PRC = (used-cost / PERCENT * -1).
                      IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                       ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                END.                       
                    
                ELSE
                   IF DISC-PERC < 0 AND qty-brk-cd = "S" THEN
                   DO:
                        SELLING-PRC = (used-cost / PERCENT * -1).
                        IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                          ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                   END.

                BASE-PRC    = CINV1.BASE-PRICE.
     
                /* HELAPAN LISTA DE PRECIOS ESPECIAL PARA ITEM INV-TYPE = UOM
                   CUANDO SE VENDE UNIDADES Y NO CAJAS */
     
                IF CINV1.INV-TYPE = "UOM"     AND 
                   ABS(QTY-FULL) < 100        AND 
                   ABS(qty-full) > 0          AND                   
                   INT(QTY-full / 100 * cinv1.uom-qty) <= CINV1.UOM-QTY THEN
                DO:
                    FIND PARAMFL WHERE PARAMFL.COMPANY-CODE   EQ SUBSTRING(CINV1.ITEM-NUMBER,1,1)
                                   AND PARAMFL.PARAM-ID       EQ "PRECIO-UOM":U
                                   AND PARAMFL.PARAM-STATUS   NO-LOCK NO-ERROR.
                    IF AVAILABLE PARAMFL THEN 
                    DO:
                        FIND CINV3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER 
                                     AND CINV3.PRICE-LIST  EQ PARAMFL.PARAM-VALUE1 NO-LOCK NO-ERROR.
     
                        IF AVAILABLE CINV3 THEN
                        DO:
                            SELLING-PRC = CINV3.BREAK-PRICE.
     
                            IF CINV1.BY-WEIGHT <> "F":U AND 
                               CINV1.BY-WEIGHT <> "V":U THEN
                               
                                ASSIGN SELLING-PRC = SELLING-PRC * CINV1.UOM-QTY.                                                              
                            ELSE                            
                               ASSIGN selling-prc = selling-prc * qty-unit.
                                                           
                               
                        END.  /* IF AVAILABLE CINV3           */                        
                    END.     /* IF AVAILABLE PARAMFL         */
                END.        /* IF CINV1.INV-TYPE = "UOM"... */             
            END.           /* else IF PRICE-LIST <> " " .. */
     
            
            DEFINE BUFFER binv3 FOR cinv3.
            
            DEFINE VARIABLE cant     AS DECIMAL NO-UNDO.
            DEFINE VARIABLE prc-sell AS DECIMAL NO-UNDO.
            DEFINE VARIABLE cnt      AS INTEGER NO-UNDO.
     
            ASSIGN cant = qty-full / 100.
            
            IF TMP-CUST-TYPE = "TIENDA":U  OR 
               TMP-CUST-TYPE = "STORE":U   THEN
            DO:
     
            END. 
            ELSE
            DO:                
                FIND ofert WHERE ofert.price-list  EQ cinv1.item-uom
                             AND ofert.item-number EQ "OFERTAS":U
                             AND OFERT.FROM-DT     LE TODAY
                             AND OFERT.TO-DT       GE TODAY NO-LOCK NO-ERROR.
     
                IF AVAILABLE OFERT THEN
                DO:
                    IF CANT > UP-TO-QTY[5]  AND 
                      CAN-FIND (BINV3 WHERE BINV3.PRICE-LIST  = "6":U 
                                        AND BINV3.ITEM-NUMBER = CINV1.ITEM-NUMBER) THEN
                    DO:
                        FIND BINV3 WHERE BINV3.PRICE-LIST  EQ "6":U
                                     AND BINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER NO-LOCK NO-ERROR.
                        
                        IF NOT AVAILABLE Binv3  THEN 
                           FIND BINV3 WHERE BINV3.ITEM-NUMBER  EQ cinv1.class-code 
                                        AND BINV3.PRICE-LIST   EQ "6":U 
                                        AND Binv3.PRC-BREAK-ID EQ "C":U NO-LOCK NO-ERROR.                        
     
                        IF AVAILABLE binv3 THEN
                        DO:
                            IF binv3.PRC-BREAK-ID = "C":U THEN
                            DO:
                               ASSIGN 
                               PRC-SELL = used-cost / (1 - (binv3.break-price / 100)).
                               
                               IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                 ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                            END.
                            
                            ELSE
                            IF binv3.prc-break-id = "%":U THEN
                            DO:                        
                               ASSIGN 
                               prc-sell = cinv1.base-price * (1 - (binv3.break-price / 100)).
                               IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                 ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                            END.
                            ELSE
                               ASSIGN prc-sell = binv3.break-price.
                               
                        END. /*  IF AVAILABLE binv3*/                       
                    END. /*  IF CANT > UP-TO-QTY[5]  AND CAN-FIND ... */
                    
                    ELSE
                    DO CNT = 5 TO 1 BY -1:
                       IF CANT <= UP-TO-QTY[CNT] THEN
                       DO:
                            FIND BINV3 WHERE BINV3.PRICE-LIST  = string(CNT,"9":U)
                                         AND BINV3.ITEM-NUMBER = CINV1.ITEM-NUMBER NO-LOCK NO-ERROR.
                            
                            IF NOT AVAILABLE Binv3 THEN 
                               FIND BINV3 WHERE BINV3.ITEM-NUMBER  = cinv1.class-code 
                                            AND BINV3.PRICE-LIST   = string(CNT,"9":U) 
                                            AND Binv3.PRC-BREAK-ID = "C":U NO-LOCK NO-ERROR.                            
     
                            IF AVAILABLE binv3 THEN
                            DO:
                                IF binv3.PRC-BREAK-ID = "C":U THEN
                                DO:
                                   ASSIGN 
                                   PRC-SELL = used-cost /  (1 - (binv3.break-price / 100)).
                                   
                                   IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                     ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                                END.
                                
                                ELSE
                                IF binv3.prc-break-id = "%":U THEN
                                DO:
                                   ASSIGN 
                                   prc-sell = cinv1.base-price * (1 - (binv3.break-price / 100)).
                                   
                                   IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
                                     ASSIGN SELLING-PRC = ROUND(SELLING-PRC,v-pos).
                                END. 
                                
                                ELSE
                                   ASSIGN prc-sell = binv3.break-price.
                            END. /* IF AVAILABLE binv3        */
                       END.     /* IF CANT <= UP-TO-QTY[CNT] */
                    END.       /* DO CNT = 5 TO 1 BY -1:    */
     
                    IF PRC-SELL < SELLING-PRC AND prc-sell > 0 THEN
                    
                      ASSIGN 
                       SELLING-PRC = PRC-SELL
                       base-prc    = SELLING-PRC.                        
                    
                       
                END.  /* IF AVAILABLE OFERT                */
            END.     /* else IF TMP-CUST-TYPE = "TIENDA"..*/
        END.        /* else IF CONTRACT-IND = "S"..      */
    END.           /* IF LOOKUP-LIST                    */    
    
  END METHOD.
    
  METHOD PUBLIC VOID getLowPrice(INPUT ipcCompany AS CHARACTER, 
                                 INPUT ipcCustNumber AS CHARACTER,
                                 INPUT ipcitem-number AS CHARACTER,
                                 INPUT PRECIO-DISC-PERC AS DECIMAL,
                                 OUTPUT opLowestPrice AS DECIMAL):
 
 
        opLowestPrice = 0.
        
        DEF VAR             W-PRICE             AS CHAR     FORMAT "X(65)"  NO-UNDO.
        DEF VAR             W-%                 AS DECIMAL  FORMAT "->>.99" NO-UNDO.
        DEF VAR             W-LIST              AS CHAR                     NO-UNDO.
        DEF VAR             NF-PARAMFL          AS LOGICAL                  NO-UNDO.
        DEF VAR             I-CUST-NUMBER       LIKE CCSMS.CUST-NUMBER      NO-UNDO.
        DEF VAR             CUST-SELLING-PRC    LIKE CIVDT.SELLING-PRC      NO-UNDO. 
        /***** ACASIGN 07/27/2006 START *****/
        DEF VAR LOW                             AS DECIMAL                  NO-UNDO.
        DEF VAR HIGH                            AS DECIMAL                  NO-UNDO.
        /***** ACASIGN 07/27/2006   END *****/
        DEF VAR TMP-ITEM-CLASS                  LIKE CINV1.CLASS-CODE       NO-UNDO.
        DEF VAR used-cost                       AS DEC                      NO-UNDO.    /* 03/03/2016 wam NUÑEZ  */ 
        DEF VAR USE-SLSMN-COST                  AS LOG                      NO-UNDO.    /* 03/03/2016 WAM NUÑEZ */
        DEF VAR PARAM-ROUND     AS LOGICAL                  NO-UNDO. 
        DEF VAR V-POS           AS INTEGER                  NO-UNDO.
        DEF VAR LOWEST-PRICE    AS DECIMAL NO-UNDO.
         
        /* 03/03/2016 WAM NUÑEZ START */
        /********************************************************/
        /* use salesman cost for price calculations             */
        /********************************************************/
        FIND PARAMFL WHERE PARAMFL.PARAM-ID     = "PRICE-USE-SLSMN-COST" 
                       AND PARAMFL.COMPANY-CODE = ipcCompany 
                       AND PARAMFL.PARAM-STATUS 
        NO-LOCK NO-ERROR.
        ASSIGN USE-SLSMN-COST = AVAILABLE PARAMFL.
        
        /* 03/03/2016 WAM NUÑEZ  END */
        /********************************************************/
        /* para redondear a x posiciones  20160628 MFA          */
        /********************************************************/
        FIND PARAMFL WHERE PARAMFL.PARAM-ID     = "PARAM-ROUND" 
                       AND PARAMFL.COMPANY-CODE = ipcCompany 
                       AND PARAMFL.PARAM-STATUS 
        NO-LOCK NO-ERROR.
        ASSIGN PARAM-ROUND = AVAILABLE PARAMFL.
        IF PARAM-ROUND THEN
           V-POS = INTEGER(PARAMFL.PARAM-VALUE1).
        
         
        ASSIGN TMP-ITEM-CLASS = " ".
        /********************************************************/
        /*  FIND BASE PRICE, ACCTING-COST, VENDOR-COST,         */
        /*       LANDED-COST, MARKET-COST, SLSMN-COST.          */
        /********************************************************/
        FIND CINV1 WHERE CINV1.ITEM-NUMBER = ipcitem-number 
             NO-LOCK NO-ERROR.
        IF AVAILABLE CINV1 THEN 
           ASSIGN TMP-ITEM-CLASS = CINV1.CLASS-CODE.
         
        /********************************************************/
        /* ASSIGN DEFAUTL VALUES                                */
        /********************************************************/
        ASSIGN 
        LOWEST-PRICE    = 0 
        W-PRICE         = FILL(" ",65).
        /********************************************************/
        /* FIND ITEM CLASS FOR ITEM BEING PROCESSED             */
        /********************************************************/
        FIND IVBRAND WHERE IVBRAND.CLASS-CODE = TMP-ITEM-CLASS
        NO-LOCK NO-ERROR.
        IF AVAILABLE IVBRAND THEN
           DO: 
         
              /********************************************************/
              /* VERIFY IF ITEM CLASS WAS MARKED AS PRICE VERIFY = N  */
              /* ITEMS BELONGING TO THIS CLASS WILL ALLOW ANY PRICE   */
              /********************************************************/
              IF IVBRAND.KNOWN-BRAND = "N" THEN
                 DO:
                    ASSIGN LOWEST-PRICE =  1.0 . /* Allow any price above 1*/
                    RETURN.
                 END. /* IF IVBRAND.KNOWN-BRAND = "N" */
         
           END. /* IF AVAILABLE IVBRAND */
         
         
        ASSIGN NF-PARAMFL = NO.
        FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = ipcCompany
                       AND PARAMFL.PARAM-ID     = "OEPRECIO-LOWPRC"
                       AND PARAMFL.PARAM-STAT   = yes
             NO-LOCK NO-ERROR.
        IF NOT AVAILABLE PARAMFL THEN
           /***** 06/27/02 START WAM *******************************/
           ASSIGN W-PRICE    = "LIST"
                  W-LIST     = "Z"
                  W-%        = 1
                  NF-PARAMFL = NO.
           /***** 06/27/02  END  WAM *******************************/
        ELSE
            /***** ACASIGN 07/27/2006 START *****/
           DO:
              IF PARAMFL.PARAM-DESCRI = "GP" THEN
                 DO:
                    ASSIGN 
                    W-PRICE = PARAM-DESCRI
                    LOW     = DECIMAL(PARAMFL.PARAM-VALUE2)
                    HIGH    = DECIMAL(PARAMFL.PARAM-VALUE3).
         
                 END. /* IF PARAMFL.PARAM-VALUE1 = "GP" */
                 /***** ACASIGN 07/27/2006  END  *****/
              ELSE
                 /***** 06/27/02 START WAM *******************************/
                 DO:
                    ASSIGN 
                    W-PRICE    = PARAM-DESCRI
                    W-LIST     = PARAM-VALUE1
                    W-%        = DECIMAL(PARAM-VALUE2)
                    NF-PARAMFL = YES.
                 /***** 06/27/02  END  WAM *******************************/
                 END.
           END.
         
         
        IF W-% <= 0 THEN
           ASSIGN W-% = 1.
         
        /*****----------------------------------------------*****/
        /* FIND LOWEST PRICE ALLOWED IN PRICE LIST              */
        /*****----------------------------------------------*****/
        IF W-PRICE = "LIST" THEN
        DO:
            
    /*        THIS-OBJECT:W-PRICE-list()*/
           ASSIGN used-cost = 0.
           IF  USE-SLSMN-COST THEN
             ASSIGN used-cost = CINV1.SLSMN-COST.
         
            FIND CINV3 WHERE CINV3.ITEM-NUMBER = ipcitem-number
                       /***** 06/27/02 START WAM *******************************/
                         AND CINV3.PRICE-LIST  = W-LIST
                       /***** 06/27/02  END  WAM *******************************/
            NO-LOCK NO-ERROR.
         
            /* 03/03/2016 WAM NUÑEZ START */
            IF NOT AVAILABLE cinv3 THEN 
               FIND CINV3 WHERE CINV3.ITEM-NUMBER =  TMP-ITEM-CLASS // ipcitem-number 
                            AND CINV3.PRICE-LIST  = W-LIST
               NO-LOCK NO-ERROR.
            /* 03/03/2016 WAM NUÑEZ  end */
         
            /***** 06/27/02 START WAM *******************************/
            IF NF-PARAMFL = NO THEN
               FIND LAST CINV3 WHERE CINV3.ITEM-NUMBER = ipcitem-number
               NO-LOCK NO-ERROR.
            /***** 06/27/02  END  WAM *******************************/
         
            IF AVAILABLE CINV3 THEN
            DO:
         
         
                IF cinv3.prc-break-id = "c" THEN
                    LOWEST-PRICE = used-cost / (1 - (cinv3.break-price / 100)).
                ELSE
                    IF cinv3.prc-break-id = "F" THEN
                        LOWEST-PRICE = used-cost / (1 - (cinv3.break-price / 100)).
                    ELSE
                        IF (CINV3.PRC-BREAK-ID = "%" 
                        OR  CINV3.PRC-BREAK-ID = "D") THEN
                            ASSIGN 
                            LOWEST-PRICE  = CINV1.BASE-PRICE 
                                            - (CINV3.BREAK-PRICE * (CINV1.BASE-PRICE / 100))
                                            * (1 - (PRECIO-DISC-PERC / 100)).
                        ELSE
                            /********************************************************/
                            /* APPLY MARK UP PERCENT TO THE COST                    */
                            /********************************************************/
                            IF cinv3.prc-break-id = "M" THEN 
                               ASSIGN
                               LOWEST-PRICE = used-cost * (1 + (cinv3.break-price / 100)) .
         
                            /*** blanks or any other value ****/
                            ELSE
                            IF CINV3.PRC-BREAK-ID <> "%" THEN
                               ASSIGN LOWEST-PRICE = CINV3.BREAK-PRICE  * (1 - (PRECIO-DISC-PERC / 100)). 
                /*** 03/03/2016 WAM NUÑEZ  end  ***/
            END. /* END DO AFTER IF AVAILABLE CINV3 */
            ELSE
                /********************************************************/
                /* WHEN PRICE LIST NOT FOUND IN LIST USE BASE PRICE     */
                /* AS VARIABLE AMOUNT.                                  */
                /********************************************************/
                ASSIGN LOWEST-PRICE = ROUND((CINV1.BASE-PRICE * W-%),2).
        END. /* IF W-PRICE = "LIST" */
         
        /*****----------------------------------------------*****/
        /* FIND LOWEST PRICE ALLOWED USING ACCOUNTING COST      */
        /*****----------------------------------------------*****/
        IF W-PRICE = "ACCOUNTING COST" THEN
        DO:
            ASSIGN LOWEST-PRICE = ROUND((CINV1.ACCTING-COST * W-%),2).
        END.
         
        /*****----------------------------------------------*****/
        /* FIND LOWEST PRICE ALLOWED USING VENDOR COST          */
        /*****----------------------------------------------*****/
        IF W-PRICE = "VENDOR COST" THEN
        DO:
            ASSIGN LOWEST-PRICE = ROUND((CINV1.VENDOR-COST * W-%),2).
        END.
         
        /*****----------------------------------------------*****/
        /* FIND LOWEST PRICE ALLOWED USING LANDED COST          */
        /*****----------------------------------------------*****/
        IF W-PRICE = "LANDED COST" THEN
        DO:
            ASSIGN LOWEST-PRICE = ROUND((CINV1.LANDED-COST * W-%),2).
        END.
         
        /*****----------------------------------------------*****/
        /* FIND LOWEST PRICE ALLOWED USING MARKET COST          */
        /*****----------------------------------------------*****/
        IF W-PRICE = "MARKET COST" THEN
        DO:
            ASSIGN LOWEST-PRICE = ROUND((CINV1.MARKET-COST * W-%),2).
        END.
         
        /*****----------------------------------------------*****/
        /* FIND LOWEST PRICE ALLOWED USING SALESMAN COST        */
        /*****----------------------------------------------*****/
        IF W-PRICE = "SALESMAN COST" THEN
        DO:
            ASSIGN LOWEST-PRICE = ROUND((CINV1.SLSMN-COST * W-%),2).
        END.
         
        /*****----------------------------------------------*****/
        /* FIND LOWEST PRICE ALLOWED USING BASE PRICE           */
        /*****----------------------------------------------*****/
        IF W-PRICE = "BASE PRICE" THEN
        DO:
            ASSIGN LOWEST-PRICE = ROUND((CINV1.BASE-PRICE * (1 - W-%)),2).
        END.
         
        /*****----------------------------------------------*****/
        /* FOR GROSS PROFIT CALCULATE LOWEST AND HIGHEST        */
        /*****----------------------------------------------*****/
        IF W-PRICE = "GP" THEN
        DO:
            /********************************************************/
            /* PRECIO-DISC-PERC CONTAINS THE COST INSTEAD OF DISC%  */
            /********************************************************/
            ASSIGN
            LOWEST-PRICE     = ROUND((PRECIO-DISC-PERC / (1 - LOW  / 100)),2).
            
         
        END. /* IF W-PRICE = "GP" */
        ELSE
        DO:
              /*****----------------------------------------------*****/
              /* CUSTOMER WITH LIST                                   */
              /*****----------------------------------------------*****/
              ASSIGN I-CUST-NUMBER = " ".
              /********************************************************/
              /* FIND ACTIVE CUSTOMER NUMBER                          */ 
              /********************************************************/
              
                 ASSIGN I-CUST-NUMBER = ipcCustNumber. 
         
              /********************************************************/
              /* FIND DATA FOR ACTIVE CUSTOMER NUMBER                 */ 
              /********************************************************/
              FIND CCSMS WHERE CCSMS.CUST-NUMBER = I-CUST-NUMBER
              NO-LOCK NO-ERROR.
              IF AVAILABLE CCSMS THEN
                 DO:
                    /********************************************************/
                    /* FIND PRICE IN THE CUSTOMER'S LIST                    */
                    /********************************************************/
                    FIND CINV3 WHERE CINV3.ITEM-NUMBER = ipcitem-number
                                 AND CINV3.PRICE-LIST  = CCSMS.PRICE-LIST
                    NO-LOCK NO-ERROR.
                    /********************************************************/
                    /* CHECK IF CUSTOMER'S LIST HAS THE LOWEST PRICE        */
                    /********************************************************/
                    IF AVAILABLE CINV3 THEN
                       DO:
                         /********************************************************/
                         /*  WHEN ITEM IS MARKED AS %:                           */
                         /*  CALCULATE VARIABLE AMOUNT % OF BASE PRICE           */
                         /********************************************************/
                         IF CINV3.PRC-BREAK-ID = "%" OR
                            CINV3.PRC-BREAK-ID = "D" THEN
                            CUST-SELLING-PRC   = (CINV1.BASE-PRICE - 
                                                 (CINV3.BREAK-PRICE * CINV1.BASE-PRICE / 100) * 
                                                 (1 - (PRECIO-DISC-PERC / 100))) * W-%.
                         ELSE 
                            CUST-SELLING-PRC   = CINV3.BREAK-PRICE * W-%.
                         
                         IF CUST-SELLING-PRC < LOWEST-PRICE  THEN
                            ASSIGN LOWEST-PRICE = CUST-SELLING-PRC.
                       END. /* IF AVAILABLE CINV3 */
                 END. /* IF AVAILABLE CCSMS */
         
        END. /*  ELSE IF W-PRICE = "GP" */
        
        
        IF PARAM-ROUND THEN  /*201606029 mfa nunez*/
            ASSIGN LOWEST-PRICE = ROUND(LOWEST-PRICE,v-pos).
           
        ASSIGN opLowestPrice = LOWEST-PRICE.
    END METHOD.  
    
    METHOD PUBLIC VOID getAllItemPrice(INPUT ipcCompany AS CHARACTER, 
                                       INPUT ipcCustNumber AS CHARACTER,
                                       INPUT ipcitem-number AS CHARACTER,
                                       INPUT PRECIO-DISC-PERC AS DECIMAL,
                                       OUTPUT opPriceList AS CHARACTER):
                                           
      DEF VAR TMP-ITEM-CLASS                  LIKE CINV1.CLASS-CODE       NO-UNDO.    
      FIND CINV1 WHERE CINV1.ITEM-NUMBER = ipcitem-number NO-LOCK NO-ERROR.
      IF AVAILABLE CINV1 THEN 
           ASSIGN TMP-ITEM-CLASS = CINV1.CLASS-CODE.   
      ELSE
       TMP-ITEM-CLASS = "".
       
      FOR EACH  CINV3 WHERE CINV3.ITEM-NUMBER   =  ipcitem-number 
                        AND NOT CINV3.PRICE-LIST MATCHES "*TAX*"  /*20160625 MFA*/
                        AND CINV3.PRIVATE-CODE <> "P"  NO-LOCK:  
        
        if opPriceList NE "" THEN 
           assign opPriceList = opPriceList + "|".
                               
        assign opPriceList = opPriceList + STRING(CINV3.BREAK-PRICE) .
                             
      END.                                        
                                           
    END.                                     
    
   
  END CLASS.