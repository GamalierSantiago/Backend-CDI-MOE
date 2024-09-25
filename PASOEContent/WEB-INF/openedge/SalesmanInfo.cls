 
/*---------------------------------------------------------------------------------
   File        : SalesmanInfo
   Purpose     : This class fetches the details of the logged In salesman (pg. 1)
   Syntax      : 
   Description : 
   Author(s)   : JKTECH
   Created     : Thu Jul 06 17:16:40 IST 2017
   Notes       : Version 1.1
   History     :
   ---------------------------------------------------------------------------------
   Date(MM-DD-YY)        Author            Initial(XX-Version)         Description
                                                   
   ---------------------------------------------------------------------------------    
 -----------------------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS SalesmanInfo: 
  
  /* temp-table to store total overdue of a customer  
  DEFINE PRIVATE TEMP-TABLE ttCustomerInfo NO-UNDO
    FIELD customerNumber LIKE CCSMS.CUST-NUMBER
    FIELD customerName   LIKE CCSMS.CUST-NAME           
    FIELD overdueAmount  AS   DECIMAL.*/
    
  /* temp-table to store all the overdues of a customer */  
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
     
  /* temp-table to store all the open orders of a customer */ 
  DEFINE PRIVATE TEMP-TABLE ttOpenOrder NO-UNDO
    FIELD orderNumber    LIKE COOHD.ORDER-NUMBER
    FIELD orderDate      LIKE COOHD.ORDER-DATE
    FIELD openAmt        LIKE COODT.ORDERED-PRC
    FIELD customerNumber LIKE CCSMS.CUST-NUMBER
    FIELD customerName AS CHARACTER.
  
  /* Temp-Table to store Salesperson's address */
  DEFINE PRIVATE TEMP-TABLE ttsalesPersonAdd NO-UNDO
    FIELD addressL1   LIKE CSAMS.ADDRESS-L1
    FIELD addressL2   LIKE CSAMS.ADDRESS-L2
    FIELD addressL3   LIKE CSAMS.ADDRESS-L3.
  
  
  DEFINE  TEMP-TABLE salesrepreport NO-UNDO 
    FIELD salesrep-id     AS CHARACTER 
    FIELD report-name     AS CHARACTER 
    FIELD report-location AS CHARACTER. 
            
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC SalesmanInfo ():

  END CONSTRUCTOR.
  
  CONSTRUCTOR PUBLIC SalesmanInfo (INPUT ipcToken AS CHARACTER):
            ASSIGN cToken =  ipcToken.                       
  END CONSTRUCTOR.
   
  /*-----------------------------------------------------------------------------------------------
   Purpose: This method gives the total number of overdue customers along with overdue amount
   Input Parameters: 1.ipcSalesRepId    - Stores the sales-rep-id of the logged in salesman.
                     2.ipcToken         - user-token.
                     3.ipcLangID        - language-id selected by the user.
                     4.lregularSalesman - login as: Yes - Regular salesperson,
                                                    No  - Supervisor.
   Output Parameters:1.ttCustomerInfo      - Temp-table contains details of each overdue customers.
                     2.opdeTotalAmtOverdue - it gives the total overdue amount of the logged
                                             in salesman.
                     3.opiOverdueCustCount - it gives the count of total overdue customers.
                     4.cError              - output error message
                     5.opiStatusCode       - provides Http status code
   Notes: 
  -------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getSalesmanCustomersOverdue(INPUT  ipcSalesRepId        AS CHARACTER,
                                                 INPUT  ipcCompanyID         AS CHARACTER, 
                                                 INPUT  lregularSalesman     AS LOGICAL,
                                                 OUTPUT TABLE ttCustomerInfo, 
                                                 OUTPUT opdeTotalAmtOverdue  AS DECIMAL,
                                                 OUTPUT opiOverdueCustCount  AS INTEGER,
                                                 OUTPUT cError               AS CHARACTER,
                                                 OUTPUT opiStatusCode        AS INTEGER):
	   	    

    DEFINE VARIABLE deOverdueAmt  AS DECIMAL   NO-UNDO.	    
    DEFINE VARIABLE iCustOpenInv  AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cCustNum      AS CHARACTER NO-UNDO. 
   
	        	   
    DEFINE VARIABLE objSales  AS CLASS SalesmanCustomersData NO-UNDO.
    ASSIGN objSales = NEW SalesmanCustomersData(INPUT cToken).
    
    
	    
	IF lregularSalesman THEN
    DO: 
      //MESSAGE "SalesManinfo.cls SalesRepCustomerAmountOverdue".
      objsales:SalesRepCustomerAmountOverdue (INPUT  cCustNum, 
                                              INPUT  ipcCompanyID,
                                              OUTPUT deOverdueAmt,
                                              OUTPUT iCustOpenInv,
                                              OUTPUT opiOverdueCustCount,
                                              OUTPUT TABLE ttCustomerInfo,
                                              OUTPUT cError).
      
      ASSIGN opdeTotalAmtOverdue = deOverdueAmt
             opiOverdueCustCount = opiOverdueCustCount.
      IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
          
      
          
      
    END. /*IF lregularSalesman*/                 	        	
      
    ELSE 
    DO:
//MESSAGE "inside getSalesmanCustomersOverdue".

      FOR EACH CSAMS NO-LOCK WHERE 
        CSAMS.SUPERVISOR EQ ipcSalesRepId, 
        EACH CCSMS WHERE
          CCSMS.SALES-REP-ID EQ CSAMS.sales-rep-id AND
          CCSMS.CUST-NUMBER  BEGINS ipcCompanyID   NO-LOCK:
          
          EMPTY TEMP-TABLE ttCustAmountOverdue.     
          ASSIGN 
            cCustNum = CCSMS.CUST-NUMBER. 
                  
          /*This method returns the overdue amount of a particular customer*/
          objSales:CustomerAmountOverdue(INPUT  cCustNum,
                                         INPUT  ipcCompanyID,
                                         OUTPUT deOverdueAmt,
                                         OUTPUT iCustOpenInv,
                                         OUTPUT TABLE ttCustAmountOverdue APPEND,
                                         OUTPUT cError).
           
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1). 
                  
          IF deOverdueAmt NE 0 THEN
          DO:
            ASSIGN 
              opdeTotalAmtOverdue = opdeTotalAmtOverdue  +  deOverdueAmt
              opiOverdueCustCount = opiOverdueCustCount  +  1  NO-ERROR.
            
            FOR EACH ttCustAmountOverdue NO-LOCK:
              IF NOT CAN-FIND(FIRST ttCustomerInfo WHERE ttCustomerInfo.customerNumber EQ ttCustAmountOverdue.customerNumber
                                             AND ttCustomerInfo.customerName   EQ ttCustAmountOverdue.customerName
                                             AND ttCustomerInfo.orderDate      EQ ttCustAmountOverdue.orderDate
                                             AND ttCustomerInfo.description1   EQ ttCustAmountOverdue.description1
                                             AND ttCustomerInfo.orderNumber    EQ ttCustAmountOverdue.orderNumber
                                             AND ttCustomerInfo.custInvoiceAmt EQ ttCustAmountOverdue.custInvoiceAmt
                                             AND ttCustomerInfo.overdueAmount  EQ ttCustAmountOverdue.overdueAmount) THEN 
      
              DO:                                      
                CREATE ttCustomerInfo.
                BUFFER-COPY ttCustAmountOverdue TO ttCustomerInfo.
              END.  /* IF NOT CAN-FIND(FIRST ttCustomerInfo).. */
            END.   /* FOR EACH ttCustAmountOverdue            */
                   
            /* CREATE ttCustomerInfo.
            ASSIGN 
            ttCustomerInfo.customerNumber = CCSMS.CUST-NUMBER
            ttCustomerInfo.customerName   = CCSMS.CUST-NAME
            ttCustomerInfo.overdueAmount  = deOverdueAmt  NO-ERROR. /*Gives overdue amount*/ */ 
          END. /*DO END */                                                  
        
      END. /*EACH  CSAMS*/
    END.
      
    ASSIGN opiStatusCode = 200.
        
    CATCH errorObj AS AppError: 
      ASSIGN cError = errorObj:GetMessage(1).
    END CATCH. 
        
    FINALLY:
      IF VALID-OBJECT(objSales) THEN  
        DELETE OBJECT objSales.      
    END FINALLY.
        
  END METHOD.

  /*-----------------------------------------------------------------------------------------------
   Purpose: This method returns the total number of open carts along with their total cart amount
   Input Parameters: 1.ipcSalesRepId    - stores the sales-rep-id of the logged in salesman.
                     2.ipcLangID        - provides language-id selected by the user,
                     3.lregularSalesman - login as: Yes - Regular salesperson,
                                                    No  - Supervisor.
   Output Parameters:1.opdeCartsAmt  - total open orders amount existing for all the customers of a salesperson.
                     2.opcError      - stores error message.
                     3.opiStatusCode - provides Http status code.
                     4.ttOpenOrder   - temp-table used to store all the open orders of a customer
   Notes: 
  -------------------------------------------------------------------------------------------------*/ 
  METHOD PUBLIC VOID getOpenCarts(INPUT  ipcSalesRepId        AS CHARACTER,
                                  INPUT  ipcLangID            AS CHARACTER,
                                  INPUT  lRegularSlsman       AS LOGICAL, 
                                  INPUT  ipcCompanyCode       AS CHARACTER,
                                  OUTPUT opiSalesPrsnOpnCarts AS INTEGER,
                                  OUTPUT opdeCartsAmt         AS DECIMAL,
                                  OUTPUT opcError             AS CHARACTER,
                                  OUTPUT opiStatusCode        AS INTEGER,
                                  OUTPUT TABLE ttOpenOrder ):
     
     DEFINE VARIABLE ipcCustNum      AS CHARACTER NO-UNDO.
     DEFINE VARIABLE deTotalOpenOrdr AS DECIMAL   NO-UNDO.
     DEFINE VARIABLE iTotalOrdrs     AS INTEGER   NO-UNDO.   
     
     DEFINE VARIABLE objCustOpnOrders AS CLASS CustomerOrders.
     ASSIGN objCustOpnOrders = NEW CustomerOrders(INPUT cToken).
     
     IF lRegularSlsman THEN 
     DO:              
       FOR EACH CCSMS NO-LOCK
         WHERE CCSMS.SALES-REP-ID EQ ipcSalesRepId
           AND CCSMS.CUST-number BEGINS ipcCompanyCode
           AND CCSMS.DELINQUENT-I NE "C":
           
         ASSIGN ipcCustNum = CCSMS.CUST-NUMBER NO-ERROR.
           
         objCustOpnOrders:getCustOpenOrdrInfo(INPUT  ipcCustNum,
                                              INPUT  ipcLangID,
                                              INPUT  ipcCompanyCode, 
                                              OUTPUT TABLE ttOpenOrder /*APPEND*/ ,
                                              OUTPUT deTotalOpenOrdr,
                                              OUTPUT iTotalOrdrs,
                                              OUTPUT opcError,
                                              OUTPUT opiStatusCode).
       
         IF opcError NE "":U THEN
           UNDO,THROW NEW AppError(opcError,1).
                                            
       END. /*FOR EACH CCSMS */
                                         
       FOR EACH ttOpenOrder NO-LOCK 
        /* BREAK BY (ttOpenOrder.customerNumber) */ : /* we are displaying total open orders now earlier 
                                                         we are trying to display open carts of a customer  */
         
       /*  IF FIRST-OF(ttOpenOrder.customerNumber) THEN */
         ASSIGN opiSalesPrsnOpnCarts = opiSalesPrsnOpnCarts + 1
                opdeCartsAmt         = opdeCartsAmt + ttOpenOrder.openAmt NO-ERROR.
         
       END. /*FOR EACH ttOpenOrder */
       
     END. /*IF lRegularSlsman */
     
     /* If the logged In person is a supervisor */
     ELSE 
     DO:        
       FOR EACH CSAMS WHERE CSAMS.SUPERVISOR EQ ipcSalesRepId NO-LOCK,
         EACH CCSMS NO-LOCK
           WHERE CCSMS.SALES-REP-ID EQ CSAMS.SALES-REP-ID:
           
         ASSIGN ipcCustNum = CCSMS.CUST-NUMBER NO-ERROR.
           
         objCustOpnOrders:getCustOpenOrdrInfo (INPUT ipcCustNum,
                                               INPUT  ipcLangID,
                                               INPUT  ipcCompanyCode,
                                               OUTPUT TABLE ttOpenOrder APPEND,
                                               OUTPUT deTotalOpenOrdr,
                                               OUTPUT iTotalOrdrs,
                                               OUTPUT opcError,
                                               OUTPUT opiStatusCode).
         IF opcError NE "":U THEN
           UNDO,THROW NEW AppError(opcError,1).
                                            
                                            
       END. /*FOR EACH CSAMS */
                                         
       FOR EACH ttOpenOrder NO-LOCK 
        /* BREAK BY (ttOpenOrder.customerNumber) */ : /* we are displaying total open orders now earlier 
                                                         we are trying to display open carts of a customer  */
         
/*         IF FIRST-OF(ttOpenOrder.customerNumber) THEN*/
         ASSIGN opiSalesPrsnOpnCarts = opiSalesPrsnOpnCarts + 1
                opdeCartsAmt         = opdeCartsAmt + ttOpenOrder.openAmt NO-ERROR.
       
       END. /*FOR EACH ttOpenOrder */
       
     END.  
     
     ASSIGN opiStatusCode = 200.
      
     CATCH errorObj AS AppError:           
       ASSIGN 
        opcError = errorObj:GetMessage(1).
     END CATCH.
     
  END METHOD.
  
	
    /*-------------------------------------------------------------------------------------------
     Purpose: This method used to fetch basic details of a logged in salesperson
     Input Parameters: 1.ipcUserName - stores the username/sales-rep-id of the logged in salesman.
                       2.ipcLangID   - provides language-id selected by the user,
                       
     Output Parameters:1.lregularSalesman - login as: Yes - Regular salesperson,
                                                      No  - Supervisor.
                       2.opcSalesName     - name of the logged in salesperson.
                       3.opcSalesRepId    - username of the salesperson.
                       4.ttsalesPersonAdd - temp-table to store salesperson address.
                       5.cError           - stores error if any.
                       6.opiStatusCode    - provides Http status code.
     Notes:                  
    ----------------------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID getSalesmanDetails(INPUT  ipcUserName      AS CHARACTER,
                                          INPUT  ipcLangID        AS CHARACTER,
                                          OUTPUT oplRegularSlsman AS LOGICAL,
                                          OUTPUT opcSalesName     AS CHARACTER,
                                          OUTPUT opcSalesRepId    AS CHARACTER,                                          
                                          OUTPUT TABLE ttsalesPersonAdd,
                                          OUTPUT cError           AS CHARACTER,
                                          OUTPUT opiStatusCode    AS INTEGER):
      
      DEFINE VARIABLE objCommonSrc    AS CLASS CommonSource NO-UNDO.
      
      ASSIGN objCommonSrc = NEW CommonSource(INPUT cToken).
                        
      FIND CSAMS WHERE CSAMS.sales-rep-id EQ ipcUserName  NO-LOCK NO-ERROR.
      
      IF AVAILABLE CSAMS THEN
      DO:      
        ASSIGN        
          oplRegularSlsman = CSAMS.laptop     /* User is a supervisor or a regular sales's person */
          opcSalesName     = REPLACE(CSAMS.SALES-NAME,"'", "") 
          opcSalesRepId    = CSAMS.SALES-REP-ID.
          
          
        IF ( CSAMS.ADDRESS-L1 NE "":U OR CSAMS.ADDRESS-L2 NE "":U OR CSAMS.ADDRESS-L3 NE "":U ) THEN
        DO:  
          CREATE ttsalesPersonAdd.
          ASSIGN ttsalesPersonAdd.addressL1 = REPLACE(CSAMS.ADDRESS-L1,"'", "")  
                 ttsalesPersonAdd.addressL2 = REPLACE(CSAMS.ADDRESS-L1,"'", "") 
                 ttsalesPersonAdd.addressL3 = REPLACE(CSAMS.ADDRESS-L1,"'", "") .
        END.         
        IF NOT oplRegularSlsman THEN 
        DO:
           IF NOT CAN-FIND (FIRST CSAMS WHERE CSAMS.SUPERVISOR EQ ipcUserName) THEN
            oplRegularSlsman = YES.           
        END.    
                                   
      END. /*IF AVAILABLE CSAMS THEN*/
      
      ELSE
      DO: 
        /* provides message in selected language when user is invalid */  
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvalidUser,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).   
      END.    
      
      ASSIGN opiStatusCode = 200.
      
      CATCH errorObj AS AppError:          
        ASSIGN cError = errorObj:GetMessage(1).
      END CATCH. 
      
      FINALLY:
        IF VALID-OBJECT(objCommonSrc) THEN
          DELETE OBJECT objCommonSrc.
      END FINALLY.
           
    END METHOD.

  /*---------------------------------------------------------------------------------
   Purpose: This method returns the total sales amount of a salesman in last 90 days
   Input Parameters: 1. ipcSalesRepId - Sales rep Id of the logged In person.
                     2. lregularSalesman - login as: Yes - Regular salesperson,
                                                     No  - Supervisor.
   Output Parameters: 1. opdeSalesAmt - Total sales amount of that salesman in last 90 days.
                      2. cError       - stores error message if any.
   Notes:                    
  -----------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID salesmanSalesAmtInLast90Days(INPUT  ipcSalesRepId    AS CHARACTER,
                                                  INPUT  ipcCompany       AS CHARACTER,
                                                  INPUT  lregularSalesman AS LOGICAL,
                                                  OUTPUT opdeSalesAmt     AS DECIMAL):       
                                                                
    DEFINE VARIABLE objCommonSrc AS CLASS commonSource NO-UNDO.

    DEFINE VARIABLE iNoOfDays    AS INTEGER            NO-UNDO.
    DEFINE VARIABLE opcLastXDays AS CHARACTER          NO-UNDO.
    DEFINE VARIABLE cError       AS CHARACTER          NO-UNDO.
    
    
    objCommonSrc = NEW CommonSource(INPUT cToken).
        
    IF VALID-OBJECT(objCommonSrc) THEN DO:
      
      objCommonSrc:parameterFile(INPUT ConstantInitializer:cNoOfDays,
                                 INPUT  ipcCompany,
                                 INPUT  YES,
                                 OUTPUT opcLastXDays,
                                 OUTPUT cError) NO-ERROR.
                              
      ASSIGN iNoOfDays = INTEGER(opcLastXDays) NO-ERROR. 
      
      IF ERROR-STATUS:ERROR OR iNoOfDays EQ 0  THEN
        ASSIGN iNoOfDays = 180 NO-ERROR.

    END. /* IF VALID-OBJECT(objCommonSrc) THEN */

    /*It's calculations will vary depending on whether logged in person is a regular or Supervisor*/
    
   // ASSIGN iNoOfDays = 90 NO-ERROR. // Sales in 90 days need to calculated
    
    IF lregularSalesman THEN
    DO:
       /* FOR FIRST CSAMS WHERE CSAMS.SALES-REP-ID = ipcSalesRepId NO-LOCK,            
          
          EACH CSAHF WHERE csahf.SALES-REP-ID    EQ ipcSalesRepId       
                       AND CSAHF.Invoice-date    GE (TODAY - iNoOfDays)
                       AND CSAHF.QTY-SHIPPED     NE 0 NO-LOCK:
                       //AND NOT CSAHF.ITEM-NUMBER BEGINS ipcCompany + "*"  NO-LOCK: 
          ASSIGN  
            opdeSalesAmt = opdeSalesAmt + CSAHF.Price-Ext /*Price, this can be changed after discussion*/.
           
      END.  /*FOR FIRST CSAMS*/  
      */
      
      FOR EACH CSAHF WHERE  CSAHF.Invoice-date GE (TODAY - iNoOfDays) NO-LOCK:
         IF csahf.SALES-REP-ID    EQ ipcSalesRepId AND CSAHF.QTY-SHIPPED     NE 0 THEN
            ASSIGN
                opdeSalesAmt = opdeSalesAmt + CSAHF.Price-Ext /*Price, this can be changed after discussion*/.
      END.     
    END. /*If lregularSalesman*/     

    /*When the logged in person is Supervisor*/
    
    ELSE 
    DO:
      /*In this case all those salesman whose supervisor is loggedIn person,  
        then it will accumulate the totalsales of all those salesperson*/
      FOR EACH CSAMS WHERE CSAMS.SUPERVISOR      EQ ipcSalesRepId NO-LOCK,
          EACH CSAHF WHERE CSAHF.Invoice-date    GE (TODAY - iNoOfDays) NO-LOCK:
          IF csahf.SALES-REP-ID    EQ CSAMS.SALES-REP-ID 
             AND CSAHF.QTY-SHIPPED     NE 0
             AND NOT CSAHF.ITEM-NUMBER BEGINS ipcCompany + "*" THEN 
             
          ASSIGN  
            opdeSalesAmt = opdeSalesAmt + CSAHF.PRICE-EXT.           
      END. /*FOR EACH CSAMS*/
    END. /*ELSE*/                     
                                                    
  END METHOD.
  
  /*-------------------------------------------------------------------------------------
   Purpose: This method updates the Long/Lat of the Customer whenever he reaches the
            customer site and also creates/updates the checkIn checkOut time of the 
            Salesman at the customer site. 
   Input Parameters: 1.ipcCustNum    - Cust Numner of the customer.
                     2.ipcLangID     - Language ID.
                     3.ipcUserId     - Sales rep Id of the logged In person.
                     4.ipcLongitude  - Longitude of the customer.
                     5.ipcLattitude  - Lattitude of the customer.
                     6.ipi64CheckIn  - Check In time of the salesman at the customer site.
                     
   Output Parameters:1.cError        - Errors if any.
                     2.opiStatusCode - Http Status code.
               
   Notes: 
  ----------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID salesmanLocationUpdate(INPUT ipcCustNum     AS CHARACTER,
                                            INPUT ipcLangID      AS CHARACTER, 
                                            INPUT ipcUserId      AS CHARACTER, 
                                            INPUT ipcLongitude   AS CHARACTER, 
                                            INPUT ipcLattitude   AS CHARACTER, 
                                            INPUT ipi64CheckIn   AS INT64, /* Received as timestamp */                                            
                                            OUTPUT cError        AS CHARACTER,
                                            OUTPUT opiStatusCode AS INTEGER):
                                                
       DEFINE VARIABLE iNowTimestamp   AS INT64              NO-UNDO.
       DEFINE VARIABLE dtNow           AS DATETIME-TZ        NO-UNDO.
       DEFINE VARIABLE objCommonSrc    AS CLASS CommonSource NO-UNDO.   
       
       ASSIGN dtNow        = NOW /* Store Current system time */
              objCommonSrc = NEW CommonSource(INPUT cToken).  
       
       /*Get timestamp of Now*/
       iNowTimestamp = objCommonSrc:getTimestamp(INPUT dtNow,
                                                 INPUT ipcLangID,
                                                 OUTPUT cError,
                                                 OUTPUT opiStatusCode).
       IF cError NE "":U THEN
         UNDO,THROW NEW AppError(cError,1). 
       
      /* 
         Checking the location of the salesman for the first time visit.If the salesman 
         is visiting for the first time then it will captures the location of the salesman 
      */                     
       
       IF (ipi64CheckIn NE 0 AND ipi64CheckIn NE ?) AND (ipi64CheckIn LE iNowTimestamp) THEN  
       DO TRANSACTION:                        
         CREATE LocationMgmt.
         ASSIGN 
           LocationMgmt.cust-number  = ipcCustNum
           LocationMgmt.sales-rep-id = ipcUserId
           LocationMgmt.CheckInTime  = ipi64CheckIn
           LocationMgmt.Longitude    = ipcLongitude 
           LocationMgmt.Latitude     = ipcLattitude NO-ERROR.                      
       END.  /* IF (ipdtCheckIn NE "":U ) */ 
       IF NOT ERROR-STATUS:ERROR THEN
         ASSIGN 
           opiStatusCode = 200. 
          
      CATCH errorObj AS AppError:          
        ASSIGN cError = errorObj:GetMessage(1).
      END CATCH. 
      
      FINALLY:
        IF VALID-OBJECT(objCommonSrc) THEN
          DELETE OBJECT objCommonSrc.
      END FINALLY.
       
  END METHOD.           
  
  METHOD PUBLIC CHARACTER GetSalesRepReport (INPUT ipcCompanyCode AS CHARACTER,
                                             INPUT SalesRep       AS CHARACTER,
                                             OUTPUT TABLE salesrepreport):
      
      DEFINE VARIABLE lcSource     AS CHARACTER NO-UNDO.
      DEFINE VARIABLE cDomain      AS CHARACTER NO-UNDO.
      DEFINE VARIABLE cItemImage   AS CHARACTER NO-UNDO.
      DEFINE VARIABLE cFileType    AS CHARACTER NO-UNDO.
      DEFINE VARIABLE lcPdfpath    AS CHARACTER NO-UNDO.
      
      lcSource    = THIS-OBJECT:ReportDirectory(INPUT SalesRep, INPUT ipcCompanyCode). 
      CDomain     = THIS-OBJECT:FINDCDN(ipcCompanyCode).  
      
      IF lCSource NE "x" THEN 
      DO: 
           FILE-INFO:FILE-NAME = lCSource.
           lCSource = FILE-INFO:FULL-PATHNAME. 
          
         INPUT FROM OS-DIR(lCSource).
         REPEAT:
               IMPORT cItemImage ^ cFileType.
               IF cFileType EQ "F":U AND INDEX(cItemImage,".pdf") GT 0 THEN
               lcPdfpath = CDomain + "/":U + "report/SLSM-" + SalesRep + "/" + Replace(cItemImage," ","%20").
               ELSE 
               lcPdfpath = "".
               
               IF  lcPdfpath NE "" THEN 
               DO:
                   CREATE salesrepreport.
                   ASSIGN salesrepreport.salesrep-id     = SalesRep
                          salesrepreport.report-name     = Replace(cItemImage," ","%20")
                          salesrepreport.report-location = lcPdfpath.
                        
               END.          
         END.
      END.
      IF NOT TEMP-TABLE salesrepreport:HAS-RECORDS THEN
      DO:
         CREATE salesrepreport.
         ASSIGN salesrepreport.salesrep-id     = SalesRep
                salesrepreport.report-name     = "No Report"
                salesrepreport.report-location = "#". 
      END.     
   END METHOD.     
  
  /* Method to return the SalesRep Report location */
  
   METHOD PUBLIC CHARACTER ReportDirectory (INPUT SalesRep AS CHARACTER,
                                            INPUT ipcCompanyCode AS CHARACTER):
                                                
     DEFINE VARIABLE ReportFolder  AS CHARACTER NO-UNDO.    
                                            
     FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "CDIPREMIUM-SALES-REP-REPORT"
                        AND PARAMFL.COMPANY-CODE = ipcCompanyCode
                        AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.     
     //FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
     
     IF AVAILABLE paramfl THEN 
     DO:
         ReportFolder = PARAMFL.PARAM-VALUE1 + "/SLSM-" + SalesRep.
        ASSIGN FILE-INFO:FILE-NAME = ReportFolder. //PARAMFL.PARAM-VALUE1.
        
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
     RETURN PARAMFL.PARAM-VALUE4.
     
     ELSE 
     RETURN "x".    
   END METHOD.                                              
  
END CLASS.
