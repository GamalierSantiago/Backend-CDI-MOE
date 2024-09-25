 /*------------------------------------------------------------------------
     File        : Checkout
     Purpose     : 
     Syntax      : 
     Description : 
     Author(s)   : JKTECH
     Created     : Wed Jan 31 12:21:25 IST 2018
     Notes       : 
   ----------------------------------------------------------------------*/

  USING Progress.Lang.*.
  USING Progress.Json.ObjectModel.*.
  
  BLOCK-LEVEL ON ERROR UNDO, THROW.

  CLASS Checkout: 
    
    
    /* Include file containing all the instance variables and temp-tables used in this file */ 
    {CheckoutDef.i}
     
    DEFINE PRIVATE TEMP-TABLE ttCheckoutCustomer NO-UNDO
      FIELD temp_number       AS CHARACTER
      FIELD cust_number       AS CHARACTER
      FIELD cust_name         AS CHARACTER
      FIELD shippingAdL1      AS CHARACTER
      FIELD shippingAdL2      AS CHARACTER
      FIELD shippingAdL3      AS CHARACTER
      FIELD payment_term      AS CHARACTER
      FIELD regular_salesman  AS LOGICAL
      FIELD ship_to_no        AS CHARACTER
      FIELD po_number         AS CHARACTER
      FIELD date_wanted       AS DATE
      FIELD order_on_hold     AS CHARACTER. /* Undeployed (deployed) - If "H" then order will be on hold */
    
    DEFINE PRIVATE TEMP-TABLE ttCheckoutProducts NO-UNDO
      FIELD temp_number       AS CHARACTER
      FIELD item_sequence     AS INTEGER
      FIELD item_number       AS CHARACTER
      FIELD item_description  AS CHARACTER      
      FIELD quantity          AS DECIMAL
      FIELD unit_price        AS DECIMAL
      FIELD item_total_price  AS DECIMAL
      FIELD item_color        AS CHARACTER
      FIELD item_size         AS CHARACTER.   
   
    DEFINE PRIVATE TEMP-TABLE ttPayment NO-UNDO
      FIELD invoice_num         AS CHARACTER
      FIELD order_number        AS CHARACTER    
      FIELD payment_type        AS CHARACTER
      FIELD payment_amt         AS DECIMAL
      FIELD cheque_num          AS CHARACTER
      FIELD discount_amt        AS DECIMAL. 
    
    DEFINE VARIABLE lcDigitalSign        AS LONGCHAR  NO-UNDO.
    DEFINE VARIABLE cSigneeName          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cOrderDateTime       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcOnlineRefId        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcOnlineTransId      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcLoggedinSalesRep   AS CHARACTER NO-UNDO.
    
    DEFINE PRIVATE DATASET ipdsCheckoutData SERIALIZE-HIDDEN FOR ttCheckoutCustomer,ttCheckoutProducts,ttPayment                                                                                                                                
      DATA-RELATION drCustCheckoutProducts  FOR ttCheckoutCustomer, ttCheckoutProducts  RELATION-FIELDS (temp_number,temp_number) NESTED FOREIGN-KEY-HIDDEN.
     
     DEFINE BUFFER bf-ttCheckoutProducts FOR ttCheckoutProducts. 
     
     DEFINE TEMP-TABLE tt-checkout LIKE ttCheckoutProducts.  
     
     DEFINE TEMP-TABLE ttcheckoutProducts-Temp LIKE ttCheckoutProducts
                  FIELDS parent-id  AS CHARACTER. 
     
     DEFINE TEMP-TABLE ttSet NO-UNDO 
           FIELD  item_no     AS CHARACTER 
           FIELD  PARENT_item AS CHARACTER  
           FIELD  Set_id      AS CHARACTER
           FIELD  table-RecId AS RECID
           FIELD  Price-zero  AS LOGICAL.  
           
     DEFINE BUFFER bufTmp-Detail for TMP-DETAIL.   
     DEFINE BUFFER bufSetdt      FOR Setdt.  
     
     DEFINE TEMP-TABLE Tmp-Detail-Temp LIKE TMP-DETAIL 
                FIELDS parent-id AS CHARACTER. 
    /*------------------------------------------------------------------------------
      Purpose:
      Notes:
     ------------------------------------------------------------------------------*/
        
    CONSTRUCTOR PUBLIC Checkout ():
      
                
    END CONSTRUCTOR.
  
  DEFINE PUBLIC  VARIABLE cToken              AS CHARACTER NO-UNDO.
  DEFINE PUBLIC  VARIABLE lcOrder-Origin      AS CHARACTER NO-UNDO.
  DEFINE PUBLIC  VARIABLE lcSendEmailForOrder AS CHAR      NO-UNDO.
  CONSTRUCTOR PUBLIC Checkout (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
    FIND FIRST token WHERE Token.Token EQ cToken NO-LOCK NO-ERROR.
    IF AVAILABLE token THEN
    DO:
        IF Token.User-Type BEGINS "web":u THEN 
          lcOrder-Origin = "WEB":U.
        ELSE IF Token.User-Type BEGINS "Mobile":u THEN 
          lcOrder-Origin = "MOB":U.
    END.     
      .
  END CONSTRUCTOR.      
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    METHOD PUBLIC VOID checkoutMainBlock(INPUT ipcUserId                AS CHARACTER,
                                         INPUT COMPANY                  AS CHARACTER,
                                         INPUT ipiWarehouseNo           AS INTEGER,
                                         INPUT ipcSigneeName            AS CHARACTER,
                                         INPUT iplcDigitalSign          AS LONGCHAR,
                                         INPUT ipcUserType              AS CHARACTER,
                                         INPUT ipcLangID                AS CHARACTER,
                                         INPUT ipcOrderDateTime         AS CHARACTER,
                                         INPUT ipdeAvailableCreditLimit AS DECIMAL,
                                         INPUT ipdeNetPaymentAmount     AS DECIMAL,
                                         INPUT ipcLongitude             AS CHARACTER,
                                         INPUT ipcLatitude              AS CHARACTER,
                                         INPUT DATASET ipdsCheckoutData,
                                         OUTPUT oplcCheckoutData        AS LONGCHAR,
                                         OUTPUT opcError                AS CHARACTER,
                                         OUTPUT opiStatusCode           AS INTEGER):
                                                
      DEFINE VARIABLE objCommonSrc         AS CLASS CommonSource      NO-UNDO.
      DEFINE VARIABLE objPaymentProcessing AS CLASS PaymentProcessing NO-UNDO.    
      DEFINE VARIABLE orderJsonObj         AS CLASS JsonObject        NO-UNDO.
         
      DEFINE VARIABLE cSalespersonId    AS CHARACTER NO-UNDO.
      DEFINE VARIABLE cCustomerNumber   AS CHARACTER NO-UNDO.
      DEFINE VARIABLE INVOICE-NUM       AS CHARACTER NO-UNDO.
      DEFINE VARIABLE ipdeInvoicePayAmt AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE ipdeOnlinePayAmt  AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE ipdeTotalPayAmt   AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE ipdQtyOnHand      AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE lByColor          AS LOGICAL   NO-UNDO.
      DEFINE VARIABLE lBySize           AS LOGICAL   NO-UNDO.
      DEFINE VARIABLE deInStockQty      AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE cInd              AS CHARACTER NO-UNDO.
      DEFINE VARIABLE lPASWDExist       AS LOGICAL   NO-UNDO.
      DEFINE VARIABLE cHold             AS CHARACTER INITIAL "HOLD-" NO-UNDO.
      DEFINE VARIABLE ldDiscountAmt     AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE ldDiscountPer     AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE lcComment         AS CHAR      NO-UNDO.
      DEFINE VARIABLE lastSeq           AS INTEGER   NO-UNDO.
      DEFINE VARIABLE ley172ItemNumber  AS CHAR      NO-UNDO.
      DEFINE VARIABLE listofItems       AS CHAR      NO-UNDO.
      
      DEFINE BUFFER bfCinv1 FOR cinv1.
      DEFINE BUFFER bfSize  FOR SIZE.
      DEFINE BUFFER bfCinv2 FOR cinv2.
      DEFINE BUFFER bfcinv3 FOR cinv1.
      DEFINE BUFFER bf2-ttCheckoutProducts FOR ttCheckoutProducts.
      ASSIGN objCommonSrc         = NEW CommonSource(INPUT cToken)
             orderJsonObj         = NEW JsonObject()
             objPaymentProcessing = NEW PaymentProcessing(INPUT cToken).
        
      ASSIGN INVOICE-NUM                 = "TMP-NUMBER":U
             THIS-OBJECT:lcDigitalSign   = iplcDigitalSign 
             THIS-OBJECT:INVOICE-NUM     = INVOICE-NUM
             THIS-OBJECT:COMPANY         = COMPANY
             THIS-OBJECT:TRANS-TYPE      = "2":U
             THIS-OBJECT:cLongitude      = ipcLongitude
             THIS-OBJECT:cLatitude       = ipcLatitude
             THIS-OBJECT:cSigneeName     = ipcSigneeName
             THIS-OBJECT:cOrderDateTime  = ipcOrderDateTime
             SUBSTRING(cHold,10,1)       = "X"
             cInd                        = cHold.  
      
      /* Undeployed code - If PASWD record exists and avail cred LT credit limit 
         then only it will place the order on hold */
      FIND PASWD WHERE PASWD.COMPANY-CODE = COMPANY 
                   AND PASWD.FILE-NAME    = "CCSMS" 
                   AND PASWD.FIELD-NAME   = "CREDIT-LIMIT" NO-LOCK NO-ERROR.
      
      IF AVAILABLE PASWD THEN
      DO:
        IF  PASWD.DESCRIPTION = "PUT-ON-HOLD" THEN
        DO:
          ASSIGN lPASWDExist = TRUE.  
        END.
      END. /* IF  AVAILABLE PASWD THEN */
      /* Undeployed code */
      
/*      MESSAGE   "before ttPayment".*/
      FOR EACH ttPayment:
          //MESSAGE "invoice_num" invoice_num "order_number " order_number  "payment_type:" payment_type
          //"payment_amt" payment_amt "cheque_num" cheque_num "discount_amt" discount_amt.
          
          IF ttPayment.discount_amt EQ ? THEN MESSAGE 0.
          
          IF ttPayment.payment_type EQ "Online":U AND NUM-ENTRIES(ttPayment.cheque_num,"|") NE 2 THEN   // Wrong payment type received from frontend
          DO:
            DELETE ttPayment.
            
          END.
          ELSE IF ttPayment.payment_type EQ "Online":U AND NUM-ENTRIES(ttPayment.cheque_num,"|") EQ 2 THEN 
          DO:
              
              ASSIGN lcOnlineRefId        = ENTRY(1,ttPayment.cheque_num,"|")
                     lcOnlineTransId      = ENTRY(2,ttPayment.cheque_num,"|")
                     ttPayment.cheque_num = "".
                  
          END.
           
      END.
      
      FOR FIRST ttCheckoutCustomer:
        
        IF NUM-ENTRIES(ttCheckoutCustomer.po_number,"|") GT 2 THEN 
        ASSIGN  lcComment                    = ENTRY(2,ttCheckoutCustomer.po_number,"|")
                lcSendEmailForOrder          = ENTRY(3,ttCheckoutCustomer.po_number,"|")
                ttCheckoutCustomer.po_number = ENTRY(1,ttCheckoutCustomer.po_number,"|").
        
        ELSE IF NUM-ENTRIES(ttCheckoutCustomer.po_number,"|") GT 1 THEN 
        ASSIGN  lcComment                    = ENTRY(2,ttCheckoutCustomer.po_number,"|")
                ttCheckoutCustomer.po_number = ENTRY(1,ttCheckoutCustomer.po_number,"|").
                
        
       FIND FIRST shpto WHERE SHPTO.CUST-NUMBER eq  ttCheckoutCustomer.cust_number
                           AND SHPTO.SHIP-NUMBER eq  ttCheckoutCustomer.ship_to_no NO-LOCK NO-ERROR.
        IF AVAILABLE shpto THEN 
           ASSIGN ttCheckoutCustomer.shippingAdL1 = SHPTO.ADDRESS-L1 
                  ttCheckoutCustomer.shippingAdL2 = SHPTO.ADDRESS-L2
                  ttCheckoutCustomer.shippingAdL3 = SHPTO.ADDRESS-L3.
                  
        FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "OEDSLDE-default-route" 
                             AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
                     
                     
        DEFINE VARIABLE DeafaultRoute  AS LOGICAL NO-UNDO.
        DEFINE VARIABLE opdDateWanted AS DATE.
        DEFINE VARIABLE opcShipViaCd  AS CHARACTER.
        DEFINE VARIABLE opcRoute      AS CHARACTER.
        DEFINE VARIABLE opcRouteStop  AS CHARACTER.
         
        ASSIGN DeafaultRoute = AVAILABLE PARAMFL.
        
        IF DeafaultRoute THEN
        THIS-OBJECT:assignDeliveryRoute(INPUT  COMPANY,
                                       INPUT   ttCheckoutCustomer.cust_number,
                                       INPUT   ttCheckoutCustomer.ship_to_no,
                                       INPUT   TODAY,                            
                                       OUTPUT opdDateWanted,
                                       OUTPUT opcShipViaCd,
                                       OUTPUT opcRoute,
                                       OUTPUT opcRouteStop).
                                       
                                       MESSAGE "opdDateWanted " opdDateWanted SKIP 
                                       "opcShipViaCd " opcShipViaCd SKIP 
                                       "opcRoute " opcRoute SKIP 
                                       "opcRouteStop " opcRouteStop SKIP 
                                       
                                       VIEW-AS ALERT-BOX.                           
                                  
        CREATE TMP-HEADER.
        ASSIGN TMP-HEADER.TMP-NUMBER   = ttCheckoutCustomer.temp_number
               TMP-HEADER.CUST-NUMBER  = ttCheckoutCustomer.cust_number
               TMP-HEADER.CUST-NAME    = ttCheckoutCustomer.cust_name
               //TMP-HEADER.CUS-TERMS-CD = ttCheckoutCustomer.payment_term
               TMP-HEADER.CUS-TERMS-DS = ttCheckoutCustomer.payment_term
               TMP-HEADER.SHIP-TO-NO   = ttCheckoutCustomer.ship_to_no
               TMP-HEADER.SHIP-ADDR-L1 = ttCheckoutCustomer.shippingAdL1
               TMP-HEADER.SHIP-ADDR-L2 = ttCheckoutCustomer.shippingAdL2
               TMP-HEADER.SHIP-ADDR-L3 = ttCheckoutCustomer.shippingAdL3
               TMP-HEADER.LAPTOP       = ttCheckoutCustomer.regular_salesman
               TMP-HEADER.CUS-ORDER-NO = ttCheckoutCustomer.po_number
               TMP-HEADER.DATE-WANTED  = IF ttCheckoutCustomer.date_wanted = ? AND DeafaultRoute THEN opdDateWanted ELSE ttCheckoutCustomer.date_wanted
               TMP-HEADER.CONFIRM-IND  = IF ttCheckoutCustomer.order_on_hold BEGINS "H":U AND lPASWDExist THEN cInd ELSE ""
               TMP-HEADER.SHIP-VIA-CD  = IF opcShipViaCd <> ? THEN opcShipViaCd ELSE ""
               TMP-HEADER.ROUTE        = IF opcRoute     <> ? THEN opcRoute     ELSE ""   
               TMP-HEADER.ROUTE-STOP   = IF opcRouteStop <> ? THEN opcRouteStop ELSE "" . /* undeployed - when order on hold */ 
               
               MESSAGE "TMP-HEADER.ROUTE " TMP-HEADER.ROUTE
               VIEW-AS ALERT-BOX.                      
                
      END. /* FOR FIRST ttCheckoutCustomer */
 
      FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ TMP-HEADER.CUST-NUMBER NO-LOCK NO-ERROR. /* JKT */
      IF AVAILABLE CCSMS THEN
      DO: 
        ASSIGN TMP-HEADER.CUS-TERMS-CD = CCSMS.TERMS-CODE.
        
        ASSIGN TMP-HEADER.CUST-NAME = REPLACE(CCSMS.CUST-NAME,"'", "") . //CCSMS.CUST-NAME.
         
        IF TMP-HEADER.SHIP-ADDR-L1 = ""  THEN 
        TMP-HEADER.SHIP-ADDR-L1 = CCSMS.PHYS-ADD-1.
        IF TMP-HEADER.SHIP-ADDR-L2 = "" THEN 
        TMP-HEADER.SHIP-ADDR-L2 = CCSMS.PHYS-ADD-2.
        IF TMP-HEADER.SHIP-ADDR-L3 = "" THEN 
        TMP-HEADER.SHIP-ADDR-L3 = CCSMS.PHYS-ADD-3.
        IF  TMP-HEADER.CUS-ORDER-NO EQ "":U AND CCSMS.ORG-TYPE MATCHES "P":U THEN
        DO:
          /* Get multilingual message for blank PO number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200PONumberBlank,                                                              
                                   OUTPUT opcError,
                                   OUTPUT opiStatusCode).
        
          IF opcError NE "":U THEN 
            UNDO,THROW NEW AppError(opcError,1).
            
        END. /* IF  TMP-HEADER.CUS-ORDER-NO EQ "":U AND CCSMS.ORG-TYPE MATCHES "P":U THEN  */
      END. /* IF AVAILABLE CCSMS */
      
      IF ipcUserType EQ ConstantInitializer:cMobileUser THEN
        ASSIGN cSalespersonId  = ipcUserId
               cCustomerNumber = TMP-HEADER.CUST-NUMBER.
      ELSE
        ASSIGN cSalespersonId  = "":U
               cCustomerNumber = ipcUserId.  
      
      lcLoggedinSalesRep = cSalespersonId.
                     
      DEFINE VARIABLE iSeq     AS INTEGER  NO-UNDO.
      DEFINE VARIABLE iLastSeq AS INTEGER  NO-UNDO.
      
      
      FIND LAST ttCheckoutProducts NO-LOCK NO-ERROR.
      IF AVAILABLE ttCheckoutProducts THEN 
          ASSIGN lastSeq = ttCheckoutProducts.item_sequence.
      
      FOR EACH ttCheckoutProducts:
          IF INDEX(ttCheckoutProducts.item_number,"KIT") GT 0 THEN 
          DO:
             
             
              CREATE ttset.
               ASSIGN ttset.item_no     = SUBSTRING(ttCheckoutProducts.item_number,INDEX(ttCheckoutProducts.item_number,"KIT") + 3)
                      ttset.parent_item = SUBSTRING(ttCheckoutProducts.item_number,1, INDEX(ttCheckoutProducts.item_number,"KIT") - 2)
                      ttset.Set_id      = "D"
                      ttset.Price-zero  = YES
                      .
                      
               ASSIGN ttCheckoutProducts.item_number =  SUBSTRING(ttCheckoutProducts.item_number,INDEX(ttCheckoutProducts.item_number,"KIT") + 3)
                      ttCheckoutProducts.item_description = ttset.parent_item.
                     
               
             DELETE ttCheckoutProducts.  
               
          END. 
          
           /* Required the below code for offline mode of mobile - Start*/
          FIND FIRST paramfl WHERE PARAMFL.PARAM-ID = "LEY172-FAMILY" 
                                AND PARAMFL.COMPANY-CODE = COMPANY 
                                AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
                                    
         IF AVAILABLE paramfl THEN 
         DO:
            FIND FIRST cinv1 WHERE cinv1.item-number = ttCheckoutProducts.item_number  NO-LOCK NO-ERROR.
            IF AVAILABLE cinv1 AND INDEX(PARAMFL.PARAM-VALUE1, CINV1.FAMILY ) GT 0  THEN
            DO:
                 FIND FIRST bfcinv1 WHERE bfcinv1.ITEM-NUMBER EQ  PARAMFL.PARAM-VALUE2 NO-LOCK NO-ERROR.
                 IF AVAILABLE bfcinv1 THEN 
                 DO: 
                    FIND FIRST bf2-ttCheckoutProducts WHERE bf2-ttCheckoutProducts.item_number = ttCheckoutProducts.item_number + "-LEY172" NO-LOCK NO-ERROR.
                    IF NOT AVAILABLE bf2-ttCheckoutProducts THEN 
                    DO:
                        CREATE bf2-ttCheckoutProducts.
                        ASSIGN bf2-ttCheckoutProducts.item_number = ttCheckoutProducts.item_number + "-LEY172".
                        BUFFER-COPY ttCheckoutProducts EXCEPT ttCheckoutProducts.item_number TO bf2-ttCheckoutProducts.
                        ASSIGN bf2-ttCheckoutProducts.unit_price    = bfcinv1.ACCTING-COST
                               bf2-ttCheckoutProducts.item_sequence = lastSeq + 1
                               lastSeq                              = bf2-ttCheckoutProducts.item_sequence.
                    END. 
                  END.     
            END.      
         END.  
         /* End here*/ 
      END.
         
      /* See if the item in the checkout has child items to add */
      
            
      FOR EACH ttCheckoutProducts BREAK BY ttCheckoutProducts.item_number:
          
         IF FIRST-OF(ttCheckoutProducts.item_number) THEN
         DO:
/*             MESSAGE "ttCheckoutProducts.item_number=" ttCheckoutProducts.item_number ttCheckoutProducts.quantity*/
/*             VIEW-AS ALERT-BOX.                                                                                  */
           //FIND FIRST cinv1 WHERE cinv1.item-number = ttCheckoutProducts.item_number NO-LOCK NO-ERROR.  
           //ttCheckoutProducts.item_number = SUBSTRING(ttCheckoutProducts.item_number,INDEX(ttCheckoutProducts.item_number,"KIT") + 3)
           FIND FIRST sethd WHERE SETHD.SET-NO EQ ttCheckoutProducts.item_number NO-LOCK NO-ERROR.
           IF AVAILABLE SETHD THEN
           DO:
               
               CREATE tt-checkout.
               BUFFER-COPY ttCheckoutProducts TO tt-checkout.
               tt-checkout.item_description = "".
               FOR EACH setdt WHERE SETDT.SET-NO EQ sethd.set-no NO-LOCK:
                   //FIND FIRST  bf-ttCheckoutProducts WHERE  bf-ttCheckoutProducts.item_number = SETDT.ITEM-NUMBER NO-LOCK NO-ERROR.
                  // IF AVAILABLE bf-ttCheckoutProducts THEN 
                  // DO:
                      CREATE tt-checkout.
                     // BUFFER-COPY bf-ttCheckoutProducts TO tt-checkout.
                     ASSIGN tt-checkout.temp_number = ttCheckoutProducts.temp_number
                            tt-checkout.item_number = SETDT.ITEM-NUMBER
                            tt-checkout.unit_price  = 0 
                            tt-checkout.item_total_price = 0.
      
                     // BUFFER-COPY ttCheckoutProducts TO tt-checkout.
                      ASSIGN tt-checkout.quantity = ttCheckoutProducts.quantity * SETDT.QTY
                             tt-checkout.item_description = sethd.set-no.
                            
                  // END.    
               END.     
              
           END.  //IF AVAILABLE SETHD THEN
           ELSE 
           DO:
               CREATE tt-checkout.
               BUFFER-COPY ttCheckoutProducts TO tt-checkout.
               tt-checkout.item_description = "NOT A KIT ITEM".
           END.    
         
          
                                            
         END.     
      END.    
      FOR EACH tt-checkout:
         
          FIND FIRST ttCheckoutProducts WHERE ttCheckoutProducts.item_number = tt-checkout.item_number NO-ERROR.
          IF AVAILABLE ttCheckoutProducts THEN 
          DO:
              DELETE ttCheckoutProducts.
          END.     
      END.
      
      FOR EACH tt-checkout:
          
          CREATE ttCheckoutProducts.
          BUFFER-COPY tt-checkout TO ttCheckoutProducts.
      END.   
        
      //FOR EACH ttCheckoutProducts BREAK BY ttCheckoutProducts.item_number:
      FOR EACH ttCheckoutProducts:    
        
        IF NUM-ENTRIES(ttCheckoutProducts.item_color,"|") EQ 3 THEN 
          ASSIGN ttCheckoutProducts.item_color  =  ENTRY(1,ttCheckoutProducts.item_color,"|").     
        
        FIND FIRST paramfl WHERE PARAMFL.PARAM-ID = "LEY172-FAMILY" 
                                AND PARAMFL.COMPANY-CODE = COMPANY 
                                AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
           IF AVAILABLE paramfl AND INDEX (ttCheckoutProducts.item_number,"LEY172") GT 0  THEN 
               ASSIGN ttCheckoutProducts.item_number = IF PARAMFL.PARAM-VALUE2 NE "" THEN PARAMFL.PARAM-VALUE2 ELSE ttCheckoutProducts.item_number
                      ley172ItemNumber               = PARAMFL.PARAM-VALUE2. 
                                
        FIND FIRST bfcinv3 WHERE bfcinv3.ITEM-NUMBER EQ  ttCheckoutProducts.item_number NO-LOCK NO-ERROR.                  
        IF ttCheckoutProducts.item_size NE "":U THEN
        DO:
           //IF FIRST-OF(ttCheckoutProducts.item_number) THEN
           //DO:
            
             FIND FIRST TMP-DETAIL WHERE TMP-DETAIL.TMP-NUMBER  EQ ttCheckoutProducts.temp_number 
                                     AND TMP-DETAIL.ITEM-NUMBER EQ ttCheckoutProducts.item_number 
                                     AND TMP-DETAIL.PRICE       EQ ttCheckoutProducts.unit_price no-lock no-error.
             if not available TMP-DETAIL then 
             DO:                        
                 iSeq = iSeq + 1.
                 CREATE TMP-DETAIL.
                 ASSIGN TMP-DETAIL.TMP-NUMBER   = ttCheckoutProducts.temp_number
                         TMP-DETAIL.TMP-SEQ     = iSeq
                         TMP-DETAIL.ITEM-NUMBER = ttCheckoutProducts.item_number
                         TMP-DETAIL.DESCRIPTION = IF AVAILABLE bfcinv3 THEN bfcinv3.DESCRIPTION ELSE "" // ttCheckoutProducts.item_description
                         
                         //TMP-DETAIL.QUANTITY    = ttCheckoutProducts.itemTotQty //ttCheckoutProducts.quantity
                         TMP-DETAIL.PRICE       = ttCheckoutProducts.unit_price  
                         TMP-DETAIL.EXTENSION   = ttCheckoutProducts.item_total_price
                         TMP-DETAIL.dt-char3    = ttCheckoutProducts.item_description.
                         
                        
              end.           
          // END. /* IF first-of(ttCheckoutProducts.item_number) then */
           
           /*Logic to calculate total quantities of all items of same size and total prices of items */
           FIND FIRST TMP-DETAIL WHERE TMP-DETAIL.ITEM-NUMBER EQ ttCHeckoutProducts.ITEM_NUMBER NO-ERROR.
           IF AVAIL TMP-DETAIL THEN
           DO:  
             ASSIGN TMP-DETAIL.QUANTITY  = TMP-DETAIL.quantity + ttCheckoutProducts.quantity.
                  /*TMP-DETAIL.PRICE     = TMP-DETAIL.PRICE    + ttCheckoutProducts.item_total_price.*/
           END.
           
            FIND FIRST SIZE WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo 
                            AND SIZE.ITEM-NUMBER  EQ ttCheckoutProducts.item_number
                            AND SIZE.SIZE         EQ ttCheckoutProducts.item_size NO-LOCK NO-ERROR.
            
            FIND FIRST TMP-DETAIL WHERE TMP-DETAIL.ITEM-NUMBER EQ ttCheckoutProducts.item_number NO-LOCK NO-ERROR.
            IF NOT CAN-FIND (FIRST SIZE-Selected WHERE SIZE-Selected.INVOICE-NUMBER EQ ttCheckoutProducts.temp_number  
                                                   AND SIZE-Selected.INVOICE-SEQ    EQ TMP-DETAIL.TMP-SEQ
                                                   AND SIZE-Selected.ITEM-NUMBER    EQ ttCheckoutProducts.item_number
                                                   AND SIZE-Selected.STYLE-COLOR    EQ (IF AVAILABLE SIZE THEN SIZE.STYLE-COLOR ELSE "":U)
                                                   AND SIZE-Selected.SIZE           EQ ttCheckoutProducts.item_size)   THEN 
            DO:                                         
               CREATE SIZE-SELECTED.
               ASSIGN SIZE-SELECTED.INVOICE-NUMBER = ttCheckoutProducts.temp_number
                      SIZE-SELECTED.INVOICE-SEQ    = TMP-DETAIL.TMP-SEQ //ttCheckoutProducts.item_sequence
                      SIZE-SELECTED.ITEM-NUMBER    = ttCheckoutProducts.item_number
                      SIZE-SELECTED.STYLE-COLOR    = IF AVAILABLE SIZE THEN SIZE.STYLE-COLOR ELSE "":U
                      SIZE-SELECTED.SIZE           = ttCheckoutProducts.item_size
                      SIZE-SELECTED.SIZE-QTY       = ttCheckoutProducts.quantity.
           END.      
        END. /* if ttCheckoutProducts.item_size NE "":U then */
        
        ELSE
        DO:
          /* when an order contains mixed items i.e by-size and by-color then records will be created for same 
             sequence numbers, to avoid this find last */
          FIND LAST tmp-detail   WHERE tmp-detail.TMP-NUMBER = tmp-header.TMP-NUMBER NO-LOCK NO-ERROR.
       
          IF AVAILABLE tmp-detail THEN 
             iLastSeq = tmp-DETAIL.TMP-SEQ .
          ELSE 
             iLastSeq = 0 .
       
          FIND FIRST TMP-DETAIL WHERE TMP-DETAIL.TMP-NUMBER  EQ ttCheckoutProducts.temp_number 
                                  AND TMP-DETAIL.ITEM-NUMBER EQ ttCheckoutProducts.item_number 
                                  AND TMP-DETAIL.PRICE       EQ ttCheckoutProducts.unit_price 
                                  AND TMP-DETAIL.QUANTITY    EQ ttCheckoutProducts.quantity 
                                  AND TMP-DETAIL.PRICE       EQ ttCheckoutProducts.unit_price
                                  AND TMP-DETAIL.EXTENSION   EQ ttCheckoutProducts.item_total_price
                                  no-lock no-error.
          FIND FIRST setdt WHERE SETDT.ITEM-NUMBER EQ ttCheckoutProducts.item_number NO-LOCK NO-ERROR.                        
          IF NOT AVAILABLE TMP-DETAIL OR (ley172ItemNumber  NE "" AND ttCheckoutProducts.item_number EQ ley172ItemNumber) 
          OR (AVAILABLE setdt )THEN 
          DO: 
                                       
              CREATE TMP-DETAIL.
              ASSIGN TMP-DETAIL.TMP-NUMBER  = ttCheckoutProducts.temp_number
                     iLastSeq               = iLastSeq + 1 
                     TMP-DETAIL.TMP-SEQ     = iLastSeq //ttCheckoutProducts.item_sequence  
                     TMP-DETAIL.ITEM-NUMBER = ttCheckoutProducts.item_number
                     TMP-DETAIL.DESCRIPTION = IF AVAILABLE bfcinv3 THEN bfcinv3.DESCRIPTION ELSE "" // ttCheckoutProducts.item_description
                     TMP-DETAIL.QUANTITY    = ttCheckoutProducts.quantity
                     TMP-DETAIL.PRICE       = ttCheckoutProducts.unit_price
                     TMP-DETAIL.EXTENSION   = ttCheckoutProducts.item_total_price
                     TMP-DETAIL.dt-char3    = ttCheckoutProducts.item_description.
                     
          END.     
            
          IF /*ttCheckoutProducts.item_color NE "":U OR*/
             ttCheckoutProducts.item_size NE "":U THEN
          DO: 
            FIND FIRST SIZE WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo 
                              AND SIZE.ITEM-NUMBER  EQ ttCheckoutProducts.item_number
                              AND SIZE.SIZE         EQ ttCheckoutProducts.item_size NO-LOCK NO-ERROR.
            
            IF NOT CAN-FIND (FIRST SIZE-Selected WHERE SIZE-Selected.INVOICE-NUMBER EQ ttCheckoutProducts.temp_number  
                                                   AND SIZE-Selected.INVOICE-SEQ    EQ ttCheckoutProducts.item_sequence
                                                   AND SIZE-Selected.ITEM-NUMBER    EQ ttCheckoutProducts.item_number
                                                   AND SIZE-Selected.STYLE-COLOR    EQ (IF AVAILABLE SIZE THEN SIZE.STYLE-COLOR ELSE "":U)
                                                   AND SIZE-Selected.SIZE           EQ ttCheckoutProducts.item_size)   THEN
            DO:        
              CREATE SIZE-SELECTED.
              ASSIGN SIZE-SELECTED.INVOICE-NUMBER = ttCheckoutProducts.temp_number
                     SIZE-SELECTED.INVOICE-SEQ    = ttCheckoutProducts.item_sequence
                     SIZE-SELECTED.ITEM-NUMBER    = ttCheckoutProducts.item_number
                     SIZE-SELECTED.STYLE-COLOR    = IF AVAILABLE SIZE THEN SIZE.STYLE-COLOR ELSE "":U
                     SIZE-SELECTED.SIZE           = ttCheckoutProducts.item_size.
             END.        
          END. /* IF ttCheckoutProducts.item_size NE "" */
                 
        END. /* else- if ttCheckoutProducts.item_size NE "":U then */                      
      END. /* FOR EACH ttCheckoutProducts */       
      
      /* Contains entire payment details */
/*      MESSAGE "temp-table ttPayment:has-records: " TEMP-TABLE ttPayment:HAS-RECORDS .*/

      FOR EACH ttPayment:
       // MESSAGE  ' ttPayment.payment_type ' ttPayment.payment_type " ttPayment.payment_amt " ttPayment.payment_amt.
      
        IF ttPayment.payment_type EQ "invoice":U THEN    
          ASSIGN ipdeInvoicePayAmt = ipdeInvoicepayAmt + ttPayment.payment_amt.
        
        IF ttPayment.payment_type EQ "online":U THEN
          ASSIGN ipdeOnlinePayAmt  = ipdeOnlinePayAmt + ttPayment.payment_amt. 
        
        /* Total amount paid by the customer while checking out/submitting order */
        ASSIGN ipdeTotalPayAmt = ipdeTotalPayAmt + ttPayment.payment_amt
               ldDiscountAmt   = IF ttPayment.discount_amt EQ ? THEN 0 ELSE ttPayment.discount_amt.
               
                       
      END. /* FOR EACH ttPayment */   
      
      IF ldDiscountAmt NE 0 THEN 
      ASSIGN ldDiscountPer   = (ldDiscountAmt / ipdeNetPaymentAmount) * 100.
      
      IF AVAILABLE TMP-HEADER THEN 
      ASSIGN TMP-HEADER.DISCOUNT-AMT = ldDiscountAmt
             TMP-HEADER.DISC-PERC    = ldDiscountPer.
             
      /* Undeployed code - Validation to check if payment amt is less than 0 then should not proceed further */
      /*IF ipdeTotalPayAmt LE 0 THEN
      DO:
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200AmtLessEQZero,                                                              
                                 OUTPUT opcError,
                                 OUTPUT opiStatusCode).
       IF opcError NE "":U THEN 
         UNDO,THROW NEW AppError(opcError,1).                                 
      END.*/
      /* Undeployed code */
      
      /* commented - 090818
      IF ipdeInvoicePayAmt NE 0 AND ipdeInvoicePayAmt GT ipdeAvailableCreditLimit THEN
      DO:
         /* Get multilingual message for invoice amount greater than available credit amount */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvoiceAmountExceed,                                                              
                                 OUTPUT opcError,
                                 OUTPUT opiStatusCode).
        
        IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).
      END.    
      */      
     // MESSAGE 'checkout class payment ipdeTotalPayAmt: ' ipdeTotalPayAmt ' ipdeNetPaymentAmount:' ipdeNetPaymentAmount
     //         'LESS AMOUNT PAID ' ipdeTotalPayAmt LT ipdeNetPaymentAmount.
      
      /* Check for amount paid by user is less than order total */
      IF ipdeTotalPayAmt LT ipdeNetPaymentAmount THEN
      DO:
        /* Get multilingual message for less payment amount */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200LessPayAmount,                                                              
                                 OUTPUT opcError,
                                 OUTPUT opiStatusCode).
        
        IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).  
      END. /* IF ipdeTotalPayAmt LT ipdeNetPaymentAmount */
      
      IF ipdeOnlinePayAmt GT ipdeNetPaymentAmount THEN
      DO:
        /* Get multilingual message for online payment amount exceeded */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200OnlineAmountExceed,                                                              
                                 OUTPUT opcError,
                                 OUTPUT opiStatusCode).
        
        IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).  
      END. 
      
      /* initiate order submission */     
      THIS-OBJECT:initiateCheckout(INPUT ipiWarehouseNo,
                                   INPUT ipcUserType,
                                   INPUT ipcLangID,                                   
                                   OUTPUT opcError,
                                   OUTPUT opiStatusCode).
      IF opcError NE "":U THEN 
        UNDO,THROW NEW AppError(opcError,1). 
         
      ASSIGN INVOICE-NUM = THIS-OBJECT:INVOICE-NUM.
      
      FOR EACH ttPayment NO-LOCK:
        
       
                
      /*  MESSAGE 'checkout class  ttPayment.payment_type ' ttPayment.payment_type ' TMP-HEADER.CUST-NUMBER ' TMP-HEADER.CUST-NUMBER 
              'ttPayment.payment_amt ' ttPayment.payment_amt ' ttPayment.cheque_num ' ttPayment.cheque_num . */ 
              
         IF ttPayment.payment_type EQ "Online":U THEN  
         DO:
            CREATE onlineTrans.
            ASSIGN onlineTrans.ServiceId    = "Serv01":U
                   onlineTrans.Order-number = INVOICE-NUM
                   onlineTrans.RefId        =  lcOnlineRefId
                   onlineTrans.TransId      = lcOnlineTransId
                   onlineTrans.payamt       = ttPayment.payment_amt
                   onlineTrans.paydate      = NOW.
                   
             NEXT.      
                   
          END.         
        
         IF ttPayment.payment_type EQ "invoice":U OR trim(ttPayment.payment_type) EQ "":U THEN
          NEXT.
          
/*          MESSAGE "before payment".*/
          
        /* initiate payment processing */
        objPaymentProcessing:mainBlock(INPUT "":U,
                                       INPUT TMP-HEADER.CUST-NUMBER ,
                                       INPUT INVOICE-NUM,
                                       INPUT ttPayment.payment_type,
                                       INPUT ttPayment.payment_amt,
                                       INPUT ttPayment.cheque_num,
                                       INPUT ipcLangID ,
                                       INPUT 0.0,
                                       OUTPUT opcError,
                                       OUTPUT opiStatusCode). 
                                       
/*        MESSAGE ' opcError ' opcError.*/
                                               
        IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).  
        
                                  
          
      END. /* FOR EACH ttPayment */   
                             
      orderJsonObj:ADD(INPUT "order_number":U,  INPUT INVOICE-NUM).
      orderJsonObj:ADD(INPUT "order_date":U,    INPUT TODAY).
      
      ASSIGN oplcCheckoutData = orderJsonObj:GetJsonText()
             opiStatusCode    = 200.
      
      /* Code to remove product from cart when order is successfully placed */
      FIND FIRST CartHeader WHERE CartHeader.Sales-Rep-ID EQ cSalespersonId
                              AND CartHeader.Cust-Number  EQ cCustomerNumber
                              AND CartHeader.Cart-Status  NO-LOCK NO-ERROR.
      IF AVAILABLE CartHeader THEN
      DO:
        FIND CURRENT CartHeader EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF AVAILABLE CartHeader THEN
        DO:
          //ASSIGN CartHeader.Cart-Status = FALSE.
         // RELEASE CartHeader.
         FOR EACH cartdetail WHERE CartDetail.Cart-ID EQ CartHeader.Cart-Id EXCLUSIVE-LOCK:
             DELETE cartdetail.
         END.    
         DELETE cartheader.
        END.  
      END. /* IF AVAILABLE CartHeader THEN */                        
      
      /* Store message of the Order */
      IF lccomment NE "" THEN 
      DO:
          CREATE MESSG.
          ASSIGN MESSG.FILE-NAME    = "MSGOE"
                 MESSG.DOC-NUMBER   = INVOICE-NUM
                 MESSG.DOC-SEQUENCE = 9990
                 MESSG.MESSAGE-DESC = lccomment
                 MESSG.MESSAGE-SEQ  = 1.
      END. 
      DEFINE VARIABLE lcorder-status AS CHARACTER NO-UNDO.   
      RELEASE COOHD.
      
     RUN  oeholdck.p(INPUT INVOICE-NUM, // The program is storing order-number in the field Invoice-num, Commenting here to avoid any confusion
                      OUTPUT lcorder-status). 
          
      THIS-OBJECT:releaseFiles(). /* R.S */
            
      CATCH errorObj AS AppError:           
        ASSIGN 
          opcError = errorObj:GetMessage(1).
      END CATCH.

      FINALLY:
        IF VALID-OBJECT(orderJsonObj) THEN  
          DELETE OBJECT orderJsonObj.  
        IF VALID-OBJECT(objCommonSrc) THEN  
          DELETE OBJECT objCommonSrc. 
        IF VALID-OBJECT(objPaymentProcessing) THEN  
          DELETE OBJECT objPaymentProcessing.  
      END FINALLY.

    END METHOD.

    /*------------------------------------------------------------------------------
       Purpose: Entry point from where all the processing required to generate new
                order will be performed. 
       Input Parameters: 
                     1. COMPANY   - company code selected for the logged in user/salesperson.
                     2. ipcLangID - language Id,
       Output Parameters:
                     1. opcError      - returns error if any,
                     2. opiStatusCode - HTTP status code.
       Input-Output Parameters:
                     1. INVOICE-NUM   - Stores new order number number.
                     2. TMP-HEADER    - Temp-table used to store customer details.
                     3. TMP-DETAIL    - Temp-table used to store item details selected for checkout
                     4. SIZE-SELECTED - Temp-table used to store size and color of an item selected for checkout
       Notes:                          
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID initiateCheckout(INPUT ipiWarehouseNo      AS INTEGER,
                                        INPUT ipcUserType         AS CHARACTER,
                                        INPUT ipcLangID           AS CHARACTER,                                       
                                        OUTPUT opcError           AS CHARACTER,
                                        OUTPUT opiStatusCode      AS INTEGER):
        
      DEFINE VARIABLE PHYSICAL-ZIP AS CHARACTER NO-UNDO.
 
      DEFINE VARIABLE objCommonSrc AS CLASS CommonSource  NO-UNDO.
           
      ASSIGN objCommonSrc = NEW CommonSource(INPUT cToken).
                     
      /*ASSIGN CALL-PROG = PROGRAM-NAME(2).*/ /* R.S */
      
      FIND TMP-HEADER WHERE TMP-HEADER.TMP-NUMBER EQ INVOICE-NUM EXCLUSIVE-LOCK NO-ERROR.
      IF NOT AVAILABLE TMP-HEADER THEN
      DO:           
        /* Get multilingual message for invalid order number check */
        
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvalidOrderNum,                                                              
                                 OUTPUT opcError,
                                 OUTPUT opiStatusCode).
        
        IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).
          
      END.
     
      /********************************************************/
      /* READ ALL PARAMFL AND TURN ON FLAGS ACCORDINGLY       */
      /********************************************************/
    
      THIS-OBJECT:paramSetup().
           
      IF TMP-HEADER.TMP-NUMBER EQ "TMP-NUMBER":U THEN 
        THIS-OBJECT:getNextNumber().
             
      IF TRANS-TYPE EQ "2":U AND 
         DELIV-ORDER         AND 
         TMP-HEADER.CUST-NUMBER EQ SUBSTRING("LA":U + USER("CDI":U),1,6) THEN
         
      REPEAT WHILE TMP-HEADER.CUST-NUMBER EQ SUBSTRING("LA":U + USER("CDI":U),1,6):
          
        FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ invoice-num NO-LOCK NO-ERROR.
        IF NOT AVAILABLE CCSMS THEN
        DO:
          FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ TMP-HEADER.CUST-NUMBER EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
          IF AVAILABLE CCSMS THEN
            ASSIGN 
              CCSMS.CUST-NUMBER      = INVOICE-NUM
              CCSMS.CUST-TYPE        = "LAYAWAY":U.   
              TMP-HEADER.CUST-NUMBER = INVOICE-NUM.
            
        END. /* IF NOT AVAILABLE CCSMS THEN */
        ELSE
          THIS-OBJECT:getNextNumber().
               
      END. /* REPEAT WHILE TMP-HEADER.CUST-NUMBER...*/
                       
      IF INVOICE-NUM EQ "":U OR INVOICE-NUM EQ TMP-HEADER.TMP-NUMBER THEN
      DO:      
        /* Get multilingual message for unknown error */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c500UnknownError,                                                              
                                 OUTPUT opcError,
                                 OUTPUT opiStatusCode).
        
        IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).
          
      END.
      
      FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ TMP-HEADER.CUST-NUMBER NO-LOCK NO-ERROR. /* R.S */
       FIND FIRST shpto WHERE SHPTO.CUST-NUMBER EQ TMP-HEADER.CUST-NUMBER
                         AND SHPTO.SHIP-NUMBER = tmp-header.SHIP-TO-NO NO-LOCK NO-ERROR.       
      ASSIGN  TMP-HEADER.SALES-REP-ID      = IF lcOrder-Origin = "WEB":U THEN CCSMS.SALES-REP-ID ELSE lcLoggedinSalesRep //CCSMS.SALES-REP-ID
              TMP-HEADER.WAREHOUSE-NO      = ipiWarehouseNo
              TMP-HEADER.ADDRESS-L1        =  CCSMS.ADDRESS-L1
              TMP-HEADER.ADDRESS-L2        =  CCSMS.ADDRESS-L2 
              TMP-HEADER.ADDRESS-L3        =  CCSMS.ADDRESS-L3       
              TMP-HEADER.SHIP-TO-NAME      = IF AVAILABLE shpto THEN SHPTO.CUST-NAME ELSE CCSMS.CUST-NAME 
              TMP-HEADER.CUST-PHONE-NUMBER = CCSMS.PHONE-NUMBER            
              PHYSICAL-ZIP                 = IF NUM-ENTRIES(CCSMS.PHYS-ADD-3) GE 3 THEN ENTRY(3,CCSMS.PHYS-ADD-3) ELSE "":U NO-ERROR. /* R.S */
                     
      IF PHYSICAL-ZIP NE "":U THEN
          ASSIGN TMP-HEADER.PHYSICAL-ZIP = PHYSICAL-ZIP.
/*        ASSIGN TMP-HEADER.PHYSICAL-ZIP = INTEGER(PHYSICAL-ZIP) NO-ERROR. /* R.S */*/
      
      IF ipcUserType EQ ConstantInitializer:cMobileUser THEN
        ASSIGN TMP-HEADER.OPERATOR = lcLoggedinSalesRep. //CCSMS.SALES-REP-ID.
      ELSE
        ASSIGN TMP-HEADER.OPERATOR = CCSMS.CUST-NUMBER. /* R.S */ 
      
      /* For mobile application, discount is provided by sales rep. No need to calculate this here in this case */
      /* IF CCSMS.DISC-PERC GT 0 THEN 
        ASSIGN PERCENT              = CCSMS.DISC-PERC
               TMP-HEADER.DISC-PERC = PERCENT NO-ERROR. */ /* R.S */
               
      /* Calculates the taxes */
      THIS-OBJECT:getTotal(). /* R.S */
      
      IF opcError NE "":U THEN 
        UNDO,THROW NEW AppError(opcError,1). /* R.S */                     
               
      FIND CURRENT CCSMS EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
      
      IF TRANS-TYPE EQ "2":U THEN
      DO:  
        THIS-OBJECT:orderFromHeader().
        
        THIS-OBJECT:orderFromDetail().
                 
      END.
    
      THIS-OBJECT:renumberMessg().
         
      //THIS-OBJECT:releaseFiles().
         
      CATCH errorObj AS AppError:           
        ASSIGN 
          opcError = errorObj:GetMessage(1).
      END CATCH.

      FINALLY:
        IF VALID-OBJECT(objCommonSrc) THEN  
          DELETE OBJECT objCommonSrc. 
      END FINALLY.
        
    END METHOD. /* END checkoutMainBlock */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    METHOD PUBLIC VOID calculateDiscount(  ):
        
     /* IF percent > 0 THEN
       tmp-header.discount-amt = tmp-header.gross-amount * ( percent / 100).
     ELSE 
       tmp-header.discount-amt = 0.
 */
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID paramSetup():
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID      EQ "ROUTE-VIA":U
                     AND PARAMFL.COMPANY-CODE  EQ COMPANY
                     AND PARAMFL.PARAM-STATUS  NO-LOCK NO-ERROR.
      ASSIGN route-via = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "NO-CUCNF-MESSG":U 
                     AND PARAMFL.COMPANY-CODE EQ COMPANY  
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      ASSIGN NO-CUCNF-MESSG = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE  EQ COMPANY
                     AND PARAMFL.PARAM-ID      EQ "PRECIO-AL-COMPONENTE":U
                     AND PARAMFL.PARAM-STATUS  NO-LOCK NO-ERROR.
      ASSIGN PRECIO-AL-COMPONENTE = AVAIL PARAMFL .
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "cucnf-contract-no":U 
                     AND PARAMFL.COMPANY-CODE EQ COMPANY  
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      ASSIGN cucnf-contract-no = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "MB-FIN":U 
                     AND PARAMFL.COMPANY-CODE EQ COMPANY  
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      ASSIGN MB-FIN = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID      EQ "VIA-WANTED":U
                     AND PARAMFL.COMPANY-CODE  EQ COMPANY
                     AND PARAMFL.PARAM-STATUS  NO-LOCK NO-ERROR.
      
      ASSIGN via-wanted = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID      EQ "price-ext-eam":U
                     AND PARAMFL.COMPANY-CODE  EQ COMPANY
                     AND PARAMFL.PARAM-STATUS  NO-LOCK NO-ERROR.
      
      ASSIGN price-ext-eam = AVAILABLE PARAMFL.
     
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "SASI":U 
                     AND PARAMFL.COMPANY-CODE EQ COMPANY  
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.  
      
      ASSIGN SASI = AVAILABLE PARAMFL.
  
      /********************************************************/
      /* P A R A M F L - D E L I V - M U L T I - W H S        */
      /* MULTIPLE WAREHOUSE                                   */
      /* SALES (A/R AND G/L) BELONG TO TMP-HEADER.WAREHOUSE-NO*/
      /* QTY WILL BE DISPATCHED FROM TMP-DETAIL.WAREHOUSE-NO  */
      /* NOTE:                                                */
      /* SINCE aap ONLY HAS REGULAR ITEMS, PROGRAMMING IS     */ 
      /* PENDING FOR NON REGULAR ITEMS.  THESE ITEMS ARE      */
      /* 1) BY SERIA                                          */ 
      /* 2) BY SIZE                                           */
      /* 3) BY WEIGHT FIXED AND VARIABLE                      */
      /* 4) BY LOT                                            */
      /* THIS NOTE WAS APPROVED BY VICTOR RODRIGUEZ           */
      /********************************************************/
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "DELIV-MULTI-WHS":U
                     AND PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      ASSIGN deliv-multi-whs = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "no-borre-quote":U  
                     AND PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
     
      ASSIGN no-borre-quote = AVAILABLE PARAMFL.
 
      ASSIGN LINE-UP-VALUE = " ":U.
      
      /********************************************************/
      /*  PARAMFL PARA PEDIR PASSWORD PARA APROBAR OVER SHIP  */
      /* VALUE1 PASSWORD PARA APROVAR OVERSHIP                */
      /* VALUE3  ???                                          */ 
      /* VALUE4 LINE UP DE ITEMS NO QUE VERIFCAN OVERSHIP     */
      /*        LABOR NO TIENE QTY POR LO TANTO NO HAY OVERSHIP*/
      /* VALUE5 "MANTE" NO LLEVAN INVENTARIO CON CDIPREMUM    */
      /*        DEJAR EN BLANCO SI LLEVAN INVENTARIO          */
      /********************************************************/ 
      
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-ID     EQ "OVER-SHIP":U
                     AND PARAMFL.PARAM-STAT   NO-LOCK NO-ERROR.
     
      IF AVAILABLE PARAMFL THEN
        ASSIGN LINE-UP-VALUE   = PARAMFL.PARAM-VALUE4.
 
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-ID     EQ "CR-REASON":U
                     AND PARAMFL.PARAM-STATUS 
                     AND PARAMFL.PARAM-VALUE1 NE "":U NO-LOCK NO-ERROR.
     
      IF AVAILABLE PARAMFL THEN 
        ASSIGN CR-REASON = YES 
               cr-field  = PARAMFL.PARAM-VALUE1.
 
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-ID     EQ "set-casas":U
                     AND PARAMFL.PARAM-STAT   NO-LOCK NO-ERROR.
      
      ASSIGN set-casas = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "oedslde-type":U
                     AND PARAMFL.COMPANY      EQ COMPANY
                     AND paramfl.param-value3 EQ "mante":U
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      ASSIGN mante-crea = AVAILABLE PARAMFL.
 
      FIND paramfl WHERE PARAMFL.PARAM-ID EQ "oeinvup-backorder":U
                     AND PARAMFL.COMPANY  EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      ASSIGN oeinvup-backorder = AVAILABLE PARAMFL.
 
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID EQ "no-backorders":U
                     AND PARAMFL.COMPANY  EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                     
      ASSIGN no-backorders = AVAILABLE PARAMFL.
 
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "DELIV-ORDER":U
                     AND PARAMFL.COMPANY      EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                     
      ASSIGN DELIV-ORDER = AVAILABLE PARAMFL.
 
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "INV-NO-PRINT":U
                     AND PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                    
      ASSIGN inv-no-print = AVAILABLE paramfl.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "TP-SHIP":U + tmp-header.CUST-NUMBER
                     AND PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    
      ASSIGN TP-SHIP = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID    EQ "OE-PICKER":U
                    AND PARAMFL.COMPANY-CODE EQ COMPANY
                    AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                   
      ASSIGN H-PICKER = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "BIN-DELETE":U
                     AND PARAMFL.COMPANY      EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                   
      ASSIGN BIN-DELETE = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID EQ "SPECIAL-COST":U
                     AND PARAMFL.COMPANY  EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                   
      IF AVAILABLE PARAMFL AND DECIMAL(PARAMFL.PARAM-VALUE2) NE 0 THEN
        ASSIGN SPECIAL-COST   = YES
               SPECIAL-COST-T = PARAMFL.PARAM-VALUE1
               SPECIAL-COST-V = DECIMAL(PARAMFL.PARAM-VALUE2).
 
      /********************************************************/
      /* whs-mod    = yes, Warehouse module on                */ 
      /********************************************************/
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "WHS-MODULE":U
                     AND PARAMFL.COMPANY      EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      ASSIGN WHS-MOD = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID    EQ "PO-DIST":U
                    AND PARAMFL.COMPANY      EQ COMPANY
                    AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
     
      ASSIGN PO-DIST = AVAILABLE PARAMFL.
 
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "RENT-INTER":U
                     AND PARAMFL.COMPANY      EQ COMPANY
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                    
      ASSIGN RENT-INTER  = AVAILABLE PARAMFL.
 
      ASSIGN oedslde-bin-upd          = NO
             whsmod-ADJ-store-BIN-LOC = "77777":U. 
            
      /********************************************************/  
      /* PARAMFL TO: UPDATE BIN FOR DIRECT SALES INVOICES     */
      /********************************************************/
        
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-ID     EQ "OEDSLDE-BIN-UPD":U
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      IF AVAILABLE PARAMFL THEN
      DO:
        ASSIGN OEDSLDE-BIN-UPD  = YES
               INVOICE-BIN-ZONE = 1
               INVOICE-BIN-LOC  = "99901":U.
        /********************************************************/ 
        /* FIRST ZONE TO SEARCH                                 */
        /********************************************************/ 
        IF PARAMFL.PARAM-VALUE1 NE " ":U THEN
          ASSIGN INVOICE-BIN-ZONE = INTEGER(PARAMFL.PARAM-VALUE1).
 
        /********************************************************/ 
        /* LOCATION TO USE WHEN A LOCATION WAS NOT FOUND        */
        /********************************************************/ 
        IF PARAMFL.PARAM-VALUE2 NE " ":U THEN
          ASSIGN INVOICE-BIN-LOC = PARAMFL.PARAM-VALUE2.
       
        /*** 12/24/2014 Toledo wam start ***/
        /********************************************************/ 
        /* LOCATION TO USE WHEN A LOCATION WAS NOT FOUND        */
        /********************************************************/ 
        IF PARAMFL.PARAM-VALUE3 BEGINS "DIRECT-SALES-BIN-":U THEN
          ASSIGN DIRECT-SALES-BIN     = YES
                 DIRECT-SALES-BIN-LOC = SUBSTRING(PARAMFL.PARAM-VALUE3,18).
                
      END. /* IF AVAILABLE cdi.PARAMFL */
 
      /********************************************************/  
      /* PARAMFL TO: ADD FREIGHT BY QUANTITY                  */
      /********************************************************/
        
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-ID     EQ "OEDSLDE-FREIGHT-BY-QTY":U
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      ASSIGN FREIGHT-BY-QTY = AVAILABLE PARAMFL.
     
      /********************************************************/  
      /* PARAMFL TO: SAVE A COST BY WAREHOUSE                 */
      /********************************************************/  
      
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-ID     EQ "OEDSLDE-COST-BY-WH":U
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
      IF AVAILABLE PARAMFL THEN
      DO:
        ASSIGN COST-BY-WH       = YES 
               which-cost-by-wh = paramfl.param-value1.
              
      END. /* IF AVAILABLE PARAMFL THEN */
      
      ELSE
      DO:
        ASSIGN COST-BY-WH       = NO 
               which-cost-by-wh = " ".
      END. /* ELSE */ 
 
    END METHOD. /* END paramSetup()..*/
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    
    METHOD PUBLIC DECIMAL calcFreightAmt():
                
      DEFINE VARIABLE csp-freight-x  AS CHARACTER NO-UNDO.
      DEFINE VARIABLE csp-freight-l  AS CHARACTER NO-UNDO.
      DEFINE VARIABLE desp-freight-p AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE desp-freight-m AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE deFreightAmt   AS DECIMAL   NO-UNDO.
      DEFINE VARIABLE lsp-freight    AS LOGICAL   NO-UNDO.
      
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                     AND PARAMFL.PARAM-ID     EQ "SP-FREIGHT":U
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
   
      IF AVAILABLE PARAMFL THEN
        ASSIGN lsp-freight    = YES
               csp-freight-l  = PARAMFL.PARAM-VALUE1
               desp-freight-p = DECIMAL(PARAMFL.PARAM-VALUE2)
               desp-freight-m = DECIMAL(PARAMFL.PARAM-VALUE3)
               csp-freight-x  = PARAMFL.PARAM-VALUE5.
                 
      IF lsp-freight THEN
      DO:
        FIND CINV1 WHERE CINV1.ITEM-NUMBER EQ tmp-detail.ITEM-NUMBER NO-LOCK NO-ERROR.
        IF NOT ((AVAILABLE CINV1 AND CINV1.LINE-UP EQ "L") OR 
               LOOKUP(TMP-HEADER.PHYSICAL-ZIP, csp-freight-x) GT 0) THEN
/*               LOOKUP(STRING(TMP-HEADER.PHYSICAL-ZIP,"99999"), csp-freight-x) GT 0) THEN*/
        DO:
          IF LOOKUP(TMP-detail.DELIV-STATUS, csp-freight-l) GT 0 THEN 
            ASSIGN TMP-HEADER.FREIGHT-AMT = TMP-HEADER.FREIGHT-AMT + (TMP-DETAIL.EXTENSION * desp-freight-p).
         
          IF TMP-HEADER.FREIGHT-AMT LT 0 THEN 
            ASSIGN TMP-HEADER.FREIGHT-AMT = 0.
           
        END. /* IF NOT ((AVAILABLE CINV1 AND CINV1.LINE-UP EQ "L") OR */
              
        IF TMP-HEADER.FREIGHT-AMT GT desp-freight-m THEN 
          ASSIGN TMP-HEADER.FREIGHT-AMT = desp-freight-m.
              
      END. /* IF lsp-freight THEN */
                
    END METHOD. /* R.S */ 
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID getTotal():
 
        DEFINE VARIABLE objOrderTaxes AS CLASS OrderTaxes NO-UNDO. /* R.S */
        DEF VARIABLE  io-CITY-TAX-EXEMPT      AS LOGICAL      NO-UNDO.
        DEF VARIABLE  io-state-TAX-EXEMPT     AS LOGICAL      NO-UNDO.
        DEF VARIABLE  fecha-exempt-vencio     AS LOGICAL      NO-UNDO. 
        DEF VARIABLE  IVU-HOLD-CODE           AS CHAR         NO-UNDO.
        DEF VARIABLE  TAX-RET-VAL             AS CHAR         NO-UNDO.    
      ASSIGN objOrderTaxes = NEW OrderTaxes(INPUT cToken).
                 
      FOR EACH tmp-detail WHERE tmp-detail.TMP-NUMBER  EQ tmp-header.TMP-NUMBER
                            AND tmp-detail.item-number NE "":U :
      
        ASSIGN TMP-DETAIL.DELIV-STATUS = "D":U. /* JKT */
        
        /* calculate Freight amount */ 
        THIS-OBJECT:calcFreightAmt().  
            
        ACCUMULATE
        TMP-DETAIL.EXTENSION(TOTAL)
        //TMP-DETAIL.QUANTITY * tmp-detail.ACCTING-COST(TOTAL) /* R.S Not required right now */
        TMP-DETAIL.QUANTITY(TOTAL).
 
        IF tmp-detail.ITEM-NUMBER NE "NOINVENTORY":U AND TMP-DETAIL.ITEM-NUMBER NE "":U THEN
        DO:
          FIND CINV1 WHERE CINV1.ITEM-NUMBER EQ tmp-detail.ITEM-NUMBER NO-LOCK NO-ERROR.
 
          IF AVAILABLE CINV1 AND CINV1.ALT-ITEM-NO NE "":U AND CINV1.WEIGHT NE 0 AND CINV1.CONV-FACT NE 0 THEN
            ACCUMULATE TMP-DETAIL.QUANTITY * CINV1.CONV-FACT(TOTAL).
 
        END.
        
      END. /* FOR EACH tmp-detail */
      
 
      ASSIGN
        tmp-header.GROSS-AMOUNT = ROUND((ACCUMULATE  TOTAL tmp-detail.EXTENSION),2)
        tmp-header.SALES-TX-AMT = (ACCUM TOTAL TMP-DETAIL.QUANTITY)
        t-city-tax-amt          = 0    
        t-state-tax-amt         = 0.    
        
      /* R.S -- Calculates discount amount */
      THIS-OBJECT:calculateDiscount().  
        
      FIND PARAMFL WHERE PARAMFL.PARAM-ID EQ "tax-on-order":U
                     AND PARAMFL.COMPANY  EQ  COMPANY
                     AND PARAMFL.PARAM-STATUS  NO-LOCK NO-ERROR.
      IF AVAILABLE PARAMFL THEN
        ASSIGN tax-on-order = AVAILABLE PARAMFL.
 
      IF  (trans-type EQ "1":U 
      OR   trans-type EQ "6":U) 
      OR  (tax-on-order 
      AND (trans-type EQ "2":U 
      OR   trans-type EQ "3":U 
      OR   trans-type EQ "4":U 
      OR   trans-type EQ "5":U))THEN
      
      DO:
        ASSIGN
          t-city-tax-amt  = 0     
          t-state-tax-amt = 0.    
 
          objOrderTaxes:OrderTaxesMainBlock(INPUT tmp-header.tmp-number, /* Temp-Number */
                                            INPUT COMPANY,
                                            INPUT TMP-HEADER.WAREHOUSE-NO,
                                            INPUT TABLE TMP-HEADER,
                                            INPUT TABLE TMP-DETAIL,
                                            INPUT-OUTPUT TABLE TMP-DETAIL-TAX, 
                                            OUTPUT t-city-tax-amt,                                          
                                            OUTPUT t-state-tax-amt ). 
             
      END.
 
      RUN oetaxverf.p(INPUT COMPANY,
                         INPUT TMP-HEADER.CUST-NUMBER,
                         INPUT TMP-HEADER.SHIP-TO-NO,
                         INPUT ?,
                         INPUT "2",
                         INPUT "NO",
                         INPUT-OUTPUT   io-CITY-TAX-EXEMPT,
                         INPUT-OUTPUT   io-state-TAX-EXEMPT,
                         INPUT-OUTPUT   fecha-exempt-vencio,
                         INPUT-OUTPUT   IVU-HOLD-CODE,
                         INPUT-OUTPUT   TAX-RET-VAL).
                        
      ASSIGN tmp-header.CITY-TAX-AMT  = IF io-CITY-TAX-EXEMPT THEN 0 ELSE t-city-tax-amt     
             tmp-header.STATE-TAX-AMT = IF io-state-TAX-EXEMPT THEN 0 ELSE t-state-tax-amt.   
      
      
      /* update a los tax % y amount de tmp-detail */
      
      THIS-OBJECT:updTmpDetailTaxes().
      
      FINALLY: 
        IF VALID-OBJECT(objOrderTaxes) THEN  
          DELETE OBJECT objOrderTaxes.  
      END FINALLY.
           
    END METHOD.
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID updTmpDetailTaxes():
    
 
      /* u p d - t m p - d e t a i l - t a x e s              */
 
      /* read all item record and find tax record             */
 
      FOR EACH tmp-detail WHERE tmp-detail.TMP-NUMBER  EQ tmp-header.TMP-NUMBER
                            AND tmp-detail.item-number NE "":U EXCLUSIVE-LOCK:
 
        /********************************************************/
        /* verify if tax record exist before creating it        */
        /********************************************************/
        FIND tmp-detail-tax WHERE tmp-detail-tax.TMP-NUMBER   EQ tmp-detail.TMP-NUMBER
                              AND tmp-detail-tax.TMP-SEQ      EQ tmp-detail.TMP-SEQ
                              AND tmp-detail-tax.ITEM-NUMBER  EQ tmp-detail.ITEM-NUMBER NO-LOCK NO-ERROR.
        
        IF AVAIL tmp-detail-tax THEN
        DO:
          ASSIGN
            TMP-DETAIL.dt-city-tax-pct  = tmp-detail-tax.dt-city-tax-pct
            TMP-DETAIL.dt-STATE-tax-pct = tmp-detail-tax.dt-state-tax-pct
 
            TMP-DETAIL.dt-city-tax-amt  = tmp-detail-tax.dt-city-tax-amt
            TMP-DETAIL.dt-state-tax-amt = tmp-detail-tax.dt-state-tax-amt.
 
        END. /* IF NOT AVAIL tmp-detail-tax */
 
      END. /* FOR EACH tmp-detail */
 
    END METHOD.
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID getNextNumber():

      /* G E T - N E X T - N U M B E R                        */

      ASSIGN popup-type = " ":U.
    
      /********************************************************/
      /*  2. Order  Entry                                     */
      /*  5. Qoute Conversion                                 */
      /*  9. New Transfer                                     */
      /* 12. Lay Away Berrios                                 */
      /********************************************************/

      IF  TRANS-TYPE EQ "2":U 
      OR  TRANS-TYPE EQ "12":U 
      OR  TRANS-TYPE EQ "9":U   
      OR  TRANS-TYPE EQ "5":U  THEN 
      DO:  
        /* "3" = find next order number & Generate new order Number */
        ASSIGN NEW-NUMBER = THIS-OBJECT:generateOrderNumber(INPUT "3":U, 
                                                            INPUT TMP-HEADER.CUST-NUMBER).
                                                              
      END. /*  IF  TRANS-TYPE = "2" ... */
 
      /********************************************************/
      /*  2. Order  Entry                                     */
      /*  9. New Transfer                                     */
      /* 12. Lay Away Berrios                                 */
      /********************************************************/
      IF  TRANS-TYPE EQ "2":U 
      OR  TRANS-TYPE EQ "12":U 
      OR  TRANS-TYPE EQ "9":U THEN 
        
        FOR EACH wkfile WHERE wkfile.PROG-NAME   EQ "OEDSLDE-ORDER":U
                          AND wkfile.terminal-id EQ USERID("CDI") + invoice-num EXCLUSIVE-LOCK:
            ASSIGN wkfile.TERMINAL-id = NEW-NUMBER.
        END.
 
      
      /********************************************************/
      /* renumber popup message for new orders                */
      /********************************************************/
      
      THIS-OBJECT:renumberPopup().
    
      INVOICE-NUM = NEW-NUMBER.
            
    END METHOD. /* END getNextNumber() */
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID renumberPopup():
      
      /* r e n u m b e r - p o p u p                          */
      /* renumber popup messages for new order                */
      
      IF  tmp-header.tmp-number = "tmp-number":U THEN
      DO:
        ASSIGN popup-type = "ORDER-NUMBER-":U.

        FOR EACH MRINST WHERE MRINST.RX-PROC EQ popup-type 
                                              + USERID("CDI") 
                                              + invoice-num EXCLUSIVE-LOCK:
          ASSIGN
            MRINST.RX-PROC  = popup-type
                            + new-number.
        END. /* FOR EACH MRINST.. */
        
      END. /* IF  tmp-header.tmp-number = "tmp-number" */
     
    END METHOD. /* END renumberPopup() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID orderFromDetail():

      /* O R D E R - F R O M - D E T A I L                    */
 
      ASSIGN INVOICE-COST = 0
             INVOICE-TOTAL = 0.
 

      FOR EACH wkfile WHERE wkfile.prog-name   EQ     "DATA-OEUOMCV":U 
                        AND WKFILE.TERMINAL-ID BEGINS COOHD.ORDER-NUMBER EXCLUSIVE-LOCK:
        DELETE WKFILE.
      END. /* FOR EACH cdi.wkfile..*/
 
      FOR EACH tmp-detail WHERE tmp-DETAIL.TMP-NUMBER  EQ TMP-HEADER.TMP-NUMBER 
                            AND tmp-detail.item-number NE "":U 
                            AND tmp-detail.quantity    NE 0 EXCLUSIVE-LOCK:
         
        /* aceros conv */
        IF NOT cucnf-contract-no AND TMP-DETAIL.log-fact THEN
        DO:
          ASSIGN temp-char = "MSGOE":U.
          THIS-OBJECT:cucnfMessg().
        END.
 
        THIS-OBJECT:createCOODT().

        /********************************************************/
        /* CREATE RELATED FILE: COOSZ                           */
        /********************************************************/

        THIS-OBJECT:createOrderChild().
 
        IF NOT tmp-detail.ITEM-NUMBER EQ "NOINVENTORY":U THEN
        DO:
          FIND CINV1 WHERE CINV1.ITEM-NUMBER EQ tmp-detail.ITEM-NUMBER EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
          
          IF NOT LOCKED CINV1 AND NOT AVAILABLE CINV1 THEN
            NEXT.
                      
          /*before adding NO-WAIT adding */
          /*IF NOT AVAILABLE CINV1 THEN
            NEXT.*/

          IF (CINV1.BY-WEIGHT EQ "N":U OR CINV1.BY-WEIGHT EQ "C":U) AND 
              NOT CINV1.SERIALIZE AND
              AVAILABLE COOHD THEN
          DO:   
            FIND CUCNF WHERE CUCNF.ITEM-UOM EQ CINV1.ITEM-UOM NO-LOCK NO-ERROR.
            IF AVAILABLE CUCNF THEN
            DO:
              CREATE wkfile.
              ASSIGN 
                WKFILE.PROG-NAME   = "DATA-OEUOMCV":U 
                WKFILE.TERMINAL-ID = COOHD.ORDER-NUMBER 
                WKFILE.DATE1       = COOHD.ORDER-DATE 
                WKFILE.DATE2       = TODAY
                WKFILE.DECIMAL1    = tmp-detail.mult-fact[1]
                WKFILE.DECIMAL2    = tmp-detail.mult-fact[2]
                WKFILE.DECIMAL3    = tmp-detail.mult-fact[3]
                WKFILE.DECIMAL4    = tmp-detail.mult-fact[4]
                WKFILE.DECIMAL5    = tmp-detail.mult-fact[5]
                WKFILE.DECIMAL6    = tmp-detail.div-fact[1]
                WKFILE.DECIMAL7    = tmp-detail.div-fact[2]
                WKFILE.DECIMAL8    = tmp-detail.div-fact[3]
                WKFILE.DECIMAL9    = tmp-detail.div-fact[4]
                WKFILE.DECIMAL10   = tmp-detail.div-fact[5]
                WKFILE.CHAR1       = tmp-detail.MULT-DESC[1]
                WKFILE.CHAR2       = tmp-detail.MULT-DESC[2]
                WKFILE.CHAR3       = tmp-detail.MULT-DESC[3]
                WKFILE.CHAR4       = tmp-detail.MULT-DESC[4]
                WKFILE.CHAR5       = tmp-detail.MULT-DESC[5]
                WKFILE.CHAR6       = tmp-detail.div-DESC[1]
                WKFILE.CHAR7       = tmp-detail.div-DESC[2]
                WKFILE.CHAR8       = tmp-detail.div-DESC[3]
                WKFILE.CHAR9       = tmp-detail.div-DESC[4]
                WKFILE.CHAR10      = tmp-detail.div-DESC[5]
                WKFILE.INTEGER2    = tmp-detail.user-fact * 1000
                WKFILE.INTEGER1    = TMP-DETAIL.TMP-SEQ .

            END. /* IF AVAILABLE CUCNF THEN */
            
          END. /* AVAILABLE COOHD THEN */

          IF tmp-detail.item-uom NE "":U                                   AND 
             substr(tmp-detail.item-uom,1,2) NE substr(cinv1.item-uom,1,2) AND 
             cinv1.uom-qty NE 0                                            THEN
             
            ASSIGN inv-qty = tmp-detail.quantity / cinv1.uom-qty.
          ELSE
            ASSIGN inv-qty = tmp-detail.quantity.
 
          IF tmp-detail.tmp-seq GT 3000 AND decimal(tmp-detail.sales-comm-%) NE 0 THEN
          DO:
            inv-qty = inv-qty * decimal(tmp-detail.sales-comm-%).
          END.
 
          IF SUBSTRING(coodt.order-number,2,1) NE "Q":U THEN 
            THIS-OBJECT:commitItem(INPUT COODT.ORDER-NUMBER,
                                   INPUT COODT.ORDER-SEQ).

 
          IF cinv1.seasonal-code EQ "REVISTA":U AND TRANS-TYPE EQ "2":U THEN
            THIS-OBJECT:creaMante().
                
        END. /* IF NOT tmp-detail.ITEM-NUMBER = "NOINVENTORY" */
 // MESSAGE "COODT.ORDER-QTY" COODT.ORDER-QTY "COODT.ORDERED-PRC" COODT.ORDERED-PRC.
 
        ASSIGN CCSMS.ON-ORDER-AMT = CCSMS.ON-ORDER-AMT  + (COODT.ORDER-QTY * COODT.ORDERED-PRC).
      //  MESSAGE "CCSMS.ON-ORDER-AMT=" CCSMS.ON-ORDER-AMT.
      END. /* FOR EACH tmp-detail */
 
      ASSIGN COOHD.ORDER-AMOUNT = COOHD.ORDER-AMOUNT 
                                - tmp-header.DISCOUNT-AMT 
                                + tmp-header.FREIGHT-AMT 
                                + tmp-header.MISC-CHG-AMT . 
 
      ASSIGN CCSMS.ON-ORDER-AMT = CCSMS.ON-ORDER-AMT  
                                - tmp-header.DISCOUNT-AMT 
                                + tmp-header.FREIGHT-AMT 
                                + tmp-header.MISC-CHG-AMT 
                                + STATE-TAX-AMT 
                                + CITY-TAX-AMT.
     
    END METHOD. /* END orderFromDetail() */
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/

    METHOD PUBLIC VOID cucnfMessg():

      /* P R O C - C U C N F - M E S S G                      */
      
      IF NO-CUCNF-MESSG THEN
        RETURN.
 
      FIND MESSG WHERE MESSG.DOC-NUMBER  EQ USER("CDI":U)  
                   AND MESSG.FILE-NAME   EQ TEMP-CHAR
                   AND MESSG.DOC-SEQ     EQ TMP-DETAIL.TMP-SEQ
                   AND MESSG.MESSAGE-SEQ EQ 0 EXCLUSIVE-LOCK NO-WAIT NO-ERROR. /* OJO SEQUENCIA CERO*/        
      IF NOT AVAILABLE MESSG THEN 
      DO:
        CREATE MESSG.
        ASSIGN
          MESSG.DOC-NUMBER  = USER("CDI":U)  
          MESSG.FILE-NAME   = TEMP-CHAR
          MESSG.DOC-SEQ     = TMP-DETAIL.TMP-SEQ
          MESSG.MESSAGE-SEQ = 0.
      END.
 
      ASSIGN TEMP-LOG  = NO
             TEMP-CHAR = STRING(TMP-DETAIL.USER-FACT) + " EA ":U.
      
      DO temp-int = 1 TO 5:
          
        IF ABS(TMP-DETAIL.MULT-FACT[temp-int]) GT 1 THEN 
        DO:
          IF temp-LOG THEN 
            ASSIGN TEMP-LOG  = YES
                   temp-char = temp-char + " X ":U /* AnADIR SIMBOLO DE MULTIPLICACION SI NO ES EL 1er VALOR*/
                   temp-char = temp-char + " ":U + STRING(TMP-DETAIL.MULT-FACT[temp-int]) + " ":U + TMP-DETAIL.MULT-DESC[temp-int].
                    
        END. /* IF ABS(TMP-DETAIL.MULT-FACT[temp-int]) GT 1 THEN */
      
      END. /* DO temp-int = 1 TO 5 */
      
      DO temp-int = 1 TO 5:
        
        IF ABS(TMP-DETAIL.DIV-FACT[temp-int]) GT 1 THEN 
        DO:
          IF temp-LOG THEN 
            ASSIGN TEMP-LOG = YES
                   temp-char = temp-char + " / ":U /* AnADIR SIMBOLO DE DIVICION SI NO ES EL 1er VALOR*/
                   temp-char = temp-char  + " ":U + STRING(TMP-DETAIL.DIV-FACT[temp-int]) + " ":U + TMP-DETAIL.DIV-DESC[temp-int].
                    
        END. /* IF ABS(TMP-DETAIL.DIV-FACT[temp-int]) GT 1 THEN */
        
      END. /* DO temp-int = 1 TO 5 */
      
      ASSIGN MESSG.MESSAGE-DESC = TEMP-CHAR .
 
    END METHOD.
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID createCOODT():

      /* C R E A T E - C O O D T                              */
      DEFINE VARIABLE lcSet-id AS CHARACTER NO-UNDO.
      DEFINE VARIABLE lcParent-id AS CHARACTER NO-UNDO.
      ASSIGN tmp-line-up = "s":U.
      
      FIND CINV1 WHERE CINV1.ITEM-NUMBER EQ tmp-detail.ITEM-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE CINV1 THEN
        ASSIGN tmp-line-up             = CINV1.LINE-UP
               TMP-DETAIL.ITEM-UOM     = CINV1.ITEM-UOM
               TMP-DETAIL.ACCTING-COST = CINV1.ACCTING-COST
               TMP-DETAIL.ORDERED-CST  = CINV1.ACCTING-COST
               tmp-detail.CLASS-CODE   = CINV1.CLASS-CODE
               TMP-DETAIL.WAREHOUSE-NO = TMP-HEADER.WAREHOUSE-NO
               TMP-DETAIL.SALES-COMM-% = STRING(CINV1.COMMISION-%)
               TMP-DETAIL.BASE-PRICE   = CINV1.BASE-PRICE. /* R.S */
                   
      /********************************************************/
      /*  4. Order/Quote Change                               */
      /********************************************************/
      IF TRANS-TYPE NE "4":U   AND
         TRANS-TYPE NE "10":U  AND
         TRANS-TYPE NE "13":U  THEN 
        CREATE COODT.       
      ELSE 
      DO:
        FIND COODT WHERE COODT.ORDER-NUMBER EQ TMP-HEADER.TMP-NUMBER  
                     AND COODT.ORDER-SEQ    EQ TMP-DETAIL.TMP-SEQ EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        
        IF NOT AVAILABLE COODT THEN 
          CREATE COODT.
      END.
      lcSet-id = "".
      lcParent-id = "".
      FIND FIRST SETHD WHERE SETHD.SET-NO EQ TMP-DETAIL.ITEM-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE sethd THEN 
      lcSet-id = "H".
      FIND FIRST setdt WHERE SETDT.ITEM-NUMBER EQ TMP-DETAIL.ITEM-NUMBER  NO-LOCK NO-ERROR. 
      IF AVAILABLE SETDT THEN 
      DO:
          FOR EACH bufSetdt WHERE bufSetdt.ITEM-NUMBER EQ TMP-DETAIL.ITEM-NUMBER NO-LOCK:
              FIND FIRST bufTmp-Detail WHERE bufTMP-DETAIL.ITEM-NUMBER EQ bufsetdt.SET-NO NO-LOCK NO-ERROR.
              IF AVAILABLE bufTmp-Detail THEN 
              DO:
                 ASSIGN lcSet-id    = "D"
                        lcParent-id = bufsetdt.set-no.
                 LEAVE. 
              END.    
          END.    
          
          
      END.
      
      IF lcParent-id NE "" THEN 
      DO:
          FIND FIRST ttset WHERE ttset.item_no = TMP-DETAIL.ITEM-NUMBER 
                             AND ttset.PARENT_item = lcParent-id  NO-LOCK NO-ERROR.
          
          IF NOT AVAILABLE ttset THEN  
            lcSet-id = "H".
      end  . 
      
       IF tmp-detail.dt-char3 EQ "" THEN 
         lcSet-id = "H".
       ELSE 
        lcSet-id = "D". 
           
       IF tmp-detail.dt-char3 EQ "NOT A KIT ITEM" THEN
         lcSet-id = "". 
         
      FIND FIRST SIZE-SELECTED WHERE SIZE-SELECTED.INVOICE-NUMBER EQ tmp-detail.TMP-NUMBER 
                                 AND SIZE-SELECTED.INVOICE-SEQ    EQ tmp-DETAIL.TMP-SEQ   
                                 AND SIZE-SELECTED.ITEM-NUMBER    EQ TMP-DETAIL.ITEM-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE SIZE-SELECTED AND SIZE-SELECTED.SIZE NE "" THEN 
             lcSet-id = "". 
             
      // Gama se lo anadio. El Find.
      
      //FIND COOHD WHERE COOHD.ORDER-NUMBER = TMP-HEADER.TMP-NUMBER  NO-LOCK NO-ERROR.                                
       
      ASSIGN 
        COODT.BASE-PRICE   = TMP-DETAIL.BASE-PRICE
        //COODT.BOXES      = TMP-DETAIL.BOXES
        //COODT.CASE-QTY   = TMP-DETAIL.CASE-QTY
        //COODT.CONTRACT-NO = TMP-DETAIL.CONTRACT-NO   /* R.S */
        COODT.ORDERED-CST  = TMP-DETAIL.ORDERED-CST
        COODT.DESCRIPTION  = IF lcSet-id = "D" THEN "(KIT Component)-" + TMP-DETAIL.DESCRIPTION ELSE TMP-DETAIL.DESCRIPTION
        COODT.ORDER-NUMBER = INVOICE-NUM 
        COODT.ORDER-SEQ    = TMP-DETAIL.TMP-SEQ
        COODT.ITEM-NUMBER  = TMP-DETAIL.ITEM-NUMBER
        //COODT.SALE-TX-CODE = TMP-DETAIL.SALE-TX-CODE
        COODT.ORDERED-PRC  = TMP-DETAIL.PRICE
        COODT.SET-ID       = lcSet-id //TMP-DETAIL.SET-ID         /* R.S */
        //COODT.SET-LINE   = TMP-DETAIL.SET-LINE       /* R.S */
        //COODT.UNIT-QTY   = TMP-DETAIL.UNIT-QTY
        COODT.FASE-1       = TODAY                //? WHEN COODT.FASE-1 = 01/01/01 COOHD.ORDER-DATETMP-HEADER.ORDER-DATE
        COODT.WAREHOUSE-NO = TMP-DETAIL.WAREHOUSE-NO
        COODT.ITEM-UOM     = TMP-DETAIL.ITEM-UOM
        COODT.SALES-COMM-% = DECIMAL(TMP-DETAIL.SALES-COMM-%)
        COODT.ORDER-QTY    = TMP-DETAIL.QUANTITY    
        COODT.ORIGINAL-QTY = TMP-DETAIL.QUANTITY 
        //COODT.CONDUCE-QTY  = tmp-detail.conduce-qty  /* R.S */
        COODT.CLASS-CODE   = tmp-detail.class-code  
        //COODT.org-SEQ      = TMP-DETAIL.ORG-ITEM-SEQ /* R.S */ 
        COODT.org-item     = IF lcSet-id = "D" THEN TMP-DETAIL.dt-char3 ELSE "" //IF AVAILABLE ttset THEN ttset.PARENT_item ELSE ""  /* R.S */ 
        /*** 09/04/2014 wam Toledo start ***/
        COODT.dt-char1     = tmp-detail.dt-char1                       
        COODT.dt-char2     = tmp-detail.dt-char2             
        //COODT.dt-char3     = tmp-detail.dt-char3             
        COODT.call-no      = tmp-detail.call-no               
        COODT.po-number    = TMP-DETAIL.po-number             
        COODT.ref-no       = tmp-detail.ref-no .
        //RELEASE COOHD NO-ERROR.
      
      /********************************************************/
      /* calculate item tax                                   */
      /********************************************************/

      ASSIGN
        COODT.item-city-tax-pcnt   = TMP-DETAIL.dt-city-tax-pct
        COODT.item-state-tax-pcnt  = TMP-DETAIL.dt-STATE-tax-pct
        COODT.item-city-tax-amt    = TMP-DETAIL.dt-city-tax-amt
        COODT.item-state-tax-amt   = TMP-DETAIL.dt-state-tax-amt.
        
      IF AVAILABLE ttset THEN DELETE ttset.
      
      /* fill in damage code */
      IF  tmp-detail.damage THEN
        ASSIGN coodt.damage = "Y":U.
      ELSE 
        ASSIGN coodt.damage  = "N":U.
 
 
      IF via-wanted THEN   
      DO:
         COODT.CONTRACT-NO = STRING(coodt.warehouse-no,"99")  
                           + TMP-DETAIL.deliv-status.
 
      END.

      /* REGULAR ITEMS                                        */
      
      IF NOT tmp-detail.ITEM-NUMBER EQ "NOINVENTORY":U THEN
      DO:
        IF AVAILABLE CINV1 THEN
          ASSIGN
            COODT.CLASS-CODE = CINV1.CLASS-CODE. 
      END.
      ELSE

      /* NON INVENTORY ITEMS                                  */
      /* SAVE CLASS CODE AND COST ENTERED BY USER             */

      DO:
        IF tmp-detail.class-code EQ " ":U THEN
          ASSIGN
            COODT.CLASS-CODE = "NOINVEN":U.
 
        ASSIGN
          COODT.ORDERED-CST  = TMP-DETAIL.ACCTING-COST. 
 
      END. /* else IF NOT tmp-detail.ITEM-NUMBER = "NOINVENTORY" */
 

      IF set-casas AND COODT.ORDER-SEQ GE 3000 THEN
      DO:
          
        ASSIGN
          COODT.CONTRACT-NO = STRING(tmp-detail.SA-PRICE) + ",":U +
                              STRING(tmp-detail.SA-orig-price) + ",":U +
                              STRING(tmp-detail.SA-orig-qty) + ",":U +
                              STRING(tmp-detail.SA-ADDED-ITEM) + ",":U +
                              STRING(tmp-detail.SA-SUB-LINE).
                              
      END. /* IF set-casas AND COODT.ORDER-SEQ GE 3000 THEN */
 
      IF COODT.ORDER-SEQ LT 3000 THEN
      DO:
        FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "JBTRK-":U
                                                  + STRING(coohd.warehouse-no,"99":U) 
                                                  + "-":U + cinv1.class-code
                             AND PARAMFL.COMPANY-CODE = COMPANY
                             AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
        IF AVAILABLE PARAMFL THEN
        DO:
            THIS-OBJECT:createJobTrk().
        END.
      END. /* IF COODT.ORDER-SEQ LT 3000 THEN */

      IF PO-DIST  THEN
        ASSIGN COODT.PRICE-CATGRY = TMP-DETAIL.DELIV-STATUS.
 
      IF COODT.ORDER-SEQ GT 3000 THEN
      DO:
        ASSIGN COODT.ORDER-QTY = TMP-DETAIL.QUANTIty * COODT.SALES-COMM-%.
        
        IF COODT.ORIGINAL-QTY EQ 0 THEN 
          COODT.ORIGINAL-QTY = COODT.ORDER-QTY.
          
      END. /* IF coodt.order-seq GT 3000 THEN */
 

      IF tmp-detail.weight NE 0 THEN
      DO:
          
        ASSIGN 
          COODT.BOXES        = TMP-DETAIL.QUANTITY.
          COODT.ORDER-QTY    = tmp-detail.weight.
          COODT.ORIGINAL-QTY = TMP-DETAIL.weight.
      END. /* IF tmp-detail.weight NE 0 THEN */
 

      /* ITEMS DE LABOR (LINE-UP=L) Y SERVICE CALL            */

      IF tmp-LINE-UP  EQ LINE-UP-VALUE  AND
         INTEGER(COOHD.call-no) NE 0 /*COOHD.picking-ind   BEGINS "CALL-NO-"*/ THEN 
      DO:
        
        /* FIND LABOR RECORD */
        
        FIND VSLBOR WHERE VSLBOR.JOB-NO   EQ COODT.ORDER-NUMBER 
                      AND VSLBOR.SEQ      EQ COODT.ORDER-SEQ
                      AND VSLBOR.CALL-NO  EQ INTEGER(COOHD.call-no) EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
 
        IF NOT AVAILABLE VSLBOR THEN
        DO:
          CREATE VSLBOR.
          ASSIGN
            VSLBOR.JOB-NO       = COODT.ORDER-NUMBER 
            VSLBOR.SEQ          = COODT.ORDER-SEQ
            VSLBOR.CALL-NO      = INTEGER(COOHD.call-no).   
 
        END. /* IF NOT AVAILABLE VSLBOR */  
 
        ASSIGN
          VSLBOR.ITEM-NUMBER  = coodt.ITEM-NUMBER
          VSLBOR.DESCRIPTION  = coodt.DESCRIPTION
          VSLBOR.TECH-ID      = tmp-detail.tech-id     
          VSLBOR.DT-ASSIGNED  = TODAY /* R.S */
          VSLBOR.HOURS        = TMP-DETAIL.QUANTITY
          VSLBOR.WAREHOUSE-NO = coodt.WAREHOUSE-NO.
 
      END. /* IF CINV1.LINE-UP = LINE-UP-VALUE AND es-job = YES  */
 
      /* MESSAGE "COOHD.ORDER-AMOUNT Create COODT" "tmp-header.DISCOUNT-AMT" tmp-header.DISCOUNT-AMT. */
       
     IF AVAILABLE cinv1 AND CINV1.INV-TYPE = "EAM":U AND price-ext-eam THEN  
      DO:
         ASSIGN COOHD.ORDER-AMOUNT = COOHD.ORDER-AMOUNT + (COODT.ORDERED-PRC * (COODT.ORDER-QTY * cinv1.uom-qty)).
      END.  
      ELSE
      DO:
         ASSIGN COOHD.ORDER-AMOUNT = COOHD.ORDER-AMOUNT + (COODT.ORDERED-PRC * COODT.ORDER-QTY ).
      END. 
/*      ASSIGN COOHD.ORDER-AMOUNT = COOHD.ORDER-AMOUNT + TMP-DETAIL.EXTENSION.*/
      /* MESSAGE "COOHD.ORDER-AMOUNT=" COOHD.ORDER-AMOUNT. */
      /*mueblerias , siempre usara la tienda de origen */
      
      IF deliv-order THEN coodt.warehouse = TMP-HEADER.WAREHOUSE-NO. /* R.S */
   
    END METHOD. /* END createCOODT() */
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID createJobTrk():
      
      /*****----------------------------------------------*****/
      /* c r e a t e - j o b - t r k                          */
      /*****----------------------------------------------*****/
      DEFINE VARIABLE f_valor     AS CHARACTER  NO-UNDO.
      DEFINE VARIABLE h_field     AS HANDLE     NO-UNDO.
      DEFINE VARIABLE h_file      AS HANDLE     NO-UNDO.
      DEFINE VARIABLE bracket-pos AS INTEGER    NO-UNDO.
 
      ASSIGN h_file = BUFFER cinv1:HANDLE.
      
      THIS-OBJECT:createHandle(INPUT "CINV1":U,
                               INPUT h_file).
      
      ASSIGN h_file = BUFFER coohd:HANDLE.
      
      THIS-OBJECT:createHandle(INPUT "COOHD":U,
                               INPUT h_file).
                            
      ASSIGN h_file = BUFFER coodt:HANDLE.
      
      THIS-OBJECT:createHandle(INPUT "COODT":U,
                               INPUT h_file).

      ASSIGN h_file = BUFFER messg:HANDLE.
      
      THIS-OBJECT:createHandle(INPUT "MESSG":U,
                               INPUT h_file).

      ASSIGN h_file = BUFFER tmp-detail:HANDLE.
      
      THIS-OBJECT:createHandle(INPUT "TMP-DETAIL":U,
                               INPUT h_file).

      ASSIGN h_file = BUFFER tmp-header:HANDLE.
      
      THIS-OBJECT:createHandle(INPUT "TMP-HEADER":U,
                               INPUT h_file).
 
      THIS-OBJECT:crearRecordPrincipal().
 
      FOR EACH FLATR WHERE FLATR.FILE-ID          EQ "oejbtrk":U
                       AND FLATR.BROWSER-SP-TABLE NE "":U
                       AND FLATR.BROWSER-SP-DISPL NE "":U
                       AND FLATR.SYS-GEN NO-LOCK:
 
        FIND handles_file WHERE handles_file.FILE_name EQ FLATR.BROWSER-SP-TABLE NO-LOCK NO-ERROR.
 
        IF AVAILABLE handles_file THEN
        DO:
          IF FLATR.FIELD-ID EQ "FILL-IN-MESG":U THEN
          DO:
            FIND FIRST MESSG WHERE MESSG.FILE-NAME  EQ "MSGOE":U
                               AND MESSG.DOC-NUMBER EQ INVOICE-NUM
                               AND MESSG.DOC-SEQ    EQ MESSG.DOC-SEQ NO-LOCK NO-ERROR.
 
            IF AVAILABLE MESSG THEN
              ASSIGN f_valor = messg.message-DESC .
              
          END.
 
          ASSIGN h_file      = handles_file.FILE_handle
                 bracket-pos = INDEX(FLATR.BROWSER-SP-DISPL,"~[":U).
 
          IF bracket-pos EQ 0 THEN
          DO:                   
            ASSIGN h_field  = h_file:BUFFER-FIELD(FLATR.BROWSER-SP-DISPLAY)
                   f_valor  = h_field:BUFFER-VALUE.
 
            IF FLATR.BROWSER-SP-DISPLAY = "seasonal-code":U THEN
            DO:
              FIND FIRST buf-WKFILE WHERE buf-WKFILE.PROG-NAME   EQ "TIPO":U
                                      AND buf-WKFILE.TERMINAL-ID EQ TRIM(f_valor) NO-LOCK NO-ERROR.
                         
              IF AVAILABLE buf-WKFILE THEN
                ASSIGN f_valor = buf-WKFILE.CHAR1.
            END. /* IF FLATR.BROWSER-SP-DISPLAY = "seasonal-code":U THEN  */
 
            IF FLATR.BROWSER-SP-DISPLAY = "COST-MTHOD-I":U THEN
            DO:
              FIND FIRST buf-WKFILE WHERE buf-WKFILE.PROG-NAME   EQ "IMP":U
                                      AND buf-WKFILE.TERMINAL-ID EQ TRIM(f_valor) NO-LOCK NO-ERROR.
                         
              IF AVAILABLE buf-WKFILE THEN
                ASSIGN f_valor = buf-WKFILE.CHAR1.
                    
            END. /* IF FLATR.BROWSER-SP-DISPLAY = "COST-MTHOD-I":U THEN */
 
            IF FLATR.BROWSER-SP-DISPLAY = "SLS-TAX-CODE":U THEN
            DO:
              FIND FIRST buf-WKFILE WHERE buf-WKFILE.PROG-NAME   EQ "RESPR":U
                                      AND buf-WKFILE.TERMINAL-ID EQ TRIM(f_valor) NO-LOCK NO-ERROR.
                         
              IF AVAILABLE buf-WKFILE THEN
                ASSIGN f_valor = buf-WKFILE.CHAR1.
            END.
 
            IF FLATR.BROWSER-SP-DISPLAY = "AUTHOR":U THEN
            DO:
              FIND FIRST buf-WKFILE WHERE buf-WKFILE.PROG-NAME   EQ "RERIP":U
                                      AND buf-WKFILE.TERMINAL-ID EQ TRIM(f_valor) NO-LOCK NO-ERROR.
                        
              IF AVAILABLE buf-WKFILE THEN
                ASSIGN f_valor = buf-WKFILE.CHAR1.
            END.
                   
            IF FLATR.FIELD-ID EQ "FILL-IN-QTY":U THEN
              IF F_VALOR EQ "0":U THEN
                ASSIGN F_VALOR = STRING(COODT.ORDER-QTY).
                
          END. /* IF bracket-pos EQ 0 THEN */
          ELSE
          DO:
            DEFINE VAR subs-var AS CHARACTER    NO-UNDO.
            DEFINE VAR subs-val AS INTEGER      NO-UNDO.
 
            ASSIGN subs-var = SUBSTRING(flatr.browser-sp-displ,1, bracket-pos - 1)
                   subs-val = INTEGER(SUBSTRING(flatr.browser-sp-displ, 
                                                bracket-pos + 1, 
                                         LENGTH(flatr.browser-sp-displ) - (bracket-pos + 1))).
 
            ASSIGN h_field = h_file:BUFFER-FIELD(subs-var)
                   f_valor = h_field:BUFFER-VALUE[subs-val].
 
          END. /* ELSE IF bracket-pos EQ 0 THEN */
 
          THIS-OBJECT:crearRecord(INPUT flatr.field-id,
                                  INPUT f_valor).
                                    
        END. /* IF AVAILABLE handles_file THEN  */
          
      END. /* FOR EACH FLATR.. */
    
    END METHOD. /* END createJobTrk() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID createHandle(INPUT F_name AS CHARACTER,
                                    INPUT F_handle AS HANDLE):
      /*****----------------------------------------------*****/
      /* c r e a t e - h a n d l e                            */
      /*****----------------------------------------------*****/
 
      FIND handles_file WHERE handles_file.FILE_name EQ f_name NO-LOCK NO-ERROR.
 
      IF NOT AVAILABLE handles_file THEN
         CREATE handles_file.
 
      ASSIGN handles_file.FILE_name   = f_name
             handles_file.FILE_handle = f_handle.
 
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID crearRecordPrincipal():
      
      /*****----------------------------------------------*****/
      /* C R E A R - R E C O R D - p r i n c i p a l          */
      /*****----------------------------------------------*****/
 
      ASSIGN 
        UPDATE-ORDER    = NO
        CURRENT-STATUS  = SUBSTRING(STRING(COOHD.WAREHOUSE-NO,"99":U),2,1) + "00000":U .
 
      FIND FIRST buf-wkfile WHERE buf-wkfile.prog-name   EQ "OEJBTRK":U 
                                                         + COODT.ORDER-NUMBER 
                                                         + STRING(COODT.ORDER-SEQ,"999":U)
                              AND BUF-WKFILE.TERMINAL-ID EQ "FILL-IN-JOB":U EXCLUSIVE-LOCK NO-ERROR.
    
      IF NOT AVAILABLE BUF-WKFILE THEN
      DO:
        CREATE BUF-WKFILE.
        ASSIGN 
          buf-wkfile.prog-name    = "OEJBTRK":U 
                                  + COODT.ORDER-NUMBER 
                                  + STRING(COODT.ORDER-SEQ,"999":U)
          BUF-WKFILE.TERMINAL-ID  = "FILL-IN-JOB":U  
          BUF-WKFILE.CHAR1        = COODT.ORDER-NUMBER 
                                  + STRING(COODT.ORDER-SEQ,"999":U)
          BUF-WKFILE.CHAR2        = CURRENT-STATUS 
          BUF-WKFILE.CHAR3        = STRING(coohd.warehouse-no,"99":U).
      END.  /* IF NOT AVAILABLE BUF-WKFILE */
      ELSE
      DO:
        ASSIGN 
          UPDATE-ORDER = YES.
      END. /* IF AVAILABLE BUF-WKFILE */
 
      /********************************************************/
      /* FIND ORDER STATUS RECORD                             */
      /********************************************************/
      FIND JOB-STATUS WHERE JOB-STATUS.TERMINAL-ID EQ "FILL-IN-status":U
                        AND JOB-STATUS.PROG-NAME   EQ "OEJBTRK":U 
                                                    + COODT.ORDER-NUMBER 
                                                    + string(COODT.ORDER-SEQ,"999":U) EXCLUSIVE-LOCK NO-ERROR.
      IF NOT AVAILABLE JOB-STATUS THEN
      DO:
        CREATE JOB-STATUS.
        ASSIGN
          JOB-STATUS.TERMINAL-ID  = "FILL-IN-status":U
          JOB-STATUS.PROG-NAME    = "OEJBTRK":U 
                                  + COODT.ORDER-NUMBER 
                                  + string(COODT.ORDER-SEQ,"999":U)
          JOB-STATUS.CHAR1        = BUF-WKFILE.CHAR2.             /* CURRENT STATUS */
 
        ASSIGN 
          jblog-date          = NOW
          jblog-date-CHAR     = STRING(jblog-date )
          jblog-date-DT       = DATETIME(jblog-date-CHAR).        /*CURRENT DATE-TIME*/
 
        /********************************************************/
        /* CREATE WKFILE WITH HISTORY OF STATUS CHANGES         */
        /********************************************************/
        CREATE HST-STATUS.
        ASSIGN
          HST-STATUS.TERMINAL-ID  = "FILL-IN-current-status":U
          HST-STATUS.PROG-NAME    = "OEJBLOG":U 
                                  + COODT.ORDER-NUMBER 
                                  + string(COODT.ORDER-SEQ,"999":U)
          HST-STATUS.CHAR1        = JOB-STATUS.CHAR1                /* NEW STATUS       */
          HST-STATUS.CHAR2        = " ":U                           /* PREVIOUS STATUS  */
          HST-STATUS.CHAR3        = USERID("CDI":U)                 /* LOG TO DATABASE  */
          HST-STATUS.CHAR4        = TERMINAL-ID                     /* LOG TO CDIPREMIUM*/
          HST-STATUS.CHAR5        = TMP-HEADER.SALES-REP-ID         /* SALES-PERSON LOG IN TO PROGRAM*/
          HST-STATUS.CHAR6        = STRING(YEAR(TODAY),"9999":U) 
                                  + STRING(MONTH(TODAY), "99":U)
                                  + STRING(DAY(TODAY), "99":U)
          HST-STATUS.CHAR7        = STRING(TIME,"HH:MM:SS":U)
          HST-STATUS.CHAR8        = "oeinvup":U                     /* PROGRAM NAME     */
          HST-STATUS.CHAR9        = jblog-date-CHAR
          HST-STATUS.DATE1        = TODAY
          HST-STATUS.LOGICAL1     = YES                             /*ACTIVE TRANSACTION*/
          HST-STATUS.LOGICAL2     = NO.                             /*REVERSE TRANSACTION*/
 
        
        /* NO CHANGE IS STATUS MADE BUT REGISTER ORDER CHANGE   */
        
        IF UPDATE-ORDER THEN
        DO:
          ASSIGN
            HST-STATUS.CHAR1        = JOB-STATUS.CHAR1                  /* NEW STATUS       */
            HST-STATUS.CHAR2        = JOB-STATUS.CHAR1                  /* PREVIOUS STATUS  */
            HST-STATUS.LOGICAL1     = NO.                               /*ACTIVE TRANSACTION*/
            
        END. /* IF UPDATE-ORDER = YES */
 
      END. /* IF NOT AVAILABLE JOB-STATUS */
      
    END METHOD. /* END crearRecordPrincipal() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID crearRecord(INPUT NOMBRE-CAMPO AS CHARACTER,
                                   INPUT VALOR-CAMPO  AS CHARACTER):
      /*****----------------------------------------------*****/
      /* C R E A R - R E C O R D                              */
      /*****----------------------------------------------*****/
 
      FIND buf-wkfile WHERE buf-wkfile.prog-name    EQ "OEJBTRK":U 
                                                     + COODT.ORDER-NUMBER 
                                                     + STRING(COODT.ORDER-SEQ,"999":U)
                        AND BUF-WKFILE.TERMINAL-ID  EQ NOMBRE-CAMPO EXCLUSIVE-LOCK NO-ERROR.
    
      IF NOT AVAILABLE BUF-WKFILE THEN
      DO:
        CREATE BUF-WKFILE.
        ASSIGN 
          buf-wkfile.prog-name   = "OEJBTRK":U 
                                 + COODT.ORDER-NUMBER 
                                 + STRING(COODT.ORDER-SEQ,"999":U)
          BUF-WKFILE.TERMINAL-ID = NOMBRE-CAMPO.  
      END.
 
      ASSIGN BUF-WKFILE.CHAR1    = VALOR-CAMPO.
 
    END METHOD. /* END crearRecord() */
       
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID createOrderChild():
      /*****----------------------------------------------*****/
      /* C R E A T E - O R D E R - C H I L D                  */
      /*****----------------------------------------------*****/
 
      FOR EACH SIZE-SELECTED WHERE SIZE-SELECTED.INVOICE-NUMBER EQ tmp-detail.TMP-NUMBER 
                               AND SIZE-SELECTED.INVOICE-SEQ    EQ tmp-DETAIL.TMP-SEQ   
                               AND SIZE-SELECTED.ITEM-NUMBER    EQ TMP-DETAIL.ITEM-NUMBER NO-LOCK: /* 06/25/09 */
        
        FIND CINV1 WHERE CINV1.ITEM-NUMBER EQ SIZE-SELECTED.ITEM-NUMBER NO-LOCK NO-ERROR.
 
        FIND tmp-detail WHERE tmp-detail.TMP-NUMBER  EQ SIZE-SELECTED.INVOICE-NUMBER
                          AND tmp-DETAIL.TMP-SEQ     EQ SIZE-SELECTED.INVOICE-SEQ 
                          AND TMP-DETAIL.ITEM-NUMBER EQ SIZE-SELECTED.ITEM-NUMBER NO-LOCK NO-ERROR. /* 06/25/09 */
       
        //ASSIGN SIZE-SELECTED.SIZE-QTY = TMP-DETAIL.QUANTITY. /* R.S */
        
        CREATE COOSZ.
        ASSIGN 
          COOSZ.ORDER-NUMBER   = INVOICE-NUM
          COOSZ.ORDER-SEQ      = SIZE-SELECTED.INVOICE-SEQ
          COOSZ.ITEM-NUMBER    = SIZE-SELECTED.ITEM-NUMBER
          COOSZ.SIZE           = SIZE-SELECTED.SIZE
          COOSZ.STYLE-COLOR    = SIZE-SELECTED.STYLE-COLOR
          COOSZ.SIZE-QTY       = SIZE-SELECTED.SIZE-QTY
          COOSZ.UNIT-QTY       = SIZE-SELECTED.UNIT-QTY
          COOSZ.QTY-PENDING    = SIZE-SELECTED.SIZE-QTY.
          
      END.  /* FOR EACH SIZE-SELECTED */
      
    END METHOD. /* END createOrderChild() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID commitItem(INPUT ORDER-NUMBER AS CHARACTER,
                                  INPUT ORDER-SEQ    AS INTEGER):
      /*****----------------------------------------------*****/
      /* C O M M I T - I T E M                                */
      /*****----------------------------------------------*****/
      /*msc suma a commited en ordenes*/
    
      FIND COOHD WHERE COOHD.ORDER-NUMBER EQ ORDER-NUMBER  EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
 
      FIND COODT WHERE COODT.ORDER-NUMBER EQ ORDER-NUMBER
                   AND COODT.ORDER-SEQ    EQ ORDER-SEQ NO-LOCK NO-ERROR.
 
 
      /* 07/16/2014 RESERVA BERRIOS ESTO ES TEMPORERO MIENTRAS EXISTAN TIENDAS CON EL SISTEMA VIEJO EN BERRIOS*************/
      IF via-wanted THEN 
      DO:
        ASSIGN
          VOP-WARE = tmp-detail.WAREHOUSE 
          VOP-ITEM = tmp-detail.ITEM-NUMBER 
          VOP-QTY  = inv-QTY
          VOP-TIPO = "ORDER":U.
      
        //THIS-OBJECT:Reserva(). /* R.S*/
      END. /* IF via-wanted THEN */
      
      /* 07/16/2014 RESERVA BERRIOS ESTO ES TEMPORERO MIENTRAS EXISTAN TIENDAS CON EL SISTEMA VIEJO EN BERRIOS*************/
 
      IF NOT DELIV-MULTI-WHS AND NOT AUTO-SALES /* 07/02/2012 */ THEN
        /********************************************************/
        /* ONE WAREHOUSE FOR ALL THE ITEMS                      */
        /********************************************************/
        FIND CINV2 WHERE CINV2.ITEM-NUMBER  EQ tmp-detail.ITEM-NUMBER 
                     AND CINV2.WAREHOUSE-NO EQ TMP-HEADER.WAREHOUSE-NO EXCLUSIVE-LOCK NO-WAIT NO-ERROR. 
       
      ELSE
        /********************************************************/
        /* EACH ITEM HAS A WAREHOUSE                            */
        /********************************************************/
        FIND CINV2 WHERE CINV2.ITEM-NUMBER  EQ tmp-detail.ITEM-NUMBER 
                     AND CINV2.WAREHOUSE-NO EQ tmp-detail.WAREHOUSE-NO EXCLUSIVE-LOCK NO-WAIT NO-ERROR. 
       
      IF NOT AVAILABLE CINV2 THEN
      DO:
        CREATE CINV2.
        ASSIGN CINV2.ITEM-NUMBER  = tmp-detail.ITEM-NUMBER .
          
        IF NOT DELIV-MULTI-WHS AND NOT AUTO-SALES  THEN
          ASSIGN CINV2.WAREHOUSE-NO = TMP-HEADER.WAREHOUSE-NO.
        ELSE
          ASSIGN CINV2.WAREHOUSE-NO = tmp-detail.WAREHOUSE-NO.
             
      END. /* IF NOT AVAILABLE CINV2 */
 
      /*    FIND CINV2 WHERE CINV2.ITEM-NUMBER  = CINV1.ITEM-NUMBER AND   */
      /*                     CINV2.WAREHOUSE-NO = tmp-detail.WAREHOUSE-NO */
      /*                     EXCLUSIVE-LOCK NO-ERROR. /*04/12/2006*/      */
 
      IF AVAILABLE CINV2 THEN
      DO:
        ASSIGN CINV2.QTY-COMMITED = CINV2.QTY-COMMITED + inv-QTY.
 
        IF  CINV2.QTY-COMMITED LT 0 THEN
            CINV2.QTY-COMMITED EQ 0.
 
        FOR EACH COOSZ OF COODT NO-LOCK:
                      
          FIND SIZE WHERE SIZE.WAREHOUSE-NO EQ COODT.WAREHOUSE-NO      /*** 09/12/2014 wam Toledo ***/
                      AND SIZE.ITEM-NUMBER  EQ COOSZ.ITEM-NUMBER
                      AND SIZE.STYLE-COLOR  EQ COOSZ.STYLE-COLOR
                      AND SIZE.SIZE         EQ COOSZ.SIZE EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
                       
          IF AVAILABLE SIZE THEN
          DO:
            ASSIGN SIZE.QTY-COMMITED = SIZE.QTY-COMMITED + COOSZ.QTY-PENDING.
          
            IF SIZE.QTY-COMMITED LT 0 THEN
              ASSIGN SIZE.QTY-COMMITED = 0.
          END. /* IF AVAILABLE SIZE THEN */   
            
        END. /* FOR EACH COOSZ */
 
      END. /*  IF AVAILABLE CINV2 */
 
    END METHOD. /* END commitItem() */
    
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID creaMante():
      /*****----------------------------------------------*****/
      /* C R E A - M A N T E  subscripcion revistas 05/26/2009 */
      /*****----------------------------------------------*****/
      DEF VAR meses  AS INTEGER  NO-UNDO.
      DEF VAR mon    AS INTEGER  NO-UNDO.
      DEF VAR days   AS INTEGER  NO-UNDO.
      DEF VAR yrs    AS INTEGER  NO-UNDO.
 
      DEF BUFFER coodt-b FOR COODT.
      DEF BUFFER mante-b FOR MANTE.
 
      FIND MANTE WHERE MANTE.CUST-NUMBER EQ COOHD.CUST-NUMBER
                   AND MANTE.SERIAL-NO   EQ COOHD.ORDER-NUMBER + STRING(COODT.ORDER-SEQ,"999":U) EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
      
      IF NOT AVAILABLE MANTE THEN
      DO:
        IF NOT CINV1.ITEM-NUMBER BEGINS company + "*":U THEN
        DO:
          ASSIGN meses = CINV1.STANDARD-QTY.
            
          FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ COOHD.CUST-NUMBER EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
          IF AVAILABLE CCSMS THEN
            ASSIGN 
              CCSMS.CONTRACT-IND = CINV1.PACK
              CCSMS.BILLING-DATE = COOHD.DATE-WANTED.
 
          FOR EACH coodt-b WHERE coodt-b.order-number EQ COOHD.ORDER-NUMBER
                             AND coodt-b.order-seq GE 995 
                             AND coodt-b.order-seq LE 996 NO-LOCK : 
           
            FIND mante-b WHERE mante-b.cust-number EQ COOHD.CUST-NUMBER
                           AND mante-b.serial-no   EQ COOHD.ORDER-NUMBER 
                                                    + STRING(COODT-B.ORDER-SEQ,"999":U) EXCLUSIVE-LOCK NO-ERROR.
                
            IF AVAILABLE mante-b THEN
              ASSIGN mante-b.monthly-rate = coodt-b.ordered-prc / meses.
 
          END.  /* FOR EACH coodt-b */
 
        END. /* IF NOT cinv1.item-number BEGINS company + "*" */
 
        CREATE MANTE.
        ASSIGN 
          MANTE.CUST-NUMBER  = COOHD.CUST-NUMBER
          MANTE.SERIAL-NO    = COOHD.ORDER-NUMBER + STRING(COODT.ORDER-SEQ,"999":U)
          MANTE.MODEL        = COODT.ITEM-NUMBER 
          MANTE.DELIVERY-DT  = COOHD.DATE-WANTED
          MANTE.FIRST-BIL-DT = COOHD.DATE-WANTED
          MANTE.REC-BIl-DATE = COOHD.DATE-WANTED
          MANTE.CONTRACT-DT  = COOHD.DATE-WANTED
          MANTE.DESCRIPTION  = CINV1.DESCRIPTION
          MANTE.MONTHLY-RATE = COODT.ORDERED-PRC / meses.
          
        /* 11/16/09 jra  revistas */
        FIND USERFILE WHERE USERFILE.CODE EQ COOHD.TP-NAME NO-LOCK NO-ERROR.
        IF AVAILABLE USERFILE THEN
          ASSIGN MANTE.MAKE         = USERFILE.NAME
                 MANTE.SALES-REP-ID = USERFILE.CODE.
          ASSIGN 
            mon = MONTH(COOHD.DATE-WANTED)
            days = DAY(COOHD.DATE-WANTED)
            yrs =  YEAR(COOHD.DATE-WANTED)
            MON = MON + CINV1.STANDARD-QTY.
 
        IF mon GT 12 THEN
        DO:
          ASSIGN 
            mon = mon - meses
            yrs = yrs + 1.
        END.
 
        IF cinv1.pack NE "w":U THEN
          ASSIGN MANTE.CONTR-END-DT =  DATE(mon,days,yrs).
        ELSE
          ASSIGN MANTE.CONTR-END-DT = COOHD.DATE-WANTED + (meses * 7).
 
        IF NOT CINV1.ITEM-NUMBER BEGINS company + "*":U THEN
        DO:
          FIND mante-b WHERE mante-b.cust-number EQ MANTE.CUST-NUMBER
                         AND mante-b.serial-no   EQ SUBSTR(MANTE.SERIAL-NO,1,6) + "995":U EXCLUSIVE-LOCK NO-ERROR.
            
          IF AVAILABLE mante-b THEN
            ASSIGN mante-b.contr-end-dt = MANTE.CONTR-END-DT. 
                            
          FIND mante-b WHERE mante-b.cust-number  = MANTE.CUST-NUMBER
                         AND mante-b.serial-no    = SUBSTR(MANTE.SERIAL-NO,1,6) + "996":U EXCLUSIVE-LOCK NO-ERROR.
            
          IF AVAILABLE mante-b THEN
            ASSIGN mante-b.contr-end-dt = MANTE.CONTR-END-DT.
            
        END. /* IF NOT cinv1.item-number BEGINS company + "*" */
 
      END. /*  IF NOT AVAILABLE MANTE */
 
    END METHOD. /* END creaMante() */
        
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID renumberMessg():
      /*****----------------------------------------------*****/
      /* R E N U M B E R - M E S S G                          */
      /*****----------------------------------------------*****/
      /********************************************************/
      /*  1. Direct Sales                                     */
      /*  6. Invoice Entry                                    */
      /* 50. SALDOS DE LAYAWAY,                               */
      /*     PROCESA IGUAL A #1 MAS SALDA LAYAWAY ORDHD       */
      /********************************************************/                                                                          
      IF TRANS-TYPE = "1":U   OR 
         TRANS-TYPE = "50":U  OR 
         TRANS-TYPE = "51":U  OR  
         TRANS-TYPE = "6":U   OR 
         TRANS-TYPE = "14":U  OR    /* picking process */
         TRANS-TYPE = "11":U  THEN  /*xxxx 12/28/2006*/  
           
        FOR EACH MESSG WHERE MESSG.DOC-NUMBER EQ  USER("CDI":U)  
                         AND MESSG.FILE-NAME  EQ  "MSGIV":U EXCLUSIVE-LOCK:
 
          FIND buf-messg WHERE buf-messg.FILE-NAME   EQ MESSG.FILE-NAME 
                           AND buf-messg.doc-number  EQ INVOICE-NUM
                           AND buf-messg.doc-seq     EQ MESSG.DOC-SEQUENCE 
                           AND buf-messg.message-seq EQ MESSG.MESSAGE-SEQ EXCLUSIVE-LOCK NO-ERROR.
               
          IF NOT AVAILABLE buf-messg THEN 
            CREATE buf-messg.
 
          ASSIGN 
            buf-messg.FILE-NAME    = MESSG.FILE-NAME 
            buf-messg.doc-number   = INVOICE-NUM 
            buf-messg.doc-seq      = MESSG.DOC-SEQUENCE 
            buf-messg.message-seq  = MESSG.MESSAGE-SEQ
            buf-messg.message-DESC = MESSG.MESSAGE-DESC.
 
          DELETE MESSG.
             
        END. /* FOR EACH MESSG..*/
          
      ELSE
        FOR EACH MESSG WHERE MESSG.DOC-NUMBER   EQ  USER("CDI":U) 
                         AND MESSG.FILE-NAME    EQ  "MSGOE":U 
                         AND MESSG.DOC-SEQUENCE NE  704 EXCLUSIVE-LOCK: /*06/16/2010 MSC PARA QUE NO ALTERE EL SHIPTO DE LA ORDEN*/
               
          FIND buf-messg WHERE buf-messg.FILE-NAME   EQ MESSG.FILE-NAME 
                           AND buf-messg.doc-number  EQ INVOICE-NUM 
                           AND buf-messg.doc-seq     EQ MESSG.DOC-SEQUENCE 
                           AND buf-messg.message-seq EQ MESSG.MESSAGE-SEQ EXCLUSIVE-LOCK NO-ERROR.
               
          IF NOT AVAILABLE buf-messg THEN 
            CREATE buf-messg.
 
          ASSIGN 
            buf-messg.FILE-NAME    = MESSG.FILE-NAME 
            buf-messg.doc-number   = INVOICE-NUM 
            buf-messg.doc-seq      = MESSG.DOC-SEQUENCE 
            buf-messg.message-seq  = MESSG.MESSAGE-SEQ
            buf-messg.message-DESC = MESSG.MESSAGE-DESC.
 
          DELETE MESSG. 
 
        END. /* FOR EACH MESSG..*/
                
    END METHOD. /* END renumberMessg() */
        
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID verificaItem(INPUT ITEM-NUMBER AS CHARACTER):
      
      /*****----------------------------------------------*****/
      /* M E T H O D - V E R I F I C A - I T E M                  */
      /*****----------------------------------------------*****/
 
      FIND CINV1 WHERE CINV1.ITEM-NUMBER EQ ITEM-NUMBER EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
      IF NOT AVAILABLE CINV1 THEN
      DO:
        CREATE CINV1.
        ASSIGN CINV1.ITEM-NUMBER = ITEM-NUMBER
               CINV1.DESCRIPTION = ITEM-NUMBER
               CINV1.LINE-UP     = "R":U
               CINV1.DATE-CREATED = TODAY.
               
      END. /* IF NOT AVAILABLE CINV1 THEN */
      
    END METHOD. /* END verificaItem() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID releaseFiles():
      /*****----------------------------------------------*****/
      /* R E L E A S E - F I L E S                            */
      /*****----------------------------------------------*****/
      RELEASE UPDATE-LOCK NO-ERROR.
      RELEASE CMPNY       NO-ERROR.
      RELEASE CCSMS       NO-ERROR.
      RELEASE CISER       NO-ERROR.
      RELEASE CINV1       NO-ERROR.
      RELEASE CINV2       NO-ERROR.   
      RELEASE SIZE        NO-ERROR.
      RELEASE CSAHF       NO-ERROR.
      RELEASE COPAR       NO-ERROR.
      RELEASE CIMRC       NO-ERROR.
      RELEASE COOHD       NO-ERROR.
      RELEASE COODT       NO-ERROR.
      RELEASE COOSZ       NO-ERROR.
      RELEASE CIVHD       NO-ERROR.
      RELEASE CIVDT       NO-ERROR.
      RELEASE CIVSZ       NO-ERROR.
      RELEASE COPTR       NO-ERROR. /* R.S */
      RELEASE CALLG       NO-ERROR. /* R.S */ 
      RELEASE CALLS       NO-ERROR. /* R.S */ 
      RELEASE CAPLY       NO-ERROR. /* R.S */ 
      RELEASE CCRIR       NO-ERROR. /* R.S */
      RELEASE TMP-HEADER.
      RELEASE TMP-DETAIL.
      RELEASE SIZE-SELECTED.
 
    END METHOD. /* END releaseFiles() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID orderFromHeader():
      /*****----------------------------------------------*****/
      /* O R D E R - F R O M - H E A D E R                    */
      /*****----------------------------------------------*****/
      /********************************************************/
      /*  4. Order/Quote Change                               */
      /*  5. Qoute Conversion                                 */
      /********************************************************/
      THIS-OBJECT:createCOOHD().
 
      IF tmp-header.CITY-TAX-AMT NE 0 THEN
      DO:
        THIS-OBJECT:verificaItem(INPUT COMPANY + "*CITY-TAX*":U).
        THIS-OBJECT:createCooTax(INPUT 995,
                                 INPUT COMPANY + "*CITY-TAX*":U,
                                 INPUT tmp-header.CITY-TAX-AMT).
      END.
 
      IF tmp-header.STATE-TAX-AMT NE 0 THEN
      DO:
        THIS-OBJECT:verificaItem(INPUT COMPANY + "*STATE-TAX*":U).
        THIS-OBJECT:createCooTax(INPUT 996,
                                 INPUT COMPANY + "*STATE-TAX*":U,
                                 INPUT tmp-header.STATE-TAX-AMT).
       
      END.
 
      ASSIGN MSG-FILE-NAME = "MSGOE":U. 
      
      /********************************************************/
      /* SAVE SHIP TO DATA INSIDE FILE MESSG                  */
      /********************************************************/
      
       THIS-OBJECT:getShipNo().
      THIS-OBJECT:ordFollowUp().
      THIS-OBJECT:renumberMessg().
 
    END METHOD. /* END orderFromHeader() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID createCOOHD():
      /*****----------------------------------------------*****/
      /* C R E A T E - C O O H D                              */
      /*****----------------------------------------------*****/
 
      /********************************************************/
      /*  4. Order/Quote Change                               */
      /********************************************************/
      DEFINE VARIABLE dOrderDate AS DATE      NO-UNDO.
      DEFINE VARIABLE cOrderTime AS CHARACTER NO-UNDO.
      DEFINE VARIABLE lcorder-status AS CHARACTER NO-UNDO.
      IF INDEX(cOrderDateTime, " ":U) NE 0 THEN
        ASSIGN
          cOrderTime = ENTRY(2, cOrderDateTime, '') 
          dOrderDate = DATE(ENTRY(1, cOrderDateTime, '')) NO-ERROR.
      
      /*FIND FIRST TERMS WHERE TERMS.CUS-TERMS-CD EQ TMP-HEADER.CUS-TERMS-CD NO-LOCK NO-ERROR.                     
      IF AVAILABLE TERMS THEN TRUE.
        ASSIGN TMP-HEADER.CUS-TERMS-DS = TERMS.CUS-TERMS-DS.*/     
      
      IF TRANS-TYPE NE "4":U  AND
         TRANS-TYPE NE "10":U AND  
         TRANS-TYPE NE "13":U THEN        /*xxxx 12/28/2006*/
         
        CREATE COOHD.       
      ELSE
        
        FIND COOHD WHERE COOHD.FORM-ID      EQ TMP-HEADER.FORM-ID 
                     AND COOHD.CUST-NUMBER  EQ TMP-HEADER.CUST-NUMBER 
                     AND COOHD.ORDER-NUMBER EQ TMP-HEADER.TMP-NUMBER EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
       
      COPY-LOB FROM lcDigitalSign TO COOHD.SIGNATURE NO-ERROR. 
   // FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ TMP-HEADER.CUST-NUMBER NO-LOCK NO-ERROR.
      FIND FIRST SHPTO WHERE SHPTO.CUST-NAME    EQ COOHD.SHIP-TO-NAME
                         AND SHPTO.SHIP-NUMBER  EQ tmp-header.SHIP-TO-NO NO-LOCK NO-ERROR. 
      FIND TERMS WHERE TERMS.CUS-TERMS-CD EQ TMP-HEADER.CUS-TERMS-CD  NO-LOCK NO-ERROR.                   
      ASSIGN 
        COOHD.ADDRESS-L1            = IF AVAILABLE CCSMS THEN CCSMS.ADDRESS-L1 else TMP-HEADER.ADDRESS-L1
        COOHD.ADDRESS-L2            = IF AVAILABLE CCSMS THEN CCSMS.ADDRESS-L2 ELSE TMP-HEADER.ADDRESS-L2
        COOHD.ADDRESS-L3            = IF AVAILABLE CCSMS THEN CCSMS.ADDRESS-L3 ELSE TMP-HEADER.ADDRESS-L3
        COOHD.COMPANY-CODE          = COMPANY /*TMP-HEADER.COMPANY-CODE*/ 
        COOHD.CUS-ORDER-NO          = IF TMP-HEADER.CUS-ORDER-NO EQ ? OR TMP-HEADER.CUS-ORDER-NO EQ "0"  THEN "" ELSE  TMP-HEADER.CUS-ORDER-NO
        COOHD.CUS-TERMS-CD          = TMP-HEADER.CUS-TERMS-CD 
        COOHD.CUS-TERMS-DS          =  IF AVAILABLE terms THEN TERMS.CUS-TERMS-DS ELSE ""  //TMP-HEADER.CUS-TERMS-DS 
        COOHD.CUST-NAME             =  IF AVAILABLE CCSMS THEN CCSMS.CUST-NAME ELSE TMP-HEADER.CUST-NAME 
        COOHD.CUST-NUMBER           = TMP-HEADER.CUST-NUMBER 
        COOHD.DISCOUNT-AMT          = TMP-HEADER.DISCOUNT-AMT 
        COOHD.DISC-PERC             = TMP-HEADER.DISC-PERC
        COOHD.DROP-SHP              = NO 
        COOHD.FORM-ID               = TMP-HEADER.FORM-ID
        COOHD.FREIGHT-AMT           = TMP-HEADER.FREIGHT-AMT  
        COOHD.HOUR                  = STRING(TIME,"HH:MM") 
        COOHD.MISC-CHG-AMT          = TMP-HEADER.MISC-CHG-AMT
        COOHD.LAPTOP                = TMP-HEADER.LAPTOP
        COOHD.ORDER-DATE            = TODAY 
        COOHD.ORDER-NUMBER          = INVOICE-NUM 
        COOHD.SALES-REP-ID          = TMP-HEADER.SALES-REP-ID
        COOHD.SHIP-ADDR-L1          = IF AVAILABLE shpto THEN SHPTO.ADDRESS-L1 ELSE TMP-HEADER.SHIP-ADDR-L1
        COOHD.SHIP-ADDR-L2          = IF AVAILABLE shpto THEN SHPTO.ADDRESS-L2 ELSE TMP-HEADER.SHIP-ADDR-L2
        COOHD.SHIP-ADDR-L3          = IF AVAILABLE shpto THEN SHPTO.ADDRESS-L3 ELSE TMP-HEADER.SHIP-ADDR-L3
        COOHD.SHIP-TO-NAME          = IF AVAILABLE shpto THEN SHPTO.CUST-NAME ELSE TMP-HEADER.SHIP-TO-NAME
        COOHD.WAREHOUSE-NO          = TMP-HEADER.WAREHOUSE-NO 
/*        COOHD.DATE-WANTED           = TODAY + 2*/
        COOHD.DATE-WANTED           = IF TMP-HEADER.DATE-WANTED = ? THEN TODAY + 1 ELSE TMP-HEADER.DATE-WANTED 
        //COOHD.DATE-WANTED           = IF NOT AVAILABLE TMP-HEADER.DATE-WANTED THEN  TODAY + 1 ELSE  TMP-HEADER.DATE-WANTED
        COOHD.SHIP-VIA              = "NO":U  
        COOHD.TP-NAME               = TMP-HEADER.OPERATOR /* Used as OPERATOR */
        COOHD.ORDER-AMOUNT          = 0
        //COOHD.CREDIT-IND          = TMP-HEADER.CONDUCE-NUM /*R.S 07/02/2018*/
        //COOHD.CONFIRM-IND           = "":U /* This will be commented out */
        COOHD.CONFIRM-IND           = TMP-HEADER.CONFIRM-IND /* Undeployed - when order on hold */
        COOHD.cust-PHONE-NUMBER     = tmp-header.cust-PHONE-NUMBER     
        //COOHD.shipto-PHONE-NUMBER   = tmp-header.shipto-PHONE-NUMBER /* R.S */ 
        COOHD.PHYSICAL-ZIP          = TMP-HEADER.PHYSICAL-ZIP /*STRING(TMP-HEADER.PHYSICAL-ZIP,"99999":U) 07/17/2014*/
        /*** 09/04/2014 wam Toledo start ***/
        COOHD.alfa-1                = TMP-HEADER.SHIP-TO-NO   
        COOHD.SHIP-NUMBER           = IF TMP-HEADER.SHIP-TO-NO EQ "PRIMARY" THEN "" ELSE TMP-HEADER.SHIP-TO-NO                          
        COOHD.alfa-2                = "2":U /* For Transaction-type = 2 New Order */                                                                                                     
        COOHD.po-number             = tmp-header.po-number
        COOHD.Longitude             = cLongitude
        COOHD.Latitude              = cLatitude
        COOHD.Signee                = cSigneeName
        COOHD.ORDER-DATE            = dOrderDate
        COOHD.HOUR                  = cOrderTime
        COOHD.ORDER-ORIGIN          = lcOrder-Origin
        COOHD.PRINTED-IND           = IF lcSendEmailForOrder EQ "yes" THEN "EMAIL":U ELSE " " 
        COOHD.SHIP-VIA              = TMP-HEADER.SHIP-VIA-CD
        COOHD.ROUTE                 = TMP-HEADER.ROUTE
        COOHD.route-stop            = TMP-HEADER.route-stop .
                            
        /*** 09/04/2014 wam Toledo  end  ***/
        /*** 11/12/2015 wam NUÑEZ start ***/
       /* COOHD.ROUTE                 = tmp-header.ROUTE                            
        COOHD.route-stop            = tmp-header.route-stop            
        COOHD.route-stop-seq        = tmp-header.route-stop-seq . */ /* R.S. 07-02-2018 */     
        /*** 11/12/2015 wam NUÑEZ  end  ***/
  
      /*06/11/2014*/
      THIS-OBJECT:layerType().
 
      /* SE CREO EN TMP-HEADER.CONFIRM-IND
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = COMPANY
                     AND PARAMFL.PARAM-ID     = "PUT-ON-HOLD"
                     AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
    
 
      IF AVAILABLE PARAMFL AND CCSMS.DELINQUENT-I = "H" THEN
      DO:
        COOHD.CONFIRM-IND = "HOLD-H".
      END.
      */
 
      IF (tmp-header.CITY-TAX-EXEMPT    AND 
          tmp-header.state-TAX-EXEMPT)  THEN
            
        ASSIGN COOHD.TAX-AUTH-CD  = "no":U .  
 
      IF (tmp-header.CITY-TAX-EXEMPT   AND 
      NOT tmp-header.state-TAX-EXEMPT) THEN 
        
        ASSIGN COOHD.TAX-AUTH-CD = "nc":U.  
 
      IF  (NOT tmp-header.CITY-TAX-EXEMPT AND 
           tmp-header.state-TAX-EXEMPT )  THEN
          
        ASSIGN COOHD.TAX-AUTH-CD = "ns":U.  
 
      IF NOT tmp-header.CITY-TAX-EXEMPT   AND 
         NOT tmp-header.state-TAX-EXEMPT  THEN  
       
        ASSIGN COOHD.TAX-AUTH-CD  = " ":U .  
 
    /*  IF COOHD.DISC-PERC NE 0 THEN
        ASSIGN COOHD.DISCOUNT-AMT = 0. */ 
                         
    END METHOD. /* END createCOOHD() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID createCooTax(INPUT INVOICE-SEQ AS INTEGER,
                                    INPUT ITEM-NUMBER AS CHARACTER,
                                    INPUT AMOUNT      AS DECIMAL):
                              
      /*****----------------------------------------------*****/
      /* P R O C - c r e a t e - c O O - t a x                */
      /*****----------------------------------------------*****/

      FIND COODT WHERE COODT.ORDER-NUMBER EQ INVOICE-NUM 
                   AND COODT.ORDER-SEQ    EQ INVOICE-SEQ EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
      
      IF NOT AVAILABLE COODT THEN CREATE COODT.
 
      ASSIGN 
        COODT.ORDER-NUMBER  = INVOICE-NUM  
        COODT.ORDER-SEQ     = INVOICE-SEQ
        COODT.ITEM-NUMBER   = ITEM-NUMBER
        COODT.ORIGINAL-QTY  = 1
        COODT.ORDER-QTY     = 1
        COODT.ORDERED-PRC   = AMOUNT
        COODT.WAREHOUSE-NO  = COOHD.WAREHOUSE-NO
        COODT.CLASS-CODE    = CINV1.CLASS-CODE
        COODT.DESCRIPTION   = ITEM-NUMBER
        /*** 09/04/2014 wam Toledo start ***/
        COODT.damage        = "N":U.
        /*** 09/04/2014 wam Toledo  end  ***/
        COOHD.ORDER-AMOUNT  = COOHD.ORDER-AMOUNT + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY).
        
 /* MESSAGE "COOHD.ORDER-AMOUNT second = " COOHD.ORDER-AMOUNT. */
 
      IF mante-crea THEN /*subscripcion revistas 05/26/2009 */
        THIS-OBJECT:creaMante().
 
    END METHOD. /* END createCooTax() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID getShipNo():
      /*****----------------------------------------------*****/
      /* G E T - S H I P - N O                                */
      /* THIS PROCEDURE SAVES THE SHIP TO DATA INSIDE FILE    */
      /* MESSG                                                */
      /*****----------------------------------------------*****/
      FIND FIRST SHPTO WHERE SHPTO.CUST-NAME    EQ COOHD.SHIP-TO-NAME
                         AND SHPTO.SHIP-NUMBER  EQ tmp-header.SHIP-TO-NO NO-LOCK NO-ERROR. 
                        
      IF tmp-header.SHIP-TO-NAME NE "":U AND tmp-header.SHIP-TO-NO NE "PRIMARY" THEN
      DO:
          
        FIND messg WHERE MESSG.FILE-NAME    EQ MSG-FILE-NAME 
                     AND MESSG.DOC-NUMBER   EQ INVOICE-NUM 
                     AND MESSG.DOC-SEQUENCE EQ 700 EXCLUSIVE-LOCK NO-WAIT NO-ERROR. 
                       
        IF NOT AVAILABLE messg THEN 
          CREATE MESSG.
          
        ASSIGN 
          MESSG.FILE-NAME    = MSG-FILE-NAME
          MESSG.DOC-NUMBER   = INVOICE-NUM
          MESSG.DOC-SEQUENCE = 700
          MESSG.MESSAGE-DESC = IF AVAILABLE shpto THEN SHPTO.CUST-NAME ELSE tmp-header.SHIP-TO-NAME.
            
      END.  /* IF tmp-header.SHIP-TO-NAME <> "" */ 
 
      IF tmp-header.SHIP-ADDR-L1 NE "":U AND tmp-header.SHIP-TO-NO NE "PRIMARY" THEN
      DO:
        FIND MESSG WHERE MESSG.FILE-NAME    EQ MSG-FILE-NAME 
                     AND MESSG.DOC-NUMBER   EQ INVOICE-NUM 
                     AND MESSG.DOC-SEQUENCE EQ 701 EXCLUSIVE-LOCK NO-WAIT NO-ERROR. 
             
        IF NOT AVAILABLE MESSG THEN 
          CREATE MESSG.
            
        ASSIGN 
          MESSG.FILE-NAME    = MSG-FILE-NAME
          MESSG.DOC-NUMBER   = INVOICE-NUM
          MESSG.DOC-SEQUENCE = 701
          MESSG.MESSAGE-DESC = IF AVAILABLE shpto THEN  SHPTO.ADDRESS-L1 ELSE  tmp-header.SHIP-ADDR-L1.
            
      END.  /* IF tmp-header.SHIP-ADDR-L1 <> "" */ 
 
      IF tmp-header.SHIP-ADDR-L2 NE "":U AND tmp-header.SHIP-TO-NO NE "PRIMARY" THEN
      DO:
        FIND MESSG WHERE MESSG.FILE-NAME    EQ MSG-FILE-NAME 
                     AND MESSG.DOC-NUMBER   EQ INVOICE-NUM 
                     AND MESSG.DOC-SEQUENCE EQ 702 EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
             
 
        IF NOT AVAILABLE MESSG THEN 
          CREATE MESSG.
            
        ASSIGN 
          MESSG.FILE-NAME    = MSG-FILE-NAME
          MESSG.DOC-NUMBER   = INVOICE-NUM
          MESSG.DOC-SEQUENCE = 702
          MESSG.MESSAGE-DESC = IF AVAILABLE shpto THEN  SHPTO.ADDRESS-L2 ELSE tmp-header.SHIP-ADDR-L2.
            
      END. /* IF tmp-header.SHIP-ADDR-L2 <> "" */
 
      IF tmp-header.SHIP-ADDR-L3 NE "":U AND tmp-header.SHIP-TO-NO NE "PRIMARY" THEN
      DO:
        FIND messg WHERE MESSG.FILE-NAME    EQ MSG-FILE-NAME 
                     AND MESSG.DOC-NUMBER   EQ INVOICE-NUM 
                     AND MESSG.DOC-SEQUENCE EQ 703 EXCLUSIVE-LOCK NO-WAIT NO-ERROR. 
             
 
        IF NOT AVAILABLE MESSG THEN 
          CREATE MESSG.
          
        ASSIGN 
          MESSG.FILE-NAME    = MSG-FILE-NAME
          MESSG.DOC-NUMBER   = INVOICE-NUM
          MESSG.DOC-SEQUENCE = 703
          MESSG.MESSAGE-DESC = IF AVAILABLE shpto THEN  SHPTO.ADDRESS-L3 else tmp-header.SHIP-ADDR-L3.
           
      END. /* IF tmp-header.SHIP-ADDR-L3 <> "" */ 
        
      /*** HL#119110 - MR PRICE START ***/
      /********************************************************/
      /* SAVE SHIP TO NUMBER IN MESSAGE 704                   */
      /********************************************************/
      IF tmp-header.SHIP-TO-NO NE " ":U AND tmp-header.SHIP-TO-NO NE "PRIMARY" THEN
      DO: 
        FIND messg WHERE MESSG.FILE-NAME    EQ MSG-FILE-NAME 
                     AND MESSG.DOC-NUMBER   EQ INVOICE-NUM 
                     AND MESSG.DOC-SEQUENCE EQ 704 EXCLUSIVE-LOCK NO-WAIT NO-ERROR. 
        
        IF NOT AVAILABLE MESSG THEN 
          CREATE MESSG.
          
        ASSIGN 
          MESSG.FILE-NAME    = MSG-FILE-NAME
          MESSG.DOC-NUMBER   = INVOICE-NUM
          MESSG.DOC-SEQUENCE = 704
          MESSG.MESSAGE-DESC = IF AVAILABLE shpto THEN  SHPTO.SHIP-NUMBER ELSE tmp-header.SHIP-TO-NO.
 
      END.  /* IF tmp-header.SHIP-TO-NO <> 0 */
        
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID ordFollowUp():
      
      /*****----------------------------------------------*****/
      /* O R D - F O L L O W - U P                            */
      /* CREATES FOLLOW UP RECORD FOR ORDER BEING PROCESS     */
      /*****----------------------------------------------*****/
 
      /********************************************************/
      /* CHECK FOLLOW UP PARAM FILE                           */
      /********************************************************/
      FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "CSFOLLO":U 
                     AND PARAMFL.COMPANY-CODE EQ COMPANY NO-LOCK NO-ERROR. 
      
      IF AVAILABLE PARAMFL THEN
      DO:
        /********************************************************/
        /* VERIFY IF ORDER FOLLOW UP RECORD EXITS               */
        /********************************************************/
        FIND WKFILE WHERE WKFILE.PROG-NAME    EQ "CSFOLLO":U 
                      AND WKFILE.TERMINAL-ID  EQ COOHD.CUST-NUMBER 
                                               + COOHD.ORDER-NUMBER 
                                               + STRING(COOHD.ORDER-DATE) NO-LOCK NO-ERROR. 
        
        IF NOT AVAILABLE WKFILE THEN
        DO:
          /********************************************************/
          /* CREATE ORDER FOLLOW UP RECORD                        */
          /********************************************************/
          CREATE WKFILE.
          ASSIGN 
            WKFILE.PROG-NAME    = "CSFOLLO":U
            WKFILE.TERMINAL-ID  = COOHD.CUST-NUMBER 
                                + COOHD.ORDER-NUMBER 
                                + STRING(COOHD.ORDER-DATE)
            WKFILE.CHAR1        = COOHD.CUST-NUMBER
            WKFILE.DATE1        = COOHD.ORDER-DATE
            WKFILE.CHAR2        = COOHD.ORDER-NUMBER
            WKFILE.DATE9        = TODAY
            wkfile.integer4     = TIME .         /* 05/14/2014 wam toledo*/    
            
          /********************************************************/
          /* VERIFY IF SHIP TO NUMBER IS VALID                    */
          /********************************************************/
          FIND FIRST SHPTO WHERE SHPTO.CUST-NAME    EQ COOHD.SHIP-TO-NAME
                             AND SHPTO.SHIP-NUMBER  EQ tmp-header.SHIP-TO-NO NO-LOCK NO-ERROR. 
            
          IF AVAILABLE SHPTO THEN
            ASSIGN WKFILE.CHAR7 = SHPTO.SHIP-NUMBER.
          ELSE
            ASSIGN WKFILE.CHAR7 = " ":U.
 
          IF COOHD.CONFIRM-IND BEGINS "HOLD":U THEN
           ASSIGN WKFILE.INTEGER2 = 1.
          ELSE
           ASSIGN WKFILE.INTEGER2 = 2.
 
          ASSIGN 
            WKFILE.DATE9 = TODAY
            WKFILE.CHAR5 = COOHD.SALES-REP-ID
            WKFILE.CHAR3 = COOHD.SHIP-VIA.
 
          IF NOT COOHD.CONFIRM-IND BEGINS "HOLD":U THEN 
            ASSIGN 
              WKFILE.CHAR8    = "SYSTEM":U
              WKFILE.DATE2    = TODAY
              WKFILE.INTEGER6 = TIME .        /* 05/14/2014 wam toledo */    
                    
 
          /********************************************************/
          /* FIND SHIP VIA CODE                                   */
          /********************************************************/
          FIND FIRST SHPVI WHERE SHPVI.DESCRIPTION EQ COOHD.SHIP-VIA   NO-LOCK NO-ERROR.
          
          IF AVAILABLE SHPVI THEN
            ASSIGN WKFILE.CHAR3 = SHPVI.SHIP-VIA-CD.
 
        END. /* IF NOT AVAILABLE WKFILE */  
 
      END. /* IF AVAILABLE PARAMFL */
 
    END METHOD.
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID tradeIn():
      
      /*****----------------------------------------------*****/
      /* P R OC - T R A D E - I N                             */
      /*****----------------------------------------------*****/
      /*12/04/2012 marcar carf.item-number */
      
      DEF BUFFER BUF-TD-TRADE-IN    FOR TMP-DETAIL.
      DEF BUFFER BUF-TD-CARRO-NUEVO FOR TMP-DETAIL.
 
 
      FIND FIRST BUF-TD-CARRO-NUEVO WHERE BUF-TD-CARRO-NUEVO.TMP-NUMBER  EQ TMP-HEADER.TMP-NUMBER 
                                      AND BUF-TD-CARRO-NUEVO.item-number NE "":U
                                      AND BUF-TD-CARRO-NUEVO.AUTOMOVIL
                                      AND BUF-TD-CARRO-NUEVO.quantity    NE 0
                                      AND BUF-TD-CARRO-NUEVO.item-number NE CARF.TI-ITEM EXCLUSIVE-LOCK NO-ERROR.
          
 
 
      IF AVAILABLE BUF-TD-CARRO-NUEVO THEN 
        ASSIGN CARF.ITEM-NUMBER = BUF-TD-CARRO-NUEVO.item-number. /*CARRO NUEVO SIN TRADE-IN*/
 
    END METHOD. /* END tradeIn() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID layerType():
       
      /*****----------------------------------------------*****/
      /* P R O C - L A Y E R - T Y P E                        */
      /*****----------------------------------------------*****/
 
      IF TRANS-TYPE EQ "12":U THEN 
        ASSIGN COOHD.LAYER-TYPE = "3":U. /*NUEVOS LAYWAY*/
        
      ELSE IF TRANS-TYPE EQ "4":U AND COOHD.LAYER-TYPE EQ "3":U THEN
      DO:
        /*SI SE ESTA CAMBIANDO  UN LAYAWAY NO HACER NADA*/
      END.
      
      ELSE IF TRANS-TYPE EQ "2":U OR TRANS-TYPE EQ "4":U THEN
      DO: /* ORDEN NUEVA O CAMBIO DE ORDEN QUE NO ERA LAYAWAY*/
        FIND FIRST TERMS WHERE TERMS.CUS-TERMS-CD EQ tmp-header.CUS-TERMS-CD NO-LOCK NO-ERROR.                     
        IF AVAILABLE TERMS THEN
        DO:
          IF MB-FIN AND TERMS.SPECIAL-TERM MATCHES "*LOAN*":U THEN 
            ASSIGN COOHD.LAYER-TYPE = "1":U. /*ORDEN FINACIADA POR LOAN*/
          ELSE
          DO:
            IF TERMS.TERMS-DAYS GT 1 THEN 
              ASSIGN COOHD.LAYER-TYPE = "4":U. /* MAYOR DE UN DIA ES THIRD PARTY*/
            ELSE 
              ASSIGN COOHD.LAYER-TYPE = "2":U. /* MENOR DE UN DIA  ES CASH*/
          END.
          
        END. /* IF AVAILABLE TERMS THEN */
        
      END. /* ELSE IF TRANS-TYPE EQ "2":U OR TRANS-TYPE EQ "4":U THEN */
 
    END METHOD. /* END layerType() */
    
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
     ------------------------------------------------------------------------------*/
    METHOD PUBLIC CHARACTER generateOrderNumber(INPUT WHAT-NUMBER AS CHARACTER,
                                                INPUT IN-PARAM    AS CHARACTER):

      /* *********************************************
        1 - INVOICE NUMBER 
        2 - CREDIT  NUMBER
        3 - ORDER   NUMBER
        4 - QUOTE   NUMBER 
        5 - Auto Receiving Number
        6 - Auto Lot Number
        7 - Purchase Order Number
        8 - Customer Number
        9 - Service Call Number
      ********************************************* */ 
    
      DEFINE VARIABLE ORDER-PENDING AS LOGICAL   NO-UNDO.
      DEFINE VARIABLE NUMBER        AS CHARACTER NO-UNDO.
    
      ASSIGN ORDER-PENDING = TRUE.
           
      FIND CMPNY WHERE CMPNY.COMPANY-CODE EQ COMPANY EXCLUSIVE-LOCK NO-WAIT NO-ERROR.

      IF WHAT-NUMBER EQ "3":U THEN
      DO:
      
        DO WHILE ORDER-PENDING:
            
          IF AVAILABLE CMPNY THEN
          DO:
            IF CMPNY.LAST-OE-NO LT 99999 THEN
              ASSIGN CMPNY.LAST-OE-NO = CMPNY.LAST-OE-NO + 1
                     NUMBER           = COMPANY + STRING(CMPNY.LAST-OE-NO,"99999":U).
            ELSE
              ASSIGN CMPNY.LAST-OE-NO = 1
                     NUMBER           = COMPANY + "00001":U.
          END. /*IF AVAILABLE CMPNY THEN*/
           
          FIND FIRST COODT WHERE COODT.ORDER-NUMBER EQ NUMBER
                             AND COODT.ORDER-QTY    NE 0 NO-LOCK NO-ERROR.
          
          ASSIGN ORDER-PENDING = AVAILABLE COODT.
 
        END. /* DO WHILE ORDER-PENDING: */
              
        FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ COMPANY
                       AND PARAMFL.PARAM-ID     EQ "ORDER-PAGE":U
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      
        IF AVAILABLE PARAMFL THEN
        DO:
          FIND WKFILE WHERE WKFILE.PROG-NAME   EQ COMPANY + "-OEORD07":U
                        AND WKFILE.TERMINAL-ID EQ IN-PARAM EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        
          IF AVAILABLE WKFILE THEN
            ASSIGN WKFILE.CHAR2 = NUMBER.
        END.
 
        FOR EACH COOHD WHERE COOHD.ORDER-NUMBER EQ NUMBER EXCLUSIVE-LOCK:
          DELETE COOHD.
        END.
   
        FOR EACH COODT WHERE COODT.ORDER-NUMBER EQ NUMBER EXCLUSIVE-LOCK:
          DELETE COODT.
        END.
   
        FOR EACH COOSZ WHERE COOSZ.ORDER-NUMBER EQ NUMBER EXCLUSIVE-LOCK:
          DELETE COOSZ.
        END.
   
        FOR EACH MESSG WHERE MESSG.DOC-NUMBER   EQ NUMBER
                         AND MESSG.FILE-NAME    EQ "MSGOE":U EXCLUSIVE-LOCK:
          DELETE MESSG.
        END.
        
      END. /* IF WHAT-NUMBER EQ "3":U THEN */
   
      RELEASE CMPNY.
    
      RETURN NUMBER.
    
    END METHOD.
  
  
    /*------------------------------------------------------------------------------
     Purpose: The purpose of this method is to calculate the default 'date wanted' that is assigned to a 
     specific customer with their specific 'ship to', should this last be available; additionally, a 
     predetermined route with its stop and the 'ship via' are also assigned.
     
     Notes: This method was created on 04/23/2024 as a feature for Nunez Bakery by Gamalier Santiago.
     ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID assignDeliveryRoute(INPUT   ipcCompanyCode  AS CHARACTER,
                                           INPUT   ipcCustNumber   AS CHARACTER,
                                           INPUT   ipcShipToNumber AS CHARACTER,
                                           INPUT   ipdOrderDate    AS DATE,                            
                                           OUTPUT opdDateWanted    AS DATE,
                                           OUTPUT opcShipViaCd     AS CHARACTER,
                                           OUTPUT opcRoute         AS CHARACTER,
                                           OUTPUT opcRouteStop     AS CHARACTER ):
                                               
                                           MESSAGE "Adentro ipcCompanyCode " ipcCompanyCode SKIP 
                                           "Adentro ipcCustNumber " ipcCustNumber SKIP 
                                           "Adentro ipcShipToNumber " ipcShipToNumber SKIP 
                                           "Adentro ipdOrderDate " ipdOrderDate
                                           VIEW-AS ALERT-BOX.    
    
    IF ipcShipToNumber = "PRIMARY" THEN
    ASSIGN ipcShipToNumber = "".
                                               
    DEFINE VARIABLE tmp-delivery-days   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE tmp-io-param        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE tmp-date-wanted     AS DATE      NO-UNDO.
    DEFINE VARIABLE selected-route      AS CHAR      NO-UNDO.
    DEFINE VARIABLE selected-route-stop AS CHAR      NO-UNDO.
    DEFINE VARIABLE error-in-assign     AS CHAR      NO-UNDO.                                           
                                       
    // Procedure  fill-in-cust-route-days                                                                                  
    RUN oe-cust-route-days.p
           (INPUT  ipcCompanyCode,                      
            INPUT  ipcCustNumber,                 
            INPUT  ipcShipToNumber,              
            INPUT-OUTPUT tmp-delivery-days,   
            INPUT-OUTPUT tmp-io-param).     

    // Procedure calculate-date-wanted            
    RUN oe-next-wanted.p             
           (INPUT ipdOrderDate,           
            INPUT tmp-delivery-days,      
            INPUT-OUTPUT tmp-date-wanted,  
            INPUT-OUTPUT tmp-io-param).
            
            ASSIGN  opdDateWanted = tmp-date-wanted.   
                                                                                   
    // Procedure assign-route-stop                                                                                   
    RUN oe-find-route.p
           (INPUT   ipcCompanyCode,                      
            INPUT  ipcCustNumber,            
            INPUT  ipcShipToNumber,     
            INPUT  tmp-date-wanted,     
            INPUT-OUTPUT selected-route,        /* route of selected date       */  
            INPUT-OUTPUT selected-route-stop,   /* stop of selected route       */   
            INPUT-OUTPUT error-in-assign,       /* error found while assign route*/
            INPUT-OUTPUT tmp-io-param).         /* send/receive additional info */ 
            
            
    FIND TOWN WHERE TOWN.CODE = selected-route  NO-LOCK NO-ERROR.

         IF AVAILABLE TOWN THEN
         ASSIGN    opcShipViaCd  =  TOWN.ROUTE.
         
         ASSIGN
                opcRoute     = selected-route    
                opcRouteStop = selected-route-stop.
    
    FIND PARAMFL WHERE PARAMFL.PARAM-ID = "OEDSLDE-default-route" 
                   AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
 
    IF AVAILABLE PARAMFL THEN
    DO:
 
    IF opcShipViaCd = "" THEN
     ASSIGN opcShipViaCd = PARAMFL.PARAM-VALUE3.
 
     IF opcRoute     = "" THEN
     ASSIGN opcRoute     = PARAMFL.PARAM-VALUE1.
 
     IF opcRouteStop = "" THEN
     ASSIGN opcRouteStop = PARAMFL.PARAM-VALUE2.
     
     END. //IF AVAILABLE PARAMFL 
     
     MESSAGE "Adentro opdDateWanted " opdDateWanted SKIP 
             "Adentro opcShipViaCd " opcShipViaCd SKIP 
             "Adentro opcRoute " opcRoute SKIP 
             "Adentro opcRouteStop " opcRouteStop
     VIEW-AS ALERT-BOX.
                                                                            
    END METHOD. /* END assignDeliveryRoute */
    
  END CLASS.