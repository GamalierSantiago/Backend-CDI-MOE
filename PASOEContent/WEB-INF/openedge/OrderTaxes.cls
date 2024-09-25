 
 /*------------------------------------------------------------------------
    File        : OrderTaxes
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : JKTECH
    Created     : Thu Feb 01 09:13:39 IST 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS OrderTaxes: 
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
   
  {CheckoutDef.i}  
  
  DEFINE PRIVATE TEMP-TABLE ttCustShippingAddress NO-UNDO
    FIELD customerNumber AS CHARACTER
    FIELD primaryAddress AS LOGICAL
    FIELD ship_number    LIKE SHPTO.SHIP-NUMBER
    FIELD addressL1      LIKE SHPTO.ADDRESS-L1
    FIELD addressL2      LIKE SHPTO.ADDRESS-L2 
    FIELD addressL3      LIKE SHPTO.ADDRESS-L3
    FIELD shipName       LIKE SHPTO.CUST-NAME
    FIELD shippingCity   LIKE CCSMS.PHYSICAL-CITY
    FIELD shippingState  LIKE CCSMS.PHYSICAL-STATE
    FIELD shippingZip    LIKE CCSMS.PHYSICAL-ZIP
    FIELD longitude      LIKE SHPTO.longitude
    FIELD latitude       LIKE SHPTO.latitude.
  
 /* DEFINE DATASET ordertaxes SERIALIZE-HIDDEN FOR TMP-HEADER, TMP-DETAIL, TMP-DETAIL-TAX
    DATA-RELATION drItemTaxDetails FOR TMP-DETAIL, TMP-DETAIL-TAX RELATION-FIELDS (ITEM-NUMBER, ITEM-NUMBER) NESTED FOREIGN-KEY-HIDDEN. */
  
    
  CONSTRUCTOR PUBLIC OrderTaxes ():
                          
  END CONSTRUCTOR.

  DEFINE PUBLIC  VARIABLE cToken           AS CHARACTER NO-UNDO.
  DEFINE PUBLIC  VARIABLE cTaxCalType      AS CHARACTER NO-UNDO.
  CONSTRUCTOR PUBLIC OrderTaxes (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
  END CONSTRUCTOR.
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID OrderTaxesMainBlock(INPUT DOC-NUMBER   AS CHARACTER,
                                         INPUT COMPANY      AS CHARACTER,
                                         INPUT WAREHOUSE-NO AS INTEGER,
                                         INPUT        TABLE TMP-HEADER,
                                         INPUT        TABLE TMP-DETAIL,
                                         INPUT-OUTPUT TABLE TMP-DETAIL-TAX,
                                         OUTPUT tmp_CITY_TAX_AMT  AS DECIMAL,
                                         OUTPUT tmp_STATE_TAX_AMT AS DECIMAL):
        
    THIS-OBJECT:DOC-NUMBER   = DOC-NUMBER.
    THIS-OBJECT:COMPANY      = COMPANY.
    THIS-OBJECT:WAREHOUSE-NO = WAREHOUSE-NO.
    
    THIS-OBJECT:Params().
    
    FIND TMP-HEADER WHERE TMP-HEADER.TMP-NUMBER EQ DOC-NUMBER NO-LOCK NO-ERROR.
    IF NOT AVAILABLE TMP-HEADER THEN RETURN. 
     
    ASSIGN
       TMP-HEADER.INVOICE-DATE = TODAY
       TMP-HEADER.alfa-2       = "2".
         
    ASSIGN 
      trans-type        = ENTRY(1,tmp-header.alfa-2, "," )
      CITY-TAXABLE-AMT  = 0
      CITY-OTHER-TAX    = 0
      CITY-regular-TAX  = 0
      STATE-TAXABLE-AMT = 0
      STATE-OTHER-TAX   = 0
      STATE-regular-TAX = 0.
     
    THIS-OBJECT:FindCustomer().
    
    IF tmp-header.SHIP-TO-NO NE " " THEN
        THIS-OBJECT:FindShipToData().
    
    THIS-OBJECT:VerifySalesTaxCd().
    
    IF NOT TMP-HEADER.CITY-TAX-EXEMPT THEN
      THIS-OBJECT:CalcCityTax().
     
    IF NOT TMP-HEADER.STATE-TAX-EXEMPT THEN
      THIS-OBJECT:CalcStateTax().
    
    TMP-HEADER.CITY-TAX-AMT  = THIS-OBJECT:tmp_CITY_TAX_AMT.
    TMP-HEADER.STATE-TAX-AMT = THIS-OBJECT:tmp_STATE_TAX_AMT.
    
    ASSIGN
      tmp_CITY_TAX_AMT  = THIS-OBJECT:tmp_CITY_TAX_AMT
      tmp_STATE_TAX_AMT = THIS-OBJECT:tmp_STATE_TAX_AMT.
     
  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID Params():
 
    /********************************************************/
    /* ON USE DATA FROM SHIP TO RECORD                      */
    /********************************************************/
    THIS-OBJECT:FindParamFl(INPUT "IVU-SIEMPRE-SHPTO").
    IVU-SIEMPRE-SHPTO = AVAILABLE paramfl.      
 
    FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                   AND PARAMFL.PARAM-ID     EQ "OETAXES-CLASS-CODE"
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    
    IF AVAILABLE PARAMFL THEN 
      ASSIGN 
        OETAXES-CLASS-CODE = PARAMFL.PARAM-VALUE1.
     
    ASSIGN 
      TENGO-CT-BB-tax-percent = NO
      TENGO-ST-BB-tax-percent = NO.
      
    /********************************************************/
    /* PARAMFL TO:                                          */
    /* identify line up for tax except items (eg labor)     */
    /* and sales-tax-code of the customers that do not pay  */
    /* tax these items (business to business)               */
    /* value1 = business to business customer sales tax code*/
    /* value2 = line up exception list labor = L            */
    /* value3 = city tax percent for B2B labor              */
    /* value4 = state tax percent for B2B labor             */
    /* value5 = other exceptions list                       */
    /*          F = Freight, M = Misc Charge                */
    /********************************************************/
    
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "oetaxes-labor" 
                   AND PARAMFL.COMPANY-CODE EQ COMPANY
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    
    IF AVAILABLE paramfl THEN
    DO:
      ASSIGN
        BB-cust-sales-tax-cd = PARAMFL.PARAM-VALUE1
        labor-line-up        = PARAMFL.PARAM-VALUE2
        CT-BB-tax-percent    = DEC(PARAMFL.PARAM-VALUE3)  
        ST-BB-tax-percent    = DEC(PARAMFL.PARAM-VALUE4)
        BB-dif-list          = PARAMFL.PARAM-VALUE5 NO-ERROR.
 
      IF PARAMFL.PARAM-VALUE3 NE "" THEN
        ASSIGN 
          TENGO-CT-BB-tax-percent = YES.
 
      IF PARAMFL.PARAM-VALUE4 NE "" THEN
        ASSIGN 
          TENGO-ST-BB-tax-percent = YES.
 
    END. /* IF AVAIL paramfl */
    
    IF BB-cust-sales-tax-cd EQ "" THEN
      ASSIGN 
        BB-cust-sales-tax-cd = "BB".
      
    IF labor-line-up EQ "" THEN
      ASSIGN 
        labor-line-up = "L".
 
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID FindParamFl(INPUT P-PARAM-ID AS CHARACTER):
    /*****----------------------------------------------*****/
    /* F I N D - P A R A M F L                              */
    /*****----------------------------------------------*****/
    
    FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ company
                   AND PARAMFL.PARAM-ID     EQ P-PARAM-ID
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.    
 
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID FindCustomer():
    /*****----------------------------------------------*****/
    /* f i n d - c u s t o m e r                            */
    /*****----------------------------------------------*****/
    
    ASSIGN
      selected-sales-tax-cd = "".     
         
    /********************************************************/
    /* read customer data                                   */
    /********************************************************/
    
    FIND ccsms WHERE ccsms.cust-number = tmp-header.cust-number NO-LOCK NO-ERROR.
    IF  AVAILABLE ccsms THEN
      ASSIGN 
        selected-sales-tax-cd = CCSMS.SALES-TAX-CD.  
 
    END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID FindShipToData():
    /*****----------------------------------------------*****/
    /* f i n d - s h p t o - d a t a                        */
    /*****----------------------------------------------*****/
    
    FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ tmp-header.cust-number 
                       AND SHPTO.SHIP-NUMBER EQ tmp-header.SHIP-TO-NO NO-LOCK NO-ERROR.
    IF AVAILABLE SHPTO THEN
    DO:
        ASSIGN 
          shpt-prev-ST-tax = SHPTO.shp-state-tax-pct 
          shpt-prev-CT-tax = SHPTO.shp-city-tax-pct.
        
        IF IVU-SIEMPRE-SHPTO THEN
        DO:  
          IF SHPTO.IVU-TAX-CD NE "" THEN     
            ASSIGN
              selected-sales-tax-cd = SHPTO.IVU-TAX-CD. 
        
        END.  /* IF IVU-SIEMPRE-SHPTO*/
         
    END. /* IF AVAIL SHPTO */
 
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID VerifySalesTaxCd():
    
    DEFINE VARIABLE objOrderTaxVerf AS CLASS OrderTaxVerf NO-UNDO.
    objOrderTaxVerf = NEW OrderTaxVerf(INPUT cToken).
    /*****----------------------------------------------*****/
    /* v e r i f y - s a l e s - t a x -c d                 */
    /*****----------------------------------------------*****/
     
    ASSIGN 
      io-CITY-TAX-EXEMPT  = tmp-header.CITY-TAX-EXEMPT   
      io-state-TAX-EXEMPT = tmp-header.state-TAX-EXEMPT.
     
        
    
    objOrderTaxVerf:OrderTaxVerfMainBlock(INPUT COMPANY ,                      
                                          INPUT tmp-header.cust-number ,                   
                                          INPUT tmp-header.SHIP-TO-NO ,   
                                          INPUT tmp-header.INVOICE-DATE ,
                                          INPUT trans-type ,
                                          INPUT "NO" ,
                                          INPUT-OUTPUT io-CITY-TAX-EXEMPT ,
                                          INPUT-OUTPUT io-state-TAX-EXEMPT ,
                                          INPUT-OUTPUT fecha-exempt-vencio ,
                                          INPUT-OUTPUT IVU-HOLD-CODE ,
                                          INPUT-OUTPUT tax-ret-val).
     
            
    ASSIGN
      cust-city-BB-tax-code  = NO
      cust-state-BB-tax-code = NO.
         
    IF LOOKUP(selected-sales-tax-cd, BB-cust-sales-tax-cd) NE 0 THEN 
      ASSIGN
        cust-city-BB-tax-code  = YES
        cust-state-BB-tax-code = YES.    
 
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID CalcCityTax():

    ASSIGN
      estoy-city-tax  = YES
      estoy-state-tax = NO.
 
    /* PARAMETRO CON EL PORCIENTO DE CITY TAX */
    
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "TAX-CITY-" + STRING(warehouse-NO,"99")
                   AND PARAMFL.COMPANY-CODE EQ COMPANY
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
 
    IF AVAILABLE PARAMFL THEN
    DO:
      ASSIGN
        TENGO-CT-LIMIT = NO
        CT-over-limit  = DECIMAL(PARAMFL.PARAM-VALUE2)
        CT-tax-percent = DECIMAL(PARAMFL.PARAM-VALUE1) NO-ERROR.
      
      IF  PARAMFL.PARAM-VALUE2 NE "" THEN
        ASSIGN
          TENGO-CT-LIMIT = YES.

      /* Certified contract(shipto) made before 7/1/2015 still pay previous tax (6%)*/
      IF shpt-prev-CT-tax NE 0 THEN
        ASSIGN  
          CT-tax-percent = shpt-prev-CT-tax.
         
      /********************************************************/
      /* process all items                                    */
      /********************************************************/
      
      FOR EACH TMP-DETAIL WHERE TMP-DETAIL.TMP-NUMBER  EQ DOC-NUMBER 
                            AND TMP-DETAIL.item-number NE "":            
        ASSIGN 
          CT-applied-pct = CT-tax-percent
          extended-price = TMP-DETAIL.EXTENSION.
         
        /********************************************************/
        /* find item data and tax rate (CT-applied-pct)         */
        /********************************************************/
        THIS-OBJECT:FindItemData().
 
        /********************************************************/
        /* item has a diferent tax rate                         */
        /* labor items are tax exempt for                       */
        /* business to business transactions                    */
        /********************************************************/
        IF cTaxCalType EQ "ForDispOnly" THEN  /* This is added because on the frontend the roundoff is not happening */
        DO:
            IF TENGO-CT-SP-ITEM-TAX-PCT THEN
            ASSIGN 
                CITY-OTHER-TAX = CITY-OTHER-TAX + (extended-price * (CT-applied-pct / 100)).  
          ELSE
            ASSIGN 
            CITY-TAXABLE-AMT = CITY-TAXABLE-AMT + extended-price
            CITY-regular-TAX = CITY-regular-TAX + (extended-price * (CT-applied-pct / 100)).  
 
          ASSIGN  
          TMP-DETAIL.dt-city-tax-pct = CT-applied-pct
          TMP-DETAIL.dt-city-tax-amt = (extended-price * (CT-applied-pct / 100)).
          tmp-prc-ext-city-tax       = extended-price. 
        END.
        ELSE 
        DO:
           IF TENGO-CT-SP-ITEM-TAX-PCT THEN
          ASSIGN 
            CITY-OTHER-TAX = CITY-OTHER-TAX + (ROUND(extended-price * (CT-applied-pct / 100),2)).  
          ELSE
            ASSIGN 
            CITY-TAXABLE-AMT = CITY-TAXABLE-AMT + extended-price
            CITY-regular-TAX = CITY-regular-TAX + (ROUND(extended-price * (CT-applied-pct / 100),2)).  
 
          ASSIGN  
          TMP-DETAIL.dt-city-tax-pct = CT-applied-pct
          TMP-DETAIL.dt-city-tax-amt = (ROUND(extended-price * (CT-applied-pct / 100),2)).
          tmp-prc-ext-city-tax       = extended-price. 
        END.    
        
 
        /********************************************************/
        /* create detail tax record                             */
        /********************************************************/
           
        THIS-OBJECT:AddUpdTmpDetailTax().
 
      END. /* for each TMP-DETAIL */
  
      ASSIGN                                                                             
        tmp_CITY_TAX_AMT = CITY-OTHER-TAX + CITY-regular-TAX. 
      
    END. /* IF AVAILABLE PARAMFL */

  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID FindItemData():
    /*****----------------------------------------------*****/
    /* f i n d - i t e m - d a t a                          */
    /*****----------------------------------------------*****/
    
    /*     Valid LINE UP are:                                               */
    /*     D = Discontinued                                                 */
    /*     L = Labor, can be sold but not purchased                         */
    /*     R = Can be purchased and sold                                    */
    /*     S = Can be sold but not purchased                                */
    /*     N = None Stock Item                                              */
    /*     W = Purchases Only From Main Warehouse                           */
    /*     C = Warehouse Set Component                                      */
    /*         Warehouse has separate items to compose a set at store level */
    /*     X = Store Set Component                                          */
    /*         All component of a set handled as an indivisible             */
    /*         item in the warehouse                                        */
    /*         At store each component can be sold as separate items        */
     
    ASSIGN 
      item-is-labor            = NO
      item-no-tax              = NO  
      TENGO-CT-SP-ITEM-TAX-PCT = NO 
      TENGO-ST-SP-ITEM-TAX-PCT = NO 
      CT-SP-ITEM-TAX-PCT       = 0 
      ST-SP-ITEM-TAX-PCT       = 0. 
     
    /********************************************************/
    /* find item data                                       */
    /********************************************************/
        
    FIND cinv1 WHERE cinv1.item-number  = TMP-DETAIL.item-number NO-LOCK NO-ERROR.
    IF AVAIL cinv1 THEN
    DO:
      IF LOOKUP(CINV1.LINE-UP,labor-line-up) <> 0 THEN 
        ASSIGN 
          item-is-labor = YES.
     
      /********************************************************/
      /*item is in B2B City tax labor lineup list apply that %*/
      /********************************************************/
          
      IF TENGO-CT-BB-tax-percent  THEN
      DO:
        IF cust-city-BB-tax-code THEN
        DO:
          IF item-is-labor = YES THEN
            ASSIGN 
              TENGO-CT-SP-ITEM-TAX-PCT = YES
              CT-SP-ITEM-TAX-PCT       = CT-BB-tax-percent.
                      
        END. /* IF cust-city-BB-tax-code */
     
      END. /* IF TENGO-CT-BB-tax-percent */
     
      /********************************************************/
      /*item is in B2B State tax labor lineup list apply that%*/
      /********************************************************/
          
      IF TENGO-ST-BB-tax-percent THEN
      DO:  
        IF cust-state-BB-tax-code THEN 
        DO:
          IF item-is-labor EQ YES THEN
            ASSIGN 
              TENGO-ST-SP-ITEM-TAX-PCT = YES
              ST-SP-ITEM-TAX-PCT       = ST-BB-tax-percent.
        END. /* IF cust-state-BB-tax-code */
     
      END. /* IF TENGO-ST-BB-tax-percent */
     
      /********************************************************/
      /* item in Dias sin IVU Class Code or Garantia Extendida*/
      /* Do not pay State or City Tax apply 0 percent         */
      /********************************************************/
          
      IF OETAXES-CLASS-CODE NE "" AND LOOKUP(CINV1.CLASS-CODE,OETAXES-CLASS-CODE) GT 0 THEN 
        ASSIGN 
          item-no-tax              = YES
          TENGO-CT-SP-ITEM-TAX-PCT = YES
          TENGO-ST-SP-ITEM-TAX-PCT = YES
          ST-SP-ITEM-TAX-PCT       = 0
          CT-SP-ITEM-TAX-PCT       = 0  
          extended-price           = 0.         
    
    END. /* IF AVAIL cinv1 */
     
    /********************************************************/
    /* find item state tax exception apply percent found    */
    /********************************************************/
    
    FIND CINV3 WHERE CINV3.ITEM-NUMBER EQ TMP-DETAIL.item-number 
                 AND cinv3.price-list  EQ "TAX-STATE"  NO-LOCK NO-ERROR.
   
    IF  AVAILABLE CINV3 THEN
      ASSIGN 
        TENGO-ST-SP-ITEM-TAX-PCT = YES
        ST-SP-ITEM-TAX-PCT       = CINV3.BREAK-PRICE.
   
    /********************************************************/
    /* find item city tax exception apply percent found     */
    /********************************************************/
    
    FIND CINV3 WHERE CINV3.ITEM-NUMBER EQ TMP-DETAIL.item-number
                 AND cinv3.price-list  EQ "TAX-CITY-" + STRING(warehouse-NO,"99") NO-LOCK NO-ERROR.
    IF  AVAILABLE CINV3 THEN
      ASSIGN 
        TENGO-CT-SP-ITEM-TAX-PCT = YES
        CT-SP-ITEM-TAX-PCT       = CINV3.BREAK-PRICE.  
     
    IF TENGO-CT-SP-ITEM-TAX-PCT  THEN
      ASSIGN 
        CT-applied-pct = CT-SP-ITEM-TAX-PCT. 
     
    IF TENGO-ST-SP-ITEM-TAX-PCT  THEN
      ASSIGN 
        ST-applied-pct = ST-SP-ITEM-TAX-PCT.  
 
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID AddUpdTmpDetailTax():
    
    /*****----------------------------------------------*****/
    /* a d d - u p d - t m p - d e t a i l - t a x          */
    /*****----------------------------------------------*****/

    /********************************************************/
    /* verify if tax record exist before creating it        */
    /********************************************************/
    
    FIND tmp-detail-tax WHERE tmp-detail-tax.TMP-NUMBER     = TMP-DETAIL.TMP-NUMBER
                          AND tmp-detail-tax.TMP-SEQ        = TMP-DETAIL.TMP-SEQ
                          AND tmp-detail-tax.ITEM-NUMBER    = TMP-DETAIL.ITEM-NUMBER NO-ERROR.
    
    IF NOT AVAIL tmp-detail-tax THEN
    DO:
      CREATE tmp-detail-tax.
      ASSIGN
        tmp-detail-tax.TMP-NUMBER   = TMP-DETAIL.TMP-NUMBER
        tmp-detail-tax.TMP-SEQ      = TMP-DETAIL.TMP-SEQ
        tmp-detail-tax.ITEM-NUMBER  = TMP-DETAIL.ITEM-NUMBER.
   
    END. /* IF NOT AVAIL tmp-detail-tax */
 
    IF estoy-city-tax  THEN
    DO:
      ASSIGN
        tmp-detail-tax.dt-prc-ext-city-tax  = tmp-prc-ext-city-tax
        tmp-detail-tax.dt-city-tax-pct      = TMP-DETAIL.dt-city-tax-pct
        tmp-detail-tax.dt-city-tax-amt      = ROUND((tmp-detail-tax.dt-prc-ext-city-tax     * (tmp-detail-tax.dt-city-tax-pct   / 100) ),2).
    END. /*  IF estoy-city-tax */
 
    IF estoy-state-tax THEN
    DO:
      ASSIGN
      tmp-detail-tax.dt-prc-ext-state-tax = tmp-prc-ext-state-tax
      tmp-detail-tax.dt-state-tax-pct     = TMP-DETAIL.dt-STATE-tax-pct
      tmp-detail-tax.dt-state-tax-amt     = ROUND((tmp-detail-tax.dt-prc-ext-state-tax    * (tmp-detail-tax.dt-state-tax-pct  / 100) ),2).
    END. /* IF estoy-state-tax */
 
  END METHOD.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID CalcStateTax():
    /*****----------------------------------------------*****/
    /* c a l c - s t a t e - t a x                          */
    /*****----------------------------------------------*****/
    
    ASSIGN
      estoy-city-tax  = NO
      estoy-state-tax = YES.
 
    /* PARAMETRO CON EL PORCIENTO DE IVU STATE TAX */
    
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "TAX-STATE" 
                   AND PARAMFL.COMPANY-CODE EQ COMPANY
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
 
    IF AVAILABLE PARAMFL THEN
    DO:
      ASSIGN
        TENGO-ST-LIMIT = NO
        st-over-limit  = DECIMAL(PARAMFL.PARAM-VALUE2)
        st-tax-percent = DECIMAL(PARAMFL.PARAM-VALUE1) NO-ERROR.
      
      IF PARAMFL.PARAM-VALUE2 NE "" THEN
        ASSIGN 
          TENGO-ST-LIMIT = YES.
      
      /* Certified contract(shipto) made before 7/1/2015 still pay previous tax (6%)*/
      IF shpt-prev-ST-tax NE 0 THEN
        ASSIGN  
          st-tax-percent =  shpt-prev-ST-tax.
 
 
        /********************************************************/
        /* PROCESS ALL ITEMS                                    */
        /********************************************************/
        FOR EACH TMP-DETAIL WHERE TMP-DETAIL.TMP-NUMBER  EQ DOC-NUMBER 
                              AND TMP-DETAIL.item-number NE "" :
            
          ASSIGN 
            ST-applied-pct = ST-tax-percent
            extended-price = TMP-DETAIL.EXTENSION.
            
          /********************************************************/
          /* find item data and tax rate (ST-applied-pct)         */
          /********************************************************/
            
          THIS-OBJECT:FindItemData().
 
          /********************************************************/
          /* item has a diferent tax rate                         */
          /* labor items are tax exempt for                       */
          /* business to business transactions                    */
          /********************************************************/
          IF cTaxCalType EQ "ForDispOnly" THEN /* This ia added because frontend is getting rounded valuse and creating tax issue to display */
          DO:
              IF TENGO-ST-SP-ITEM-TAX-PCT   THEN
                ASSIGN 
                  state-OTHER-TAX = state-OTHER-TAX + (extended-price * (ST-applied-pct / 100)). 
              ELSE
                ASSIGN 
                  state-TAXABLE-AMT = state-TAXABLE-AMT + extended-price
                  STATE-regular-TAX = STATE-regular-TAX + (extended-price * (ST-applied-pct / 100)).   
     
              ASSIGN 
                TMP-DETAIL.dt-STATE-tax-pct = ST-applied-pct
                TMP-DETAIL.dt-state-tax-amt = (extended-price * (ST-applied-pct / 100)).
                
              
          END.
          ELSE 
          DO:    
              IF TENGO-ST-SP-ITEM-TAX-PCT   THEN
                ASSIGN 
                  state-OTHER-TAX = state-OTHER-TAX + (ROUND(extended-price * (ST-applied-pct / 100),2)). 
              ELSE
                ASSIGN 
                  state-TAXABLE-AMT = state-TAXABLE-AMT + extended-price
                  STATE-regular-TAX = STATE-regular-TAX + (ROUND(extended-price * (ST-applied-pct / 100),2)).   
     
              ASSIGN 
                TMP-DETAIL.dt-STATE-tax-pct = ST-applied-pct
                TMP-DETAIL.dt-state-tax-amt = (ROUND(extended-price * (ST-applied-pct / 100),2)).
          END.            
          ASSIGN
            tmp-prc-ext-state-tax = extended-price.
            
          /********************************************************/
          /* create detail tax record                             */
          /********************************************************/
            
          THIS-OBJECT:AddUpdTmpDetailTax().
            
        END. /* FOR EACH TMP-DETAIL */        
 
        ASSIGN                                                                             
          tmp_STATE_TAX_AMT = STATE-OTHER-TAX + STATE-regular-TAX.  
 
    END. /* IF AVAILABLE PARAMFL */
 
  END METHOD.
  
  
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getItemTaxForShipping(INPUT ipcItemNumber       AS CHARACTER,
                                           INPUT ipcCompanyId        AS CHARACTER,
                                           INPUT ipcCustmerNumber    AS CHARACTER,
                                           INPUT ipiWarehouseNo      AS INTEGER,
                                           INPUT ipcShipTo           AS CHARACTER,
                                           INPUT ipdeUnitPrice       AS DECIMAL,
                                           OUTPUT oparrOrderTax      AS CLASS JsonArray):
                                               
/*    DEFINE VARIABLE inShipZip    AS INTEGER   NO-UNDO.*/
    DEFINE VARIABLE inShipZip    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE deFreightAmt AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deCityTax    AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deStateTax   AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE cError       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDelvStatus  AS CHARACTER NO-UNDO.
    
    DEF VARIABLE  io-CITY-TAX-EXEMPT      AS LOGICAL      NO-UNDO.
    DEF VARIABLE  io-state-TAX-EXEMPT     AS LOGICAL      NO-UNDO.
    DEF VARIABLE  fecha-exempt-vencio     AS LOGICAL      NO-UNDO. 
    DEF VARIABLE  IVU-HOLD-CODE           AS CHAR         NO-UNDO.
    DEF VARIABLE  TAX-RET-VAL             AS CHAR         NO-UNDO.
    
    DEFINE VARIABLE objShipingAddress AS CLASS SalesmanCustomersData   NO-UNDO.
    DEFINE VARIABLE orderTaxObj       AS CLASS JsonObject              NO-UNDO.   
    DEFINE VARIABLE Searchparamid     AS CHARACTER NO-UNDO.
        
    ASSIGN oparrOrderTax     = NEW JsonArray()
           objShipingAddress = NEW SalesmanCustomersData(INPUT cToken).
                    
    FIND PARAMFL WHERE PARAMFL.PARAM-ID EQ "tax-on-order":U
                   AND PARAMFL.COMPANY  EQ ipcCompanyId
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
    ASSIGN tax-on-order  = AVAILABLE PARAMFL
           ipdeUnitPrice = ROUND(ipdeUnitPrice, 2)
           cDelvStatus   = "D".
    
    objShipingAddress:getCustShippingAddress(INPUT  ipcCustmerNumber,
                                             INPUT ipcShipTo,
                                             OUTPUT cError,
                                             OUTPUT TABLE ttCustShippingAddress).
    
    IF CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustmerNumber) THEN
    DO: 
       cTaxCalType = "ForDispOnly".
       FOR EACH ttCustShippingAddress NO-LOCK:
         
         EMPTY TEMP-TABLE TMP-HEADER.
         EMPTY TEMP-TABLE TMP-DETAIL.
        
         ASSIGN orderTaxObj = NEW JsonObject().
         
         CREATE TMP-HEADER.
         ASSIGN TMP-HEADER.TMP-NUMBER  = "TMP-NUMBER"
                TMP-HEADER.CUST-NUMBER = ttCustShippingAddress.customerNumber
                TMP-HEADER.SHIP-TO-NO  = ttCustShippingAddress.ship_number NO-ERROR.
         
                                 
         CREATE TMP-DETAIL.
         ASSIGN TMP-DETAIL.TMP-NUMBER  = "TMP-NUMBER"
                TMP-DETAIL.ITEM-NUMBER = ipcItemNumber
                TMP-DETAIL.TMP-SEQ     = 1
                TMP-DETAIL.EXTENSION   = ipdeUnitPrice NO-ERROR.
         
         /* Check if the discount is applied to the item or not. If item is 
            available in the cart, calculate tax on cart unit price */
         find first token where Token.Token eq cToken no-lock no-error.
         if available token then 
         do:
/*             MESSAGE "OrderTaxes.cls- Token Available"*/
/*             VIEW-AS ALERT-BOX.                       */
         find last cartheader where CartHeader.Cust-Number eq ttCustShippingAddress.customerNumber 
                                 and CartHeader.Sales-Rep-ID eq Token.User-ID no-lock no-error.
         if available cartheader then 
         do:
/*             MESSAGE "OrderTaxes.cls- Cart Header available CartHeader.Cart-Id " CartHeader.Cart-Id*/
/*             VIEW-AS ALERT-BOX.                                                                    */
             find first cartdetail where CartDetail.Cart-ID eq CartHeader.Cart-Id
                                     and CartDetail.Item-Number eq ipcItemNumber no-lock no-error.
             if available cartdetail then 
              TMP-DETAIL.EXTENSION   = CartDetail.Unit-Price no-error. 
/*                                                                                                                              */
/*              MESSAGE "OrderTaxes.cls- Cartdetails TMP-DETAIL.EXTENSION " TMP-DETAIL.EXTENSION "ipcItemNumber= " ipcItemNumber*/
/*             VIEW-AS ALERT-BOX.                                                                                               */
         end.                          
         end. 
               
         IF tax-on-order THEN
           THIS-OBJECT:OrderTaxesMainBlock(INPUT "TMP-NUMBER",
                                           INPUT ipcCompanyId,
                                           INPUT ipiWarehouseNo,
                                           INPUT TABLE TMP-HEADER,
                                           INPUT TABLE TMP-DETAIL,
                                           INPUT-OUTPUT TABLE TMP-DETAIL-TAX,
                                           OUTPUT deCityTax,
                                           OUTPUT deStateTax).
                               
         orderTaxObj:ADD(INPUT "ship_number",    INPUT ttCustShippingAddress.ship_number).
         RUN oetaxverf.p(INPUT ipcCompanyId,
                         INPUT ipcCustmerNumber,
                         INPUT TMP-HEADER.SHIP-TO-NO,
                         INPUT ?,
                         INPUT "2",
                         INPUT "NO",
                         INPUT-OUTPUT   io-CITY-TAX-EXEMPT,
                         INPUT-OUTPUT   io-state-TAX-EXEMPT,
                         INPUT-OUTPUT   fecha-exempt-vencio,
                         INPUT-OUTPUT   IVU-HOLD-CODE,
                         INPUT-OUTPUT   TAX-RET-VAL).
         
         IF available token and Token.User-Type eq "mobileuser":u then 
         do:
            
            
            FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE EQ ipcCompanyId NO-LOCK NO-ERROR.
            IF AVAILABLE CMPNY THEN 
            DO:
                IF CMPNY.whs-location LT 9 THEN 
                 Searchparamid = "TAX-CITY-0" +  String(CMPNY.whs-location).
                ELSE 
                 Searchparamid = "TAX-CITY-" +  String(CMPNY.whs-location). 
            END.    
           
         
           FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID  begins Searchparamid 
                   AND PARAMFL.COMPANY-CODE EQ ipcCompanyId
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
           if available ParamFL then 
           DO:
               IF io-CITY-TAX-EXEMPT THEN 
                 orderTaxObj:ADD(INPUT "city_tax_unit",  INPUT 0.0).
               ELSE 
                 orderTaxObj:ADD(INPUT "city_tax_unit",  INPUT DECIMAL(PARAMFL.PARAM-VALUE1)).
           END. 
           ELSE 
             orderTaxObj:ADD(INPUT "city_tax_unit",  INPUT 0.0).    
         end.
         else
         DO:
           IF io-CITY-TAX-EXEMPT THEN 
            orderTaxObj:ADD(INPUT "city_tax_unit",  INPUT 0.0).
           ELSE  
           orderTaxObj:ADD(INPUT "city_tax_unit",  INPUT deCityTax).    
         END.     
         
         IF io-state-TAX-EXEMPT THEN 
         orderTaxObj:ADD(INPUT "state_tax_unit", INPUT 0).
         ELSE 
         DO:
              FIND PARAMFL WHERE PARAMFL.PARAM-ID  begins "TAX-STATE" 
                   AND PARAMFL.COMPANY-CODE EQ ipcCompanyId
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
           /* if available ParamFL then 
                orderTaxObj:ADD(INPUT "state_tax_unit", INPUT DECIMAL(PARAMFL.PARAM-VALUE1)).
           ELSE 
             DO:
                  IF available token and Token.User-Type eq "mobileuser":u then 
                    orderTaxObj:ADD(INPUT "state_tax_unit", INPUT TMP-DETAIL.dt-city-tax-pct ). 
                  ELSE 
                    orderTaxObj:ADD(INPUT "state_tax_unit", INPUT deStateTax).   
             END. */ 
             IF NOT AVAILABLE TMP-DETAIL THEN  
             DO:
                FIND FIRST TMP-DETAIL WHERE TMP-DETAIL.ITEM-NUMBER = ipcItemNumber NO-LOCK NO-ERROR.
                orderTaxObj:ADD(INPUT "state_tax_unit", INPUT TMP-DETAIL.dt-state-tax-pct ).
             END.     
             ELSE 
               orderTaxObj:ADD(INPUT "state_tax_unit", INPUT TMP-DETAIL.dt-state-tax-pct ).
             
         END. 
                  
/*         ASSIGN inShipZip = INTEGER(ttCustShippingAddress.shippingZip).*/
         ASSIGN inShipZip = ttCustShippingAddress.shippingZip.
         cTaxCalType = "".
         deFreightAmt = THIS-OBJECT:calcFreightUnitAmt(INPUT ipcItemNumber,
                                                       INPUT ipcCompanyId,
                                                       INPUT ipdeUnitPrice,
                                                       INPUT inShipZip,
                                                       INPUT cDelvStatus).
                                                    
         orderTaxObj:ADD(INPUT "freight_unit", INPUT deFreightAmt).
         oparrOrderTax:ADD(INPUT orderTaxObj).
              
       END.
       
    END.
                                                 
  END METHOD.
  
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  
  METHOD PUBLIC DECIMAL calcFreightUnitAmt(INPUT ipcItemNumber  AS CHARACTER,
                                           INPUT ipcCompanyId   AS CHARACTER,
                                           INPUT ipcTotalPrice  AS DECIMAL,
/*                                         INPUT ipiCustPhysZip AS INTEGER,*/
                                           INPUT ipiCustPhysZip AS CHARACTER,
                                           INPUT ipcDelvStatus  AS CHARACTER):
      
    DEFINE VARIABLE csp-freight-x  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE csp-freight-l  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE desp-freight-p AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE desp-freight-m AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deFreightAmt   AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE lsp-freight    AS LOGICAL   NO-UNDO.
      
    FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ ipcCompanyId
                   AND PARAMFL.PARAM-ID     EQ "SP-FREIGHT":U
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
   
    IF AVAILABLE PARAMFL THEN
      ASSIGN lsp-freight    = YES
             csp-freight-l  = PARAMFL.PARAM-VALUE1
             desp-freight-p = DECIMAL(PARAMFL.PARAM-VALUE2)
             desp-freight-m = DECIMAL(PARAMFL.PARAM-VALUE3)
             csp-freight-x  = PARAMFL.PARAM-VALUE5 NO-ERROR.
                 
    IF lsp-freight THEN
    DO:
      FIND CINV1 WHERE CINV1.ITEM-NUMBER EQ ipcItemNumber NO-LOCK NO-ERROR.
      IF NOT ((AVAILABLE CINV1 AND CINV1.LINE-UP EQ "L") OR 
                LOOKUP(ipiCustPhysZip, csp-freight-x) GT 0) THEN
/*              LOOKUP(STRING(ipiCustPhysZip,"99999"), csp-freight-x) GT 0) THEN*/
      DO:
        IF LOOKUP(ipcDelvStatus, csp-freight-l) GT 0 THEN 
          ASSIGN deFreightAmt = deFreightAmt + (ipcTotalPrice * desp-freight-p).
         
        IF deFreightAmt LT 0 THEN 
          ASSIGN deFreightAmt = 0.
      END.
              
      IF deFreightAmt GT desp-freight-m THEN 
        ASSIGN deFreightAmt = desp-freight-m.
              
    END. /* IF lsp-freight THEN */
      
    RETURN deFreightAmt.
      
  END METHOD. 
  
END CLASS.