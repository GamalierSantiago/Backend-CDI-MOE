/*------------------------------------------------------------------------
    File        : InvoiceHistory
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : JKTECH
    Created     : Wed Mar 07 16:49:35 IST 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS InvoiceHistory: 

    DEFINE PRIVATE TEMP-TABLE ttCustomerInfo NO-UNDO
      FIELD customerNumber LIKE COPAR.CUST-NUMBER
      FIELD customerName   LIKE CCSMS.CUST-NAME
      FIELD orderNumber    LIKE COPAR.CUS-ORDER-NO 
      FIELD description1   LIKE COPAR.Description1
      FIELD orderDate      LIKE COPAR.CUS-INV-DATE
      FIELD custInvoiceAmt LIKE COPAR.CUS-INV-COST
      FIELD collected      LIKE COPAR.CUS-PAYMENT
      FIELD due_on         LIKE COPAR.CUS-INV-DATE
      FIELD item_fr_invoice_nt_foundmsg AS LOGICAL 
      FIELD overdueAmount  LIKE COPAR.GROSS-INVAMT.
      
    DEFINE PRIVATE TEMP-TABLE ttCustInvoice NO-UNDO
      FIELD customerNumber AS CHARACTER
      FIELD invoiceNumber  AS CHARACTER
      FIELD orderNumber    AS CHARACTER
      FIELD invoiceDate    AS DATE
      FIELD invoiceAmount  AS DECIMAL
      FIELD collected      LIKE COPAR.CUS-PAYMENT
      FIELD due_on         LIKE COPAR.CUS-INV-DATE
      FIELD item_fr_invoice_nt_foundmsg AS LOGICAL.   

   DEFINE PUBLIC VARIABLE cToken      AS CHARACTER NO-UNDO.
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
        
    CONSTRUCTOR PUBLIC InvoiceHistory ():
      
/*      DEFINE VARIABLE opcError     AS CHARACTER NO-UNDO.        */
/*      DEFINE VARIABLE opiStatusCode AS INTEGER   NO-UNDO.       */
/*      DEFINE VARIABLE lcInvoiceData AS LONGCHAR NO-UNDO.        */
/*      MESSAGE 'START '                                          */
/*      VIEW-AS ALERT-BOX.                                        */
/*      ETIME(TRUE).                                              */
/*      THIS-OBJECT:getCustomerInvoices(INPUT 'n00075',           */
/*                                      INPUT '1',                */
/*                                      INPUT  1,                 */
/*                                      INPUT 'mobileuser',       */
/*                                      INPUT 0,                  */
/*                                      OUTPUT lcInvoiceData,     */
/*                                      OUTPUT opcError,          */
/*                                      OUTPUT opiStatusCode).    */
/*                                                                */
/*      MESSAGE 'opcError ' opcError                              */
/*      VIEW-AS ALERT-BOX.                                        */
/*      OUTPUT TO 'C:\Users\nm01\Desktop\ModifiedInvoiceHist.txt'.*/
/*      EXPORT lcInvoiceData.                                     */
/*      OUTPUT CLOSE.                                             */
      

      /*DEFINE VARIABLE opcError    AS CHARACTER NO-UNDO.
      DEFINE VARIABLE opiStatusCode AS INTEGER   NO-UNDO.
      DEFINE VARIABLE lcInvoiceData AS LONGCHAR NO-UNDO.


  
      getCustomerOverdueInvoiceItems(INPUT "o**",
                                     INPUT "O03227",
                                     INPUT "o",
                                     INPUT 1,
                                     INPUT 1,
                                     INPUT "mobileuser", 
                                     INPUT 0,
                                     INPUT "0",
                                     OUTPUT lcInvoiceData,
                                     OUTPUT opcError,
                                     OUTPUT opiStatusCode).
      
            MESSAGE 'after constructor opcError ' opcError
            VIEW-AS ALERT-BOX.
            OUTPUT TO 'C:\Users\jkt-1\Desktop\InvoiceItems.txt'.
            EXPORT lcInvoiceData.
            OUTPUT CLOSE.*/
        
    END CONSTRUCTOR.
    
    CONSTRUCTOR PUBLIC InvoiceHistory (INPUT ipcToken AS character):
        cToken = ipcToken.
    END CONSTRUCTOR.

    /*------------------------------------------------------------------------------
     Purpose: This method is used to get the invoice history of a customer and 
              their invoice details along with status of invoices  
     Notes:
    ------------------------------------------------------------------------------*/
    @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
    METHOD PUBLIC VOID getCustomerInvoices(/*INPUT-OUTPUT ipcLastRowID AS CHARACTER,*/
                                           INPUT ipcCustNumber        AS CHARACTER,
                                           INPUT ipcSalesRep          AS CHARACTER,
                                           INPUT ipcLangID            AS CHARACTER,                                            
                                           INPUT ipiWareHouseNo       AS INTEGER,
                                           INPUT cUserType            AS CHARACTER, 
                                           INPUT ipiLastSyncTimestamp AS INT64,
                                           OUTPUT lcInvoiceArr        AS LONGCHAR,
                                           OUTPUT opcError            AS CHARACTER,                                           
                                           OUTPUT opiStatusCode       AS INTEGER):
        
        DEFINE VARIABLE objInvoiceHistory   AS CLASS jsonObject     NO-UNDO.
        DEFINE VARIABLE ObjInvoiceItems     AS CLASS jsonObject     NO-UNDO. 
        DEFINE VARIABLE itemJsonObj         AS CLASS jsonObject     NO-UNDO.
        DEFINE VARIABLE prodInfoJsonObj     AS CLASS jsonObject     NO-UNDO. 
        DEFINE VARIABLE ObjInvoiceArr       AS CLASS jsonArray      NO-UNDO.
        DEFINE VARIABLE itemsArray          AS CLASS jsonArray      NO-UNDO.
        DEFINE VARIABLE objInvoiceStatusArr AS CLASS jsonArray      NO-UNDO.
        DEFINE VARIABLE objCommonSrc        AS CLASS CommonSource   NO-UNDO.
        DEFINE VARIABLE objCustomerOrders   AS CLASS CustomerOrders NO-UNDO.
        
        DEFINE VARIABLE deBalanceDue        AS DECIMAL              NO-UNDO.
        DEFINE VARIABLE iTermDays           AS INTEGER              NO-UNDO.
        DEFINE VARIABLE cCompanyCode        AS CHARACTER            NO-UNDO.
        DEFINE VARIABLE cPriceList          AS CHARACTER            NO-UNDO.        
        DEFINE VARIABLE iarrayIndex         AS INTEGER              NO-UNDO.              
        DEFINE VARIABLE iBatchSize          AS INTEGER              NO-UNDO INIT 50.  /* initial batch size set to 50 records */                
        DEFINE VARIABLE cItemNtFoundMsg     AS CHARACTER            NO-UNDO.
        DEFINE VARIABLE cNotFoundMsg        AS CHARACTER            NO-UNDO.  
        DEFINE VARIABLE cItemFrInvoiceMsg   AS CHARACTER            NO-UNDO.      
        DEFINE VARIABLE iGraceDays          AS INTEGER              NO-UNDO.
        DEFINE VARIABLE dMaxPayDt           AS DATE                 NO-UNDO.
        DEFINE VARIABLE cDiscPerc           AS CHARACTER            NO-UNDO.
        DEFINE VARIABLE cMaxDiscount        AS CHARACTER            NO-UNDO.
        DEFINE VARIABLE iMaxInvoiceDayFetch AS INTEGER              NO-UNDO.
        
        /* DEFINE QUERY lvQuery FOR COPAR SCROLLING. */
        
        ASSIGN
          ObjInvoiceArr       = NEW jsonArray()  
          cCompanyCode        = SUBSTRING(ipcCustNumber,1,1)
          itemJsonObj         = NEW jsonObject()
          objCustomerOrders   = NEW CustomerOrders(INPUT cToken)
          objCommonSrc        = NEW CommonSource(INPUT cToken).              
        
        /* If user type is mobile user then check timestamp for invoice syncing */
        IF cUserType EQ ConstantInitializer:cMobileUser THEN
        DO:
           FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE = cCompanyCode
                                AND PARAMFL.PARAM-ID     = "SALE-HISTORY-DAYS":U
                                AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
           IF AVAILABLE PARAMFL THEN 
             ASSIGN iMaxInvoiceDayFetch = INTEGER(PARAMFL.PARAM-VALUE1).
           ELSE 
             ASSIGN iMaxInvoiceDayFetch = 181.  
          
             
          /*Pagination OPEN QUERY lvQuery FOR EACH COPAR NO-LOCK WHERE COPAR.CUST-NUMBER EQ TRIM(ipcCustNumber) 
                                                      AND COPAR.Timestamp   GT ipiLastSyncTimestamp.
                                                      
          IF TO-ROWID(ipcLastRowID) <> ? THEN
          DO:
            REPOSITION lvQuery TO ROWID TO-ROWID(ipcLastRowID).
            GET NEXT lvQuery.
          END. /* IF TO-ROWID(ipcLastRowID) <> ? */                                               
          
          DO iRecords = 1 TO iBatchSize:  */          
          /* In this query, GE can be changed to GT when sycning will be implemented */            
/*          FOR EACH COPAR NO-LOCK WHERE COPAR.CUST-NUMBER  EQ TRIM(ipcCustNumber)          */
/*                                   AND COPAR.Timestamp    GE ipiLastSyncTimestamp         */
/*                                   AND COPAR.CUS-INV-DATE GE (TODAY - iMaxInvoiceDayFetch)*/
/*                                   AND copar.sales-rep-id EQ ipcSalesRep:                 */
            
            FOR EACH COPAR NO-LOCK WHERE COPAR.CUST-NUMBER  EQ TRIM(ipcCustNumber) 
/*                                   AND COPAR.Timestamp    GE ipiLastSyncTimestamp*/
/*                                   AND copar.sales-rep-id EQ ipcSalesRep*/
                                  /* AND (COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT - COPAR.PAY-DISC-AMT -  
                                        COPAR.OTH-ALLOWANC - COPAR.INV-CR-TOT  + COPAR.INV-DR-TOT <> 0 ) */ :
                                        //OR COPAR.CUS-INV-DATE GT (TODAY - iMaxInvoiceDayFetch)):
                                        
           // IF COPAR.CUS-CHG-NO EQ "":U OR COPAR.DESCRIPTION1 EQ "":U THEN NEXT.  
             IF COPAR.CUS-CHG-NO EQ "":U  THEN NEXT.  
             
             IF copar.sales-rep-id NE ipcSalesRep THEN NEXT.
                                     
            objInvoiceStatusArr = NEW JsonArray().
            itemsArray          = NEW jsonArray ().
            
             IF COPAR.CUS-CHG-NO BEGINS "on/acc" THEN NEXT. 
            
            /* Pagination 
            IF QUERY-OFF-END("lvQuery") THEN
            DO:
            /*objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200NoMoreItemRecords,                                                              
                                       OUTPUT cError,
                                       OUTPUT opiStatusCode).*/
             ASSIGN lQueryOffEnd = TRUE.  
             LEAVE.
            END.
            */
            
            FIND FIRST TERMS NO-LOCK WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-ERROR.
            IF AVAILABLE terms THEN 
            DO:
              ASSIGN 
                iTermDays   = TERMS.TERMS-DAYS
                          
                cDiscPerc    = STRING(TERMS.TERMS-PERCEN / 100) /* DISCOUNT PERCENT */
                cMaxDiscount = STRING(INTEGER(cDiscPerc) * (COPAR.GROSS-INVAMT - COPAR.CUS-DISC-AMT)) NO-ERROR.
            END.
           /* logic to calculate the grace period allowed to customer to pay thr invoices */
           
            FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE EQ cCompanyCode AND PARAMFL.PARAM-ID EQ "OVERRIDE-TERMS":U NO-LOCK NO-ERROR.
            IF AVAILABLE PARAMFL THEN
              ASSIGN iGraceDays = INTEGER (PARAMFL.PARAM-VALUE1) NO-ERROR. 
              
            /*Max date to pay invoice incl. grace days*/
            ASSIGN dMaxPayDt = COPAR.CUS-INV-DATE + iTermDays + iGraceDays. 
            
            ASSIGN deBalanceDue = COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT - COPAR.PAY-DISC-AMT -  
                                  COPAR.OTH-ALLOWANC - COPAR.INV-CR-TOT  + COPAR.INV-DR-TOT.
            
           // IF deBalanceDue EQ 0 AND COPAR.CUS-INV-DATE LT (TODAY - iMaxInvoiceDayFetch) THEN NEXT.
                                  
            FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
            IF AVAIL CCSMS THEN
            DO:    
              FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
              IF AVAILABLE SHPTO THEN
                ASSIGN cPriceList = SHPTO.PRICE-LIST.
              ELSE
                ASSIGN cPriceList = CCSMS.PRICE-LIST.
            END. /* IF AVAIL CCSMS THEN */
              
            ASSIGN 
              objInvoiceHistory = NEW JsonObject().                                   
              
                                                          
            
            objInvoiceHistory:ADD(INPUT "invoice_number":U, INPUT COPAR.CUS-CHG-NO).    /* Add invoice number key */
            
            IF COPAR.DESCRIPTION1 NE "" THEN 
            objInvoiceHistory:ADD(INPUT "order_number":U,   INPUT COPAR.DESCRIPTION1). /* Add order_number key   */
            ELSE 
            objInvoiceHistory:ADD(INPUT "order_number":U,   INPUT "NA").
            
            IF COPAR.cus-inv-date EQ ? THEN
              objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT "NA").
            ELSE
              objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT COPAR.CUS-INV-DATE + iTermDays).
                                                                  
            IF COPAR.CUS-INV-DATE EQ ? THEN
              objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT ""). 
            ELSE
              objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT COPAR.CUS-INV-DATE).
              
            objInvoiceHistory:ADD(INPUT "total":U,          INPUT COPAR.CUS-INV-NET).
            objInvoiceHistory:ADD(INPUT "collected":U,      INPUT COPAR.CUS-PAYMENT).
            /*objInvoiceHistory:ADD(INPUT "outstanding":U,  INPUT (COPAR.CUS-INV-NET - COPAR.CUS-PAYMENT)).*/
            objInvoiceHistory:ADD(INPUT "outstanding":U,    INPUT deBalanceDue).
            objInvoiceHistory:ADD(INPUT "city_tax":U,       INPUT 0).
            objInvoiceHistory:ADD(INPUT "state_tax":U,      INPUT 0).
            /* set the value conditionally This will just create the object once 
               and then SET will just update that object 
            */
            objInvoiceHistory:ADD(INPUT "status":U,         INPUT "").
            objInvoiceHistory:ADD(INPUT "grace_days":U,          INPUT iGraceDays).
            objInvoiceHistory:ADD(INPUT "discount_percentage":U, INPUT cDiscPerc).
            objInvoiceHistory:ADD(INPUT "max_discount":U,        INPUT cMaxDiscount).
            objInvoiceHistory:ADD(INPUT "max_pay_date":U,        INPUT dMaxPayDt).  
             
            
             
            FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1 NO-LOCK NO-ERROR.
            IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
            DO:
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200ItemForInvoice,                                                              
                                       OUTPUT cItemFrInvoiceMsg,
                                       OUTPUT opiStatusCode).
              
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200NotFound,                                                              
                                       OUTPUT cNotFoundMsg,
                                       OUTPUT opiStatusCode).
                                      
              cItemNtFoundMsg =  cItemFrInvoiceMsg + " " + COPAR.CUS-CHG-NO + " " +  cNotFoundMsg.
                                                                                                                                                 
              /* This message will be displayed when no such record exists in COOHD and COODT */ 
              objInvoiceHistory:ADD(INPUT "item_fr_invoice_nt_foundmsg":U, INPUT cItemNtFoundMsg).
            
            END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT).. */
            
            /* For PARTIAL status */
            IF COPAR.CUS-PAYMENT LT COPAR.CUS-INV-NET THEN
            DO:
              (IF objInvoiceHistory:Has("status")   THEN              
              objInvoiceHistory:SET(INPUT "status":U, INPUT 4) ELSE ?).
            END.
            
            /* For PENDING_PAYMENT status */
            IF COPAR.CUS-PAYMENT EQ 0.0 THEN
            DO: 
              (IF objInvoiceHistory:Has("status")   THEN            
                 objInvoiceHistory:SET(INPUT "status",INPUT 3) ELSE ?).
            END.
            
              
            /* For OVERDUE status */
            /* Invoices which are overdue are pending as well */
            IF TODAY GT (COPAR.cus-inv-date + iTermDays) THEN
            DO:  
                     
              (IF objInvoiceHistory:Has("status")   THEN  
                objInvoiceHistory:SET(INPUT "status",INPUT 2) ELSE ?).
            END.       
            
            /* For PAID status */
            IF deBalanceDue EQ 0.0 THEN 
            DO:   
                
              (IF objInvoiceHistory:Has("status")   THEN         
                objInvoiceHistory:SET(INPUT "status",INPUT 1) ELSE ?).  
            END.                           
                                   
            FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1 NO-LOCK NO-ERROR.
            IF AVAILABLE COOHD THEN 
            DO:
              objInvoiceHistory:ADD(INPUT "shipping_handling":U, INPUT COOHD.FREIGHT-AMT).
              
              IF COOHD.DATE-WANTED EQ ? THEN
                objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT "").
              ELSE
                objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT COOHD.DATE-WANTED). 
                
            END.
            
          /*  FOR EACH CSAHF WHERE CSAHF.INVOICE-NO       EQ COPAR.CUS-CHG-NO 
                             AND CSAHF.ITEM-NUMBER      BEGINS cCompanyCode                                               
                             AND CSAHF.CUST-NUMBER      EQ COPAR.CUST-NUMBER
                             AND CSAHF.INVOICE-DATE     EQ COPAR.CUS-INV-DATE NO-LOCK: */
                             
            FOR EACH CSAHF WHERE CSAHF.INVOICE-NO       EQ COPAR.CUS-CHG-NO NO-LOCK: 
                IF NOT (CSAHF.ITEM-NUMBER      BEGINS cCompanyCode                                               
                        AND CSAHF.CUST-NUMBER      EQ COPAR.CUST-NUMBER
                        AND CSAHF.INVOICE-DATE     EQ COPAR.CUS-INV-DATE) THEN LEAVE.
                        
             IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*CITY-TAX*":U) THEN
             DO:
               objInvoiceHistory:SET(INPUT "city_tax":U, INPUT CSAHF.PRICE-EXT).
               NEXT. 
             END.
             
             IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*STATE-TAX*":U) THEN
             DO:
               objInvoiceHistory:SET(INPUT "state_tax":U, INPUT CSAHF.PRICE-EXT).
               NEXT. 
             END.
             IF CSAHF.ITEM-NUMBER  BEGINS cCompanyCode + "*":U THEN NEXT.
             ASSIGN 
               itemJsonObj     = NEW jsonObject() 
               prodInfoJsonObj = NEW jsonObject().            
             
             objCustomerOrders:getOrderedItem(INPUT CSAHF.ORDER-NUMBER,
                                              INPUT CSAHF.ITEM-NUMBER ,
                                              INPUT CSAHF.INVOICE-SEQ,
                                              INPUT CSAHF.DESCRIPTION,
                                              INPUT CSAHF.QTY-SHIPPED,
                                              INPUT "NOTAPPLICABLE", 
                                              INPUT cPriceList,
                                              INPUT CCSMS.CUST-NUMBER,
                                              INPUT cCompanyCode,
                                              INPUT ipiWarehouseNo,
                                              INPUT "",
                                              INPUT CCSMS.DISC-PERC,
                                              INPUT CCSMS.CONTRACT-IND,
                                              INPUT CCSMS.SPEC-DICT-I,
                                              INPUT CCSMS.QTY-BRK-CD,
                                              INPUT CCSMS.CUST-TYPE,
                                              OUTPUT itemJsonObj). 
             
             itemsArray:ADD(INPUT itemJsonObj).
             
             /* Remove item_tax_unit array from product_info object */                                           
             DO iarrayIndex = 1 TO itemsArray:LENGTH:
              
               ASSIGN itemJsonObj = itemsArray:GetJsonObject(INPUT iarrayIndex).
               
               IF itemJsonObj:has(INPUT "product_info") THEN 
               DO:
                 ASSIGN prodInfoJsonObj = itemJsonObj:GetJsonObject("product_info").
               END.
              
               IF prodInfoJsonObj:has("item_tax_unit") THEN
               DO:                
                 prodInfoJsonObj:Remove(INPUT "item_tax_unit":U).
               END.                                          
                                       
             END. /* DO iarrayIndex = 1 TO itemJsonArray:LENGTH */ 
                                                   
            END. /* FOR EACH CSAHF   */
                        
            objInvoiceHistory:ADD(INPUT "invoice_items", INPUT itemsArray).
            
            ObjInvoiceArr:ADD(INPUT objInvoiceHistory).           
            ASSIGN lcInvoiceArr = ObjInvoiceArr:getJsonText().
                   /* Pagination ipcLastRowID = STRING(ROWID(copar)).*/
          
          END. /* FOR EACH COPAR */
          
          /*END. /* DO iRecords = 1 TO iBatchSize: */*/
        END. /* IF - cUserType EQ "MobileUser" */
        
        /* Code for web user: Did not code for discount logic as in mobile case for web case */
        ELSE 
        DO: 
          /* Pagination       
          OPEN QUERY lvQuery FOR EACH COPAR NO-LOCK WHERE COPAR.CUST-NUMBER EQ TRIM(ipcCustNumber).
          
           IF TO-ROWID(ipcLastRowID) <> ? THEN
            DO:
              REPOSITION lvQuery TO ROWID TO-ROWID(ipcLastRowID).
              GET NEXT lvQuery.
            END. /* IF TO-ROWID(ipcLastRowID) <> ? */                                               
          
          DO iRecords = 1 TO iBatchSize:     
          */       
          
          FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE = cCompanyCode
                                AND PARAMFL.PARAM-ID     = "SALE-HISTORY-DAYS":U
                                AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
           IF AVAILABLE PARAMFL THEN 
             ASSIGN iMaxInvoiceDayFetch = INTEGER(PARAMFL.PARAM-VALUE1).
           ELSE 
             ASSIGN iMaxInvoiceDayFetch = 181.  
           MESSAGE "SALE-HISTORY-DAYS"  iMaxInvoiceDayFetch.
             
/*          FOR EACH COPAR NO-LOCK WHERE COPAR.CUST-NUMBER EQ TRIM(ipcCustNumber):*/
          FOR EACH COPAR NO-LOCK WHERE COPAR.CUST-NUMBER  EQ TRIM(ipcCustNumber) 
                                   AND COPAR.Timestamp    GE ipiLastSyncTimestamp
/*                                   AND copar.sales-rep-id EQ ipcSalesRep*/
                                /*   AND (COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT - COPAR.PAY-DISC-AMT -  
                                        COPAR.OTH-ALLOWANC - COPAR.INV-CR-TOT  + COPAR.INV-DR-TOT <> 0 OR 
                                        COPAR.CUS-INV-DATE GT (TODAY - iMaxInvoiceDayFetch)) */:    
            
            // IF COPAR.CUS-CHG-NO EQ "":U OR COPAR.DESCRIPTION1 EQ "":U THEN NEXT.
            
             IF COPAR.CUS-CHG-NO EQ "":U THEN NEXT. 
            
            objInvoiceStatusArr = NEW JsonArray().
            itemsArray          = NEW jsonArray ().
            
            IF COPAR.CUS-CHG-NO BEGINS "on/acc" THEN NEXT. 
            
            /*IF QUERY-OFF-END("lvQuery") THEN
            DO:
            objCommonSrc:getMessages(INPUT  ipcLangID,
                                     INPUT  ConstantInitializer:c200NoMoreItemRecords,                                                              
                                     OUTPUT cError,
                                     OUTPUT opiStatusCode).
             ASSIGN lQueryOffEnd = TRUE.  
             LEAVE.
            END.*/
            
            FIND FIRST terms NO-LOCK WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-ERROR.
            IF AVAILABLE terms THEN 
              ASSIGN iTermDays = TERMS.TERMS-DAYS.
            
            FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
            IF AVAIL CCSMS THEN
            DO:    
              FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
              IF AVAILABLE SHPTO THEN
                ASSIGN cPriceList = SHPTO.PRICE-LIST.
              ELSE
                ASSIGN cPriceList = CCSMS.PRICE-LIST.
            END. /* IF AVAIL CCSMS THEN */
            
            ASSIGN 
              objInvoiceHistory  = NEW JsonObject().                                   
              
            ASSIGN deBalanceDue = COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT - COPAR.PAY-DISC-AMT -  
                                  COPAR.OTH-ALLOWANC - COPAR.INV-CR-TOT  + COPAR.INV-DR-TOT.
            
            objInvoiceHistory:ADD(INPUT "invoice_number":U, INPUT COPAR.CUS-CHG-NO).    /* add invoice number key */
            
            IF COPAR.DESCRIPTION1 NE "" THEN 
              objInvoiceHistory:ADD(INPUT "order_number":U,   INPUT COPAR.DESCRIPTION1). /* add order_number key   */
            ELSE 
              objInvoiceHistory:ADD(INPUT "order_number":U,   INPUT "NA").
            
            IF COPAR.cus-inv-date EQ ? THEN
              objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT "NA").
            ELSE
              objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT COPAR.CUS-INV-DATE + iTermDays).
                                                                  
            IF COPAR.CUS-INV-DATE EQ ? THEN
              objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT ""). 
            ELSE
              objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT COPAR.CUS-INV-DATE).
              
            objInvoiceHistory:ADD(INPUT "total":U,          INPUT COPAR.CUS-INV-NET).
            objInvoiceHistory:ADD(INPUT "collected":U,      INPUT COPAR.CUS-PAYMENT).
            /*objInvoiceHistory:ADD(INPUT "outstanding":U,  INPUT (COPAR.CUS-INV-NET - COPAR.CUS-PAYMENT)).*/
            objInvoiceHistory:ADD(INPUT "outstanding":U,    INPUT deBalanceDue).
            objInvoiceHistory:ADD(INPUT "city_tax":U,       INPUT 0).
            objInvoiceHistory:ADD(INPUT "state_tax":U,      INPUT 0).
            objInvoiceHistory:ADD(INPUT "status":U,         INPUT ""). /* set the value conditionally */
            
            FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
            IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
            DO:            
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200ItemForInvoice,                                                              
                                       OUTPUT cItemFrInvoiceMsg,
                                       OUTPUT opiStatusCode).
              
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200NotFound,                                                              
                                       OUTPUT cNotFoundMsg,
                                       OUTPUT opiStatusCode). 
                                       
              cItemNtFoundMsg =  cItemFrInvoiceMsg + " " + COPAR.CUS-CHG-NO + " " +  cNotFoundMsg.
                                                                                                                                  
              /* ITEMS FOR INVOICE copar.CUS-CHS-NO NOT FOUND */
              objInvoiceHistory:ADD(INPUT "item_fr_invoice_nt_foundmsg":U, INPUT cItemNtFoundMsg).
            END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT).. */
            
            /* For PARTIAL status */
            IF COPAR.CUS-PAYMENT LT COPAR.CUS-INV-NET THEN
            DO:
              (IF objInvoiceHistory:Has("status")   THEN              
              objInvoiceHistory:SET(INPUT "status":U, INPUT 4) ELSE ?).
            END.
            
            /* For PENDING_PAYMENT status */
            IF COPAR.CUS-PAYMENT EQ 0.0 THEN
            DO:
              (IF objInvoiceHistory:Has("status")   THEN               
              objInvoiceHistory:SET(INPUT "status",INPUT 3) ELSE ?).
            END.
              
            /* For OVERDUE status */
            IF TODAY GT (COPAR.cus-inv-date + iTermDays) THEN
            DO:             
              (IF objInvoiceHistory:Has("status")   THEN  
              objInvoiceHistory:SET(INPUT "status",INPUT 2) ELSE ?).
            END.       
            
            /* For PAID status */
            IF deBalanceDue EQ 0.0 THEN 
            DO:             
              (IF objInvoiceHistory:Has("status")   THEN
              objInvoiceHistory:SET(INPUT "status",INPUT 1) ELSE ?).  
            END.    
            
            /*IF lOverdue AND lPartialPay AND lPending THEN 
              objInvoiceHistory:SET(INPUT "status",INPUT "2":U).*/
              
            /*IF lPaid THEN
              objInvoiceHistory:SET(INPUT "status",INPUT "1":U).
              
            IF lOverdue AND lPartialPay AND lPending THEN 
              objInvoiceHistory:SET(INPUT "status",INPUT "1":U).*/
                                    
            FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1 NO-LOCK NO-ERROR.
            IF AVAILABLE COOHD THEN 
            DO:
              objInvoiceHistory:ADD(INPUT "shipping_handling":U, INPUT COOHD.FREIGHT-AMT).
              
              IF COOHD.DATE-WANTED EQ ? THEN
                objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT "").
              ELSE
                objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT COOHD.DATE-WANTED). 
                
            END.
            
            FOR EACH CSAHF WHERE CSAHF.INVOICE-NO       EQ COPAR.CUS-CHG-NO
                             AND CSAHF.ITEM-NUMBER      BEGINS cCompanyCode                                               
                             AND NOT CSAHF.ITEM-NUMBER  BEGINS cCompanyCode + "*":U NO-LOCK:
  
             IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*CITY-TAX*":U) THEN
             DO:
               objInvoiceHistory:SET(INPUT "city_tax":U, INPUT CSAHF.PRICE-EXT).
               NEXT. 
             END.
             
             IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*STATE-TAX*":U) THEN
             DO:
               objInvoiceHistory:SET(INPUT "state_tax":U, INPUT CSAHF.PRICE-EXT).
               NEXT. 
             END.
             
             ASSIGN 
               itemJsonObj     = NEW jsonObject() 
               prodInfoJsonObj = NEW jsonObject().            
             
             objCustomerOrders:getOrderedItem(INPUT CSAHF.ORDER-NUMBER,
                                              INPUT CSAHF.ITEM-NUMBER ,
                                              INPUT CSAHF.INVOICE-SEQ,
                                              INPUT CSAHF.DESCRIPTION,
                                              INPUT CSAHF.QTY-SHIPPED,
                                              INPUT "NOTAPPLICABLE", 
                                              INPUT cPriceList,
                                              INPUT CCSMS.CUST-NUMBER,
                                              INPUT cCompanyCode,
                                              INPUT ipiWarehouseNo,
                                              INPUT "",
                                              INPUT CCSMS.DISC-PERC,
                                              INPUT CCSMS.CONTRACT-IND,
                                              INPUT CCSMS.SPEC-DICT-I,
                                              INPUT CCSMS.QTY-BRK-CD,
                                              INPUT CCSMS.CUST-TYPE,
                                              OUTPUT itemJsonObj).
             itemsArray:ADD(INPUT itemJsonObj).
             
             /* remove item_tax_unit array from product_info object*/                                           
             DO iarrayIndex = 1 TO itemsArray:LENGTH:
              
               ASSIGN itemJsonObj = itemsArray:GetJsonObject(INPUT iarrayIndex).
               
               IF itemJsonObj:has(INPUT "product_info") THEN 
               DO:
                 ASSIGN prodInfoJsonObj = itemJsonObj:GetJsonObject("product_info").
               END.
              
               IF prodInfoJsonObj:has("item_tax_unit") THEN
               DO:                
                 prodInfoJsonObj:Remove(INPUT "item_tax_unit":U).
               END.                                          
                                       
             END. /* DO iarrayIndex = 1 TO itemJsonArray:LENGTH */ 
                                                   
            END. /* FOR EACH CSAHF   */
                        
            objInvoiceHistory:ADD(INPUT "invoice_items", INPUT itemsArray).
            
            ObjInvoiceArr:ADD(INPUT objInvoiceHistory).           
            ASSIGN lcInvoiceArr = ObjInvoiceArr:getJsonText().
                   /* Pagination ipcLastRowID = STRING(ROWID(copar)).*/
                    
          /* commented END */ 
          END. /* FOR EACH COPAR */
          /* Pagination END. /* DO iRecords = 1 TO iBatchSize: */*/
        END. /* ELSE - cUserType EQ "MobileUser" */
               
        RETURN.

    END METHOD.
    
  /*----------------------------------------------------------------------------------------
   Purpose: This API returns the items of invoices of customer overdue on salesman dashboard
            and amount invoiced on customer dashboard
   Input Paramters:   1.ipcUserName    - Username (for mobile)
                      2.ipcCustNum     - Customer number 
                      3.ipcCompanyID   - Logged In company ID 
                      4.ipiWarehouseNo - Warehouse number 
                      5.cUserType      - User type 
                      6.ipiLastSyncTimestamp - Last sync timestamp 
                      7.ipcLangID            - Selected language ID
                      8.iType                - decides the API logic to be executed,
                        iType = 2            - overdue invoices logic (salesman dashboard)  
                        otherthan 2          - amount invoiced invoices (customer dashboard) 
                    
   Output Parameters: 1.lcInvoiceArr  - returned invoiced data in array 
                      2.opcError      - Error message (if any)
                      3.opiStatusCode - HTTP Status code                       
   Notes:
  ------------------------------------------------------------------------------------------*/

    METHOD PUBLIC VOID getCustomerOverdueInvoiceItems(INPUT ipcUserName          AS CHARACTER,
                                                      INPUT ipcCustNum           AS CHARACTER,
                                                      INPUT ipcCompanyID         AS CHARACTER,
                                                      INPUT iType                AS INTEGER,
                                                      INPUT ipiWareHouseNo       AS INTEGER,
                                                      INPUT cUserType            AS CHARACTER, 
                                                      INPUT ipiLastSyncTimestamp AS INT64,
                                                      INPUT ipcLangId            AS CHARACTER,
                                                      OUTPUT lcInvoiceArr        AS LONGCHAR,
                                                      OUTPUT opcError            AS CHARACTER,
                                                      OUTPUT opiStatusCode       AS INTEGER):
      
      DEFINE VARIABLE objSalesman         AS CLASS SalesmanInfo   NO-UNDO.
      DEFINE VARIABLE objInvoiceHistory   AS CLASS jsonObject     NO-UNDO.
      DEFINE VARIABLE ObjInvoiceItems     AS CLASS jsonObject     NO-UNDO. 
      DEFINE VARIABLE itemJsonObj         AS CLASS jsonObject     NO-UNDO.
      DEFINE VARIABLE prodInfoJsonObj     AS CLASS jsonObject     NO-UNDO. 
      DEFINE VARIABLE ObjInvoiceArr       AS CLASS jsonArray      NO-UNDO.
      DEFINE VARIABLE itemsArray          AS CLASS jsonArray      NO-UNDO.
      DEFINE VARIABLE objInvoiceStatusArr AS CLASS jsonArray      NO-UNDO.
      DEFINE VARIABLE objCommonSrc        AS CLASS CommonSource   NO-UNDO.
      DEFINE VARIABLE objCustomerOrders   AS CLASS CustomerOrders NO-UNDO.
      DEFINE VARIABLE objSalesmanCustData AS CLASS salesmanCustomersData NO-UNDO.
      
      DEFINE VARIABLE lRegularSlsman      AS LOGICAL              NO-UNDO.
      DEFINE VARIABLE deTotalOverdueAmt   AS DECIMAL              NO-UNDO.
      DEFINE VARIABLE iOverdueCustCount   AS INTEGER              NO-UNDO.
      DEFINE VARIABLE cError              AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cCompanyCode        AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE iTermDays           AS INTEGER              NO-UNDO.
      DEFINE VARIABLE cPriceList          AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cCustNum            AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cSpecDict           AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE deDiscPerc          AS DECIMAL              NO-UNDO.
      DEFINE VARIABLE cQtyBrkCd           AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cSpecDictI          AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cContractInd        AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cCustType           AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cCustName           AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE deBalanceDue        AS DECIMAL              NO-UNDO.
      DEFINE VARIABLE cItemFrInvoiceMsg   AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cItemNtFoundMsg     AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cNotFoundMsg        AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE iarrayIndex         AS INTEGER              NO-UNDO.
      DEFINE VARIABLE deAvailCredit       AS DECIMAL              NO-UNDO.
      DEFINE VARIABLE iCreditLim          AS INTEGER              NO-UNDO.
      DEFINE VARIABLE deCustAmtInvoiced   AS DECIMAL              NO-UNDO.
      DEFINE VARIABLE iTotalInvoices      AS INTEGER              NO-UNDO.
      DEFINE VARIABLE iGraceDays          AS INTEGER              NO-UNDO.
      DEFINE VARIABLE dMaxPayDt           AS DATE                 NO-UNDO.
      DEFINE VARIABLE cDiscPerc           AS CHARACTER            NO-UNDO.
      DEFINE VARIABLE cMaxDiscount        AS CHARACTER            NO-UNDO.
        
      
      ASSIGN
        ObjInvoiceArr       = NEW jsonArray()            
        itemJsonObj         = NEW jsonObject()
        objCustomerOrders   = NEW CustomerOrders(INPUT cToken)
        objCommonSrc        = NEW CommonSource(INPUT cToken)
        objSalesmanCustData = NEW SalesmanCustomersData(INPUT cToken)
        cCompanyCode        = ipcCompanyID
        lcInvoiceArr        = "[]".            
      
      ASSIGN 
        objSalesman  = NEW SalesmanInfo(INPUT cToken). 
      
      FIND FIRST csams WHERE CSAMS.SALES-REP-ID EQ ipcUserName NO-LOCK NO-ERROR.
      IF AVAILABLE csams THEN 
      DO:
        ASSIGN lRegularSlsman = csams.laptop.
      END. /* IF AVAILABLE csams THEN */
      //MESSAGE "iType:" iType.
      
      /* Data for Customers overdue on slsmn dashboard (ipcCustNum = "a")/Amount overdue(ipcCustNum = "cust-num" cust dashboard)
         for salesaman dashboard */ 
      IF iType EQ 2 THEN 
      DO:
         /* Get data of overdue invoices in temp-table */
        // MESSAGE "getSalesmanCustomersOverdue-11".
        objSalesman:getSalesmanCustomersOverdue(INPUT  ipcUserName,
                                                INPUT  ipcCompanyID,
                                                INPUT  lRegularSlsman,
                                                OUTPUT TABLE ttCustomerInfo, 
                                                OUTPUT deTotalOverdueAmt,
                                                OUTPUT iOverdueCustCount,
                                                OUTPUT cError,
                                                OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
          
        FOR EACH ttCustomerInfo WHERE IF ipcCustNum NE "A":U THEN 
                                         ttCustomerInfo.customerNumber EQ ipcCustNum 
                                      ELSE TRUE:
            
          FIND FIRST COPAR WHERE COPAR.CUST-NUMBER EQ ttCustomerInfo.customerNumber 
                             AND COPAR.CUS-CHG-NO  EQ ttCustomerInfo.description1 NO-LOCK NO-ERROR.
          IF AVAILABLE COPAR THEN 
          DO:
            IF COPAR.CUS-CHG-NO EQ "":U OR COPAR.DESCRIPTION1 EQ "":U THEN NEXT. 
                                       
            objInvoiceStatusArr = NEW jsonArray().
            itemsArray          = NEW jsonArray().
            
            IF COPAR.CUS-CHG-NO BEGINS "on/acc" THEN NEXT. 
            
            FIND FIRST terms NO-LOCK WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-ERROR.
            IF AVAILABLE terms THEN 
              ASSIGN 
                iTermDays    = TERMS.TERMS-DAYS
                cDiscPerc    = STRING(TERMS.TERMS-PERCEN / 100) /* DISCOUNT PERCENT */
                cMaxDiscount = STRING(INTEGER(cDiscPerc) * (COPAR.GROSS-INVAMT - COPAR.CUS-DISC-AMT)).
            
           /* logic to calculate the grace period allowed to customer to pay thr invoices */
           
            FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE EQ cCompanyCode AND PARAMFL.PARAM-ID EQ "OVERRIDE-TERMS":U NO-LOCK NO-ERROR.
            IF AVAILABLE PARAMFL THEN
               ASSIGN iGraceDays = INTEGER (PARAMFL.PARAM-VALUE1) NO-ERROR. 
              
            /*Max date to pay invoice incl. grace days*/
            ASSIGN dMaxPayDt = COPAR.CUS-INV-DATE + iTermDays + iGraceDays. 
            
           
            
            FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ COPAR.CUST-NUMBER NO-LOCK NO-ERROR.
            IF AVAIL CCSMS THEN
            DO:
               
              FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
              IF AVAILABLE SHPTO THEN
                ASSIGN cPriceList = SHPTO.PRICE-LIST.
              ELSE
                ASSIGN cPriceList = CCSMS.PRICE-LIST.
                
              ASSIGN 
                cCustNum       = CCSMS.CUST-NUMBER
                cSpecDict      = ccsms.spec-dict-i
                deDiscPerc     = ccsms.disc-perc
                cQtyBrkCd      = ccsms.qty-brk-cd
                cSpecDictI     = CCSMS.SPEC-DICT-I                      
                cContractInd   = CCSMS.CONTRACT-IND
                cCustType      = CCSMS.CUST-TYPE
                cCustName      = REPLACE(CCSMS.CUST-NAME,"'", "")  //ccsms.cust-name
                iCreditLim     = CCSMS.CREDIT-LIMIT.
                
                objSalesmanCustData:getAvailableCredit(INPUT  cCustNum,
                                                       OUTPUT deAvailCredit, 
                                                       OUTPUT cError).    
            END. /* IF AVAIL CCSMS THEN */
              
            ASSIGN objInvoiceHistory = NEW JsonObject().                                   
              
            ASSIGN deBalanceDue = COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT - COPAR.PAY-DISC-AMT -  
                                  COPAR.OTH-ALLOWANC - COPAR.INV-CR-TOT  + COPAR.INV-DR-TOT.
            
            objInvoiceHistory:ADD(INPUT "invoice_number":U,  INPUT COPAR.CUS-CHG-NO).    /* add invoice number key */
            IF COPAR.DESCRIPTION1 NE "" THEN 
              objInvoiceHistory:ADD(INPUT "order_number":U,    INPUT COPAR.DESCRIPTION1). /* add order_number key   */
            ELSE 
              objInvoiceHistory:ADD(INPUT "order_number":U,    INPUT "NA"). /* add order_number key   */
            
            objInvoiceHistory:ADD(INPUT "customer_number":U, INPUT COPAR.CUST-NUMBER).
            objInvoiceHistory:ADD(INPUT "customer_name":U,   INPUT cCustName).
            objInvoiceHistory:ADD(INPUT "customer_type":U,   INPUT cCustType).
            objInvoiceHistory:ADD(INPUT "available_credit":U,INPUT deAvailCredit).
            objInvoiceHistory:ADD(INPUT "credit_limit":U,    INPUT iCreditLim).
            
            IF COPAR.CUS-INV-DATE EQ ? THEN
              objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT "NA").
            ELSE
              objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT COPAR.CUS-INV-DATE + iTermDays).
                                                                  
            IF COPAR.CUS-INV-DATE EQ ? THEN
              objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT ""). 
            ELSE
              objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT COPAR.CUS-INV-DATE).
              
            objInvoiceHistory:ADD(INPUT "total":U,          INPUT COPAR.CUS-INV-NET).
            objInvoiceHistory:ADD(INPUT "collected":U,      INPUT COPAR.CUS-PAYMENT).
            /*objInvoiceHistory:ADD(INPUT "outstanding":U,  INPUT (COPAR.CUS-INV-NET - COPAR.CUS-PAYMENT)).*/
            objInvoiceHistory:ADD(INPUT "outstanding":U,    INPUT deBalanceDue).
            objInvoiceHistory:ADD(INPUT "city_tax":U,       INPUT 0).
            objInvoiceHistory:ADD(INPUT "state_tax":U,      INPUT 0).
            objInvoiceHistory:ADD(INPUT "status":U,         INPUT ""). 
            objInvoiceHistory:ADD(INPUT "grace_days":U,          INPUT iGraceDays).
            objInvoiceHistory:ADD(INPUT "discount_percentage":U, INPUT cDiscPerc).
            objInvoiceHistory:ADD(INPUT "max_discount":U,        INPUT cMaxDiscount).
            objInvoiceHistory:ADD(INPUT "max_pay_date":U,        INPUT dMaxPayDt).  
             
             
            /* Set the value conditionally This will just create the object once 
               and then SET will just update that object 
            */
            
            FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
            IF NOT AVAIL COOHD AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
            DO:
            
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200ItemForInvoice,                                                              
                                       OUTPUT cItemFrInvoiceMsg,
                                       OUTPUT opiStatusCode).
              
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200NotFound,                                                              
                                       OUTPUT cNotFoundMsg,
                                       OUTPUT opiStatusCode).
                                      
              cItemNtFoundMsg =  cItemFrInvoiceMsg + " " + COPAR.CUS-CHG-NO + " " +  cNotFoundMsg.
                                                                                                                                                 
              /* This message will be displayed when no such record exists in COOHD and COODT */ 
              objInvoiceHistory:ADD(INPUT "item_fr_invoice_nt_foundmsg":U, INPUT cItemNtFoundMsg).
            
            END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT..) */
            
            /* For PARTIAL status */
            IF COPAR.CUS-PAYMENT LT COPAR.CUS-INV-NET THEN
            DO:            
              objInvoiceHistory:SET(INPUT "status":U, INPUT 4).
            END.
            
            /* For PENDING_PAYMENT status */
            IF COPAR.CUS-PAYMENT EQ 0.0 THEN
            DO:             
              objInvoiceHistory:SET(INPUT "status",INPUT 3).
            END.
              
            /* For OVERDUE status */
            /* Invoices which are overdue, will be treated as pending also */
            IF TODAY GT (COPAR.cus-inv-date + iTermDays) THEN
            DO:             
              objInvoiceHistory:SET(INPUT "status",INPUT 2).
            END.       
            
            /* For PAID status */
            IF deBalanceDue EQ 0.0 THEN 
            DO:             
              objInvoiceHistory:SET(INPUT "status",INPUT 1).  
            END.                           
                                    
            FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1 NO-LOCK NO-ERROR.
            IF AVAILABLE COOHD THEN 
            DO:
              objInvoiceHistory:ADD(INPUT "shipping_handling":U, INPUT COOHD.FREIGHT-AMT).
              
              IF COOHD.DATE-WANTED EQ ? THEN
                objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT "").
              ELSE
                objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT COOHD.DATE-WANTED). 
                
            END. /* IF AVAILABLE COOHD */
            
                          
            FOR EACH CSAHF WHERE CSAHF.INVOICE-NO       EQ COPAR.CUS-CHG-NO 
                             AND CSAHF.ITEM-NUMBER      BEGINS cCompanyCode                                                
                             AND NOT CSAHF.ITEM-NUMBER  BEGINS cCompanyCode + "*":U  NO-LOCK:
  
             IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*CITY-TAX*":U) THEN
             DO:
               objInvoiceHistory:SET(INPUT "city_tax":U, INPUT CSAHF.PRICE-EXT).
               NEXT. 
             END.
             
             IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*STATE-TAX*":U) THEN
             DO:
               objInvoiceHistory:SET(INPUT "state_tax":U, INPUT CSAHF.PRICE-EXT).
               NEXT. 
             END.
             
             ASSIGN 
               itemJsonObj     = NEW jsonObject() 
               prodInfoJsonObj = NEW jsonObject().            
             
             objCustomerOrders:getOrderedItem(INPUT CSAHF.ORDER-NUMBER,
                                              INPUT CSAHF.ITEM-NUMBER ,
                                              INPUT CSAHF.INVOICE-SEQ,
                                              INPUT CSAHF.DESCRIPTION,
                                              INPUT CSAHF.QTY-SHIPPED,
                                              INPUT "NOTAPPLICABLE", 
                                              INPUT cPriceList,
                                              INPUT cCustNum,
                                              INPUT cCompanyCode,
                                              INPUT ipiWarehouseNo,
                                              INPUT "",
                                              INPUT deDiscPerc,
                                              INPUT cContractInd,
                                              INPUT cSpecDictI,
                                              INPUT cQtyBrkCd,
                                              INPUT cCustType,
                                              OUTPUT itemJsonObj).
             IF CINV1.ITEM-NUMBER EQ CSAHF.ITEM-NUMBER THEN DO:                                
                 itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
             END.
             itemsArray:ADD(INPUT itemJsonObj).
             
             /* remove item_tax_unit array from product_info object */                                           
             DO iarrayIndex = 1 TO itemsArray:LENGTH:
              
               ASSIGN itemJsonObj = itemsArray:GetJsonObject(INPUT iarrayIndex).
               
               IF itemJsonObj:has(INPUT "product_info") THEN 
               DO:
                 ASSIGN prodInfoJsonObj = itemJsonObj:GetJsonObject("product_info").
               END.
              
               IF prodInfoJsonObj:has("item_tax_unit") THEN
               DO:                
                 prodInfoJsonObj:Remove(INPUT "item_tax_unit":U).
               END.                                          
                                       
             END. /* DO iarrayIndex = 1 TO itemJsonArray:LENGTH */ 
                                                   
            END. /* FOR EACH CSAHF */
            
            objInvoiceHistory:ADD(INPUT "invoice_items", INPUT itemsArray).
            
            ObjInvoiceArr:ADD(INPUT objInvoiceHistory).           
            ASSIGN lcInvoiceArr = ObjInvoiceArr:getJsonText().
            
          END. /* IF AVAILABLE COPAR THEN */
          
        END. /* FOR EACH ttCustomerInfo */
      
      END. /* IF iType EQ 0 THEN */
      
      /* Logic for amount invoiced customers dashboard for mobile */
      ELSE 
      DO:
          MESSAGE "getSalesmanCustomersOverdue-2".
          
        IF TRIM(ipcCustNum) NE "":U AND TRIM(ipcCustNum) NE "A":U THEN 
        DO:
          IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum) THEN 
          DO:
            objCommonSrc:getMessages(INPUT ipcLangID,
                                     INPUT ConstantInitializer:c200InvalidCustomer,
                                     OUTPUT opcError,
                                     OUTPUT opiStatusCode).
            
            IF cError NE "":U THEN 
              UNDO, THROW NEW AppError(opcError,1).
              
          END. /* IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum) */
                        
        END. /* IF TRIM(ipcCustNum) NE "":U AND TRIM(ipcCustNum) NE "A":U  */

        /* Get amount Invoiced inoivces which are displayed on customer dashboard */
        objSalesmanCustData:getCustAmountInvoiced(INPUT  ipcCustNum,
                                                  INPUT  cCompanyCode, 
                                                  INPUT  ipcUserName,
                                                  OUTPUT deCustAmtInvoiced,
                                                  OUTPUT iTotalInvoices,
                                                  OUTPUT TABLE ttCustInvoice,
                                                  OUTPUT cError).
                  
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
                
          
        FOR EACH ttCustInvoice:
          
          FIND FIRST COPAR WHERE COPAR.CUST-NUMBER EQ ttCustInvoice.customerNumber 
                             AND COPAR.CUS-CHG-NO  EQ ttCustInvoice.invoiceNumber NO-LOCK NO-ERROR.
          
          IF NOT AVAILABLE COPAR THEN 
          DO:
            /* If an invoice exists in CSAHF but doesn't exists in COPAR then don't send in array */
            NEXT.          
          END. /* IF NOT AVAILABLE COPAR THEN  */
           
          IF AVAILABLE COPAR THEN 
          DO:
            IF COPAR.CUS-CHG-NO EQ "":U OR COPAR.DESCRIPTION1 EQ "":U THEN NEXT. 
                                       
              objInvoiceStatusArr = NEW JsonArray().
              itemsArray          = NEW jsonArray().
              
              IF COPAR.CUS-CHG-NO BEGINS "on/acc" THEN NEXT. 
              
              FIND FIRST terms NO-LOCK WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-ERROR.
              IF AVAILABLE terms THEN 
                ASSIGN 
                  iTermDays    = TERMS.TERMS-DAYS
                  cDiscPerc    = STRING(TERMS.TERMS-PERCEN / 100) /* DISCOUNT PERCENT */
                  cMaxDiscount = STRING(INTEGER(cDiscPerc) * (COPAR.GROSS-INVAMT - COPAR.CUS-DISC-AMT)).
            
           /* logic to calculate the grace period allowed to customer to pay thr invoices */
           
              FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE EQ cCompanyCode AND PARAMFL.PARAM-ID EQ "OVERRIDE-TERMS":U NO-LOCK NO-ERROR.
              IF AVAILABLE PARAMFL THEN
                ASSIGN iGraceDays = INTEGER (PARAMFL.PARAM-VALUE1) NO-ERROR. 
              
              /*Max/last date to pay invoice incl. grace days*/
              ASSIGN dMaxPayDt = COPAR.CUS-INV-DATE + iTermDays + iGraceDays. 
              
              FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ COPAR.CUST-NUMBER NO-LOCK NO-ERROR.
              IF AVAIL CCSMS THEN
              DO:

                FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
                IF AVAILABLE SHPTO THEN
                  ASSIGN cPriceList = SHPTO.PRICE-LIST.
                ELSE
                  ASSIGN cPriceList = CCSMS.PRICE-LIST.
                  
                ASSIGN 
                  cCustNum       = CCSMS.CUST-NUMBER
                  cSpecDict      = ccsms.spec-dict-i
                  deDiscPerc     = ccsms.disc-perc
                  cQtyBrkCd      = ccsms.qty-brk-cd
                  cSpecDictI     = CCSMS.SPEC-DICT-I                      
                  cContractInd   = CCSMS.CONTRACT-IND
                  cCustType      = CCSMS.CUST-TYPE
                  cCustName      = REPLACE(CCSMS.CUST-NAME,"'", "")  //ccsms.cust-name
                  iCreditLim     = CCSMS.CREDIT-LIMIT.
                  
                  objSalesmanCustData:getAvailableCredit(INPUT  cCustNum,
                                                         OUTPUT deAvailCredit, 
                                                         OUTPUT cError).    
              END. /* IF AVAIL CCSMS THEN */
                
              ASSIGN 
                objInvoiceHistory = NEW JsonObject().                                   
                
              ASSIGN deBalanceDue = COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT - COPAR.PAY-DISC-AMT -  
                                    COPAR.OTH-ALLOWANC - COPAR.INV-CR-TOT  + COPAR.INV-DR-TOT.
              
              objInvoiceHistory:ADD(INPUT "invoice_number":U,  INPUT COPAR.CUS-CHG-NO).    /* add invoice number key */
              IF COPAR.DESCRIPTION1 NE "" THEN 
                 objInvoiceHistory:ADD(INPUT "order_number":U,    INPUT COPAR.DESCRIPTION1). /* add order_number key   */
              ELSE 
                 objInvoiceHistory:ADD(INPUT "order_number":U,    INPUT "NA").
                 
              objInvoiceHistory:ADD(INPUT "customer_number":U, INPUT COPAR.CUST-NUMBER).
              objInvoiceHistory:ADD(INPUT "customer_name":U,   INPUT cCustName).
              objInvoiceHistory:ADD(INPUT "customer_type":U,   INPUT cCustType).
              objInvoiceHistory:ADD(INPUT "available_credit":U,INPUT deAvailCredit).
              objInvoiceHistory:ADD(INPUT "credit_limit":U,    INPUT iCreditLim).
              
              IF COPAR.CUS-INV-DATE EQ ? THEN
                objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT "NA").
              ELSE
                objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT COPAR.CUS-INV-DATE + iTermDays).
                                                                    
              IF COPAR.CUS-INV-DATE EQ ? THEN
                objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT ""). 
              ELSE
                objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT COPAR.CUS-INV-DATE).
                
              objInvoiceHistory:ADD(INPUT "total":U,          INPUT COPAR.CUS-INV-NET).
              objInvoiceHistory:ADD(INPUT "collected":U,      INPUT COPAR.CUS-PAYMENT).
              /*objInvoiceHistory:ADD(INPUT "outstanding":U,  INPUT (COPAR.CUS-INV-NET - COPAR.CUS-PAYMENT)).*/
              objInvoiceHistory:ADD(INPUT "outstanding":U,    INPUT deBalanceDue).
              objInvoiceHistory:ADD(INPUT "city_tax":U,       INPUT 0).
              objInvoiceHistory:ADD(INPUT "state_tax":U,      INPUT 0).
              objInvoiceHistory:ADD(INPUT "status":U,         INPUT ""). 
              objInvoiceHistory:ADD(INPUT "grace_days":U,          INPUT iGraceDays).
              objInvoiceHistory:ADD(INPUT "discount_percentage":U, INPUT cDiscPerc).
              objInvoiceHistory:ADD(INPUT "max_discount":U,        INPUT cMaxDiscount).
              objInvoiceHistory:ADD(INPUT "max_pay_date":U,        INPUT dMaxPayDt).  
             
               
              /* Set the value conditionally This will just create the object once 
                 and then SET will just update that object 
              */
              
              FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
              IF NOT AVAIL COOHD AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
              DO:
                objCommonSrc:getMessages(INPUT  ipcLangID,
                                         INPUT  ConstantInitializer:c200ItemForInvoice,                                                              
                                         OUTPUT cItemFrInvoiceMsg,
                                         OUTPUT opiStatusCode).
                
                objCommonSrc:getMessages(INPUT  ipcLangID,
                                         INPUT  ConstantInitializer:c200NotFound,                                                              
                                         OUTPUT cNotFoundMsg,
                                         OUTPUT opiStatusCode).
                                        
                cItemNtFoundMsg =  cItemFrInvoiceMsg + " " + COPAR.CUS-CHG-NO + " " +  cNotFoundMsg.
                                                                                                                                                   
                /* This message will be displayed when no such record exists in COOHD and COODT */ 
                objInvoiceHistory:ADD(INPUT "item_fr_invoice_nt_foundmsg":U, INPUT cItemNtFoundMsg).
              
              END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT..) */
              
              /* For PARTIAL status */
              IF COPAR.CUS-PAYMENT LT COPAR.CUS-INV-NET THEN
              DO:            
                objInvoiceHistory:SET(INPUT "status":U, INPUT 4).
              END.
              
              /* For PENDING_PAYMENT status */
              IF COPAR.CUS-PAYMENT EQ 0.0 THEN
              DO:             
                objInvoiceHistory:SET(INPUT "status",INPUT 3).
              END.
                
               /* For OVERDUE status */
              /* Invoices which are overdue, will be treated as pending also */
              IF TODAY GT (COPAR.cus-inv-date + iTermDays) THEN
              DO:             
                objInvoiceHistory:SET(INPUT "status",INPUT 2).
              END.       
              
              /* For PAID status */
              IF deBalanceDue EQ 0.0 THEN 
              DO:             
                objInvoiceHistory:SET(INPUT "status",INPUT 1).  
              END.                           
                                      
              FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1 NO-LOCK NO-ERROR.
              IF AVAILABLE COOHD THEN 
              DO:
                objInvoiceHistory:ADD(INPUT "shipping_handling":U, INPUT COOHD.FREIGHT-AMT).
                
                IF COOHD.DATE-WANTED EQ ? THEN
                  objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT "").
                ELSE
                  objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT COOHD.DATE-WANTED). 
                  
              END. /* IF AVAILABLE COOHD */
              
              FOR EACH CSAHF WHERE CSAHF.INVOICE-NO       EQ COPAR.CUS-CHG-NO 
                               AND CSAHF.ITEM-NUMBER      BEGINS cCompanyCode                                               
                               AND NOT CSAHF.ITEM-NUMBER  BEGINS cCompanyCode + "*":U NO-LOCK:
    
               IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*CITY-TAX*":U) THEN
               DO:
                 objInvoiceHistory:SET(INPUT "city_tax":U, INPUT CSAHF.PRICE-EXT).
                 NEXT. 
               END.
               
               IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*STATE-TAX*":U) THEN
               DO:
                 objInvoiceHistory:SET(INPUT "state_tax":U, INPUT CSAHF.PRICE-EXT).
                 NEXT. 
               END.
               
               ASSIGN 
                 itemJsonObj     = NEW jsonObject() 
                 prodInfoJsonObj = NEW jsonObject().            
               
               objCustomerOrders:getOrderedItem(INPUT CSAHF.ORDER-NUMBER,
                                                INPUT CSAHF.ITEM-NUMBER ,
                                                INPUT CSAHF.INVOICE-SEQ,
                                                INPUT CSAHF.DESCRIPTION,
                                                INPUT CSAHF.QTY-SHIPPED,
                                                INPUT "NOTAPPLICABLE", 
                                                INPUT cPriceList,
                                                INPUT cCustNum,
                                                INPUT cCompanyCode,
                                                INPUT ipiWarehouseNo,
                                                INPUT "",
                                                INPUT deDiscPerc,
                                                INPUT cContractInd,
                                                INPUT cSpecDictI,
                                                INPUT cQtyBrkCd,
                                                INPUT cCustType,
                                                OUTPUT itemJsonObj).
               
               itemsArray:ADD(INPUT itemJsonObj).
               
               /* remove item_tax_unit array from product_info object */                                           
               DO iarrayIndex = 1 TO itemsArray:LENGTH:
                
                 ASSIGN itemJsonObj = itemsArray:GetJsonObject(INPUT iarrayIndex).
                 
                 IF itemJsonObj:has(INPUT "product_info") THEN 
                 DO:
                   ASSIGN prodInfoJsonObj = itemJsonObj:GetJsonObject("product_info").
                 END.
                
                 IF prodInfoJsonObj:has("item_tax_unit") THEN
                 DO:                
                   prodInfoJsonObj:Remove(INPUT "item_tax_unit":U).
                 END.                                          
                                         
               END. /* DO iarrayIndex = 1 TO itemJsonArray:LENGTH */ 
                                                     
              END. /* FOR EACH CSAHF */
              
              objInvoiceHistory:ADD(INPUT "invoice_items", INPUT itemsArray).
              
              ObjInvoiceArr:ADD(INPUT objInvoiceHistory).           
              ASSIGN lcInvoiceArr = ObjInvoiceArr:getJsonText().
            
          END. /* IF AVAILABLE COPAR THEN */
        END. /* for each ttCustInvoice  */
                                                             
      END.  /* ELSE - IF iType EQ 0 THEN */
      
      IF ObjInvoiceArr:LENGTH EQ 0 THEN 
      DO:
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvoiceNtFound,                                                              
                                 OUTPUT opcError,
                                 OUTPUT opiStatusCode).
       IF cError NE "":U THEN 
         UNDO, THROW NEW AppError(opcError,1).
      
      END. /* IF ObjInvoiceArr:LENGTH EQ 0 THEN  */ 
      
      RETURN.
  
    END METHOD.
    
    METHOD PUBLIC VOID getInvoiceData(INPUT ipcCustNumber        AS CHARACTER,
                                      INPUT ipcSalesRep          AS CHARACTER,
                                      INPUT ipcLangID            AS CHARACTER,                                            
                                      INPUT ipiWareHouseNo       AS INTEGER,
                                      INPUT cUserType            AS CHARACTER, 
                                      INPUT ipcInvoiceNumber     AS CHARACTER,
                                      OUTPUT lcInvoiceArr        AS LONGCHAR,
                                      OUTPUT opcError            AS CHARACTER,                                           
                                      OUTPUT opiStatusCode       AS INTEGER).
                                      
    DEFINE VARIABLE objInvoiceHistory   AS CLASS jsonObject     NO-UNDO.
        DEFINE VARIABLE ObjInvoiceItems     AS CLASS jsonObject     NO-UNDO. 
        DEFINE VARIABLE itemJsonObj         AS CLASS jsonObject     NO-UNDO.
        DEFINE VARIABLE prodInfoJsonObj     AS CLASS jsonObject     NO-UNDO. 
        DEFINE VARIABLE ObjInvoiceArr       AS CLASS jsonArray      NO-UNDO.
        DEFINE VARIABLE itemsArray          AS CLASS jsonArray      NO-UNDO.
        DEFINE VARIABLE objInvoiceStatusArr AS CLASS jsonArray      NO-UNDO.
        DEFINE VARIABLE objCommonSrc        AS CLASS CommonSource   NO-UNDO.
        DEFINE VARIABLE objCustomerOrders   AS CLASS CustomerOrders NO-UNDO.
        
        DEFINE VARIABLE deBalanceDue        AS DECIMAL              NO-UNDO.
        DEFINE VARIABLE iTermDays           AS INTEGER              NO-UNDO.
        DEFINE VARIABLE cCompanyCode        AS CHARACTER            NO-UNDO.
        DEFINE VARIABLE cPriceList          AS CHARACTER            NO-UNDO.        
        DEFINE VARIABLE iarrayIndex         AS INTEGER              NO-UNDO.              
        DEFINE VARIABLE iBatchSize          AS INTEGER              NO-UNDO INIT 50.  /* initial batch size set to 50 records */                
        DEFINE VARIABLE cItemNtFoundMsg     AS CHARACTER            NO-UNDO.
        DEFINE VARIABLE cNotFoundMsg        AS CHARACTER            NO-UNDO.  
        DEFINE VARIABLE cItemFrInvoiceMsg   AS CHARACTER            NO-UNDO.      
        DEFINE VARIABLE iGraceDays          AS INTEGER              NO-UNDO.
        DEFINE VARIABLE dMaxPayDt           AS DATE                 NO-UNDO.
        DEFINE VARIABLE cDiscPerc           AS CHARACTER            NO-UNDO.
        DEFINE VARIABLE cMaxDiscount        AS CHARACTER            NO-UNDO.
        DEFINE VARIABLE iMaxInvoiceDayFetch AS INTEGER              NO-UNDO.
        
        /* DEFINE QUERY lvQuery FOR COPAR SCROLLING. */
       
        ASSIGN
          ObjInvoiceArr       = NEW jsonArray()  
          cCompanyCode        = SUBSTRING(ipcCustNumber,1,1)
          itemJsonObj         = NEW jsonObject()
          objCustomerOrders   = NEW CustomerOrders(INPUT cToken)
          objCommonSrc        = NEW CommonSource(INPUT cToken).              
        
        FOR EACH COPAR  WHERE COPAR.CUST-NUMBER  EQ TRIM(ipcCustNumber) 
                          AND COPAR.CUS-CHG-NO   EQ ipcInvoiceNumber NO-LOCK:
                                       
            
            IF COPAR.CUS-CHG-NO EQ "":U OR COPAR.DESCRIPTION1 EQ "":U THEN NEXT. 
            
            objInvoiceStatusArr = NEW JsonArray().
            itemsArray          = NEW jsonArray ().
            
            IF COPAR.CUS-CHG-NO BEGINS "on/acc" THEN NEXT. 
            
            FIND FIRST terms NO-LOCK WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-ERROR.
            IF AVAILABLE terms THEN 
              ASSIGN iTermDays = TERMS.TERMS-DAYS.
            
            FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
            IF AVAIL CCSMS THEN
            DO:    
              FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
              IF AVAILABLE SHPTO THEN
                ASSIGN cPriceList = SHPTO.PRICE-LIST.
              ELSE
                ASSIGN cPriceList = CCSMS.PRICE-LIST.
            END. /* IF AVAIL CCSMS THEN */
            
            ASSIGN 
              objInvoiceHistory  = NEW JsonObject().                                   
              
            ASSIGN deBalanceDue = COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT - COPAR.PAY-DISC-AMT -  
                                  COPAR.OTH-ALLOWANC - COPAR.INV-CR-TOT  + COPAR.INV-DR-TOT.
            
            objInvoiceHistory:ADD(INPUT "invoice_number":U, INPUT COPAR.CUS-CHG-NO).    /* add invoice number key */
            IF COPAR.DESCRIPTION1 NE "" THEN 
              objInvoiceHistory:ADD(INPUT "order_number":U,   INPUT COPAR.DESCRIPTION1). /* add order_number key   */
            ELSE 
              objInvoiceHistory:ADD(INPUT "order_number":U,   INPUT "NA"). /* add order_number key   */  
            
            IF COPAR.cus-inv-date EQ ? THEN
              objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT "NA").
            ELSE
              objInvoiceHistory:ADD(INPUT "due_on":U,       INPUT COPAR.CUS-INV-DATE + iTermDays).
                                                                  
            IF COPAR.CUS-INV-DATE EQ ? THEN
              objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT ""). 
            ELSE
              objInvoiceHistory:ADD(INPUT "invoice_date":U, INPUT COPAR.CUS-INV-DATE).
              
            objInvoiceHistory:ADD(INPUT "total":U,          INPUT COPAR.CUS-INV-NET).
            objInvoiceHistory:ADD(INPUT "collected":U,      INPUT COPAR.CUS-PAYMENT).
            /*objInvoiceHistory:ADD(INPUT "outstanding":U,  INPUT (COPAR.CUS-INV-NET - COPAR.CUS-PAYMENT)).*/
            objInvoiceHistory:ADD(INPUT "outstanding":U,    INPUT deBalanceDue).
            objInvoiceHistory:ADD(INPUT "city_tax":U,       INPUT 0).
            objInvoiceHistory:ADD(INPUT "state_tax":U,      INPUT 0).
            objInvoiceHistory:ADD(INPUT "status":U,         INPUT ""). /* set the value conditionally */
            
            FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
            IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
            DO:            
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200ItemForInvoice,                                                              
                                       OUTPUT cItemFrInvoiceMsg,
                                       OUTPUT opiStatusCode).
              
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200NotFound,                                                              
                                       OUTPUT cNotFoundMsg,
                                       OUTPUT opiStatusCode). 
                                       
              cItemNtFoundMsg =  cItemFrInvoiceMsg + " " + COPAR.CUS-CHG-NO + " " +  cNotFoundMsg.
                                                                                                                                  
              /* ITEMS FOR INVOICE copar.CUS-CHS-NO NOT FOUND */
              objInvoiceHistory:ADD(INPUT "item_fr_invoice_nt_foundmsg":U, INPUT cItemNtFoundMsg).
            END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT).. */
            
            /* For PARTIAL status */
            IF COPAR.CUS-PAYMENT LT COPAR.CUS-INV-NET THEN
            DO:
              (IF objInvoiceHistory:Has("status")   THEN              
              objInvoiceHistory:SET(INPUT "status":U, INPUT 4) ELSE ?).
            END.
            
            /* For PENDING_PAYMENT status */
            IF COPAR.CUS-PAYMENT EQ 0.0 THEN
            DO:
              (IF objInvoiceHistory:Has("status")   THEN               
              objInvoiceHistory:SET(INPUT "status",INPUT 3) ELSE ?).
            END.
              
            /* For OVERDUE status */
            IF TODAY GT (COPAR.cus-inv-date + iTermDays) THEN
            DO:             
              (IF objInvoiceHistory:Has("status")   THEN  
              objInvoiceHistory:SET(INPUT "status",INPUT 2) ELSE ?).
            END.       
            
            /* For PAID status */
            IF deBalanceDue EQ 0.0 THEN 
            DO:             
              (IF objInvoiceHistory:Has("status")   THEN
              objInvoiceHistory:SET(INPUT "status",INPUT 1) ELSE ?).  
            END.    
            
            /*IF lOverdue AND lPartialPay AND lPending THEN 
              objInvoiceHistory:SET(INPUT "status",INPUT "2":U).*/
              
            /*IF lPaid THEN
              objInvoiceHistory:SET(INPUT "status",INPUT "1":U).
              
            IF lOverdue AND lPartialPay AND lPending THEN 
              objInvoiceHistory:SET(INPUT "status",INPUT "1":U).*/
                                    
            FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1 NO-LOCK NO-ERROR.
            IF AVAILABLE COOHD THEN 
            DO:
              objInvoiceHistory:ADD(INPUT "shipping_handling":U, INPUT COOHD.FREIGHT-AMT).
              
              IF COOHD.DATE-WANTED EQ ? THEN
                objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT "").
              ELSE
                objInvoiceHistory:ADD(INPUT "shipped_on_date":U, INPUT COOHD.DATE-WANTED). 
                
            END.
            
            FOR EACH CSAHF WHERE CSAHF.INVOICE-NO       EQ COPAR.CUS-CHG-NO
                             AND CSAHF.ITEM-NUMBER      BEGINS cCompanyCode                                               
                             AND NOT CSAHF.ITEM-NUMBER  BEGINS cCompanyCode + "*":U NO-LOCK:
  
             IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*CITY-TAX*":U) THEN
             DO:
               objInvoiceHistory:SET(INPUT "city_tax":U, INPUT CSAHF.PRICE-EXT).
               NEXT. 
             END.
             
             IF CSAHF.ITEM-NUMBER  EQ (cCompanyCode + "*STATE-TAX*":U) THEN
             DO:
               objInvoiceHistory:SET(INPUT "state_tax":U, INPUT CSAHF.PRICE-EXT).
               NEXT. 
             END.
             
             ASSIGN 
               itemJsonObj     = NEW jsonObject() 
               prodInfoJsonObj = NEW jsonObject().            
             
             objCustomerOrders:getOrderedItem(INPUT CSAHF.ORDER-NUMBER,
                                              INPUT CSAHF.ITEM-NUMBER ,
                                              INPUT CSAHF.INVOICE-SEQ,
                                              INPUT CSAHF.DESCRIPTION,
                                              INPUT CSAHF.QTY-SHIPPED,
                                              INPUT "NOTAPPLICABLE", 
                                              INPUT cPriceList,
                                              INPUT CCSMS.CUST-NUMBER,
                                              INPUT cCompanyCode,
                                              INPUT ipiWarehouseNo,
                                              INPUT "",
                                              INPUT CCSMS.DISC-PERC,
                                              INPUT CCSMS.CONTRACT-IND,
                                              INPUT CCSMS.SPEC-DICT-I,
                                              INPUT CCSMS.QTY-BRK-CD,
                                              INPUT CCSMS.CUST-TYPE,
                                              OUTPUT itemJsonObj).
             itemsArray:ADD(INPUT itemJsonObj).
             
             /* remove item_tax_unit array from product_info object*/                                           
             DO iarrayIndex = 1 TO itemsArray:LENGTH:
              
               ASSIGN itemJsonObj = itemsArray:GetJsonObject(INPUT iarrayIndex).
               
               IF itemJsonObj:has(INPUT "product_info") THEN 
               DO:
                 ASSIGN prodInfoJsonObj = itemJsonObj:GetJsonObject("product_info").
               END.
              
               IF prodInfoJsonObj:has("item_tax_unit") THEN
               DO:                
                 prodInfoJsonObj:Remove(INPUT "item_tax_unit":U).
               END.                                          
                                       
             END. /* DO iarrayIndex = 1 TO itemJsonArray:LENGTH */ 
                                                   
            END. /* FOR EACH CSAHF   */
                        
            objInvoiceHistory:ADD(INPUT "invoice_items", INPUT itemsArray).
            
            ObjInvoiceArr:ADD(INPUT objInvoiceHistory).           
            ASSIGN lcInvoiceArr = ObjInvoiceArr:getJsonText().
                   /* Pagination ipcLastRowID = STRING(ROWID(copar)).*/
                    
          /* commented END */ 
        END. /* FOR EACH COPAR */
          /* Pagination END. /* DO iRecords = 1 TO iBatchSize: */*/
        
               
        RETURN.
                                          
                                  
    END METHOD.                                     

END CLASS.