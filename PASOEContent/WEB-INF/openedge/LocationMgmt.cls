 
 /*------------------------------------------------------------------------
    File        : LocationMgmt
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : JKTECH
    Created     : Mon Jun 18 03:31:17 BOT 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

                
CLASS LocationMgmt: 
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
    
    DEFINE TEMP-TABLE ttSalesRepLocation
      FIELD sales_rep_id   LIKE LocationMgmt.Sales-Rep-Id  
      FIELD sales-rep-name LIKE CSAMS.SALES-NAME
      FIELD check_in_time  LIKE LocationMgmt.CheckInTime
      FIELD check_out_time LIKE LocationMgmt.CheckoutTime
      FIELD longitude      LIKE LocationMgmt.Longitude
      FIELD Latitude       LIKE LocationMgmt.Latitude.    
        
    CONSTRUCTOR PUBLIC LocationMgmt (  ):
        /*DEFINE VARIABLE cError AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cCode AS INT NO-UNDO.
        
        THIS-OBJECT:slsmanCheckInCheckout(INPUT "O**",
                                          INPUT "O04045",
                                          INPUT "1",
                                          INPUT "28789098",
                                          INPUT "77432423948",
                                          INPUT "0",
                                          INPUT 1529398056,
                                          INPUT 0,
                                          INPUT 0,
                                          OUTPUT cError,
                                          OUTPUT cCode ).   
                                MESSAGE cError
                                VIEW-AS ALERT-BOX. */
       /*DEFINE VARIABLE opcError AS CHARACTER NO-UNDO.
       DEFINE VARIABLE opiStatusCode AS INTEGER NO-UNDO.                         
                                this-object:getSalesmanLocations(INPUT 'n10',
                                          INPUT 90, 
                                          INPUT '0',  
                                          INPUT 'report',                                       
                                          OUTPUT opcError,
                                          OUTPUT opiStatusCode,
                                          OUTPUT TABLE ttSalesRepLocation).
       MESSAGE 'opcError ' opcError 
       VIEW-AS ALERT-BOX.*/                                          
    END CONSTRUCTOR.
    
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC LocationMgmt (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
  END CONSTRUCTOR.
  /*----------------------------------------------------------------------------------
   Purpose: This method return the locations of salesman assigned under a supervisor
            who has logged in here.
            
   Notes: ipcDetailType - Used to tell, whether it is live report or historical report
  ------------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID getSalesmanLocations(INPUT ipcSupervisorID AS CHARACTER,
                                          INPUT ipiNumberOfDays AS INTEGER, 
                                          INPUT ipcLangID       AS CHARACTER,  
                                          INPUT ipcDetailType   AS CHARACTER,                                       
                                          OUTPUT opcError       AS CHARACTER,
                                          OUTPUT opiStatusCode  AS INTEGER,
                                          OUTPUT TABLE ttSalesRepLocation):
                                          
    DEFINE VARIABLE objCommonSrc        AS CLASS CommonSource NO-UNDO. 
    DEFINE VARIABLE cError              AS CHARACTER          NO-UNDO.
    DEFINE VARIABLE i64CheckInTimestmp  AS INT64              NO-UNDO.
    DEFINE VARIABLE dtLastXXDate        AS DATETIME           NO-UNDO.
    DEFINE VARIABLE dtzStartTime        AS DATETIME           NO-UNDO INIT "01-01-1970 00:00:00":U.
    DEFINE VARIABLE lSlsmnLiveDataExist AS LOGICAL            NO-UNDO. 
    
    ASSIGN objCommonSrc = NEW CommonSource(INPUT cToken)
           dtLastXXDate = DATETIME(TODAY - ipiNumberOfDays).
    
    ASSIGN i64CheckInTimestmp = INTERVAL(dtLastXXDate , dtzStartTime, "milliseconds":U).                                                    
                                           
    FOR EACH CSAMS NO-LOCK WHERE CSAMS.SUPERVISOR EQ ipcSupervisorID:
      
      populateLocationBlk:
      FOR EACH LocationMgmt NO-LOCK 
         WHERE LocationMgmt.Sales-Rep-Id EQ CSAMS.SALES-REP-ID 
           AND LocationMgmt.CheckInTime  GE i64CheckInTimestmp
            BY LocationMgmt.CheckInTime  DESCENDING: 
           
           IF NOT CAN-FIND(FIRST ttSalesRepLocation WHERE 
                                 ttSalesRepLocation.check_in_time EQ LocationMgmt.CheckInTime) THEN 
           DO:
             CREATE ttSalesRepLocation.
             ASSIGN 
               ttSalesRepLocation.sales_rep_id   = LocationMgmt.Sales-Rep-Id
               ttSalesRepLocation.sales-rep-name = CSAMS.SALES-NAME
               ttSalesRepLocation.check_in_time  = LocationMgmt.CheckInTime
               ttSalesRepLocation.check_out_time = LocationMgmt.CheckoutTime
               ttSalesRepLocation.longitude      = LocationMgmt.Longitude
               ttSalesRepLocation.Latitude       = LocationMgmt.Latitude NO-ERROR.
               lSlsmnLiveDataExist               = TRUE.
             
             IF ERROR-STATUS:ERROR THEN 
             DO:
               ASSIGN cError = ERROR-STATUS:GET-MESSAGE(1). 
               IF cError NE "":U THEN 
                 UNDO, THROW NEW AppError(cError,1).
             END. /* IF ERROR-STATUS:ERROR THEN */
              
           END. /* IF NOT CAN-FIND(FIRST ttSalesRepLocation  */
           
           IF ipcDetailType EQ "Live":U THEN  
             LEAVE populateLocationBlk.
      
      END. /* FOR EACH LocationMgmt  */

    END. /* FOR EACH CSAMS */
    
    IF NOT lSlsmnLiveDataExist THEN 
    DO:
        /* Get multilingual message when no live tracking record is found */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200NoLiveTrackingRec,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
            
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
    END. /* IF NOT lSlsmnLiveDataExist */
    
    CATCH errorObj AS AppError:
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.

  END METHOD.
  
  /*-------------------------------------------------------------------------------------
   Purpose: This method updates the location of customer as well as creates locationMgmt 
            records as well.
            
   Notes: 1. ipiMode - Represents the mode of operation; check-in(0), check-out(1)
  ---------------------------------------------------------------------------------------*/
  
    METHOD PUBLIC VOID slsmanCheckInCheckout(INPUT ipcSalesRepID   AS CHARACTER,
                                             INPUT ipcCustNumber   AS CHARACTER,
                                             INPUT ipcShipNumber   AS CHARACTER,
                                             INPUT ipcLattitude    AS CHARACTER,
                                             INPUT ipcLongitude    AS CHARACTER,
                                             INPUT ipcLangID       AS CHARACTER,
                                             INPUT ipcCheckInTime  AS INT64,
                                             INPUT ipcCheckOutTime AS INT64,
                                             INPUT ipiMode         AS INTEGER,
                                             OUTPUT opcError       AS CHARACTER,
                                             OUTPUT opiStatusCode  AS INTEGER):
                                               
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource NO-UNDO.                                              
    
    DEFINE VARIABLE cError       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cLatitude    AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cLongitude   AS CHARACTER NO-UNDO.
    
    objCommonSrc = NEW CommonSource(INPUT cToken).
/*    MESSAGE "ipcSalesRepID="  ipcSalesRepID SKIP "ipcCustNumber=" ipcCustNumber SKIP "ipcShipNumber=" ipcShipNumber*/
/*    SKIP "ipcLattitude=" ipcLattitude SKIP "ipcLongitude=" ipcLongitude SKIP "ipcLangID=" ipcLangID skip           */
/*    "ipcCheckInTime=" ipcCheckInTime SKIP "ipcCheckOutTime=" ipcCheckOutTime                                       */
/*                                                                                                                   */
/*    VIEW-AS ALERT-BOX.                                                                                             */
    CASE ipiMode:
        WHEN 0 THEN
        DO:
          
           FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber AND CCSMS.SALES-REP-ID EQ ipcSalesRepID EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
           IF AVAILABLE CCSMS  THEN
           DO:
            
             IF (CCSMS.Latitude  EQ "" OR CCSMS.Latitude  EQ ?)   OR
                (CCSMS.Longitude EQ "" OR CCSMS.Longitude EQ ?)   THEN
                
               ASSIGN CCSMS.Latitude  = IF ipcLattitude EQ "0" THEN "" ELSE ipcLattitude
                      CCSMS.Longitude = IF ipcLongitude EQ "0" THEN "" ELSE ipcLongitude.
                    
             FIND CURRENT CCSMS NO-LOCK.
             ASSIGN cLatitude  = CCSMS.Latitude
                    cLongitude = CCSMS.Longitude.    
                    
           END. /* IF AVAILABLE CCSMS THEN */
           
           ELSE IF LOCKED CCSMS THEN
           DO:
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200ErrorOccured,                                                              
                                       OUTPUT opcError,
                                       OUTPUT opiStatusCode).
        
              IF opcError NE "":U THEN 
                UNDO,THROW NEW AppError(opcError,1).
           END. /* ELSE IF LOCKED CCSMS */
           
           FIND SHPTO WHERE SHPTO.CUST-NUMBER EQ ipcCustNumber AND SHPTO.SHIP-NUMBER EQ ipcShipNumber EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
           IF AVAILABLE SHPTO THEN
           DO:
             IF (SHPTO.Latitude  EQ "" OR SHPTO.Latitude  EQ ?) OR
                (SHPTO.Longitude EQ "" OR SHPTO.Longitude EQ ?) THEN
                
               ASSIGN SHPTO.Latitude  = ipcLattitude
                      SHPTO.Longitude = ipcLongitude.
             
             FIND CURRENT SHPTO NO-LOCK.
             ASSIGN cLatitude  = SHPTO.Latitude
                    cLongitude = SHPTO.Longitude. 
                           
           END. /* IF AVAILABLE SHPTO */
           
           ELSE IF LOCKED SHPTO THEN
           DO:
              objCommonSrc:getMessages(INPUT  ipcLangID,
                                       INPUT  ConstantInitializer:c200ErrorOccured,                                                              
                                       OUTPUT opcError,
                                       OUTPUT opiStatusCode).
        
              IF opcError NE "":U THEN 
                UNDO,THROW NEW AppError(opcError,1).
                               
           END. /* ELSE IF LOCKED SHPTO THEN */
           
           FIND LOCATIONMGMT WHERE LOCATIONMGMT.CUST-NUMBER  EQ ipcCustNumber 
                               AND LOCATIONMGMT.SALES-REP-ID EQ ipcSalesRepID
                               AND LOCATIONMGMT.LOCATION-ID  EQ ipcShipNumber  
                               AND LOCATIONMGMT.CheckInTime  EQ ipcCheckInTime NO-LOCK NO-ERROR.
                               
           IF NOT AVAILABLE LOCATIONMGMT THEN
           DO:                              
               CREATE LOCATIONMGMT.
               ASSIGN LOCATIONMGMT.CUST-NUMBER  = ipcCustNumber
                      LOCATIONMGMT.SALES-REP-ID = ipcSalesRepID
                      LOCATIONMGMT.LOCATION-ID  = ipcShipNumber
                      LOCATIONMGMT.CheckInTIme  = ipcCheckInTime
                      LOCATIONMGMT.Longitude    = ipcLongitude
                      LOCATIONMGMT.Latitude     = ipcLattitude. 
                      MESSAGE "create".
                      
           END. /* IF NOT AVAILABLE LOCATIONMGMT */
           
           ELSE
           DO:
               objCommonSrc:getMessages(INPUT  ipcLangID,
                                        INPUT  ConstantInitializer:c200AlrdyChckIn,                                                              
                                        OUTPUT opcError,
                                        OUTPUT opiStatusCode).
        
              IF opcError NE "":U THEN 
                UNDO,THROW NEW AppError(opcError,1).
                
           END. /* ELSE - IF NOT AVAILABLE LOCATIONMGMT */
           
        END. /* WHEN 0 THEN */
         
        WHEN 1 THEN
        DO:
          FIND LAST LOCATIONMGMT WHERE LOCATIONMGMT.CUST-NUMBER  EQ ipcCustNumber 
                                   AND LOCATIONMGMT.SALES-REP-ID EQ ipcSalesRepID
                                   AND LOCATIONMGMT.LOCATION-ID  EQ ipcShipNumber EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
                              
          IF NOT AVAILABLE LOCATIONMGMT /*OR 
             LOCATIONMGMT.CheckInTime GE ipcCheckOutTime*/ THEN
          DO:
               IF LOCKED LOCATIONMGMT THEN
               DO:
                  objCommonSrc:getMessages(INPUT  ipcLangID,
                                           INPUT  ConstantInitializer:c200ErrorOccured,                                                              
                                           OUTPUT opcError,
                                           OUTPUT opiStatusCode).
            
                  IF opcError NE "":U THEN 
                    UNDO,THROW NEW AppError(opcError,1).
               END.
               
               objCommonSrc:getMessages(INPUT  ipcLangID,
                                        INPUT  ConstantInitializer:c200ChckInFirst,                                                              
                                        OUTPUT opcError,
                                        OUTPUT opiStatusCode).
        
               IF opcError NE "":U THEN 
                UNDO,THROW NEW AppError(opcError,1).
              
          END. /* IF NOT AVAILABLE LOCATIONMGMT */
          
          ASSIGN LOCATIONMGMT.CheckoutTime = ipcCheckOutTime.
          MESSAGE LOCATIONMGMT.CheckoutTime.
                               
        END. /* WHEN 1 THEN */
        
    END CASE. /* CASE ipiMode */
    
    CATCH errorObj AS AppError:           
      ASSIGN 
       opcError = errorObj:GetMessage(1).   
    END CATCH.
           
    END METHOD.        
    
    METHOD PUBLIC VOID SetCustomerLangLat(INPUT ipcSalesRepID   AS CHARACTER,
                                          INPUT ipcCustNumber   AS CHARACTER,
                                          INPUT ipcLattitude    AS DECIMAL,
                                          INPUT ipcLongitude    AS DECIMAL
                                          ):
                                                   
         FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
         IF AVAILABLE CCSMS  THEN
         DO:
            IF (CCSMS.Latitude  EQ "" OR CCSMS.Latitude  EQ ? )   OR
               (CCSMS.Longitude EQ "" OR CCSMS.Longitude EQ ?  )   THEN
                
               ASSIGN CCSMS.Latitude  = IF ipcLattitude EQ 0 THEN "" ELSE STRING(ipcLattitude)
                      CCSMS.Longitude = IF ipcLongitude = 0 THEN "" ELSE  STRING(ipcLongitude).
                    
                 
                    
         END. /* IF AVAILABLE CCSMS THEN */                                      
   END.                                                 
END CLASS.