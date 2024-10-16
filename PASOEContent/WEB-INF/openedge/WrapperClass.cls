@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
/*--------------------------------------------------------------------------------
   File        : WrapperClass
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : JKTECH
   Created     : Thu Jul 06 15:25:29 IST 2017
   Notes       : Version 1.1
   History     :
   --------------------------------------------------------------------------------
   Date(MM-DD-YY)        Author            Initial(XX-Version)      Description
                                                   
   --------------------------------------------------------------------------------         
 ----------------------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW. 

CLASS WrapperClass: 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
  /* Temp-table to store details of all the customers belonging to a logged in salesperson */     
  DEFINE PRIVATE TEMP-TABLE ttCustomer NO-UNDO SERIALIZE-NAME "customers":U   
    FIELD customerNumber      LIKE CCSMS.CUST-NUMBER
    FIELD discount            LIKE CCSMS.CUST-NUMBER
    FIELD customerName        LIKE CCSMS.CUST-NAME
    FIELD secondName          LIKE CCSMS.SECOND-NAME
    FIELD creditLimit         LIKE CCSMS.CREDIT-LIMIT
    FIELD phoneNumber         LIKE CCSMS.PHONE-NUMBER
    FIELD customerType        LIKE CCSMS.CUST-TYPE
    FIELD customer_picture    LIKE CCSMS.CUST-NAME
    FIELD terms_condition_pdf LIKE CCSMS.CUST-NAME
    FIELD emailId             LIKE CCSMS.E-MAIL
    FIELD amtOverdue          AS DECIMAL
    FIELD availCredit         AS DECIMAL
    FIELD route               LIKE CCSMS.route
    FIELD totalSales          AS DECIMAL
    FIELD custSaleInLast90Day AS DECIMAL
    FIELD custAmtInvoiced     AS DECIMAL
    FIELD paymentTerm         LIKE TERMS.CUS-TERMS-DS
    FIELD priceList           LIKE CCSMS.PRICE-LIST
    FIELD totalOpenOrderAmt   AS DECIMAL
    FIELD totalOpenOrder      AS INTEGER
    FIELD totalOverdues       AS INTEGER
    FIELD totalInvoices       AS INTEGER 
    FIELD recentOrderDate     AS CHARACTER
    FIELD onHoldCustomer      AS LOGICAL
    FIELD poRequired          AS LOGICAL
    FIELD number_of_days      AS INTEGER.  
    
  DEFINE PRIVATE TEMP-TABLE ttsalesPersonAdd NO-UNDO
    FIELD addressL1 LIKE CSAMS.ADDRESS-L1
    FIELD addressL2 LIKE CSAMS.ADDRESS-L2
    FIELD addressL3 LIKE CSAMS.ADDRESS-L3.
 
  DEFINE PRIVATE TEMP-TABLE ttOpenOrder NO-UNDO SERIALIZE-NAME "open_orders":U
    FIELD orderNumber    LIKE COOHD.ORDER-NUMBER
    FIELD orderDate      LIKE COOHD.ORDER-DATE
    FIELD openAmt        LIKE COODT.ORDERED-PRC
    FIELD customerNumber LIKE CCSMS.CUST-NUMBER
    FIELD customerName   AS CHARACTER. 
  
  DEFINE PRIVATE TEMP-TABLE ttCustInvoice NO-UNDO SERIALIZE-NAME "customer_invoices":U
    FIELD customerNumber              AS CHARACTER SERIALIZE-HIDDEN
    FIELD invoiceNumber               AS CHARACTER
    FIELD orderNumber                 AS CHARACTER
    FIELD invoiceDate                 AS DATE 
    FIELD invoiceAmount               AS DECIMAL
    FIELD collected                   LIKE COPAR.CUS-PAYMENT
    FIELD due_on                      LIKE COPAR.CUS-INV-DATE
    FIELD item_fr_invoice_nt_foundmsg AS LOGICAL.
   
  DEFINE PRIVATE TEMP-TABLE ttCustAmountOverdue NO-UNDO SERIALIZE-NAME "customer_overdues":U
    FIELD customerNumber              LIKE COPAR.CUST-NUMBER SERIALIZE-HIDDEN
    FIELD customerName                LIKE CCSMS.CUST-NAME SERIALIZE-HIDDEN
    FIELD orderNumber                 LIKE COPAR.CUS-ORDER-NO 
    FIELD description1                LIKE COPAR.Description1
    FIELD orderDate                   LIKE COPAR.CUS-INV-DATE
    FIELD custInvoiceAmt              LIKE COPAR.CUS-INV-COST
    FIELD collected                   LIKE COPAR.CUS-PAYMENT
    FIELD due_on                      LIKE COPAR.CUS-INV-DATE
    FIELD item_fr_invoice_nt_foundmsg AS LOGICAL 
    FIELD overdueAmount               LIKE COPAR.GROSS-INVAMT.
  
  /* Temp-Table For storing item details presented in the cart */
  DEFINE PRIVATE TEMP-TABLE ttCartProducts NO-UNDO
    FIELD item_number AS CHARACTER
    FIELD description AS CHARACTER
    FIELD quantity    AS DECIMAL
    FIELD unit_price  AS DECIMAL
    FIELD item_color  AS CHARACTER
    FIELD item_size   AS CHARACTER
    FIELD unique_id   AS CHARACTER.
    
  
  DEFINE PRIVATE TEMP-TABLE ttCustomerInfo NO-UNDO
    FIELD customerNumber              LIKE COPAR.CUST-NUMBER
    FIELD customerName                LIKE CCSMS.CUST-NAME
    FIELD orderNumber                 LIKE COPAR.CUS-ORDER-NO 
    FIELD description1                LIKE COPAR.Description1
    FIELD orderDate                   LIKE COPAR.CUS-INV-DATE
    FIELD custInvoiceAmt              LIKE COPAR.CUS-INV-COST
    FIELD collected                   LIKE COPAR.CUS-PAYMENT
    FIELD due_on                      LIKE COPAR.CUS-INV-DATE
    FIELD item_fr_invoice_nt_foundmsg AS LOGICAL 
    FIELD overdueAmount               LIKE COPAR.GROSS-INVAMT. 
    
  
  
  DEFINE PRIVATE TEMP-TABLE ttEnglishLit NO-UNDO 
    FIELD languageId AS CHARACTER
    FIELD LabelName  AS CHARACTER
    FIELD LabelValue AS CHARACTER. 
    
  DEFINE PRIVATE TEMP-TABLE ttSpanishLit NO-UNDO LIKE ttEnglishLit .
      
  DEFINE PRIVATE TEMP-TABLE ttCompany NO-UNDO SERIALIZE-NAME "company":U
    FIELD companyCode    AS CHARACTER
    FIELD companyName    AS CHARACTER
    FIELD companyFreight AS DECIMAL.
  
  DEFINE PRIVATE TEMP-TABLE ttCustShippingAddress NO-UNDO SERIALIZE-NAME "customer_shipping_addresses":U
    FIELD customerNumber AS CHARACTER SERIALIZE-HIDDEN
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
    
  DEFINE PRIVATE TEMP-TABLE ttCustBillingAddress NO-UNDO SERIALIZE-NAME "customer_billing_address":U
    FIELD customerNumber AS CHARACTER SERIALIZE-HIDDEN   
    FIELD billingAdd1    LIKE ccsms.ADDRESS-L1
    FIELD billingAdd2    LIKE ccsms.ADDRESS-L2
    FIELD billingAdd3    LIKE ccsms.ADDRESS-L3
    FIELD billingState   LIKE ccsms.POSTAL-STATE
    FIELD billingCity    LIKE CCSMS.POSTAL-city  
    FIELD billingZip     LIKE CCSMS.POSTAL-ZIP.  
  
  DEFINE PRIVATE TEMP-TABLE ttCheckoutCustomer NO-UNDO
    FIELD temp_number      AS CHARACTER
    FIELD cust_number      AS CHARACTER
    FIELD cust_name        AS CHARACTER
    FIELD shippingAdL1     AS CHARACTER
    FIELD shippingAdL2     AS CHARACTER
    FIELD shippingAdL3     AS CHARACTER
    FIELD payment_term     AS CHARACTER
    FIELD regular_salesman AS LOGICAL
    FIELD ship_to_no       AS CHARACTER
    FIELD po_number        AS CHARACTER
    FIELD date_wanted      AS DATE
    FIELD order_on_hold    AS CHARACTER.
    
  DEFINE PRIVATE TEMP-TABLE ttCheckoutProducts NO-UNDO
    FIELD temp_number      AS CHARACTER
    FIELD item_sequence    AS INTEGER
    FIELD item_number      AS CHARACTER
    FIELD item_description AS CHARACTER    
    FIELD quantity         AS DECIMAL
    FIELD unit_price       AS DECIMAL
    FIELD item_total_price AS DECIMAL
    FIELD item_color       AS CHARACTER
    FIELD item_size        AS CHARACTER.   
   
  DEFINE PRIVATE TEMP-TABLE ttPayment NO-UNDO 
    FIELD invoice_num   AS CHARACTER
    FIELD order_number  AS CHARACTER    
    FIELD payment_type  AS CHARACTER
    FIELD payment_amt   AS DECIMAL
    FIELD cheque_num    AS CHARACTER
    FIELD discount_amt  AS DECIMAL.
  
  DEFINE TEMP-TABLE ttSalesRepLocation SERIALIZE-NAME "locations_data":U
    FIELD sales_rep_id   LIKE LocationMgmt.Sales-Rep-Id  
    FIELD sales-rep-name LIKE CSAMS.SALES-NAME
    FIELD check_in_time  LIKE LocationMgmt.CheckInTime
    FIELD check_out_time LIKE LocationMgmt.CheckoutTime
    FIELD longitude      LIKE LocationMgmt.Longitude
    FIELD latitude       LIKE LocationMgmt.Latitude.  
    
  DEFINE PRIVATE DATASET ipdsCheckoutData SERIALIZE-HIDDEN FOR ttCheckoutCustomer,ttCheckoutProducts,ttPayment                                                                                                                                
    DATA-RELATION drCustCheckoutProducts  FOR ttCheckoutCustomer, ttCheckoutProducts 
    RELATION-FIELDS (temp_number,temp_number) NESTED FOREIGN-KEY-HIDDEN.
                
  DEFINE PRIVATE DATASET opdsSalespersonData SERIALIZE-HIDDEN FOR ttCustomer,     ttOpenOrder,            ttCustAmountOverdue, 
    ttCustInvoice,  ttCustShippingAddress,  ttCustBillingAddress
                                                                  
    DATA-RELATION drCustShippingAdd  FOR ttCustomer, ttCustShippingAddress  RELATION-FIELDS (customerNumber,customerNumber) NESTED FOREIGN-KEY-HIDDEN
    DATA-RELATION drCustBillingAdd   FOR ttCustomer, ttCustBillingAddress   RELATION-FIELDS (customerNumber,customerNumber) NESTED FOREIGN-KEY-HIDDEN
    DATA-RELATION drCustOpenOrder    FOR ttCustomer, ttOpenOrder            RELATION-FIELDS (customerNumber,customerNumber) NESTED FOREIGN-KEY-HIDDEN
    DATA-RELATION drCustAmtOverdue   FOR ttCustomer, ttCustAmountOverdue    RELATION-FIELDS (customerNumber,customerNumber) NESTED FOREIGN-KEY-HIDDEN
    DATA-RELATION drCustInvoices     FOR ttCustomer, ttCustInvoice          RELATION-FIELDS (customerNumber,customerNumber) NESTED FOREIGN-KEY-HIDDEN.
  
  DEFINE TEMP-TABLE online_account_info NO-UNDO 
         FIELDS provider_name    AS CHARACTER 
         FIELD  provider_id      AS CHARACTER 
         FIELDS provider_account AS CHARACTER 
         FIELD  provider_auth_key AS CHARACTER.
         
         
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
          
    DEFINE  TEMP-TABLE salesrepreport NO-UNDO 
          FIELD salesrep-id     AS CHARACTER 
          FIELD report-name     AS CHARACTER 
          FIELD report-location AS CHARACTER.           
       
  DEFINE PRIVATE VARIABLE cError            AS CHARACTER NO-UNDO.
  DEFINE PRIVATE VARIABLE iOverdueCustCount AS INTEGER   NO-UNDO.
  DEFINE PRIVATE VARIABLE deCartsAmt        AS DECIMAL   NO-UNDO.
  DEFINE PRIVATE VARIABLE deTotalOverdueAmt AS DECIMAL   NO-UNDO.
  DEFINE PRIVATE VARIABLE lRegularSlsman    AS LOGICAL   NO-UNDO.
  DEFINE PRIVATE VARIABLE lLoginStatus      AS LOGICAL   NO-UNDO.
  DEFINE         VARIABLE hSharedVar        AS HANDLE    NO-UNDO.
  DEFINE         VARIABLE cUserType         AS HANDLE    NO-UNDO.
  
  DEFINE VARIABLE dtzStartTime AS DATETIME-TZ NO-UNDO INIT "01-01-1970 00:00:00+00:00":U.
  CONSTRUCTOR PUBLIC WrapperClass():
    
    /* Shared variables defined in triggers are initialized in this file */
    RUN sharedVariables.p.  
  
                                                         
                                                                                                      
  END CONSTRUCTOR.
  
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID collectPaymentWrapper(INPUT ipcUserId         AS CHARACTER,                                                                                      
                                            INPUT ipcCustNumber     AS CHARACTER,
                                            INPUT ipcPaymentData    AS LONGCHAR,
                                            INPUT ipcToken          AS CHARACTER,
                                            INPUT ipcLangId         AS CHARACTER,                                                  
                                            OUTPUT opcAppToken      AS CHARACTER,                                                                                    
                                            OUTPUT opiStatusCode    AS INTEGER,
                                            OUTPUT opcError         AS CHARACTER):
    
    DEFINE VARIABLE objPaymentProcess AS CLASS     PaymentProcessing NO-UNDO.
    DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement   NO-UNDO.
    DEFINE VARIABLE objCommonSrc      AS CLASS     CommonSource      NO-UNDO.
    
    DEFINE VARIABLE cCustNumber       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE opcStatus         AS CHARACTER NO-UNDO.     
    DEFINE VARIABLE cUserType         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lReadJSONOK       AS LOGICAL   NO-UNDO.
     
    ASSIGN 
      objPaymentProcess = NEW PaymentProcessing(INPUT ipcToken)
      objTokenMgmt      = NEW TokenManagement(INPUT ipcToken)
      objCommonSrc      = NEW CommonSource(INPUT ipcToken).
    
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /* Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U OR.. */

    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
    END. /* ELSE */ 
    
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
      
    /* validate the token */
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
      INPUT  ipcUserId,
      INPUT  ipcLangID, 
      OUTPUT cError,
      OUTPUT opcStatus,
      OUTPUT opcAppToken,
      OUTPUT opiStatusCode). 
                                                                                      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
    
    IF opcStatus EQ "Success":U THEN
    DO:   
      FIND FIRST Token WHERE Token.Token EQ ipcToken NO-LOCK NO-ERROR.
      IF AVAILABLE TOKEN THEN
        ASSIGN cUserType = Token.User-Type.  
       
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /* Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
            
        END. /* IF NOT CAN-FIND(CSAMS...) */
        
        IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
        DO:
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200CustBlank,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /* IF TRIM(ipcCustNum) EQ "" */  
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
          
          ASSIGN 
            cCustNumber = ipcCustNumber.
               
        END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
        
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */
      
      ELSE
      DO:
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        ASSIGN 
          cCustNumber = ipcUserId.
        
      END. /* ELSE OF cUserType EQ ConstantInitializer:cMobileUser THEN */ 
      
      lReadJSONOK = TEMP-TABLE ttPayment:READ-JSON("longchar":U, ipcPaymentData, "empty":U).
      
      objPaymentProcess:Pay-invoice-mobile-web( INPUT cCustNumber,
                                                INPUT ipcLangID,
                                                INPUT TABLE ttPayment,
                                                OUTPUT opcError,
                                                OUTPUT opiStatusCode).
      IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).                                                  
      /* FOR EACH ttPayment NO-LOCK:
        
        IF ttPayment.payment_type EQ "invoice":U THEN
          NEXT.
        
        
        /* initiate payment processing */
        objPaymentProcess:mainBlock(INPUT ttPayment.invoice_num,  
                                    INPUT cCustNumber,
                                    INPUT ttPayment.order_number, 
                                    INPUT ttPayment.payment_type,
                                    INPUT ttPayment.payment_amt,
                                    INPUT ttPayment.cheque_num,
                                    INPUT ipcLangID,
                                    INPUT ttPayment.discount_amt,          
                                    OUTPUT opcError,
                                    OUTPUT opiStatusCode). 
        IF opcError NE "":U THEN 
          UNDO,THROW NEW AppError(opcError,1).                               
          
      END. */ /* FOR EACH ttPayment */
           
    END. /* IF opcStatus EQ "Success":U THEN */   
    
    ASSIGN 
      opiStatusCode = 200.
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
        
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
      
      IF VALID-OBJECT(objPaymentProcess) THEN  
        DELETE OBJECT objPaymentProcess.
      
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
              
    END FINALLY.

  END METHOD.
  
  
  /*----------------------------------------------------------------------------------------------------
   Purpose:This API provides the items of invoices of customer's overdue invoices on
           Salesman's dashboard AND amount invoiced invoices on cust dashboard. Invoices which are overdue 
           will be returned in the 
           response along with their items (if available)
   Notes: This API returns data for Customer Amount Overdue invioces(Customer wise, when a cust num is 
          specified, if cust-num EQ 'A' is passed then it will give data of only that customer and 
          all sales rep, when cust-num EQ "A"), Amount invoiced (cust dashboard). When iType EQ 2 then it 
          will return data for Customers Overdue/Amount Overdue for both salesman dashboard and customer dashboard.
          When iType EQ 2 then it will return data for Customer overdue mobile, otherthan 2
          it will return data for amount invoiced (Customer Dashboard).
  -------------------------------------------------------------------------------------------------------*/

  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID getCustOverdueInvoiceItemsWpr(INPUT ipcUserID            AS CHARACTER,
                                                    INPUT ipcCustNum           AS CHARACTER,                                                    
                                                    INPUT ipcToken             AS CHARACTER, 
                                                    INPUT iType                AS INTEGER,                                                 
                                                    INPUT ipiLastSyncTimestamp AS INT64,
                                                    INPUT ipcLangId            AS CHARACTER,
                                                    OUTPUT lcInvoiceArr        AS LONGCHAR,
                                                    OUTPUT opcError            AS CHARACTER,
                                                    OUTPUT opcAppToken         AS CHARACTER, 
                                                    OUTPUT opiStatusCode       AS INTEGER):
    
    DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc      AS CLASS     CommonSource    NO-UNDO. 
    DEFINE VARIABLE objInvoiceHistory AS CLASS     InvoiceHistory  NO-UNDO.

    DEFINE VARIABLE opcStatus         AS CHARACTER NO-UNDO.     
    DEFINE VARIABLE iWareHouseNo      AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCompanyCode      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType         AS CHARACTER NO-UNDO. 
        
    ASSIGN                
      objTokenMgmt      = NEW TokenManagement(INPUT ipcToken)
      objCommonSrc      = NEW CommonSource(INPUT ipcToken)
      objInvoiceHistory = NEW InvoiceHistory(INPUT ipcToken )
      lcInvoiceArr      = "[]".      
    
    IF TRIM(ipcCustNum) EQ "":U OR TRIM(ipcCustNum) EQ ? THEN 
    DO:
      objCommonSrc:getMessages(INPUT ipcLangID,
        INPUT ConstantInitializer:c200CustBlank,
        OUTPUT cError,
        OUTPUT opiStatusCode).
      IF cError NE "":U THEN
        UNDO, THROW NEW AppError(cError,1).
        
    END. /* IF TRIM(ipcCustNum) EQ "":U.. */
    
    IF iType NE 2 THEN 
    DO:
      IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum) THEN 
      DO:
        objCommonSrc:getMessages(INPUT ipcLangID,
          INPUT ConstantInitializer:c200InvalidCustomer,
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO, THROW NEW AppError(cError,1).
          
      END. /* IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum) */
    END. /* IF iType NE 2 */
    
    IF TRIM(ipcCustNum) NE "":U AND TRIM(ipcCustNum) NE "A":U THEN 
    DO:
      IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum) THEN 
      DO:
        objCommonSrc:getMessages(INPUT ipcLangID,
          INPUT ConstantInitializer:c200InvalidCustomer,
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO, THROW NEW AppError(cError,1).
          
      END. /* IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum) */
                    
    END. /* IF TRIM(ipcCustNum) NE "":U AND TRIM(ipcCustNum) NE "A":U  */
             
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /* Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
    
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILanguage WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE).. */        
    END. /* ELSE */ 
        
    /* Validate the token of the user on every request */
    IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c403InvalidToken,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcToken) EQ "":U OR.. */   
        
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
                    
    /* validate the token */
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
      INPUT  ipcUserId,
      INPUT  ipcLangID, 
      OUTPUT cError,
      OUTPUT opcStatus,
      OUTPUT opcAppToken,
      OUTPUT opiStatusCode). 
                                                                                      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
    
        
    IF opcStatus EQ "Success":U THEN
    DO:
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.  
        FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE. 
        END. /* FOR FIRST CMPNY..*/           
      END. /* FOR FIRST Token..*/
      IF AVAIL token AND Token.User-Type = "mobileuser":u   THEN 
        DO:
          
        END.
      
      IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
      DO:
        /*Get multilingual message for invalid user */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidUser,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK).. */        
      
      /* Get items of customer's overdue invoices */
      objInvoiceHistory:getCustomerOverdueInvoiceItems(INPUT ipcUserId,
        INPUT ipcCustNum,
        INPUT cCompanyCode,
        INPUT iType,
        INPUT iWareHouseNo,
        INPUT cUserType, 
        INPUT ipiLastSyncTimestamp,
        INPUT ipcLangId,
        OUTPUT lcInvoiceArr,
        OUTPUT opcError,
        OUTPUT opiStatusCode).
      
      IF opcError NE "":U THEN
        UNDO,THROW NEW AppError(opcError,1).                                                                                                                         
                                 
      ASSIGN 
        opiStatusCode = 200. 
                                               
    END. /* IF opcStatus EQ "Success":U THEN */

    RETURN. 
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
        
      IF VALID-OBJECT(objCommonSrc)      THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt)      THEN  
        DELETE OBJECT objTokenMgmt.
      
      IF VALID-OBJECT(objInvoiceHistory) THEN  
        DELETE OBJECT objInvoiceHistory.
               
      IF VALID-HANDLE(hSharedVar)        THEN 
        DELETE PROCEDURE hSharedVar      NO-ERROR.
    
    END FINALLY.                                                                                                           
        

  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/
  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID orderHistoryWrapper(INPUT ipcUserId          AS CHARACTER,
                                        INPUT ipcCustNumber      AS CHARACTER,                                    
                                        INPUT ipcToken           AS CHARACTER,
                                        INPUT ipcLangId          AS CHARACTER,
                                        INPUT ipiNoOfmonth       AS INTEGER,
                                        INPUT ipcShipTo          AS CHARACTER,
                                        INPUT ipiSyncTime        AS INT64,                                                  
                                        OUTPUT opcAppToken       AS CHARACTER,                                       
                                        OUTPUT opcError          AS CHARACTER,
                                        OUTPUT opiStatusCode     AS INTEGER, 
                                        OUTPUT oplcOrderHistData AS LONGCHAR):
                                                 
    
    DEFINE VARIABLE objTokenMgmt AS CLASS     TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc AS CLASS     CommonSource    NO-UNDO. 
    DEFINE VARIABLE objCustOrder AS CLASS     CustomerOrders  NO-UNDO.

    DEFINE VARIABLE opcStatus    AS CHARACTER NO-UNDO.     
    DEFINE VARIABLE iWareHouseNo AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCompanyCode AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType    AS CHARACTER NO-UNDO. 
    
   MESSAGE string(ipcShipTo)
   VIEW-AS ALERT-BOX.
   
   ASSIGN ipcShipTo = REPLACE(ipcShipTo, '"', "") NO-ERROR.
   
   MESSAGE "Este es el valor de ipiShipTo" ipcShipTo
   VIEW-AS ALERT-BOX. 
        
    ASSIGN                
      objTokenMgmt = NEW TokenManagement(INPUT ipcToken)
      objCommonSrc = NEW CommonSource(INPUT ipcToken)
      objCustOrder = NEW customerOrders(INPUT ipcToken).      
             
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /* Get multilingual message for blank language ID */
       
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
    
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvalidLang,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
    END. /* ELSE */ 
        
    /* Validate the token of the user on every request */
    
    IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c403InvalidToken,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcToken) EQ "":U OR.. */   
      
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
/*         MESSAGE "ipcUserId-2:" ipcUserId .*/
      /* Get multilingual message for blank user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200UserBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
                    
    /* validate the token */
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
                                        INPUT  ipcUserId,
                                        INPUT  ipcLangID, 
                                        OUTPUT cError,
                                        OUTPUT opcStatus,
                                        OUTPUT opcAppToken,
                                        OUTPUT opiStatusCode). 
                                                                                      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
    
       
    IF opcStatus EQ "Success":U THEN
    DO:
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.  
        FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE. 
        END. /* FOR FIRST CMPNY.. */           
      END.  /* FOR FIRST Token.. */
      
      IF cUserType NE  ConstantInitializer:cMobileUser THEN 
      DO:
          IF ipcCustNumber EQ "" OR ipcCustNumber EQ ? THEN 
          ASSIGN ipcCustNumber = ipcUserId.
      END.    
      
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(FIRST CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId)) THEN
        DO:
          /*Get multilingual message for invalid user */
/*           MESSAGE "ipcUserId:-5" ipcUserId .*/
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200InvalidUser,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
        DO:
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200CustBlank,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcCustNum) EQ ""*/ 
         
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
        END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
/*        IF AVAIL token AND Token.User-Type = "mobileuser":u   THEN*/
/*        DO:                                                       */
/*                                                                  */
/*        END.                                                      */
        /*ShipTo esta en l posicion quinta*/
        objCustOrder:customerOrderHistory(INPUT  ipcCustNumber,
          INPUT  ipcLangID,
          INPUT  cCompanyCode,                                          
          INPUT  ipiNoOfmonth,
          INPUT  ipcShipTo,
          INPUT  iWareHouseNo,
          INPUT  ipiSyncTime,
          INPUT  cUserType,
          OUTPUT oplcOrderHistData,
          OUTPUT opcError,
          OUTPUT opiStatusCode).
          
          //Gama Debug
    
    /*MESSAGE "Contenido de oplcOrderHistData 2" string(oplcOrderHistData)
    VIEW-AS ALERT-BOX.*/
          
        FIND CURRENT LastAPIHit EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF AVAILABLE LastAPIHit THEN 
        DO:
            
        END.
        IF opcError NE "":U THEN
          UNDO,THROW NEW AppError(opcError,1).
                                                       
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */ 
                                                        
      ELSE 
      DO:
          
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /* Get multilingual message for invalid user */
         
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200InvalidUser,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 
        
        
        objCustOrder:customerOrderHistory(INPUT  ipcUserId,
                                          INPUT  ipcLangID,
                                          INPUT  cCompanyCode,
                                          INPUT  ipiNoOfmonth,
                                          INPUT  ipcShipTo,
                                          INPUT  iWareHouseNo,
                                          INPUT  ipiSyncTime,
                                          INPUT  cUserType, 
                                          OUTPUT oplcOrderHistData,
                                          OUTPUT opcError,
                                          OUTPUT opiStatusCode).  
        //Gama Debug
    /*
    MESSAGE "Contenido de oplcOrderHistData 2" string(oplcOrderHistData)
    VIEW-AS ALERT-BOX.   */                                                           
         
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1). 
              
      END. /* ELSE IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                               
      ASSIGN 
        opiStatusCode = 200. 
                                               
    END. /* IF opcStatus EQ "Success":U THEN */

    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    
    
    
    FINALLY:
        
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
      
      IF VALID-OBJECT(objCustOrder) THEN  
        DELETE OBJECT objCustOrder.
      
      IF VALID-HANDLE(hSharedVar)   THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
               
    END FINALLY.                                                                               

  END METHOD.  
  
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID checkOutWrapper(INPUT ipcUserId                AS CHARACTER,
                                        INPUT ipcLangID                AS CHARACTER,
                                        INPUT ipcToken                 AS CHARACTER,
                                        INPUT ipcLongitude             AS CHARACTER,
                                        INPUT ipcLatitude              AS CHARACTER,
                                        INPUT ipcSigneeName            AS CHARACTER,
                                        INPUT iplcDigitalSign          AS LONGCHAR,
                                        INPUT ipcOrderDateTime         AS CHARACTER,
                                        INPUT ipdeAvailableCreditLimit AS DECIMAL,
                                        INPUT ipdeNetPaymentAmount     AS DECIMAL,
                                        INPUT DATASET             ipdsCheckoutData,
                                        OUTPUT oplcCheckoutData        AS LONGCHAR,
                                        OUTPUT opcAppToken             AS CHARACTER,
                                        OUTPUT opcError                AS CHARACTER,
                                        OUTPUT opiStatusCode           AS INTEGER):
        
    DEFINE VARIABLE objCheckout  AS CLASS     Checkout        NO-UNDO.
    DEFINE VARIABLE objTokenMgmt AS CLASS     TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc AS CLASS     CommonSource    NO-UNDO.
    
    DEFINE VARIABLE opcStatus    AS CHARACTER NO-UNDO.     
    DEFINE VARIABLE iWareHouseNo AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCompanyCode AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType    AS CHARACTER NO-UNDO.
    
    ASSIGN 
      objCheckout  = NEW Checkout(INPUT ipcToken)
      objTokenMgmt = NEW TokenManagement(INPUT ipcToken)
      objCommonSrc = NEW CommonSource(INPUT ipcToken).
           
    
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /* Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200LangBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
    
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                  INPUT  ConstantInitializer:c200InvalidLang,                                                              
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
    END.  /* ELSE */ 
    
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200UserBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
    
    IF TRIM(ipcSigneeName) EQ "":U THEN
    DO:
      /* Get multilingual message for blank signee name */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200SigneeNameBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.
    
    IF TRIM(ipcOrderDateTime) EQ "":U THEN
    DO:
      /* Get multilingual message for blank order's date & time */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200OrderDateTimeBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. 
                   
    /* validate the token */
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
                                          INPUT  ipcUserId,
                                          INPUT  ipcLangID, 
                                          OUTPUT cError,
                                          OUTPUT opcStatus,
                                          OUTPUT opcAppToken,
                                          OUTPUT opiStatusCode). 
                                                                                      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
            
    IF opcStatus EQ "Success":U THEN
    DO:
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.  
        FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE. 
        END. /* FOR FIRST CMPNY..*/           
      END. /* FOR FIRST Token..*/
      
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200InvalidUser,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        IF TRIM(ipcLongitude) EQ "":U OR TRIM(ipcLongitude) EQ ?  OR 
          TRIM(ipcLatitude)  EQ "":U OR TRIM(ipcLatitude)  EQ ? THEN
        DO:
          /* Get multilingual message for blank latitude and longitude data */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200LongLatBlank,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
            
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcLongitude) EQ ""*/
        
        /* Calling Checkout functionality */        
        objCheckout:checkoutMainBlock(INPUT ipcUserId,
                                      INPUT cCompanyCode,
                                      INPUT iWareHouseNo,
                                      INPUT ipcSigneeName,
                                      INPUT iplcDigitalSign,
                                      INPUT cUserType,
                                      INPUT ipcLangID,
                                      INPUT ipcOrderDateTime,
                                      INPUT ipdeAvailableCreditLimit,
                                      INPUT ipdeNetPaymentAmount,
                                      INPUT ipcLongitude,
                                      INPUT ipcLatitude,
                                      INPUT DATASET ipdsCheckoutData,
                                      OUTPUT oplcCheckoutData,
                                      OUTPUT cError,
                                      OUTPUT opiStatusCode).
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
                                                     
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                                                         
      ELSE 
      DO:
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 
                       
        /* Calling Checkout functionality */
        objCheckout:checkoutMainBlock(INPUT ipcUserId,
                                      INPUT cCompanyCode,
                                      INPUT iWareHouseNo,
                                      INPUT ipcSigneeName,
                                      INPUT iplcDigitalSign,
                                      INPUT cUserType,
                                      INPUT ipcLangID,
                                      INPUT ipcOrderDateTime,
                                      INPUT ipdeAvailableCreditLimit,
                                      INPUT ipdeNetPaymentAmount,
                                      INPUT ipcLongitude,
                                      INPUT ipcLatitude,
                                      INPUT DATASET ipdsCheckoutData,
                                      OUTPUT oplcCheckoutData,
                                      OUTPUT cError,
                                      OUTPUT opiStatusCode).                                        
         
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1). 
              
      END. /* ELSE IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                               
      ASSIGN 
        opiStatusCode = 200. 
                                               
    END. /* IF opcStatus EQ "Success":U THEN */
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
        
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
            
      IF VALID-OBJECT(objCheckout) THEN  
        DELETE OBJECT objCheckout.  
               
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
      
    END FINALLY.
             
  END METHOD.
  
  /*------------------------------------------------------------------------------
   Purpose: This method is used to add/update cart tables based on the products selected by a user.
 
   Input Parameters: 1.ipcUserId            - Username/Userid of a logged-in user.
                     2.ipcCustNumber        - Customer number for whom items are added in a cart.
                     3.ipcLangID            - Language-id.
                     4.iplcCartData         - Stores information related to products available in the cart
                     5.ipcToken             - Active User-token, 
                                          
   Output Parameters:1.oplcCartUniqueIds   - Unique id's of all the items added in the cart are stored.
                     2.opcAppToken         - It contains new token if old token expired 
                                             otherwise return old token.
                     3.opiStatusCode       - HTTP status code.          
                     4.opcError            - Errors if any.              
                     
   Notes:
  ------------------------------------------------------------------------------*/
  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID cartOperations(INPUT  ipcUserId            AS CHARACTER,
                                    INPUT  ipcCustNumber        AS CHARACTER,
                                    INPUT  ipcOperationType     AS CHARACTER,                                 
                                    INPUT  ipcLangID            AS CHARACTER,
                                    INPUT  ipcToken             AS CHARACTER,
                                    INPUT  TABLE                ttCartProducts,
                                    OUTPUT oplcCartUniqueIds    AS LONGCHAR, 
                                    OUTPUT opcAppToken          AS CHARACTER,                                   
                                    OUTPUT opiStatusCode        AS INTEGER,
                                    OUTPUT opcError             AS CHARACTER):
    
    DEFINE VARIABLE cCartOperationList AS CHARACTER INITIAL "a,r,m,e":U NO-UNDO.
    DEFINE VARIABLE outStatus          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCompnyCode        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iWareHouseNo       AS INTEGER   NO-UNDO.
    
    DEFINE VARIABLE objTokenMgmt       AS CLASS     TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc       AS CLASS     CommonSource    NO-UNDO.
    DEFINE VARIABLE objUserCart        AS CLASS     UserCart        NO-UNDO.
    
    //ErrorBanner que llega en ttcartProduct
 /*   OUTPUT TO C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\ContenidOttCartProducts.txt.
    FOR EACH ttCartProducts NO-LOCK:
        
        DISPLAY ttCartProducts WITH 1 col.
        
        END. 
    OUTPUT CLOSE. */
    
    ASSIGN 
      objUserCart  = NEW UserCart(INPUT ipcToken)
      objCommonSrc = NEW CommonSource(INPUT ipcToken)
      objTokenMgmt = NEW TokenManagement(INPUT ipcToken). 
        
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /*Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200LangBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U.. */  
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /*Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                  INPUT  ConstantInitializer:c200InvalidLang,                                                              
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE..) */        
    END. /* ELSE */ 
    
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user*/
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200UserBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.
    
    IF TRIM(ipcOperationType) EQ "":U OR TRIM(ipcOperationType) EQ ?  THEN
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200BlankCartOperation,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcSortBy) EQ "":U  */
    ELSE
    DO:
      IF LOOKUP(ipcOperationType,cCartOperationList) EQ 0 THEN
      DO: 
        /* Get multilingual message for invalid sorting criteria */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                  INPUT  ConstantInitializer:c200InvalidCartOperation,                                                              
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).                                          
      END. /* IF LOOKUP(ipcSortBy,ipcSortList).. */   
    END.
    
    IF VALID-OBJECT(objTokenMgmt) THEN
    DO:  
      /* This method returns a new token if the token is expired in case of mobile user, and
         in case of web user it returns same token if not expired. Otherwise status failure */     
      objTokenMgmt:loggedInUserTokenRenew(INPUT ipcToken,
                                            INPUT ipcUserId,                                         
                                            INPUT ipcLangID, 
                                            OUTPUT cError,
                                            OUTPUT outStatus,
                                            OUTPUT opcAppToken,  
                                            OUTPUT opiStatusCode).
                                        
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).                                          
    END.

    IF outStatus EQ "Success":U THEN
    DO:
      ASSIGN 
        ipcToken = opcAppToken.
        
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.    
        FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK NO-ERROR.
        IF AVAILABLE cmpny THEN 
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION 
            cCompnyCode  = CMPNY.COMPANY-CODE. 
                  
      END. /* FOR FIRST Token..*/  
      
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200InvalidUser,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
        DO:
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200CustBlank,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcCustNum) EQ ""*/
          
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
        END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
        
        objUserCart:performCartOperations(INPUT  ipcUserId,
                                          INPUT  ipcCustNumber, 
                                          INPUT  ipcOperationType,                                
                                          INPUT  ipcLangID,
                                          INPUT  TABLE ttCartProducts,
                                          INPUT  iWareHouseNo, 
                                          OUTPUT oplcCartUniqueIds,                                    
                                          OUTPUT opiStatusCode,
                                          OUTPUT cError).
        
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
                                                       
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */
       
      ELSE 
      DO:
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 
        
        objUserCart:performCartOperations(INPUT  "":U,
          INPUT  ipcUserId,
          INPUT  ipcOperationType,                                 
          INPUT  ipcLangID,
          INPUT  TABLE ttCartProducts,
          INPUT  iWareHouseNo, 
          OUTPUT oplcCartUniqueIds,                                    
          OUTPUT opiStatusCode,
          OUTPUT cError).                                        
         
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1). 
              
      END. /* ELSE IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                               
      ASSIGN 
        opiStatusCode = 200. 
                                               
    END. /* IF outStatus EQ "Success":U THEN */
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    

    FINALLY:
           
      IF VALID-OBJECT(objUserCart) THEN  
        DELETE OBJECT objUserCart.
      
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
      
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
//ErrorBanner
/*
OUTPUT TO "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\CapturaOutput-cartOperations.txt".
DISPLAY 
        "opcAppToken" opcAppToken skip
        "opiStatusCode" opiStatusCode skip
        "opcError" opcError.
OUTPUT CLOSE.   */    

/*  COPY-LOB oplcCartUniqueIds to file "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\oplcCartUniqueIds.txt".
    COPY-LOB opcAppToken       to file "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\opcAppToken.txt".
    COPY-LOB opiStatusCode     to file "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\opiStatusCode.txt".
    COPY-LOB opcError          to file "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\opcError.txt". */       
        
      
    END FINALLY.

  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose: This method is used to get all the products which are stored in the cart for a particular user.
 
   Input Parameters: 1.ipcUserId            - Username/Userid of a logged-in user.
                     2.ipcCustNumber        - Customer number for whom items need to be fetched.
                     3.ipcLangID            - Language-id.
                     4.ipcToken             - Active User-token.
                     5.ipiLastSyncTimestamp - Last sync timestamp.
                                         
   Output Parameters:1.oplcCartItems       - All the products stored in the cart for a particular user.
                     2.opcAppToken         - It contains new token if old token expired 
                                             otherwise return old token.
                     3.opiStatusCode       - HTTP status code.          
                     4.opcError            - Errors if any.              
                     
   Notes:
  ------------------------------------------------------------------------------*/
  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID fetchCartProducts(INPUT ipcUserId            AS CHARACTER,
                                        INPUT ipcCustNumber        AS CHARACTER,
                                        INPUT ipcLangID            AS CHARACTER,
                                        INPUT ipcToken             AS CHARACTER,
                                        INPUT ipiLastSyncTimestamp AS INT64,
                                        OUTPUT oplcCartItems       AS LONGCHAR,
                                        OUTPUT opcAppToken         AS CHARACTER,
                                        OUTPUT opiStatusCode       AS INTEGER,
                                        OUTPUT opcError            AS CHARACTER):
                                           
    DEFINE VARIABLE outStatus    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iWareHouseNo AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCompanyCode AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE objTokenMgmt AS CLASS     TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc AS CLASS     CommonSource    NO-UNDO.
    DEFINE VARIABLE objUserCart  AS CLASS     UserCart        NO-UNDO.
    
    ASSIGN 
      objUserCart  = NEW UserCart(INPUT ipcToken)
      objCommonSrc = NEW CommonSource(INPUT ipcToken)
      objTokenMgmt = NEW TokenManagement(INPUT ipcToken). 
        
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /*Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U.. */  
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /*Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE..) */        
    END. /* ELSE */ 
    
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user*/
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200UserBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.
    
    IF VALID-OBJECT(objTokenMgmt) THEN
    DO:  
      /* This method returns a new token if the token is expired in case of mobile user, and
         in case of web user it returns same token if not expired. Otherwise status failure */     
      objTokenMgmt:loggedInUserTokenRenew(INPUT ipcToken,
                                            INPUT ipcUserId,                                         
                                            INPUT ipcLangID, 
                                            OUTPUT cError,
                                            OUTPUT outStatus,
                                            OUTPUT opcAppToken,  
                                            OUTPUT opiStatusCode).
                                        
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).                                         
    END.
    
    IF outStatus EQ "Success":U THEN
    DO:
        
      ASSIGN 
        ipcToken = opcAppToken.  
      
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.
        FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK NO-ERROR.
        IF AVAILABLE CMPNY THEN 
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE.
                       
      END. /* FOR FIRST Token..*/
      
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
        DO:
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200CustBlank,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcCustNum) EQ ""*/  
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
        END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
        
        objUserCart:getCartProducts(INPUT ipcUserId,
          INPUT ipcCustNumber,
          INPUT ipcLangID,
          INPUT cCompanyCode,
          INPUT cUserType,
          INPUT iWareHouseNo,
          INPUT ipiLastSyncTimestamp,
          OUTPUT oplcCartItems,
          OUTPUT opiStatusCode,
          OUTPUT cError).
          
        
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
                                                       
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */ 
      ELSE 
      DO:
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                   
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 
        
        objUserCart:getCartProducts(INPUT "":U,
          INPUT ipcUserId,
          INPUT ipcLangID,
          INPUT cCompanyCode,
          INPUT cUserType,
          INPUT iWareHouseNo,
          INPUT ipiLastSyncTimestamp,
          OUTPUT oplcCartItems,
          OUTPUT opiStatusCode,
          OUTPUT cError).                                  
         
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1). 
              
      END. /* ELSE IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                               
      ASSIGN 
        opiStatusCode = 200. 
                                               
    END. /* IF outStatus EQ "Success":U THEN */
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.

    FINALLY:
           
      IF VALID-OBJECT(objUserCart) THEN  
        DELETE OBJECT objUserCart.
      
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
      
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
            
    END FINALLY.

  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose: This method supports free flow product search for products.
 
   Input Parameters: 1.ipcUserId            - Username/Userid of a logged-in user.
                     2.ipcCustNumber        - Customer number for whom item price is derived for a particular item.
                     3.ipcSearchKeywords    - stores search keywords provided by the user                     
                     4.ipcToken             - Active User-token.
                     5.ipcLangID            - Language-id.
                                       
   Output Parameters:1.opcAppToken         - It contains new token if old token expired 
                                             otherwise return old token.
                     2.opiTotalrecords     - Total no of records found satisfying the search criteria.        
                     3.opcError            - Errors if any. 
                     4.opiStatusCode       - HTTP status code. 
                     5.oplcSearchData      - Returns the list of all the matched products provided in the search box.             
                     
   Notes:
    ------------------------------------------------------------------------------*/

  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID freeFormProductSearchWrapper(INPUT ipcUserId         AS CHARACTER,
                                                    INPUT ipcCustNumber     AS CHARACTER,
                                                    INPUT ipcSearchKeywords AS LONGCHAR,
                                                    INPUT ipcToken          AS CHARACTER,
                                                    INPUT ipcLangId         AS CHARACTER,                                                  
                                                    OUTPUT opcAppToken      AS CHARACTER,
                                                    OUTPUT opiTotalrecords  AS INTEGER,
                                                    OUTPUT opcError         AS CHARACTER,
                                                    OUTPUT opiStatusCode    AS INTEGER, 
                                                    OUTPUT oplcSearchData   AS LONGCHAR):
                                                        
    DEFINE VARIABLE objCategryFiltrItem AS CLASS     CategoryFilterItem NO-UNDO.
  
    DEFINE VARIABLE objTokenMgmt        AS CLASS     TokenManagement    NO-UNDO.
    DEFINE VARIABLE objCommonSrc        AS CLASS     CommonSource       NO-UNDO. 

    DEFINE VARIABLE opcStatus           AS CHARACTER NO-UNDO.     
    DEFINE VARIABLE iWareHouseNo        AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCompanyCode        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType           AS CHARACTER NO-UNDO.
        
    ASSIGN 
      objCategryFiltrItem = NEW CategoryFilterItem(INPUT ipcToken)          
      objTokenMgmt        = NEW TokenManagement(INPUT ipcToken)
      objCommonSrc        = NEW CommonSource(INPUT ipcToken).      
             
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /* Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200LangBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                  INPUT  ConstantInitializer:c200InvalidLang,                                                              
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
    END.  /* ELSE */ 
        
    /* Validate the token of the user on every request */
    IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c403InvalidToken,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcToken) EQ "":U OR.. */   
        
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200UserBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
                    
    /* validate the token */
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
                                          INPUT  ipcUserId,
                                          INPUT  ipcLangID, 
                                          OUTPUT cError,
                                          OUTPUT opcStatus,
                                          OUTPUT opcAppToken,
                                          OUTPUT opiStatusCode). 
                                                                                      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
    
        
    IF opcStatus EQ "Success":U THEN
    DO:
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.  
        FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE. 
        END. /* FOR FIRST CMPNY..*/           
      END. /* FOR FIRST Token..*/
      
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200InvalidUser,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
        DO:
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200CustBlank,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcCustNum) EQ ""*/  
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
                                      INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
                                      OUTPUT cError,
                                      OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
        END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
        
        objCategryFiltrItem:freeformProductSearch(INPUT  ipcCustNumber,
                                                  INPUT  ipcSearchKeywords,
                                                  INPUT  cCompanyCode,
                                                  INPUT  iWareHouseNo,
                                                  INPUT  ipcLangID,
                                                  OUTPUT opiTotalRecords,
                                                  OUTPUT opiStatusCode,
                                                  OUTPUT cError,
                                                  OUTPUT oplcSearchData).
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
                                                       
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */                                                   
      ELSE 
      DO:
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER).. */
        
        objCategryFiltrItem:freeformProductSearch(INPUT  ipcUserId,
          INPUT  ipcSearchKeywords,
          INPUT  cCompanyCode,
          INPUT  iWareHouseNo,
          INPUT  ipcLangID,
          OUTPUT opiTotalRecords,
          OUTPUT opiStatusCode,
          OUTPUT cError,
          OUTPUT oplcSearchData).                                        
         
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1). 
              
      END. /* ELSE IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                               
      ASSIGN 
        opiStatusCode = 200. 
                                               
    END. /* IF opcStatus EQ "Success":U THEN */

    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
        
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
            
      IF VALID-OBJECT(objCategryFiltrItem) THEN  
        DELETE OBJECT objCategryFiltrItem.  
               
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
               
    END FINALLY.                                                                               

  END METHOD.
  
  
  /*------------------------------------------------------------------------------------
   Purpose: This method is fetching only updated records of customers i.e. Any type of 
            CRUD operation is performed on CCSMS which resulted in modifications of 
            customers records, then it will give only those affected / modified records.
            
   Input Parameters: 1.ipiLastSyncTimestamp - Last sync timestamp,
                     2.ipcToken             - User-token,
                     3.ipcSalesRepId        - Salesrep id for which customers to be fetched, 
                     4.ipcLangID            - Language-id,
                     
   Output Parameters:1.opcError            - Errors if any,
                     2.opiStatusCode       - HTTP status code
                     3.opcAppToken         - It contains new token if old token expired 
                                             otherwise return old token
                     4.ttCustomer          - Table containes modified customer records
   Notes: 
  ---------------------------------------------------------------------------------------*/
  
  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID customerSync(INPUT ipiLastSyncTimestamp  AS INT64,
                                  INPUT ipcToken              AS CHARACTER,
                                  INPUT ipcSalesRepId         AS CHARACTER,        
                                  INPUT ipcLangID             AS CHARACTER,
                                  OUTPUT opcError             AS CHARACTER,
                                  OUTPUT opiStatusCode        AS INTEGER,
                                  OUTPUT opcAppToken          AS CHARACTER,
                                  OUTPUT DATASET opdsSalespersonData):
                                            
    DEFINE VARIABLE objCommonSrc  AS CLASS     CommonSource          NO-UNDO.
    DEFINE VARIABLE objTokenMgmt  AS CLASS     TokenManagement       NO-UNDO.
    DEFINE VARIABLE objCustomer   AS CLASS     SalesmanCustomersData NO-UNDO.
    
    DEFINE VARIABLE iNowTimeStamp AS INT64     NO-UNDO.
    DEFINE VARIABLE outStatus     AS CHARACTER NO-UNDO.
    
    ASSIGN 
      objCommonSrc = NEW CommonSource(INPUT ipcToken)
      objTokenMgmt = NEW TokenManagement(INPUT ipcToken)
      objCustomer  = NEW SalesmanCustomersData(INPUT ipcToken).
    
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /*Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U.. */
    
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /*Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE..) */        
    END. /* ELSE */  
    
    /* get current time stamp */
    IF VALID-OBJECT(objCommonSrc) THEN 
    DO:
      iNowTimeStamp = objCommonSrc:getTimestamp(INPUT DATETIME-TZ(NOW),
        INPUT ipcLangID,
        OUTPUT cError,      
        OUTPUT opiStatusCode).
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).                                                
    END.                                                
    
    /* Check whether the recieved timestamp is valid */                                               
    IF ipiLastSyncTimestamp GT iNowTimeStamp THEN 
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidTimeStamp,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).                               
    END.
      
    IF TRIM(ipcSalesRepId) EQ "":U OR TRIM(ipcSalesRepId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user*/
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /*IF TRIM(ipcSalesRepId) EQ ""..*/  
    ELSE
    DO: 
      IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcSalesRepId) NO-LOCK) THEN
      DO:
        /* Get multilingual message for invalid user*/
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidUser,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                  
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /*  IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID... */      
    END. /* ELSE */
                                                                                                                                 
    IF VALID-OBJECT(objTokenMgmt) THEN
    DO:  
      /* This method returns a new token if the token is expired in case of mobile user, and
         in case of web user it returns same token if not expired. Otherwise status failure */     
      objTokenMgmt:loggedInUserTokenRenew(INPUT ipcToken,
        INPUT ipcSalesRepId,                                         
        INPUT ipcLangID, 
        OUTPUT cError,
        OUTPUT outStatus,
        OUTPUT opcAppToken,  
        OUTPUT opiStatusCode).
                                        
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).                                        
    END.
    
    FOR EACH CCSMS WHERE CCSMS.SALES-REP-ID EQ ipcSalesRepId AND CCSMS.timestamp GT ipiLastSyncTimestamp NO-LOCK:
          
      CREATE ttCustomer.
            
      ASSIGN 
        ttCustomer.customerNumber = CCSMS.CUST-NUMBER
        ttCustomer.customerName   = REPLACE(CCSMS.CUST-NAME,"'", "") //CCSMS.CUST-NAME
        ttCustomer.secondName     = CCSMS.SECOND-NAME             
        ttCustomer.totalSales     = CCSMS.YTD-SALES
        ttCustomer.customerType   = CCSMS.CUST-TYPE
        ttCustomer.creditLimit    = CCSMS.CREDIT-LIMIT
        ttCustomer.phoneNumber    = CCSMS.PHONE-NUMBER
        ttCustomer.emailId        = CCSMS.E-MAIL
        ttCustomer.priceList      = CCSMS.PRICE-LIST
        ttCustomer.poRequired     = IF CCSMS.ORG-TYPE MATCHES "P" THEN TRUE ELSE FALSE NO-ERROR. 
             
      /* Get Picture */
      FILE-INFO:FILE-NAME = ConstantInitializer:cCustomerPicDir + "/" + ttCustomer.customerNumber + ".jpg".
      IF FILE-INFO:FULL-PATHNAME NE ? THEN
        ASSIGN ttCustomer.customer_picture = ConstantInitializer:cCustomerPicDir + ttCustomer.customerNumber + ".jpg".
      ELSE
        ASSIGN ttCustomer.customer_picture = "".
      
      /* Get the billing address of the customer if exists */
      IF (CCSMS.ADDRESS-L1 NE "":U OR CCSMS.ADDRESS-L2 NE "":U OR CCSMS.ADDRESS-L3 NE "":U ) THEN
      DO:
        CREATE ttCustBillingAddress.  
        ASSIGN   
          ttCustBillingAddress.customerNumber = CCSMS.CUST-NUMBER         
          ttCustBillingAddress.billingAdd1    = CCSMS.ADDRESS-L1
          ttCustBillingAddress.billingAdd2    = CCSMS.ADDRESS-L2
          ttCustBillingAddress.billingAdd3    = CCSMS.ADDRESS-L3
          ttCustBillingAddress.billingState   = CCSMS.POSTAL-STATE
          ttCustBillingAddress.billingCity    = CCSMS.postal-city      
          ttCustBillingAddress.billingZip     = CCSMS.POSTAL-ZIP.    
      END. 
                 
      /*Get the multiple shipping addresses of the customer if exists*/
      objCustomer:getCustShippingAddress(INPUT  CCSMS.CUST-NUMBER,
        INPUT "",
        OUTPUT cError,
        OUTPUT TABLE ttCustShippingAddress APPEND).                                                                                                                                                                                                    
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).      
     
    END. /* FOR EACH CCSMS  */
    
    ASSIGN 
      opiStatusCode = 200.
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
      
      IF VALID-OBJECT(objCustomer) THEN  
        DELETE OBJECT objCustomer.  
               
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
    
    END FINALLY.
        
  END METHOD.
  
  /*------------------------------------------------------------------------------
   Purpose: This method is used to get all the items of a particular category.
            In case of mobile user, this method will provide only the last modified items. 
   Input Parameters: 1.ipcUserId            - Username/Userid of a logged-in user.
                     2.ipiLastSyncTimestamp - Last sync timestamp.
                     3.ipcCustNum           - Customer number for whom items to be fetched.
                     4.ipcClassCode         - Category id for which items to be fetched.
                     5.ipcToken             - Active User-token, 
                     6.ipcLangID            - Language-id.
                     
   Output Parameters:1.oplcItemsJSON       - Containing list of all the items.
                     2.opcAppToken         - It contains new token if old token expired 
                                             otherwise return old token.
                     3.opcError            - Errors if any.
                     4.opiStatusCode       - HTTP status code.                        
                     
   Notes: 
  ------------------------------------------------------------------------------*/
  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID getCategoryItems(INPUT  ipcUserId            AS CHARACTER,
                                        INPUT  ipiLastSyncTimestamp AS INT64,
                                        INPUT  ipcCustNum           AS CHARACTER,
                                        INPUT  ipcClassCode         AS CHARACTER,
                                        INPUT  ipcToken             AS CHARACTER,
                                        INPUT  ipcLangId            AS CHARACTER,
                                        OUTPUT oplcItemsJSON        AS LONGCHAR,
                                        OUTPUT opcAppToken          AS CHARACTER,
                                        OUTPUT opcError             AS CHARACTER,                                      
                                        OUTPUT opiStatusCode        AS INTEGER):
    
    DEFINE VARIABLE objCommonSrc  AS CLASS     CommonSource       NO-UNDO.  
    DEFINE VARIABLE objCategory   AS CLASS     CategoryFilterItem NO-UNDO.
    DEFINE VARIABLE objTokenMgmt  AS CLASS     TokenManagement    NO-UNDO.
    DEFINE VARIABLE itemJsonArr   AS CLASS     JsonArray          NO-UNDO.
    DEFINE VARIABLE itemJsonObj   AS CLASS     JsonObject         NO-UNDO.
    
    DEFINE VARIABLE outStatus     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE opcItem       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iWareHouseNo  AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iNowTimeStamp AS INT64     NO-UNDO.
    DEFINE VARIABLE lTopSeller    AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE cCompnyCode   AS CHARACTER NO-UNDO.
    
    
    ASSIGN 
      objCommonSrc = NEW CommonSource(INPUT ipcToken)
      objTokenMgmt = NEW TokenManagement(INPUT ipcToken)
      objCategory  = NEW CategoryFilterItem(INPUT ipcToken)
      itemJsonArr  = NEW JsonArray().
    
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /*Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U.. */  
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /*Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE..) */        
    END. /* ELSE */ 
    
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user*/
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.
        
    /* get current time stamp */
    IF VALID-OBJECT(objCommonSrc) THEN 
    DO:
      ASSIGN 
        iNowTimeStamp = objCommonSrc:getTimestamp(INPUT DATETIME-TZ(NOW),
                                                       INPUT ipcLangID,
                                                       OUTPUT cError,      
                                                       OUTPUT opiStatusCode).
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).                                                
    END.                                                
    
    /* Check whether the recieved timestamp is valid */                                               
    IF ipiLastSyncTimestamp GT iNowTimeStamp THEN 
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidTimeStamp,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
                           
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).                               
    END.
    
    IF TRIM(ipcClassCode) EQ "":U OR TRIM(ipcClassCode) EQ ? THEN
    DO:
      /* Get multilingual message for blank category */
      objCommonSrc:getMessages(INPUT  ipcLangId,
        INPUT  ConstantInitializer:c200CatBlank,
        OUTPUT cError,
        OUTPUT opiStatusCode).
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).

    END. /* IF TRIM(ipcClassCode) EQ "":U.. */
    ELSE
    DO:
      IF NOT CAN-FIND (IVBRAND WHERE IVBRAND.CLASS-CODE EQ TRIM(ipcClassCode) NO-LOCK) THEN
      DO:
        /* Get multilingual message for invalid category */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidCategory,
          OUTPUT cError,
          OUTPUT opiStatusCode).

        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
      END.  /*END of IF NOT CAN-FIND ( IVBRAND WHERE..*/
 
    END.  /*Else part of IF TRIM(ipcClassCode) EQ "":U..*/
    
    IF VALID-OBJECT(objTokenMgmt) THEN
    DO:  
      /* This method returns a new token if the token is expired in case of mobile user, and
         in case of web user it returns same token if not expired. Otherwise status failure */     
      objTokenMgmt:loggedInUserTokenRenew(  INPUT ipcToken,
                                            INPUT ipcUserId,                                         
                                            INPUT ipcLangID, 
                                            OUTPUT cError,
                                            OUTPUT outStatus,
                                            OUTPUT opcAppToken,  
                                            OUTPUT opiStatusCode).
                                        
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).                                         
    END.
   // MESSAGE "GetCategoryItems-1" .
    IF outStatus EQ "Success":U THEN
    DO: 
      ASSIGN 
        ipcToken = opcAppToken.
      /* To find the warehouse number and user-type associated with the logged-in user */
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.    
        FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK NO-ERROR.
        IF AVAILABLE cmpny THEN 
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompnyCode  = CMPNY.COMPANY-CODE. 
                  
      END. /* FOR FIRST Token..*/ 
      
       
      /* Find top-seller item for a specific category by calling topSellerItem(..) method*/
     
     /* objCategory:topSellerItem(INPUT ipcClassCode,
                                INPUT cCompnyCode,
                                OUTPUT opcItem).  */                               
         
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /* Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  "200_invalid_user":U,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 
        
        IF TRIM(ipcCustNum) EQ "":U OR TRIM(ipcCustNum) EQ ? THEN
        DO:
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages( INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200CustBlank,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcCustNum) EQ ""*/  
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNum) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
        END. /* ELSE OF TRIM(ipcCustNum) EQ "":U OR TRIM(ipcCustNum) EQ ? */
       /*  IF AVAIL token AND Token.User-Type = "mobileuser":u   THEN 
        DO:
            FIND FIRST LastAPIHit WHERE LastAPIHit.API_Name    EQ "getCategoryItems":U 
                                    AND LastAPIHit.user_id     EQ Token.User-ID  
                                    AND LastAPIHit.ext_char[1] EQ Token.Device-ID EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
            IF AVAILABLE LastAPIHit THEN                                     
              ipiLastSyncTimestamp = LastAPIHit.lasthittime.
            ELSE 
            DO:
               CREATE LastAPIHit.
               ASSIGN LastAPIHit.API_Name    = "getCategoryItems":U
                      LastAPIHit.user_id     = Token.User-ID 
                      LastAPIHit.token       = Token.Token
                      LastAPIHit.ext_char[1] = Token.Device-ID
                      ipiLastSyncTimestamp   = 0.
                      
            END. 
            IF AVAILABLE LastAPIHit THEN 
              ASSIGN LastAPIHit.lasthittime  = INTERVAL(NOW, dtzStartTime, "milliseconds":U).
                
            FIND CURRENT LastAPIHit NO-LOCK NO-ERROR.     
        END. */
        /* Fetching items based on the class-code and last sync timestamp */  
                 
        FOR EACH cinv1 WHERE CINV1.CLASS-CODE       EQ     ipcClassCode         
                         AND CINV1.ITEM-NUMBER      BEGINS cCompnyCode
                         //AND CINV1.COMPANY-CODE EQ cCompnyCode
                         // AND NOT CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U  
                         NO-LOCK: 
         IF CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U OR CINV1.LINE-UP = "D":U OR CINV1.LINE-UP EQ "W":U OR CINV1.LINE-UP EQ "X":U THEN NEXT.
          IF CINV1.ITEM-NUMBER EQ opcItem THEN
            ASSIGN lTopSeller = TRUE.
          ELSE
            ASSIGN lTopSeller = FALSE.
          /* This code is to check if any customer has contract pricing. Requested by SabaTier */
          FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNum) NO-LOCK NO-ERROR.
          
          IF AVAILABLE CCSMS AND CCSMS.CONTRACT-IND EQ "A" THEN 
          DO:
           IF NOT CAN-FIND(CINV3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER AND CINV3.PRICE-LIST EQ CCSMS.PRICE-LIST ) THEN NEXT.
           
          END. 
          FIND FIRST CINV2 WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
                             AND CINV2.WAREHOUSE-NO EQ iWareHouseNo NO-LOCK NO-ERROR.
/*            FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"*/
/*                                 AND PARAMFL.COMPANY-CODE = cCompnyCode                  */
/*                                 AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.        */
/*            IF AVAILABLE paramfl AND AVAILABLE cinv2 THEN                                */
/*            DO:                                                                          */
/*                IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN NEXT.                 */
/*            END.                                                                         */
          objCategory:getCategoryAllItems(  INPUT  ipcCustNum,
                                            INPUT  CINV1.CLASS-CODE,
                                            INPUT  CINV1.ITEM-NUMBER,
                                            INPUT  CINV1.DESCRIPTION,
                                            INPUT  CINV1.QTY-ONHAND,
                                            /*INPUT  CINV1.PICTURE,*/
                                            INPUT SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1),
                                            INPUT  CINV1.FABRIC,
                                            INPUT  CINV1.FAMILY,
                                            INPUT  CINV1.VENDOR-NO, 
                                            INPUT  CINV1.MAKE,
                                            INPUT  CINV1.BY-SIZE, 
                                            INPUT  CINV1.BY-COLOR,
                                            INPUT  lTopSeller,
                                            INPUT  cCompnyCode,
                                            INPUT  iWareHouseNo,
                                            OUTPUT itemJsonObj).
                                            
/*          itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).         */
/*          itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).*/
                             
          itemJsonArr:ADD(INPUT itemJsonObj).                                 
        END. /* FOR EACH cinv1... */
      END. /* IF userType is Mobile user */
      
      ELSE /* Webuser */
      DO: 
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 

        /* Fetching items based on the class-code */ 
        FOR EACH cinv1 WHERE CINV1.CLASS-CODE       EQ     ipcClassCode   
                         AND CINV1.ITEM-NUMBER  BEGINS cCompnyCode         
                       // AND CINV1.COMPANY-CODE EQ cCompnyCode
                        NO-LOCK:              
        /* FOR EACH CINV1 WHERE CINV1.CLASS-CODE   EQ     ipcClassCode        AND
                             CINV1.ITEM-NUMBER  BEGINS cCompnyCode         AND
                         NOT CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U NO-LOCK: */
          
          IF CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U OR CINV1.LINE-UP = "D":U OR CINV1.LINE-UP = "W":U OR CINV1.LINE-UP = "X":U THEN NEXT.
          
          IF CINV1.ITEM-NUMBER EQ opcItem THEN
            ASSIGN lTopSeller = TRUE.
          ELSE
            ASSIGN lTopSeller = FALSE.
           /* This code is to check if any customer has contract pricing. Requested by SabaTier */
          FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK NO-ERROR.
          
          IF AVAILABLE CCSMS AND CCSMS.CONTRACT-IND EQ "A" THEN 
          DO:
           IF NOT CAN-FIND(CINV3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER AND CINV3.PRICE-LIST EQ CCSMS.PRICE-LIST ) THEN NEXT.
           
          END.   
          FIND FIRST CINV2 WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
                             AND CINV2.WAREHOUSE-NO EQ iWareHouseNo NO-LOCK NO-ERROR.
/*            FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"*/
/*                                 AND PARAMFL.COMPANY-CODE = cCompnyCode                  */
/*                                 AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.        */
/*            IF AVAILABLE paramfl AND AVAILABLE cinv2 THEN                                */
/*            DO:                                                                          */
/*                IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN NEXT.                 */
/*            END.                                                                         */
          objCategory:getCategoryAllItems(INPUT  ipcUserId,
            INPUT  CINV1.CLASS-CODE,
            INPUT  CINV1.ITEM-NUMBER,
            INPUT  CINV1.DESCRIPTION,
            INPUT  CINV1.QTY-ONHAND,
            /*INPUT  CINV1.PICTURE,*/
            INPUT SUBSTRING(CINV1.picture, R-INDEX(cinv1.picture, "\" ) + 1),
            INPUT  cinv1.fabric,
            INPUT  cinv1.family,
            INPUT  cinv1.vendor-no, 
            INPUT  cinv1.make,
            INPUT  cinv1.by-size,
            INPUT  CINV1.BY-COLOR,
            INPUT  lTopSeller,
            INPUT  cCompnyCode,
            INPUT  iWareHouseNo,
            OUTPUT itemJsonObj).
          
          itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
          itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).      
                                        
          itemJsonArr:ADD(INPUT itemJsonObj).
        END. /* FOR EACH cinv1 WHERE cinv1.class-code...*/
                                              
      END. /* ELSE OF cUserType EQ ConstantInitializer:cMobileUser */               
  
      ASSIGN 
        oplcItemsJSON = itemJsonArr:GetJsonText()
        opiStatusCode = 200.
    END. /* IF outStatus EQ "Success":U THEN */
    
    CATCH errorObj AS AppError:
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.

    FINALLY:
      INPUT CLOSE.  
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
      IF VALID-OBJECT(objTokenMgmt) THEN
        DELETE OBJECT objTokenMgmt.
      IF VALID-OBJECT(objCategory)  THEN
        DELETE OBJECT objCategory.
      IF VALID-OBJECT(itemJsonArr)  THEN
        DELETE OBJECT itemJsonArr. 
      IF VALID-OBJECT(itemJsonObj)  THEN
        DELETE OBJECT itemJsonObj.             
      
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
      
    END FINALLY.

  END METHOD.
  /*------------------------------------------------------------------------------------
   Purpose: This method is used get the required categories with their possible filters.
            
   Input Parameters:1.ipcCatId      - Category Id of the category,
                    2.ipcToken      - User-token,
                    3.ipcUserId     - Selected user for which the categories have to be populated.
                    4.ipcLangID     - Selected Language-id by the user,
                     
   Output Parameters:1.opcError      - Errors if any,
                     2.opiStatusCode - HTTP status code
                     3.opcAppToken   - It contains new token if old token expired 
                                       otherwise return old token
                     4.oplcSetupJSON - Contains JSON response of the category
                                         
   Notes:
   -------------------------------------------------------------------------------------*/
  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID getCategoriesFilters(INPUT ipcCatId        AS CHARACTER,
                                          INPUT ipcToken        AS CHARACTER,
                                          INPUT ipcUserId       AS CHARACTER,
                                          INPUT ipcLangId       AS CHARACTER,
                                          OUTPUT opcError       AS CHARACTER,
                                          OUTPUT opiStatusCode  AS INTEGER,
                                          OUTPUT opcAppToken    AS CHARACTER,
                                          OUTPUT oplcSetupJSON  AS LONGCHAR):
          
    DEFINE VARIABLE objCommonSrc AS CLASS     CommonSource       NO-UNDO.  
    DEFINE VARIABLE objCategory  AS CLASS     CategoryFilterItem NO-UNDO.
    DEFINE VARIABLE objTokenMgmt AS CLASS     TokenManagement    NO-UNDO.
    
    DEFINE VARIABLE outStatus              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCompanyCode           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iWareHouseNo           AS INTEGER   NO-UNDO.
    
    
    
      
    ASSIGN 
      objCommonSrc = NEW CommonSource(INPUT ipcToken)
      objTokenMgmt = NEW TokenManagement(INPUT ipcToken)
      objCategory  = NEW CategoryFilterItem(INPUT ipcToken).
               
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /*Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200LangBlank,
                                OUTPUT cError,
                                OUTPUT opiStatusCode).

      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U.. */
    
    ELSE
    DO:   
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:   
        /*Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                  INPUT  ConstantInitializer:c200InvalidLang,
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).

        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE..) */
    END. /* ELSE of IF TRIM(ipcLangID) EQ "":U..  */

    IF TRIM(ipcCatId) EQ "":U OR TRIM(ipcCatId) EQ ? THEN
    DO:
      /*Get multilingual message for blank category */
      objCommonSrc:getMessages( INPUT  ipcLangId,
                                INPUT  ConstantInitializer:c200CatBlank,
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).

    END. /* IF TRIM(ipcCatId) EQ "":U.. */
    
    ELSE
    DO:
      IF ipcCatId NE "*":U AND NOT CAN-FIND (IVBRAND WHERE IVBRAND.class-code EQ TRIM(ipcCatId) NO-LOCK) THEN
      DO:
        /* Get multilingual message for invalid category */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                  INPUT  ConstantInitializer:c200InvalidCategory,
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).

        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
      END.  /*END - IF NOT CAN-FIND ( IVBRAND WHERE..*/
 
    END.  /*Else part of IF TRIM(ipcCatId) EQ "":U..*/
    
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user*/
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200UserBlank,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /*IF TRIM(ipcSalesRepId) EQ ""..*/  
              
    IF VALID-OBJECT(objTokenMgmt) THEN
    DO:
      /* This method returns a new token if the token is expired in case of mobile user, and
         in case of web user it returns same token if not expired. Otherwise status failure */       
      objTokenMgmt:loggedInUserTokenRenew(INPUT ipcToken,
                                            INPUT ipcUserId,                                         
                                            INPUT ipcLangID, 
                                            OUTPUT cError,
                                            OUTPUT outStatus,
                                            OUTPUT opcAppToken,  
                                            OUTPUT opiStatusCode).
                                        
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).                                        
    END.
    
    IF outStatus EQ "Success":U THEN
    DO: 
      ASSIGN 
        ipcToken = opcAppToken.
      /* To find the warehouse number and user-type associated with the logged-in user */
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:    
        FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE. 
        END. /* FOR FIRST CMPNY..*/           
      END. /* FOR FIRST Token..*/   
    
         
      objCategory:getData(  INPUT  ipcCatId,
                            INPUT  cCompanyCode,
                            INPUT  iWareHouseNo,
                            OUTPUT cError,
                            OUTPUT oplcSetupJSON ).
        
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).   
    
      ASSIGN 
        opiStatusCode = 200.
    
    END. /* IF outStatus EQ "Success":U THEN */
    
    CATCH errorObj AS AppError:
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.

    FINALLY:
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
      IF VALID-OBJECT(objTokenMgmt) THEN
        DELETE OBJECT objTokenMgmt.  
      IF VALID-OBJECT(objCategory)  THEN
        DELETE OBJECT objCategory.  
    
      IF VALID-HANDLE(hSharedVar)   THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
    
    END FINALLY.

  END METHOD.

  /*------------------------------------------------------------------------------
  Purpose:
  Notes:
 ------------------------------------------------------------------------------*/
  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID invoiceHistoryWrapper(INPUT ipcToken         AS CHARACTER,
                                           INPUT ipcCustNumber    AS CHARACTER,
                                           INPUT ipcUserID        AS CHARACTER,
                                           INPUT ipcLangId        AS CHARACTER,
                                           INPUT ipiLastSyncTimestamp AS INT64,
                                           OUTPUT opcError        AS CHARACTER,
                                           OUTPUT opiStatusCode   AS INTEGER,
                                           OUTPUT opcAppToken     AS CHARACTER,
                                           OUTPUT oplcInvoiceData AS LONGCHAR /*,
                                           OUTPUT ipcLastRowID    AS CHARACTER*/):
    
    /* ASSIGN ipcNextBatchRowId = "". /*3rd batch */ */
    DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc      AS CLASS     CommonSource    NO-UNDO. 
    DEFINE VARIABLE objInvoiceHistory AS CLASS     InvoiceHistory  NO-UNDO.

    DEFINE VARIABLE opcStatus         AS CHARACTER NO-UNDO.     
    DEFINE VARIABLE iWareHouseNo      AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCompanyCode      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType         AS CHARACTER NO-UNDO. 
       
    // MESSAGE "ipcCustNumber: " ipcCustNumber   "ipcUserID:" ipcUserID. 
    ASSIGN                
      objTokenMgmt      = NEW TokenManagement(INPUT ipcToken)
      objCommonSrc      = NEW CommonSource(INPUT ipcToken)
      objInvoiceHistory = NEW InvoiceHistory(INPUT ipcToken).      
             
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /* Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
    END. /* ELSE */ 
        
    /*Validate the token of the user on every request*/
    IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c403InvalidToken,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcToken) EQ "":U OR.. */   
        
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
                    
    /* validate the token */
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
      INPUT  ipcUserId,
      INPUT  ipcLangID, 
      OUTPUT cError,
      OUTPUT opcStatus,
      OUTPUT opcAppToken,
      OUTPUT opiStatusCode). 
                                                                                      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
    
        
    IF opcStatus EQ "Success":U THEN
    DO:
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.  
        FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE. 
        END. /* FOR FIRST CMPNY..*/           
      END. /* FOR FIRST Token..*/
      
      IF AVAIL token AND Token.User-Type = "mobileuser":u   THEN 
        DO:
          /* FIND FIRST LastAPIHit WHERE LastAPIHit.API_Name    EQ "invoiceHistoryWrapper":U 
                                    AND LastAPIHit.user_id     EQ Token.User-ID  
                                    AND LastAPIHit.ext_char[1] EQ Token.Device-ID EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
            IF AVAILABLE LastAPIHit THEN                                     
              ipiLastSyncTimestamp = LastAPIHit.lasthittime.
            ELSE 
            DO:
               CREATE LastAPIHit.
               ASSIGN LastAPIHit.API_Name    = "invoiceHistoryWrapper":U
                      LastAPIHit.user_id     = Token.User-ID 
                      LastAPIHit.token       = Token.Token
                      LastAPIHit.ext_char[1] = Token.Device-ID
                      ipiLastSyncTimestamp   = 0.
                      
            END. 
            IF AVAILABLE LastAPIHit THEN 
              ASSIGN LastAPIHit.lasthittime  = INTERVAL(NOW, dtzStartTime, "milliseconds":U).
                
            FIND CURRENT LastAPIHit NO-LOCK NO-ERROR.     */
        END. 
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
        DO:
          
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200CustBlank,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcCustNum) EQ ""*/  
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
        END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
        
        objInvoiceHistory:getCustomerInvoices(INPUT  ipcCustNumber,
                                              INPUT  ipcUserId,
                                              INPUT  ipcLangID,
                                              INPUT  iWareHouseNo,
                                              INPUT cUserType,
                                              INPUT ipiLastSyncTimestamp,
                                              OUTPUT oplcInvoiceData,
                                              OUTPUT opcError,
                                              OUTPUT opiStatusCode).
        
        IF opcError NE "":U THEN
          UNDO,THROW NEW AppError(opcError,1).
                                                       
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */                                                   
      ELSE 
      DO:
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 
        
        objInvoiceHistory:getCustomerInvoices(INPUT  ipcUserId,
                                              INPUT  ipcUserId,
                                              INPUT  ipcLangID,
                                              INPUT  iWareHouseNo,
                                              INPUT  cUserType,
                                              INPUT  ipiLastSyncTimestamp,
                                              OUTPUT oplcInvoiceData,
                                              OUTPUT opcError,
                                              OUTPUT opiStatusCode).
                                         
         
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1). 
              
      END. /* ELSE IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                               
      ASSIGN 
        opiStatusCode = 200. 
                                               
    END. /* IF opcStatus EQ "Success":U THEN */

    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
        
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
      
      IF VALID-OBJECT(objInvoiceHistory) THEN  
        DELETE OBJECT objInvoiceHistory.
               
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
    
    END FINALLY.     

  END METHOD.

  /*--------------------------------------------------------------------------------------
   Purpose: This method is used to call all the methods in order to load all the 
            data in one server call.
   Input Parameters: 01.ipcSalesRepId - Sales-rep-id
                     02.ipcPassword   - authentcation password,
                     03.ipcLangID     - language-id,
                     04.ipcDeviceID   - device-id (in case of mobile user), 
                     05.ipcUserType   - either mobile or web,
                     06.ipcCompanyID  - company-id for a user.
                    
   Output Parameters:01.opcUserToken         - Token details for entire session,
                     02.opcError             - errors if any,
                     03.opcSalesName         - salesperson name,
                     04.opcSalesRepId        - salesperson ID,
                     05.opdeSalesAmt         - sales amount for last 90 days(pg2),
                     06.opdeTotalOverdueAmt  - total overdue amount for an user(pg2),
                     07.opdeCartsAmt         - total amount of open carts for an user(pg2),
                     08.opiOverdueCustCount  - total count of customer overdue(pg2),
                     09.opiSalesPrsnOpnCarts - total count of open carts(pg2),
                     10.opiStatusCode        - response code,
                     11.opdsSalespersonData  - dataset that contains customers, 
                                               open-orders, invoices etc.details for 
                                               an user(pg2-5),
                     12.ttCustomerInfo       - temp-table contains salesperson's 
                                               overdue-customers details(pg2)
                     13.ttsalesPersonAdd     - temp-table contains salesperson information.
                     
   Notes:   
  ------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getData(INPUT  ipcSalesRepId        AS CHARACTER,
                            INPUT  ipcPassword          AS CHARACTER,
                            INPUT  ipcLangID            AS CHARACTER,
                            INPUT  ipcDeviceID          AS CHARACTER,
                            INPUT  ipcUserType          AS CHARACTER,  
                            INPUT  ipcCompanyID         AS CHARACTER, 
                            /* INPUT ipcSortBy       AS CHARACTER, */
                            OUTPUT opcUserToken         AS CHARACTER,
                            OUTPUT opcError             AS CHARACTER,
                            OUTPUT opcSalesName         AS CHARACTER,
                            OUTPUT opcSalesRepId        AS CHARACTER,
                            OUTPUT opdeSalesAmt         AS DECIMAL,
                            OUTPUT opdeTotalOverdueAmt  AS DECIMAL,
                            OUTPUT opdeCartsAmt         AS DECIMAL,
                            OUTPUT opiOverdueCustCount  AS INTEGER,
                            OUTPUT opiSalesPrsnOpnCarts AS INTEGER,
                            OUTPUT opiStatusCode        AS INTEGER,
                            OUTPUT DATASET opdsSalespersonData, 
                            OUTPUT TABLE   ttCustomerInfo,
                            OUTPUT TABLE   ttsalesPersonAdd):
    
    DEFINE VARIABLE objLogin     AS CLASS Login                 NO-UNDO.
    DEFINE VARIABLE objSalesCust AS CLASS SalesmanCustomersData NO-UNDO.
    DEFINE VARIABLE objSalesman  AS CLASS SalesmanInfo          NO-UNDO.
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource          NO-UNDO.
    
    ASSIGN 
      objLogin     = NEW Login()    
      objSalesCust = NEW SalesmanCustomersData()
      objSalesman  = NEW SalesmanInfo()
      objCommonSrc = NEW CommonSource().
        
    IF (TRIM(ipcSalesRepId) EQ "":U OR TRIM(ipcSalesRepId) EQ ? ) AND ( TRIM(ipcPassword) EQ "":U OR TRIM(ipcPassword) EQ ? ) THEN 
    DO:
      /*Get multilingual message for blank username and password */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserPswdBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF (TRIM(ipcSalesRepId) EQ "":U.. */  
               
    IF TRIM(ipcSalesRepId) EQ "":U OR TRIM(ipcSalesRepId) EQ ? THEN
    DO:
      /*Get multilingual message for blank username */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcSalesRepId) EQ "":U.. */ 
    ELSE
    DO:
      FIND CSAMS WHERE CSAMS.sales-rep-id EQ ipcSalesRepId  NO-LOCK NO-ERROR.
      IF NOT AVAILABLE CSAMS THEN
      DO:
        /* Get multilingual message for invalid user */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidUser,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT AVAILABLE CSAMS.. */ 
    END.  
            
    IF TRIM(ipcPassword) EQ "":U OR TRIM(ipcPassword) EQ ? THEN 
    DO:
      /*Get multilingual message for blank password */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200PswdBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcPassword) EQ "":U OR.. */
                   
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /*Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U.. */
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /*Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE.. */        
    END. /* ELSE */
      
    IF TRIM(ipcCompanyID) EQ "":U OR TRIM(ipcCompanyID) EQ ? THEN
    DO:
      /*Get multilingual message for blank company id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200CmpnyBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcCompanyID) EQ "":U.. */
    ELSE
    DO: 
      IF NOT CAN-FIND(CMPNY WHERE CMPNY.COMPANY-CODE EQ TRIM(ipcCompanyID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for invalid company id */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidCmpny,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /*  IF NOT CAN-FIND(CMPNY.. */       
    END. /* ELSE */ 
      
    /* Method returns token details and user details if login is successful  */            
    objLogin:validateSalesperson(INPUT  ipcSalesRepId,
      INPUT  ipcPassword,
      INPUT  ipcDeviceID,
      INPUT  ipcLangID,
      INPUT  ipcUserType,  
      INPUT  ipcCompanyID,  
      OUTPUT opcUserToken,                                  
      OUTPUT cError,
      OUTPUT lLoginStatus,
      OUTPUT opiStatusCode). 
    
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
    
   
    /* Checking if login is successful  */
    IF lLoginStatus THEN
    DO:
      /* Method returns salesperson basic information */   
      objSalesman:getSalesmanDetails(INPUT ipcSalesRepId,
                                    INPUT ipcLangID,
                                    OUTPUT lRegularSlsman,
                                    OUTPUT opcSalesName,
                                    OUTPUT opcSalesRepId,
                                    OUTPUT TABLE ttsalesPersonAdd,
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode). 
        
        
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).  
        
      /* This method returns salesperson's sales details for last X days */
      objSalesman:salesmanSalesAmtInLast90Days(INPUT  ipcSalesRepId, 
        INPUT  ipcCompanyID,
        INPUT  lRegularSlsman,
        OUTPUT opdeSalesAmt). 
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
      
      /* This method returns overdue details for the user/salesperson */
      objSalesman:getSalesmanCustomersOverdue(INPUT  ipcSalesRepId,
        INPUT  ipcCompanyID,
        INPUT  lRegularSlsman,
        OUTPUT TABLE ttCustomerInfo,
        OUTPUT opdeTotalOverdueAmt,
        OUTPUT opiOverdueCustCount,
        OUTPUT cError,
        OUTPUT opiStatusCode).
     
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
      
      /* This method returns open-cart details for the user  */  
      objSalesman:getOpenCarts(INPUT  ipcSalesRepId,
        INPUT  ipcLangID,
        INPUT  lRegularSlsman,
        INPUT  ipcCompanyID,
        OUTPUT opiSalesPrsnOpnCarts,
        OUTPUT opdeCartsAmt,
        OUTPUT cError,
        OUTPUT opiStatusCode,
        OUTPUT TABLE ttOpenorder).
                               
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
      
      /* This method returns all user specific details like customer list, open-order details etc. */    
      objSalesCust:getCustomers(INPUT  ipcSalesRepId,
        INPUT  ipcCompanyID,
        INPUT  lRegularSlsman,
        INPUT  "*":U, 
        INPUT  ipcLangID ,
        OUTPUT TABLE ttCustomer, 
        OUTPUT TABLE ttCustShippingAddress,
        OUTPUT TABLE ttOpenOrder, 
        OUTPUT TABLE ttCustInvoice,
        OUTPUT TABLE ttCustAmountOverdue,
        OUTPUT TABLE ttCustBillingAddress,
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
      
    END. /* IF lLoginStatus THEN */  
         
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      IF VALID-OBJECT(objLogin) THEN    
        DELETE OBJECT objLogin.
      IF VALID-OBJECT(objSalesCust) THEN  
        DELETE OBJECT objSalesCust.
      IF VALID-OBJECT(objSalesman) THEN
        DELETE OBJECT objSalesman.
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc.      
    
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
    
    END FINALLY. 
        
  END METHOD.
  
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  @openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
  METHOD PUBLIC VOID orderedItemsWrapper(INPUT ipcUserId          AS CHARACTER,
                                        INPUT ipcCustNumber      AS CHARACTER,                                    
                                        INPUT ipcToken           AS CHARACTER,
                                        INPUT ipcLangId          AS CHARACTER,
                                        INPUT ipcOrderNumber     AS CHARACTER,                                                 
                                        OUTPUT opcAppToken       AS CHARACTER,                                       
                                        OUTPUT opcError          AS CHARACTER,
                                        OUTPUT opiStatusCode     AS INTEGER, 
                                        OUTPUT oplcOrderedItems  AS LONGCHAR):
    
    DEFINE VARIABLE objTokenMgmt    AS CLASS     TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc    AS CLASS     CommonSource    NO-UNDO. 
    DEFINE VARIABLE objCustOrder    AS CLASS     CustomerOrders  NO-UNDO.
    DEFINE VARIABLE itemJsonObj     AS CLASS     JsonObject      NO-UNDO.
    DEFINE VARIABLE orderedItemsArr AS CLASS     JsonArray       NO-UNDO.
    
    DEFINE VARIABLE opcStatus       AS CHARACTER NO-UNDO.     
    DEFINE VARIABLE iWareHouseNo    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCompanyCode    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType       AS CHARACTER NO-UNDO.    
    DEFINE VARIABLE cPriceList      AS CHARACTER NO-UNDO.
        
    ASSIGN                
      objTokenMgmt    = NEW TokenManagement(INPUT ipcToken)
      objCommonSrc    = NEW CommonSource(INPUT ipcToken)
      orderedItemsArr = NEW JsonArray()
      objCustOrder    = NEW customerOrders(INPUT ipcToken)
      itemJsonObj     = NEW JsonObject().      
             
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /* Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
    END. /* ELSE */ 
    
    IF TRIM(ipcOrderNumber) EQ "":U OR TRIM(ipcOrderNumber) EQ ? THEN
    DO:
      /* Get multilingual message for blank order number */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200OrderBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcOrderNumber) EQ "":U OR.. */
    ELSE
    DO: 
      IF NOT CAN-FIND(COOHD WHERE COOHD.ORDER-NUMBER EQ TRIM(ipcOrderNumber) NO-LOCK) THEN
      DO:
        /* Get multilingual message for invalid order number */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidOrder,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(COOHD WHERE.. */        
    END. /* ELSE */
        
    /* Validate the token of the user on every request */
    IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c403InvalidToken,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcToken) EQ "":U OR.. */   
        
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
                    
    /* validate the token */
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
      INPUT  ipcUserId,
      INPUT  ipcLangID, 
      OUTPUT cError,
      OUTPUT opcStatus,
      OUTPUT opcAppToken,
      OUTPUT opiStatusCode). 
                                                                                      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
         
    IF opcStatus EQ "Success":U THEN
    DO:
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.  
        FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE. 
        END. /* FOR FIRST CMPNY..*/           
      END. /* FOR FIRST Token..*/
      
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
        DO:
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200CustBlank,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcCustNum) EQ ""*/  
        
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
        END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
        
        FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
        IF AVAIL CCSMS THEN
        DO:    
          FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
          IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
            ASSIGN cPriceList = SHPTO.PRICE-LIST.
          ELSE
            ASSIGN cPriceList = CCSMS.PRICE-LIST.
        END.
         
        FOR EACH COODT WHERE     COODT.ORDER-NUMBER EQ     ipcOrderNumber
          AND NOT COODT.ITEM-NUMBER  BEGINS cCompanyCode + "*":U NO-LOCK:
        
          ASSIGN 
            itemJsonObj = NEW JsonObject().      
  
          /* Get Item Json Object */
          objCustOrder:getOrderedItem(INPUT COODT.ORDER-NUMBER,
            INPUT COODT.ITEM-NUMBER,
            INPUT COODT.ORDER-SEQ,
            INPUT COODT.DESCRIPTION,
            INPUT COODT.ORIGINAL-QTY,
            INPUT "NOTAPPLICABLE", 
            INPUT cPriceList,
            INPUT CCSMS.CUST-NUMBER,
            INPUT cCompanyCode,
            INPUT iWareHouseNo,
            INPUT "",
            INPUT CCSMS.DISC-PERC,
            INPUT CCSMS.CONTRACT-IND,
            INPUT CCSMS.SPEC-DICT-I,
            INPUT CCSMS.QTY-BRK-CD,
            INPUT CCSMS.CUST-TYPE,
            OUTPUT itemJsonObj).
            
          IF CINV1.ITEM-NUMBER EQ COODT.ITEM-NUMBER THEN DO:
              itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
             itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).
          END.         
             
          orderedItemsArr:ADD(itemJsonObj). 
         
        END. /* FOR EACH COODT... */  
                                                               
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */                                                   
      ELSE 
      DO:
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 
        
        FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcUserId NO-LOCK NO-ERROR.
        IF AVAIL CCSMS THEN
        DO:    
          FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
          
          IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
            ASSIGN cPriceList = SHPTO.PRICE-LIST.
          ELSE
            ASSIGN cPriceList = CCSMS.PRICE-LIST.
        END.
         
        FOR EACH COODT WHERE     COODT.ORDER-NUMBER EQ     ipcOrderNumber
          AND NOT COODT.ITEM-NUMBER  BEGINS cCompanyCode + "*":U NO-LOCK BY COODT.ITEM-NUMBER:
          
        IF CAN-FIND(FIRST coosz WHERE COOSZ.ORDER-NUMBER EQ COODT.ORDER-NUMBER 
          AND COOSZ.ORDER-SEQ    EQ COODT.ORDER-SEQ) THEN
        DO:
            
          FOR EACH coosz WHERE coosz.order-number EQ COODT.ORDER-NUMBER 
            AND COOSZ.ORDER-SEQ    EQ COODT.ORDER-SEQ NO-LOCK:
                             
            ASSIGN 
              itemJsonObj = NEW JsonObject().      
      
            /* Get Item Json Object */
            objCustOrder:getOrderedItem(INPUT COODT.ORDER-NUMBER,
              INPUT COODT.ITEM-NUMBER,
              INPUT COODT.ORDER-SEQ,
              INPUT COODT.DESCRIPTION,
              INPUT COOSZ.SIZE-QTY, //COODT.ORIGINAL-QTY,
              input coosz.size, /* new added */
              INPUT cPriceList,
              INPUT CCSMS.CUST-NUMBER,
              INPUT cCompanyCode,
              INPUT iWareHouseNo,
              INPUT "",
              INPUT CCSMS.DISC-PERC,
              INPUT CCSMS.CONTRACT-IND,
              INPUT CCSMS.SPEC-DICT-I,
              INPUT CCSMS.QTY-BRK-CD,
              INPUT CCSMS.CUST-TYPE,
              OUTPUT itemJsonObj).
              
            IF CINV1.ITEM-NUMBER EQ COODT.ITEM-NUMBER THEN DO:
              itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
              itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).
            END.                  
                
            orderedItemsArr:ADD(itemJsonObj). 
          END. /* for each coosz */
        END. /* IF CAN-FIND(first coosz).. */
          
        else
        do:
          ASSIGN 
            itemJsonObj = NEW JsonObject().      
    
          /* Get Item Json Object */
          objCustOrder:getOrderedItem(INPUT COODT.ORDER-NUMBER,
            INPUT COODT.ITEM-NUMBER,
            INPUT COODT.ORDER-SEQ,
            INPUT COODT.DESCRIPTION,
            INPUT COODT.ORIGINAL-QTY,
            INPUT "NOTAPPLICABLE", 
            INPUT cPriceList,
            INPUT CCSMS.CUST-NUMBER,
            INPUT cCompanyCode,
            INPUT iWareHouseNo,
            INPUT "",
            INPUT CCSMS.DISC-PERC,
            INPUT CCSMS.CONTRACT-IND,
            INPUT CCSMS.SPEC-DICT-I,
            INPUT CCSMS.QTY-BRK-CD,
            INPUT CCSMS.CUST-TYPE,
            OUTPUT itemJsonObj).
          
          IF CINV1.ITEM-NUMBER EQ COODT.ITEM-NUMBER THEN DO:
              itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
             itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).
          END.        
                        
          orderedItemsArr:ADD(itemJsonObj). 
        end. /* ELSE - IF CAN-FIND(first coosz)..  */
         
      END. /* FOR EACH COODT... */
                     
    END. /* ELSE IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                               
    ASSIGN 
      opiStatusCode    = 200
      oplcOrderedItems = orderedItemsArr:GetJsonText(). 
                                               
  END. /* IF opcStatus EQ "Success":U THEN */

  CATCH errorObj AS AppError:           
    ASSIGN 
      opcError = errorObj:GetMessage(1).
  END CATCH.
    
  FINALLY:
    INPUT CLOSE.      
    IF VALID-OBJECT(orderedItemsArr) THEN
      DELETE OBJECT orderedItemsArr.
      
    IF VALID-OBJECT(itemJsonObj) THEN
      DELETE OBJECT itemJsonObj.
        
    IF VALID-OBJECT(objCommonSrc) THEN  
      DELETE OBJECT objCommonSrc. 
        
    IF VALID-OBJECT(objTokenMgmt) THEN  
      DELETE OBJECT objTokenMgmt.
      
    IF VALID-OBJECT(objCustOrder) THEN  
      DELETE OBJECT objCustOrder.
               
    IF VALID-HANDLE(hSharedVar) THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
    
  END FINALLY.

END METHOD.

/*----------------------------------------------------------------------------------
 Purpose: This method is used to get the recommended items. (Pg. 6)
 Input Parameters: 1. ipcUserId        - userid of a logged-in user.
                   2 .ipcCustNumber    - Customer Number,
                   3. ipcLangID        - language Id,
                   4. ipcToken         - active valid user token,
                   5. ipcCompanyID     - company id of the logged in user/salesperson.
                   6. ipcFetchCriteria - Top selling items fetching criteria e.g. week/month
                     
 Output Parameters:1. opcAppToken       - it contains new token if old token expired 
                                          otherwise return old token.
                   2. opcError          - returns error if any.
                   3. oplcTopSellerData - stores data related to top selling items.
                   4. opiStatusCode     - HTTP status code.
 Notes:
-------------------------------------------------------------------------------------*/
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID recommendedItems(INPUT  ipcUserId           AS CHARACTER,
                                      INPUT  ipcCustNumber       AS CHARACTER,                       
                                      INPUT  ipcLangID           AS CHARACTER,
                                      INPUT  ipcToken            AS CHARACTER,                                                                          
                                      OUTPUT opcAppToken         AS CHARACTER,
                                      OUTPUT opcError            AS CHARACTER, 
                                      OUTPUT oplcTopSellerData   AS LONGCHAR,
                                      OUTPUT oplcPurchaseHistory AS LONGCHAR,
                                      OUTPUT oplcPromoImagesData AS LONGCHAR,
                                      OUTPUT opiStatusCode       AS INTEGER):
                                         
    
  DEFINE VARIABLE opcStatus             AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cUserType             AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cCompanyID            AS CHARACTER NO-UNDO.
    
  DEFINE VARIABLE objCategoryFilterItem AS CLASS     CategoryFilterItem NO-UNDO.
  DEFINE VARIABLE objCommonSrc          AS CLASS     CommonSource       NO-UNDO.
  DEFINE VARIABLE objTokenMgmt          AS CLASS     TokenManagement    NO-UNDO.

  DEFINE VARIABLE iWareHouseNo          AS INTEGER   NO-UNDO.
         
  ASSIGN 
    objCategoryFilterItem = NEW CategoryFilterItem(INPUT ipcToken)                                        
    objCommonSrc          = NEW CommonSource(INPUT ipcToken)
    objTokenMgmt          = NEW TokenManagement(INPUT ipcToken).
                                                 
  IF TRIM(ipcLangId) EQ "":U OR TRIM(ipcLangId) EQ ? THEN
  DO:
    /* Get multilingual message for blank language id */
    objCommonSrc:getMessages(INPUT  ipcLangId,
                             INPUT  ConstantInitializer:c200LangBlank,
                             OUTPUT cError,
                             OUTPUT opiStatusCode).

    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcLangId) EQ "":U.. */    
  ELSE
  DO:
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangId) NO-LOCK) THEN
    DO:                  
      /* Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangId,
                                INPUT  ConstantInitializer:c200InvalidLang,
                                OUTPUT cError,
                                OUTPUT opiStatusCode).                                       

      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT CAN-FIND(CDILANGUAGE..) */
  END. /* ELSE of IF TRIM(ipcLangId) EQ "":U..  */

  IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
  DO:
    /* Get multilingual message for blank user*/
    objCommonSrc:getMessages(INPUT  ipcLangID,
                              INPUT  ConstantInitializer:c200UserBlank,                                                              
                              OUTPUT cError,
                              OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END.
              
  objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
                                        INPUT  ipcUserId,
                                        INPUT  ipcLangID, 
                                        OUTPUT cError,
                                        OUTPUT opcStatus,
                                        OUTPUT opcAppToken,
                                        OUTPUT opiStatusCode). 
                                                                                      
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
       
  IF opcStatus EQ "Success":U THEN
  DO:
    ASSIGN 
      ipcToken = opcAppToken.
    /* To find the warehouse number and user-type associated with the logged-in user */
    FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
      ASSIGN 
        cUserType  = Token.User-Type
        cCompanyID = Token.Company-ID.    
      FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK NO-ERROR.
      IF AVAILABLE CMPNY THEN
        ASSIGN iWareHouseNo = CMPNY.WHS-LOCATION. 
    END. /* FOR FIRST Token..*/                  
      
    IF cUserType EQ ConstantInitializer:cMobileUser THEN
    DO:
      IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
      DO:
        /*Get multilingual message for invalid user */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                  INPUT  "200_invalid_user":U,                                                              
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).
                                  
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END.
        
      IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
      DO:
        /* Get multilingual message for blank customer number */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                  INPUT  ConstantInitializer:c200CustBlank,                                                              
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /*IF TRIM(ipcCustNum) EQ ""*/  
      ELSE
      DO: 
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
        DO:
          /* Get multilingual message for invalid customer */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
                                 
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
      END. /* ELSE OF TRIM(ipcCustNum) EQ "":U OR TRIM(ipcCustNum) EQ ? */
        
      /* Get all the top selling items */
     objCategoryFilterItem:getTopSellerItems(INPUT  ipcCustNumber,                                            
                                                INPUT  cCompanyID,
                                                INPUT  iWareHouseNo,                                       
                                                OUTPUT cError,
                                                OUTPUT oplcTopSellerData). 
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
          
      /* Get inspired by your purchasing history items */
        objCategoryFilterItem:inspiredByPurchasingHistory(INPUT ipcCustNumber,
                                                         INPUT cCompanyID,
                                                         INPUT iWareHouseNo,                                         
                                                         OUTPUT cError,
                                                         OUTPUT oplcPurchaseHistory). 
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).  
        
      /* Get promo-images that are currently active */
        objCategoryFilterItem:getPromoImages(INPUT ipcUserId, 
                                             INPUT cCompanyID, 
                                             OUTPUT cError, 
                                             OUTPUT oplcPromoImagesData).
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
        
    END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */ 
       
    ELSE
    DO:
      IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
      DO:
        /*Get multilingual message for invalid user */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidUser,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                  
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END.
        
      /* Get all the top selling items */
      objCategoryFilterItem:getTopSellerItems(INPUT  ipcUserId,                                            
        INPUT  cCompanyID,
        INPUT  iWareHouseNo,                                       
        OUTPUT cError,
        OUTPUT oplcTopSellerData).
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
        
      /* Get inspired by your purchasing history items */  
      objCategoryFilterItem:inspiredByPurchasingHistory(INPUT ipcUserId,
        INPUT cCompanyID,
        INPUT iWareHouseNo,                                         
        OUTPUT cError,
        OUTPUT oplcPurchaseHistory).
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).  
      
      /* Get promo-images that are currently active */
      objCategoryFilterItem:getPromoImages(INPUT ipcUserId, 
      INPUT cCompanyID, 
      OUTPUT cError, 
      OUTPUT oplcPromoImagesData).
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
        
    END. /* ELSE OF cUserType EQ ConstantInitializer:cMobileUser THEN */     
 
    ASSIGN 
      opiStatusCode = 200.
                                            
  END. /* IF opcStatus EQ "Success":U */  
  
  
         
  CATCH errorObj AS AppError:           
    ASSIGN 
      opcError = errorObj:GetMessage(1).
  END CATCH.     
    
  FINALLY:
    IF VALID-OBJECT(objCommonSrc) THEN  
      DELETE OBJECT objCommonSrc. 
        
    IF VALID-OBJECT(objTokenMgmt) THEN  
      DELETE OBJECT objTokenMgmt.
      
    IF VALID-OBJECT(objCategoryFilterItem) THEN  
      DELETE OBJECT objCategoryFilterItem.             
   
    IF VALID-HANDLE(hSharedVar) THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
      
  END FINALLY.      
                                      
END METHOD.  
    
/*----------------------------------------------------------------------------------
 Purpose: This method is used to authenticate login user, maintain
          session for that user and also fetches user/salesperson information.
 Input Parameters: 1 .ipcSalesRepId - Sales Rep Id,
                   2. ipcPassword   - authentcation password,
                   3. ipcDeviceID   - device id (in case of mobile user),
                   4. ipcLangID     - language Id,
                   5. ipcUserType   - either mobile or web user,
                   6. ipcCompanyID  - company id of the logged in user/salesperson.
                    
 Output Parameters:1. opcError            - returns error if any,
                   2. oplcLoginData       - salesperson's sales , carts, overdue-
                                            customer information,
                   3. opiStatusCode       - HTTP status code.
 Notes:
-------------------------------------------------------------------------------------*/
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID salespersonLogin(INPUT  ipcUserName     AS CHARACTER,
                                      INPUT  ipcPassword     AS CHARACTER,
                                      INPUT  ipcDeviceID     AS CHARACTER,  
                                      INPUT  ipcLangID       AS CHARACTER,
                                      INPUT  ipcUserType     AS CHARACTER, 
                                      INPUT  ipcCompanyID    AS CHARACTER,
                                      OUTPUT opcError        AS CHARACTER, 
                                      OUTPUT oplcLoginData   AS LONGCHAR,
                                      OUTPUT opiStatusCode   AS INTEGER):
                                          
   
     
  DEFINE VARIABLE objLogin             AS CLASS     Login                 NO-UNDO.
  DEFINE VARIABLE objSalesman          AS CLASS     SalesmanInfo          NO-UNDO.
  DEFINE VARIABLE objCustomer          AS CLASS     SalesmanCustomersData NO-UNDO.
  DEFINE VARIABLE objCommonSrc         AS CLASS     CommonSource          NO-UNDO.
    
  DEFINE VARIABLE jsonObjData          AS CLASS     JsonObject            NO-UNDO. 
  DEFINE VARIABLE jsonObjAmountOverdue AS CLASS     JsonObject            NO-UNDO.
  DEFINE VARIABLE jsonObjOpenOrder     AS CLASS     JsonObject            NO-UNDO.
       
  DEFINE VARIABLE jsonarray            AS CLASS     JsonArray             NO-UNDO.
  DEFINE VARIABLE jsonArrayOverdues    AS CLASS     JsonArray             NO-UNDO.
  DEFINE VARIABLE jsonArrayOpenOrders  AS CLASS     JsonArray             NO-UNDO.
    
  DEFINE VARIABLE userToken            AS CHARACTER NO-UNDO.
  DEFINE VARIABLE salesName            AS CHARACTER NO-UNDO.
  DEFINE VARIABLE salesRepId           AS CHARACTER NO-UNDO.
  DEFINE VARIABLE opcLastXDays         AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iNoOfDays            AS INTEGER   NO-UNDO.
  DEFINE VARIABLE isalesPrsnOpnCarts   AS INTEGER   NO-UNDO.
  DEFINE VARIABLE opiOverdueCustCount  AS INTEGER   NO-UNDO.
  DEFINE VARIABLE deSalesAmt           AS DECIMAL   NO-UNDO.
  DEFINE VARIABLE opdeTotalOverdueAmt  AS DECIMAL   NO-UNDO.
  DEFINE VARIABLE opdeCartsAmt         AS DECIMAL   NO-UNDO.
  DEFINE VARIABLE hCustomerOverdue     AS HANDLE    NO-UNDO.
  DEFINE VARIABLE hOpenOrder           AS HANDLE    NO-UNDO.    
  DEFINE VARIABLE hSalesPersonAdd      AS HANDLE    NO-UNDO.
  DEFINE VARIABLE lcCanModifyPrice     AS CHARACTER NO-UNDO.
  DEFINE VARIABLE Cdomain              AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cSaleRepImage        AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cFileType            AS CHARACTER NO-UNDO.    
  DEFINE VARIABLE lcCanGiveDiscount    AS CHARACTER NO-UNDO.
   
  ASSIGN 
    objLogin             = NEW Login()
    objCommonSrc         = NEW CommonSource() 
    jsonObjData          = NEW JsonObject()
    jsonObjAmountOverdue = NEW JsonObject()
    jsonObjOpenOrder     = NEW JsonObject()
    jsonArray            = NEW JsonArray()
    jsonArrayOverdues    = NEW JsonArray()
    jsonArrayOpenOrders  = NEW JsonArray().
    
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /*Get multilingual message for blank languageId */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200LangBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
      
  END. /* IF TRIM(ipcLangID) EQ "":U OR.. */  
      
  ELSE
  DO: 
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      /*Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidLang,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /*  IF NOT CAN-FIND(CDILANGUAGE.. */       
  END. /* ELSE.. */
        
  IF (TRIM(ipcUserName) EQ "":U OR TRIM(ipcUserName) EQ ? ) AND ( TRIM(ipcPassword) EQ "":U OR TRIM(ipcPassword) EQ ? ) THEN 
  DO:
    /*Get multilingual message for blank username and password */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200UserPswdBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcUserName) EQ "":U AND TRIM(ipcPassword) EQ "":U.. */ 
        
  IF TRIM(ipcUserName) EQ "":U OR TRIM(ipcUserName) EQ ? THEN
  DO:
    /*Get multilingual message for blank username */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                              INPUT  ConstantInitializer:c200UserBlank,                                                              
                              OUTPUT cError,
                              OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*  IF TRIM(ipcUserName) EQ "":U OR.. */ 
  ELSE
  DO: 
    IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserName) NO-LOCK) THEN
    DO:
      /*Get multilingual message for invalid user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  "200_invalid_user":U,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
                                  
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.        
  END. 
        
  IF TRIM(ipcPassword) EQ "":U OR TRIM(ipcPassword) EQ ? THEN 
  DO:
    /*Get multilingual message for blank password */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200PswdBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcPassword) EQ "":U.. */
                        
  IF TRIM(ipcCompanyID) EQ "":U OR TRIM(ipcCompanyID) EQ ? THEN
  DO:
    /*Get multilingual message for blank company */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200CmpnyBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*  IF TRIM(ipcCompanyID) EQ "":U OR.. */
    
  ELSE 
  DO: 
    IF NOT CAN-FIND(CMPNY WHERE CMPNY.COMPANY-CODE EQ TRIM(ipcCompanyID) NO-LOCK) THEN
    DO:
      /*Get multilingual message for invalid company */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200InvalidCmpny,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
          
    END. /* IF NOT CAN-FIND(CMPNY WHERE.. */         
  END. /* ELSE.. */  
   // MESSAGE  "validateSalesperson". 
  /*This method validates user credentials and returns valid token of a user when successfully logged-in */         
  objLogin:validateSalesperson(INPUT  ipcUserName,
                                INPUT  ipcPassword,
                                INPUT  ipcDeviceID,
                                INPUT  ipcLangID,
                                INPUT  ipcUserType,
                                INPUT  ipcCompanyID,
                                OUTPUT userToken,                                  
                                OUTPUT cError,
                                OUTPUT lLoginStatus,
                                OUTPUT opiStatusCode).  
    
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
                    
  IF lLoginStatus THEN
  DO: 
     ASSIGN objSalesman     = NEW SalesmanInfo(INPUT userToken)
           objCustomer      = NEW SalesmanCustomersData(INPUT userToken) .
    /* Method returns salesperson basic information */ 
    // MESSAGE "getSalesmanDetails".
    objSalesman:getSalesmanDetails(INPUT ipcUserName,
                                  INPUT ipcLangID,
                                  OUTPUT lRegularSlsman,
                                  OUTPUT salesName,
                                  OUTPUT salesRepId,
                                  OUTPUT TABLE ttsalesPersonAdd,
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode). 
        
        
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
                                          
      // MESSAGE "salesmanSalesAmtInLast90Days".                                                                    
    /* Method returns sales amount for last X days for a salesperson */
    objSalesman:salesmanSalesAmtInLast90Days(INPUT  ipcUserName ,
                                              INPUT  ipcCompanyID, 
                                              INPUT  lRegularSlsman,
                                              OUTPUT deSalesAmt). 
       // MESSAGE  "getOpenCarts".    
    /* Method returns open-carts count, carts amount and carts details.  */ 
    objSalesman:getOpenCarts(INPUT  ipcUserName,
                             INPUT  ipcLangID,
                             INPUT  lRegularSlsman,
                             INPUT  ipcCompanyID,
                             OUTPUT iSalesPrsnOpnCarts,
                             OUTPUT deCartsAmt,
                             OUTPUT cError,
                             OUTPUT opiStatusCode,
                             OUTPUT TABLE ttOpenOrder). 
    
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
      
    /* Method returns overdue amount, customer-overdue count and sales- */
    /* person's overdue customer details                                 */
    
   // MESSAGE "getSalesmanCustomersOverdue".
    objSalesman:getSalesmanCustomersOverdue(  INPUT  ipcUserName,
                                              INPUT  ipcCompanyID,
                                              INPUT  lRegularSlsman,
                                              OUTPUT TABLE ttCustomerInfo,
                                              OUTPUT deTotalOverdueAmt,
                                              OUTPUT iOverdueCustCount,
                                              OUTPUT cError,
                                              OUTPUT opiStatusCode). 
        
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
               
              
    /* Logic to generate customized JSON response */    
    ASSIGN 
      hCustomerOverdue = TEMP-TABLE ttCustomerInfo:HANDLE
      hOpenOrder       = TEMP-TABLE ttOpenOrder:HANDLE
      hSalesPersonAdd  = TEMP-TABLE ttsalesPersonAdd:HANDLE.
      
    jsonArray:READ(hSalesPersonAdd).
    jsonArrayOverdues:READ(hCustomerOverdue). 
    jsonArrayOpenOrders:READ(hOpenOrder).
      
    jsonObjAmountOverdue:ADD(INPUT "no_overdue_customers":U, INPUT iOverdueCustCount).
    jsonObjAmountOverdue:ADD(INPUT "total_overdue_amount":U, INPUT deTotalOverdueAmt).
    jsonObjAmountOverdue:ADD(INPUT "overdue_customers":U,    INPUT jsonArrayOverdues).

    jsonObjOpenOrder:ADD(INPUT "no_open_orders":U,           INPUT iSalesPrsnOpnCarts).
    jsonObjOpenOrder:ADD(INPUT "total_open_orders_amount":U, INPUT deCartsAmt).
    jsonObjOpenOrder:ADD(INPUT "open_orders":U,              INPUT jsonArrayOpenOrders).

    jsonObjData:ADD(INPUT "salesPersonName":U,    INPUT salesName).
    jsonObjData:ADD(INPUT "salesRepId":U,         INPUT CAPS(salesRepId)).
      
    IF VALID-OBJECT(objCommonSrc) THEN 
    DO:
     // MESSAGE "parameterFile".
      objCommonSrc:parameterFile(INPUT ConstantInitializer:cNoOfDays,
                                 INPUT  ipcCompanyID,
                                 INPUT  YES,
                                 OUTPUT opcLastXDays,
                                 OUTPUT cError) NO-ERROR.
                              
      ASSIGN 
        iNoOfDays = INTEGER(opcLastXDays) NO-ERROR. 
      
      IF ERROR-STATUS:ERROR OR iNoOfDays EQ 0  THEN
        ASSIGN iNoOfDays = 180 NO-ERROR.

    END. /* IF VALID-OBJECT(objCommonSrc) THEN */
      
    /* Decides the number of days for sales in last XX days of salesperson */
    jsonObjData:ADD(INPUT "number_of_days":U, INPUT iNoOfDays).
                     
    /* get Salesman pictures */
    FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
    IF AVAILABLE paramfl THEN 
    jsonObjData:ADD(INPUT "salesman_picture":U, INPUT PARAMFL.PARAM-VALUE2 + "/salesrep/" + salesRepId + ".jpg"). 
    ELSE 
    jsonObjData:ADD(INPUT "salesman_picture":U, INPUT ""). 
  /*  FOR FIRST CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM (salesRepId) NO-LOCK:
      IF CSAMS.PICTURE NE "" THEN 
      DO:
        
        FILE-INFO:FILE-NAME = ConstantInitializer:cSalesmanPicDir + salesRepId + ".jpg".
        IF FILE-INFO:FULL-PATHNAME NE ? THEN
          jsonObjData:ADD(INPUT "salesman_picture":U, INPUT ConstantInitializer:cSalesmanPicDir + salesRepId + ".jpg").
        ELSE 
          jsonObjData:ADD(INPUT "salesman_picture":U, INPUT "").
        
      END. /* IF CSAMS.PICTURE NE "" THEN */                    
          
      ELSE
        jsonObjData:ADD(INPUT "salesman_picture":U, INPUT "").
    END. /* FOR FIRST CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM (salesRepId) NO-LOCK */
    */
    IF CAN-FIND (FIRST  PARAMFL WHERE PARAMFL.COMPANY-CODE EQ ipcCompanyID
                                  AND PARAMFL.PARAM-ID     EQ "CAN-MODIFY-PRICE":U 
                                  AND PARAMFL.PARAM-STATUS EQ YES ) THEN  
    DO: 
                                                                         
         ASSIGN lcCanModifyPrice = "yes".
    END.   
    ELSE
      ASSIGN lcCanModifyPrice = "no".
      
    IF CAN-FIND (FIRST  PARAMFL WHERE PARAMFL.COMPANY-CODE EQ ipcCompanyID
                                  AND PARAMFL.PARAM-ID     EQ "CAN-GIVE-DISCOUNT":U 
                                  AND PARAMFL.PARAM-STATUS EQ YES ) THEN  
    DO: 
                                                                         
         ASSIGN lcCanGiveDiscount = "yes".
    END.   
    ELSE
      ASSIGN lcCanGiveDiscount = "no".  
       
    
      
    jsonObjData:ADD(INPUT "token":U,              INPUT userToken).      
    jsonObjData:ADD(INPUT "total_sales_amount":U, INPUT deSalesAmt). /* Gives sales amount in last XX days */
      
    
    jsonObjData:ADD(INPUT "regular_salesman":U,   INPUT lRegularSlsman).

    jsonObjData:ADD(INPUT "salesPersonAddress":U, INPUT  jsonArray).

    jsonObjData:ADD(INPUT "customersOverdue":U,   INPUT  jsonObjAmountOverdue).

    jsonObjData:ADD(INPUT "openOrdersInfo":U,     INPUT  jsonObjOpenOrder).
    
    IF ipcUserType EQ "mobileuser" THEN 
    jsonObjData:ADD(INPUT "can_modify_price":U, INPUT lcCanModifyPrice).
     
    jsonObjData:ADD(INPUT "can_give_discount":U, INPUT lcCanGiveDiscount).
    
    /***************************************************************
     *Use this section of the code to add all future PARAMFL values* 
     ***************************************************************/
     
    FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"
                         AND PARAMFL.COMPANY-CODE = ipcCompanyID
                         AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.
    IF AVAILABLE paramfl THEN  
       jsonObjData:ADD(INPUT "do_not_allow_negative_inv_order":U, INPUT "yes").
    ELSE 
       jsonObjData:ADD(INPUT "do_not_allow_negative_inv_order":U, INPUT "no"). 
    
    FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "HAS-DATE-WANTED"
                         AND PARAMFL.COMPANY-CODE = ipcCompanyID
                         AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
    IF AVAILABLE PARAMFL THEN
        jsonObjData:ADD(INPUT "has_date_wanted":U, INPUT "yes").
    ELSE 
        jsonObjData:ADD(INPUT "has_date_wanted":U, INPUT "no").
    
    FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "HAS-CARD-PAYMENT"
                         AND PARAMFL.COMPANY-CODE = ipcCompanyID
                         AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
    IF AVAILABLE PARAMFL THEN
        jsonObjData:ADD(INPUT "has_card_payment":U, INPUT "yes").
    ELSE 
        jsonObjData:ADD(INPUT "has_card_payment":U, INPUT "no").
                                        
    ASSIGN 
      oplcLoginData = jsonObjData:GetJsonText()
      opiStatusCode = 200. 
                         
  END. /* IF lLoginStatus THEN.. */  
         
  CATCH errorObj AS AppError:           
    ASSIGN 
      opcError = errorObj:GetMessage(1).
  END CATCH.    
    
  FINALLY:
    IF VALID-OBJECT(objLogin)             THEN  
      DELETE OBJECT objLogin.
    IF VALID-OBJECT(objSalesman)          THEN
      DELETE OBJECT objSalesman.
    IF VALID-OBJECT(objCommonSrc)         THEN
      DELETE OBJECT objCommonSrc.
    IF VALID-OBJECT(objCustomer)          THEN
      DELETE OBJECT objCustomer. 
    IF VALID-OBJECT(jsonObjData)          THEN  
      DELETE OBJECT jsonObjData.
    IF VALID-OBJECT(jsonObjAmountOverdue) THEN  
      DELETE OBJECT jsonObjAmountOverdue.
    IF VALID-OBJECT(jsonObjOpenOrder)     THEN  
      DELETE OBJECT jsonObjOpenOrder.
    IF VALID-OBJECT(jsonarray)            THEN  
      DELETE OBJECT jsonarray.
    IF VALID-OBJECT(jsonArrayOverdues)    THEN  
      DELETE OBJECT jsonArrayOverdues.
    IF VALID-OBJECT(jsonArrayOpenOrders)  THEN  
      DELETE OBJECT jsonArrayOpenOrders.                   
    
    IF VALID-HANDLE(hSharedVar)           THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
        
  END FINALLY.
  
END METHOD.
    
/*----------------------------------------------------------------------------------
Purpose: This method is used to authenticate login user, maintain
         session for that user and also fetches user/salesperson information.
Input Parameters: 1 .ipcSalesRepId - Sales Rep Id,
                  2. ipcPassword   - authentcation password,
                  3. ipcDeviceID   - device id (in case of mobile user),
                  4. ipcLangID     - language Id,
                  5. ipcUserType   - either mobile or web user,
                  6. ipcCompanyID  - company id of the logged in user/salesperson.
                    
Output Parameters:1. opcError            - returns error if any,
                  2. oplcLoginData       - salesperson's sales , carts, overdue-
                                           customer information,
                  3. opiStatusCode       - HTTP status code.
Notes:
-------------------------------------------------------------------------------------*/
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID customerLogin(INPUT  ipcUserName        AS CHARACTER,
                                 INPUT  ipcPassword        AS CHARACTER, 
                                 INPUT  ipcLangID          AS CHARACTER,
                                 INPUT  ipcUserType        AS CHARACTER, 
                                 INPUT  ipcCompanyID       AS CHARACTER,
                                 OUTPUT opcError           AS CHARACTER, 
                                 OUTPUT oplcLoginData      AS LONGCHAR,
                                 OUTPUT opiStatusCode      AS INTEGER):
       
  DEFINE VARIABLE objLogin             AS CLASS     Login                 NO-UNDO.
  DEFINE VARIABLE objSalesman          AS CLASS     SalesmanInfo          NO-UNDO.
  DEFINE VARIABLE objCustomer          AS CLASS     SalesmanCustomersData NO-UNDO.
  DEFINE VARIABLE objCommonSrc         AS CLASS     CommonSource          NO-UNDO.
    
  DEFINE VARIABLE jsonObjData          AS CLASS     JsonObject            NO-UNDO. 
  DEFINE VARIABLE jsonObjAmountOverdue AS CLASS     JsonObject            NO-UNDO.
  DEFINE VARIABLE jsonObjOpenOrder     AS CLASS     JsonObject            NO-UNDO.
  DEFINE VARIABLE jsonObjInvoiceInfo   AS CLASS     JsonObject            NO-UNDO.
  DEFINE VARIABLE jsonObjBillingAd     AS CLASS     jsonobject            NO-UNDO.
       
  DEFINE VARIABLE jsonarray            AS CLASS     JsonArray             NO-UNDO.
  DEFINE VARIABLE jsonArrayOverdues    AS CLASS     JsonArray             NO-UNDO.
  DEFINE VARIABLE jsonArrayInvoices    AS CLASS     JsonArray             NO-UNDO.
  DEFINE VARIABLE jsonArrayOpenOrders  AS CLASS     JsonArray             NO-UNDO.
  DEFINE VARIABLE jsonArrayShippingAd  AS CLASS     JsonArray             NO-UNDO.
    
  DEFINE VARIABLE userToken            AS CHARACTER NO-UNDO.
  DEFINE VARIABLE hCustomerOverdue     AS HANDLE    NO-UNDO.
  DEFINE VARIABLE hOpenOrder           AS HANDLE    NO-UNDO.
  DEFINE VARIABLE hCustomerInvoice     AS HANDLE    NO-UNDO.    
  DEFINE VARIABLE hCustShipping        AS HANDLE    NO-UNDO.
   // MESSAGE "customerLogin" .   
  ASSIGN 
    objLogin             = NEW Login()
    
    objCommonSrc         = NEW CommonSource() 
    jsonObjData          = NEW JsonObject()
    jsonObjBillingAd     = NEW JsonObject()
    jsonObjAmountOverdue = NEW JsonObject()
    jsonObjInvoiceInfo   = NEW JsonObject()
    jsonObjOpenOrder     = NEW JsonObject()
    jsonArray            = NEW JsonArray()
    jsonArrayOverdues    = NEW JsonArray()
    jsonArrayInvoices    = NEW JsonArray()
    jsonArrayOpenOrders  = NEW JsonArray()
    jsonArrayShippingAd  = NEW JsonArray().
    
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /*Get multilingual message for blank languageId */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200LangBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
      
  END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
     
  ELSE
  DO: 
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      /*Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200InvalidLang,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /*  IF NOT CAN-FIND(CDILANGUAGE..) */       
  END. /* ELSE.. */
        
  IF (TRIM(ipcUserName) EQ "":U OR TRIM(ipcUserName) EQ ?) AND (TRIM(ipcPassword) EQ "":U OR TRIM(ipcPassword) EQ ?) THEN 
  DO:
    /* Get multilingual message for blank username and password */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200UserPswdBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).    
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcUserName) EQ "":U AND TRIM(ipcPassword) EQ "":U.. */ 
        
  IF TRIM(ipcUserName) EQ "":U OR TRIM(ipcUserName) EQ ? THEN
  DO:
    /*Get multilingual message for blank username */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200UserBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*  IF TRIM(ipcUserName) EQ "":U OR.. */
     
  ELSE
  DO: 
    IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserName) NO-LOCK) THEN
    DO:
      /*Get multilingual message for invalid user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200InvalidUser,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
                                  
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.        
  END. 
        
  IF TRIM(ipcPassword) EQ "":U OR TRIM(ipcPassword) EQ ? THEN 
  DO:
    /*Get multilingual message for blank password */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200PswdBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcPassword) EQ "":U.. */
                        
  IF TRIM(ipcCompanyID) EQ "":U OR TRIM(ipcCompanyID) EQ ? THEN
  DO:
    /*Get multilingual message for blank company */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200CmpnyBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*  IF TRIM(ipcCompanyID) EQ "":U OR.. */
    
  ELSE 
  DO: 
    IF NOT CAN-FIND(CMPNY WHERE CMPNY.COMPANY-CODE EQ TRIM(ipcCompanyID) NO-LOCK) THEN
    DO:
      /*Get multilingual message for invalid company */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200InvalidCmpny,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
          
    END. /* IF NOT CAN-FIND(CMPNY WHERE.. */         
  END. /* ELSE.. */  
      
  /*This method validates user credentials and returns valid token of a user when successfully logged-in */  
  //MESSAGE  "validateCustomer".      
  objLogin:validateCustomer(INPUT  ipcUserName,
                            INPUT  ipcPassword,
                            INPUT  ipcLangID,
                            INPUT  ipcUserType,
                            INPUT  ipcCompanyID,
                            OUTPUT userToken,                                  
                            OUTPUT cError,
                            OUTPUT lLoginStatus,
                            OUTPUT opiStatusCode).  
    
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
    
  ASSIGN objSalesman          = NEW SalesmanInfo(INPUT userToken)
         objCustomer          = NEW SalesmanCustomersData(INPUT userToken).
                             
  IF lLoginStatus THEN
  DO:  
    /* Method used to return details of a customer */   
    IF ipcUserType = "mobileuser" THEN   
    DO:
        objCustomer:fillAllCustomersData(INPUT ipcUserName,
                                  INPUT ipcCompanyID,
                                  INPUT ipcLangID,
                                  OUTPUT TABLE ttCustomer, 
                                  OUTPUT TABLE ttCustShippingAddress,
                                  OUTPUT TABLE ttOpenOrder, 
                                  OUTPUT TABLE ttCustInvoice,
                                  OUTPUT TABLE ttCustAmountOverdue,
                                  OUTPUT TABLE ttCustBillingAddress,
                                  OUTPUT cError,
                                  OUTPUT opiStatusCode).
    END. 
    ELSE 
    DO:   
        objCustomer:fillCustomersData(INPUT ipcUserName,
                                      INPUT ipcCompanyID,
                                      INPUT ipcLangID,
                                      OUTPUT TABLE ttCustomer, 
                                      OUTPUT TABLE ttCustShippingAddress,
                                      OUTPUT TABLE ttOpenOrder, 
                                      OUTPUT TABLE ttCustInvoice,
                                      OUTPUT TABLE ttCustAmountOverdue,
                                      OUTPUT TABLE ttCustBillingAddress,
                                      OUTPUT cError,
                                      OUTPUT opiStatusCode). 
      END.                         
                                                                         
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
      
    FIND FIRST ttCustBillingAddress NO-ERROR.
      
    IF AVAILABLE ttCustBillingAddress THEN
    DO:
      jsonObjBillingAd:Add("billingAdd1",ttCustBillingAddress.billingAdd1).
      jsonObjBillingAd:Add("billingAdd2",ttCustBillingAddress.billingAdd2).
      jsonObjBillingAd:Add("billingAdd3",ttCustBillingAddress.billingAdd3).
      jsonObjBillingAd:Add("city",ttCustBillingAddress.billingCity).
      jsonObjBillingAd:Add("state",ttCustBillingAddress.billingState).
      jsonObjBillingAd:Add("zip_code",ttCustBillingAddress.billingZip).
    END. /* IF AVAILABLE ttCustBillingAddress */
      
    FIND FIRST ttCustomer NO-LOCK NO-ERROR.
    IF AVAIL ttCustomer THEN
    DO: 
      /* Logic to generate customized JSON response */    
      ASSIGN 
        hCustomerOverdue = TEMP-TABLE ttCustAmountOverdue:HANDLE
        hCustShipping    = TEMP-TABLE ttCustShippingAddress:HANDLE
        hOpenOrder       = TEMP-TABLE ttOpenOrder:HANDLE
        hCustomerInvoice = TEMP-TABLE ttCustInvoice:HANDLE.

      jsonArrayShippingAd:READ(hCustShipping).
      jsonArrayOverdues:READ(hCustomerOverdue).
      jsonArrayInvoices:READ(hCustomerInvoice).
      jsonArrayOpenOrders:READ(hOpenOrder).
        
      jsonObjOpenOrder:ADD(INPUT "total_open_orders_amount":U, INPUT ttCustomer.totalOpenOrderAmt).
      jsonObjOpenOrder:ADD(INPUT "no_open_orders":U,           INPUT ttCustomer.totalOpenOrder).
      jsonObjOpenOrder:ADD(INPUT "open_orders":U,              INPUT jsonArrayOpenOrders).
        
      jsonObjInvoiceInfo:ADD(INPUT "total_invoice_amount":U,INPUT ttCustomer.custAmtInvoiced).
      jsonObjInvoiceInfo:ADD(INPUT "no_of_invoices":U,      INPUT ttCustomer.totalInvoices).
      jsonObjInvoiceInfo:ADD(INPUT "invoices":U,            INPUT jsonArrayInvoices).
        
      jsonObjAmountOverdue:ADD(INPUT "total_overdue_amount":U,INPUT ttCustomer.amtOverdue).
      jsonObjAmountOverdue:ADD(INPUT "no_of_overdues":U,      INPUT ttCustomer.totalOverdues).
      jsonObjAmountOverdue:ADD(INPUT "overdues":U,            INPUT jsonArrayOverdues).
        
      jsonObjData:ADD(INPUT "token":U,              INPUT userToken).                            
      jsonObjData:ADD(INPUT "customer_number":U,    INPUT ttCustomer.customerNumber). 
      jsonObjData:ADD(INPUT "customer_name":U,      INPUT ttCustomer.customerName).
      jsonObjData:ADD(INPUT "second_name":U,        INPUT ttCustomer.secondName). 
      
      /* Get Customer Picture */
      FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
       IF AVAILABLE paramfl THEN 
       DO:
         jsonObjData:ADD(INPUT "customer_picture":U,    INPUT PARAMFL.PARAM-VALUE2 + "/customer/" + ttCustomer.customerNumber + ".jpg").
         jsonObjData:ADD(INPUT "terms_condition_pdf":U, INPUT PARAMFL.PARAM-VALUE2 + "/customer/" + ttCustomer.customerNumber + ".pdf").
       END.  
       ELSE
       DO:
        jsonObjData:ADD(INPUT "customer_picture":U,      INPUT "").
        jsonObjData:ADD(INPUT "terms_condition_pdf":U,   INPUT "").
       END. 
     /* FILE-INFO:FILE-NAME = ConstantInitializer:cCustomerPicDir + "/" + ttCustomer.customerNumber + ".jpg".
      IF FILE-INFO:FULL-PATHNAME NE ? THEN
        jsonObjData:ADD(INPUT "customer_picture":U,   INPUT ConstantInitializer:cCustomerPicDir + ttCustomer.customerNumber + ".jpg").
      ELSE
        jsonObjData:ADD(INPUT "customer_picture":U,   INPUT "").    */    
      /* Get Customer Picture */
      
      /* Get terms & conditions PDF */
      
    /*  FILE-INFO:FILE-NAME = ConstantInitializer:cCustomerPicDir + "/" + ttCustomer.customerNumber + ".pdf".
      IF FILE-INFO:FULL-PATHNAME NE ? THEN
        jsonObjData:ADD(INPUT "terms_condition_pdf":U,   INPUT ConstantInitializer:cCustomerPicDir + ttCustomer.customerNumber + ".pdf").
      ELSE
        jsonObjData:ADD(INPUT "terms_condition_pdf":U,   INPUT "").      */  
      /* Get terms & conditions PDF */
      
      jsonObjData:ADD(INPUT "billing_address":U,    INPUT jsonObjBillingAd).
      jsonObjData:ADD(INPUT "shipping_address":U,   INPUT jsonArrayShippingAd). 
      jsonObjData:ADD(INPUT "credit_limit":U,       INPUT ttCustomer.creditLimit). 
      jsonObjData:ADD(INPUT "available_credit":U,   INPUT ttCustomer.availCredit). 
      jsonObjData:ADD(INPUT "phone_number":U,       INPUT ttCustomer.phoneNumber).
      jsonObjData:ADD(INPUT "customer_type":U,      INPUT ttCustomer.customerType).
      jsonObjData:ADD(INPUT "email_id":U,           INPUT ttCustomer.emailId). 
      jsonObjData:ADD(INPUT "total_sales":U,        INPUT ttCustomer.totalSales).
      jsonObjData:ADD(INPUT "sales_90_days":U,      INPUT ttCustomer.custSaleInLast90Day).
      jsonObjData:ADD(INPUT "payment_term":U,       INPUT ttCustomer.paymentTerm).
      jsonObjData:ADD(INPUT "price_list":U,         INPUT ttCustomer.priceList).
      jsonObjData:ADD(INPUT "recent_order_date":U,  INPUT ttCustomer.recentOrderDate).
      jsonObjData:ADD(INPUT "onhold":U,             INPUT ttCustomer.onHoldCustomer).
      jsonObjData:ADD(INPUT "po_required":U,        INPUT ttCustomer.poRequired). 
      jsonObjData:ADD(INPUT "number_of_days":U,     INPUT ttCustomer.number_of_days).        
      jsonObjData:ADD(INPUT "amount_overdue_info":U,INPUT jsonObjAmountOverdue).
      jsonObjData:ADD(INPUT "invoice_info":U,       INPUT jsonObjInvoiceInfo).
      jsonObjData:ADD(INPUT "open_order_info":U,    INPUT jsonObjOpenOrder).
    
      /* Do Not Allow Negative Inventory Orders */ 
      FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"
                         AND PARAMFL.COMPANY-CODE = ipcCompanyID
                         AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.
      IF AVAILABLE paramfl THEN  
        jsonObjData:ADD(INPUT "do_not_allow_negative_inv_order":U, INPUT "yes").
      ELSE 
        jsonObjData:ADD(INPUT "do_not_allow_negative_inv_order":U, INPUT "no").
      
      /* Inspired By Purchase History */ 
      FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "SALE-HISTORY-DAYS" 
                         AND PARAMFL.COMPANY-CODE = ipcCompanyID
                         AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
      IF AVAILABLE PARAMFL THEN
        jsonObjData:ADD(INPUT "inspired_by_purchase_history_active":U, INPUT "yes").
      ELSE 
        jsonObjData:ADD(INPUT "inspired_by_purchase_history_active":U, INPUT "no").
      
      /* Top Selling Item */   
      FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "TOP-SELLING-ITEM" 
                         AND PARAMFL.COMPANY-CODE = ipcCompanyID
                         AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
      IF AVAILABLE PARAMFL THEN
        jsonObjData:ADD(INPUT "top_selling_item_active":U, INPUT "yes").
      ELSE 
        jsonObjData:ADD(INPUT "top_selling_item_active":U, INPUT "no").
      
      FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "HAS-DATE-WANTED"
                         AND PARAMFL.COMPANY-CODE = ipcCompanyID
                         AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
      IF AVAILABLE PARAMFL THEN
          jsonObjData:ADD(INPUT "has_date_wanted":U, INPUT "yes").
      ELSE 
          jsonObjData:ADD(INPUT "has_date_wanted":U, INPUT "no").
       
    END. /* IF AVAIL ttCustomer THEN */                           
                                         
    ASSIGN 
      oplcLoginData = jsonObjData:GetJsonText()
      opiStatusCode = 200. 
                         
  END. /* IF lLoginStatus THEN.. */  
         
  CATCH errorObj AS AppError:           
    ASSIGN 
      opcError = errorObj:GetMessage(1).
  END CATCH.    
    
  FINALLY:
    IF VALID-OBJECT(objLogin) THEN  
      DELETE OBJECT objLogin.
    IF VALID-OBJECT(objSalesman) THEN
      DELETE OBJECT objSalesman.
    IF VALID-OBJECT(objCommonSrc) THEN
      DELETE OBJECT objCommonSrc.
    IF VALID-OBJECT(objCustomer) THEN
      DELETE OBJECT objCustomer. 
    IF VALID-OBJECT(jsonObjData) THEN  
      DELETE OBJECT jsonObjData.
    IF VALID-OBJECT(jsonObjAmountOverdue) THEN  
      DELETE OBJECT jsonObjAmountOverdue.
    IF VALID-OBJECT(jsonObjOpenOrder) THEN  
      DELETE OBJECT jsonObjOpenOrder.
    IF VALID-OBJECT(jsonObjInvoiceInfo) THEN  
      DELETE OBJECT jsonObjInvoiceInfo.
    IF VALID-OBJECT(jsonarray) THEN  
      DELETE OBJECT jsonarray.
    IF VALID-OBJECT(jsonArrayOverdues) THEN  
      DELETE OBJECT jsonArrayOverdues.
    IF VALID-OBJECT(jsonArrayInvoices) THEN  
      DELETE OBJECT jsonArrayInvoices.
    IF VALID-OBJECT(jsonArrayOpenOrders) THEN  
      DELETE OBJECT jsonArrayOpenOrders.
    IF VALID-OBJECT(jsonArrayShippingAd) THEN  
      DELETE OBJECT jsonArrayShippingAd.
    IF VALID-OBJECT(jsonObjBillingAd) THEN  
      DELETE OBJECT jsonObjBillingAd.           
                 
    IF VALID-HANDLE(hSharedVar) THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
    
  END FINALLY.
  
END METHOD.
     
/*------------------------------------------------------------------------------
 Purpose: This method is used to logout the user who is currently logged in.
 Input Parameters: 1.ipcToken  - Token details for the loggedin user,
                   2.ipcLangID - language-id.
   
 Output Parameters:1.opcStatus     - Login status of an user,
                   2.opeMessage    - user specific messages,
                   3.opiStatusCode - HTTP status code.
 Notes:
------------------------------------------------------------------------------*/
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID logout(INPUT  ipcToken      AS CHARACTER,
                          INPUT  ipcLangID     AS CHARACTER,
                          OUTPUT opcStatus     AS CHARACTER,
                          OUTPUT opcMessage    AS CHARACTER,
                          OUTPUT opiStatusCode AS INTEGER):
   
  DEFINE VARIABLE objTokenmgmt AS CLASS TokenManagement NO-UNDO.
  DEFINE VARIABLE objCommonSrc AS CLASS COmmonSource    NO-UNDO.
    
  objTokenmgmt = NEW TokenManagement(INPUT ipcToken).
  objCommonSrc = NEW CommonSource(INPUT ipcToken).
    
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /* Get multilingual message for blank language id */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200LangBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
  ELSE
  DO: 
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidLang,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
                                  
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */      
  END. /* ELSE OF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? */
      
  IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
  DO:
    /*Get multilingual message for invalid token */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c403InvalidToken,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcToken) EQ "":U OR.. */
      
  /* This method expire user token when log out. */     
  objTokenmgmt:expireToken(INPUT  ipcToken,
    INPUT  ipcLangID, 
    OUTPUT opcStatus, 
    OUTPUT opcMessage, 
    OUTPUT opiStatusCode).
    
  IF opcMessage NE "":U THEN
    UNDO,THROW NEW AppError(opcMessage,1).
    
  CATCH errorObj AS AppError:           
    ASSIGN 
      opcMessage = errorObj:GetMessage(1).   
  END CATCH.
                          
  FINALLY:
    IF VALID-OBJECT(objTokenmgmt) THEN  
      DELETE OBJECT objTokenmgmt.
    IF VALID-OBJECT(objCommonSrc) THEN
      DELETE OBJECT objCommonSrc.
    
    IF VALID-HANDLE(hSharedVar) THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
    
/*    IF opiStatusCode EQ 200 THEN QUIT.*/
  END FINALLY.
                          
END METHOD. 

DEFINE PRIVATE TEMP-TABLE TTCustomerSuggestionList NO-UNDO
    FIELD CustomerNumber      AS CHARACTER 
    FIELD CustomerName        AS CHARACTER 
    FIELD CustomerPhoneNumber AS CHARACTER
    FIELD CustomerEmail       AS CHARACTER.
    


/*------------------------------------------------------------------------------------
 Purpose: This method is used to fetch all the customers data to be used for 
 a list of suggestions for the search client function in the front end
  
 Input Parameters: 1.ipcToken      - User-token,
                   2.ipcLangID     - language-id,
                   3.ipcSalesRepId - salesrep id for which customers to be fetched,
                   
 Output Parameters:1.opcError                 - Errors if any,
                   2.opcMessage               - messages contains user related information,
                   3.opcAppToken              - it contains new token if old token expired 
                                                otherwise return old token,
                   4.TTCustomerSuggestionList - Contains a temp table that contains all 
                                                the data for the suggestions that will be 
                                                present in the front end
 Notes: 
---------------------------------------------------------------------------------------*/

@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID fetchCustomerSuggestionsList(INPUT ipcToken             AS CHARACTER,
                                                INPUT ipcLangID            AS CHARACTER,
                                                INPUT ipcSalesRepID        AS CHARACTER,
                                                OUTPUT opcMessage          AS CHARACTER,
                                                OUTPUT opcAppToken         AS CHARACTER,
                                                OUTPUT opiStatusCode       AS INTEGER,
                                                OUTPUT TABLE TTCustomerSuggestionList):
                                                    
      DEFINE VARIABLE cCompanyCode      AS           CHARACTER             NO-UNDO.
      DEFINE VARIABLE objCustomer       AS CLASS     SalesmanCustomersData NO-UNDO.
      DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement       NO-UNDO.
      DEFINE VARIABLE objCommonSrc      AS CLASS     CommonSource          NO-UNDO.
      DEFINE VARIABLE opcStatus         AS CHARACTER                       NO-UNDO.
      
                                                    
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
      IF CAN-FIND(FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK) THEN
        ASSIGN cCompanyCode = Token.Company-ID.            
      END. /* FOR FIRST Token..*/  
      
      ASSIGN 
        objCustomer       = NEW SalesmanCustomersData(INPUT ipcToken)
        objTokenMgmt      = NEW TokenManagement(INPUT ipcToken)
        objCommonSrc      = NEW CommonSource(INPUT ipcToken).
                                                   
      IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
      DO:
        /* Get multilingual message for blank language id */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200LangBlank,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
            
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF TRIM(ipcLangID) EQ "":U OR.. */ 
      ELSE
      DO: 
       IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
        DO:
          /* Get multilingual message for language not supported */
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200InvalidLang,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
                                      
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
      END. /* ELSE */    
      
      /*Validate the token of the user on every request*/
  IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
  DO:
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c403InvalidToken,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcToken) EQ "":U OR.. */ 
  
  IF TRIM(ipcSalesRepId) EQ "":U OR TRIM(ipcSalesRepId) EQ ? THEN
  DO:
    /* Get multilingual message for blank user */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200UserBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcSalesRepId) EQ "":U OR.. */
  
  ELSE
  DO:
    FIND CSAMS WHERE CSAMS.sales-rep-id EQ ipcSalesRepId  NO-LOCK NO-ERROR.
    IF NOT AVAILABLE CSAMS THEN
    DO:
      /* Get multilingual message for invalid user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200InvalidUser,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT AVAILABLE CSAMS.. */ 
  END.
  
  objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
                                      INPUT  ipcSalesRepId,
                                      INPUT  ipcLangID, 
                                      OUTPUT opcMessage,
                                      OUTPUT opcStatus,
                                      OUTPUT opcAppToken,
                                      OUTPUT opiStatusCode). 
                                                                                      
  IF opcMessage NE "":U THEN
    UNDO,THROW NEW AppError(opcMessage,1).
    
  
  /* Checking if status is success */                                          
  IF opcStatus EQ "Success":U THEN
  DO:
    // TODO -> Implement getting the suggestion list here 
    
    DEFINE VARIABLE willShowAllCustomers AS LOGICAL NO-UNDO.
    FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID BEGINS "OE-SALES-OPERATOR" AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    willShowAllCustomers = AVAIL PARAMFL.
    
    /* Create a list of customers assigned to Salesrep based on CCSMS and shpto*/
    FOR EACH ccsms WHERE CCSMS.CUST-Number BEGINS cCompanyCode NO-LOCK:
       IF ccsms.SALES-REP-ID NE ipcSalesRepId THEN
       DO: 
          IF  willShowAllCustomers THEN DO:
              FIND TTCustomerSuggestionList WHERE TTCustomerSuggestionList.CustomerNumber = CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
              IF NOT AVAILABLE TTCustomerSuggestionList THEN DO:
              CREATE TTCustomerSuggestionList.
              ASSIGN 
                TTCustomerSuggestionList.CustomerNumber      = CCSMS.CUST-NUMBER
                TTCustomerSuggestionList.CustomerName        = CCSMS.CUST-NAME
                TTCustomerSuggestionList.CustomerPhoneNumber = CCSMS.PHONE-NUMBER
                TTCustomerSuggestionList.CustomerEmail       = CCSMS.E-MAIL.
              END.
          END.
          ELSE DO:
            FOR EACH shpto WHERE shpto.cust-number  = ccsms.cust-number
                         AND ((shpto.SALES-REP-ID = ipcSalesRepId AND NOT willShowAllCustomers) OR willShowAllCustomers) NO-LOCK BREAK BY shpto.cust-number:
             IF FIRST-OF(shpto.cust-number) THEN DO:
                 FIND TTCustomerSuggestionList WHERE TTCustomerSuggestionList.CustomerNumber = CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
                 IF NOT  AVAILABLE TTCustomerSuggestionList THEN DO:
                 CREATE TTCustomerSuggestionList.
                 ASSIGN 
                    TTCustomerSuggestionList.CustomerNumber      = shpto.cust-number
                    TTCustomerSuggestionList.CustomerName        = CCSMS.CUST-NAME
                    TTCustomerSuggestionList.CustomerPhoneNumber = CCSMS.PHONE-NUMBER 
                    TTCustomerSuggestionList.CustomerEmail       = CCSMS.E-MAIL.
                 END.
              END.
            END.
          END.
       END.
    ELSE
    DO:
        FIND FIRST TTCustomerSuggestionList WHERE TTCustomerSuggestionList.CustomerNumber EQ ccsms.cust-number NO-ERROR.
        IF NOT AVAILABLE TTCustomerSuggestionList THEN 
        DO:
           CREATE TTCustomerSuggestionList.
           ASSIGN  
                TTCustomerSuggestionList.CustomerNumber      = CCSMS.CUST-NUMBER
                TTCustomerSuggestionList.CustomerName        = CCSMS.CUST-NAME
                TTCustomerSuggestionList.CustomerPhoneNumber = CCSMS.PHONE-NUMBER
                TTCustomerSuggestionList.CustomerEmail       = CCSMS.E-MAIL.
        END.   
        
    END.
  END. 
  END.   
      
END METHOD.
    
    
/*------------------------------------------------------------------------------------
 Purpose: This method is used to expose API to fetch data of all the customers
          based on the input sort by.
 Input Parameters: 1.ipcToken      - User-token,
                   2.ipcLangID     - language-id,
                   3.ipcSalesRepId - salesrep id for which customers to be fetched,
                   4.ipcSortBy     - determines how you want to display customer's
                                     list.
 Output Parameters:1.opcError            - Errors if any,
                   2.opcMessage          - messages contains user related information,
                   3.opcAppToken         - it contains new token if old token expired 
                                           otherwise return old token,
                   4.opdsSalespersonData - dataset that contains customers, 
                                           open-orders, invoices etc.details for 
                                           an user(pg2-5) 
 Notes: 
---------------------------------------------------------------------------------------*/
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID fetchCustomers(INPUT  ipcToken            AS CHARACTER,
                                  INPUT  ipcLangID           AS CHARACTER, 
                                  INPUT  ipcSalesRepId       AS CHARACTER,                                  
                                  INPUT  ipcSortBy           AS CHARACTER,  
                                  OUTPUT opcMessage          AS CHARACTER,
                                  OUTPUT opcAppToken         AS CHARACTER,
                                  OUTPUT opiStatusCode       AS INTEGER,
                                  OUTPUT oplcSalespersonData AS LONGCHAR):
                                      
                                      MESSAGE "ipcToken " ipcToken skip
                                              "ipcLangID " ipcLangID skip
                                              "ipcSalesRepId " ipcSalesRepId skip
                                              "ipcSortBy " ipcSortBy skip
                                      VIEW-AS ALERT-BOX.       
    
  DEFINE VARIABLE ipcSortList       AS CHARACTER INITIAL "*,A-Z,recentvisit,nearme":U.
  DEFINE VARIABLE opcStatus         AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cCompanyCode      AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iarrayIndex       AS INTEGER   NO-UNDO.
  DEFINE VARIABLE lCheck            AS LOGICAL   NO-UNDO.
  DEFINE VARIABLE objCustomer       AS CLASS     SalesmanCustomersData NO-UNDO.
  DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement       NO-UNDO.
  DEFINE VARIABLE objCommonSrc      AS CLASS     CommonSource          NO-UNDO.
  DEFINE VARIABLE salesDataJsonObj  AS CLASS     JsonObject            NO-UNDO.
  DEFINE VARIABLE customerJsonObj   AS CLASS     JsonObject            NO-UNDO.
  DEFINE VARIABLE customerJsonArray AS CLASS     JsonArray             NO-UNDO.
  DEFINE VARIABLE blankJsonArray    AS CLASS     JsonArray             NO-UNDO.
  DEFINE VARIABLE lchar             AS LONGCHAR NO-UNDO.
  
  FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
      IF CAN-FIND(FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK) THEN
        ASSIGN cCompanyCode = Token.Company-ID.            
  END. /* FOR FIRST Token..*/
  
  IF ipcToken EQ "BATCH" THEN 
  DO:
      FOR FIRST token WHERE Token.User-ID EQ ipcSalesRepId NO-LOCK:
        ASSIGN cCompanyCode = Token.Company-ID.   
      END. 
      IF cCompanyCode = "" THEN DO:
      //ASSIGN cCompanyCode = "I". 
      FIND FIRST cmpny NO-LOCK NO-ERROR.
      IF AVAILABLE cmpny THEN cCompanyCode = CMPNY.COMPANY-CODE.
      MESSAGE "Company " cCompanyCode 
      VIEW-AS ALERT-BOX.
      END. 
  END. 
  
  IF ipcToken NE "BATCH" THEN 
  DO:
      FIND FIRST APIDATA WHERE APIDATA.SALES-REP-ID EQ ipcSalesRepId 
                           AND APIDATA.Company EQ cCompanyCode 
                           AND APIDATA.APIName EQ "GETCUSTOMER" NO-LOCK NO-ERROR.
      IF AVAILABLE APIDATA THEN
      DO:
         COPY-LOB FROM APIDATA.Data1 TO oplcSalespersonData.
         opiStatusCode = 200. 
         //COPY-LOB APIDATA.Data1 TO FILE "C:\Users\cdisixto\Desktop\APIDATA-Produccion\DelBackend.txt" APPEND.
         //COPY-LOB oplcSalespersonData TO FILE "C:\Users\cdisixto\Desktop\APIDATA-Produccion\DelBackendVariable.txt" APPEND.
         RETURN.
      END.                         
  END.    
  ASSIGN 
    objCustomer       = NEW SalesmanCustomersData(INPUT ipcToken)
    objTokenMgmt      = NEW TokenManagement(INPUT ipcToken)
    objCommonSrc      = NEW CommonSource(INPUT ipcToken)
    salesDataJsonObj  = NEW JsonObject()
    customerJsonObj   = NEW JsonObject()
    customerJsonArray = NEW JsonArray()
    blankJsonArray    = NEW JsonArray().
    
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /* Get multilingual message for blank language id */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200LangBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
  
  ELSE
  DO: 
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      /* Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200InvalidLang,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
                                  
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
  END. /* ELSE */ 
    
  
  /*Validate the token of the user on every request*/
  IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
  DO:
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c403InvalidToken,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcToken) EQ "":U OR.. */ 
          
  IF TRIM(ipcSalesRepId) EQ "":U OR TRIM(ipcSalesRepId) EQ ? THEN
  DO:
    /* Get multilingual message for blank user */
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200UserBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcSalesRepId) EQ "":U OR.. */
  
  ELSE
  DO:
    FIND CSAMS WHERE CSAMS.sales-rep-id EQ ipcSalesRepId  NO-LOCK NO-ERROR.
    IF NOT AVAILABLE CSAMS THEN
    DO:
      /* Get multilingual message for invalid user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200InvalidUser,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT AVAILABLE CSAMS.. */ 
  END.
    
/*  ASSIGN                                   */
/*    lRegularSlsman = CSAMS.LAPTOP NO-ERROR.*/ // CSAMS.LAPTO IS OF NO USE AT this point. Marking this field as true 
   lRegularSlsman = YES.
  /* This method returns a new token if the token is expired in case of mobile user, and
   in case of web user it returns same token if not expired. Otherwise status failure */
  
  IF ipcTOKEN NE "BATCH" THEN 
  DO:  
      objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
                                          INPUT  ipcSalesRepId,
                                          INPUT  ipcLangID, 
                                          OUTPUT opcMessage,
                                          OUTPUT opcStatus,
                                          OUTPUT opcAppToken,
                                          OUTPUT opiStatusCode). 
                                                                                      
      IF opcMessage NE "":U THEN
        UNDO,THROW NEW AppError(opcMessage,1).
  END.
  ELSE 
   opcStatus = "Success".
  
    
  IF TRIM(ipcSortBy) EQ "":U OR TRIM(ipcSortBy) EQ ?  THEN
  DO:
    objCommonSrc:getMessages(INPUT  ipcLangID,
                             INPUT  ConstantInitializer:c200SortbyBlank,                                                              
                             OUTPUT cError,
                             OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
      
  END. /* IF TRIM(ipcSortBy) EQ "":U  */
  
  ELSE
  DO:
    IF LOOKUP(ipcSortBy,ipcSortList) EQ 0 THEN
    DO: 
      ASSIGN 
        ipcSortBy = "*":U.
      /* Get multilingual message for invalid sorting criteria */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200InvalidSortby,                                                              
                               OUTPUT opcMessage,
                               OUTPUT opiStatusCode).
                                                  
    END. /* IF LOOKUP(ipcSortBy,ipcSortList).. */   
  END.   
  
                                
  /* Checking if status is success */                                          
  IF opcStatus EQ "Success":U THEN
  DO:
    
    
    
    /* This method returns customer's list and details */
  /*  objCustomer:getCustomers(INPUT  ipcSalesRepId ,
                             INPUT  cCompanyCode,
                             INPUT  lRegularSlsman,
                             INPUT  ipcSortBy, 
                             INPUT  ipcLangID,
                             OUTPUT TABLE ttCustomer,
                             OUTPUT TABLE ttCustShippingAddress, 
                             OUTPUT TABLE ttOpenOrder, 
                             OUTPUT TABLE ttCustInvoice,
                             OUTPUT TABLE ttCustAmountOverdue,
                             OUTPUT TABLE ttCustBillingAddress,
                             OUTPUT cError,
                             OUTPUT opiStatusCode). */
                                  
     objCustomer:getAllCustomers(INPUT  ipcSalesRepId ,
                             INPUT  cCompanyCode,
                             INPUT  lRegularSlsman,
                             INPUT  ipcSortBy, 
                             INPUT  ipcLangID,
                             OUTPUT TABLE ttCustomer,
                             OUTPUT TABLE ttCustShippingAddress, 
                             OUTPUT TABLE ttOpenOrder, 
                             OUTPUT TABLE ttCustInvoice,
                             OUTPUT TABLE ttCustAmountOverdue,
                             OUTPUT TABLE ttCustBillingAddress,
                             OUTPUT cError,
                             OUTPUT opiStatusCode).                          
      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
  /* 
   OUTPUT TO "C:\Users\bsantiago\Desktop\FeatureAllCustomer-Impec\ttCustShippingAddressImpec.txt" APPEND.
                                         FOR EACH ttCustShippingAddress NO-LOCK:
                                             DISPLAY ttCustShippingAddress with 1 COL.
                                         END.
                                         OUTPUT CLOSE.   
                                         
                                         MESSAGE "Voy armar el Json."
                                         VIEW-AS ALERT-BOX.*/
 
         
    salesDataJsonObj:READ(DATASET opdsSalespersonData:HANDLE).
        
    IF salesDataJsonObj:Has(INPUT "customers":U) THEN
    DO:    
      ASSIGN 
        customerJsonArray = salesDataJsonObj:GetJsonArray("customers":U) NO-ERROR.
             
      DO iarrayIndex = 1 TO customerJsonArray:LENGTH:
        ASSIGN 
          customerJsonObj = customerJsonArray:GetJsonObject(INPUT iarrayIndex).
          
        IF NOT customerJsonObj:Has( INPUT "customer_shipping_addresses":U) THEN
        DO:
          ASSIGN 
            lCheck = TRUE. 
          customerJsonObj:add("customer_shipping_addresses":U,INPUT blankJsonArray). 
        END. /* IF NOT customerJsonObj:Has( INPUT "customer_shipping.. */
           
        IF NOT customerJsonObj:Has( INPUT "customer_billing_address":U) THEN
        DO:
          ASSIGN 
            lCheck = TRUE. 
          customerJsonObj:add("customer_billing_address":U,INPUT blankJsonArray). 
        END. /* IF NOT customerJsonObj:Has( INPUT "customer_billing.. */
                             
        IF NOT customerJsonObj:Has( INPUT "open_orders":U) THEN
        DO:
          ASSIGN 
            lCheck = TRUE. 
          customerJsonObj:add("open_orders":U,INPUT blankJsonArray). 
        END. /*  IF NOT customerJsonObj:Has( INPUT "open_orders.. */
          
        IF NOT customerJsonObj:Has( INPUT "customer_overdues":U) THEN
        DO:
          ASSIGN 
            lCheck = TRUE. 
          customerJsonObj:add("customer_overdues":U,INPUT blankJsonArray). 
        END. /*  IF NOT customerJsonObj:Has( INPUT "customer_overdues.. */
          
        IF NOT customerJsonObj:Has( INPUT "customer_invoices":U) THEN
        DO:
          ASSIGN 
            lCheck = TRUE. 
          customerJsonObj:add("customer_invoices":U,INPUT blankJsonArray). 
        END. /* IF NOT customerJsonObj:Has( INPUT "customer_invoices.. */
           
        IF lCheck THEN 
          customerJsonArray:Set( INPUT iarrayIndex, INPUT customerJsonObj).
          
        ASSIGN 
          lCheck = FALSE.      
      END. /*  DO iarrayIndex = 1 TO customerJsonArray:Length.. */
          
      salesDataJsonObj:Set(INPUT "customers":U,INPUT customerJsonArray) NO-ERROR.
      ASSIGN 
        oplcSalespersonData = salesDataJsonObj:GetJsonText().
        
    END.  /* IF salesDataJsonObj:Has(INPUT "customers") THEN..*/
    
    ELSE
    DO:
       
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
      
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1). 
             
    END. /* ELSE of salesDataJsonObj:Has( INPUT "customers" ) */   
         
  END. /* IF opcStatus EQ "Success":U THEN */
  FIND FIRST APIDATA WHERE APIDATA.SALES-REP-ID EQ ipcSalesRepId 
                       AND APIDATA.Company EQ cCompanyCode 
                       AND APIDATA.APIName EQ "GETCUSTOMER" NO-LOCK NO-ERROR.
                       
  IF NOT AVAILABLE APIDATA THEN 
     CREATE APIDATA.
  FIND CURRENT APIDATA EXCLUSIVE-LOCK NO-WAIT NO-ERROR.   
  IF AVAILABLE APIDATA THEN 
  DO:
      
      ASSIGN APIDATA.APIName = "GETCUSTOMER"
             APIDATA.Company =  cCompanyCode
             APIDATA.SALES-REP-ID = ipcSalesRepId
             APIDATA.LastUpdated  = TODAY.
     COPY-LOB FROM oplcSalespersonData TO APIDATA.Data1 NO-ERROR.     
  END.                                                                
  CATCH errorObj AS AppError:           
    ASSIGN 
      opcMessage = errorObj:GetMessage(1).  
  END CATCH.
    
  FINALLY:
    IF VALID-OBJECT(objCustomer)       THEN    
      DELETE OBJECT objCustomer.
    IF VALID-OBJECT(objCommonSrc)      THEN  
      DELETE OBJECT objCommonSrc.
    IF VALID-OBJECT(objTokenMgmt)      THEN
      DELETE OBJECT objTokenMgmt. 
    IF VALID-OBJECT(salesDataJsonObj)  THEN
      DELETE OBJECT salesDataJsonObj.  
    IF VALID-OBJECT(customerJsonObj)   THEN
      DELETE OBJECT customerJsonObj.
    IF VALID-OBJECT(customerJsonArray) THEN
      DELETE OBJECT customerJsonArray.
    IF VALID-OBJECT(blankJsonArray)    THEN
      DELETE OBJECT blankJsonArray.              
    
    IF VALID-HANDLE(hSharedVar)        THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
    
  END FINALLY.
    
END METHOD. 

     
/*------------------------------------------------------------------------------
  Purpose: This method returns all company details. It also returns literal 
           details for all languages available in database at initial screen.
  Input Parameters: 1.ipcLangID - Language id.
   
  Output Parameters:1.opcError        - returns error if any,
                    2.oplcSetupJSON   - contains literal details,
                    3.ttCompany       - temp-table contains company details.
  Notes:
 ------------------------------------------------------------------------------*/
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID systemSetup(INPUT  ipcLangID     AS CHARACTER,                                                   
  OUTPUT oplcSetupJSON AS LONGCHAR,
  OUTPUT opiStatusCode AS INTEGER,
  OUTPUT TABLE ttCompany,
  OUTPUT opcError      AS CHARACTER):    
                                                         
  DEFINE VARIABLE objCommon             AS CLASS CommonSource NO-UNDO.
  DEFINE VARIABLE objCDIsetup           AS CLASS JsonObject   NO-UNDO.
  DEFINE VARIABLE objCDILangEnglish     AS CLASS JsonObject   NO-UNDO.
  DEFINE VARIABLE objCDILangSpanish     AS CLASS JsonObject   NO-UNDO.
  DEFINE VARIABLE objCDIEnglishLiterals AS CLASS JsonObject   NO-UNDO.
  DEFINE VARIABLE objCDISpanishLiterals AS CLASS JsonObject   NO-UNDO.
  DEFINE VARIABLE objCDILangArray       AS CLASS JsonArray    NO-UNDO.
  DEFINE VARIABLE JsonArrLiterals       AS CLASS JsonArray    NO-UNDO.
      
  ASSIGN 
    objCommon             = NEW CommonSource()
    objCDIsetup           = NEW JsonObject()
    objCDILangEnglish     = NEW JsonObject()
    objCDILangSpanish     = NEW JsonObject()
    objCDIEnglishLiterals = NEW JsonObject()
    objCDISpanishLiterals = NEW JsonObject()
    objCDILangArray       = NEW JsonArray().  
     
  /* If input parameter 'ipcLangID' is blank then it will find literals for all languages */
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO: 
    ASSIGN 
      ipcLangID = "*":U.
    /* This method returns all company details available in database  */                       
    objCommon:getCompanyCode(OUTPUT TABLE ttCompany,
      OUTPUT cError).
                           
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
        
  END. /* IF ipcLangID EQ "":U THEN */ 
    
  /* This method returns all literals details for the available languages */
    
  objCommon:returnLiterals(INPUT  ipcLangID,
    OUTPUT TABLE ttEnglishLit,
    OUTPUT TABLE ttSpanishLit,
    OUTPUT cError,
    OUTPUT opiStatusCode).  
     
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
         
  /* Building JSON format */
    
  FOR EACH ttEnglishLit WHERE ttEnglishLit.LabelName NE "":U AND ttEnglishLit.LabelValue NE "":U :
    objCDIEnglishLiterals:ADD(INPUT ttEnglishLit.LabelName, INPUT ttEnglishLit.LabelValue).
  END. /*FOR EACH ttEnglishLit */
    
  FOR EACH ttSpanishLit WHERE ttSpanishLit.LabelName NE "":U AND ttSpanishLit.LabelValue NE "":U :  
    objCDISpanishLiterals:ADD(INPUT ttSpanishLit.LabelName, INPUT ttSpanishLit.LabelValue).
  END. /*FOR EACH ttSpanishLit */
    
  IF TEMP-TABLE ttEnglishLit:HAS-RECORDS THEN
  DO:
    objCDILangEnglish:ADD(INPUT "languageId":U,INPUT "0":U).
    objCDILangEnglish:ADD(INPUT "languageName":U,INPUT "English":U).
    objCDILangEnglish:ADD(INPUT "literals":U,INPUT objCDIEnglishLiterals).
    objCDILangArray:ADD(INPUT objCDILangEnglish).
      
  END. /*IF TEMP-TABLE ttEnglishLit:HAS-RECORDS..*/

  IF TEMP-TABLE ttSpanishLit:HAS-RECORDS  THEN
  DO:
    objCDILangSpanish:ADD(INPUT "languageId":U,INPUT "1":U).
    objCDILangSpanish:ADD(INPUT "languageName":U,INPUT "Spanish":U).
    objCDILangSpanish:ADD(INPUT "literals":U,INPUT objCDISpanishLiterals).
    objCDILangArray:ADD(INPUT objCDILangSpanish).
      
  END. /* IF TEMP-TABLE ttSpanishLit:HAS-RECORDS.. */

  objCDIsetup:ADD(INPUT "setup_info":U, INPUT objCDILangArray).
   
  ASSIGN 
    oplcSetupJSON = objCDIsetup:GetJsonText()   
    opiStatusCode = 200.
    
  /*Code for multilingual support - supporting 'N' languages without multiple temp-tables     
  objCommon:reLiterals(INPUT  ipcLangID,
                       OUTPUT JsonArrLiterals,
                       OUTPUT cError,
                       OUTPUT opiStatusCode).  
     
  objCDIsetup:ADD(INPUT "setup_info":U, INPUT JsonArrLiterals).
  ASSIGN oplcSetupJSON = objCDIsetup:GetJsonText()   
         opiStatusCode = 200.
  */
    
  CATCH errorObj AS AppError:           
    ASSIGN 
      opcError = errorObj:GetMessage(1).
       // opcError = opcError + ",":U + cError NO-ERROR.   
  END CATCH.
    
  FINALLY:
    IF VALID-OBJECT(objCDIsetup)           THEN
      DELETE OBJECT objCDIsetup.
        
    IF VALID-OBJECT(objCDILangEnglish)     THEN
      DELETE OBJECT objCDILangEnglish.
        
    IF VALID-OBJECT(objCDILangSpanish)     THEN
      DELETE OBJECT objCDILangSpanish.
        
    IF VALID-OBJECT(objCDIEnglishLiterals) THEN
      DELETE OBJECT objCDIEnglishLiterals.
        
    IF VALID-OBJECT(objCDISpanishLiterals) THEN
      DELETE OBJECT objCDISpanishLiterals.
        
    IF VALID-OBJECT(objCDILangArray)       THEN
      DELETE OBJECT objCDILangArray.
        
    IF VALID-OBJECT(objCommon)             THEN
      DELETE OBJECT objCommon.     
    
    IF VALID-HANDLE(hSharedVar)            THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
    
  END FINALLY.                                                               
      
END METHOD.
  
  
/*----------------------------------------------------------------------------------
Purpose: This method is used for getting the current locations of the salesperson
         under a supervisor.
            
Input Parameters: 1 .ipcUserName   - Supervisor ID (CSAMS.Sales-rep-id),
                  2. ipcPassword   - authentcation password (CSAMS.password),                     
                  3. ipcLangID     - language Id,
                  5. ipcUserType   - either mobile or web user,
                  6. ipcCompanyID  - company id of the logged in user/salesperson.
                    
Output Parameters:1. opcError            - returns error if any,
                  2. oplcLoginData       - salesperson's sales , carts, overdue-
                                           customer information,
                  3. opiStatusCode       - HTTP status code.
Notes:
-------------------------------------------------------------------------------------*/
  
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID supervisorLogin(INPUT  ipcUserName        AS CHARACTER,
                                  INPUT  ipcPassword        AS CHARACTER, 
                                  INPUT  ipcLangID          AS CHARACTER,
                                  INPUT  ipcUserType        AS CHARACTER, 
                                  INPUT  ipcCompanyID       AS CHARACTER,
                                  INPUT  ipiNumberOfDays    AS INTEGER,
                                  INPUT  ipcDetailType      AS CHARACTER, 
                                  OUTPUT opcError           AS CHARACTER,
                                  OUTPUT opcSupervisor      AS CHARACTER,
                                  OUTPUT opcSupervisorName  AS CHARACTER, 
                                  OUTPUT opiStatusCode      AS INTEGER,
                                  OUTPUT TABLE ttSalesRepLocation):
       
  DEFINE VARIABLE objLogin        AS CLASS     Login        NO-UNDO.
  DEFINE VARIABLE objSalesman     AS CLASS     SalesmanInfo NO-UNDO.
  DEFINE VARIABLE objCommonSrc    AS CLASS     CommonSource NO-UNDO.
  DEFINE VARIABLE objLocationMgmt AS CLASS     LocationMgmt NO-UNDO.
  DEFINE VARIABLE userToken       AS CHARACTER NO-UNDO.
                
  ASSIGN 
    objLogin        = NEW Login()
    objSalesman     = NEW SalesmanInfo()
    objCommonSrc    = NEW CommonSource()
    objLocationMgmt = NEW LocationMgmt(). 
    
  IF TRIM(ipcDetailType) EQ "":U OR TRIM(ipcDetailType) EQ ? THEN
  DO:
    /*Get multilingual message for blank report type */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200ReportTypeBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
      
  END. /* IF TRIM(ipcDetailType) EQ "":U OR.. */
    
  IF TRIM(ipcDetailType) NE "Report":U AND TRIM(ipcDetailType) NE "Live":U THEN
  DO:
    /* Get multilingual message for invalid report type */
    
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200InvalidReportType,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
    
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
      
  END. /* IF TRIM(ipcDetailType) NE "Report":U AND TRIM(ipcDetailType) NE "Live":U */ 
     
      
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /*Get multilingual message for blank languageId */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200LangBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
      
  END. /* IF TRIM(ipcLangID) EQ "":U OR.. */   
  ELSE
  DO: 
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      /*Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidLang,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /*  IF NOT CAN-FIND(CDILANGUAGE.. */       
  END. /* ELSE.. */
        
  IF (TRIM(ipcUserName) EQ "":U OR TRIM(ipcUserName) EQ ?) AND (TRIM(ipcPassword) EQ "":U OR TRIM(ipcPassword) EQ ?) THEN 
  DO:
    /* Get multilingual message for blank username and password */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200UserPswdBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcUserName) EQ "":U AND TRIM(ipcPassword) EQ "":U.. */ 
        
  IF TRIM(ipcUserName) EQ "":U OR TRIM(ipcUserName) EQ ? THEN
  DO:
    /*Get multilingual message for blank username */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200UserBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*  IF TRIM(ipcUserName) EQ "":U OR.. */
     
  ELSE
  DO: 
    IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserName) NO-LOCK) THEN
    DO:
      /*Get multilingual message for invalid user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidUser,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
                                  
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.        
  END. 
        
  IF TRIM(ipcPassword) EQ "":U OR TRIM(ipcPassword) EQ ? THEN 
  DO:
    /*Get multilingual message for blank password */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200PswdBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcPassword) EQ "":U.. */
                        
  IF TRIM(ipcCompanyID) EQ "":U OR TRIM(ipcCompanyID) EQ ? THEN
  DO:
    /*Get multilingual message for blank company */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200CmpnyBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*  IF TRIM(ipcCompanyID) EQ "":U OR.. */
    
  ELSE 
  DO: 
    IF NOT CAN-FIND(CMPNY WHERE CMPNY.COMPANY-CODE EQ TRIM(ipcCompanyID) NO-LOCK) THEN
    DO:
      /*Get multilingual message for invalid company */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidCmpny,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
          
    END. /* IF NOT CAN-FIND(CMPNY WHERE.. */         
  END. /* ELSE.. */  
      
  /* This method validates user credentials and returns valid token of a user when successfully logged-in */ 
  FIND FIRST csams WHERE sales-rep-id EQ ipcUserName NO-LOCK NO-ERROR. 
  IF AVAILABLE csams THEN  
    ASSIGN opcSupervisor     = ipcUserName
      opcSupervisorName = csams.sales-name.   
                   
      
  objLogin:validateSupervisor(INPUT  ipcUserName,
    INPUT  ipcPassword,
    INPUT  ipcLangID,
    INPUT  ipcUserType,
    INPUT  ipcCompanyID,
    OUTPUT userToken,                                  
    OUTPUT cError,
    OUTPUT lLoginStatus,
    OUTPUT opiStatusCode).  
    
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
    
                    
  IF lLoginStatus THEN
  DO:  
      
    /* Method used to return details of a customer */         
    objLocationMgmt:getSalesmanLocations(INPUT ipcUserName, /*Supervisor ID*/ 
      INPUT ipiNumberOfDays, 
      INPUT ipcLangId, 
      INPUT ipcDetailType,                                        
      OUTPUT opcError,
      OUTPUT opiStatusCode,
      OUTPUT TABLE ttSalesRepLocation).
                                                                         
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
                                         
    ASSIGN 
      opiStatusCode = 200. 
                         
  END. /* IF lLoginStatus THEN.. */  
         
  CATCH errorObj AS AppError:             
    ASSIGN 
      opcError = errorObj:GetMessage(1).
  END CATCH.    
    
  FINALLY:
    IF VALID-OBJECT(objLogin) THEN  
      DELETE OBJECT objLogin.
    IF VALID-OBJECT(objSalesman) THEN
      DELETE OBJECT objSalesman.
    IF VALID-OBJECT(objCommonSrc) THEN
      DELETE OBJECT objCommonSrc.
                 
    IF VALID-HANDLE(hSharedVar) THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
    
  END FINALLY.
  
END METHOD.
  
/*------------------------------------------------------------------------------
 Purpose: This method is used to store the information of user's check in.
 Input Parameters: 1.ipcToken      - User-token,
                   2.ipcCustNum    - customer number,
                   3.ipcSalesRepId - salesrep id for which customers to be fetched,
                   4.ipcLongitude  - longitude information of customer,
                   5.ipcLattitude  - latitude information of customer,
                   6.ipiCheckinTime- check in time of user,
                   7.ipcLangID     - language id.
                     
 Output Parameters:1.opcAppToken        - it contains new token if old token expired 
                                           otherwise return old token,
                   2.opcError            - errors if any,                       
                   3.opiStatusCode       - HTTP response code.
                     
 Notes:
------------------------------------------------------------------------------*/
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID updateCheckInTime(INPUT  ipcToken       AS CHARACTER,
  INPUT  ipcCustNum     AS CHARACTER,
  INPUT  ipcSalesRepId  AS CHARACTER,
  INPUT  ipcLongitude   AS CHARACTER,
  INPUT  ipcLattitude   AS CHARACTER,
  INPUT  ipiCheckinTime AS INT64,
  INPUT  ipcLangID      AS CHARACTER,
  OUTPUT opcAppToken    AS CHARACTER, 
  OUTPUT opcError       AS CHARACTER,
  OUTPUT opiStatusCode  AS INTEGER):
	 
  DEFINE VARIABLE outStatus    AS CHARACTER NO-UNDO.
	                                         
  DEFINE VARIABLE objSalesman  AS CLASS     SalesmanInfo    NO-UNDO.
  DEFINE VARIABLE objCommonSrc AS CLASS     CommonSource    NO-UNDO.   
  DEFINE VARIABLE objTokenMgmt AS CLASS     TokenManagement NO-UNDO.     
       
  objSalesman  = NEW SalesmanInfo(INPUT ipcToken).
  objCommonSrc = NEW CommonSource(INPUT ipcToken).
  objTokenMgmt = NEW TokenManagement(INPUT ipcToken).
      
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /* Get multilingual message for blank language id*/
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200LangBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
  ELSE
  DO: 
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      /* Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidLang,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
                                  
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE CDILANGUAGE.. */       
  END. /* ELSE */
      
      
  IF TRIM(ipcSalesRepId) EQ "":U OR TRIM(ipcSalesRepId) EQ ? THEN
  DO:
    /* Get multilingual message for blank user*/
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200UserBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*IF TRIM(ipcSalesRepId) EQ ""..*/  
  ELSE
  DO: 
    IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcSalesRepId) NO-LOCK) THEN
    DO:
      /* Get multilingual message for invalid user*/
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidUser,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
                                  
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /*  IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID... */      
  END. /* ELSE */
      
      
  IF TRIM(ipcCustNum) EQ "":U OR TRIM(ipcCustNum) EQ ? THEN
  DO:
    /* Get multilingual message for blank customer number */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200CustBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*IF TRIM(ipcCustNum) EQ ""*/  
  ELSE
  DO: 
    IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNum) NO-LOCK) THEN
    DO:
      /* Get multilingual message for invalid customer */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
                                 
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */      
  END.
      
  IF TRIM(ipcLongitude) EQ "":U OR TRIM(ipcLongitude) EQ ?  OR 
    TRIM(ipcLattitude) EQ "":U OR TRIM(ipcLattitude) EQ ? THEN
  DO:
    /* Get multilingual message for blank latitude and longitude data */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200LongLatBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*IF TRIM(ipcLongitude) EQ ""*/  
      
  IF ipiCheckinTime EQ 0 OR ipiCheckinTime EQ ? THEN
  DO:
    /* Get multilingual message for blank check in time */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200CheckinTimeStampBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*IF TRIM(ipiCheckinTime) EQ ""*/   
    
  IF VALID-OBJECT(objTokenMgmt) THEN
  DO:    
    objTokenMgmt:loggedInUserTokenRenew(INPUT ipcToken,
      INPUT ipcSalesRepId,                                         
      INPUT ipcLangID, 
      OUTPUT cError,
      OUTPUT outStatus,
      OUTPUT opcAppToken,  
      OUTPUT opiStatusCode).
                                        
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).                                        
  END.
      
  IF VALID-OBJECT(objSalesman) THEN
  DO: 
    objSalesman:salesmanLocationUpdate(INPUT ipcCustNum,
      INPUT ipcLangID, 
      INPUT ipcSalesRepId,  
      INPUT ipcLongitude,      /*12.920122*/ 
      INPUT ipcLattitude,     /*77.666696*/
      INPUT ipiCheckinTime,  /*Checkin Timestamp*/                                        
      OUTPUT cError,
      OUTPUT opiStatusCode).
                                                 
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).                                  
  END. /*IF VALID-OBJECT(objSalesman)*/                                                        
      
  CATCH errorObj AS AppError:           
    ASSIGN 
      opcError = errorObj:GetMessage(1).   
  END CATCH.
      
  FINALLY:
    IF VALID-OBJECT(objCommonSrc) THEN
      DELETE OBJECT objCommonSrc.
    IF VALID-OBJECT(objSalesman) THEN    
      DELETE OBJECT objSalesman.
    
    IF VALID-HANDLE(hSharedVar) THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
    
  END FINALLY.
      
END METHOD.  
  
/*------------------------------------------------------------------------------
 Purpose: This method is used to get all the items of a particular category.
          In case of mobile user, this method will provide only the last modified items. 
 Input Parameters: 1.ipcUserId            - Username/Userid of a logged-in user.
                   2.ipiLastSyncTimestamp - Last sync timestamp.
                   3.ipcCustNum           - Customer number for whom items to be fetched.
                   4.ipcClassCode         - Category id for which items to be fetched.
                   5.ipcToken             - Active User-token, 
                   6.ipcLangID            - Language-id.
                     
 Output Parameters:1.oplcItemsJSON       - Containing list of all the items.
                   2.opcAppToken         - It contains new token if old token expired 
                                           otherwise return old token.
                   3.opcError            - Errors if any.
                   4.opiStatusCode       - HTTP status code.                        
                     
 Notes: 
------------------------------------------------------------------------------*/
  
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID getCategoryItemsPagination(INPUT-OUTPUT ipcLastRowID         AS CHARACTER,                                      
  INPUT        ipcUserId            AS CHARACTER,
  INPUT        ipiLastSyncTimestamp AS INT64,
  INPUT        ipcCustNum           AS CHARACTER,
  INPUT        ipcClassCode         AS CHARACTER,
  INPUT        ipcToken             AS CHARACTER,
  INPUT        ipcLangId            AS CHARACTER,
  OUTPUT       oplcItemsJSON        AS LONGCHAR,
  OUTPUT       lNoMoreProdFound     AS LOGICAL,
  OUTPUT       opcAppToken          AS CHARACTER,
  OUTPUT       opcError             AS CHARACTER,                                      
  OUTPUT       opiStatusCode        AS INTEGER):
     
    
  DEFINE VARIABLE objCommonSrc  AS CLASS     CommonSource       NO-UNDO.  
  DEFINE VARIABLE objCategory   AS CLASS     CategoryFilterItem NO-UNDO.
  DEFINE VARIABLE objTokenMgmt  AS CLASS     TokenManagement    NO-UNDO.
  DEFINE VARIABLE itemJsonArr   AS CLASS     JsonArray          NO-UNDO.
  DEFINE VARIABLE itemJsonObj   AS CLASS     JsonObject         NO-UNDO.
    
  DEFINE VARIABLE outStatus     AS CHARACTER NO-UNDO.
  DEFINE VARIABLE opcItem       AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cUserType     AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iWareHouseNo  AS INTEGER   NO-UNDO.
  DEFINE VARIABLE iNowTimeStamp AS INT64     NO-UNDO.
  DEFINE VARIABLE lTopSeller    AS LOGICAL   NO-UNDO.
  DEFINE VARIABLE cCompnyCode   AS CHARACTER NO-UNDO.
  DEFINE VARIABLE iBatchSize    AS INTEGER   NO-UNDO.
  DEFINE VARIABLE lQueryOffEnd  AS LOGICAL   NO-UNDO.
       
  DEFINE VARIABLE iLoop         AS INTEGER   NO-UNDO.
   
  DEFINE QUERY lvQuery   FOR CINV1 SCROLLING.
  ASSIGN 
    objCommonSrc = NEW CommonSource(INPUT ipcToken).
  ASSIGN 
    objTokenMgmt = NEW TokenManagement(INPUT ipcToken)
    objCategory  = NEW CategoryFilterItem(INPUT ipcToken)
    itemJsonArr  = NEW JsonArray()
    iBatchSize   = 50. /* Decides the batch size */
     
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /*Get multilingual message for blank language id */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200LangBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
      
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcLangID) EQ "":U.. */  
  ELSE
  DO: 
    IF NOT CAN-FIND(FIRST CDILANGUAGE WHERE CDILANGUAGE.language-id EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      /*Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidLang,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT CAN-FIND(CDILANGUAGE..) */        
  END. /* ELSE */ 
    
    
    
  IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
  DO:
    /* Get multilingual message for blank user*/
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200UserBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
        
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END.
      
  IF TRIM(ipcLastRowID) NE "":U AND trim(ipcLastRowID) NE ? THEN
  DO:  
    IF NOT CAN-FIND(CINV1 WHERE ROWID(CINV1) EQ TO-ROWID(ipcLastRowID)) THEN
    DO:
      /* Get multilingual message for Invalid row ID */
        
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidRowID,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END.
  END.
    
    
  /* get current time stamp */
  IF VALID-OBJECT(objCommonSrc) THEN 
  DO:
    ASSIGN 
      iNowTimeStamp = objCommonSrc:getTimestamp(INPUT DATETIME-TZ(NOW),
                                                       INPUT ipcLangID,
                                                       OUTPUT cError,      
                                                       OUTPUT opiStatusCode).
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).                                                
  END.    
                                                
  /* Check whether the recieved timestamp is valid */                                               
  IF ipiLastSyncTimestamp GT iNowTimeStamp THEN 
  DO:
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200InvalidTimeStamp,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).                               
  END.
    
  IF TRIM(ipcClassCode) EQ "":U OR TRIM(ipcClassCode) EQ ? THEN
  DO:
    /*Get multilingual message for blank category */
    objCommonSrc:getMessages(INPUT  ipcLangId,
      INPUT  ConstantInitializer:c200CatBlank,
      OUTPUT cError,
      OUTPUT opiStatusCode).
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).

  END. /* IF TRIM(ipcClassCode) EQ "":U.. */
    
  ELSE
  DO:
    IF NOT CAN-FIND (IVBRAND WHERE IVBRAND.class-code EQ TRIM(ipcClassCode) NO-LOCK) THEN
    DO:
      /* Get multilingual message for invalid category */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidCategory,
        OUTPUT cError,
        OUTPUT opiStatusCode).

      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
    END.  /*END of IF NOT CAN-FIND ( IVBRAND WHERE..*/
 
  END.  /*Else part of IF TRIM(ipcClassCode) EQ "":U..*/
  IF VALID-OBJECT(objTokenMgmt) THEN
  DO:  
    /* This method returns a new token if the token is expired in case of mobile user, and
       in case of web user it returns same token if not expired. Otherwise status failure */     
    objTokenMgmt:loggedInUserTokenRenew(INPUT ipcToken,
      INPUT ipcUserId,                                         
      INPUT ipcLangID, 
      OUTPUT cError,
      OUTPUT outStatus,
      OUTPUT opcAppToken,  
      OUTPUT opiStatusCode).
                                        
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).            
  END.
          
  IF outStatus EQ "Success":U THEN
  DO: 
    ASSIGN 
      ipcToken = opcAppToken.
    /* To find the warehouse number and user-type associated with the logged-in user */
    FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
      ASSIGN 
        cUserType = Token.User-Type.    
      FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK NO-ERROR.
      IF AVAILABLE cmpny THEN 
        ASSIGN 
          iWareHouseNo = CMPNY.WHS-LOCATION 
          cCompnyCode  = CMPNY.COMPANY-CODE. 
                  
    END. /* FOR FIRST Token..*/  
     
    /* Find top-seller item for a specific category by calling topSellerItem(..) method*/ 
    /* objCategory:topSellerItem(INPUT ipcClassCode,
      INPUT cCompnyCode,
      OUTPUT opcItem).  */                                
          
    IF cUserType EQ ConstantInitializer:cMobileUser THEN
    DO:
      IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
      DO:
        /*Get multilingual message for invalid user */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidUser,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                  
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. 
        
      IF TRIM(ipcCustNum) EQ "":U OR TRIM(ipcCustNum) EQ ? THEN
      DO:
        /* Get multilingual message for blank customer number */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200CustBlank,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /*IF TRIM(ipcCustNum) EQ ""*/  
      ELSE
      DO: 
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNum) NO-LOCK) THEN
        DO:
          /* Get multilingual message for invalid customer */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                 
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
      END. /* ELSE OF TRIM(ipcCustNum) EQ "":U OR TRIM(ipcCustNum) EQ ? */
        
          
        /* FOR EACH CINV1 WHERE CINV1.CLASS-CODE   EQ     ipcClassCode        AND
                             CINV1.ITEM-NUMBER  BEGINS cCompnyCode         AND
                         NOT CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U NO-LOCK: */
          
          IF CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U OR CINV1.LINE-UP = "D":U OR CINV1.LINE-UP = "W":U OR CINV1.LINE-UP = "X":U THEN NEXT.
      /* Records batching logic */
     /* OPEN QUERY lvQuery FOR EACH cinv1 WHERE  CINV1.ITEM-NUMBER  BEGINS cCompnyCode
        AND  CINV1.CLASS-CODE   EQ     ipcClassCode 
        AND  (CINV1.LINE-UP NE "D":U OR CINV1.LINE-UP NE "W":U OR CINV1.LINE-UP NE "X":U)
        /*AND NOT CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U*/   
        AND     CINV1.Timestamp GT     ipiLastSyncTimestamp NO-LOCK.    */
        
      OPEN QUERY lvQuery FOR EACH cinv1 WHERE  CINV1.COMPANY-CODE EQ cCompnyCode
        AND  CINV1.CLASS-CODE   EQ     ipcClassCode NO-LOCK.
       // AND     CINV1.Timestamp GT     ipiLastSyncTimestamp NO-LOCK.                           
         
      /* when row id is populated (Not first tym) */
      IF TO-ROWID(ipcLastRowID) <> ? THEN
      DO:
        REPOSITION lvQuery TO ROWID TO-ROWID(ipcLastRowID).
        GET NEXT lvQuery.
      END. /* IF TO-ROWID(ipcLastRowID) <> ? */
        
      DO iLoop = 1 TO iBatchSize:
          
        GET NEXT lvQuery.
                    
        IF QUERY-OFF-END("lvQuery") THEN
        DO:
          /*objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200NoMoreItemRecords,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).*/
             
          ASSIGN 
            lQueryOffEnd = TRUE.  
          LEAVE.

        END. /* IF QUERY-OFF-END("lvQuery") THEN */
          
        /* Fetching items based on the class-code and last sync timestamp */
        /*                     
        FOR EACH cinv1 WHERE CINV1.CLASS-CODE       EQ     ipcClassCode         AND
                             CINV1.ITEM-NUMBER      BEGINS cCompnyCode          AND                                     
                             NOT CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U  AND                              
                             CINV1.Timestamp        GT ipiLastSyncTimestamp     NO-LOCK: */
                               
        IF CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U THEN NEXT.
        IF (CINV1.LINE-UP EQ "D":U OR CINV1.LINE-UP EQ "W":U OR CINV1.LINE-UP EQ "X":U) THEN NEXT.   
        IF CINV1.ITEM-NUMBER EQ opcItem THEN
          ASSIGN lTopSeller = TRUE.
        ELSE
          ASSIGN lTopSeller = FALSE.            
         /* This code is to check if any customer has contract pricing. Requested by SabaTier */
          FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNum) NO-LOCK NO-ERROR.
          
          IF AVAILABLE CCSMS AND CCSMS.CONTRACT-IND EQ "A" THEN 
          DO:
           IF NOT CAN-FIND(CINV3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER AND CINV3.PRICE-LIST EQ CCSMS.PRICE-LIST ) THEN NEXT.
           
          END. 
          FIND FIRST CINV2 WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
                             AND CINV2.WAREHOUSE-NO EQ iWareHouseNo NO-LOCK NO-ERROR.
/*            FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"*/
/*                                 AND PARAMFL.COMPANY-CODE = cCompnyCode                  */
/*                                 AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.        */
/*            IF AVAILABLE paramfl AND AVAILABLE cinv2 THEN                                */
/*            DO:                                                                          */
/*                IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN NEXT.                 */
/*            END.                                                                         */
        objCategory:getCategoryAllItems(INPUT  ipcCustNum,
          INPUT  CINV1.CLASS-CODE,
          INPUT  CINV1.ITEM-NUMBER,
          INPUT  CINV1.DESCRIPTION,
          INPUT  CINV1.QTY-ONHAND,
          /*INPUT  CINV1.PICTURE,*/
          INPUT SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1),
          INPUT  CINV1.FABRIC,
          INPUT  CINV1.FAMILY,
          INPUT  CINV1.VENDOR-NO, 
          INPUT  CINV1.MAKE,
          INPUT  CINV1.BY-SIZE, 
          INPUT  CINV1.BY-COLOR,
          INPUT  lTopSeller,
          INPUT  cCompnyCode,
          INPUT  iWareHouseNo,
          OUTPUT itemJsonObj).
        
/*        itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).         */
/*        itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).*/
                              
        itemJsonArr:ADD(INPUT itemJsonObj). 
        ipcLastRowID = STRING(ROWID(CINV1)).                                
      /*END. /* FOR EACH cinv1... */ */
      END. /* DO iLoop = 1 TO iBatchSize:  */
                                                  
    END.
    /* for Webuser */
    ELSE
    DO: 
       
      IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
      DO:
        /*Get multilingual message for invalid user */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidUser,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                  
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END.   
               
     /* OPEN QUERY lvQuery FOR EACH cinv1 WHERE CINV1.ITEM-NUMBER  BEGINS cCompnyCode 
        AND CINV1.CLASS-CODE   EQ     ipcClassCode 
        AND (CINV1.LINE-UP NE "D" OR CINV1.LINE-UP NE "W":U OR CINV1.LINE-UP NE "X":U)NO-LOCK.   */                                               
      /*AND NOT CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U*/ 
      OPEN QUERY lvQuery FOR EACH cinv1 WHERE  CINV1.COMPANY-CODE EQ cCompnyCode
        AND  CINV1.CLASS-CODE   EQ     ipcClassCode NO-LOCK.  
      /* when row id is populated (Not first tym) */
      IF TO-ROWID(ipcLastRowID) <> ? THEN
      DO:           
        REPOSITION lvQuery TO ROWID TO-ROWID(ipcLastRowID) .            
        GET NEXT lvQuery.
        
      END. /* IF TO-ROWID(ipcLastRowID) <> ? */
        
      
      DO iLoop = 1 TO iBatchSize:
          
        GET NEXT lvQuery.                
        
        IF QUERY-OFF-END("lvQuery") = TRUE THEN
        DO:
          ASSIGN 
            lQueryOffEnd = TRUE.  
          LEAVE.
        END.
            
        /* Fetching items based on the class-code */              
        /* FOR EACH cinv1 WHERE CINV1.CLASS-CODE   EQ     ipcClassCode        AND
                                CINV1.ITEM-NUMBER  BEGINS cCompnyCode         AND
                            NOT CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U NO-LOCK: */
                       
        IF CINV1.ITEM-NUMBER  BEGINS cCompnyCode + "*":U THEN NEXT .
        IF (CINV1.LINE-UP EQ "D":U OR CINV1.LINE-UP EQ "W":U OR CINV1.LINE-UP EQ "X":U) THEN NEXT.   
        IF CINV1.ITEM-NUMBER EQ opcItem THEN
          ASSIGN lTopSeller = TRUE.
        ELSE
          ASSIGN lTopSeller = FALSE.
        /* This code is to check if any customer has contract pricing. Requested by SabaTier */
          FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK NO-ERROR.
          
          IF AVAILABLE CCSMS AND CCSMS.CONTRACT-IND EQ "A" THEN 
          DO:
           IF NOT CAN-FIND(CINV3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER AND CINV3.PRICE-LIST EQ CCSMS.PRICE-LIST ) THEN NEXT.
           
          END. 
          FIND FIRST CINV2 WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
                             AND CINV2.WAREHOUSE-NO EQ iWareHouseNo NO-LOCK NO-ERROR.
/*            FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"*/
/*                                 AND PARAMFL.COMPANY-CODE = cCompnyCode                  */
/*                                 AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.        */
/*            IF AVAILABLE paramfl AND AVAILABLE cinv2 THEN                                */
/*            DO:                                                                          */
/*                IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN NEXT.                 */
/*            END.                                                                         */
        objCategory:getCategoryAllItems(INPUT  ipcUserId,
          INPUT  CINV1.CLASS-CODE,
          INPUT  CINV1.ITEM-NUMBER,
          INPUT  CINV1.DESCRIPTION,
          INPUT  CINV1.QTY-ONHAND,
          /*INPUT  CINV1.PICTURE,*/
          INPUT SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1),
          INPUT  cinv1.fabric,
          INPUT  cinv1.family,
          INPUT  cinv1.vendor-no, 
          INPUT  cinv1.make,
          INPUT  cinv1.by-size,
          INPUT  CINV1.BY-COLOR,
          INPUT  lTopSeller,
          INPUT  cCompnyCode,
          INPUT  iWareHouseNo,
          OUTPUT itemJsonObj).
        
/*        itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).         */
/*        itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).*/
                                      
        itemJsonArr:ADD(INPUT itemJsonObj).
        ipcLastRowID = STRING(ROWID(CINV1)). 
          
      /* END. /* FOR EACH cinv1 WHERE cinv1.class-code...*/*/
      END. /* DO iLoop = 1 TO iBatchSize: */
                                              
    END. /* ELSE OF cUserType EQ ConstantInitializer:cMobileUser */               
      
    ASSIGN 
      oplcItemsJSON = itemJsonArr:GetJsonText()
      opiStatusCode = 200.
    //COPY-LOB oplcItemsJSON to file "c:\temp\json_string.txt".
    /*ipcLastRowID  = STRING(ROWID(CINV1)).*/
      
    IF lQueryOffEnd THEN   
    DO:
                                        
      ASSIGN 
        lNoMoreProdFound = TRUE.              
                                        
    END.      
      
  END. /* IF outStatus EQ "Success":U THEN */       
    
  CLOSE QUERY lvQuery.
    
  CATCH errorObj AS AppError:
    ASSIGN 
      opcError = errorObj:GetMessage(1).         
  END CATCH.

  FINALLY:
    INPUT CLOSE.  
    IF VALID-OBJECT(objCommonSrc) THEN
      DELETE OBJECT objCommonSrc.
    IF VALID-OBJECT(objTokenMgmt) THEN
      DELETE OBJECT objTokenMgmt.
    IF VALID-OBJECT(objCategory)  THEN
      DELETE OBJECT objCategory.
    IF VALID-OBJECT(itemJsonArr)  THEN
      DELETE OBJECT itemJsonArr. 
    IF VALID-OBJECT(itemJsonObj)  THEN
      DELETE OBJECT itemJsonObj.             
      
    /* Delete the persistent procedure */     
    IF VALID-HANDLE(hSharedVar) THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
    
  END FINALLY.

END METHOD.
  
/*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID setSlsmanLocation(INPUT ipcUserId       AS CHARACTER,
                                      INPUT ipcCustNumber   AS CHARACTER,
                                      INPUT ipcShipNumber   AS CHARACTER,
                                      INPUT ipcLattitude    AS CHARACTER,
                                      INPUT ipcLongitude    AS CHARACTER,
                                      INPUT ipcLangID       AS CHARACTER,
                                      INPUT ipiCheckInTime  AS INT64,
                                      INPUT ipiCheckOutTime AS INT64,
                                      INPUT ipiMode         AS INTEGER,
                                      INPUT ipcToken        AS CHARACTER,
                                      OUTPUT opcAppToken    AS CHARACTER,
                                      OUTPUT opcError       AS CHARACTER,
                                      OUTPUT opiStatusCode  AS INTEGER):
        
  DEFINE VARIABLE objTokenMgmt    AS CLASS     TokenManagement NO-UNDO.
  DEFINE VARIABLE objCommonSrc    AS CLASS     CommonSource    NO-UNDO.
  DEFINE VARIABLE objLocationMgmt AS CLASS     LocationMgmt    NO-UNDO.
        
  DEFINE VARIABLE cCustNumber     AS CHARACTER NO-UNDO.
  DEFINE VARIABLE opcStatus       AS CHARACTER NO-UNDO.     
  DEFINE VARIABLE cUserType       AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lReadJSONOK     AS LOGICAL   NO-UNDO.
  DEFINE VARIABLE cModeList       AS CHARACTER NO-UNDO INITIAL "0,1".
/*     MESSAGE ipcUserId "ipcUserId" SKIP */
/*    "ipcCustNumber" ipcCustNumber SKIP  */
/*    "ipcShipNumber" ipcShipNumber SKIP  */
/*    "ipcLattitude" ipcLattitude SKIP    */
/*    "ipcLongitude" ipcLongitude SKIP    */
/*    "ipiCheckInTime" ipiCheckInTime SKIP*/
/*    "ipiMode" ipiMode.                  */
         
  ASSIGN 
    objTokenMgmt = NEW TokenManagement(INPUT ipcToken)
    objCommonSrc = NEW CommonSource(INPUT ipcToken).
  objLocationMgmt   = NEW LocationMgmt(INPUT ipcToken).
               

        
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /* Get multilingual message for blank language id */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200LangBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
                
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
        
  ELSE
  DO: 
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      /* Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidLang,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
                                          
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
  END. /* ELSE */ 
        
  IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
  DO:
    /* Get multilingual message for blank user */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200UserBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
                
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
          
  IF TRIM(ipcLongitude) EQ "":U OR TRIM(ipcLongitude) EQ ?  OR 
    TRIM(ipcLattitude) EQ "":U OR TRIM(ipcLattitude) EQ ?  THEN
  DO:
    /* Get multilingual message for blank latitude and longitude data */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200LongLatBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
            
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*IF TRIM(ipcLongitude) EQ ""*/  
          
  MESSAGE ipiCheckinTime.
        
  IF ipiMode EQ 0 AND (ipiCheckinTime EQ 0 OR ipiCheckinTime EQ ?) THEN
  DO:
    /* Get multilingual message for blank check in time */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200CheckinTimeStampBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
            
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*IF TRIM(ipiCheckinTime) EQ ""*/
        
  IF ipiMode EQ 1 AND (ipiCheckOutTime EQ 0 OR ipiCheckOutTime EQ ?) THEN
  DO:
    /* Get multilingual message for blank check in time */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200CheckoutTimeStampBlank, /* Add msg */                                                             
      OUTPUT cError,
      OUTPUT opiStatusCode).
            
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /*IF TRIM(ipiCheckinTime) EQ ""*/
        
  IF ipiMode EQ ? THEN
  DO:
    /* Get multilingual message for blank check in time */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200BlankMode,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
            
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END.
        
  IF LOOKUP(STRING(ipiMode), cModeList) EQ 0 OR
    LOOKUP(STRING(ipiMode), cModeList) EQ ? THEN 
  DO:
          
    /* Get multilingual message for blank check in time */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200InvalidMode,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
            
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END.
        
  /* validate the token */
  objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
    INPUT  ipcUserId,
    INPUT  ipcLangID, 
    OUTPUT cError,
    OUTPUT opcStatus,
    OUTPUT opcAppToken,
    OUTPUT opiStatusCode). 
                                                                                          
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
        
  IF opcStatus EQ "Success":U THEN
  DO:   
    FIND FIRST Token WHERE Token.Token EQ ipcToken NO-LOCK NO-ERROR.
    IF AVAILABLE TOKEN THEN
      ASSIGN cUserType = Token.User-Type.  
           
    IF cUserType EQ ConstantInitializer:cMobileUser THEN
    DO:
      IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
      DO:
        /* Get multilingual message for invalid user */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidUser,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
                
      END. /* IF NOT CAN-FIND(CSAMS...) */
            
      IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
      DO:
        /* Get multilingual message for blank customer number */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200CustBlank,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
            
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF TRIM(ipcCustNum) EQ "" */
              
      ELSE
      DO: 
              
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) AND CCSMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /* Get multilingual message for invalid customer */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                     
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
              
                   
      END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
            
      IF ipcShipNumber EQ "" OR ipcShipNumber EQ ? THEN
      DO:
        /* Get multilingual message for blank ship number */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200BlankShipNum,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                     
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END.
            
      ELSE
      DO:
        IF NOT CAN-FIND(FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ ipcCustNumber
          AND SHPTO.SHIP-NUMBER EQ ipcShipNumber)THEN
        DO:
          
          IF ipcShipNumber NE "PRIMARY":U THEN
          DO:           
            /* Get multilingual message for invalid ship number */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidShipNum,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                           
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1). 
          END.
        END.
      END.
      
      message "initiate checkin ".      
      objLocationMgmt:slsmanCheckInCheckout(INPUT ipcUserId,
        INPUT ipcCustNumber,
        INPUT ipcShipNumber,
        INPUT ipcLattitude,
        INPUT ipcLongitude,
        INPUT ipcLangID,
        INPUT ipiCheckInTime,
        INPUT ipiCheckOutTime,
        INPUT ipiMode,
        OUTPUT opcError,
        OUTPUT opiStatusCode).
            
      IF opcError NE "":U THEN 
        UNDO,THROW NEW AppError(opcError,1). 
          
    END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */
  END. /* IF opcStatus EQ "Success":U .. */
        
  ASSIGN 
    opiStatusCode = 200.
        
  CATCH errorObj AS AppError:           
    ASSIGN 
      opcError = errorObj:GetMessage(1).
  END CATCH.
        
  FINALLY:
            
    IF VALID-OBJECT(objCommonSrc)    THEN  
      DELETE OBJECT objCommonSrc. 
            
    IF VALID-OBJECT(objTokenMgmt)    THEN  
      DELETE OBJECT objTokenMgmt.
          
    IF VALID-OBJECT(objLocationMgmt) THEN  
      DELETE OBJECT objLocationMgmt.
                   
  END FINALLY.
        
END METHOD.
  
/*------------------------------------------------------------------------------
 Purpose: This API returns the items details of all the open orders of a salesman. 
 Notes:
------------------------------------------------------------------------------*/
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID openOrderItemsWrapper(INPUT ipcUserId          AS CHARACTER,
                                         INPUT ipcCustNum         AS CHARACTER,                                                                              
                                         INPUT ipcToken           AS CHARACTER,
                                         INPUT ipcLangId          AS CHARACTER,                                          
                                         INPUT ipiSyncTime        AS INT64,                                                  
                                         OUTPUT opcAppToken       AS CHARACTER,                                       
                                         OUTPUT opcError          AS CHARACTER,
                                         OUTPUT opiStatusCode     AS INTEGER, 
                                         OUTPUT oplcOrderItems    AS LONGCHAR):
    
  DEFINE VARIABLE objTokenMgmt AS CLASS     TokenManagement NO-UNDO.
  DEFINE VARIABLE objCommonSrc AS CLASS     CommonSource    NO-UNDO. 
  DEFINE VARIABLE objCustOrder AS CLASS     CustomerOrders  NO-UNDO.

  DEFINE VARIABLE opcStatus    AS CHARACTER NO-UNDO.     
  DEFINE VARIABLE iWareHouseNo AS INTEGER   NO-UNDO.
  DEFINE VARIABLE cCompanyCode AS CHARACTER NO-UNDO.
  DEFINE VARIABLE cUserType    AS CHARACTER NO-UNDO.    
        
  ASSIGN                
    objTokenMgmt = NEW TokenManagement(INPUT ipcToken)
    objCommonSrc = NEW CommonSource(INPUT ipcToken)
    objCustOrder = NEW customerOrders(INPUT ipcToken).                         
    
  IF TRIM(ipcCustNum) EQ "":U OR TRIM(ipcCustNum) EQ ? THEN 
  DO:
    objCommonSrc:getMessages(INPUT ipcLangID,
      INPUT ConstantInitializer:c200CustBlank,
      OUTPUT cError,
      OUTPUT opiStatusCode).
    IF cError NE "":U THEN
      UNDO, THROW NEW AppError(cError,1).
        
  END. /* IF TRIM(ipcCustNum) EQ "":U.. */
    
  IF TRIM(ipcCustNum) NE "":U AND TRIM(ipcCustNum) NE "A":U THEN 
  DO:
    IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum) THEN 
    DO:
      objCommonSrc:getMessages(INPUT ipcLangID,
        INPUT ConstantInitializer:c200InvalidCustomer,
        OUTPUT cError,
        OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO, THROW NEW AppError(cError,1).
          
    END. /* IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum) */
                    
  END. /* IF TRIM(ipcCustNum) NE "":U AND TRIM(ipcCustNum) NE "A":U  */  
            
  IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
  DO:
    /* Get multilingual message for blank language id */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200LangBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
            
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
    
  ELSE
  DO: 
    IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
    DO:
      /* Get multilingual message for language not supported */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200InvalidLang,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
                                      
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
  END. /* ELSE */ 
        
  /* Validate the token of the user on every request */
  IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
  DO:
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c403InvalidToken,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
            
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcToken) EQ "":U OR.. */   
        
  IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
  DO:
    /* Get multilingual message for blank user */
    objCommonSrc:getMessages(INPUT  ipcLangID,
      INPUT  ConstantInitializer:c200UserBlank,                                                              
      OUTPUT cError,
      OUTPUT opiStatusCode).
            
    IF cError NE "":U THEN 
      UNDO,THROW NEW AppError(cError,1).
  END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
                    
  /* validate the token */
  objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
    INPUT  ipcUserId,
    INPUT  ipcLangID, 
    OUTPUT cError,
    OUTPUT opcStatus,
    OUTPUT opcAppToken,
    OUTPUT opiStatusCode). 
                                                                                      
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
    
        
  IF opcStatus EQ "Success":U THEN
  DO:
    FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
      ASSIGN 
        cUserType = Token.User-Type.  
      FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
        ASSIGN 
          iWareHouseNo = CMPNY.WHS-LOCATION
          cCompanyCode = CMPNY.COMPANY-CODE. 
      END. /* FOR FIRST CMPNY..*/           
    END. /* FOR FIRST Token..*/
      
    IF cUserType EQ ConstantInitializer:cMobileUser THEN
    DO:
      IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
      DO:
        /*Get multilingual message for invalid user */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidUser,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                  
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END.                           
        
      objCustOrder:getOpenOrderItems(INPUT  ipcUserId,
        INPUT  ipcCustNum,
        INPUT  ipcLangID,                                       
        INPUT  cCompanyCode,                                                                             
        INPUT  iWareHouseNo,
        INPUT  ipiSyncTime,
        INPUT  cUserType,
        OUTPUT oplcOrderItems,
        OUTPUT opcError,
        OUTPUT opiStatusCode).
    
        
      IF opcError NE "":U THEN
        UNDO,THROW NEW AppError(opcError,1).
                                                       
    END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */                                                   
                               
    ASSIGN 
      opiStatusCode = 200. 
                                               
  END. /* IF opcStatus EQ "Success":U THEN */

  CATCH errorObj AS AppError:           
    ASSIGN 
      opcError = errorObj:GetMessage(1).
  END CATCH.
    
  FINALLY:
        
    IF VALID-OBJECT(objCommonSrc) THEN  
      DELETE OBJECT objCommonSrc. 
        
    IF VALID-OBJECT(objTokenMgmt) THEN  
      DELETE OBJECT objTokenMgmt.
      
    IF VALID-OBJECT(objCustOrder) THEN  
      DELETE OBJECT objCustOrder.
      
    IF VALID-HANDLE(hSharedVar)   THEN 
      DELETE PROCEDURE hSharedVar NO-ERROR.
               
  END FINALLY.                                                                               

END METHOD.

@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID getInvoiceDetail(INPUT ipcToken         AS CHARACTER,
                                    INPUT ipcCustNumber    AS CHARACTER,
                                    INPUT ipcUserID        AS CHARACTER,
                                    INPUT ipcLangId        AS CHARACTER,
                                    INPUT ipcInvoiceNumber AS CHARACTER,
                                    OUTPUT opcError        AS CHARACTER,
                                    OUTPUT opiStatusCode   AS INTEGER,
                                    OUTPUT opcAppToken     AS CHARACTER,
                                    OUTPUT oplcInvoiceData AS LONGCHAR): 
                                        
    DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc      AS CLASS     CommonSource    NO-UNDO. 
    DEFINE VARIABLE objInvoiceHistory AS CLASS     InvoiceHistory  NO-UNDO.

    DEFINE VARIABLE opcStatus         AS CHARACTER NO-UNDO.     
    DEFINE VARIABLE iWareHouseNo      AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCompanyCode      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cUserType         AS CHARACTER NO-UNDO. 
       
     
    ASSIGN                
      objTokenMgmt      = NEW TokenManagement(INPUT ipcToken)
      objCommonSrc      = NEW CommonSource(INPUT ipcToken)
      objInvoiceHistory = NEW InvoiceHistory(INPUT ipcToken).      
             
    IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
    DO:
      /* Get multilingual message for blank language id */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200LangBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
    ELSE
    DO: 
      IF NOT CAN-FIND(CDILANGUAGE WHERE CDILanguage.Language-ID EQ TRIM(ipcLangID) NO-LOCK) THEN
      DO:
        /* Get multilingual message for language not supported */
        objCommonSrc:getMessages(INPUT  ipcLangID,
          INPUT  ConstantInitializer:c200InvalidLang,                                                              
          OUTPUT cError,
          OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
    END. /* ELSE */ 
        
    /*Validate the token of the user on every request*/
    IF TRIM(ipcToken) EQ "":U OR TRIM(ipcToken) EQ ? THEN
    DO:
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c403InvalidToken,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcToken) EQ "":U OR.. */   
        
    IF TRIM(ipcUserId) EQ "":U OR TRIM(ipcUserId) EQ ? THEN
    DO:
      /* Get multilingual message for blank user */
      objCommonSrc:getMessages(INPUT  ipcLangID,
        INPUT  ConstantInitializer:c200UserBlank,                                                              
        OUTPUT cError,
        OUTPUT opiStatusCode).
            
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF TRIM(ipcUserId) EQ "":U OR.. */
                    
    /* validate the token */
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
      INPUT  ipcUserId,
      INPUT  ipcLangID, 
      OUTPUT cError,
      OUTPUT opcStatus,
      OUTPUT opcAppToken,
      OUTPUT opiStatusCode). 
                                                                                      
    IF cError NE "":U THEN
      UNDO,THROW NEW AppError(cError,1).
    
        
    IF opcStatus EQ "Success":U THEN
    DO:
      FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:
        ASSIGN 
          cUserType = Token.User-Type.  
        FOR FIRST CMPNY WHERE CMPNY.COMPANY-CODE = Token.Company-ID NO-LOCK:
          ASSIGN 
            iWareHouseNo = CMPNY.WHS-LOCATION
            cCompanyCode = CMPNY.COMPANY-CODE. 
        END. /* FOR FIRST CMPNY..*/           
      END. /* FOR FIRST Token..*/
      
      
      IF cUserType EQ ConstantInitializer:cMobileUser THEN
      DO:
        IF NOT CAN-FIND(CSAMS WHERE CSAMS.SALES-REP-ID EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END.
        
        IF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? THEN
        DO:
          
          /* Get multilingual message for blank customer number */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200CustBlank,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*IF TRIM(ipcCustNum) EQ ""*/  
        ELSE
        DO: 
          IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcCustNumber) NO-LOCK) THEN
          DO:
            /* Get multilingual message for invalid customer */
            objCommonSrc:getMessages(INPUT  ipcLangID,
              INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
              OUTPUT cError,
              OUTPUT opiStatusCode).
                                 
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
          END. /* IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER.. */ 
               
        END. /* ELSE OF TRIM(ipcCustNumber) EQ "":U OR TRIM(ipcCustNumber) EQ ? */
        
        objInvoiceHistory:getInvoiceData(INPUT  ipcCustNumber,
                                         INPUT  ipcUserId,
                                         INPUT  ipcLangID,
                                         INPUT  iWareHouseNo,
                                         INPUT cUserType,
                                         INPUT ipcInvoiceNumber,
                                         OUTPUT oplcInvoiceData,
                                         OUTPUT opcError,
                                         OUTPUT opiStatusCode).
        
        IF opcError NE "":U THEN
          UNDO,THROW NEW AppError(opcError,1).
                                                       
      END. /* IF cUserType EQ ConstantInitializer:cMobileUser THEN */                                                   
      ELSE 
      DO:
        IF NOT CAN-FIND(CCSMS WHERE CCSMS.CUST-NUMBER EQ TRIM(ipcUserId) NO-LOCK) THEN
        DO:
          /*Get multilingual message for invalid user */
          objCommonSrc:getMessages(INPUT  ipcLangID,
            INPUT  ConstantInitializer:c200InvalidUser,                                                              
            OUTPUT cError,
            OUTPUT opiStatusCode).
                                  
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. 
        
        objInvoiceHistory:getInvoiceData(INPUT  ipcUserId,
                                     INPUT  ipcUserId,
                                     INPUT  ipcLangID,
                                     INPUT  iWareHouseNo,
                                     INPUT  cUserType,
                                     INPUT  ipcInvoiceNumber,
                                     OUTPUT oplcInvoiceData,
                                     OUTPUT opcError,
                                     OUTPUT opiStatusCode).
                                         
         
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1). 
              
      END. /* ELSE IF cUserType EQ ConstantInitializer:cMobileUser THEN */
                               
      ASSIGN 
        opiStatusCode = 200. 
                                               
    END. /* IF opcStatus EQ "Success":U THEN */

    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
        
      IF VALID-OBJECT(objCommonSrc) THEN  
        DELETE OBJECT objCommonSrc. 
        
      IF VALID-OBJECT(objTokenMgmt) THEN  
        DELETE OBJECT objTokenMgmt.
      
      IF VALID-OBJECT(objInvoiceHistory) THEN  
        DELETE OBJECT objInvoiceHistory.
               
      IF VALID-HANDLE(hSharedVar) THEN 
        DELETE PROCEDURE hSharedVar NO-ERROR.
    
    END FINALLY.     
                                           
                                        
END METHOD.                                         

       
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID getOnlinePaymentAccont(INPUT ipcToken         AS CHARACTER,
                                          INPUT ipcLandId        AS CHARACTER, 
                                          INPUT ipcCustNumber    AS CHARACTER,
                                          OUTPUT opcError        AS CHARACTER,
                                          OUTPUT opiStatusCode   AS INTEGER,
                                          OUTPUT TABLE online_account_info): 
                                              
  DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement NO-UNDO. 
  DEFINE VARIABLE ipcUserId         AS CHARACTER                 NO-UNDO.
  DEFINE VARIABLE opcAppToken       AS CHARACTER                 NO-UNDO.
  DEFINE VARIABLE opcStatus         AS CHARACTER                 NO-UNDO.
  DEFINE VARIABLE lccomp-id         AS CHARACTER                 NO-UNDO.
   // ASSIGN  objTokenMgmt      = NEW TokenManagement(INPUT ipcToken).
  
/*  FOR FIRST Token WHERE Token.Token = ipcToken NO-LOCK:     */
/*     ASSIGN lccomp-id = Token.Company-ID.                   */
/*  END. /* FOR FIRST Token..*/                               */
/*  objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,      */
/*                                      INPUT  ipcUserId,     */
/*                                      INPUT  ipcLandId,     */
/*                                      OUTPUT cError,        */
/*                                      OUTPUT opcStatus,     */
/*                                      OUTPUT opcAppToken,   */
/*                                      OUTPUT opiStatusCode).*/
/* IF opcStatus EQ "Success":U THEN*/
/* DO:                             */
    IF lccomp-id = "" THEN lccomp-id = SUBSTRING(ipcCustNumber,1,1).
    
     FOR EACH Online_Account_detail WHERE online_account_detail.comp-id EQ lccomp-id NO-LOCK:
         
       CREATE online_account_info.
       ASSIGN online_account_info.provider_name      = Online_Account_detail.Service_Provider_Name
              online_account_info.provider_id        = Online_Account_detail.Provider_Id
              online_account_info.provider_account   = Online_Account_detail.Account_number
              online_account_info.provider_auth_key  = Online_Account_detail.Account_Key.
                 
          opiStatusCode =  200.       
      END.                                            
       IF opiStatusCode NE 200 THEN 
         ASSIGN opiStatusCode = 404
                opcError      = "Online Payment Account Not Setup. Please Contact CDI Admin":U.                              
 // END. 
/*  ELSE                                                                                      */
/*  DO:                                                                                       */
/*      ASSIGN opiStatusCode = 404                                                            */
/*             opcError      = "Online Payment Account Not Setup. Please Contact CDI Admin":U.*/
/*  END.                                                                                      */
END METHOD.
  
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID setCustomerLocation( INPUT ipcToken         AS CHARACTER,
                                        INPUT ipcLandId        AS CHARACTER,
                                        INPUT ipcUserId       AS CHARACTER,
                                        INPUT ipcCustNumber   AS CHARACTER,
                                        INPUT ipcLattitude    AS DECIMAL,
                                        INPUT ipcLongitude    AS DECIMAL):

    DEFINE VARIABLE objLocationMgmt   AS CLASS     LocationMgmt NO-UNDO.
    DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement   NO-UNDO.
    DEFINE VARIABLE opcStatus         AS CHARACTER NO-UNDO.   
    DEFINE VARIABLE opcAppToken       AS CHARACTER NO-UNDO. 
    DEFINE VARIABLE opiStatusCode     AS INTEGER NO-UNDO.  
    
    objLocationMgmt   = NEW LocationMgmt(INPUT ipcToken).
    objTokenMgmt      = NEW TokenManagement(INPUT ipcToken).
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
                                        INPUT  ipcUserId,
                                        INPUT  ipcLandId, 
                                        OUTPUT cError,
                                        OUTPUT opcStatus,
                                        OUTPUT opcAppToken,
                                        OUTPUT opiStatusCode). 
                                                                                          
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
     
  IF opcStatus EQ "Success":U THEN
  DO:  
     objLocationMgmt:SetCustomerLangLat(ipcUserId, 
                                        ipcCustNumber, 
                                        ipcLattitude, 
                                        ipcLongitude).                                               
  END.                                           
                                        
END.    
  
@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID getsethd(INPUT ipcToken         AS CHARACTER,
                            INPUT ipcLandId        AS CHARACTER,
                            INPUT ipcCompanyCode   AS CHARACTER,
                            OUTPUT opcError        AS CHARACTER,
                            OUTPUT opiStatusCode   AS INTEGER,
                            OUTPUT TABLE sethd_header,
                            OUTPUT TABLE setdt_detail,
                            OUTPUT TABLE LeyDetail):
    
   DEFINE VARIABLE objsetHD   AS CLASS     sethd NO-UNDO.
   
   objsetHD = NEW sethd(INPUT ipcToken).
   
   objsethd:getsetinfo(INPUT ipcCompanyCode,
                       OUTPUT TABLE sethd_header, 
                       OUTPUT TABLE setdt_detail, 
                       OUTPUT TABLE LeyDetail).
                                  
END METHOD.

@openapi.openedge.export(type="REST", useReturnValue="false", writeDataSetBeforeImage="false").
METHOD PUBLIC VOID getsalesrepreport(INPUT ipcToken         AS CHARACTER,
                                     INPUT ipcLandId        AS CHARACTER,
                                     INPUT ipcCompanyCode   AS CHARACTER,
                                     INPUT ipcSalesRep      AS CHARACTER,
                                     OUTPUT opcError        AS CHARACTER,
                                     OUTPUT opiStatusCode   AS INTEGER,
                                     OUTPUT TABLE salesrepreport
                                     ):
    
   
    DEFINE VARIABLE objTokenMgmt      AS CLASS     TokenManagement   NO-UNDO.
    DEFINE VARIABLE opcStatus         AS CHARACTER                   NO-UNDO.   
    DEFINE VARIABLE opcAppToken       AS CHARACTER                   NO-UNDO. 
    DEFINE VARIABLE objSalesman       AS CLASS SalesmanInfo          NO-UNDO.
    DEFINE VARIABLE lcSalesRep        AS CHARACTER                   NO-UNDO.
    DEFINE VARIABLE lcUserId          AS CHARACTER                   NO-UNDO.
    
    objSalesman       = NEW SalesmanInfo(INPUT ipcToken).
    objTokenMgmt      = NEW TokenManagement(INPUT ipcToken).
  
  
     FIND FIRST Token WHERE Token.Token EQ ipcToken NO-LOCK NO-ERROR.
     IF AVAILABLE TOKEN THEN
        ASSIGN lcUserId = Token.User-ID.
     ELSE 
        ASSIGN lcUserId = "".       
    objTokenMgmt:loggedInUserTokenRenew(INPUT  ipcToken,
                                        INPUT  lcUserId,
                                        INPUT  ipcLandId, 
                                        OUTPUT cError,
                                        OUTPUT opcStatus,
                                        OUTPUT opcAppToken,
                                        OUTPUT opiStatusCode).  
                                                                                          
  IF cError NE "":U THEN
    UNDO,THROW NEW AppError(cError,1).
     
  IF opcStatus EQ "Success":U THEN
  DO:
      objSalesman:GetSalesRepReport(INPUT ipcCompanyCode, 
                                    INPUT lcUserId,
                                    OUTPUT TABLE salesrepreport).
  END.    
                                  
END METHOD.
  
END CLASS.