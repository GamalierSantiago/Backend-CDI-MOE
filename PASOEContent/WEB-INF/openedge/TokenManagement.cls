 /*----------------------------------------------------------------------------
   File        : TokenManagement
   Purpose     : This file is the master file for Generating, Renewing & 
                 Expiring the session or token
   Syntax      : 
   Description : 
   Author(s)   : JKTECH
   Created     : Friday September 11 13:47:21 IST 2017
   Notes       : Version 1.1
   History     :
   ----------------------------------------------------------------------------
   Date(MM-DD-YY)       Author          Initial(XX-Version)    Description
                                                   
   ----------------------------------------------------------------------------         
 ------------------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS TokenManagement: 
   
  DEFINE PRIVATE VARIABLE iTokenTimeout AS INTEGER   NO-UNDO INIT  1800.
  DEFINE PRIVATE VARIABLE cError        AS CHARACTER NO-UNDO.
  
  /*------------------------------------------------------------------------------
   Purpose: This class handles / manages token for an user.
   Notes:
  ------------------------------------------------------------------------------*/
  CONSTRUCTOR PUBLIC TokenManagement ( ):
				
  END CONSTRUCTOR.
  
   DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
   
  CONSTRUCTOR PUBLIC TokenManagement (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
    
    FIND FIRST token WHERE Token.Token EQ ipcToken NO-LOCK NO-ERROR.
    IF AVAILABLE token THEN 
      RUN initiate-cdi-erp-var(INPUT Token.Company-ID).
  END CONSTRUCTOR.
  
  /*------------------------------------------------------------------------------
   Purpose:This method expires a token and returns status messages.
   Input Parameters: 1.ipcToken  - User's token.
                     2.ipcLangID - User's Language ID
   
   Output Parameters:1.opcStatus     - Expired token status(success if token is
                                       successfully expired),
                     2.opcMessage    - messages contains token info.
                     3.opiStatusCode - HTTP status code
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID expireToken(INPUT  ipcToken      AS CHARACTER, 
                                 INPUT  ipcLangID     AS CHARACTER,
                                 OUTPUT opcStatus     AS CHARACTER, 
                                 OUTPUT opcMessage    AS CHARACTER,
                                 OUTPUT opiStatusCode AS INTEGER):
                                     
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource.                                
                                     
	  objCommonSrc = NEW CommonSource(INPUT cToken).
            
    FIND Token WHERE Token.Token EQ ipcToken NO-LOCK NO-ERROR.
        
    IF AVAILABLE TOKEN THEN 
    DO:
      IF Token.SessionActive THEN  
      DO: 
        FIND CURRENT token EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF AVAILABLE token  THEN 
        DO:  
          ASSIGN 
            Token.SessionActive   = NO
            Token.Last-Updated-On = DATETIME(TODAY,MTIME)
            opcStatus             = "Success":U 
            opiStatusCode         = 200.
        END. /* IF AVAILABLE token */
	
        RELEASE token.  
      END. /* IF Token.SessionActive.. */
           
      ELSE
      DO:
        /* provides message in selected language when user's session is already expired */
        message "ExpireToken method @78".  
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200SessionExpired,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
         
      END. /* ELSE- IF Token.SessionActive */
           
    END. /* IF AVAILABLE TOKEN .. */	                
        
    ELSE 
    DO:
       /* provides message when token is not valid */ 
       
       objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c403InvalidToken,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
        
       IF cError NE "":U THEN 
         UNDO,THROW NEW AppError(cError,1).
    END. /* ELSE - IF AVAILABLE TOKEN*/
  
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcMessage = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
    END FINALLY.   
	    
  END METHOD.

  
  /*------------------------------------------------------------------------------------
   Purpose: This method generates the token for the particular session.
   Input Parameters: 1.ipcUserID     - Username / User ID of a salesperson (Sales-rep-id)
                     2.ipcLangID     - language ID that user selected
                     3.ipcDeviceID   - device ID in case of mobile user 
                                       (Will be used for push notification)
                     4.ipcUserType   - either mobile user or web user
                     5.ipcCompanyID  - compnany ID selected by user
                     
   Output Parameters:1.opcAppToken   - Generated token for the user
                     2.opcStatus     - success if any token is generated otherwise 
                                       failure
                     3.opcMessage    - message contains token information.
                     4.opiStatusCode - HTTP status code.
   Notes:
  ------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID generateToken(INPUT  ipcUserID     AS CHARACTER, 
                                   INPUT  ipcLangID     AS CHARACTER,
                                   INPUT  ipcDeviceID   AS CHARACTER,
                                   INPUT  ipcUserType   AS CHARACTER,
                                   INPUT  ipcCompanyID  AS CHARACTER,
                                   OUTPUT opcAppToken   AS CHARACTER,                                     
                                   OUTPUT opcStatus     AS CHARACTER,
                                   OUTPUT opcMessage    AS CHARACTER,
                                   OUTPUT opiStatusCode AS INTEGER):
                                            
    DEFINE VARIABLE cToken       AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE cTimeStamp   AS CHARACTER  NO-UNDO.
    
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource.                                
                                     
    objCommonSrc = NEW CommonSource(INPUT cToken).
    
    /*Generate encoded token and update the timestamp when it was generated*/   
    ASSIGN 
      cToken     = ENCODE(ipcUserID + STRING(RANDOM(1000,16000)) + STRING(MTIME))
      cTimeStamp = STRING(DATETIME(TODAY, MTIME)).
         
    IF CAN-FIND( FIRST Token WHERE Token.Token EQ cToken NO-LOCK) THEN
    DO:
      /* provides message in selected language when generated token already exist */  
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c500UnknownError,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).
    END. /* IF CAN-FIND( FIRST Token.. */
    
    ELSE
    DO:                                 
      CREATE Token. 
      ASSIGN 
        Token.Company-ID      = ipcCompanyID
        Token.User-ID         = ipcUserID 
        Token.Device-ID       = ipcDeviceID
        Token.language-ID     = ipcLangID
        Token.User-Type       = ipcUserType               
        Token.Token           = cToken /*Encoded token*/
        Token.Created-On      = DATETIME(cTimeStamp) 
        Token.Last-Updated-On = DATETIME(cTimeStamp) 
        Token.SessionActive   = YES NO-ERROR.
                
      IF NOT ERROR-STATUS:ERROR THEN
        ASSIGN 
          opiStatusCode = 200
          opcStatus     = "Success":U 
          opcAppToken   = cToken NO-ERROR.  
                                                             
    END. /* ELSE OF CAN-FIND( FIRST Token.. */	

    CATCH errorObj AS AppError:           
      ASSIGN 
        opcMessage = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
    END FINALLY.
    	
  END METHOD.
  
  /*----------------------------------------------------------------------------------
   Purpose:In case of mobile user, it renews and updates the token of a logged-in user,
           if mobuser exceeds the time-out interval. In case of web user, it returns
           message "Your session has been expired" if webuser exceeds time-out interval. 
   
   Input Parameters: 1.ipcToken  - User-token
                     2.ipcUserId - Sales-rep-id
                     3.ipcLangID - languageID
                     
   Output Parameters:1.outMessage    - message contains token information
                     2.outStatus     - Success / failure 
                     3.outApp_Token  - updated token (if created)
                     4.opiStatusCode - HTTP status code
           
   Notes:
  -------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID loggedInUserTokenRenew(INPUT  ipcToken      AS CHARACTER,
                                            INPUT  ipcUserId     AS CHARACTER,                                         
                                            INPUT  ipcLangID     AS CHARACTER, 
                                            OUTPUT outMessage    AS CHARACTER,
                                            OUTPUT outStatus     AS CHARACTER,
                                            OUTPUT outApp_Token  AS CHARACTER,
                                            OUTPUT opiStatusCode AS INTEGER):
    
    DEFINE VARIABLE objTokenMgmt AS CLASS TokenManagement NO-UNDO.
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource    NO-UNDO.
    
    DEFINE VARIABLE opcSessionTimeout AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE cCompany          AS CHARACTER  NO-UNDO.
    
    ASSIGN objTokenMgmt = NEW TokenManagement(INPUT cToken)
           objCommonSrc = NEW CommonSource(INPUT cToken). 
    
    DO ON ERROR UNDO,THROW:
        
        ASSIGN outApp_Token = ipcToken.
            
        FIND FIRST Token WHERE Token.Token  EQ ipcToken NO-LOCK NO-ERROR.
        IF AVAILABLE Token THEN
        DO:
          ASSIGN cCompany = Token.Company-ID.  
        END.
       
        IF VALID-OBJECT(objCommonSrc) THEN DO:
          
          objCommonSrc:parameterFile(INPUT ConstantInitializer:cSessionTimeOut,
                                     INPUT  cCompany,
                                     INPUT  YES,
                                     OUTPUT opcSessionTimeout,
                                     OUTPUT cError) NO-ERROR.
                                  
          ASSIGN iTokenTimeout = INTEGER(opcSessionTimeout) NO-ERROR. 
          
          IF ERROR-STATUS:ERROR OR iTokenTimeout EQ 0  THEN
            ASSIGN iTokenTimeout = ConstantInitializer:iTokenTimeout NO-ERROR.
    
        END. /* IF VALID-OBJECT(objCommonSrc) THEN */
        
        FIND FIRST Token WHERE Token.Token  EQ ipcToken NO-LOCK NO-ERROR.
        IF AVAILABLE Token THEN
        DO:
          IF Token.User-ID NE ipcUserId THEN
          DO:
            /* provides message in selected language when token mismatches with the user */
           
            objCommonSrc:getMessages(INPUT  ipcLangID,
                                     INPUT  ConstantInitializer:c403MisMatchUserToken,                                                              
                                     OUTPUT cError,
                                     OUTPUT opiStatusCode).
        
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).  
                   
          END. /*IF Token.User-ID NE ipcUserId*/
            
          IF Token.SessionActive THEN 
          DO:
            /*Check whether token's timeout condition is reached or not*/
            IF INTERVAL(DATETIME(TODAY, MTIME), Token.Last-Updated-On, 'seconds':U) LE iTokenTimeout THEN
            DO:
              //FIND CURRENT Token EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
              FIND FIRST Token WHERE Token.Token  EQ ipcToken EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
                            
              IF AVAILABLE token THEN
              DO: 
                  
                ASSIGN 
                  Token.Last-Updated-On = DATETIME(TODAY, MTIME)
                  outApp_Token          = Token.Token
                  opiStatusCode         = 200
                  outStatus             = "Success":U NO-ERROR.
                
                /*If user has changed it's language in between then update it's selected language in token table*/                            
                IF (TRIM(ipcLangID) NE "":U AND TRIM(ipcLangID) NE ?) AND Token.language-ID NE TRIM(ipcLangID) THEN
                  ASSIGN Token.language-ID = ipcLangID.
                
              END. /*  IF AVAILABLE token */
              
              IF LOCKED(TOKEN) THEN /* Due to quick calls to API at interval of 1 second, code is going into the lock stage */
              DO:
                  Assign outApp_Token          = ipcToken
                         opiStatusCode         = 200
                         outStatus             = "Success":U NO-ERROR. 
              END.
              RELEASE Token.
              
            END. /*IF INTERVAL(DATETIME(TODAY, MTIME)*/     
          
            /*When user has exceeded the time out interval i.e. 30 mins*/
            ELSE
            DO:
                
              FIND FIRST Token WHERE Token.Token  EQ ipcToken EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
              IF AVAILABLE Token THEN
              DO:                                           
                ASSIGN 
                  Token.SessionActive   = NO
                  Token.Last-Updated-On = DATETIME(TODAY, MTIME).
                                  
                IF Token.User-Type EQ ConstantInitializer:cWebUser THEN
                DO: 
                  /* provides message in selected language when user's session expired */
                  
                  objCommonSrc:getMessages(INPUT  ipcLangID,
                                           INPUT  ConstantInitializer:c200SessionExpired,                                                              
                                           OUTPUT cError,
                                           OUTPUT opiStatusCode).
                                           
                  ASSIGN opiStatusCode = 200
                         outStatus     = "Failure":U.
                  
                  IF cError NE "":U THEN 
                    UNDO,THROW NEW AppError(cError,1).       
                   
                END. /* IF Token.User-Type EQ ConstantInitializer:cWebUser */
            
                
                /*If user is mobile user then regenerate the token*/
                IF Token.User-Type EQ ConstantInitializer:cMobileUser THEN
                DO:
                  THIS-OBJECT:generateToken(INPUT  Token.User-ID,
                                            INPUT  Token.language-ID,
                                            INPUT  Token.Device-ID,
                                            INPUT  Token.User-Type,
                                            INPUT  Token.Company-ID, 
                                            OUTPUT outApp_Token, 
                                            OUTPUT outStatus, 
                                            OUTPUT outMessage,
                                            OUTPUT opiStatusCode).
                                            
                  ASSIGN 
                    opiStatusCode = 200
                    outStatus     = "Success":U NO-ERROR.
                              
                END. /* IF Token.User-Type EQ ConstantInitializer:cMobileUser THEN.. */
             
              END.  /* IF AVAILABLE Token.. */
                  
              RELEASE Token.
              
            END. /* ELSE */
          END. /* IF Token.SessionActive.. */
          
          ELSE 
          DO:
            /* provides message in selected language when user's session is already expired */
            
            objCommonSrc:getMessages(INPUT  ipcLangID,
                                     INPUT  ConstantInitializer:c200SessionExpired,                                                              
                                     OUTPUT cError,
                                     OUTPUT opiStatusCode).
        
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1). 
          END. 
                               
        END.  /* IF AVAILABLE Token  */
        
        ELSE 
        DO:
          
          /* provides message when user's token is invalid */  
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c403InvalidToken,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /*ELSE - IF AVAILABLE Token*/
              
    END. /* DO ON ERROR UNDO,THROW */  
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        outMessage =  errorObj:GetMessage(1).       
    END CATCH.
        
  END METHOD.

END CLASS.
