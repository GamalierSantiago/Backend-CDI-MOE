@openapi.openedge.export FILE(type="REST", executionMode="singleton", useReturnValue="false", writeDataSetBeforeImage="false").
 
/*----------------------------------------------------------------------------------
   File        : CommonSource
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : JKTECH
   Created     : Thu Aug 03 13:34:53 IST 2017
   Notes       : Version 1.1    
   History     :
   ----------------------------------------------------------------------------------
   Date(MM-DD-YY)          Author             Initial(XX-Version)       Description
                                                   
   ----------------------------------------------------------------------------------    
-------------------------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS CommonSource:
 
 /*Temp-table used to store all the details of a customer */            
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
    FIELD number_of_days      AS INTEGER.  
          
  DEFINE PRIVATE VARIABLE cError AS CHARACTER NO-UNDO.
  
 /*Temp-table used to store customers in sorted order */
  DEFINE PRIVATE TEMP-TABLE ttSortCustomer NO-UNDO LIKE ttCustomer. 
 
 /*Temp-table used to store customer's open-order details */       
  DEFINE PRIVATE TEMP-TABLE ttOpenOrder NO-UNDO 
    FIELD orderNumber    LIKE COOHD.ORDER-NUMBER
    FIELD orderDate      LIKE COOHD.ORDER-DATE
    FIELD openAmt        LIKE COODT.ORDERED-PRC
    FIELD customerNumber LIKE CCSMS.CUST-NUMBER 
    FIELD customerName   AS CHARACTER.
/*Temp-table used to store the customer's order amount-overdue details */       
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
 
/* Temp-table used to store customer's open order details */   
  DEFINE PRIVATE TEMP-TABLE ttOrder NO-UNDO LIKE ttOpenOrder.

/* Temp-table used to store customer's invoice details */  
  DEFINE PRIVATE TEMP-TABLE ttCustInvoice NO-UNDO
    FIELD customerNumber AS CHARACTER
    FIELD invoiceNumber  AS CHARACTER
    FIELD orderNumber    AS CHARACTER
    FIELD invoiceDate    AS DATE
    FIELD invoiceAmount  AS DECIMAL
    FIELD collected      LIKE COPAR.CUS-PAYMENT
    FIELD due_on         LIKE COPAR.CUS-INV-DATE
    FIELD item_fr_invoice_nt_foundmsg AS LOGICAL.

/* Temp-table used to store all the company details */    
  DEFINE PRIVATE TEMP-TABLE ttCompany NO-UNDO
    FIELD companyCode    AS CHARACTER
    FIELD companyName    AS CHARACTER
    FIELD companyFreight AS DECIMAL.

/* Temp-table used to store all the English literals  */  
  DEFINE PRIVATE TEMP-TABLE ttEnglish NO-UNDO 
    FIELD languageId   AS CHARACTER
    FIELD keyName      AS CHARACTER
    FIELD keyValue     AS CHARACTER. 
 
 /* Temp-table used to store all the Spanish literals  */    
  DEFINE PRIVATE TEMP-TABLE ttSpanish NO-UNDO LIKE ttEnglish. 
  DEFINE PRIVATE TEMP-TABLE ttLiterals NO-UNDO LIKE ttEnglish .
 
/* Temp-table used to store customer's multiple shipping addresses  */    
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
 
 /* Temp-table used to store customer's billing address */   
  DEFINE PRIVATE TEMP-TABLE ttCustBillingAddress NO-UNDO 
    FIELD customerNumber AS CHARACTER     
    FIELD billingAdd1    LIKE ccsms.ADDRESS-L1
    FIELD billingAdd2    LIKE ccsms.ADDRESS-L2
    FIELD billingAdd3    LIKE ccsms.ADDRESS-L3
    FIELD billingState   LIKE ccsms.POSTAL-STATE
    FIELD billingCity    LIKE CCSMS.POSTAL-city  
    FIELD billingZip     LIKE CCSMS.POSTAL-ZIP.     
    
  DEFINE PRIVATE STREAM mystream1. /* Stream used to read literals from English csv file */
  DEFINE PRIVATE STREAM mystream2. /* Stream used to read literals from Spanish csv file */
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  
  CONSTRUCTOR PUBLIC CommonSource (INPUT ipcToken AS CHARACTER):
        ASSIGN cToken =  ipcToken.
  END CONSTRUCTOR.
 
  CONSTRUCTOR PUBLIC CommonSource ():
        
  END CONSTRUCTOR.
    
  /*----------------------------------------------------------------------------------------------
   Purpose:This method is used for searching customer and display all details of that customer.
   INPUT Parameters: 1. ipcSearchKey         - Search key as customer number
                     2. ipcToken             - Token number
                     3. ipcSalesRepId        - SaklesRepId of the salesman
                     4. ipcLangID            - Language ID
                     
   OUTPUT parameters:1. opcError             - Stores error message if any
                     2. ttCustomer           - Table stores customer related data
                     3. ttOpenOrder          - Stores all the open orders of the customers
                     4. ttCustInvoice        - Stores invoice details of customer
                     5. ttCustAmountOverdue  - Stores the details of the customer overdue amount
                     6. opiStatusCode        - Response Code
  -----------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID customerSearch(INPUT  ipcSearchKey  AS CHARACTER,
                                    INPUT  ipcCompanyID  AS CHARACTER,
                                    INPUT  ipcSalesRepId AS CHARACTER,
                                    INPUT  ipcLangID     AS CHARACTER,
                                    OUTPUT opcError      AS CHARACTER,
                                    OUTPUT TABLE ttCustomer,
                                    OUTPUT TABLE ttOpenOrder,
                                    OUTPUT TABLE ttCustInvoice,
                                    OUTPUT TABLE ttCustAmountOverdue,
                                    OUTPUT TABLE ttCustShippingAddress,
                                    OUTPUT TABLE ttCustBillingAddress,
                                    OUTPUT opiStatusCode AS INTEGER):
  
    DEFINE VARIABLE objFillCustomerData AS CLASS SalesmanCustomersData NO-UNDO.
    objFillCustomerData = NEW SalesmanCustomersData(INPUT cToken).
    
    FOR FIRST CCSMS NO-LOCK
      WHERE CCSMS.CUST-NAME    EQ ipcSearchKey
        AND CCSMS.SALES-REP-ID EQ ipcSalesRepId:
            
      objFillCustomerData:fillCustomersData(INPUT  CCSMS.CUST-NUMBER,
                                            INPUT  ipcCompanyID,
                                            INPUT  ipcLangID,
                                            OUTPUT TABLE ttCustomer /*APPEND*/,
                                            OUTPUT TABLE ttCustShippingAddress,
                                            OUTPUT TABLE ttOpenOrder /*APPEND*/,
                                            OUTPUT TABLE ttCustInvoice /*APPEND*/,
                                            OUTPUT TABLE ttCustAmountOverdue /*APPEND 21-07-2017*/,
                                            OUTPUT TABLE ttCustBillingAddress,
                                            OUTPUT cError,
                                            OUTPUT opiStatusCode).  
                                           
    END. /* FOR FIRST CCSMS.. */
    
    IF cError NE "":U THEN
      ASSIGN opcError = cError. 
    
    FINALLY:
      DELETE OBJECT objFillCustomerData.
    END FINALLY.  
            
  END METHOD.
  
  /*-----------------------------------------------------------------------------------------------
   Purpose:This method is used to generate a timestamp.
   INPUT Parameters: 1.ipcDateTime    - date-time and timezone 
                     2.ipcLangID      - language-id
                    
   OUTPUT Parameters:1.opcError       - this will have the error message if any
                     2.opiStatusCode  - this stores the response code               
    -------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC INT64 getTimestamp(INPUT ipcDateTime    AS DATETIME-TZ,
                                   INPUT ipcLangID      AS CHARACTER,
                                   OUTPUT opcError      AS CHARACTER,
                                   OUTPUT opiStatusCode AS INTEGER):
      
    DEFINE VARIABLE dtzStartTime AS DATETIME-TZ NO-UNDO INIT "01-01-1970 00:00:00+00:00":U.
    DEFINE VARIABLE intTimestamp AS INT64    NO-UNDO.
       
    ASSIGN ipcDateTime = DATETIME-TZ(ipcDateTime) NO-ERROR.
    IF ERROR-STATUS:ERROR THEN
    DO:
      /* provides message in selected language when incoming date-time value is invalid */  
      THIS-OBJECT:getMessages(INPUT  ipcLangID,
                              INPUT  ConstantInitializer:c200InvalidDateTime,                                                              
                              OUTPUT cError,
                              OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).  
    END.    
    
    //ipcDateTime = DATETIME-TZ("09/04/2017 16:19:11.853+05:30").
    ASSIGN intTimestamp = INTERVAL(ipcDateTime , dtzStartTime, "milliseconds":U).
     
    RETURN intTimestamp.
   
    CATCH errorObj AS AppError:           
      ASSIGN 
       opcError = errorObj:GetMessage(1).   
    END CATCH.
       
  END METHOD.
   
  /*------------------------------------------------------------------------------
   Purpose:This method returns parameter value based on some specific data. This
           method is used as parameter file.
   INPUT Parameters:1. ipcParamId         - Parameter Id
                    2. ipcCompanyCode     - Company Code
                    3. ipcParamStatus     - Parameter Status
                    4. ipcLangID          - Language ID
                    
   OUTPUT Parameters:1.opcParamValue      - Parameter Value
                     2.cError             - error message if any
                     3.opiStatusCode      - Response Code
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID parameterFile(INPUT  ipcParamId     AS CHARACTER,
                                   INPUT  ipcCompanyCode AS CHARACTER,
                                   INPUT  ipcParamStatus AS LOGICAL,
                                   OUTPUT opcParamValue  AS CHARACTER,
                                   OUTPUT cError         AS CHARACTER):
     
                                         
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ ipcParamId
                   AND PARAMFL.COMPANY-CODE EQ ipcCompanyCode
                   AND PARAMFL.PARAM-STATUS EQ ipcParamStatus  NO-LOCK NO-ERROR.
      
    IF AVAILABLE(PARAMFL) THEN
      ASSIGN opcParamValue = PARAMFL.PARAM-VALUE1.
      
    CATCH errorObj AS AppError:           
      ASSIGN 
        cError = errorObj:GetMessage(1).
    END CATCH. 
                                         
  END METHOD.
  
  
  /*------------------------------------------------------------------------------
   Purpose: This method fetch all Company details available in database.
   Output Parameter: 1.ttCompany - Temp-Table for all company details,
                     2.cError    - returns error if any. 
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getCompanyCode(OUTPUT TABLE ttCompany,
                                    OUTPUT cError AS CHARACTER):
                                        
    
    FOR EACH CMPNY NO-LOCK:
          
      CREATE ttCompany.
      ASSIGN 
        ttCompany.companyCode = CMPNY.COMPANY-CODE
        ttCompany.companyName = CMPNY.COMPANY-NAME NO-ERROR.
        
      FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ CMPNY.COMPANY-CODE
                     AND PARAMFL.PARAM-ID     EQ "SP-FREIGHT":U
                     AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
   
      IF AVAILABLE PARAMFL THEN
        ASSIGN ttCompany.companyFreight = DECIMAL(PARAMFL.PARAM-VALUE3) NO-ERROR. 
           
    END. /* FOR EACH CMPNY.. */ 
    
    CATCH errorObj AS AppError:           
        ASSIGN cError = errorObj:GetMessage(1).
    END CATCH.
                                         
  END METHOD.                                        
  
  
  /*-----------------------------------------------------------------------------------------------
   Purpose: This method will return the literals corresponding to the passed languages.
   Input Parameter:  1.ipcLangID  - Language ID corresponding to which literals are required.
   
   Output Parameter: 1.ttEnglish     - Temp-table stores english literals,
                     2.ttSpanish     - temp-table contains spanish literals,
                     3.cError        - returns an error if any.
                     4.opiStatusCode - this the response code
   Notes:
  -------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID returnLiterals(INPUT  ipcLangID     AS CHARACTER,
                                    OUTPUT TABLE ttEnglish,
                                    OUTPUT TABLE ttSpanish,
                                    OUTPUT outMessage    AS CHARACTER,
                                    OUTPUT opiStatusCode AS INTEGER):
                                        
    DEFINE VARIABLE cFilename  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFilepath  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFiletype  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileExist AS CHARACTER NO-UNDO.    
    DEFINE VARIABLE cLangDir   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cLangID    AS CHARACTER NO-UNDO.
      
    /* Checking input parameter is not blank */           
    IF TRIM(ipcLangID) NE "":U AND TRIM(ipcLangID) NE ? THEN  
    DO:
      FILE-INFO:FILE-NAME = "lang\literals":U.
      
      /* Checking if the input parameter request for all languages */                 
      IF ipcLangID EQ "*":U THEN  
      DO:  
        FOR EACH CDILanguage NO-LOCK:
            
            ASSIGN cFilepath = FILE-INFO:FULL-PATHNAME + "\":U + CDILanguage.LiteralsDir.
           
            IF SEARCH(cFilepath) <> ? THEN /* search will return ? if it does not find cFilepath */
            DO:
              IF CDILanguage.Language-ID EQ "0":U THEN
              DO:  
                INPUT stream mystream2 from value(cFilepath).
         
                REPEAT:
                  CREATE ttEnglish.
                  IMPORT STREAM mystream2 DELIMITER ",":U  ttEnglish.
                END. /* REPEAT */
              
                INPUT close.  
              END. /* IF CDILanguage.Language-ID EQ "0" THEN */
            
              IF CDILanguage.Language-ID EQ "1":U THEN
              DO:  
                INPUT stream mystream2 from value(cFilepath).
         
                REPEAT:
                  CREATE ttSpanish.
                  IMPORT STREAM mystream2 DELIMITER ",":U ttSpanish.
                END. /* REPEAT */
              
                INPUT close.  
              END. /* IF CDILanguage.Language-ID EQ "1" THEN */
              
            END. /* IF SEARCH(cFilepath) */
            ELSE
            DO:
              ASSIGN outMessage    = "Server resource not found":U
                     opiStatusCode = 200.  
              UNDO,THROW NEW AppError(outMessage,1).    
            END.    
        END. /* FOR EACH CDILanguage */
        
      END. /* IF ipcLangID EQ "*" THEN */
 
      ELSE
      DO: 
        FIND FIRST CDILanguage WHERE CDILanguage.Language-ID EQ ipcLangID NO-LOCK NO-ERROR.
        IF AVAILABLE CDILanguage THEN
        DO:  
          ASSIGN cFilepath = FILE-INFO:FULL-PATHNAME + "\":U + CDILanguage.LiteralsDir.
            
          IF SEARCH(cFilepath) <> ? THEN
          DO:
            IF CDILanguage.Language-ID EQ "0":U THEN
            DO:  
              INPUT stream mystream2 from value(cFilepath).
         
              REPEAT:
                CREATE ttEnglish.
                IMPORT STREAM mystream2 DELIMITER ",":U  ttEnglish.
              END. /* REPEAT */
              
              INPUT close.                
            END. /* IF CDILanguage.Language-ID EQ "0" THEN */
            
            IF CDILanguage.Language-ID EQ "1":U THEN
            DO:  
              INPUT stream mystream2 from value(cFilepath).
         
              REPEAT:
                CREATE ttSpanish.
                IMPORT STREAM mystream2 DELIMITER ",":U ttSpanish.
              END. /* REPEAT */
              
              INPUT close.  
            END. /* IF CDILanguage.Language-ID EQ "1" THEN */
              
          END. /* IF SEARCH(cFilepath) .. */
          ELSE
          DO:
            ASSIGN outMessage    = "Server resource not found":U
                   opiStatusCode = 200.  
            UNDO,THROW NEW AppError(outMessage,1).
          END.                       
        END. /* IF AVAILABLE CDILanguage THEN.. */  
          
        ELSE 
        DO:
          ASSIGN outMessage    = "Language not supported":U
                 opiStatusCode = 200.  
          UNDO,THROW NEW AppError(outMessage,1).   
        END. /* ELSE when CDILanguage.Language-ID doesn't exist */ 
        
      END. /* ELSE of  ipcLangID EQ "*" THEN */ 
      
    END. /* IF ipcLangID  NE "":U THEN .. */ 
    
    ELSE 
    DO: 
      ASSIGN outMessage    = "No language selected":U
             opiStatusCode = 200.
      UNDO,THROW NEW AppError(outMessage,1).       
    END. /* ELSE */ 
        
    CATCH errorObj AS AppError:           
      ASSIGN 
        outMessage = errorObj:GetMessage(1).       
    END CATCH.

  END METHOD.
  
  
  /*-----------------------------------------------------------------------------------------------
   Purpose: This method will return the literals corresponding to the all passed languages.
   Input Parameter:  1.ipcLangID     - Language ID corresponding to which literals are required.
                     2.ipcMsgID      - Messag id for the message.
   Output Parameter: 1.cError        - returns an error if any.
                     2.opiStatusCode - Response Code
   Notes:
  -------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getMessages(INPUT  ipcLangID     AS CHARACTER,
                                 INPUT  ipcMsgID      AS CHARACTER,
                                 OUTPUT outMessage    AS CHARACTER,
                                 OUTPUT opiStatusCode AS INTEGER):
       
    IF ipcLangID EQ "*":U THEN
    DO:
       ASSIGN cError        = "Unsupported language id, cannot process your request":U 
              opiStatusCode = 200.
       UNDO,THROW NEW AppError(cError,1).       
    END.
    /* method used to get all the literals and messages based on the selected language-id */            
    THIS-OBJECT:returnLiterals(INPUT ipcLangID,
                               OUTPUT TABLE ttEnglish,
                               OUTPUT TABLE ttSpanish,
                               OUTPUT outMessage,
                               OUTPUT opiStatusCode).
      
    IF outMessage NE "":U THEN
      UNDO,THROW NEW AppError(outMessage,1).
            
    IF ipcLangID EQ "0":U THEN
    DO: /*If langid is 0 it will find record in ttEnglish with the keyname = msgid and corresponding keyvalue assigned
           to outMessage */
      FIND FIRST ttEnglish WHERE (ttEnglish.languageId EQ ipcLangID) AND (ttEnglish.keyName EQ ipcMsgID) NO-ERROR.
      IF AVAILABLE ttEnglish THEN
      DO:
        ASSIGN   
          outMessage    = ttEnglish.keyValue  
          opiStatusCode = INTEGER(ENTRY(1,ttEnglish.keyName,"_":U)) NO-ERROR.
        
        IF ERROR-STATUS:ERROR THEN
          ASSIGN opiStatusCode = 200.
            
      END. /* FIND FIRST ttEnglish */  
    END.    
 
    ELSE IF ipcLangID EQ "1":U THEN 
    DO: 
      /* If langid is 1 it will find record in ttSpanish with the keyname = msgid and corresponding keyvalue assigned
         to outMessage */ 
      FIND FIRST ttSpanish WHERE (ttSpanish.languageId EQ ipcLangID) AND (ttSpanish.keyName EQ ipcMsgID) NO-ERROR.
      IF AVAILABLE ttSpanish THEN
      DO:
        ASSIGN   
          outMessage    = ttSpanish.keyValue 
          opiStatusCode = INTEGER(ENTRY(1,ttSpanish.keyName,"_":U)) NO-ERROR.
        
        IF ERROR-STATUS:ERROR THEN
          ASSIGN opiStatusCode = 200. 
           
      END. /* FIND FIRST ttSpanish */    
    END.             
        
    CATCH errorObj AS AppError:           
      ASSIGN 
        outMessage = errorObj:GetMessage(1).   
    END CATCH.
                                 
  END METHOD. 
    
  /*-----------------------------------------------------------------------------------------------
   Purpose: This method will return the literals corresponding to the all passed languages.
   Input Parameter:  1.ipcLangID     - Language ID corresponding to which literals are required.
                     2.ipcMsgID      - Messag id for the message.
   Output Parameter: 1.cError        - returns an error if any.
                     2.opiStatusCode - Response Code
   Notes:
  -------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID reLiterals(INPUT  ipcLangID       AS CHARACTER,
                                OUTPUT JsonArrLiterals AS JsonArray,
                                OUTPUT outMessage      AS CHARACTER,
                                OUTPUT opiStatusCode   AS INTEGER):
                                        
    DEFINE VARIABLE cFilename  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFilepath  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFiletype  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileExist AS CHARACTER NO-UNDO.    
    DEFINE VARIABLE cLangDir   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cLangID    AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE JsonObjLiterals AS CLASS JsonObject NO-UNDO. 
    DEFINE VARIABLE objLangLiterals AS CLASS JsonObject NO-UNDO.
//    DEFINE VARIABLE JsonArrLiterals AS CLASS JsonArray  NO-UNDO.
    
    JsonArrLiterals = NEW JsonArray().
    
    /* Checking input parameter is not blank */           
    IF TRIM(ipcLangID) NE "":U AND TRIM(ipcLangID) NE ? THEN  
    DO:
      FILE-INFO:FILE-NAME = "lang\literals":U.
      /* Checking if the input parameter request for all languages */                 
      IF ipcLangID EQ "*":U THEN  
      DO:  
        FOR EACH CDILanguage NO-LOCK:
            
            ASSIGN cFilepath = FILE-INFO:FULL-PATHNAME + "\":U + CDILanguage.LiteralsDir.
           
            IF SEARCH(cFilepath) <> ? THEN /* search will return ? if it does not find cFilepath */
            DO:
                objLangLiterals = NEW JsonObject().
                JsonObjLiterals = NEW JsonObject().
                
                EMPTY TEMP-TABLE ttLiterals.
                
                INPUT stream mystream2 from value(cFilepath).
         
                REPEAT:
                  CREATE ttLiterals.
                  IMPORT STREAM mystream2 DELIMITER ",":U  ttLiterals.
                END. /* REPEAT */
              
                INPUT close.
                
                FOR EACH ttLiterals WHERE ttLiterals.keyName NE "":U AND ttLiterals.keyValue NE "":U :
                  objLangLiterals:ADD(INPUT ttLiterals.keyName, INPUT ttLiterals.keyValue).
                END.
                
                JsonObjLiterals:ADD(INPUT "languageId":U,INPUT CDILanguage.Language-ID).
                JsonObjLiterals:ADD(INPUT "languageName":U,INPUT CDILanguage.Language-Name).
                JsonObjLiterals:ADD(INPUT "literals":U,INPUT objLangLiterals).
                JsonArrLiterals:ADD(INPUT JsonObjLiterals).
              
            END. /* IF SEARCH(cFilepath)*/
            ELSE
            DO:
              ASSIGN outMessage    = "Server resource not found":U
                     opiStatusCode = 200.  
              UNDO,THROW NEW AppError(outMessage,1).    
            END.   
             
        END. /* FOR EACH CDILanguage */
        
      END. /* IF ipcLangID EQ "*" THEN */
 
      ELSE
      DO: 
        FIND FIRST CDILanguage WHERE CDILanguage.Language-ID EQ ipcLangID NO-LOCK NO-ERROR.
        IF AVAILABLE CDILanguage THEN
        DO:  
          ASSIGN cFilepath = FILE-INFO:FULL-PATHNAME + "\":U + CDILanguage.LiteralsDir.
            
          IF SEARCH(cFilepath) <> ? THEN
          DO:
            objLangLiterals = NEW JsonObject().
            JsonObjLiterals = NEW JsonObject().
            
            EMPTY TEMP-TABLE ttLiterals.
            
            INPUT stream mystream2 from value(cFilepath).
     
            REPEAT:
              CREATE ttLiterals.
              IMPORT STREAM mystream2 DELIMITER ",":U  ttLiterals.
            END. /* REPEAT */
          
            INPUT close.
            
            FOR EACH ttLiterals WHERE ttLiterals.keyName NE "":U AND ttLiterals.keyValue NE "":U :
              objLangLiterals:ADD(INPUT ttLiterals.keyName, INPUT ttLiterals.keyValue).
            END.
            
            JsonObjLiterals:ADD(INPUT "languageId":U,INPUT CDILanguage.Language-ID).
            JsonObjLiterals:ADD(INPUT "languageName":U,INPUT CDILanguage.Language-Name).
            JsonObjLiterals:ADD(INPUT "literals":U,INPUT objLangLiterals).
            JsonArrLiterals:ADD(INPUT JsonObjLiterals).
              
          END. /* IF SEARCH(cFilepath) .. */
          
          ELSE
          DO:
            ASSIGN outMessage    = "Server resource not found":U
                   opiStatusCode = 200.  
            UNDO,THROW NEW AppError(outMessage,1).
          END.                       
        END. /* IF AVAILABLE CDILanguage THEN.. */  
          
        ELSE 
        DO:
          ASSIGN outMessage    = "Language not supported":U
                 opiStatusCode = 200.  
          UNDO,THROW NEW AppError(outMessage,1).   
        END. /* ELSE when CDILanguage.Language-ID doesn't exist */ 
        
      END. /* ELSE of  ipcLangID EQ "*" THEN */ 
      
    END. /* IF ipcLangID  NE "":U THEN .. */ 
    
    ELSE 
    DO: 
      ASSIGN outMessage    = "No language selected":U
             opiStatusCode = 200.
      UNDO,THROW NEW AppError(outMessage,1).       
    END. /* ELSE */ 
    
//    oplcLiterals = JsonArrLiterals:GetJsonText().
        
    CATCH errorObj AS AppError:           
      ASSIGN 
        outMessage = errorObj:GetMessage(1).       
    END CATCH.

  END METHOD.                                   
END CLASS.

