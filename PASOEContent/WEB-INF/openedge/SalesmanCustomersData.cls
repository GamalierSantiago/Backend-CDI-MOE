/*-----------------------------------------------------------------------------------
   File        : SalesmanCustomerInfo
   Purpose     : To get the reqiured data of all customers of a salesman
   Syntax      : 
   Description : In this file we are fetching the salesman customers and their relevant details
   Author(s)   : JKTECH
   Created     : Tue Jul 04 04:45:11 IST 2017
   Notes       : Version 1.1
   History     :
   ----------------------------------------------------------------------------------
   Date(MM-DD-YY)          Author             Initial(XX-Version)       Description
                                                   
   ----------------------------------------------------------------------------------    
 ------------------------------------------------------------------------------------*/

USING Progress.Lang.*.


BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS SalesmanCustomersData: 
  
  DEFINE PRIVATE TEMP-TABLE ttCustomer NO-UNDO    
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
    FIELD number_of_days      AS INTEGER
    FIELD pageNumber          AS INTEGER.  

  DEFINE PRIVATE TEMP-TABLE ttSortCustomer NO-UNDO LIKE ttCustomer.
        
  DEFINE PRIVATE TEMP-TABLE ttOpenOrder NO-UNDO
    FIELD orderNumber    LIKE COOHD.ORDER-NUMBER
    FIELD orderDate      LIKE COOHD.ORDER-DATE
    FIELD openAmt        LIKE COODT.ORDERED-PRC
    FIELD customerNumber LIKE CCSMS.CUST-NUMBER
    FIELD customerName   AS CHARACTER.
    
  DEFINE PRIVATE TEMP-TABLE ttCustAmountOverdue NO-UNDO 
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
    
  DEFINE PRIVATE TEMP-TABLE ttCustBillingAddress NO-UNDO 
    FIELD customerNumber AS CHARACTER     
    FIELD billingAdd1    LIKE ccsms.ADDRESS-L1
    FIELD billingAdd2    LIKE ccsms.ADDRESS-L2
    FIELD billingAdd3    LIKE ccsms.ADDRESS-L3
    FIELD billingState   LIKE ccsms.POSTAL-STATE
    FIELD billingCity    LIKE CCSMS.POSTAL-city  
    FIELD billingZip     LIKE CCSMS.POSTAL-ZIP.      
  
   DEFINE TEMP-TABLE ttSalesManCustList NO-UNDO 
          FIELD cust-num LIKE CCSMS.CUST-NUMBER.
                
  DEFINE PRIVATE VARIABLE cError      AS CHARACTER NO-UNDO.
  DEFINE VARIABLE opdeCustAmtInvoiced AS DECIMAL   NO-UNDO.
  DEFINE VARIABLE opiTotalInvoices    AS INTEGER   NO-UNDO.
  DEFINE VARIABLE opiStatusCode       AS INTEGER   NO-UNDO.
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lcSalesrep          AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lcAppType           AS CHARACTER NO-UNDO.  
  DEFINE VARIABLE lcAddress           AS CHARACTER NO-UNDO. 
  CONSTRUCTOR PUBLIC SalesmanCustomersData ():
                                    
  END CONSTRUCTOR.

  CONSTRUCTOR PUBLIC SalesmanCustomersData (INPUT ipcToken AS CHARACTER):
            ASSIGN cToken =  ipcToken.   
            FIND FIRST token WHERE Token.Token EQ ipcToken NO-LOCK NO-ERROR.
            IF AVAIL token THEN 
            ASSIGN lcSalesrep = Token.User-ID
                   lcAppType  = Token.User-Type.                    
  END CONSTRUCTOR.      
  /*---------------------------------------------------------------------------------
   Purpose:This method returns whether any customer of logged in person exists or not
   Notes:
  -----------------------------------------------------------------------------------*/

  METHOD PUBLIC LOGICAL CustomerExists(INPUT ipcSalesRepId AS CHARACTER):
    
    DEFINE VARIABLE lCustomerExists AS LOGICAL NO-UNDO.
    
    IF CAN-FIND(FIRST ccsms WHERE CCSMS.SALES-REP-ID EQ ipcSalesRepId NO-LOCK) THEN 
      lCustomerExists = TRUE.

    RETURN lCustomerExists.

  END METHOD.
  
  /*---------------------------------------------------------------------------------
   Purpose:This method returns whether any customer of logged in person exists or not
   Notes:
  -----------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID CustomerDiscount(INPUT ipcCustNumber       AS CHARACTER,
                                      INPUT ipcTermsCode        AS CHARACTER,
                                      OUTPUT opcDiscountPercent AS CHARACTER,
                                      OUTPUT opcError           AS CHARACTER):
      
      
         FIND TERMS WHERE TERMS.CUS-TERMS-CD EQ ipcTermsCode NO-LOCK NO-ERROR.
         IF AVAILABLE Terms THEN
         DO:
            ASSIGN opcDiscountPercent  = STRING(TERMS.TERMS-PERCEN / 100).
         END.
      

  END METHOD.

  

  /*------------------------------------------------------------------------------------
   Purpose: This method populates the temp-table and calls other methods for reqd data
   Input Parameters:
               1. cCustNumber  - Customer number
               2. ipcCompanyID - Logged-in Company ID
               3. ipcLangID    - Language ID of the Logged-In user

   Output Parameters:
               1. ttCustomer            - Table stores customer related data
               2. ttCustShippingAddress - Temp table which stores the shipping addresses 
                                          of the customer
               3. ttOpenOrder           - Stores all the open orders of the customers
               4. ttCustInvoice         - Stores the invoices of the customer
               5. ttCustAmountOverdue   - Stores the details of the customer overdue amount
               6. cError                - Error message (If any)
               7. opiStatusCode         - HTTP status code
  --------------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID fillCustomersData(INPUT  cCustNumber   AS CHARACTER,
                                       INPUT  ipcCompanyID  AS CHARACTER, 
                                       INPUT  ipcLangID     AS CHARACTER,
                                       OUTPUT TABLE ttCustomer, 
                                       OUTPUT TABLE ttCustShippingAddress,
                                       OUTPUT TABLE ttOpenOrder, 
                                       OUTPUT TABLE ttCustInvoice,
                                       OUTPUT TABLE ttCustAmountOverdue,
                                       OUTPUT TABLE ttCustBillingAddress,
                                       OUTPUT cError        AS CHARACTER,
                                       OUTPUT opiStatusCode AS INTEGER):
	     
    DEFINE VARIABLE deTotalAmtOverdue AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deAvailCredit     AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deTotalOpenOrdr   AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE cPayTerms         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE opcLastXDays      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iNoOfDays         AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iTotalOpenOrdr    AS INTEGER   NO-UNDO.	
    DEFINE VARIABLE iTotalOverdues    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iTotalInvoices    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE dRecentOrdrDate   AS DATE      NO-UNDO.
    DEFINE VARIABLE deCusSaleAmt90day AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deCustAmtInvoiced AS DECIMAL   NO-UNDO. 	
    DEFINE VARIABLE iStatusCode       AS INTEGER   NO-UNDO.
    DEFINE VARIABLE opcDiscountPercent AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE opcError           AS CHARACTER NO-UNDO.
	  
    DEFINE VARIABLE custOpenOrdrObj        AS CLASS CustomerOrders NO-UNDO.      
    DEFINE VARIABLE objCommonSrc           AS CLASS CommonSource   NO-UNDO.
    
    
    DEFINE VARIABLE cCustImage  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileType   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE deUnitPrice AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE CDomain     AS CHARACTER NO-UNDO.
    
    objCommonSrc    = NEW CommonSource(INPUT cToken).
    custOpenOrdrObj = NEW CustomerOrders(INPUT cToken).
                                      	
    FOR FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ cCustNumber NO-LOCK:
     
      /* FOR EACH COOHD WHERE 
	    COOHD.CUST-NUMBER EQ CCSMS.CUST-NUMBER 
	    NO-LOCK BY COOHD.ORDER-DATE :
        ASSIGN 
          dRecentOrdrDate = COOHD.ORDER-DATE.
      END. */
      FIND LAST COOHD WHERE COOHD.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE COOHD THEN 
        ASSIGN dRecentOrdrDate = COOHD.ORDER-DATE.
      /* Decides the number of days for sales in last XX days */
      IF VALID-OBJECT(objCommonSrc) THEN DO:
      
        objCommonSrc:parameterFile(INPUT ConstantInitializer:cNoOfDays,
                                   INPUT  ipcCompanyID,
                                   INPUT  YES,
                                   OUTPUT opcLastXDays,
                                   OUTPUT cError) NO-ERROR.
                              
        ASSIGN iNoOfDays = INTEGER(opcLastXDays) NO-ERROR. 
      
        IF ERROR-STATUS:ERROR OR iNoOfDays EQ 0  THEN
          ASSIGN iNoOfDays = 180 NO-ERROR.

      END. /* IF VALID-OBJECT(objCommonSrc) THEN */
      
      
      THIS-OBJECT:CustomerDiscount(INPUT CCSMS.CUST-NUMBER,   
                                   INPUT CCSMS.TERMS-CODE, 
                                   OUTPUT opcDiscountPercent,                                    
                                   OUTPUT opcError).
	  	  
      CREATE ttCustomer.
      ASSIGN 
        ttCustomer.customerNumber            = CCSMS.CUST-NUMBER
        ttCustomer.customerName              = REPLACE(CCSMS.CUST-NAME,"'", "") //CCSMS.CUST-NAME
        ttCustomer.secondName                = REPLACE(CCSMS.SECOND-NAME,"'", "") 
        /*ttCustomer.totalSales                = CCSMS.YTD-SALES*/
        ttCustomer.customerType              = CCSMS.CUST-TYPE              
        ttCustomer.creditLimit               = CCSMS.CREDIT-LIMIT
        ttCustomer.phoneNumber               = CCSMS.PHONE-NUMBER
        ttCustomer.emailId                   = CCSMS.E-MAIL
        ttCustomer.priceList                 = CCSMS.PRICE-LIST
        ttCustomer.route                     = CCSMS.ROUTE
        ttCustomer.poRequired                = IF CCSMS.ORG-TYPE MATCHES "P" THEN TRUE ELSE FALSE
        ttCustomer.number_of_days            = iNoOfDays 
        ttCustomer.discount                  = opcDiscountPercent
        no-error. 
           
      /* Logic to get the total sales of a customer */
      FOR EACH CSAHF WHERE CSAHF.CUST-NUMBER   EQ CCSMS.CUST-NUMBER                    
                     AND NOT CSAHF.ITEM-NUMBER BEGINS ipcCompanyID + "*"
                     AND CSAHF.QTY-SHIPPED     NE 0 
                     /* AND CSAHF.INVOICE-DATE GE (TODAY - iNoOfDays ) */ NO-LOCK:
        
        ASSIGN  ttCustomer.totalSales = ttCustomer.totalSales + CSAHF.PRICE-ext.                        
      
      END. /* FOR EACH CSAHF   */
      
      /* get Picture */
      FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
      IF AVAILABLE paramfl THEN 
        ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1 
               Cdomain             = PARAMFL.PARAM-VALUE2
               FILE-INFO:FILE-NAME =  FILE-INFO:FILE-NAME + "\" + "customer" NO-ERROR.
               
        
      IF FILE-INFO:FULL-PATHNAME NE ? THEN
      DO:
         INPUT FROM OS-DIR(FILE-INFO:FULL-PATHNAME).
         REPEAT:
            IMPORT cCustImage ^ cFileType.
            IF cFileType EQ "F":U AND INDEX(cCustImage,".pdf") = 0 AND INDEX(cCustImage,CCSMS.CUST-NUMBER) GT 0 THEN
              ttCustomer.customer_picture = (Cdomain + "/":U + "customer" + "/":U + Replace(cCustImage," ","%20")). // Customer Image
            IF cFileType EQ "F":U AND INDEX(cCustImage,".pdf") GT 0 AND INDEX(cCustImage,CCSMS.CUST-NUMBER) GT 0 THEN  
              ttCustomer.terms_condition_pdf =  (Cdomain + "/":U + "customer" + "/":U + Replace(cCustImage," ","%20")).  //Term and condition PDF  
            
         END. /* REPEAT */  
              
      END. /* IF FILE-INFO:FULL-PATHNAME NE ? THEN */  
      //FILE-INFO:FILE-NAME = ConstantInitializer:cCustomerPicDir + "/" + ttCustomer.customerNumber + ".jpg".
      
/*      IF FILE-INFO:FULL-PATHNAME NE ? THEN                                                                             */
/*        ASSIGN ttCustomer.customer_picture  = ConstantInitializer:cCustomerPicDir + ttCustomer.customerNumber + ".jpg".*/
      ELSE
      ASSIGN ttCustomer.customer_picture  = "".
      
      /* get terms & conditions PDF */
/*      FILE-INFO:FILE-NAME = ConstantInitializer:cCustomerPicDir + "/" + ttCustomer.customerNumber + ".pdf".       */
/*      IF FILE-INFO:FULL-PATHNAME NE ? THEN                                                                        */
/*        ttCustomer.terms_condition_pdf = ConstantInitializer:cCustomerPicDir + ttCustomer.customerNumber + ".pdf".*/
/*      ELSE                                                                                                        */
/*        ttCustomer.terms_condition_pdf = "".                                                                      */
       
      /* Get the billing address of the customer if exists */
      IF (CCSMS.ADDRESS-L1 NE "":U OR CCSMS.ADDRESS-L2 NE "":U OR CCSMS.ADDRESS-L3 NE "":U ) THEN
      DO:
        CREATE ttCustBillingAddress.  
        ASSIGN   
          ttCustBillingAddress.customerNumber  = CCSMS.CUST-NUMBER.   
          
          lcAddress = REPLACE(CCSMS.ADDRESS-L1,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
              
          ttCustBillingAddress.billingAdd1     = lcAddress.
          
          lcAddress = REPLACE(CCSMS.ADDRESS-L2,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
          
          ttCustBillingAddress.billingAdd2     = lcAddress.
          
          lcAddress = REPLACE(CCSMS.ADDRESS-L3,"'", "").
          lcAddress = REPLACE(lcAddress,'"', '').
          lcAddress = REPLACE(lcAddress,"/", "").
          lcAddress = REPLACE(lcAddress,"\", "").
          
          ttCustBillingAddress.billingAdd3     = lcAddress.
          ttCustBillingAddress.billingState    = CCSMS.POSTAL-STATE.
          ttCustBillingAddress.billingCity     = ccsms.postal-city.      
          ttCustBillingAddress.billingZip      = CCSMS.POSTAL-ZIP.    
      END.  /* IF (CCSMS.ADDRESS-L1 NE "":U OR CCSMS.ADDRESS-L2 NE "":U OR CCSMS.ADDRESS-L3 NE "":U ) */
                   
      /* Get the multiple shipping addresses of the customer if exists */
      THIS-OBJECT:getCustShippingAddress(INPUT  cCustNumber,
                                         INPUT  "",
                                         OUTPUT cError,
                                         OUTPUT TABLE ttCustShippingAddress).
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).   
      
      /* Get the amount overdue of the selected customer */
      THIS-OBJECT:CustomerAmountOverdue(INPUT  cCustNumber,
                                        INPUT  ipcCompanyID, 
                                        OUTPUT deTotalAmtOverdue, 
                                        OUTPUT iTotalOverdues,
                                        OUTPUT TABLE ttCustAmountOverdue, 
                                        OUTPUT cError).         
           
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).           
            
      /* Get the amount of sales to a customer in last 90 days */
      THIS-OBJECT:customerSalesInLast90Days(INPUT  cCustNumber, 
                                            OUTPUT deCusSaleAmt90day, 
				       	                            OUTPUT cError).
           
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
      
      /* Get the available credit of the customer */
      THIS-OBJECT:getAvailableCredit(INPUT  cCustNumber,
				                             OUTPUT deAvailCredit, 
				                             OUTPUT cError).
           
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
           
      /* Get the payment information of the customer like payment terms */
      THIS-OBJECT:getPaymentInfo(INPUT  cCustNumber, 
				                         OUTPUT cPayTerms, 
				                         OUTPUT cError).
            
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).

 
      /* Get customer's invoiced amount */        
      THIS-OBJECT:getCustAmountInvoiced(INPUT  cCustNumber,
                                        INPUT  ipcCompanyID, 
                                        INPUT  CCSMS.SALES-REP-ID,
                                        OUTPUT deCustAmtInvoiced,
                                        OUTPUT iTotalInvoices,
                                        OUTPUT TABLE ttCustInvoice,
                                        OUTPUT cError).
            
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
      
       /* Get the open order of a customer. */
      custOpenOrdrObj:getCustOpenOrdrInfo(INPUT  cCustNumber, 
                                          INPUT  ipcLangID ,
                                          INPUT  ipcCompanyID, 
                                          OUTPUT TABLE ttOpenOrder APPEND,
                                          OUTPUT deTotalOpenOrdr,
                                          OUTPUT iTotalOpenOrdr,        
                                          OUTPUT cError,
                                          OUTPUT opiStatusCode).   
                 
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).

       /* Here CCSMS.DELINQUENT-I = 'H' Shows Customer is on Hold  */ 
      IF CCSMS.DELINQUENT-I = 'H':U THEN
        ASSIGN ttCustomer.onholdcust = YES.
      
      
      ASSIGN 
        ttCustomer.amtOverdue          = deTotalAmtOverdue
        ttCustomer.availCredit         = deAvailCredit
        ttCustomer.paymentTerm         = cPayTerms
        ttCustomer.totalOpenOrderAmt   = deTotalOpenOrdr
        ttCustomer.totalOpenOrder      = iTotalOpenOrdr
        ttCustomer.totalOverdues       = iTotalOverdues
        ttCustomer.totalInvoices       = iTotalInvoices
        ttCustomer.recentOrderDate     = IF dRecentOrdrDate EQ ? THEN "":U
                                         ELSE STRING(dRecentOrdrDate)
        ttCustomer.custSaleInLast90Day = deCusSaleAmt90day
        ttCustomer.custAmtInvoiced     = deCustAmtInvoiced  NO-ERROR.
   
    END. /* FOR FIRST CCSMS */
    
    ASSIGN opiStatusCode = 200.
        
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError    = errorObj:GetMessage(1).      
    END CATCH.  
                    
    FINALLY:
      IF VALID-OBJECT(custOpenOrdrObj) THEN    
        DELETE OBJECT custOpenOrdrObj.
      IF VALID-OBJECT(objCommonSrc) THEN      
        DELETE OBJECT objCommonSrc.
    END FINALLY.

  END METHOD.
  
  /*------------------------------------------------------------------------------------
   Purpose: This method retrieves all the Customers of a logged in Salesman
   Input Parameters: 
               1. ipcSalesRepId    - Sales rep ID of the salesman
               2. ipcCompanyID     - Logged-in Company ID
               3. lRegularSalesman - Shows whether the logged In person is a salesman or supervisor 
               4. ipcSortBy        - Gives the filter criteria ex. New-Me, Recent Visit etc.
               5. ipcLangID        - Gives the laguage ID of the user.
			   
   Output Parameters
   		       1. ttSortCustomer - Stores the result on the basis of filter criteria
   		       2. ttCustShippingAddress - Stores the multi[le shipping addresses of the customer
			   4. ttOpenOrder   - Stores all the open orders of the customers
			   5. ttOpenOrder   - Stores all the open orders related data
			   6. ttCustInvoice - stores the invoices of the customers 
			   6. ttCustAmountOverdue - Stores the details of the customer overdue amount
			   7. cError - Stores the error (if any)
			   8. opiStatusCode - HTTP status code 
  --------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getCustomers(INPUT ipcSalesRepId    AS CHARACTER,
                                  INPUT ipcCompanyID     AS CHARACTER,
                                  INPUT lRegularSalesman AS LOGICAL, 
                                  INPUT ipcSortBy        AS CHARACTER,
                                  INPUT  ipcLangID       AS CHARACTER,
                                  OUTPUT TABLE ttSortCustomer, 
                                  OUTPUT TABLE ttCustShippingAddress,
                                  OUTPUT TABLE ttOpenOrder, 
                                  OUTPUT TABLE ttCustInvoice,
                                  OUTPUT TABLE ttCustAmountOverdue,
                                  OUTPUT TABLE ttCustBillingAddress,
                                  OUTPUT cError          AS CHARACTER,
                                  OUTPUT opiStatusCode   AS INTEGER):
    
    DEFINE VARIABLE lCustomerExists AS LOGICAL NO-UNDO.
    ASSIGN lcSalesrep = ipcSalesRepId.                                                                                                                                                     
    CASE ipcSortBy:
      WHEN ConstantInitializer:cAllRecords OR 
      WHEN ConstantInitializer:cA-Z        THEN
        DO ON ERROR UNDO,THROW:   
         
          /* if the logged In person is a regular salesman OR even if single customer exists
             for logged in person, then return the Customers list 
          */
          
          //lCustomerExists = THIS-OBJECT:CustomerExists(INPUT ipcSalesRepId).
                                     
          IF lregularSalesman THEN
          DO:
            FOR EACH CCSMS NO-LOCK
              WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID
                AND CCSMS.SALES-REP-ID EQ     ipcSalesRepId :                           
                            
              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
          
            END.  /* FOR EACH CCSMS ENDS */  
          END. /* IF lregularSalesman ENDS  */
          
          ELSE
          DO:
            FOR EACH CSAMS NO-LOCK 
              WHERE CSAMS.SUPERVISOR   EQ ipcSalesRepId 
                 OR csams.sales-rep-id EQ ipcSalesRepId,              
              
              EACH CCSMS NO-LOCK 
                WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID
                  AND CCSMS.SALES-REP-ID EQ     CSAMS.SALES-REP-ID:

              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
                                                        
            END. /* FOR EACH CSAMS ENDS */ 
          END. /* ELSE - If lRegulatSlsmn */
                            
        FOR EACH ttCustomer WHERE ttCustomer.customerNumber NE "":U  BY ttCustomer.customerName :
          CREATE ttSortCustomer.
          BUFFER-COPY ttCustomer TO ttSortCustomer.  
        END. /* FOR EACH ttCustomer */
                            
      END.
        
      WHEN ConstantInitializer:cNearMe THEN
        DO ON ERROR UNDO,THROW:
          /* full logic not yet implemented */
          /* When the logged In person is a regular Salesman */
          IF lregularSalesman THEN
          DO:
            FOR EACH CCSMS NO-LOCK
              WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID
                AND CCSMS.SALES-REP-ID EQ     ipcSalesRepId : 
     
              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
                                                               
            END.  /* FOR EACH CCSMS ENDS */  
          END. /* IF lregularSalesman..  */
          
          /* when the logged-In person is a supervisor */
          ELSE
          DO:
            FOR EACH CSAMS NO-LOCK 
              WHERE CSAMS.SUPERVISOR EQ ipcSalesRepId, 
              EACH CCSMS NO-LOCK 
                WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID
                  AND CCSMS.SALES-REP-ID EQ     CSAMS.SALES-REP-ID :
             
              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
                                             
            END. /* FOR EACH CSAMS ENDS */  
          END. /* ELSE - IF lRegulrslsmn */           
        END. /* DO ON ERROR UNDO */ 
               
      WHEN ConstantInitializer:cRecentVisit THEN
        DO ON ERROR UNDO,THROW:
          
          /* When the logged In person is a regular Salesman */
          IF lregularSalesman THEN
          DO:
            FOR EACH CCSMS NO-LOCK
              WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID
                AND CCSMS.SALES-REP-ID EQ     ipcSalesRepId : 
     
              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
                                          
            END.  /* FOR EACH CCSMS ENDS */  
          END. /* IF lregularSalesman..  */
          
          /* when the Logged in person is a supervisor */
          ELSE
          DO:
            FOR EACH CSAMS NO-LOCK WHERE CSAMS.SUPERVISOR   EQ ipcSalesRepId, 
              EACH CCSMS   NO-LOCK WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID 
                                     AND CCSMS.SALES-REP-ID EQ     CSAMS.SALES-REP-ID :
              
              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
                   
            END. /* FOR EACH CSAMS ENDS */
                    
          END. /* ELSE - IF lRegularslsmn */ 
                     
          FOR EACH ttCustomer BY ttCustomer.recentOrderDate DESCENDING:
            CREATE ttSortCustomer.
            BUFFER-COPY ttCustomer TO ttSortCustomer.  
          END. /* FOR EACH ttCustomer   */
                                  
        END. /* WHEN "recentvisit" THEN */
               
    END CASE.     
     
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError =  errorObj:GetMessage(1).       
    END CATCH.    
           
  END METHOD.
 
  /*------------------------------------------------------------------------------
  Purpose: This method returns the credit limit of a salesman's customer and also
           gives the available credit amount of that customer. 
  Input Parameters: 
              1. ipcCustNum - Customer number
              2. ipcLangID  - Language ID 
  Output Parameters:              
              1. deAvailCredit - available credit amount of the customer
	            2. cError        - Error (If any)	          
			  
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID getAvailableCredit(INPUT  ipcCustNum    AS CHARACTER,
                                        OUTPUT deAvailCredit AS DECIMAL,
                                        OUTPUT cError        AS CHARACTER):

    DEFINE VARIABLE deCreditLimit AS DECIMAL NO-UNDO.
    DEFINE VARIABLE deBalance     AS DECIMAL NO-UNDO.
    DEFINE VARIABLE deUsed       AS DECIMAL NO-UNDO.                                     
    FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER  EQ ipcCustNum NO-LOCK NO-ERROR.
          
    IF AVAILABLE CCSMS THEN  
    DO ON ERROR UNDO,THROW:  
       
      ASSIGN 
        deBalance     = CCSMS.OPEN-INVOICE - CCSMS.ON-ACCOUNT - CCSMS.CREDIT-AMT + CCSMS.DEBIT-AMT + CCSMS.ON-ORDER-AMT /* + deOpenOrdrAmt */
        deCreditLimit = CCSMS.CREDIT-LIMIT.
        //deAvailCredit = CCSMS.OPEN-INVOICE - CCSMS.ON-ACCOUNT  + CCSMS.ON-ORDER-AMT + CCSMS.DEBIT-AMT - CCSMS.CREDIT-AMT.
        //deAvailCredit = deCreditLimit - deBalance.
        deUsed = (CCSMS.OPEN-INVOICE
                        - CCSMS.ON-ACCOUNT
                        + CCSMS.ON-ORDER-AMT     
                        + CCSMS.DEBIT-AMT
                        - CCSMS.CREDIT-AMT).
        IF deUsed < 0 THEN 
            deUsed = ABS(deUsed).
                           
        deAvailCredit = ccsms.credit-limit
                        - deUsed.
       /* deAvailCredit = CCSMS.CREDIT-LIMIT - (CCSMS.OPEN-INVOICE - 
                                             CCSMS.ON-ACCOUNT - 
                                             CCSMS.CREDIT-AMT + 
                                             CCSMS.DEBIT-AMT + 
                                             CCSMS.ON-ORDER-AMT).   */     
    END. /* DO ON ERROR UNDO,THROW: */
   
    CATCH errorObj AS AppError:           
      cError = errorObj:GetMessage(1).
    END CATCH.  
                       
  END METHOD.

  /*--------------------------------------------------------------------------------------
  Purpose: This method calculates the total amount overdue of a particular customer (Pg.3)
  Input Parameters: 
              1. ipcCustNum   - customer number
              2. ipcCompanyID - Logged-in Company ID
              3. ipcLangId    - Language ID
  
  Output Parameters:              
              1. opdeCustAmtOverdue  - Customer Overdue amount
	            2. opiOpenInvoiceCount - Total open invoices count
	            3. ttCustAmountOverdue - Table which stores details of overdue amount
	            4. cError              - Stores the error if any
	            5. opiStatusCode       - HTTP status code
  ----------------------------------------------------------------------------------------*/  
        
  METHOD PUBLIC VOID CustomerAmountOverdue(INPUT  ipcCustNum          AS CHARACTER,
                                           INPUT  ipcCompanyID        AS CHARACTER, 
                                           OUTPUT opdeCustAmtOverdue  AS DECIMAL,
                                           OUTPUT opiOpenInvoiceCount AS INTEGER,
                                           OUTPUT TABLE ttCustAmountOverdue,
                                           OUTPUT cError              AS CHARACTER):         
                      
    DEFINE VARIABLE iDays           AS INTEGER FORMAT "ZZZ"           NO-UNDO.
    DEFINE VARIABLE deAmountDue     AS DECIMAL FORMAT "->,>>>,>>>.99" NO-UNDO.        
    DEFINE VARIABLE iNoOfDays       AS INTEGER                        NO-UNDO.
    DEFINE VARIABLE opcLastXDays    AS CHARACTER                      NO-UNDO.
    DEFINE VARIABLE iTermsDays      AS INTEGER                        NO-UNDO.
    DEFINE VARIABLE lcSalesRep      AS CHARACTER                      NO-UNDO.
    DEFINE VARIABLE objCommonSrc    AS CLASS commonSource             NO-UNDO.
    DEFINE VARIABLE iGraceDays      AS INTEGER                        NO-UNDO.
    objCommonSrc = NEW CommonSource(INPUT cToken).
    
    IF VALID-OBJECT(objCommonSrc) THEN DO:
      
      objCommonSrc:parameterFile(INPUT  ConstantInitializer:cNoOfDays,
                                 INPUT  ipcCompanyID,
                                 INPUT  YES,
                                 OUTPUT opcLastXDays,
                                 OUTPUT cError).
                              
      ASSIGN iNoOfDays = INTEGER(opcLastXDays) NO-ERROR. 
      
      IF ERROR-STATUS:ERROR OR iNoOfDays EQ 0  THEN
        ASSIGN iNoOfDays = 180 NO-ERROR.

    END. /* IF VALID-OBJECT(objCommonSrc) THEN */
    
    FIND FIRST token WHERE Token.Token = ctoken NO-LOCK NO-ERROR. 
    IF AVAILABLE token THEN 
      ASSIGN lcSalesRep = Token.User-ID.
    
    IF ipcCustNum NE lcSalesRep THEN 
    DO:
        //Gama modifico para llamar al paramfl y en base a eso se condicione o no el For each.
        
        DEFINE VARIABLE willShowAllCustomers AS LOGICAL NO-UNDO.
    FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID BEGINS "OE-SALES-OPERATOR" AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    willShowAllCustomers = AVAIL PARAMFL.
        
        FOR FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum NO-LOCK:
            /* FOR EACH COPAR NO-LOCK 
                WHERE COPAR.CUST-NUMBER  EQ CCSMS.CUST-NUMBER 
                  AND COPAR.CUS-CHG-NO   NE ConstantInitializer:cOnAcc
                  AND COPAR.CUS-CHG-NO   NE "":U
                  AND COPAR.DESCRIPTION1 NE "":U
                  AND COPAR.SALES-REP-ID EQ lcSalesRep: */
               FOR EACH COPAR WHERE COPAR.CUST-NUMBER  EQ CCSMS.CUST-NUMBER 
                                AND ((COPAR.SALES-REP-ID EQ lcSalesRep AND NOT willShowAllCustomers) OR willShowAllCustomers)
                                AND COPAR.CUS-CHG-NO   NE ConstantInitializer:cOnAcc
                                AND (COPAR.CUS-INV-NET - COPAR.CUS-PAYMENT
                                                      - COPAR.PAY-DISC-AMT 
                                                      - COPAR.OTH-ALLOWANC
                                                      - COPAR.INV-CR-TOT  
                                                      + COPAR.INV-DR-TOT <> 0) USE-INDEX INVOICE-KY NO-LOCK:   
                
                ASSIGN iDays = 0.
                      
                FIND TERMS WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-LOCK NO-ERROR.
                IF AVAILABLE TERMS THEN
                    ASSIGN
                        iDays = TODAY - (COPAR.CUS-INV-DATE + TERMS.TERMS-DAYS)
                        iTermsDays = TERMS.TERMS-DAYS.         
                ELSE
                    ASSIGN
                        iDAYS = TODAY - (COPAR.CUS-INV-DATE + 30).
             
               FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE EQ ipcCompanyID
                                    AND PARAMFL.PARAM-ID     EQ "OVERRIDE-TERMS":U 
                                    AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
               IF AVAILABLE PARAMFL THEN
                  ASSIGN iGraceDays = INTEGER (PARAMFL.PARAM-VALUE1) NO-ERROR. 
               
                IF (COPAR.CUS-INV-DATE + iTermsDays + iGraceDays) LT TODAY THEN    
                DO:
                    ASSIGN deAmountDue = COPAR.CUS-INV-NET  - 
                                         COPAR.CUS-PAYMENT  - 
                                         COPAR.PAY-DISC-AMT - 
                                         COPAR.OTH-ALLOWANC - 
                                         COPAR.INV-CR-TOT   + 
                                         COPAR.INV-DR-TOT.
                                         
                    IF deAmountDue EQ 0 THEN NEXT.
                    
                    ASSIGN 
                        opdeCustAmtOverdue  = opdeCustAmtOverdue + deAmountDue
                        opiOpenInvoiceCount = opiOpenInvoiceCount + 1.
                    //Gama anadio el Find y el If Not Available para el TimeComplexity.    
                    FIND ttCustAmountOverdue WHERE ttCustAmountOverdue.customerNumber = COPAR.CUST-NUMBER
                                               AND ttCustAmountOverdue.description1   = COPAR.CUS-CHG-NO
                                               AND ttCustAmountOverdue.orderDate      = COPAR.CUS-INV-DATE NO-LOCK NO-ERROR.    
                    IF NOT AVAILABLE ttCustAmountOverdue THEN DO:              
                    CREATE ttCustAmountOverdue.
                    ASSIGN ttCustAmountOverdue.customerNumber = COPAR.CUST-NUMBER
                           ttCustAmountOverdue.orderNumber    = COPAR.DESCRIPTION1  
                           ttCustAmountOverdue.description1   = COPAR.CUS-CHG-NO    /* Invoice number  */
                           ttCustAmountOverdue.orderDate      = COPAR.CUS-INV-DATE /* Invoice date    */
                           ttCustAmountOverdue.custInvoiceAmt = COPAR.CUS-INV-NET /* invoice amount  */
                           ttCustAmountOverdue.customerName   = REPLACE(CCSMS.CUST-NAME,"'", "") //CCSMS.CUST-NAME
                           ttCustAmountOverdue.collected      = COPAR.CUS-PAYMENT
                           ttCustAmountOverdue.due_on         = COPAR.CUS-INV-DATE + iTermsDays                  
                           ttCustAmountOverdue.overdueAmount  = deAmountDue  NO-ERROR.   
                           
                           IF  ttCustAmountOverdue.due_on  = ? THEN ttCustAmountOverdue.due_on  = TODAY + 30.
                    END. //FIND ttCustAmountOverdue                                 
                    
                    FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
                    IF NOT AVAIL COOHD AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
                    DO:                                                                        
                      /* This message will be displayed when no such record exists in COOHD and COODT */ 
                      ASSIGN ttCustAmountOverdue.item_fr_invoice_nt_foundmsg = TRUE.
                
                    END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT..) */ 
                           
                END. /* IF iDays GT 0 AND iDays.. */
            END.    /*  FOR EACH COPAR NO-LOCK.. */   
        END.       /*   FOR FIRST CCSMS WHERE.. */
    END.
    ELSE 
    DO:
        
        FOR FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum NO-LOCK:
            /* FOR EACH COPAR NO-LOCK 
                WHERE COPAR.CUST-NUMBER  EQ CCSMS.CUST-NUMBER 
                  AND COPAR.CUS-CHG-NO   NE ConstantInitializer:cOnAcc
                  AND COPAR.CUS-CHG-NO   NE "":U
                  AND COPAR.DESCRIPTION1 NE "":U: */
              FOR EACH COPAR WHERE COPAR.CUST-NUMBER  EQ CCSMS.CUST-NUMBER 
                               AND COPAR.CUS-CHG-NO   NE ConstantInitializer:cOnAcc
                               AND (COPAR.CUS-INV-NET - COPAR.CUS-PAYMENT
                                                      - COPAR.PAY-DISC-AMT 
                                                      - COPAR.OTH-ALLOWANC
                                                      - COPAR.INV-CR-TOT  
                                                      + COPAR.INV-DR-TOT <> 0) NO-LOCK:    
                
                ASSIGN iDays = 0.
                      
                FIND TERMS WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-LOCK NO-ERROR.
                IF AVAILABLE TERMS THEN
                    ASSIGN
                        iDays = TODAY - (COPAR.CUS-INV-DATE + TERMS.TERMS-DAYS)
                        iTermsDays = TERMS.TERMS-DAYS.         
                ELSE
                    ASSIGN
                        iDAYS = TODAY - (COPAR.CUS-INV-DATE + 30).
             
                FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE EQ ipcCompanyID
                                    AND PARAMFL.PARAM-ID     EQ "OVERRIDE-TERMS":U 
                                    AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
               IF AVAILABLE PARAMFL THEN
                  ASSIGN iGraceDays = INTEGER (PARAMFL.PARAM-VALUE1) NO-ERROR. 
                  
               /* IF (iDays GT 0 AND iDays LE iNoOfDays)          OR 
                   (iDays LT 0 AND COPAR.CUS-INV-DATE GT TODAY) OR
                   (iDays LE 0 AND COPAR.CUS-INV-DATE LE TODAY) OR
                   (COPAR.CUS-CHG-NO  EQ ConstantInitializer:cOnAcc)THEN */
                   
                IF (COPAR.CUS-INV-DATE + iTermsDays + iGraceDays) LT TODAY THEN      
                DO:
                    ASSIGN deAmountDue = COPAR.CUS-INV-NET  - 
                                         COPAR.CUS-PAYMENT  - 
                                         COPAR.PAY-DISC-AMT - 
                                         COPAR.OTH-ALLOWANC - 
                                         COPAR.INV-CR-TOT   + 
                                         COPAR.INV-DR-TOT.
                                         
                    IF deAmountDue EQ 0 THEN NEXT.
                    
                    ASSIGN 
                        opdeCustAmtOverdue  = opdeCustAmtOverdue + deAmountDue
                        opiOpenInvoiceCount = opiOpenInvoiceCount + 1. 
                                  
                    CREATE ttCustAmountOverdue.
                    ASSIGN ttCustAmountOverdue.customerNumber = COPAR.CUST-NUMBER
                           ttCustAmountOverdue.orderNumber    = COPAR.DESCRIPTION1  
                           ttCustAmountOverdue.description1   = COPAR.CUS-CHG-NO    /* Invoice number  */
                           ttCustAmountOverdue.orderDate      = COPAR.CUS-INV-DATE /* Invoice date    */
                           ttCustAmountOverdue.custInvoiceAmt = COPAR.CUS-INV-NET /* invoice amount  */
                           ttCustAmountOverdue.customerName   = REPLACE(CCSMS.CUST-NAME,"'", "") //CCSMS.CUST-NAME
                           ttCustAmountOverdue.collected      = COPAR.CUS-PAYMENT
                           ttCustAmountOverdue.due_on         = COPAR.CUS-INV-DATE + iTermsDays                  
                           ttCustAmountOverdue.overdueAmount  = deAmountDue  NO-ERROR.                               
                    
                    IF  ttCustAmountOverdue.due_on  = ? THEN ttCustAmountOverdue.due_on  = TODAY + 30.
                    
                    FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
                    IF NOT AVAIL COOHD AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
                    DO:                                                                        
                      /* This message will be displayed when no such record exists in COOHD and COODT */ 
                      ASSIGN ttCustAmountOverdue.item_fr_invoice_nt_foundmsg = TRUE.
                
                    END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT..) */ 
                           
                END. /* IF iDays GT 0 AND iDays.. */
            END.    /*  FOR EACH COPAR NO-LOCK.. */   
        END.       /*   FOR FIRST CCSMS WHERE.. */
    END.  
                
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError = errorObj:GetMessage(1).
    END CATCH.        
                             
  END METHOD.
   
  /*--------------------------------------------------------------------------------------
  Purpose: This method calculates the sales in last XX days of a particular customer (Pg.3)
  Input Parameters: 
              1. ipcCustNum - customer number
              2. ipcLangId  - Language ID
              
  Output Parameters:
              1. opdeCusSaleAmt90day - Customer Customer sales in last 90 days
	            2. cError              - Stores the error (if any)
	            3. opiStatusCode       - HTTP status code 
  ----------------------------------------------------------------------------------------*/  
  
  METHOD PUBLIC VOID customerSalesInLast90Days(INPUT ipcCustNum           AS CHARACTER, 
                                               OUTPUT opdeCusSaleAmtXXdays AS DECIMAL,
                                               OUTPUT cError              AS CHARACTER):  /* need to check logic -jkt-3 */
    
    DEFINE VARIABLE iNoOfDays       AS INTEGER   NO-UNDO.
    DEFINE VARIABLE opcLastXDays    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cCompany        AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE objCommonSrc AS CLASS commonSource NO-UNDO.
    objCommonSrc = NEW CommonSource(INPUT cToken).
    cCompany     = SUBSTRING(ipcCustNum, 1,1).
    
    IF VALID-OBJECT(objCommonSrc) THEN DO:
      objCommonSrc:parameterFile(INPUT ConstantInitializer:cNoOfDays,
                                 INPUT  cCompany,
                                 INPUT  YES,
                                 OUTPUT opcLastXDays,
                                 OUTPUT cError).
                              
      ASSIGN iNoOfDays = INTEGER(opcLastXDays) NO-ERROR. 
      
      IF ERROR-STATUS:ERROR OR iNoOfDays EQ 0  THEN
        ASSIGN iNoOfDays = 180 NO-ERROR.

    END. /* IF VALID-OBJECT(objCommonSrc) THEN */
                                  
    /* FOR EACH CSAHF WHERE CSAHF.CUST-NUMBER     EQ ipcCustNum    
                     AND CSAHF.Invoice-date    GE (TODAY - iNoOfDays)
                     AND CSAHF.QTY-SHIPPED     NE 0
                     /* AND NOT CSAHF.ITEM-NUMBER BEGINS cCompany + "*" */ NO-LOCK: */
                     
     FOR EACH CSAHF WHERE  CSAHF.Invoice-date GE (TODAY - iNoOfDays) NO-LOCK:
         
       IF CSAHF.CUST-NUMBER     EQ ipcCustNum  AND CSAHF.QTY-SHIPPED     NE 0 THEN                     
      /* get the total sales amount in last XX days */
      ASSIGN opdeCusSaleAmtXXdays = opdeCusSaleAmtXXdays + CSAHF.Price-Ext.
      
     END. /*FOR EACH CSAHF*/
           
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError = errorObj:GetMessage(1).
    END CATCH.             
                                
  END METHOD.   

  /*--------------------------------------------------------------------------------------
  Purpose: This method is getting payment information and payment methods
  Input Parameters: 
              1. ipcCustNum - Selected customer number
              2. ipcLangID  - Language ID
  Output Parameers:              
              1. opcTermsDesc  - It gets the payment terms description
	          2. cError        - Stores the error (if any)
	          3. opiStatusCode - HTTP status code
  ----------------------------------------------------------------------------------------*/    
    
  METHOD PUBLIC VOID getPaymentInfo(INPUT  ipcCustNum    AS CHARACTER, 
                                    OUTPUT opcTermsDesc  AS CHARACTER,
                                    OUTPUT cError        AS CHARACTER):
                                                 
    FIND TERMS WHERE TERMS.CUS-TERMS-CD EQ CCSMS.TERMS-CODE NO-LOCK NO-ERROR.
    IF AVAILABLE TERMS THEN
      ASSIGN opcTermsDesc = TERMS.CUS-TERMS-DS.
    
    CATCH  errorObj AS AppError:
      ASSIGN 
        cError = errorObj:GetMessage(1).    
    END CATCH.
       
  END METHOD.
   
  /*--------------------------------------------------------------------------------------
  Purpose: This method is used to calculate amount invoiced of a customer(Pg3)
  Input Parameters: 
              1. ipcCustNum    - customer number
              2. ipcSalesRepId - Sales Rep Id 
              3. ipcLangID     - Language ID
              
  Output Parameters:
              1. opdeCustAmtInvoiced - It gives the invoiced amount of the customer	
              2. ttCustInvoice - temp-table which stores customer's invoice		
              3. cError - Stores an error (if any)
              4. opiStatusCode - HTTP status code	  
  ----------------------------------------------------------------------------------------*/ 
   
  METHOD PUBLIC VOID getCustAmountInvoiced(INPUT  ipcCustNum          AS CHARACTER,
                                           INPUT  ipcCompanyID        AS CHARACTER,
                                           INPUT  ipcSalesRepId       AS CHARACTER,  
                                           OUTPUT opdeCustAmtInvoiced AS DECIMAL,
                                           OUTPUT opiTotalInvoices    AS INTEGER,
                                           OUTPUT TABLE ttCustInvoice,
                                           OUTPUT cError              AS CHARACTER):
                                               
    DEFINE VARIABLE opcLastXDays AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE inDateRange  AS INTEGER    NO-UNDO.
    DEFINE VARIABLE iTermsDays   AS INTEGER    NO-UNDO.
   
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource     NO-UNDO.
     
    ASSIGN objCommonSrc = NEW CommonSource(INPUT cToken).
                                     
    IF ipcCustNum NE "":U AND ipcSalesRepId NE "":U THEN
    DO:
     /* objCommonSrc:parameterFile(INPUT  ConstantInitializer:cDateRange,
                                 INPUT  ipcCompanyID,
                                 INPUT  YES,
                                 OUTPUT opcLastXDays,
                                 OUTPUT cError).
                              
      ASSIGN inDateRange = INTEGER(opcLastXDays) NO-ERROR. 
      
      IF ERROR-STATUS:ERROR OR inDateRange EQ 0  THEN
        ASSIGN inDateRange = 180 NO-ERROR. */
        
        FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE    = ipcCompanyID
                                AND PARAMFL.PARAM-ID     = "SALE-HISTORY-DAYS":U
                                AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
           IF AVAILABLE PARAMFL THEN 
             ASSIGN inDateRange = INTEGER(PARAMFL.PARAM-VALUE1).
           ELSE 
             ASSIGN inDateRange = 181.  
           
       
      /*IF opcDateRange EQ "":U THEN
        ASSIGN opcDateRange = "90".*/                     
      
      FOR EACH CSAHF NO-LOCK WHERE CSAHF.CUST-NUMBER  EQ ipcCustNum
                               AND CSAHF.SALES-REP-ID EQ ipcSalesRepId
                              /* AND CSAHF.INVOICE-DATE GE (TODAY - inDateRange) */:
         
        
        IF NOT CAN-FIND(FIRST ttCustInvoice WHERE ttCustInvoice.invoiceNumber EQ CSAHF.INVOICE-NO) THEN
        DO:    
            CREATE ttCustInvoice.
            ASSIGN ttCustInvoice.customerNumber = CSAHF.CUST-NUMBER
                   ttCustInvoice.invoiceNumber  = CSAHF.INVOICE-NO
                   ttCustInvoice.invoiceDate    = CSAHF.INVOICE-DATE
                   ttCustInvoice.orderNumber    = CSAHF.ORDER-NUMBER /* Added after bug raised */                   
                   opiTotalInvoices             = opiTotalInvoices + 1 NO-ERROR.
            
            /* Required following keys for getCustomers API in amount invoiced setion on mobile */
            FIND FIRST COPAR WHERE COPAR.CUST-NUMBER EQ CSAHF.CUST-NUMBER
                               AND COPAR.CUS-CHG-NO  EQ CSAHF.INVOICE-NO NO-LOCK NO-ERROR.
        
            IF AVAILABLE COPAR THEN 
            DO:
               FIND FIRST terms NO-LOCK WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-ERROR.
               IF AVAILABLE terms THEN
                 ASSIGN iTermsDays = TERMS.TERMS-DAYS.
              
                ASSIGN ttCustInvoice.collected  = COPAR.CUS-PAYMENT
                       ttCustInvoice.due_on     = COPAR.CUS-INV-DATE + iTermsDays NO-ERROR.                               
               
               IF  ttCustInvoice.due_on  = ? THEN ttCustInvoice.due_on  = TODAY + 30.
                
               FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
               IF NOT AVAIL COOHD AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
               DO:                                                                        
                 /* This message will be displayed when no such record exists in COOHD and COODT */ 
                 ASSIGN ttCustInvoice.item_fr_invoice_nt_foundmsg = TRUE.
            
               END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT..) */
                
            END. /* IF AVAILABLE COPAR THEN */
        
        END. /* IF NOT CAN-FIND(FIRST ttCustInvoice).. */
        
        FIND FIRST ttCustInvoice WHERE ttCustInvoice.invoiceNumber EQ  CSAHF.INVOICE-NO  NO-ERROR.
        IF AVAILABLE ttCustInvoice THEN
        DO:
          ASSIGN ttCustInvoice.invoiceAmount =  ttCustInvoice.invoiceAmount + CSAHF.PRICE-EXT.
        END.
        opdeCustAmtInvoiced = opdeCustAmtInvoiced + CSAHF.PRICE-EXT.    
      END. /* FOR EACH CSAHF..      */
    END.  /* IF ipcCustNum NE "":U */
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError = errorObj:GetMessage(1).
    END CATCH. 
    
    FINALLY:
      IF VALID-OBJECT(objCommonSrc) THEN    
        DELETE OBJECT objCommonSrc.  
    END FINALLY.
      
  END METHOD. 
  
  
  /*---------------------------------------------------------------------------------------------
  Purpose: This method is used to fetch multiple shipping addresses of the customer.
  Input Parameter: 1.ipcCustNum - customer number whose shipping address is to be fetched.
                   2.ipcLangID  - selected language-id
  
  Output Parameter: 1.opcError              - to display error message if any.
                    2.ttCustShippingAddress - temp-table to store multiple shipping addresses
		                                      of a customer
		            3.opiStatusCode         - Http status code
  --------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getCustShippingAddress(INPUT ipcCustNum     AS CHARACTER,
                                            INPUT ipcShipTo      AS CHARACTER,
                                            OUTPUT opcError      AS CHARACTER,
                                            OUTPUT TABLE ttCustShippingAddress):
                                                
                                               /* MESSAGE "En el metodo getCustShippingAddress " string(ipcShipTo)
                                                VIEW-AS ALERT-BOX.*/
 
 /*It is used to decide which address is used for primary address which is assigned "YES" value.*/  
    DEFINE VARIABLE lFlag AS LOGICAL NO-UNDO.
    DEFINE VARIABLE lcShipActive      AS LOGICAL  INITIAL YES. 
     FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNum NO-LOCK NO-ERROR.
     
     IF ipcShipTo <> ? OR ipcShipTo <> "" THEN DO:
   ASSIGN lcShipActive = NO.
   END.
    
     //Gama le anadio and SHIP-TO = "" ?                                                                            
     IF AVAILABLE CCSMS AND ipcShipTo = ? OR ipcShipTo = "" THEN
      DO: 
          /*MESSAGE "Entro? getCustShippingAddress"
          VIEW-AS ALERT-BOX.  */
            /* When CCSMS has shipping address it will be considered as primary one. */
         
            CREATE ttCustShippingAddress.
            ASSIGN ttCustShippingAddress.customerNumber = ipcCustNum
                   ttCustShippingAddress.ship_number    = "PRIMARY":U
                   ttCustShippingAddress.shipName       = REPLACE(CCSMS.CUST-NAME,"'", "") .
                   
                   lcAddress = REPLACE(IF CCSMS.PHYS-ADD-1 NE "":U THEN CCSMS.PHYS-ADD-1 ELSE CCSMS.ADDRESS-L1,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", ""). 
                   
                   ttCustShippingAddress.addressL1      = lcAddress.
                   
                   
                   lcAddress = REPLACE(IF CCSMS.PHYS-ADD-2 NE "":U THEN CCSMS.PHYS-ADD-2 ELSE CCSMS.ADDRESS-L2,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", ""). 
                   
                   ttCustShippingAddress.addressL2      = lcAddress.
                   
                   lcAddress = REPLACE(IF CCSMS.PHYS-ADD-3 NE "":U THEN CCSMS.PHYS-ADD-3 ELSE CCSMS.ADDRESS-L3,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", ""). 
                   
                   ttCustShippingAddress.addressL3      = lcAddress.
                   
                   ASSIGN ttCustShippingAddress.shippingCity   = CCSMS.PHYSICAL-CITY
                   ttCustShippingAddress.shippingState  = CCSMS.PHYSICAL-STATE
                   ttCustShippingAddress.shippingZip    = CCSMS.PHYSICAL-ZIP
                   ttCustShippingAddress.longitude      = CCSMS.Longitude
                   ttCustShippingAddress.latitude       = CCSMS.Latitude
                   ttCustShippingAddress.PrimaryAddress = YES  .
            /* This variable determines that we have a primary shipping address in our system */
            lFlag = YES. 
         END. /* IF AVAILABLE CCSMS */   
     IF lcAppType = "mobileuser" THEN 
     DO:
         //Gama le anadio el indice, el find y el if not available para el error de TimeComplexity.
         FOR EACH SHPTO WHERE SHPTO.CUST-NUMBER EQ ipcCustNum 
                          AND ((SHPTO.SHIP-NUMBER EQ ipcShipTo AND NOT lcShipActive) OR lcShipActive)
                          AND (SHPTO.ADDRESS-L1 NE "":U OR
                               SHPTO.ADDRESS-L2 NE "":U OR
                               SHPTO.ADDRESS-L3 NE "":U) 
                          AND (SHPTO.SALES-REP-ID EQ lcSalesrep 
                               OR SHPTO.SALES-REP-ID EQ "**":U) USE-INDEX NAME-IX  NO-LOCK:
           FIND ttCustShippingAddress WHERE ttCustShippingAddress.customerNumber = ipcCustNum AND ttCustShippingAddress.ship_number = SHPTO.SHIP-NUMBER NO-LOCK NO-ERROR.
           IF NOT AVAILABLE ttCustShippingAddress THEN DO:  
           CREATE ttCustShippingAddress.
           ASSIGN ttCustShippingAddress.customerNumber = ipcCustNum
                  ttCustShippingAddress.ship_number    = SHPTO.SHIP-NUMBER 
                  ttCustShippingAddress.shipName       = REPLACE(SHPTO.CUST-NAME,"'", "").
                  
                   lcAddress = REPLACE(SHPTO.ADDRESS-L1,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", "").
                   
                  ttCustShippingAddress.addressL1      = lcAddress.
                   
                   lcAddress = REPLACE(SHPTO.ADDRESS-L2,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", "").
                    
                  ttCustShippingAddress.addressL2      = lcAddress.
                  
                   lcAddress = REPLACE(SHPTO.ADDRESS-L3,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", "").
                   
                  ttCustShippingAddress.addressL3      = lcAddress. 
                  
                  ASSIGN 
                  ttCustShippingAddress.shippingCity   = CCSMS.PHYSICAL-CITY
                  ttCustShippingAddress.shippingState  = CCSMS.PHYSICAL-STATE
                  ttCustShippingAddress.shippingZip    = CCSMS.PHYSICAL-ZIP
                  ttCustShippingAddress.longitude      = SHPTO.Longitude
                  ttCustShippingAddress.latitude       = SHPTO.Latitude    
                  ttCustShippingAddress.PrimaryAddress = NO  NO-ERROR.
             END. //IF NOT AVAILABLE ttCustShippingAddress.
             /* If CCSMS doesn't have any shipping address then first SHPTO record will consider as primary shipping address */
           IF NOT lFlag THEN
           ASSIGN ttCustShippingAddress.PrimaryAddress = YES
                                                 lFlag = YES. 
           
         
         END. /* FOR EACH SHPTO */
          
      END.
      ELSE 
      DO:
          
          FOR EACH SHPTO WHERE SHPTO.CUST-NUMBER EQ ipcCustNum 
                          AND  ((SHPTO.SHIP-NUMBER EQ ipcShipTo AND NOT lcShipActive) OR lcShipActive)
                          AND (SHPTO.ADDRESS-L1 NE "":U) 
                               NO-LOCK:
               
           CREATE ttCustShippingAddress.
           ASSIGN ttCustShippingAddress.customerNumber = ipcCustNum
                  ttCustShippingAddress.ship_number    = SHPTO.SHIP-NUMBER 
                  ttCustShippingAddress.shipName       = REPLACE(SHPTO.CUST-NAME,"'", "").
                  
                  lcAddress = REPLACE(SHPTO.ADDRESS-L1,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", "").
                    
                  ttCustShippingAddress.addressL1      = lcAddress.
                  
                  lcAddress = REPLACE(SHPTO.ADDRESS-L2,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", "").
                    
                  ttCustShippingAddress.addressL2      = lcAddress.
                  
                  lcAddress = REPLACE(SHPTO.ADDRESS-L3,"'", "").
                   lcAddress = REPLACE(lcAddress,'"', '').
                   lcAddress = REPLACE(lcAddress,"/", "").
                   lcAddress = REPLACE(lcAddress,"\", "").
                   
                  ttCustShippingAddress.addressL3      = lcAddress.
                  
                  ASSIGN  
                  ttCustShippingAddress.shippingCity   = CCSMS.PHYSICAL-CITY
                  ttCustShippingAddress.shippingState  = CCSMS.PHYSICAL-STATE
                  ttCustShippingAddress.shippingZip    = CCSMS.PHYSICAL-ZIP
                  ttCustShippingAddress.longitude      = SHPTO.Longitude
                  ttCustShippingAddress.latitude       = SHPTO.Latitude    
                  ttCustShippingAddress.PrimaryAddress = NO  NO-ERROR.
             
             /* If CCSMS doesn't have any shipping address then first SHPTO record will consider as primary shipping address */
           IF NOT lFlag THEN
           ASSIGN ttCustShippingAddress.PrimaryAddress = YES
                                                 lFlag = YES. 
           
         
         END. /* FOR EACH SHPTO */
      END. 
      //Gama 
   /*   OUTPUT TO "C:\Users\cdisixto\Desktop\war03-25-2024\ttCustShippingAddress.txt".
    FOR EACH ttCustShippingAddress NO-LOCK:
        DISPLAY ttCustShippingAddress WITH 1 col.
    END. 
    OUTPUT CLOSE.*/   
     IF NOT CAN-FIND(FIRST ttCustShippingAddress) THEN 
      DO:
         
        CREATE ttCustShippingAddress.
        ASSIGN ttCustShippingAddress.customerNumber = ipcCustNum
               ttCustShippingAddress.ship_number    = "PRIMARY":U
               ttCustShippingAddress.shipName       = "Not Setup"
               ttCustShippingAddress.addressL1      = "Not Setup"
               ttCustShippingAddress.addressL2      = "Not Setup"
               ttCustShippingAddress.addressL3      = "Not Setup"
               ttCustShippingAddress.shippingCity   = "Not Setup"
               ttCustShippingAddress.shippingState  = "Not Setup"
               ttCustShippingAddress.PrimaryAddress = YES  NO-ERROR.
     END.           
    CATCH errorObj AS AppError:           
      opcError =  errorObj:GetMessage(1).
    END CATCH.
    
      
       
  END METHOD. 
  
  METHOD PUBLIC VOID SalesRepCustomerAmountOverdue(INPUT  ipcCustNum          AS CHARACTER,
                                                   INPUT  ipcCompanyID        AS CHARACTER, 
                                                   OUTPUT opdeCustAmtOverdue  AS DECIMAL,
                                                   OUTPUT opiOpenInvoiceCount AS INTEGER,
                                                   OUTPUT opiOverdueCustCount AS INTEGER,
                                                   OUTPUT TABLE ttCustAmountOverdue,
                                                   OUTPUT cError              AS CHARACTER):  
    ASSIGN opdeCustAmtOverdue = 0.0 
           opiOpenInvoiceCount = 0
           opiOverdueCustCount = 0.                                                            
                      
    DEFINE VARIABLE iDays           AS INTEGER FORMAT "ZZZ"           NO-UNDO.
    DEFINE VARIABLE deAmountDue     AS DECIMAL FORMAT "->,>>>,>>>.99" NO-UNDO.        
    DEFINE VARIABLE iNoOfDays       AS INTEGER                        NO-UNDO.
    DEFINE VARIABLE opcLastXDays    AS CHARACTER                      NO-UNDO.
    DEFINE VARIABLE iTermsDays      AS INTEGER                        NO-UNDO.
    DEFINE VARIABLE lcSalesRep      AS CHARACTER                      NO-UNDO.
    DEFINE VARIABLE objCommonSrc    AS CLASS commonSource             NO-UNDO.
    DEFINE VARIABLE iGraceDays      AS INTEGER                        NO-UNDO.
    DEFINE VARIABLE icCompanyId     AS CHARACTER                      NO-UNDO.
    objCommonSrc = NEW CommonSource(INPUT cToken).
    
   
           
    IF VALID-OBJECT(objCommonSrc) THEN DO:
      
      objCommonSrc:parameterFile(INPUT  ConstantInitializer:cNoOfDays,
                                 INPUT  ipcCompanyID,
                                 INPUT  YES,
                                 OUTPUT opcLastXDays,
                                 OUTPUT cError).
                              
      ASSIGN iNoOfDays = INTEGER(opcLastXDays) NO-ERROR. 
      
      IF ERROR-STATUS:ERROR OR iNoOfDays EQ 0  THEN
        ASSIGN iNoOfDays = 180 NO-ERROR.

    END. /* IF VALID-OBJECT(objCommonSrc) THEN */
    FIND FIRST token WHERE Token.Token = ctoken NO-LOCK NO-ERROR. 
    IF AVAILABLE token THEN 
      ASSIGN lcSalesRep  = Token.User-ID
             icCompanyId = Token.Company-ID.
      
   // MESSAGE "SalesManCustomerData.cls SalesRepCustomerAmountOverdue" .
       
    FOR EACH COPAR WHERE COPAR.CUST-NUMBER  BEGINS icCompanyId 
                     AND COPAR.SALES-REP-ID EQ lcSalesRep 
                     AND (COPAR.CUS-INV-NET - COPAR.CUS-PAYMENT
                                            - COPAR.PAY-DISC-AMT 
                                            - COPAR.OTH-ALLOWANC
                                            - COPAR.INV-CR-TOT  
                                            + COPAR.INV-DR-TOT <> 0) NO-LOCK USE-INDEX SALES-REP-ID
                                            BREAK BY COPAR.CUST-NUMBER: 
        IF COPAR.CUS-CHG-NO BEGINS "on" THEN NEXT.       
        IF COPAR.CUS-INV-NET  -  COPAR.CUS-PAYMENT  - 
                                 COPAR.PAY-DISC-AMT - 
                                 COPAR.OTH-ALLOWANC - 
                                 COPAR.INV-CR-TOT   + 
                                 COPAR.INV-DR-TOT LT 0 THEN NEXT.                                           
        FIND TERMS WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-LOCK NO-ERROR.
        IF AVAILABLE TERMS THEN
          ASSIGN iTermsDays = TERMS.TERMS-DAYS.
        ELSE 
          ASSIGN iTermsDays = 0.
                     
        FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE EQ ipcCompanyID
                             AND PARAMFL.PARAM-ID EQ "OVERRIDE-TERMS":U NO-LOCK NO-ERROR.
        IF AVAILABLE PARAMFL THEN
          ASSIGN iGraceDays = INTEGER (PARAMFL.PARAM-VALUE1) NO-ERROR. 
        ELSE   
          ASSIGN iGraceDays = 0.
               
        IF (COPAR.CUS-INV-DATE + iTermsDays) LT TODAY THEN    
        DO:
           
           IF FIRST-OF (COPAR.CUST-NUMBER) THEN 
           DO:
              FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ COPAR.CUST-NUMBER NO-LOCK NO-ERROR.  
              ASSIGN opiOverdueCustCount = opiOverdueCustCount + 1. 
           END. 
           ASSIGN deAmountDue        =  COPAR.CUS-INV-NET  - 
                                        COPAR.CUS-PAYMENT  - 
                                        COPAR.PAY-DISC-AMT - 
                                        COPAR.OTH-ALLOWANC - 
                                        COPAR.INV-CR-TOT   + 
                                        COPAR.INV-DR-TOT
                  opdeCustAmtOverdue  = opdeCustAmtOverdue + deAmountDue
                  opiOpenInvoiceCount = opiOpenInvoiceCount + 1.
                  
            FIND ttCustAmountOverdue WHERE ttCustAmountOverdue.customerNumber = COPAR.CUST-NUMBER 
                                       AND ttCustAmountOverdue.description1   = COPAR.CUS-CHG-NO
                                       AND ttCustAmountOverdue.orderDate      = COPAR.CUS-INV-DATE NO-LOCK NO-ERROR.
            IF NOT AVAILABLE ttCustAmountOverdue THEN DO:                  
            CREATE ttCustAmountOverdue.
            ASSIGN ttCustAmountOverdue.customerNumber = COPAR.CUST-NUMBER
                   ttCustAmountOverdue.orderNumber    = COPAR.DESCRIPTION1  
                   ttCustAmountOverdue.description1   = COPAR.CUS-CHG-NO    /* Invoice number  */
                   ttCustAmountOverdue.orderDate      = COPAR.CUS-INV-DATE /* Invoice date    */
                   ttCustAmountOverdue.custInvoiceAmt = COPAR.CUS-INV-NET /* invoice amount  */
                   ttCustAmountOverdue.customerName   = REPLACE(CCSMS.CUST-NAME,"'", "") //CCSMS.CUST-NAME
                   ttCustAmountOverdue.collected      = COPAR.CUS-PAYMENT
                   ttCustAmountOverdue.due_on         = COPAR.CUS-INV-DATE + iTermsDays                   
                   ttCustAmountOverdue.overdueAmount  = deAmountDue  NO-ERROR.                               
            
             IF  ttCustAmountOverdue.due_on  = ? THEN ttCustAmountOverdue.due_on  = TODAY + 30.
             END. //FIND ttCustAmountOverdue
             ASSIGN deAmountDue = 0.       
             FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
             IF NOT AVAIL COOHD AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN
             DO:                                                                        
                /* This message will be displayed when no such record exists in COOHD and COODT */ 
                ASSIGN ttCustAmountOverdue.item_fr_invoice_nt_foundmsg = TRUE.
                
             END. /* IF NOT AVAIL coohd AND NOT CAN-FIND(FIRST COODT..) */ 
           END.    /*  COPAR.CUS-INV-DATE + TERMS.TERMS-DAYS  */   
        END.       /*   FOR EACH COPAR NO-LOCK.. */
        
  END METHOD. 
  
   /*------------------------------------------------------------------------------------
   Purpose: This method retrieves all the Customers of a logged in Salesman
   Input Parameters: 
               1. ipcSalesRepId    - Sales rep ID of the salesman
               2. ipcCompanyID     - Logged-in Company ID
               3. lRegularSalesman - Shows whether the logged In person is a salesman or supervisor 
               4. ipcSortBy        - Gives the filter criteria ex. New-Me, Recent Visit etc.
               5. ipcLangID        - Gives the laguage ID of the user.
               
   Output Parameters
               1. ttSortCustomer - Stores the result on the basis of filter criteria
               2. ttCustShippingAddress - Stores the multi[le shipping addresses of the customer
               4. ttOpenOrder   - Stores all the open orders of the customers
               5. ttOpenOrder   - Stores all the open orders related data
               6. ttCustInvoice - stores the invoices of the customers 
               6. ttCustAmountOverdue - Stores the details of the customer overdue amount
               7. cError - Stores the error (if any)
               8. opiStatusCode - HTTP status code 
  --------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getAllCustomers(INPUT ipcSalesRepId    AS CHARACTER,
                                     INPUT ipcCompanyID     AS CHARACTER,
                                     INPUT lRegularSalesman AS LOGICAL, 
                                     INPUT ipcSortBy        AS CHARACTER,
                                     INPUT  ipcLangID       AS CHARACTER,
                                     OUTPUT TABLE ttSortCustomer, 
                                     OUTPUT TABLE ttCustShippingAddress,
                                     OUTPUT TABLE ttOpenOrder, 
                                     OUTPUT TABLE ttCustInvoice,
                                     OUTPUT TABLE ttCustAmountOverdue,
                                     OUTPUT TABLE ttCustBillingAddress,
                                     OUTPUT cError          AS CHARACTER,
                                     OUTPUT opiStatusCode   AS INTEGER):    
    
    DEFINE VARIABLE lCustomerExists AS LOGICAL NO-UNDO.
    ASSIGN lcSalesrep = ipcSalesRepId.  
                                                                                                                                                      
    CASE ipcSortBy:
      WHEN ConstantInitializer:cAllRecords OR 
      WHEN ConstantInitializer:cA-Z        THEN
        DO ON ERROR UNDO,THROW:   
         
          /* if the logged In person is a regular salesman OR even if single customer exists
             for logged in person, then return the Customers list 
          */
          
          //lCustomerExists = THIS-OBJECT:CustomerExists(INPUT ipcSalesRepId).
           //  MESSAGE "lregularSalesman: " lregularSalesman. 
           lregularSalesman = YES. // At this point, no use of CSAMS.laptop field. Marking all as salesperson                       
          IF lregularSalesman THEN
          DO:
              
             THIS-OBJECT:fillAllCustomersData(INPUT  lcSalesrep,
                                              INPUT  ipcCompanyID,
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
          END. /* IF lregularSalesman ENDS  */
          
          ELSE
          DO:
              
            FOR EACH CSAMS NO-LOCK 
              WHERE CSAMS.SUPERVISOR   EQ ipcSalesRepId 
                 OR csams.sales-rep-id EQ ipcSalesRepId,              
              
              EACH CCSMS NO-LOCK 
                WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID
                  AND CCSMS.SALES-REP-ID EQ     CSAMS.SALES-REP-ID:

              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
                                                        
            END. /* FOR EACH CSAMS ENDS */ 
          END. /* ELSE - If lRegulatSlsmn */
                            
        FOR EACH ttCustomer WHERE ttCustomer.customerNumber NE "":U  BY ttCustomer.customerName :
          CREATE ttSortCustomer.
          BUFFER-COPY ttCustomer TO ttSortCustomer.  
        END. /* FOR EACH ttCustomer */
                            
      END.
        
      WHEN ConstantInitializer:cNearMe THEN
        DO ON ERROR UNDO,THROW:
          /* full logic not yet implemented */
          /* When the logged In person is a regular Salesman */
          IF lregularSalesman THEN
          DO:
             THIS-OBJECT:fillAllCustomersData(INPUT  lcSalesrep,
                                              INPUT  ipcCompanyID,
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
                                                               
          END. /* IF lregularSalesman..  */
          
          /* when the logged-In person is a supervisor */
          ELSE
          DO:
            FOR EACH CSAMS NO-LOCK 
              WHERE CSAMS.SUPERVISOR EQ ipcSalesRepId, 
              EACH CCSMS NO-LOCK 
                WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID
                  AND CCSMS.SALES-REP-ID EQ     CSAMS.SALES-REP-ID :
             
              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
                                             
            END. /* FOR EACH CSAMS ENDS */  
          END. /* ELSE - IF lRegulrslsmn */           
        END. /* DO ON ERROR UNDO */ 
               
      WHEN ConstantInitializer:cRecentVisit THEN
        DO ON ERROR UNDO,THROW:
          
          /* When the logged In person is a regular Salesman */
          IF lregularSalesman THEN
          DO:
             THIS-OBJECT:fillAllCustomersData(INPUT  lcSalesrep,
                                              INPUT  ipcCompanyID,
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
          END. /* IF lregularSalesman..  */
          
          /* when the Logged in person is a supervisor */
          ELSE
          DO:
            FOR EACH CSAMS NO-LOCK WHERE CSAMS.SUPERVISOR   EQ ipcSalesRepId, 
              EACH CCSMS   NO-LOCK WHERE CCSMS.CUST-NUMBER  BEGINS ipcCompanyID 
                                     AND CCSMS.SALES-REP-ID EQ     CSAMS.SALES-REP-ID :
              
              THIS-OBJECT:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
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
                   
            END. /* FOR EACH CSAMS ENDS */
                    
          END. /* ELSE - IF lRegularslsmn */ 
                     
          FOR EACH ttCustomer BY ttCustomer.recentOrderDate DESCENDING:
            CREATE ttSortCustomer.
            BUFFER-COPY ttCustomer TO ttSortCustomer.  
          END. /* FOR EACH ttCustomer   */
                                  
        END. /* WHEN "recentvisit" THEN */
               
    END CASE.     
     
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError =  errorObj:GetMessage(1).       
    END CATCH.    
           
  END METHOD.
    /*------------------------------------------------------------------------------------
   Purpose: This method populates the temp-table and calls other methods for reqd data
   Input Parameters:
               1. cCustNumber  - Customer number
               2. ipcCompanyID - Logged-in Company ID
               3. ipcLangID    - Language ID of the Logged-In user

   Output Parameters:
               1. ttCustomer            - Table stores customer related data
               2. ttCustShippingAddress - Temp table which stores the shipping addresses 
                                          of the customer
               3. ttOpenOrder           - Stores all the open orders of the customers
               4. ttCustInvoice         - Stores the invoices of the customer
               5. ttCustAmountOverdue   - Stores the details of the customer overdue amount
               6. cError                - Error message (If any)
               7. opiStatusCode         - HTTP status code
  --------------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID fillAllCustomersData(INPUT  ipcSalesRepId AS CHARACTER,
                                          INPUT  ipcCompanyID  AS CHARACTER, 
                                          INPUT  ipcLangID     AS CHARACTER,
                                          OUTPUT TABLE ttCustomer, 
                                          OUTPUT TABLE ttCustShippingAddress,
                                          OUTPUT TABLE ttOpenOrder, 
                                          OUTPUT TABLE ttCustInvoice,
                                          OUTPUT TABLE ttCustAmountOverdue,
                                          OUTPUT TABLE ttCustBillingAddress,
                                          OUTPUT cError        AS CHARACTER,
                                          OUTPUT opiStatusCode AS INTEGER):
       
    DEFINE VARIABLE deTotalAmtOverdue AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deAvailCredit     AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deTotalOpenOrdr   AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE cPayTerms         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE opcLastXDays      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iNoOfDays         AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iTotalOpenOrdr    AS INTEGER   NO-UNDO. 
    DEFINE VARIABLE iTotalOverdues    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iTotalInvoices    AS INTEGER   NO-UNDO.
    DEFINE VARIABLE dRecentOrdrDate   AS DATE      NO-UNDO.
    DEFINE VARIABLE deCusSaleAmt90day AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deCustAmtInvoiced AS DECIMAL   NO-UNDO.     
    DEFINE VARIABLE iStatusCode       AS INTEGER   NO-UNDO.
    DEFINE VARIABLE opcDiscountPercent AS CHARACTER     NO-UNDO.
    DEFINE VARIABLE opcError           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iTermsDays         AS INTEGER NO-UNDO.
    DEFINE VARIABLE lcSalesId          AS CHARACTER NO-UNDO.
      
    DEFINE VARIABLE custOpenOrdrObj AS CLASS CustomerOrders NO-UNDO.      
    DEFINE VARIABLE objCommonSrc    AS CLASS CommonSource   NO-UNDO.
    DEFINE VARIABLE cntr            AS INTEGER NO-UNDO.
    
    DEFINE VARIABLE cCustImage  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileType   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE deUnitPrice AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE CDomain      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcListOfCust AS CHARACTER NO-UNDO.
    DEFINE VARIABLE deUsedCredit AS DECIMAL   NO-UNDO.
    objCommonSrc    = NEW CommonSource(INPUT cToken).
    custOpenOrdrObj = NEW CustomerOrders(INPUT cToken).
    
    ASSIGN lcSalesId = SUBSTRING(ipcSalesRepId, 2).
    
   
          
    //FOR EACH CCSMS WHERE (CCSMS.SALES-REP-ID EQ ipcSalesRepId OR CCSMS.SALES-REP-ID = "**") NO-LOCK USE-INDEX SALES-REP-ID:
   /* FOR EACH shpto WHERE SHPTO.SALES-REP-ID = ipcSalesRepId NO-LOCK BREAK BY SHPTO.CUST-NUMBER :
        IF FIRST-OF(SHPTO.CUST-NUMBER) THEN 
        ASSIGN lcListOfCust = lcListOfCust + "," + SHPTO.CUST-NUMBER.
    END. */
    
    DEFINE VARIABLE willShowAllCustomers AS LOGICAL NO-UNDO.
    FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID BEGINS "OE-SALES-OPERATOR" AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    willShowAllCustomers = AVAIL PARAMFL.
    /*
    MESSAGE "Entro a fillAllCustomersData"
    VIEW-AS ALERT-BOX.
    
    MESSAGE "ParamaFL Prendido " string(willShowAllCustomers)
    VIEW-AS ALERT-BOX.*/
    
    /* Create a list of customers assigned to Salesrep based on CCSMS and shpto*/
    FOR EACH ccsms WHERE CCSMS.CUST-Number BEGINS ipcCompanyID NO-LOCK:
       IF ccsms.SALES-REP-ID NE ipcSalesRepId THEN
       DO: 
          IF  willShowAllCustomers THEN DO:
              FIND ttSalesManCustList WHERE ttSalesManCustList.cust-num = CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
              IF NOT AVAILABLE ttSalesManCustList THEN DO:
              CREATE ttSalesManCustList.
              ASSIGN ttSalesManCustList.cust-num = CCSMS.CUST-NUMBER.
              END.
          END.
          ELSE DO:
            FOR EACH shpto WHERE shpto.cust-number  = ccsms.cust-number
                         AND ((shpto.SALES-REP-ID = ipcSalesRepId AND NOT willShowAllCustomers) OR willShowAllCustomers) NO-LOCK BREAK BY shpto.cust-number:
             IF FIRST-OF(shpto.cust-number) THEN DO:
                 FIND ttSalesManCustList WHERE ttSalesManCustList.cust-num = CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
                 IF NOT  AVAILABLE ttSalesManCustList THEN DO:
                 CREATE ttSalesManCustList.
                 ASSIGN ttSalesManCustList.cust-num = shpto.cust-number.
                 END.
              END.
            END.
          END.
       END.
    ELSE
    DO:
        FIND FIRST ttSalesManCustList WHERE ttSalesManCustList.cust-num EQ ccsms.cust-number NO-ERROR.
        IF NOT AVAILABLE ttSalesManCustList THEN 
        DO:
           CREATE ttSalesManCustList.
           ASSIGN ttSalesManCustList.cust-num = ccsms.cust-number.
        END.   
        
    END.

END.
  
    
DEFINE VARIABLE Counter AS INTEGER NO-UNDO INITIAL 0.
DEFINE VARIABLE PageNumber AS INTEGER NO-UNDO INITIAL 1.     
           
   // FOR EACH CCSMS WHERE (CCSMS.SALES-REP-ID EQ ipcSalesRepId AND CCSMS.CUST-Number BEGINS ipcCompanyID) NO-LOCK:
      FOR EACH ttSalesManCustList NO-LOCK:
        FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ  ttSalesManCustList.cust-num NO-LOCK NO-ERROR.
        IF NOT AVAILABLE CCSMS THEN NEXT.                                                                
      FOR LAST COOHD WHERE COOHD.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK USE-INDEX order-date:
        ASSIGN dRecentOrdrDate = COOHD.ORDER-DATE.
      END.
      /* Decides the number of days for sales in last XX days */
      IF VALID-OBJECT(objCommonSrc) THEN 
      DO:
         objCommonSrc:parameterFile(INPUT ConstantInitializer:cNoOfDays,
                                    INPUT  ipcCompanyID,
                                    INPUT  YES,
                                    OUTPUT opcLastXDays,
                                    OUTPUT cError) NO-ERROR.
                              
        ASSIGN iNoOfDays = INTEGER(opcLastXDays) NO-ERROR. 
      
        IF ERROR-STATUS:ERROR OR iNoOfDays EQ 0  THEN
          ASSIGN iNoOfDays = 180 NO-ERROR.
      END. /* IF VALID-OBJECT(objCommonSrc) THEN */
      
     /* THIS-OBJECT:CustomerDiscount(INPUT CCSMS.CUST-NUMBER,   
                                   INPUT CCSMS.TERMS-CODE, 
                                   OUTPUT opcDiscountPercent,                                    
                                   OUTPUT opcError). */
                                   
      ASSIGN Counter = Counter + 1.                             
          
      CREATE ttCustomer.
      ASSIGN 
        ttCustomer.customerNumber            = CCSMS.CUST-NUMBER
        ttCustomer.customerName              = REPLACE(CCSMS.CUST-NAME,"'", "") //CCSMS.CUST-NAME
        ttCustomer.secondName                = REPLACE(CCSMS.SECOND-NAME,"'", "") 
        /*ttCustomer.totalSales                = CCSMS.YTD-SALES*/
        ttCustomer.customerType              = CCSMS.CUST-TYPE              
        ttCustomer.creditLimit               = CCSMS.CREDIT-LIMIT
        ttCustomer.phoneNumber               = CCSMS.PHONE-NUMBER
        ttCustomer.emailId                   = CCSMS.E-MAIL
        ttCustomer.priceList                 = CCSMS.PRICE-LIST
        ttCustomer.route                     = CCSMS.ROUTE
        ttCustomer.poRequired                = IF CCSMS.ORG-TYPE MATCHES "P" THEN TRUE ELSE FALSE
        ttCustomer.number_of_days            = iNoOfDays 
        ttCustomer.discount                  = opcDiscountPercent
        ttCustomer.pageNumber                = PageNumber
        no-error.
        
        IF Counter MODULO 20 = 0 THEN DO:
        ASSIGN PageNumber = PageNumber + 1.
        MESSAGE "PageNumber " PageNumber
        VIEW-AS ALERT-BOX.
        END. //IF Counter MODULO 20 
       ASSIGN deCusSaleAmt90day = 0.0.       
      /* Logic to get the total sales of a customer */
      
      
         
      //Gama Cambio el For each del CSAHF para que ponga bien los datos si el paramfl esta prendido
          
     /* FOR EACH CSAHF WHERE CSAHF.CUST-NUMBER EQ CCSMS.CUST-NUMBER                    
                     AND CSAHF.SALES-REP-ID  EQ lcSalesId 
                     AND CSAHF.QTY-SHIPPED   NE 0 
                     AND CSAHF.INVOICE-DATE  GE (TODAY - iNoOfDays ) NO-LOCK: */
      FOR EACH CSAHF WHERE CSAHF.CUST-NUMBER EQ CCSMS.CUST-NUMBER AND CSAHF.Invoice-date GE (TODAY - iNoOfDays) USE-INDEX CUST-INVDT NO-LOCK:             
        IF csahf.SALES-REP-ID EQ lcSalesId OR willShowAllCustomers AND CSAHF.QTY-SHIPPED NE 0 THEN
        DO:
            IF NOT (CSAHF.ITEM-NUMBER BEGINS ipcCompanyID + "*") THEN 
            DO:
               ASSIGN  ttCustomer.totalSales = ttCustomer.totalSales + CSAHF.PRICE-ext. 
               IF CSAHF.INVOICE-DATE GT (TODAY - 90)  THEN 
               ASSIGN deCusSaleAmt90day = deCusSaleAmt90day + CSAHF.PRICE-ext.                      
            END.
            
            IF NOT CAN-FIND(FIRST ttCustInvoice WHERE ttCustInvoice.invoiceNumber EQ CSAHF.INVOICE-NO) THEN
            DO:    
                CREATE ttCustInvoice.
                ASSIGN ttCustInvoice.customerNumber = CSAHF.CUST-NUMBER
                       ttCustInvoice.invoiceNumber  = CSAHF.INVOICE-NO
                       ttCustInvoice.invoiceDate    = CSAHF.INVOICE-DATE
                       ttCustInvoice.orderNumber    = CSAHF.ORDER-NUMBER /* Added after bug raised */                   
                       iTotalInvoices               = iTotalInvoices + 1 NO-ERROR.
                
                /* Required following keys for getCustomers API in amount invoiced setion on mobile */
                FIND FIRST COPAR WHERE COPAR.CUST-NUMBER EQ CSAHF.CUST-NUMBER
                                   AND COPAR.CUS-CHG-NO  EQ CSAHF.INVOICE-NO 
                                   AND COPAR.CUS-INV-DATE EQ CSAHF.INVOICE-DATE NO-LOCK NO-ERROR.
            
                IF AVAILABLE COPAR THEN 
                DO:
                   FIND FIRST terms NO-LOCK WHERE TERMS.CUS-TERMS-CD EQ COPAR.TERMS-CODE NO-ERROR.
                   IF AVAILABLE terms THEN
                     ASSIGN iTermsDays = TERMS.TERMS-DAYS.
                  
                    ASSIGN ttCustInvoice.collected  = COPAR.CUS-PAYMENT
                           ttCustInvoice.due_on     = COPAR.CUS-INV-DATE + iTermsDays NO-ERROR.                               
                   
                   IF  ttCustInvoice.due_on EQ ? THEN ttCustInvoice.due_on = TODAY + 30.
                   FIND FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ COPAR.DESCRIPTION1  NO-LOCK NO-ERROR.
                   IF NOT AVAIL COOHD AND NOT CAN-FIND(FIRST COODT WHERE COODT.ORDER-NUMBER EQ COOHD.ORDER-NUMBER) THEN                                                           
                     /* This message will be displayed when no such record exists in COOHD and COODT */ 
                     ASSIGN ttCustInvoice.item_fr_invoice_nt_foundmsg = TRUE.
                END. /* IF AVAILABLE COPAR THEN */
            END. /* IF NOT CAN-FIND(FIRST ttCustInvoice).. */
            
            
            FIND FIRST ttCustInvoice WHERE ttCustInvoice.invoiceNumber EQ  CSAHF.INVOICE-NO  NO-ERROR.
            IF AVAILABLE ttCustInvoice THEN
            ASSIGN ttCustInvoice.invoiceAmount =  ttCustInvoice.invoiceAmount + CSAHF.PRICE-EXT.
            
            ASSIGN deCustAmtInvoiced = deCustAmtInvoiced + CSAHF.PRICE-EXT.    
        END.
      END. /* FOR EACH CSAHF   */
     
      /* get Picture */
      /* get Picture */                                              //Gama le anadio AND PARAMFL.PARAM-STATUS  para el error del Batch
      FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
      IF AVAILABLE paramfl THEN DO:
        ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1 
               Cdomain             = PARAMFL.PARAM-VALUE2
               FILE-INFO:FILE-NAME =  FILE-INFO:FILE-NAME + "\" + "customer" NO-ERROR.
      END.         
        
      IF FILE-INFO:FULL-PATHNAME NE ? THEN
      DO:
         INPUT FROM OS-DIR(FILE-INFO:FULL-PATHNAME).
         REPEAT:
            IMPORT cCustImage ^ cFileType.
            IF cFileType EQ "F":U AND INDEX(cCustImage,".pdf") = 0 AND INDEX(cCustImage,CCSMS.CUST-NUMBER) GT 0 THEN
              ttCustomer.customer_picture = (Cdomain + "/":U + "customer" + "/":U + Replace(cCustImage," ","%20")). // Customer Image
            IF cFileType EQ "F":U AND INDEX(cCustImage,".pdf") GT 0 AND INDEX(cCustImage,CCSMS.CUST-NUMBER) GT 0 THEN  
              ttCustomer.terms_condition_pdf =  (Cdomain + "/":U + "customer" + "/":U + Replace(cCustImage," ","%20")).  //Term and condition PDF  
            
         END. /* REPEAT */  
              
      END. /* IF FILE-INFO:FULL-PATHNAME NE ? THEN */  
      ELSE
      ASSIGN ttCustomer.customer_picture  = "".
    
      /* Get the billing address of the customer if exists */
      IF (CCSMS.ADDRESS-L1 NE "":U OR CCSMS.ADDRESS-L2 NE "":U OR CCSMS.ADDRESS-L3 NE "":U ) THEN
      DO:
        //IF NOT AVAILABLE  ttCustBillingAddress THEN DO: 
        CREATE ttCustBillingAddress.  
        ASSIGN   
          ttCustBillingAddress.customerNumber  = CCSMS.CUST-NUMBER         
          ttCustBillingAddress.billingAdd1     = REPLACE(CCSMS.ADDRESS-L1,"'", "") 
          ttCustBillingAddress.billingAdd2     = REPLACE(CCSMS.ADDRESS-L2,"'", "")
          ttCustBillingAddress.billingAdd3     = REPLACE(CCSMS.ADDRESS-L3,"'", "")
          ttCustBillingAddress.billingState    = CCSMS.POSTAL-STATE
          ttCustBillingAddress.billingCity     = ccsms.postal-city      
          ttCustBillingAddress.billingZip      = CCSMS.POSTAL-ZIP.   
         // END. //Gama anadio IF NOT AVAILABLE  ttCustBillingAddress por el tema de Time Complexity aunque aqui no hace mucho sentido
      END.  /* IF (CCSMS.ADDRESS-L1 NE "":U OR CCSMS.ADDRESS-L2 NE "":U OR CCSMS.ADDRESS-L3 NE "":U ) */
                   
      /* Get the multiple shipping addresses of the customer if exists */
      THIS-OBJECT:getCustShippingAddress(INPUT  CCSMS.CUST-NUMBER,
                                         INPUT  "",
                                         OUTPUT cError,
                                         OUTPUT TABLE ttCustShippingAddress).
      
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).   
      
      /* Get the amount overdue of the selected customer */
      THIS-OBJECT:CustomerAmountOverdue(INPUT  CCSMS.CUST-NUMBER,
                                        INPUT  ipcCompanyID, 
                                        OUTPUT deTotalAmtOverdue, 
                                        OUTPUT iTotalOverdues,
                                        OUTPUT TABLE ttCustAmountOverdue, 
                                        OUTPUT cError).         
           
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).           
            
      /* Get the amount of sales to a customer in last 90 days */
     /* THIS-OBJECT:customerSalesInLast90Days(INPUT  cCustNumber, 
                                            OUTPUT deCusSaleAmt90day, 
                                            OUTPUT cError).
           
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1). */
      
     
     /*  deAvailCredit = CCSMS.CREDIT-LIMIT - (CCSMS.OPEN-INVOICE - 
                                             CCSMS.ON-ACCOUNT - 
                                             CCSMS.CREDIT-AMT + 
                                             CCSMS.DEBIT-AMT + 
                                             CCSMS.ON-ORDER-AMT).   */
        deUsedCredit =  (CCSMS.OPEN-INVOICE
                        - CCSMS.ON-ACCOUNT
                        + CCSMS.ON-ORDER-AMT     
                        + CCSMS.DEBIT-AMT
                        - CCSMS.CREDIT-AMT).
        IF deUsedCredit < 0 THEN 
        deUsedCredit = ABS(deUsedCredit).                                                    
        deAvailCredit = ccsms.credit-limit
                        - deUsedCredit. 
      /* Get the payment information of the customer like payment terms */
      
      THIS-OBJECT:getPaymentInfo(INPUT  CCSMS.CUST-NUMBER, 
                                         OUTPUT cPayTerms, 
                                         OUTPUT cError).
            
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).

      /* Get customer's invoiced amount */        
    /*  THIS-OBJECT:getCustAmountInvoiced(INPUT  cCustNumber,
                                        INPUT  ipcCompanyID, 
                                        INPUT  CCSMS.SALES-REP-ID,
                                        OUTPUT deCustAmtInvoiced,
                                        OUTPUT iTotalInvoices,
                                        OUTPUT TABLE ttCustInvoice,
                                        OUTPUT cError).
            
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).
      */
       /* Get the open order of a customer. */
      custOpenOrdrObj:getCustOpenOrdrInfo(INPUT  CCSMS.CUST-NUMBER, 
                                          INPUT  ipcLangID ,
                                          INPUT  ipcCompanyID, 
                                          OUTPUT TABLE ttOpenOrder APPEND,
                                          OUTPUT deTotalOpenOrdr,
                                          OUTPUT iTotalOpenOrdr,        
                                          OUTPUT cError,
                                          OUTPUT opiStatusCode).   
                 
      IF cError NE "":U THEN
        UNDO,THROW NEW AppError(cError,1).

       /* Here CCSMS.DELINQUENT-I = 'H' Shows Customer is on Hold  */ 
      IF CCSMS.DELINQUENT-I = 'H':U THEN
        ASSIGN ttCustomer.onholdcust = YES.
      
      
      ASSIGN 
        ttCustomer.amtOverdue          = deTotalAmtOverdue
        ttCustomer.availCredit         = deAvailCredit
        ttCustomer.paymentTerm         = cPayTerms
        ttCustomer.totalOpenOrderAmt   = deTotalOpenOrdr
        ttCustomer.totalOpenOrder      = iTotalOpenOrdr
        ttCustomer.totalOverdues       = iTotalOverdues
        ttCustomer.totalInvoices       = iTotalInvoices
        ttCustomer.recentOrderDate     = IF dRecentOrdrDate EQ ? THEN "":U
                                         ELSE STRING(dRecentOrdrDate)
        ttCustomer.custSaleInLast90Day = deCusSaleAmt90day
        ttCustomer.custAmtInvoiced     = deCustAmtInvoiced  NO-ERROR.
   
    END. /* FOR Each CCSMS */
    
    ASSIGN opiStatusCode = 200.
        
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError    = errorObj:GetMessage(1).      
    END CATCH.  
                    
    FINALLY:
      IF VALID-OBJECT(custOpenOrdrObj) THEN    
        DELETE OBJECT custOpenOrdrObj.
      IF VALID-OBJECT(objCommonSrc) THEN      
        DELETE OBJECT objCommonSrc.
    END FINALLY.

  END METHOD.
  
    
END CLASS.