 
 /*------------------------------------------------------------------------
    File        : CustomerOrders
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : JKTECH 
    Created     : Mon Sep 18 14:46:32 IST 2017
    Notes       : Version 1.1    
    History     :
    --------------------------------------------------------------------------------------
    Date(MM-DD-YY)            Author                Initial(XX-Version)    Description
                                                   
    -------------------------------------------------------------------------------------- 
  --------------------------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS CustomerOrders: 
 
 /* Temp-table to store open order details of a customer */   
  DEFINE PRIVATE TEMP-TABLE ttOpenOrder NO-UNDO
    FIELD orderNumber    LIKE COOHD.ORDER-NUMBER
    FIELD orderDate      LIKE COOHD.ORDER-DATE  
    FIELD openAmt        LIKE COODT.ORDERED-PRC
    FIELD customerNumber LIKE CCSMS.CUST-NUMBER
    FIELD customerName   AS CHARACTER.
 
  CONSTRUCTOR PUBLIC CustomerOrders ():
                         
    /*DEFINE VARIABLE oplcOrderHistory AS LONGCHAR  NO-UNDO.
    DEFINE VARIABLE opcError         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE opiStatusCode    AS INTEGER   NO-UNDO.
    
    THIS-OBJECT:customerOrderHistory(INPUT  "J008687",
                                     INPUT  "0",
                                     INPUT  "j",
                                     INPUT  1 ,
                                     INPUT  1 ,
                                     INPUT 0,
                                     INPUT "webuser",
                                     OUTPUT oplcOrderHistory,
                                     OUTPUT opcError,
                                     OUTPUT opiStatusCode).
                                     
    /*MESSAGE "Error" opcError STRING(oplcOrderHistory)
    VIEW-AS ALERT-BOX.*/                                 
    
    OUTPUT TO C:\Users\jkt-1\Desktop\orderHistory.txt.
    EXPORT oplcOrderHistory.
    
    OUTPUT CLOSE. */
          
  END CONSTRUCTOR.
  
   DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
   DEFINE PUBLIC  VARIABLE gvSales-rep AS CHARACTER NO-UNDO.
   DEFINE PUBLIC  VARIABLE gvUser-type AS CHARACTER NO-UNDO.
   DEFINE PUBLIC  VARIABLE lcAddress   AS CHARACTER NO-UNDO.
  CONSTRUCTOR PUBLIC CustomerOrders (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
    FIND FIRST token WHERE Token.Token = cToken NO-LOCK NO-ERROR.
    IF AVAILABLE token THEN 
    ASSIGN gvSales-rep = Token.User-ID
           gvUser-type = Token.User-Type.
  END CONSTRUCTOR.
    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID customerOrderHistory(INPUT  ipcCustNumber    AS CHARACTER,
                                          INPUT  ipcLangID        AS CHARACTER,
                                          INPUT  ipcCompanyID     AS CHARACTER,
                                          INPUT  ipiNoOfmonth     AS INTEGER,
                                          INPUT  ipcShipTo        AS CHARACTER,
                                          INPUT  ipiWareHouseNo   AS INTEGER,
                                          INPUT  ipiLastSyncTime  AS INT64,
                                          INPUT  cUserType        AS CHARACTER,
                                          OUTPUT oplcOrderHistory AS LONGCHAR,
                                          OUTPUT opcError         AS CHARACTER,
                                          OUTPUT opiStatusCode    AS INTEGER):
                                                   
   
    DEFINE VARIABLE opcLastXDays      AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE iDateRange        AS INTEGER       NO-UNDO.
    DEFINE VARIABLE deGrossAmount     AS DECIMAL       NO-UNDO.
    DEFINE VARIABLE cPriceList        AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE lPartiallyShip    AS LOGICAL       NO-UNDO.
    DEFINE VARIABLE lShipped          AS LOGICAL       NO-UNDO.
    DEFINE VARIABLE lClosed           AS LOGICAL       NO-UNDO.
    DEFINE VARIABLE lcSalesRep        AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE icCompanyId       AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE lcShipActive      AS LOGICAL       INITIAL yes.
    
    DEFINE VARIABLE objCommonSrc      AS CLASS CommonSource       NO-UNDO.
    DEFINE VARIABLE orderSummaryObj   AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE shippingObj       AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE billingObj        AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE orderJsonObj      AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE itemJsonObj       AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE orderJsonArray    AS CLASS JsonArray          NO-UNDO.
    DEFINE VARIABLE itemsArray        AS CLASS JsonArray          NO-UNDO.
    DEFINE VARIABLE ldStatetax AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldCitytax  AS DECIMAL   NO-UNDO.
    
   MESSAGE "En CustomerOrders  el ShipTo " STRING(ipcShipTo)
   VIEW-AS ALERT-BOX. 
  
   IF ipcShipTo <> ? THEN DO:
   ASSIGN lcShipActive =  NO.
   MESSAGE "lcShipActive = No"
   VIEW-AS ALERT-BOX.
   END.    
       
     
    ASSIGN objCommonSrc        = NEW CommonSource(INPUT cToken)
           orderSummaryObj     = NEW JsonObject()
           itemJsonObj         = NEW JsonObject() 
           shippingObj         = NEW JsonObject()
           billingObj          = NEW JsonObject()
           orderJsonObj        = NEW JsonObject()
           orderJsonArray      = NEW JsonArray()
           itemsArray          = NEW JsonArray().
                                                  
   
    FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE  = ipcCompanyID
                          AND PARAMFL.PARAM-ID     = "SALE-HISTORY-DAYS":U
                          AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
    IF AVAILABLE PARAMFL THEN 
      ASSIGN iDateRange = INTEGER(PARAMFL.PARAM-VALUE1) NO-ERROR.
    ELSE 
      ASSIGN iDateRange = 180.   
        
    IF ipiNoOfmonth = 3 THEN 
    iDateRange = 90.
    ELSE IF ipiNoOfmonth = 1 THEN 
     iDateRange = 30.
    
    FIND FIRST token WHERE Token.Token = ctoken NO-LOCK NO-ERROR. 
    IF AVAILABLE token THEN 
      ASSIGN lcSalesRep  = Token.User-ID
             icCompanyId = Token.Company-ID.
             
    FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
    IF AVAIL CCSMS THEN
    DO:    
      FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
        ASSIGN cPriceList = SHPTO.PRICE-LIST.
      ELSE
        ASSIGN cPriceList = CCSMS.PRICE-LIST.
    END. /* IF AVAIL CCSMS THEN  */
/*      MESSAGE "CustomerOrder.cls ipiLastSyncTime " ipiLastSyncTime.*/
    /* Logic for mobile user */
    
    IF cUserType EQ ConstantInitializer:cMobileUser THEN
    DO: 
      FOR EACH COOHD WHERE COOHD.ORDER-NUMBER BEGINS SUBSTRING (ipcCustNumber, 1,1)
                       AND COOHD.CUST-NUMBER  EQ ipcCustNumber
                       AND ((COOHD.SHIP-NUMBER  EQ ipcShipTo AND NOT lcShipActive) OR lcShipActive)
                       AND COOHD.ORDER-DATE   GE (TODAY - iDateRange)
                       AND COOHD.Timestamp    GT ipiLastSyncTime 
                       AND (COOHD.SALES-REP-ID EQ lcSalesRep OR COOHD.SALES-REP-ID EQ SUBSTRING (lcSalesRep, 2)) 
                       USE-INDEX ORDER-DATE NO-LOCK 
                       BY coohd.order-date  DESC BY coohd.order-number DESC:
       /* MESSAGE "Columnas de COOHD " skip
        "ipcCustNumber " ipcCustNumber skip
        "COOHD.CUST-NUMBER " COOHD.CUST-NUMBER SKIP
        //"ipiShipTo " ipiShipTo SKIP
        "COOHD.SHIP-NUMBER " COOHD.SHIP-NUMBER SKIP
        "COOHD.ORDER-NUMBER " COOHD.ORDER-NUMBER SKIP
        VIEW-AS ALERT-BOX.
        
        OUTPUT TO "P:\cdi-Mobile-app\ElForEachCOOHD.txt".
        DISPLAY  COOHD.ORDER-NUMBER COOHD.CUST-NUMBER COOHD.SHIP-NUMBER COOHD.CUST-NUMBER WITH 1 col.
        OUTPUT CLOSE.*/
        
        MESSAGE "Adentro del For each COOHD COOHD.CUST-NUMBER " COOHD.CUST-NUMBER skip
         "COOHD.SHIP-NUMBER " COOHD.SHIP-NUMBER
        VIEW-AS ALERT-BOX.
        
        ASSIGN orderSummaryObj = NEW JsonObject() 
               shippingObj     = NEW JsonObject()
               billingObj      = NEW JsonObject()
               orderJsonObj    = NEW JsonObject()
               itemsArray      = NEW JsonArray()
               deGrossAmount   = 0
               lPartiallyShip  = FALSE
               lShipped        = TRUE
               lClosed         = TRUE.
                     
        //orderSummaryObj:ADD(INPUT "order_total":U,  INPUT  IF COOHD.ORDER-AMOUNT EQ ? THEN 0 ELSE COOHD.ORDER-AMOUNT).
        orderSummaryObj:ADD(INPUT "pending_amount":U,  INPUT  IF COOHD.ORDER-AMOUNT EQ ? THEN 0 ELSE COOHD.ORDER-AMOUNT).
        orderSummaryObj:ADD(INPUT "shipping_tax":U, INPUT  COOHD.FREIGHT-AMT).
        orderSummaryObj:ADD(INPUT "city_tax":U,     INPUT 0).
        orderSummaryObj:ADD(INPUT "state_tax":U,    INPUT 0).
        ldCitytax = 0.
        ldStatetax = 0.      
        FOR EACH COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER NO-LOCK:
          
          IF CAN-FIND(FIRST coosz WHERE COOSZ.ORDER-NUMBER EQ COODT.ORDER-NUMBER 
                                    AND COOSZ.ORDER-SEQ    EQ COODT.ORDER-SEQ) THEN 
          DO:
            ASSIGN deGrossAmount = deGrossAmount + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY). /* avoided dulicate calculation where by-size*/
            
            FOR EACH coosz WHERE coosz.order-number EQ COODT.ORDER-NUMBER 
                             AND COOSZ.ORDER-SEQ    EQ COODT.ORDER-SEQ NO-LOCK:
                             
              ASSIGN itemJsonObj = NEW JsonObject().      
             
              IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*CITY-TAX*":U) THEN
              DO:
                ldCitytax = COODT.ORDERED-PRC.  
                orderSummaryObj:SET(INPUT "city_tax":U, INPUT COODT.ORDERED-PRC).
                NEXT. 
              END.
            
              IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*STATE-TAX*":U) THEN   
              DO:
                   ldStatetax = COODT.ORDERED-PRC.
                orderSummaryObj:SET(INPUT "state_tax":U, INPUT COODT.ORDERED-PRC).
                NEXT.
              END.
                             
              IF COODT.ORDER-QTY NE 0 THEN
              DO:
                 ASSIGN lClosed = FALSE. 
                 
                 IF COODT.DELIVERD-QTY NE 0 THEN
                   ASSIGN lPartiallyShip = TRUE.  
              END.
              
              IF COODT.DELIVERD-QTY LT COODT.ORIGINAL-QTY THEN
                ASSIGN lShipped = FALSE.
                       
              /* Populate/Get Item Json Object */
              THIS-OBJECT:getOrderedItem(INPUT COODT.ORDER-NUMBER,
                                         INPUT COODT.ITEM-NUMBER,
                                         INPUT COODT.ORDER-SEQ,
                                         INPUT COODT.DESCRIPTION,
                                         INPUT COOSZ.SIZE-QTY,
                                         INPUT coosz.size, 
                                         INPUT cPriceList,
                                         INPUT CCSMS.CUST-NUMBER,
                                         INPUT ipcCompanyID,
                                         INPUT ipiWarehouseNo,
                                         INPUT ipcShipTo,
                                         INPUT CCSMS.DISC-PERC,
                                         INPUT CCSMS.CONTRACT-IND,
                                         INPUT CCSMS.SPEC-DICT-I,
                                         INPUT CCSMS.QTY-BRK-CD,
                                         INPUT CCSMS.CUST-TYPE,
                                         OUTPUT itemJsonObj).
              
              itemJsonObj:ADD(INPUT "order_old_price":U, INPUT COODT.ORDERED-PRC).
              itemJsonObj:ADD(INPUT "shipped_on":U,      INPUT COOHD.DATE-WANTED). /* Need to be discussed */
                      
              itemsArray:ADD(itemJsonObj).
            END. /* FOR EACH COOSZ */
          
          END. /* IF CAN-FIND(FIRST coosz).. */
          
          /* For items without sizes - mobile */
          ELSE
          DO:
            ASSIGN itemJsonObj = NEW JsonObject().      
          
            IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*CITY-TAX*":U) THEN
            DO:
                ldCitytax = COODT.ORDERED-PRC.
              orderSummaryObj:SET(INPUT "city_tax":U, INPUT COODT.ORDERED-PRC).
              NEXT. 
            END.
            
            IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*STATE-TAX*":U) THEN   
            DO:
                ldstatetax = COODT.ORDERED-PRC.
              orderSummaryObj:SET(INPUT "state_tax":U, INPUT COODT.ORDERED-PRC).
              NEXT.
            END.
                           
            IF COODT.ORDER-QTY NE 0 THEN
            DO:
               ASSIGN lClosed = FALSE. 
               
               IF COODT.DELIVERD-QTY NE 0 THEN
                 ASSIGN lPartiallyShip = TRUE.  
            END.
            
            IF COODT.DELIVERD-QTY LT COODT.ORIGINAL-QTY THEN
              ASSIGN lShipped = FALSE.
              
            ASSIGN deGrossAmount = deGrossAmount + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY).
         
            /* Populate/Get Item Json Object */
            THIS-OBJECT:getOrderedItem(INPUT COODT.ORDER-NUMBER,
                                       INPUT COODT.ITEM-NUMBER,
                                       INPUT COODT.ORDER-SEQ,
                                       INPUT COODT.DESCRIPTION,
                                       INPUT COODT.ORIGINAL-QTY,
                                       INPUT "NOTAPPLICABLE", 
                                       INPUT cPriceList,
                                       INPUT CCSMS.CUST-NUMBER,
                                       INPUT ipcCompanyID,
                                       INPUT ipiWarehouseNo,
                                       INPUT ipcShipTo,
                                       INPUT CCSMS.DISC-PERC,
                                       INPUT CCSMS.CONTRACT-IND,
                                       INPUT CCSMS.SPEC-DICT-I,
                                       INPUT CCSMS.QTY-BRK-CD,
                                       INPUT CCSMS.CUST-TYPE,
                                       OUTPUT itemJsonObj).
            
            itemJsonObj:ADD(INPUT "order_old_price":U, INPUT COODT.ORDERED-PRC).
            itemJsonObj:ADD(INPUT "shipped_on":U,      INPUT COOHD.DATE-WANTED). /* Need to be discussed */
                    
            itemsArray:ADD(itemJsonObj).
            
          END. /* ELSE - Items without sizes */
           
        END. /* FOR EACH COODT... */  
        
        orderSummaryObj:ADD(INPUT "order_total":U,  INPUT  deGrossAmount + COOHD.FREIGHT-AMT + ldCitytax + ldstatetax).
        orderSummaryObj:ADD(INPUT "sub_total":U,   INPUT IF deGrossAmount EQ ? THEN 0 ELSE deGrossAmount).
        
        shippingObj:ADD(INPUT "ship_number":U,     INPUT  COOHD.alfa-1).
        
        lcAddress = REPLACE(COOHD.SHIP-ADDR-L1,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        shippingObj:ADD(INPUT "shipping_addL1":U,  INPUT  lcAddress).
        
        lcAddress = REPLACE(COOHD.SHIP-ADDR-L2,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        shippingObj:ADD(INPUT "shipping_addL2":U,  INPUT  lcAddress).
        
        lcAddress = REPLACE(COOHD.SHIP-ADDR-L3,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        shippingObj:ADD(INPUT "shipping_addL3":U,  INPUT  COOHD.SHIP-ADDR-L3).
        
        lcAddress = REPLACE(COOHD.ADDRESS-L1,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        billingObj:ADD(INPUT "billing_addL1":U,    INPUT  lcAddress).
        
        lcAddress = REPLACE(COOHD.ADDRESS-L2,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        billingObj:ADD(INPUT "billing_addL2":U,    INPUT  lcAddress).
        
        lcAddress = REPLACE(COOHD.ADDRESS-L3,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        billingObj:ADD(INPUT "billing_addL3":U,    INPUT  lcAddress).
        
        /* Constructing main order object */
        orderJsonObj:ADD(INPUT "order_number":U,   INPUT COOHD.ORDER-NUMBER).
        orderJsonObj:ADD(INPUT "order_date":U,     INPUT IF COOHD.ORDER-DATE = ? THEN TODAY - 7  ELSE COOHD.ORDER-DATE ).
        orderJsonObj:ADD(INPUT "order_status":U,   INPUT "":U).
              
        IF lPartiallyShip THEN
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "partially shipped":U).
        ELSE
        DO: 
            IF COOHD.ORDER-AMOUNT GT 0 THEN 
              orderJsonObj:SET(INPUT "order_status":U,  INPUT "open":U).
            ELSE 
              orderJsonObj:SET(INPUT "order_status":U,  INPUT "closed":U). 
        END.
       
        /* Closed order status has higher priority then shipped */
        IF lClosed THEN
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "closed":U).
        
        IF lShipped AND NOT lClosed THEN
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "shipped":U).   
        
        IF COOHD.BOOKED-IND BEGINS "CANCEL":U THEN
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "cancelled":U).
        MESSAGE "orderjsonobj" orderJsonObj
        VIEW-AS ALERT-BOX.
        IF COOHD.DATE-WANTED NE ? THEN
          orderJsonObj:ADD(INPUT "date_wanted":U, INPUT COOHD.DATE-WANTED).
                   
        /* Adding sub-objects into the main order object */  
        orderJsonObj:ADD(INPUT "order_summary":U, INPUT orderSummaryObj).
        orderJsonObj:ADD(INPUT "shipping_info":U, INPUT shippingObj).
        orderJsonObj:ADD(INPUT "billing_info":U,  INPUT billingObj).
        orderJsonObj:ADD(INPUT "items_ordered":U, INPUT itemsArray).
        //Gama
       /* MESSAGE "Como se crea el objeto? " skip
        "orderJsonObj " string(orderJsonObj)
        VIEW-AS ALERT-BOX.*/
        
        orderJsonArray:ADD(orderJsonObj).
        
      /*  MESSAGE "orderJsonArray " string(orderJsonArray)
        VIEW-AS ALERT-BOX.*/
        
      END. /* FOR EACH COOHD..*/
    END. /* If ConstantInitializer:cMobileUser then */
    
    /* Logic for Web user */
    ELSE 
    DO:
      FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE  = ipcCompanyID
                          AND PARAMFL.PARAM-ID     = "SALE-HISTORY-DAYS":U
                          AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
      IF AVAILABLE PARAMFL THEN 
        ASSIGN iDateRange = INTEGER(PARAMFL.PARAM-VALUE1) NO-ERROR.
      ELSE 
      ASSIGN iDateRange = 180.
       
    /*  FOR EACH COOHD WHERE COOHD.CUST-NUMBER EQ ipcCustNumber
                       AND COOHD.ORDER-DATE  GE (TODAY - iDateRange)
                       NO-LOCK BY coohd.order-date DESC BY coohd.order-number DESC:
                           */
      FOR EACH COOHD WHERE COOHD.ORDER-NUMBER BEGINS SUBSTRING (ipcCustNumber, 1,1)
                       AND COOHD.CUST-NUMBER  EQ ipcCustNumber
                       AND COOHD.ORDER-DATE   GE (TODAY - iDateRange)
/*                       AND COOHD.Timestamp    GT ipiLastSyncTime                                                */
/*                       AND (COOHD.SALES-REP-ID EQ lcSalesRep OR COOHD.SALES-REP-ID EQ SUBSTRING (lcSalesRep, 2))*/
                       USE-INDEX ORDER-DATE NO-LOCK 
                       BY coohd.order-date  DESC BY coohd.order-number DESC:                     
        
        ASSIGN orderSummaryObj = NEW JsonObject() 
               shippingObj     = NEW JsonObject()
               billingObj      = NEW JsonObject()
               orderJsonObj    = NEW JsonObject()
               itemsArray      = NEW JsonArray().
               
        ASSIGN deGrossAmount  = 0
               lPartiallyShip = FALSE
               lShipped       = TRUE
               lClosed        = TRUE.
                     
        // orderSummaryObj:ADD(INPUT "order_total":U,  INPUT  IF COOHD.ORDER-AMOUNT EQ ? THEN 0 ELSE COOHD.ORDER-AMOUNT).
        orderSummaryObj:ADD(INPUT "pending_amount":U,  INPUT  IF COOHD.ORDER-AMOUNT EQ ? THEN 0 ELSE COOHD.ORDER-AMOUNT).
        orderSummaryObj:ADD(INPUT "shipping_tax":U, INPUT  COOHD.FREIGHT-AMT).
        orderSummaryObj:ADD(INPUT "city_tax":U,     INPUT 0).
        orderSummaryObj:ADD(INPUT "state_tax":U,    INPUT 0).
        ldCitytax = 0.
        ldStatetax = 0.       
        FOR EACH COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER NO-LOCK:
          
          IF CAN-FIND(FIRST coosz WHERE COOSZ.ORDER-NUMBER EQ COODT.ORDER-NUMBER 
                                    AND COOSZ.ORDER-SEQ    EQ COODT.ORDER-SEQ) THEN 
          DO:
            ASSIGN deGrossAmount = deGrossAmount + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY). /* avoided dulicate calculation where by-size*/
            
            FOR EACH coosz WHERE coosz.order-number EQ COODT.ORDER-NUMBER 
                             AND COOSZ.ORDER-SEQ    EQ COODT.ORDER-SEQ NO-LOCK:
                               
              ASSIGN itemJsonObj = NEW JsonObject().                            
              
              IF COODT.ITEM-NUMBER EQ (ipcCompanyID + "*CITY-TAX*":U) THEN
              DO:
                  ldCitytax = COODT.ORDERED-PRC.
                orderSummaryObj:SET(INPUT "city_tax":U, INPUT COODT.ORDERED-PRC).
                NEXT. 
              END.
              
              IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*STATE-TAX*":U) THEN   
              DO:
                  ldStatetax = COODT.ORDERED-PRC.
                orderSummaryObj:SET(INPUT "state_tax":U, INPUT COODT.ORDERED-PRC).
                NEXT.
              END.
                             
              IF COODT.ORDER-QTY NE 0 THEN
              DO:
                 ASSIGN lClosed = FALSE. 
                 
                 IF COODT.DELIVERD-QTY NE 0 THEN
                   ASSIGN lPartiallyShip = TRUE.  
              END.
              
              IF COODT.DELIVERD-QTY LT COODT.ORIGINAL-QTY THEN
                ASSIGN lShipped = FALSE.
                
              //ASSIGN deGrossAmount = deGrossAmount + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY).  test getting duplicate
           
              /* Get Item Json Object */
              THIS-OBJECT:getOrderedItem(INPUT COODT.ORDER-NUMBER,
                                         INPUT COODT.ITEM-NUMBER,
                                         INPUT COODT.ORDER-SEQ,
                                         INPUT COODT.DESCRIPTION,
                                         INPUT COOSZ.SIZE-QTY,
                                         INPUT coosz.size, 
                                         INPUT cPriceList,
                                         INPUT CCSMS.CUST-NUMBER,
                                         INPUT ipcCompanyID,
                                         INPUT ipiWarehouseNo,
                                         INPUT ipcShipTo,
                                         INPUT CCSMS.DISC-PERC,
                                         INPUT CCSMS.CONTRACT-IND,
                                         INPUT CCSMS.SPEC-DICT-I,
                                         INPUT CCSMS.QTY-BRK-CD,
                                         INPUT CCSMS.CUST-TYPE,
                                         OUTPUT itemJsonObj).
              
              itemJsonObj:ADD(INPUT "order_old_price":U, INPUT COODT.ORDERED-PRC).
              itemJsonObj:ADD(INPUT "shipped_on":U,      INPUT COOHD.DATE-WANTED). /* Need to be discussed */
                      
              itemsArray:ADD(itemJsonObj).
            END. /* for each coosz */ 
          END. /* IF CAN-FIND(first coosz).. */
          
          /* items withouts sizes */
          ELSE
          DO:
            ASSIGN itemJsonObj = NEW JsonObject().      
          
            IF COODT.ITEM-NUMBER EQ (ipcCompanyID + "*CITY-TAX*":U) THEN
            DO:
                ldCitytax = COODT.ORDERED-PRC.
              orderSummaryObj:SET(INPUT "city_tax":U, INPUT COODT.ORDERED-PRC).
              NEXT. 
            END.
            
            IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*STATE-TAX*":U) THEN   
            DO:
                ldstatetax = COODT.ORDERED-PRC.
              orderSummaryObj:SET(INPUT "state_tax":U, INPUT COODT.ORDERED-PRC).
              NEXT.
            END.
                           
            IF COODT.ORDER-QTY NE 0 THEN
            DO:
               ASSIGN lClosed = FALSE. 
               
               IF COODT.DELIVERD-QTY NE 0 THEN
                 ASSIGN lPartiallyShip = TRUE.  
            END.
            
            IF COODT.DELIVERD-QTY LT COODT.ORIGINAL-QTY THEN
              ASSIGN lShipped = FALSE.
              
            ASSIGN deGrossAmount = deGrossAmount + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY). 
         
            /* Get Item Json Object */
            THIS-OBJECT:getOrderedItem(INPUT COODT.ORDER-NUMBER,
                                       INPUT COODT.ITEM-NUMBER,
                                       INPUT COODT.ORDER-SEQ,
                                       INPUT COODT.DESCRIPTION,
                                       INPUT COODT.ORIGINAL-QTY,
                                       INPUT "NOTAPPLICABLE", 
                                       INPUT cPriceList,
                                       INPUT CCSMS.CUST-NUMBER,
                                       INPUT ipcCompanyID,
                                       INPUT ipiWarehouseNo,
                                       INPUT ipcShipTo,
                                       INPUT CCSMS.DISC-PERC,
                                       INPUT CCSMS.CONTRACT-IND,
                                       INPUT CCSMS.SPEC-DICT-I,
                                       INPUT CCSMS.QTY-BRK-CD,
                                       INPUT CCSMS.CUST-TYPE,
                                       OUTPUT itemJsonObj).
            
            itemJsonObj:ADD(INPUT "order_old_price":U, INPUT COODT.ORDERED-PRC).
            itemJsonObj:ADD(INPUT "shipped_on":U,      INPUT COOHD.DATE-WANTED). /* Need to be discussed */
                    
            itemsArray:ADD(itemJsonObj). 
          END. /*(ELSE - ID CAN-FIND COOSZ)*/
          
          
        END. /* FOR EACH COODT... */  
        orderSummaryObj:ADD(INPUT "order_total":U,  INPUT  deGrossAmount + COOHD.FREIGHT-AMT + ldCitytax + ldstatetax).
        orderSummaryObj:ADD(INPUT "sub_total":U,   INPUT IF deGrossAmount EQ ? THEN 0 ELSE deGrossAmount).
        
        shippingObj:ADD(INPUT "ship_number":U,    INPUT  COOHD.alfa-1).
        
        lcAddress = REPLACE(COOHD.SHIP-ADDR-L1,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        shippingObj:ADD(INPUT "shipping_addL1":U, INPUT  COOHD.SHIP-ADDR-L1).
        
        lcAddress = REPLACE(COOHD.SHIP-ADDR-L2,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        shippingObj:ADD(INPUT "shipping_addL2":U, INPUT  COOHD.SHIP-ADDR-L2).
        
        lcAddress = REPLACE(COOHD.SHIP-ADDR-L3,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        shippingObj:ADD(INPUT "shipping_addL3":U, INPUT  COOHD.SHIP-ADDR-L3).
        
        lcAddress = REPLACE(COOHD.ADDRESS-L1,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        billingObj:ADD(INPUT "billing_addL1":U,  INPUT  lcAddress).
        
        lcAddress = REPLACE(COOHD.ADDRESS-L2,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        billingObj:ADD(INPUT "billing_addL2":U,  INPUT  lcAddress).
        
        lcAddress = REPLACE(COOHD.ADDRESS-L3,"'", "").
        lcAddress = REPLACE(lcAddress,'"', '').
        lcAddress = REPLACE(lcAddress,"/", "").
        lcAddress = REPLACE(lcAddress,"\", "").
        
        billingObj:ADD(INPUT "billing_addL3":U,  INPUT  lcAddress).
        
        /* Constructing main order object */
        orderJsonObj:ADD(INPUT "order_number":U,  INPUT COOHD.ORDER-NUMBER).
        orderJsonObj:ADD(INPUT "order_date":U,    INPUT COOHD.ORDER-DATE).
        orderJsonObj:ADD(INPUT "order_status":U,  INPUT "":U).
              
        IF lPartiallyShip THEN
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "partially shipped":U).
        ELSE
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "open":U). 
        
        /* Closed order status has higher priority then shipped */
        IF lClosed THEN
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "closed":U).
        
        IF lShipped AND NOT lClosed THEN
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "shipped":U).   
        
        IF COOHD.BOOKED-IND BEGINS "CANCEL":U THEN
          orderJsonObj:SET(INPUT "order_status":U,  INPUT "cancelled":U).
        
        IF COOHD.DATE-WANTED NE ? THEN
          orderJsonObj:ADD(INPUT "date_wanted":U, INPUT COOHD.DATE-WANTED).
                   
        /* Adding sub-objects into the main order object */  
        orderJsonObj:ADD(INPUT "order_summary":U, INPUT orderSummaryObj).
        orderJsonObj:ADD(INPUT "shipping_info":U, INPUT shippingObj).
        orderJsonObj:ADD(INPUT "billing_info":U,  INPUT billingObj).
        orderJsonObj:ADD(INPUT "items_ordered":U, INPUT itemsArray).
        
        orderJsonArray:ADD(orderJsonObj).
        
      END. /* FOR EACH COOHD..*/
    END. /* ELSE - Mobile user, logic for web user */
    
    ASSIGN oplcOrderHistory = orderJsonArray:GetJsonText().
    
    //Gama
    /*MESSAGE "oplcOrderHistory " STRING(oplcOrderHistory)
    VIEW-AS ALERT-BOX.*/
    
    IF orderJsonArray:Length EQ 0 THEN
    DO:
      /*Get multilingual message for No order history available */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200NoOrderHistory,                                                              
                               OUTPUT opcError,
                               OUTPUT opiStatusCode).
                                  
      IF opcError NE "":U THEN 
        UNDO,THROW NEW AppError(opcError,1).
    END.  
       
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      
      INPUT CLOSE.
              
      IF VALID-OBJECT(orderJsonArray) THEN
        DELETE OBJECT orderJsonArray.
      
      IF VALID-OBJECT(orderJsonObj) THEN
        DELETE OBJECT orderJsonObj.
      
      IF VALID-OBJECT(billingObj) THEN
        DELETE OBJECT billingObj.
      
      IF VALID-OBJECT(shippingObj) THEN
        DELETE OBJECT shippingObj.
      
      IF VALID-OBJECT(orderSummaryObj) THEN
        DELETE OBJECT orderSummaryObj.
      
      IF VALID-OBJECT(itemsArray) THEN
        DELETE OBJECT itemsArray.
      
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
                
      IF VALID-OBJECT(itemJsonObj) THEN
        DELETE OBJECT itemJsonObj.  
              
    END FINALLY.
    
  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose: This method returns total open order's details of a customer.
   Input Parameters :1.ipcCustNum - Custmer Number,
                     2.ipcLangID  - language id.
                     
   Output Parameters:1.ttOpenOrder          - Open Order Details,
                     2.opdeTotalOpenOrdrAmt - sum of amount of total open orders,
                     3.opiTotalOrdrs        - count of total oopen orders,
                     4.cError               - errors if any,
                     5.opiStatusCode        - HTTP response code.
   Notes:
  ------------------------------------------------------------------------------*/     
  METHOD PUBLIC VOID getCustOpenOrdrInfo(INPUT  ipcCustNum           AS CHARACTER, 
                                         INPUT  ipcLangID            AS CHARACTER,
                                         INPUT  ipcCompanyCode       AS CHARACTER,
                                         OUTPUT TABLE ttOpenOrder,
                                         OUTPUT opdeTotalOpenOrdrAmt AS DECIMAL,
                                         OUTPUT opiTotalOrdrs        AS INTEGER,
                                         OUTPUT cError               AS CHARACTER,
                                         OUTPUT opiStatusCode        AS INTEGER):
    
    DEFINE VARIABLE oplOrdStatus  AS LOGICAL            NO-UNDO.
    DEFINE VARIABLE opcOpenOrdAmt AS DECIMAL            NO-UNDO.
    DEFINE VARIABLE lcSalesRep    AS CHARACTER          NO-UNDO.
    DEFINE VARIABLE icCompanyId   AS CHARACTER          NO-UNDO.
    DEFINE VARIABLE iDateRange    AS INTEGER            NO-UNDO.
    
   FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE  = ipcCompanyCode
                          AND PARAMFL.PARAM-ID     = "SALE-HISTORY-DAYS":U
                          AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
    IF AVAILABLE PARAMFL THEN 
      ASSIGN iDateRange = INTEGER(PARAMFL.PARAM-VALUE1) NO-ERROR.
    ELSE  
      ASSIGN iDateRange = 180.   
    
   FIND FIRST token WHERE Token.Token = ctoken NO-LOCK NO-ERROR. 
    IF AVAILABLE token THEN 
      ASSIGN lcSalesRep  = Token.User-ID
             icCompanyId = Token.Company-ID.
               
   IF gvUser-type EQ "mobileuser" THEN 
   DO:
   /* FOR EACH COOHD NO-LOCK WHERE COOHD.CUST-NUMBER = ipcCustNum 
                            AND COOHD.SALES-REP-ID = gvSales-rep
                            AND COOHD.ORDER-NUMBER BEGINS ipcCompanyCode BY COOHD.ORDER-DATE DESC: */
                            
                            //Gama le anadio el paramfl y la condicion.
                            
    DEFINE VARIABLE willShowAllCustomers AS LOGICAL NO-UNDO.
    FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID BEGINS "OE-SALES-OPERATOR" AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    willShowAllCustomers = AVAIL PARAMFL.                        
                                
    FOR EACH COOHD WHERE COOHD.ORDER-NUMBER BEGINS SUBSTRING (ipcCustNum, 1,1)
                       AND COOHD.CUST-NUMBER  EQ ipcCustNum
                       AND COOHD.ORDER-DATE   GE (TODAY - iDateRange)
                       //AND (COOHD.SALES-REP-ID EQ lcSalesRep OR COOHD.SALES-REP-ID EQ SUBSTRING (lcSalesRep, 2))
                       AND (((COOHD.SALES-REP-ID EQ lcSalesRep OR COOHD.SALES-REP-ID EQ SUBSTRING(lcSalesRep, 2)) AND NOT willShowAllCustomers) OR willShowAllCustomers) 
                       USE-INDEX ORDER-DATE NO-LOCK 
                       BY coohd.order-date  DESC BY coohd.order-number DESC:  
       
      /* This method check if an order is open or not for the customer */       
      THIS-OBJECT:checkOpenOrdr(INPUT  COOHD.ORDER-NUMBER,
                                INPUT  ipcLangID,
                                INPUT  ipcCompanyCode,
                                OUTPUT oplOrdStatus, 
                                OUTPUT opcOpenOrdAmt,
                                OUTPUT cError,
                                OUTPUT opiStatusCode).     
       
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1). 
           
      /* If open order status is true */
      IF oplOrdStatus AND  COOHD.ORDER-AMOUNT GT 0 THEN
      DO:
                      
        IF opcOpenOrdAmt NE 0 AND opcOpenOrdAmt NE ? THEN
        DO: 
           // IF COOHD.ORDER-AMOUNT GT 0 THEN 
              ASSIGN opdeTotalOpenOrdrAmt = opdeTotalOpenOrdrAmt + COOHD.ORDER-AMOUNT. // Modified as per Wanda
            //ASSIGN opdeTotalOpenOrdrAmt = opdeTotalOpenOrdrAmt + opcOpenOrdAmt.
        END.       
          
        IF NOT CAN-FIND(FIRST ttOpenOrder WHERE ttOpenOrder.customerNumber EQ ipcCustNum 
                                            AND ttOpenOrder.orderNumber    EQ COOHD.ORDER-NUMBER) THEN
        DO:    
          FIND FIRST ccsms WHERE CCSMS.CUST-NUMBER EQ ipcCustNum NO-LOCK NO-ERROR.       
          CREATE ttOpenOrder.
          ASSIGN 
            ttOpenOrder.customerNumber = ipcCustNum
            ttOpenOrder.orderNumber    = COOHD.ORDER-NUMBER
            ttOpenOrder.orderDate      = COOHD.ORDER-DATE  
            ttOpenOrder.openAmt        =  COOHD.ORDER-AMOUNT  //IF opcOpenOrdAmt EQ ? THEN 0.0 ELSE opcOpenOrdAmt NO-ERROR.
            ttOpenOrder.CustomerName   = IF AVAILABLE ccsms THEN REPLACE(CCSMS.CUST-NAME,"'", "")  ELSE " No Name" .
            opiTotalOrdrs = opiTotalOrdrs + 1.
        END. /*  IF NOT CAN-FIND(FIRST ttOpenOrder... */
        ELSE
        DO:
          FIND FIRST ttOpenOrder WHERE ttOpenOrder.customerNumber EQ ipcCustNum 
                                   AND ttOpenOrder.orderNumber    EQ COOHD.ORDER-NUMBER.
          
          IF opcOpenOrdAmt NE ? THEN 
            ASSIGN ttOpenOrder.openAmt = ttOpenOrder.openAmt + COOHD.ORDER-AMOUNT. // ttOpenOrder.openAmt + opcOpenOrdAmt.
          
        END. /* ElSE IF NOT CAN-FIND(FIRST ttOpenOrder...  */
      END. /* IF oplOrdStatus.. */
    END. /* FOR EACH COOHD */  
   END. 
   ELSE 
   DO:
       FOR EACH COOHD NO-LOCK WHERE COOHD.CUST-NUMBER = ipcCustNum 
                           AND COOHD.ORDER-NUMBER BEGINS ipcCompanyCode BY COOHD.ORDER-DATE DESC:
                                
      
        
      /* This method check if an order is open or not for the customer */       
      THIS-OBJECT:checkOpenOrdr(INPUT  COOHD.ORDER-NUMBER,
                                INPUT  ipcLangID,
                                INPUT  ipcCompanyCode,
                                OUTPUT oplOrdStatus, 
                                OUTPUT opcOpenOrdAmt,
                                OUTPUT cError,
                                OUTPUT opiStatusCode).     
       
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1). 
           
      /* If open order status is true */
      //IF oplOrdStatus AND  COOHD.ORDER-AMOUNT GT 0 THEN
      IF  COOHD.ORDER-AMOUNT GT 0 THEN
      DO:
                      
        IF opcOpenOrdAmt NE 0 AND opcOpenOrdAmt NE ? THEN
        DO:
           // IF COOHD.ORDER-AMOUNT GT 0 THEN 
              ASSIGN opdeTotalOpenOrdrAmt = opdeTotalOpenOrdrAmt + COOHD.ORDER-AMOUNT. // Modified as per Wanda
            //ASSIGN opdeTotalOpenOrdrAmt = opdeTotalOpenOrdrAmt + opcOpenOrdAmt.
        END.       
          
        IF NOT CAN-FIND(FIRST ttOpenOrder WHERE ttOpenOrder.customerNumber EQ ipcCustNum 
                                            AND ttOpenOrder.orderNumber    EQ COOHD.ORDER-NUMBER) THEN
        DO:    
          FIND FIRST ccsms WHERE CCSMS.CUST-NUMBER EQ ipcCustNum NO-LOCK NO-ERROR.       
          CREATE ttOpenOrder.
          ASSIGN 
            ttOpenOrder.customerNumber = ipcCustNum
            ttOpenOrder.orderNumber    = COOHD.ORDER-NUMBER
            ttOpenOrder.orderDate      = COOHD.ORDER-DATE  
            ttOpenOrder.openAmt        =  COOHD.ORDER-AMOUNT  //IF opcOpenOrdAmt EQ ? THEN 0.0 ELSE opcOpenOrdAmt NO-ERROR.
            ttOpenOrder.CustomerName   = IF AVAILABLE ccsms THEN REPLACE(CCSMS.CUST-NAME,"'", "") ELSE " No Name" .
            opiTotalOrdrs = opiTotalOrdrs + 1.
        END. /*  IF NOT CAN-FIND(FIRST ttOpenOrder... */
        ELSE
        DO:
          FIND FIRST ttOpenOrder WHERE ttOpenOrder.customerNumber EQ ipcCustNum 
                                   AND ttOpenOrder.orderNumber    EQ COOHD.ORDER-NUMBER.
          
          IF opcOpenOrdAmt NE ? THEN 
            ASSIGN ttOpenOrder.openAmt = ttOpenOrder.openAmt + COOHD.ORDER-AMOUNT. // ttOpenOrder.openAmt + opcOpenOrdAmt.
          
        END. /* ElSE IF NOT CAN-FIND(FIRST ttOpenOrder...  */
      END. /* IF oplOrdStatus.. */
    END. /* FOR EACH COOHD */  
   END.    
    /* Undeployed code */
  
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError = errorObj:GetMessage(1).
    END CATCH.
                            
  END METHOD.
 
  
  /*------------------------------------------------------------------------------
   Purpose: This method is checking if an order is open or close.
   Input Parameters: 1.ipcOrdNum - Order Number,
                     2.ipcLangID - language id.
   
   Output Parameters:1.oplOpenOrder - Yes(if an open order),
                     2.opcOpenAmt   - total amount of an order,
                     3.cError       - errors if any,
                     4opiStatusCode - HTTP response code.
                     
   Notes: 
  ------------------------------------------------------------------------------*/  
  METHOD PUBLIC VOID checkOpenOrdr(INPUT  ipcOrdNum      AS CHARACTER,
                                   INPUT  ipcLangID      AS CHARACTER,
                                   INPUT  ipcCompanyCode AS CHARACTER, 
                                   OUTPUT oplOpenOrder   AS LOGICAL, 
                                   OUTPUT opcOpenAmt     AS DECIMAL, 
                                   OUTPUT cError         AS CHARACTER,
                                   OUTPUT opiStatusCode  AS INTEGER):
                                       
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource NO-UNDO.
     
    objCommonSrc = NEW CommonSource(INPUT cToken).
                                                               
    IF TRIM(ipcOrdNum) EQ "":U OR TRIM(ipcOrdNum) EQ ?  THEN
    DO:
      /* Get multilingual message for blank order number */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200OrderBlank,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
       
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.  /* IF TRIM(ipcOrdNum) = "":U OR.. */
   //Gama le quito la condicion al For each, le anadio el indice y puse el validar que no sea COODT.ORDER-QTY       NE 0 para el error del TimeComplexity. 
    FOR EACH COODT NO-LOCK USE-INDEX ORDER-KEY
      WHERE COODT.ORDER-NUMBER    EQ ipcOrdNum
        //AND COODT.ORDER-QTY       NE 0
       /* AND NOT COODT.ITEM-NUMBER BEGINS ipcCompanyCode + "*":U*/ :
      IF COODT.ORDER-QTY NE 0 AND NOT COODT.ITEM-NUMBER BEGINS ipcCompanyCode + "*":U THEN DO:   
      ASSIGN opcOpenAmt   = opcOpenAmt + (COODT.ORDERED-PRC * COODT.ORDER-QTY)
             oplOpenOrder = TRUE.
      END. //IF COODT.ORDER-QTY NE 0
    END. /* FOR EACH COODT... */
   
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.    
    END FINALLY.    
      
  END METHOD. 

  /*------------------------------------------------------------------------------------
   Purpose: This Method returns the items of all the open orders for salesman dashboard
   Notes: 
  --------------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID getOpenOrderItems(INPUT  ipcSalesRepID    AS CHARACTER,
                                       INPUT  ipcCustNum       AS CHARACTER,
                                       INPUT  ipcLangID        AS CHARACTER,                                       
                                       INPUT  ipcCompanyID     AS CHARACTER,                                                                             
                                       INPUT  ipiWareHouseNo   AS INTEGER,
                                       INPUT  ipiLastSyncTime  AS INT64,
                                       INPUT  cUserType        AS CHARACTER,
                                       OUTPUT oplcOrderItems   AS LONGCHAR,
                                       OUTPUT opcError         AS CHARACTER,
                                       OUTPUT opiStatusCode    AS INTEGER):
    
    DEFINE VARIABLE opcLastXDays      AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE iDateRange        AS INTEGER       NO-UNDO.
    DEFINE VARIABLE deGrossAmount     AS DECIMAL       NO-UNDO.
    DEFINE VARIABLE cPriceList        AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE lPartiallyShip    AS LOGICAL       NO-UNDO.
    DEFINE VARIABLE lShipped          AS LOGICAL       NO-UNDO.
    DEFINE VARIABLE lClosed           AS LOGICAL       NO-UNDO.
    DEFINE VARIABLE cCustNum          AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE cSpecDict         AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE deDiscPerc        AS DECIMAL       NO-UNDO.
    DEFINE VARIABLE cQtyBrkCd         AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE cSpecDictI        AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE cContractInd      AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE cCustType         AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE cCustName         AS CHARACTER     NO-UNDO.
    
    DEFINE VARIABLE objCommonSrc      AS CLASS CommonSource       NO-UNDO.
    DEFINE VARIABLE orderSummaryObj   AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE shippingObj       AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE billingObj        AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE orderJsonObj      AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE itemJsonObj       AS CLASS JsonObject         NO-UNDO.
    DEFINE VARIABLE orderJsonArray    AS CLASS JsonArray          NO-UNDO.
    DEFINE VARIABLE itemsArray        AS CLASS JsonArray          NO-UNDO.                                   
    DEFINE VARIABLE objSalesman       AS CLASS SalesmanInfo       NO-UNDO.
      
    DEFINE VARIABLE lRegularSlsman    AS LOGICAL                  NO-UNDO.
    DEFINE VARIABLE deCartsAmt        AS DECIMAL                  NO-UNDO.
    DEFINE VARIABLE cError            AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE cTermsDesc        AS CHARACTER                NO-UNDO.
    DEFINE VARIABLE iSalesPrsnOpnCarts AS INTEGER                 NO-UNDO.
                                         
      ASSIGN 
        objSalesman      = NEW SalesmanInfo(INPUT cToken)
        objCommonSrc     = NEW CommonSource(INPUT cToken)
        orderSummaryObj  = NEW JsonObject()
        itemJsonObj      = NEW JsonObject() 
        shippingObj      = NEW JsonObject()
        billingObj       = NEW JsonObject()
        orderJsonObj     = NEW JsonObject()
        orderJsonArray   = NEW JsonArray()
        itemsArray       = NEW JsonArray().
                                                  
                                                  
      FIND CSAMS WHERE CSAMS.sales-rep-id EQ ipcSalesRepID  NO-LOCK NO-ERROR.
      IF AVAILABLE CSAMS THEN
      DO:      
        ASSIGN        
          lRegularSlsman = CSAMS.laptop.
      END. /* IF AVAILABLE CSAMS */
     
      /* Method returns open-carts count, carts amount and carts details.  */ 
      objSalesman:getOpenCarts(INPUT  ipcSalesRepID,
                               INPUT  ipcLangID,
                               INPUT  lRegularSlsman,
                               INPUT  ipcCompanyID,
                               OUTPUT iSalesPrsnOpnCarts,
                               OUTPUT deCartsAmt, 
                               OUTPUT cError,
                               OUTPUT opiStatusCode,
                               OUTPUT TABLE ttOpenOrder).                                                                
            
      FOR EACH ttOpenOrder WHERE IF ipcCustNum NE "A":U THEN 
                                    ttOpenOrder.customerNumber EQ ipcCustNum 
                                 ELSE TRUE 
                                 BY ttOpenOrder.orderDate DESC:
                                          
        FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ ttOpenOrder.orderNumber 
                           AND COOHD.Timestamp    GT ipiLastSyncTime NO-LOCK NO-ERROR.
                         
        IF AVAIL COOHD THEN
        DO:
          
          FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ COOHD.CUST-NUMBER NO-LOCK NO-ERROR.
          IF AVAIL CCSMS THEN
          DO:    
            FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
            IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
              ASSIGN cPriceList = SHPTO.PRICE-LIST.
            ELSE
              ASSIGN cPriceList = CCSMS.PRICE-LIST.
              
            FIND TERMS WHERE TERMS.CUS-TERMS-CD EQ CCSMS.TERMS-CODE NO-LOCK NO-ERROR.
            IF AVAILABLE TERMS THEN
            ASSIGN cTermsDesc = TERMS.CUS-TERMS-DS.
            
            ASSIGN 
              cCustNum       = CCSMS.CUST-NUMBER
              cSpecDict      = ccsms.spec-dict-i
              deDiscPerc     = ccsms.disc-perc
              cQtyBrkCd      = ccsms.qty-brk-cd
              cSpecDictI     = CCSMS.SPEC-DICT-I                      
              cContractInd   = CCSMS.CONTRACT-IND
              cCustType      = CCSMS.CUST-TYPE
              cCustName      = REPLACE(CCSMS.CUST-NAME,"'", "").
       
          END. /* IF AVAIL CCSMS THEN  */
    
          ASSIGN 
            orderSummaryObj  = NEW JsonObject() 
            shippingObj      = NEW JsonObject()
            billingObj       = NEW JsonObject()
            orderJsonObj     = NEW JsonObject()
            itemsArray       = NEW JsonArray()
            deGrossAmount    = 0
            lPartiallyShip   = FALSE
            lShipped         = TRUE
            lClosed          = TRUE.
                     
          orderSummaryObj:ADD(INPUT "order_total":U,  INPUT  IF ttOpenOrder.openAmt EQ ? THEN 0 ELSE ttOpenOrder.openAmt).            
          orderSummaryObj:ADD(INPUT "shipping_tax":U, INPUT  COOHD.FREIGHT-AMT).
          orderSummaryObj:ADD(INPUT "city_tax":U,     INPUT 0).
          orderSummaryObj:ADD(INPUT "state_tax":U,    INPUT 0).
                 
          FOR EACH COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER NO-LOCK:
            
            IF CAN-FIND(FIRST COOSZ WHERE COOSZ.ORDER-NUMBER EQ COODT.ORDER-NUMBER 
                                      AND COOSZ.ORDER-SEQ    EQ COODT.ORDER-SEQ) THEN 
            DO:
              /* calculate sub total */
              ASSIGN deGrossAmount = deGrossAmount + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY). /* avoided repeated calculation where by-size */
              
              /* For items with sizes */
              FOR EACH COOSZ WHERE COOSZ.order-number EQ COODT.ORDER-NUMBER 
                               AND COOSZ.ORDER-SEQ    EQ COODT.ORDER-SEQ NO-LOCK:
                                 
                ASSIGN itemJsonObj = NEW JsonObject().      
                
                IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*CITY-TAX*":U) THEN
                DO:
                  orderSummaryObj:SET(INPUT "city_tax":U, INPUT COODT.ORDERED-PRC).
                  NEXT. 
                END.
                
                IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*STATE-TAX*":U) THEN   
                DO:
                  orderSummaryObj:SET(INPUT "state_tax":U, INPUT COODT.ORDERED-PRC).
                  NEXT.
                END.
                               
                IF COODT.ORDER-QTY NE 0 THEN
                DO:
                   ASSIGN lClosed = FALSE. 
                   
                   IF COODT.DELIVERD-QTY NE 0 THEN
                     ASSIGN lPartiallyShip = TRUE.  
                END.
                
                IF COODT.DELIVERD-QTY LT COODT.ORIGINAL-QTY THEN
                  ASSIGN lShipped = FALSE.
                  
                //ASSIGN deGrossAmount = deGrossAmount + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY). Avoided repeated calculation

                
                /* Populate/Get Item Json Object */
                THIS-OBJECT:getOrderedItem(INPUT COODT.ORDER-NUMBER,
                                           INPUT COODT.ITEM-NUMBER,
                                           INPUT COODT.ORDER-SEQ,
                                           INPUT COODT.DESCRIPTION,
                                           INPUT COOSZ.SIZE-QTY,
                                           INPUT COOSZ.size, 
                                           INPUT cPriceList,
                                           INPUT cCustNum,
                                           INPUT ipcCompanyID,
                                           INPUT ipiWarehouseNo,
                                           INPUT "",
                                           INPUT deDiscPerc,
                                           INPUT cContractInd,
                                           INPUT cSpecDictI,
                                           INPUT cQtyBrkCd,
                                           INPUT cCustType,
                                           OUTPUT itemJsonObj).
                
                itemJsonObj:ADD(INPUT "order_old_price":U, INPUT COODT.ORDERED-PRC).
                itemJsonObj:ADD(INPUT "shipped_on":U,      INPUT COOHD.DATE-WANTED). /* Need to be discussed */
                        
                itemsArray:ADD(itemJsonObj).
              END. /* FOR EACH COOSZ */
            
            END. /* IF CAN-FIND(FIRST COOSZ).. */
            
            /* Items without sizes */
            ELSE
            DO:
              ASSIGN itemJsonObj = NEW JsonObject().      
              
              IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*CITY-TAX*":U) THEN
              DO:
                orderSummaryObj:SET(INPUT "city_tax":U, INPUT COODT.ORDERED-PRC).
                NEXT. 
              END.
              
              IF COODT.ITEM-NUMBER  EQ (ipcCompanyID + "*STATE-TAX*":U) THEN   
              DO:
                orderSummaryObj:SET(INPUT "state_tax":U, INPUT COODT.ORDERED-PRC).
                NEXT.
              END.
                             
              IF COODT.ORDER-QTY NE 0 THEN
              DO:
                 ASSIGN lClosed = FALSE. 
                 
                 IF COODT.DELIVERD-QTY NE 0 THEN
                   ASSIGN lPartiallyShip = TRUE.  
              END.
              
              IF COODT.DELIVERD-QTY LT COODT.ORIGINAL-QTY THEN
                ASSIGN lShipped = FALSE.
                
              ASSIGN deGrossAmount = deGrossAmount + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY).
                  
              
              /* Populate/Get Item Json Object */
              THIS-OBJECT:getOrderedItem(INPUT COODT.ORDER-NUMBER,
                                         INPUT COODT.ITEM-NUMBER,
                                         INPUT COODT.ORDER-SEQ,
                                         INPUT COODT.DESCRIPTION,
                                         INPUT COODT.ORIGINAL-QTY,
                                         INPUT "NOTAPPLICABLE", 
                                         INPUT cPriceList,
                                         INPUT cCustNum,
                                         INPUT ipcCompanyID,
                                         INPUT ipiWarehouseNo,
                                         INPUT "",
                                         INPUT deDiscPerc,
                                         INPUT cContractInd,
                                         INPUT cSpecDictI,
                                         INPUT cQtyBrkCd,
                                         INPUT cCustType,
                                         OUTPUT itemJsonObj).
              
              itemJsonObj:ADD(INPUT "order_old_price":U, INPUT COODT.ORDERED-PRC).
              itemJsonObj:ADD(INPUT "shipped_on":U,      INPUT COOHD.DATE-WANTED). /* Need to be discussed */
                      
              itemsArray:ADD(itemJsonObj).
              
            END. /* ELSE - IF CAN-FIND(FIRST COOSZ).. */ 
             
          END. /* FOR EACH COODT... */  
          
          orderSummaryObj:ADD(INPUT "sub_total":U,   INPUT IF deGrossAmount EQ ? THEN 0 ELSE deGrossAmount).
          
          shippingObj:ADD(INPUT "ship_number":U,    INPUT  COOHD.alfa-1).
          
          lcAddress = REPLACE(COOHD.SHIP-ADDR-L1,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
        
          shippingObj:ADD(INPUT "shipping_addL1":U, INPUT  lcAddress).
          
          lcAddress = REPLACE(COOHD.SHIP-ADDR-L2,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
          
          shippingObj:ADD(INPUT "shipping_addL2":U, INPUT  lcAddress).
          
          lcAddress = REPLACE(COOHD.SHIP-ADDR-L3,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
          
          shippingObj:ADD(INPUT "shipping_addL3":U, INPUT  lcAddress).
          
          lcAddress = REPLACE(COOHD.ADDRESS-L1,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
          
          billingObj:ADD(INPUT "billing_addL1":U,  INPUT  lcAddress).
          
          lcAddress = REPLACE(COOHD.ADDRESS-L2,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
          
          billingObj:ADD(INPUT "billing_addL2":U,  INPUT  lcAddress).
          
          lcAddress = REPLACE(COOHD.ADDRESS-L3,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
          
          billingObj:ADD(INPUT "billing_addL3":U,  INPUT  lcAddress).
          
          /* Constructing main order object */
          orderJsonObj:ADD(INPUT "order_number":U,   INPUT COOHD.ORDER-NUMBER).
          /*Only orders with timestamp GT this last synced timestamp will be returned on mobile*/
          orderJsonObj:ADD(INPUT "last_synced_on":U, INPUT COOHD.timestamp).
          orderJsonObj:ADD(INPUT "customer_number":U,INPUT COOHD.CUST-NUMBER).
          orderJsonObj:ADD(INPUT "paymentTerm":U,    INPUT  cTermsDesc).
          orderJsonObj:ADD(INPUT "customer_name":U,  INPUT cCustName).
          orderJsonObj:ADD(INPUT "customer_type":U,  INPUT cCustType).
          
          orderJsonObj:ADD(INPUT "order_date":U,    INPUT COOHD.ORDER-DATE).
          orderJsonObj:ADD(INPUT "order_status":U,  INPUT "":U).
                
          IF lPartiallyShip THEN
            orderJsonObj:SET(INPUT "order_status":U,  INPUT "partially shipped":U).
          ELSE
            orderJsonObj:SET(INPUT "order_status":U,  INPUT "open":U). 
          
          /* Closed order status has higher priority then shipped */
          IF lClosed THEN
            orderJsonObj:SET(INPUT "order_status":U,  INPUT "closed":U).
          
          IF lShipped AND NOT lClosed THEN
            orderJsonObj:SET(INPUT "order_status":U,  INPUT "shipped":U).   
          
          IF COOHD.BOOKED-IND BEGINS "CANCEL":U THEN
            orderJsonObj:SET(INPUT "order_status":U,  INPUT "cancelled":U).
                   
          IF COOHD.DATE-WANTED NE ? THEN
            orderJsonObj:ADD(INPUT "date_wanted":U, INPUT COOHD.DATE-WANTED).
               
          /* Adding sub-objects into the main order object */  
          orderJsonObj:ADD(INPUT "order_summary":U, INPUT orderSummaryObj).
          orderJsonObj:ADD(INPUT "shipping_info":U, INPUT shippingObj).
          orderJsonObj:ADD(INPUT "billing_info":U,  INPUT billingObj).
          orderJsonObj:ADD(INPUT "items_ordered":U, INPUT itemsArray).
          
          orderJsonArray:ADD(orderJsonObj).
    
        END. /* IF AVAIL COOHD  */

      END. /* FOR EACH ttOpenOrder */              
      
      ASSIGN oplcOrderItems = orderJsonArray:GetJsonText().
    
      IF orderJsonArray:LENGTH EQ 0 THEN
      DO:
        /*Get multilingual message for No order history available */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200NoOpenOrderFound,                                                              
                                 OUTPUT opcError,
                                 OUTPUT opiStatusCode).
                                    
        IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).
      END.  
         
      CATCH errorObj AS AppError:           
        ASSIGN 
          opcError = errorObj:GetMessage(1).
      END CATCH.
      
      FINALLY:
        
        INPUT CLOSE.
                
        IF VALID-OBJECT(orderJsonArray)   THEN
          DELETE OBJECT orderJsonArray.
        
        IF VALID-OBJECT(orderJsonObj)     THEN
          DELETE OBJECT orderJsonObj.
        
        IF VALID-OBJECT(billingObj)       THEN
          DELETE OBJECT billingObj.
        
        IF VALID-OBJECT(shippingObj)      THEN
          DELETE OBJECT shippingObj.
        
        IF VALID-OBJECT(orderSummaryObj)  THEN
          DELETE OBJECT orderSummaryObj.
        
        IF VALID-OBJECT(itemsArray)       THEN
          DELETE OBJECT itemsArray.
        
        IF VALID-OBJECT(objCommonSrc)     THEN
          DELETE OBJECT objCommonSrc.
                  
        IF VALID-OBJECT(itemJsonObj)      THEN
          DELETE OBJECT itemJsonObj.  
                
      END FINALLY.

  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
                                    
  METHOD PUBLIC VOID getOrderedItem(INPUT  ipcOrderNumber  AS CHARACTER,
                                    INPUT  ipcItemNumber   AS CHARACTER,
                                    INPUT  ipiOrderSeq     AS INTEGER,
                                    INPUT  ipcDescription  AS CHARACTER,
                                    INPUT  ipdeQuantity    AS DECIMAL,
                                    INPUT  ipcSize         AS CHARACTER,
                                    INPUT  ipcPriceList    AS CHARACTER,
                                    INPUT  ipcCustNumber   AS CHARACTER,
                                    INPUT  ipcCompanyID    AS CHARACTER,
                                    INPUT  ipiWarehouseNo  AS INTEGER,
                                    INPUT  ipcShipTo       AS CHARACTER,
                                    INPUT  ipdeDiscountPrc AS DECIMAL,
                                    INPUT  ipcContractInd  AS CHARACTER,
                                    INPUT  ipcSpecDictI    AS CHARACTER,
                                    INPUT  ipcQtyBrkCd     AS CHARACTER,
                                    INPUT  ipcCustType     AS CHARACTER,
                                    OUTPUT itemJsonObj     AS JsonObject):
      
      DEFINE VARIABLE objCustProductPrice    AS CLASS ProductPrices      NO-UNDO.
      DEFINE VARIABLE objOrderTax            AS CLASS OrderTaxes         NO-UNDO.
      DEFINE VARIABLE prodInfoObj            AS CLASS JsonObject         NO-UNDO.
      DEFINE VARIABLE moreProdInfoObj        AS CLASS JsonObject         NO-UNDO.
      DEFINE VARIABLE pictureJsonArr         AS CLASS JsonArray          NO-UNDO.
      DEFINE VARIABLE moreProdInfoArr        AS CLASS JsonArray          NO-UNDO.
      DEFINE VARIABLE orderTaxArray          AS CLASS JsonArray          NO-UNDO.
      DEFINE VARIABLE ObjCategoryFilterItem  AS CLASS CategoryFilterItem    NO-UNDO.
      DEFINE VARIABLE deSellingPrc   AS DECIMAL     NO-UNDO.
      DEFINE VARIABLE deBasePrc      AS DECIMAL     NO-UNDO.
      DEFINE VARIABLE cItemImage     AS CHARACTER   NO-UNDO.
      DEFINE VARIABLE cFileType      AS CHARACTER   NO-UNDO.
      DEFINE VARIABLE cSourceDir     AS CHARACTER   NO-UNDO.
      DEFINE VARIABLE SHIP-NO        AS CHARACTER   NO-UNDO.
      DEFINE VARIABLE cSize          AS CHARACTER   NO-UNDO.
      DEFINE VARIABLE QTY-FULL       AS INTEGER   FORMAT "->>>9" NO-UNDO.
      DEFINE VARIABLE QTY-UNIT       AS INTEGER   FORMAT "->>>9" NO-UNDO.
      DEFINE VARIABLE CDomain        AS CHARACTER NO-UNDO.  
      DEFINE VARIABLE byitem         AS LOGICAL NO-UNDO.
      DEFINE VARIABLE lcDescription AS CHARACTER NO-UNDO.
      DEFINE VARIABLE ldUptoQty            AS DECIMAL EXTENT 5 NO-UNDO.
      DEFINE VARIABLE ldUptoQtyPrice       AS DECIMAL EXTENT 5 NO-UNDO.
      DEFINE VARIABLE ldPercent            AS DECIMAL          NO-UNDO.
      DEFINE VARIABLE ldbuyforFreeQty      AS DECIMAL NO-UNDO.
      DEFINE VARIABLE ldgetforFreeQty      AS DECIMAL NO-UNDO.
      DEFINE VARIABLE ldHasOffer           AS CHARACTER NO-UNDO.
      
      ASSIGN itemJsonObj           = NEW JsonObject()
             objOrderTax           = NEW OrderTaxes(INPUT cToken)
             orderTaxArray         = NEW JsonArray()  
             prodInfoObj           = NEW JsonObject()
             pictureJsonArr        = NEW JsonArray()
             moreProdInfoObj       = NEW JsonObject()
             moreProdInfoArr       = NEW JsonArray()   
             objCustProductPrice   = NEW ProductPrices(INPUT cToken).
            ObjCategoryFilterItem = NEW CategoryFilterItem(INPUT cToken).
      
       lcDescription = REPLACE(ipcDescription,"'", "").
       lcDescription = REPLACE(lcDescription,'"', '').
       lcDescription = REPLACE(lcDescription,"/", "").
       lcDescription = REPLACE(lcDescription,"\", "").
                      
      itemJsonObj:ADD(INPUT "item_number":U,     INPUT ipcItemNumber).
      itemJsonObj:ADD(INPUT "description":U,     INPUT lcDescription ). //REPLACE(ipcDescription,"'", "") ).
      itemJsonObj:ADD(INPUT "quantity":U,        INPUT ipdeQuantity).
      itemJsonObj:ADD(INPUT "item_size":U,       INPUT "":U).
      itemJsonObj:ADD(INPUT "item_color":U,      INPUT "":U).
      itemJsonObj:ADD(INPUT "item_exist":U,      INPUT FALSE).
      itemJsonObj:ADD(INPUT "category_id":U,     INPUT "").
    
      /* if item exists the set it else leave them blank */
      itemJsonObj:ADD(INPUT "item_uom":U,        INPUT "").
      itemJsonObj:ADD(INPUT "uom_qty":U,         INPUT "").
      itemJsonObj:ADD(INPUT "unit_price":U,      INPUT 0).      
      itemJsonObj:ADD(INPUT "sell_price":U,      INPUT 0).
      
      /* if item exists the set it else leave them blank */
      
      itemJsonObj:ADD(INPUT "on_order",          INPUT 0).
      itemJsonObj:ADD(INPUT "commit_qty":U,      INPUT 0).
      
      FIND FIRST CINV2 
             WHERE CINV2.ITEM-NUMBER  EQ ipcItemNumber
             AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.
             
      IF AVAILABLE CINV2 THEN
      DO:        
        itemJsonObj:SET(INPUT "commit_qty":U,  INPUT CINV2.QTY-COMMITED).
      END.
      
      IF ipcSize EQ "NOTAPPLICABLE" THEN  
      DO:
        
        FIND FIRST COOSZ WHERE COOSZ.ORDER-NUMBER EQ ipcOrderNumber
                           AND COOSZ.ORDER-SEQ    EQ ipiOrderSeq NO-LOCK NO-ERROR.
                         
        IF AVAILABLE COOSZ THEN
          itemJsonObj:SET(INPUT "item_size":U, INPUT COOSZ.SIZE).
            
      END. /* IF ipcSize EQ "NOTAPPLICABLE" */                    
      
      ELSE 
      DO:
        
        FIND FIRST COOSZ WHERE COOSZ.ORDER-NUMBER EQ ipcOrderNumber
                           AND COOSZ.ORDER-SEQ    EQ ipiOrderSeq
                           AND COOSZ.SIZE         EQ ipcSize NO-LOCK NO-ERROR.
                         
        IF AVAILABLE COOSZ THEN
          itemJsonObj:SET(INPUT "item_size":U, INPUT COOSZ.SIZE).
          
      END. /* ELSE - IF ipcSize EQ "NOTAPPLICABLE" */
         
      //itemJsonObj:SET(INPUT "item_color":U, INPUT IF COOSZ.STYLE-COLOR EQ "":U THEN "Not Applicable":U ELSE COOSZ.STYLE-COLOR).       
                         
      FIND FIRST CINV1 WHERE CINV1.ITEM-NUMBER EQ ipcItemNumber NO-LOCK NO-ERROR.
      IF AVAILABLE CINV1 THEN
      DO:
          
        /* When item exist in the master table CINV1 then SET following keys */
        itemJsonObj:SET(INPUT "item_exist":U, INPUT TRUE).
        itemJsonObj:SET(INPUT "item_uom",     INPUT CINV1.ITEM-UOM).
        itemJsonObj:SET(INPUT "uom_qty",      INPUT CINV1.UOM-QTY).
        itemJsonObj:SET(INPUT "on_order",     INPUT CINV1.QTY-ON-ORDER).
    
        /*By-calling getPrice() method , assign selling-price of a specific Item corresponding to a specific customer*/
        objCustProductPrice:getProductPrices(INPUT '0',
                                             INPUT ipcCustNumber,
                                             INPUT CINV1.ITEM-NUMBER,
                                             INPUT YES,
                                             INPUT ipdeDiscountPrc, 
                                             OUTPUT deSellingPrc,
                                             OUTPUT deBasePrc,
                                             INPUT  SHIP-NO,
                                             INPUT  QTY-FULL,
                                             INPUT  QTY-UNIT,
                                             INPUT ipcPriceList,
                                             INPUT ipcCompanyID).               
     //Gama 03/22/2024 Me quede en pasar los parametros a los metodos y este no es muy importante que se le pase pq no va hacer nada con el pero el que corre para llenar el Tax_Unit si
     //Gama 03/25/2024 me acab de dar cuenta que el parametro SHIP-NO no lo puse yo aunque se define en este metodo y no se hace nada con ella.
        /* Set current price for an item */
        
        IF INDEX(lcDescription,"KIT Component") GT 0 THEN 
        deSellingPrc = 0.
         
        itemJsonObj:SET(INPUT "unit_price":U, INPUT deSellingPrc).
        
        FIND FIRST COODT WHERE COODT.ORDER-NUMBER = ipcOrderNumber 
                            AND COODT.item-number = ipcItemNumber NO-LOCK NO-ERROR.
        IF AVAILABLE COODT THEN  
        itemJsonObj:SET(INPUT "sell_price":U, INPUT COODT.ORDERED-PRC ).
      
        /* creating product_info JSON object */    
        prodInfoObj:ADD(INPUT "class_code":U, INPUT CINV1.CLASS-CODE). 
              
        IF ipcItemNumber MATCHES "*" THEN
           ipcItemNumber = CAPS(TRIM(REPLACE(ipcItemNumber, "*", "-") , "-":U)).
   

         
         cSourceDir  = this-object:ImgDirectory(INPUT ipcItemNumber, INPUT ipcCompanyID, OUTPUT byitem).
         CDomain    = this-object:FINDCDN(INPUT ipcCompanyID ).
         
        IF cSourceDir NE "x" THEN
        DO:
         
         ASSIGN FILE-INFO:FILE-NAME = cSourceDir.
                cSourceDir = FILE-INFO:FULL-PATHNAME.
          
         
          INPUT FROM OS-DIR(cSourceDir).
          
          IF byitem THEN  
          DO:
              REPEAT:
                IMPORT cItemImage ^ cFileType.
                IF cFileType EQ "F":U THEN
                  //pictureJsonArr:ADD(INPUT ConstantInitializer:cImageDir + "/":U + ipcItemNumber + "/":U + cItemImage).  
                  pictureJsonArr:ADD(Cdomain + "/":U + ipcItemNumber + "/":U + Replace(cItemImage," ","%20")).              
              END.    
          END.
          ELSE 
          DO:
             REPEAT:
                IMPORT cItemImage ^ cFileType.
                IF cFileType EQ "F":U AND INDEX(cItemImage , ipcItemNumber) GT 0 THEN
                  pictureJsonArr:ADD(Cdomain + "/":U + Replace(cItemImage," ","%20")).   
                     
              END. 
          END.      
        END. /* IF FILE-INFO:FULL-PATHNAME NE ? THEN */  
      
        prodInfoObj:ADD(INPUT "pictures":U, INPUT pictureJsonArr).
        
        
       /* IF CINV1.PICTURE NE "":U THEN
        DO:
          FILE-INFO:FILE-NAME = ConstantInitializer:cPDFDir + "/":U + SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1) + ".pdf".
          IF FILE-INFO:FULL-PATHNAME NE ? THEN
          DO:
            itemJsonObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1) + ".pdf").
          END.
         
          ELSE
            prodInfoObj:ADD(INPUT "pdf_link":U, INPUT "":U).
        END.
        
        ELSE
          prodInfoObj:ADD(INPUT "pdf_link":U, INPUT "":U). */
           
         prodInfoObj:ADD(INPUT "pdf_link":U, INPUT ObjCategoryFilterItem:PdfLink(ipcItemNumber,ipcCompanyID ) ).    
        /* Assign value of quantity on hand of specific item */
        FIND FIRST CINV2 
             WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
             AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.
             
        IF AVAILABLE CINV2 THEN
        DO:
          prodInfoObj:ADD(INPUT "qty_on_hand":U, INPUT IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED GT 0 THEN CINV2.QTY-ONHAND - CINV2.QTY-COMMITED ELSE 0).
          prodInfoObj:ADD(INPUT "commit_qty":U,  INPUT CINV2.QTY-COMMITED ).
        END.
        
        ELSE
        DO:
           prodInfoObj:ADD(INPUT "qty_on_hand":U, INPUT IF CINV1.QTY-ONHAND GT 0 THEN CINV1.QTY-ONHAND ELSE 0).
          prodInfoObj:ADD(INPUT "commit_qty":U,  INPUT 0).
        END.
                                          
        IF CINV1.BY-SIZE OR CINV1.BY-COLOR THEN
        DO: 
          FOR EACH SIZE WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo 
                          AND SIZE.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER NO-LOCK:
            
/*            IF COOSZ.SIZE EQ SIZE.SIZE THEN                                                                              */
/*              itemJsonObj:SET(INPUT "item_color":U, INPUT IF CINV1.BY-COLOR THEN SIZE.DESCRIPTION ELSE 'Not Applicable').*/
            
            IF AVAILABLE COOSZ AND (COOSZ.SIZE EQ SIZE.SIZE) THEN
              itemJsonObj:SET(INPUT "item_color":U, INPUT IF CINV1.BY-COLOR THEN SIZE.DESCRIPTION ELSE 'Not Applicable').
            ELSE
              itemJsonObj:SET(INPUT "item_color":U, INPUT 'Not Applicable').
                            
            ASSIGN moreProdInfoObj = NEW jsonObject().
                     
            moreProdInfoObj:ADD(INPUT "size",       INPUT SIZE.SIZE).
            moreProdInfoObj:ADD(INPUT "color",      INPUT IF CINV1.BY-COLOR THEN REPLACE(SIZE.DESCRIPTION ,"'", "") ELSE 'Not Applicable').
            moreProdInfoObj:ADD(INPUT "in_stock",   INPUT (SIZE.QTY-ONHAND - SIZE.QTY-COMMITED)).
            moreProdInfoObj:ADD(INPUT "unit_price", INPUT deSellingPrc).
            moreProdInfoArr:ADD(INPUT moreProdInfoObj).
                    
          END. /* FOR EACH SIZE... */
        
        END. /* IF CINV1.BY-SIZE THEN */
        
        IF moreProdInfoArr:LENGTH EQ 0 THEN
        DO:
            ASSIGN moreProdInfoObj = NEW jsonObject ().
            
            moreProdInfoObj:ADD(INPUT "size":U,  INPUT 'Not Applicable':U).
            moreProdInfoObj:ADD(INPUT "color":U, INPUT 'Not Applicable':U).
            
            IF AVAILABLE CINV2 THEN
                moreProdInfoObj:ADD(INPUT "in_stock":U, INPUT CINV2.QTY-ONHAND - CINV2.QTY-COMMITED ).
            ELSE
                moreProdInfoObj:ADD(INPUT "in_stock":U, INPUT CINV1.QTY-ONHAND ).
                
            moreProdInfoObj:ADD(INPUT "unit_price":U, INPUT deSellingPrc).
            moreProdInfoArr:ADD(INPUT moreProdInfoObj).
        
        END. /* IF moreProdInfoArr:LENGTH EQ 0 THEN */ 
            
        prodInfoObj:Add(INPUT "more_product_data", INPUT moreProdInfoArr).
        
        
        objOrderTax:getItemTaxForShipping(INPUT CINV1.ITEM-NUMBER,
                                          INPUT ipcCompanyID, /* not available */
                                          INPUT ipcCustNumber,
                                          INPUT ipiWareHouseNo,
                                          INPUT ipcShipTo,
                                          INPUT deSellingPrc,
                                          OUTPUT orderTaxArray).
                                                        
      
        IF VALID-OBJECT(prodInfoObj) THEN
          prodInfoObj:ADD(INPUT "item_tax_unit", INPUT orderTaxArray).
          
          MESSAGE "En getOrderedItem prodInfoObj" string(prodInfoObj)
          VIEW-AS ALERT-BOX.
          
        itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
        
         /* Find the discount on item if any */
        FIND FIRST OFERT WHERE OFERT.ITEM-NUMBER EQ ipcItemNumber 
                           AND OFERT.TO-DT       GE TODAY 
                           AND OFERT.FROM-DT     LE TODAY NO-LOCK NO-ERROR. 
        IF AVAILABLE OFERT THEN 
        DO:
            
                  
            ASSIGN ldUptoQty[1]       = OFERT.UP-TO-QTY[1]
                   ldUptoQty[2]       = OFERT.UP-TO-QTY[2]
                   ldUptoQty[3]       = OFERT.UP-TO-QTY[3]
                   ldUptoQty[4]       = OFERT.UP-TO-QTY[4]
                   ldUptoQty[5]       = OFERT.UP-TO-QTY[5]
                   ldUptoQtyPrice[1]  = OFERT.PERCASE-DISC[1]
                   ldUptoQtyPrice[2]  = OFERT.PERCASE-DISC[2]
                   ldUptoQtyPrice[3]  = OFERT.PERCASE-DISC[3]
                   ldUptoQtyPrice[4]  = OFERT.PERCASE-DISC[4]
                   ldUptoQtyPrice[5]  = OFERT.PERCASE-DISC[5]
                   ldPercent          = OFERT.PER-CENT
                   ldbuyforFreeQty    = OFERT.PUR-FOR-FREE
                   ldgetforFreeQty    = OFERT.FREE-CASES
                   ldHasOffer         = "yes".
                   
        END.
        ELSE DO:
                ASSIGN ldUptoQty[1]       = 0
                       ldUptoQty[2]       = 0
                       ldUptoQty[3]       = 0
                       ldUptoQty[4]       = 0
                       ldUptoQty[5]       = 0
                       ldUptoQtyPrice[1]  = 0
                       ldUptoQtyPrice[2]  = 0
                       ldUptoQtyPrice[3]  = 0
                       ldUptoQtyPrice[4]  = 0
                       ldUptoQtyPrice[5]  = 0
                       ldPercent          = 0
                       ldbuyforFreeQty    = 0
                       ldgetforFreeQty    = 0
                       ldHasOffer         = "no".
        END.

        itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).
        itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).  
        itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).
        itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]). 
        itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).
        itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]). 
        itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).
        itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]). 
        itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).
        itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).
        itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).  
        itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).
        itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty). 
        itemJsonObj:ADD(INPUT "has_offer":U,             INPUT ldHasOffer).
        itemJsonObj:ADD(INPUT "product_info", INPUT prodInfoObj).
              
      END. /* IF AVAILABLE CINV1 THEN */
      ELSE
        itemJsonObj:ADD(INPUT "product_info", INPUT NEW JsonObject()).
            
    FINALLY:
      
      IF VALID-OBJECT(objOrderTax) THEN
        DELETE OBJECT objOrderTax. 
        
      IF VALID-OBJECT(objCustProductPrice) THEN
        DELETE OBJECT objCustProductPrice.  
         
    END FINALLY.
         
  END METHOD.
  /* Method to return the Image location */
  
   METHOD PUBLIC CHARACTER ImgDirectory (INPUT cItemNumber AS CHARACTER,
                                         INPUT ipcCompanyCode AS CHARACTER,
                                         OUTPUT byitem AS LOGICAL):
     FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "CDIPREMIUM-FOTOS"
                        AND PARAMFL.COMPANY-CODE = ipcCompanyCode
                        AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.     
     //FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
     byitem = NO.
     IF AVAILABLE paramfl THEN 
     DO:
        ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1.
        IF PARAMFL.PARAM-VALUE2 EQ "by-item":U THEN  
           ASSIGN byitem = YES
                  FILE-INFO:FILE-NAME =  FILE-INFO:FILE-NAME + "\" + cItemNumber NO-ERROR.
     END.         
     IF FILE-INFO:FULL-PATHNAME NE ? THEN
     RETURN FILE-INFO:FULL-PATHNAME.
     ELSE 
     RETURN "x".    
   END METHOD.  
   
   /* Method to return the Content Delivery Network location */
  
   METHOD PUBLIC CHARACTER FINDCDN (INPUT ipcCompanyCode AS CHARACTER):
     FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "CDIPREMIUM-FOTOS"
                        AND PARAMFL.COMPANY-CODE = ipcCompanyCode
                        AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR. 
     IF AVAILABLE paramfl THEN 
     RETURN PARAMFL.PARAM-VALUE3.
     
     ELSE 
     RETURN "x".    
   END METHOD.           
END CLASS.