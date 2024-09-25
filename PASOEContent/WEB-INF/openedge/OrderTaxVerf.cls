 
 /*------------------------------------------------------------------------
    File        : OrderTaxVerf
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : JKTECH
    Created     : Thu Feb 01 09:43:15 IST 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OrderTaxVerf: 
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  
  {ordertaxverfdef.i} 
     
  CONSTRUCTOR PUBLIC OrderTaxVerf (  ):
      
  END CONSTRUCTOR.
  
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC OrderTaxVerf (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
  END CONSTRUCTOR.
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID OrderTaxVerfMainBlock(INPUT i-company                  AS CHARACTER,
                                           INPUT i-cust-number              AS CHARACTER,
                                           INPUT i-ship-to-no               AS CHARACTER,
                                           INPUT i-INVOICE-DATE             AS DATE,
                                           INPUT i-trans-type               AS CHARACTER,
                                           INPUT i-dsp-msg                  AS CHARACTER,
                                           INPUT-OUTPUT io-CITY-TAX-EXEMPT  AS LOGICAL,
                                           INPUT-OUTPUT io-state-TAX-EXEMPT AS LOGICAL,
                                           INPUT-OUTPUT fecha-exempt-vencio AS LOGICAL,
                                           INPUT-OUTPUT IVU-HOLD-CODE       AS CHARACTER,
                                           INPUT-OUTPUT TAX-RET-VAL         AS CHARACTER):
        
    THIS-OBJECT:i-company           = i-company.
    THIS-OBJECT:i-cust-number       = i-cust-number.
    THIS-OBJECT:i-ship-to-no        = i-ship-to-no.
    THIS-OBJECT:i-INVOICE-DATE      = i-INVOICE-DATE.
    THIS-OBJECT:i-trans-type        = i-trans-type.
    THIS-OBJECT:io-CITY-TAX-EXEMPT  = io-CITY-TAX-EXEMPT.
    THIS-OBJECT:io-state-TAX-EXEMPT = io-state-TAX-EXEMPT.
    THIS-OBJECT:fecha-exempt-vencio = fecha-exempt-vencio.
    THIS-OBJECT:IVU-HOLD-CODE       = IVU-HOLD-CODE.
    THIS-OBJECT:TAX-RET-VAL         = TAX-RET-VAL.
    
    /*****----------------------------------------------*****/
    /* M A I N   L I N E                                    */
    /*****----------------------------------------------*****/
    ASSIGN 
        TAX-RET-VAL         = " "
        IVU-HOLD-CODE       = " " 
        error-msg-line-1    = " "
        error-msg-line-2    = " ".
         
    /********************************************************/
    /* find paramfl                                         */
    /********************************************************/
    THIS-OBJECT:Params().
     
    /********************************************************/
    /* find tax codes and dates                             */
    /********************************************************/
    THIS-OBJECT:TaxCode().
        
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID Params():
     /*****----------------------------------------------*****/
    /* p r o c - p a r a m s                                */ 
    /*****----------------------------------------------*****/
    /********************************************************/
    /* ON USE DATA FROM SHIP TO RECORD                      */
    /********************************************************/
    
    THIS-OBJECT:FindParamFl(INPUT "IVU-SIEMPRE-SHPTO").
    
    IVU-SIEMPRE-SHPTO = AVAILABLE paramfl.
    
    /********************************************************/
    /* ON-TO HOLD ORDERS OTHER PERSON WILL RELEASE IT       */
    /********************************************************/
    
    THIS-OBJECT:FindParamFl(INPUT "PUT-ON-HOLD").
    PUT-ON-HOLD = AVAILABLE PARAMFL.
 
    /********************************************************/
    /* ON-sc2916                                            */
    /********************************************************/
    
    THIS-OBJECT:FindParamFl(INPUT "sc2916-billing-date").
    sc2916-billing-date =  AVAILABLE PARAMFL .
 
    ASSIGN  
      start-new-law-date  = 08/01/2014
      from-invoice-date   = 01/01/2014
      warning-days        = 60.
   
    /********************************************************/
    /* new ivu law starts in 7/1/2014                       */
    /********************************************************/
    THIS-OBJECT:FindParamFl(INPUT "ivu-law-2014").
    IF  AVAIL paramfl THEN
    DO:
      IF  DATE(paramfl.param-value1) NE ? THEN 
        ASSIGN  
          start-new-law-date  = DATE(paramfl.param-value1).
 
      IF  DATE(paramfl.param-value2) NE ? THEN 
        ASSIGN  
          from-invoice-date   = DATE(paramfl.param-value2).
 
      IF  paramfl.param-value3 NE " " THEN
        ASSIGN warning-days = INT(paramfl.param-value3).
        
    END. /* IF  AVAIL paramfl */
 
  END METHOD.
    
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID FindParamFl(INPUT P-PARAM-ID AS CHARACTER):
    /*****----------------------------------------------*****/
    /* F I N D - P A R A M F L                              */
    /*****----------------------------------------------*****/

    FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ i-company
                       AND PARAMFL.PARAM-ID EQ P-PARAM-ID
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.    
 
  END METHOD.
    
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID TaxCode():
    
    /*****----------------------------------------------*****/
    /* P R O C - T A X - C O D E                            */
    /* BUSCA LA EL CODIGO Y FECHA EN QUE TERMINA LA         */
    /* EXEMPTION de ccscs y si tiene shipto DEL SHIPTO      */
    /*****----------------------------------------------*****/
    
    /********************************************************/
    /* find selected customer                               */
    /********************************************************/
   
    FIND ccsms WHERE ccsms.cust-number EQ i-cust-number NO-LOCK NO-ERROR.
    IF NOT AVAIL ccsms THEN
    DO:
        ASSIGN TAX-RET-VAL = "invalid-customer".
    END.
 
    SET 
    ivu-exp-exe = ? 
    ivu-code    = ""
    SC2916-EXP  = ?
    ivu-code    = ccsms.SALES-TAX-CD. 
    
    ivu-exp-exe  = DATE(SUBSTRING(ccsms.beeper-unit,1,8)) NO-ERROR.
 
    IF sc2916-billing-date THEN
       SC2916-EXP = ccsms.BILLING-DATE.
    
    ELSE
       SC2916-EXP = ?.
 
    /* find ship to data */
    IF  i-ship-to-no NE "" THEN
    DO:
      TEMP-CHAR = SEARCH("OEIVUSHP.R").
  
      IF TEMP-CHAR NE ? THEN 
      DO:
        SET 
        SHP-CODE        = "" 
        SHP-EXP         = ? 
        SHP-SC2916-EXP  = ?.
        
        THIS-OBJECT:OrderTaxExpireMain(INPUT CCSMS.CUST-NUMBER,
                                       INPUT i-ship-to-no,
                                       OUTPUT SHP-CODE ,
                                       OUTPUT SHP-EXP ,
                                       OUTPUT SHP-SC2916-EXP).
                                             
        /*IVU-SIEMPRE-SHPTO ENTONCES USA LA DATA DEL SHIP-TO SIEMPRE*/
        IF IVU-SIEMPRE-SHPTO 
        THEN 
        DO:
          /* para no tener que llenar todos los shipto solo hace overwrite cuando se escribio algo en el shipto*/
          IF  SHP-CODE NE "" THEN
            ASSIGN IVU-CODE = SHP-CODE.
 
          IF  SHP-EXP NE ?   THEN
            ASSIGN IVU-EXP-EXE = SHP-EXP.
 
          IF  SHP-SC2916-EXP NE ? THEN
            ASSIGN SC2916-EXP  = SHP-SC2916-EXP.
 
        END. /* IF SHP-CODE <> "" OR SHP-EXP <> ? OR SHP-SC2916-EXP <> ? OR IVU-SIEMPRE-SHPTO*/
 
      END.  /* IF TEMP-CHAR <> ? */
 
    END. /* IF  CUSTOMER-HAS-SHIPTO AND tmp-header.SHIP-TO-NO <> "" */
 
    /********************************************************/
    /*verify if customer or shipto marked with ivu exemption*/
    /********************************************************/
    
    IF  IVU-CODE NE " " THEN
    DO: 
      /********************************************************/
      /* verifica fecha del certificado                       */
      /********************************************************/
      
      IF  i-INVOICE-DATE GE start-new-law-date  THEN
        THIS-OBJECT:NewIvuLawCkDate().
      ELSE
        THIS-OBJECT:VerificaFechaCert().
        
    END. /* IF  IVU-CODE <> " "*/
 
 
  END METHOD.
    
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID NewIvuLawCkDate():
    /*****----------------------------------------------*****/
    /* n e w - i v u - l a w - c k - d a t e                */
    /*****----------------------------------------------*****/
    
    /********************************************************/
    /* para que llene la pantalla                           */
    /********************************************************/
    ASSIGN 
      /* fill using last value read customer or shipto*/
      io-CITY-TAX-EXEMPT  = (IVU-CODE = "no" OR IVU-CODE = "nc" OR IVU-CODE = "BB")
      io-state-TAX-EXEMPT = NO. /* under new law there are no state exemption */ 
                    
 
    /********************************************************/
    /* VALUES OF TRANSACTION TYPE                           */
    /*  1 = Direct Sales                                    */
    /*  2 = New Order                                       */
    /*  3 = New Quote                                       */
    /*  4 = Modify Order/Quote                              */
    /*  5 = Convert Quote to Order                          */
    /*  6 = Invoice Order                                   */
    /*  7 = Order Reprint                                   */
    /*  8 = Copy Quote                                      */
    /*  9 = New Transfer                                    */
    /* 10 = Modify Transfer                                 */
    /* 11 = Confirm Transfer                                */
    /* 12 = LAY AWAY                                        */
    /********************************************************/ 
    
    IF (i-trans-type EQ "1"
    OR  i-trans-type EQ "2" 
    OR  i-trans-type EQ "3"
    OR  i-trans-type EQ "4"
    OR  i-trans-type EQ "5"      
    OR  i-trans-type EQ "6"
    OR  i-trans-type EQ "8"     
    OR  i-TRANS-TYPE EQ "12") THEN 
    
    DO:
      /* old code no longer valid */
     
      IF  ivu-code EQ "NS" THEN
      DO:
          THIS-OBJECT:IvuCodeNs().
      END. /* IF  ivu-code = "NS" */
 
        /* only for government and export reseller */
      IF  ivu-code EQ "NO" THEN
      DO:
          THIS-OBJECT:IvuCodeNo().
      END. /* IF  ivu-code = "NO" */
 
        /* reseller exempt from city tax */
      IF  ivu-code EQ "NC" 
      OR  ivu-code EQ "BB" THEN   
      DO:
          THIS-OBJECT:IvuCodeNc().
      END. /* IF  ivu-code = "NC" */
 
    END. /* if i-trans-type ...*/
 
    
  END METHOD.
    
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID IvuCodeNs():

    ASSIGN 
      error-msg-line-1  = "CHECK CUSTOMER " + i-cust-number
      error-msg-line-2  = "TAX EXEMPTION CODE -NS- IS INVALID" .
 
    IF  i-ship-to-no NE " " THEN
      ASSIGN 
        error-msg-line-1    = error-msg-line-1 + " WITH SHIP TO " +  i-ship-to-no
        error-msg-line-2    = "TAX EXEMPTION CODE -NS- IS INVALID, IN CUSTOMER OR SHIP TO" .
 
  END METHOD.
    
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID IvuCodeNo():
        
    /*****----------------------------------------------*****/
    /* i v u - c o d e - N O                                */
    /*****----------------------------------------------*****/

    /* without expiration date */
    IF ivu-exp-exe EQ ? THEN
    DO:
      /* government or export sales EXEMPT of CITY & STATE */
      ASSIGN 
        io-CITY-TAX-EXEMPT  = YES
        io-state-TAX-EXEMPT = YES. 
    END. /* IF  ivu-exp-exe = ? */
  
    ELSE
    /* check expiration date */
    DO:
      /* invoice after expiration date */   
      IF ivu-exp-exe LT i-INVOICE-DATE THEN
      DO:
        /* remove exemption of both city and state taxes*/
        ASSIGN 
          io-CITY-TAX-EXEMPT  = NO
          io-state-TAX-EXEMPT = NO
          fecha-exempt-vencio = YES . 
 
        /* TO PLACE ORDERS ON HOLD WHEN IVU EXPIRED */
        IF  PUT-ON-HOLD THEN
            ASSIGN IVU-HOLD-CODE = "HOLD-IVU".
 
      END. /* IF ivu-exp-exe < i-INVOICE-DATE */
      
      ELSE
      /* invoice before expiration date */
      DO:
        /* reseller with certificate, EXEMPT of CITY & STATE */
        ASSIGN 
          io-CITY-TAX-EXEMPT  = YES
          io-state-TAX-EXEMPT = YES. 
 
        /* WARNING: certificate is near expiration */
        IF (ivu-exp-exe - i-INVOICE-DATE) LE warning-days THEN
        DO:
            
        END. /*  IF (ivu-exp-exe - i-INVOICE-DATE) <= warning-days  */
 
      END. /* else IF ivu-exp-exe < i-INVOICE-DATE */
      
    END. /* else IF  ivu-exp-exe = ? */
 
  END METHOD.
    
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID IvuCodeNc():
    /*****----------------------------------------------*****/
    /* i v u - c o d e - N C                                */
    /*****----------------------------------------------*****/

    /* without expiration date */
    IF ivu-exp-exe EQ ? THEN
    DO:
      /* INVALID NO TAX EXEMPTION */
      ASSIGN 
        io-CITY-TAX-EXEMPT  = NO
        io-state-TAX-EXEMPT = NO. 
 
      ASSIGN 
        error-msg-line-1  = "CHECK CUSTOMER " + i-cust-number
        error-msg-line-2  = "TAX EXEMPTION CODE-" + ivu-code + "- IS INVALID " .
 
      IF  i-ship-to-no NE " " THEN
        ASSIGN 
          error-msg-line-1    = error-msg-line-1 + " WITH SHIP TO " +  i-ship-to-no
          error-msg-line-2    = "TAX EXEMPTION CODE-" + ivu-code + "- IS INVALID, IN CUSTOMER OR SHIP TO" .
 
      /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
        
    END. /* IF  ivu-exp-exe = ? */
   
    ELSE
    /* check expiration date */
    DO:
        /* invoice after expiration date*/   
        IF ivu-exp-exe < i-INVOICE-DATE THEN
        DO:
            /* remove exemption of both city and state taxes*/
            ASSIGN 
              io-CITY-TAX-EXEMPT  = NO
              io-state-TAX-EXEMPT = NO
              fecha-exempt-vencio = YES. 
 
            /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
 
            /* TO PLACE ORDERS ON HOLD WHEN IVU EXPIRED*/
            IF  PUT-ON-HOLD THEN
              ASSIGN IVU-HOLD-CODE = "HOLD-IVU".
 
        END. /* IF ivu-exp-exe < i-INVOICE-DATE */
        ELSE
        /* invoice before expiration date */
        DO:
            /* reseller with certificate, EXEMPT of CITY & STATE */
            ASSIGN 
              io-CITY-TAX-EXEMPT  = YES
              io-state-TAX-EXEMPT = NO. 
 
            /* WARNING: certificate is near expiration */
            IF (ivu-exp-exe - i-INVOICE-DATE) <= warning-days THEN
            DO:
                /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
                
            END. /*  IF (ivu-exp-exe - i-INVOICE-DATE) <= warning-days  */
 
        END. /* else IF ivu-exp-exe < i-INVOICE-DATE */
    END. /* else IF  ivu-exp-exe = ? */
 
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID VerificaFechaCert():
    /*****----------------------------------------------*****/
    /* v e r i f i c a - f e c h a - c e r t                */
    /* procedure creado de logica que existia dentro del    */
    /* procedure create-header                              */
    /*****----------------------------------------------*****/

    /********************************************************/
    /* para que llene la pantalla con el valor del shipto   */
    /********************************************************/
    
    ASSIGN 
      io-CITY-TAX-EXEMPT  = (IVU-CODE = "no" OR IVU-CODE = "nc")
      io-state-TAX-EXEMPT = (IVU-CODE = "no" OR IVU-CODE = "ns").
 
    /********************************************************/
    /* VALUES OF TRANSACTION TYPE                           */
    /*  1 = Direct Sales                                    */
    /*  2 = New Order                                       */
    /*  3 = New Quote                                       */
    /*  4 = Modify Order/Quote                              */
    /*  5 = Convert Quote to Order                          */
    /*  6 = Invoice Order                                   */
    /*  7 = Order Reprint                                   */
    /*  8 = Copy Quote                                      */
    /*  9 = New Transfer                                    */
    /* 10 = Modify Transfer                                 */
    /* 11 = Confirm Transfer                                */
    /* 12 = LAY AWAY                                        */
    /********************************************************/
     
    IF   i-INVOICE-DATE  >= 11/01/2009 /* fecha de comienzo de la nueva ley*/
    AND (i-trans-type = "1"
    OR   i-trans-type = "2" 
    OR   i-trans-type = "3"  
    OR   i-TRANS-TYPE = "12" 
    OR   i-trans-type = "4"
    OR   i-trans-type = "6") THEN
    DO:
        
        IF  ivu-code = "NS"
        OR  ivu-code = "NC"
        OR  ivu-code = "NO" THEN
        DO:
            IF  ivu-exp-exe = ? THEN
            DO:
                /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
                
            END. /* IF  ivu-exp-exe = ? */
        END. /* IF  ivu-code = "NS" ... */
 
        IF  ivu-exp-exe <> ? 
        AND ivu-exp-exe < i-INVOICE-DATE THEN
        DO: 
            
            IF  ivu-code = "NS" 
            OR  ivu-code = "NO" THEN
            DO:
               
                ASSIGN 
                  io-CITY-TAX-EXEMPT  = NO
                  io-state-TAX-EXEMPT = NO
                  fecha-exempt-vencio = YES.
 
            END. /* IF ivu-code = "NS" OR ivu-code = "NO" */
            ELSE
            DO:  
                /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
                
            END.  /* else IF ivu-code = "NS" OR ivu-code = "NO" */
 
        END.  /* IF  ivu-exp-exe <> ? AND ivu-exp-exe < tmp-header.INVOICE-DATE */
        ELSE
            IF  ivu-exp-exe <> ? /*es fecha enque termina la exempt de IVU*/
            AND ivu-exp-exe - i-INVOICE-DATE <= 60 THEN
            DO:
                /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
                
            END.
 
    END.
    
    IF  sc2916-billing-date THEN
       THIS-OBJECT:VerifySC2916().
 
 
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID VerifySC2916():
    /*****----------------------------------------------*****/ 
    /* v e r i f y - s c 2 9 1 6                            */
    /*****----------------------------------------------*****/

    IF  sc2916-billing-date 
    AND (ivu-code = "NS" OR ivu-code = "NO")   THEN
    DO:
        IF  SC2916-EXP = ? THEN
        DO:            
            ASSIGN  fecha-exempt-vencio = YES.
                      
            IF  PUT-ON-HOLD THEN
              ASSIGN IVU-HOLD-CODE = "HOLD-IVU".
        END. /* IF  SC2916-EXP = ?  */
        
        ELSE
            IF  SC2916-EXP < TODAY THEN
            DO: 
                /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
                ASSIGN 
                fecha-exempt-vencio = YES.
            END. /* IF  SC2916-EXP < TODAY */

            ELSE
                IF  SC2916-EXP - TODAY  <= 60 THEN
                DO:
                    /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
                
                END. /* IF SC2916-EXP - TODAY <= 60 */
            
            IF  ivu-exp-exe = ? THEN
            DO:
                /* DISPLAY MESSAGE ONLY WHEN CALLING PROGRAM SEND YES */
                ASSIGN  
                fecha-exempt-vencio = YES.
 
                /* TO PLACE ORDERS ON HOLD WHEN IVU EXPIRED*/
                IF  PUT-ON-HOLD THEN
                    ASSIGN IVU-HOLD-CODE = "HOLD-IVU".
            END.
    END. /* IF  sc2916-billing-date */
 
  END METHOD.
    
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID OrderTaxExpireMain(INPUT  CUST-NUMBER     AS CHARACTER,
                                        INPUT  SHIP-TO-NO      AS CHARACTER,
                                        OUTPUT SHP-CODE        AS CHARACTER,
                                        OUTPUT SHP-EXP         AS DATE,
                                        OUTPUT SHP-SC2916-EXP  AS DATE):
                                            
     FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER = CUST-NUMBER AND 
         SHPTO.SHIP-NUMBER = SHIP-TO-NO  NO-LOCK NO-ERROR.
         
      IF AVAILABLE SHPTO THEN
      DO:
        ASSIGN 
          SHP-CODE       = IVU-TAX-CD
          SHP-EXP        = IVU-EXP
          SHP-SC2916-EXP = SC2916.
      END.
      
      ELSE SET SHP-CODE = ""  SHP-EXP = ?  SHP-SC2916-EXP = ?. 
  END METHOD.
    
END CLASS.