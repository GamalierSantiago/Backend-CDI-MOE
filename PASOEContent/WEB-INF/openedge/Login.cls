/*-------------------------------------------------------------------------------------
   File        : Login
   Purpose     : To validate username and password. 
   Syntax      : 
   Description : 
   Author(s)   : JKTECH
   Created     : Fri September 15 12:09:49 IST 2017
   Notes       : Version 1.1
   History     :  
   ------------------------------------------------------------------------------------
   Date(MM-DD-YY)            Author                Initial(XX-Version)    Description
                                                   
  ------------------------------------------------------------------------------------- 
  -------------------------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Login: 
  /*----------------------------------------------------------------------------------------------------
   Purpose: Login class will provide all the functionalities which are used to successfully login 
            the valid user.Here user is authenticated first and if the user is valid then the session
            is managed for that user until/unless the user would have been logged out from the application.
   Notes:
  ------------------------------------------------------------------------------------------------------*/
          
  DEFINE PRIVATE VARIABLE cError AS CHARACTER NO-UNDO.
           
  CONSTRUCTOR PUBLIC Login ():

  END CONSTRUCTOR.
  
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC Login (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
  END CONSTRUCTOR.  
  /*------------------------------------------------------------------------------
   Purpose: This method is used to change the old password of the user when the 
            user forgets the password.
   Parameters:     
   Notes:
  ------------------------------------------------------------------------------*/
  /*METHOD PUBLIC VOID forgotPassword(INPUT ipcCustID AS CHARACTER, 
                                      OUTPUT oplSuccess AS LOGICAL,
                                      OUTPUT opcError AS CHARACTER):
		
    /* OTP is generated and stored in the Database.Also it will be sended to the user's email.
       When OTP is verified then the user's new password, replaces the old password in the DB. */ 
   
    CATCH errorObj AS Error:
      opcError = errorObj:GetMessage(1).
    END CATCH.

  END METHOD.*/
  
  
  /*-----------------------------------------------------------------------------------
   Purpose: This method authenticates the user and also returns the error message 
            if any error exist.
   Input Parameters: 1.ipcUserName  - Username of the Salesperson,
                     2.ipcPassword  - valid password for that user,
                     3.ipcDeviceID  - device id (in case of mobile user),
                     4.ipcLangID    - language id in which user wants to use app,
                     5.ipcCompanyID - company id to which an user logged in.
                     
   Output Parameters:1.opcToken         - token details for which a user needs to 
                                          be validated.
                     2.opcMessage       - user specific message if any.
                     3.oplLoginStatus   - login status as Yes - Active,
                                                          No  - Inactive.
                     4.opiStatusCode    - Http Status code.                                      
   Notes:
  --------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID validateSalesperson(INPUT  ipcUserName       AS CHARACTER,
                                         INPUT  ipcPassword       AS CHARACTER,
                                         INPUT  ipcDeviceID       AS CHARACTER,
                                         INPUT  ipcLangID         AS CHARACTER,
                                         INPUT  ipcUserType       AS CHARACTER,
                                         INPUT  ipcCompanyID      AS CHARACTER,  
                                         OUTPUT opcToken          AS CHARACTER,
                                         OUTPUT opcMessage        AS CHARACTER,
                                         OUTPUT oplLoginStatus    AS LOGICAL,
                                         OUTPUT opiStatusCode     AS INTEGER):
    
    DEFINE VARIABLE cAppToken     AS CHARACTER NO-UNDO. 
    DEFINE VARIABLE cTokenStatus  AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource    NO-UNDO.
    DEFINE VARIABLE objToken     AS CLASS TokenManagement NO-UNDO. 
    
    ASSIGN objToken     = NEW TokenManagement(INPUT cToken)
           objCommonSrc = NEW CommonSource(INPUT cToken).
                               
    /* First Login Approach starts */       
    IF ipcUserType EQ "":U AND TRIM(ipcUserType) EQ ? THEN
    DO:
      /* provides message in selected language when user-type is blank */  
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200UserTypeBlank,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
       IF cError NE "":U THEN 
         UNDO,THROW NEW AppError(cError,1).
    END.
    
    ELSE 
    DO:
      IF ipcUserType NE ConstantInitializer:cMobileuser THEN
      DO:
        /* provides message in selected language when user-type is invalid */  
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvalidUserType,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF ipcUserType NE ConstantInitializer:cMobileuser THEN */
            
      /*Usertype is Mobile user*/
      ELSE 
      DO:
        IF NOT CAN-FIND(FIRST CSAMS WHERE CSAMS.sales-rep-id EQ ipcUserName 
                                      AND (CSAMS.Password    EQ ipcPassword OR CSAMS.Password EQ ENCODE(ipcPassword) ) ) THEN 
        DO:
          /* provides message in selected language when username or password is invalid */ 
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200InvalidUserPaswd,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).                
        END.  
                 
        IF TRIM(ipcDeviceID) EQ "":U OR TRIM(ipcDeviceID) EQ ? THEN
        DO:
          /* provides message in selected language when user-type is mobileuser and device-id is blank */  
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200DeviceidBlank,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
            
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /* IF TRIM(ipcDeviceID) EQ "":U OR TRIM(ipcDeviceID) EQ ? THEN */
      
        /*
          If a user is already logged in mobile then the user will not be allowed to login again from  
          different mobile until the user log's out from the mobile in which he/she is currently logged-in.
        */  
    
        FOR FIRST Token WHERE Token.User-ID   EQ ipcUserName 
                          AND Token.User-Type EQ ConstantInitializer:cMobileUser 
                          AND Token.SessionActive NO-LOCK:
                            
          IF ipcDeviceID EQ Token.Device-ID THEN
          DO: 
            FIND CURRENT Token EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
            IF AVAILABLE Token THEN
            DO:                                           
              ASSIGN 
                Token.SessionActive   = NO
                Token.Last-Updated-On = DATETIME(TODAY, MTIME).
                
                RELEASE Token.
            END. /* IF AVAILABLE Token THEN */  
                                
          END. /* IF ipcDeviceID EQ Token.Device-ID THEN */
          
          ELSE
          DO: 
              /* Kill previous session of user and create new . DELETE THIS AFTER THE DEVELOPMENT */
              FIND CURRENT Token EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
              IF AVAILABLE Token THEN 
              do: 
                delete Token.
                release token.
                cError = "".
              end.  
            /* provides message in case of multiple mobile login  */    
            
            /* UNCOMMENT IT AFTER DEVELOPMENT COMPLETE */
            
          /*   objCommonSrc:getMessages(INPUT  ipcLangID,
                                     INPUT  ConstantInitializer:c200MobMultiLogin,                                                              
                                     OUTPUT cError,
                                     OUTPUT opiStatusCode).
        
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).     */
            
          END. /* ELSE OF IF ipcDeviceID EQ Token.Device-ID THEN         */
                 
        END. /*  FOR FIRST Token WHERE..                               */
      
      END. /* ELSE part when Usertype is Mobile user                 */
      
    END. /* ELSE OF ipcUserType EQ "":U AND TRIM(ipcUserType) EQ ? */   
   
                
    IF cError EQ "":U THEN 
    DO:       
   /*   FIND CSAMS WHERE CSAMS.sales-rep-id EQ ipcUserName AND CSAMS.Password EQ ipcPassword NO-LOCK NO-ERROR.
      
      IF AVAILABLE CSAMS THEN
      DO:
        IF CSAMS.cust-number NE "" THEN
        DO:
           /* return message when customer tries to login in mobile */    
          /* objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  "User not allowed to login in mobile":U,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode). */
                                    
           cError = "User not allowed to login in mobile".
                   
           IF cError NE "":U THEN 
             UNDO,THROW NEW AppError(cError,1).    
        END. */
                               
        /* This method generates token for a valid logged in user  */          
        objToken:generateToken(INPUT  ipcUserName,
                               INPUT  ipcLangID,
                               INPUT  ipcDeviceID,
                               INPUT  ipcUserType,
                               INPUT  ipcCompanyID, 
                               OUTPUT cAppToken,                                     
                               OUTPUT cTokenStatus,
                               OUTPUT opcMessage,
                               OUTPUT opiStatusCode).
        
         IF cTokenStatus EQ ConstantInitializer:cSuccess THEN                        
           ASSIGN oplLoginStatus = TRUE
                  opcToken       = cAppToken. 
                                    
           /* a session will be created page will be redirected after successful login */
                     
   /*   END. /* IF AVAILABLE CSAMS THEN */ */ 
                   
    END. /* IF cError EQ "":U THEN  */
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcMessage = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      IF VALID-OBJECT(objToken) THEN  
        DELETE OBJECT objToken.
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
    END FINALLY.
                                               
  END METHOD.
  
    /*-----------------------------------------------------------------------------------
   Purpose: This method authenticates the user and also returns the error message 
            if any error exist.
   Input Parameters: 1.ipcCustID  -   Customer user id,
                     2.ipcPassword  - valid password for that user,
                     3.ipcLangID    - language id in which user wants to use app,
                     5.ipcCompanyID - company id to which an user logged in.
                     
   Output Parameters:1.opcToken         - token details for which a user needs to 
                                          be validated.
                     2.opcMessage       - user specific message if any.

         
                     3.oplLoginStatus   - login status as Yes - Active,
                                                          No  - Inactive.
                     4.opiStatusCode    - Http Status code.                                      
   Notes:
  --------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID validateCustomer(INPUT  ipcCustID       AS CHARACTER,
                                      INPUT  ipcPassword       AS CHARACTER,
                                      INPUT  ipcLangID         AS CHARACTER,
                                      INPUT  ipcUserType       AS CHARACTER,
                                      INPUT  ipcCompanyID      AS CHARACTER,  
                                      OUTPUT opcToken          AS CHARACTER,
                                      OUTPUT opcMessage        AS CHARACTER,
                                      OUTPUT oplLoginStatus    AS LOGICAL,
                                      OUTPUT opiStatusCode     AS INTEGER):
    
    DEFINE VARIABLE cAppToken     AS CHARACTER NO-UNDO. 
    DEFINE VARIABLE cTokenStatus  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDeviceId     AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource    NO-UNDO.
    DEFINE VARIABLE objToken     AS CLASS TokenManagement NO-UNDO. 
    
    ASSIGN objToken     = NEW TokenManagement(INPUT cToken)
           objCommonSrc = NEW CommonSource(INPUT cToken).
                               
    /* First Login Approach starts */       
    IF ipcUserType EQ "":U AND TRIM(ipcUserType) EQ ? THEN
    DO:
      /* provides message in selected language when user-type is blank */  
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200UserTypeBlank,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
       IF cError NE "":U THEN 
         UNDO,THROW NEW AppError(cError,1).
    END.
    
    ELSE 
    DO:
      IF ipcUserType NE ConstantInitializer:cWebUser THEN
      DO:
        /* provides message in selected language when user-type is invalid */  
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvalidUserType,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF ipcUserType NE ConstantInitializer:cWebUser THEN */
      
      ELSE IF ipcUserType EQ ConstantInitializer:cWebUser THEN 
      DO: 
        IF NOT CAN-FIND(FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustID 
                                      AND (CCSMS.Password   EQ ipcPassword OR CCSMS.Password EQ ENCODE(ipcPassword)))
                                      THEN 

        DO:
          /* provides message in selected language when username or password is invalid */ 
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200InvalidUserPaswd,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).           
            
        END. /*IF NOT CAN-FIND(FIRST ccsms*/
                
      END. /* IF ipcUserType EQ "Webuser" THEN */
        
    END. /* ELSE OF ipcUserType EQ "":U AND TRIM(ipcUserType) EQ ? */   
    
   /*            
    IF NOT CAN-FIND(FIRST CSAMS WHERE 
      CSAMS.sales-rep-id EQ ipcCustID  AND
      CSAMS.Password     EQ ipcPassword) THEN 
    DO:
       /* provides message in selected language when username or password is invalid */ 
       objCommonSrc:getMessages(INPUT  ipcLangID,
                                INPUT  ConstantInitializer:c200InvalidUserPaswd,                                                              
                                OUTPUT cError,
                                OUTPUT opiStatusCode).
        
       IF cError NE "":U THEN 
         UNDO,THROW NEW AppError(cError,1).                
    END. 
       
    IF ipcUserType EQ "":U AND TRIM(ipcUserType) EQ ? THEN
    DO:
      /* provides message in selected language when user-type is blank */  
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200UserTypeBlank,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
       IF cError NE "":U THEN 
         UNDO,THROW NEW AppError(cError,1).
    END.
    ELSE
    DO:
      IF ipcUserType NE ConstantInitializer:cWebUser THEN
      DO:
        /* provides message in selected language when user-type is invalid */  
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvalidUserType,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF ipcUserType NE ConstantInitializer:cWebUser THEN */ 
         
    END. /* ELSE OF ipcUserType EQ "":U AND TRIM(ipcUserType) EQ ? */ */
                   
    IF cError EQ "":U THEN 
    DO:       
   /*   FIND CSAMS WHERE CSAMS.sales-rep-id EQ ipcCustID AND CSAMS.Password EQ ipcPassword NO-LOCK NO-ERROR.
      
      IF AVAILABLE CSAMS THEN
      DO:     
        IF CSAMS.cust-number EQ "" THEN
        DO:
           /* return message when salesperson tries to login in web application  */    
          /* objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  "User not allowed to login in web application":U,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode). */
           cError = "User not allowed to login in web application".
           
           IF cError NE "":U THEN 
             UNDO,THROW NEW AppError(cError,1).    
        END.  */ 
                        
        /* This method generates token for a valid logged in user  */          
        objToken:generateToken(INPUT  ipcCustID,
                               INPUT  ipcLangID,
                               INPUT  cDeviceId,
                               INPUT  ipcUserType,
                               INPUT  ipcCompanyID, 
                               OUTPUT cAppToken,                                     
                               OUTPUT cTokenStatus,
                               OUTPUT opcMessage,
                               OUTPUT opiStatusCode).
        
         IF cTokenStatus EQ ConstantInitializer:cSuccess THEN                        
           ASSIGN oplLoginStatus = TRUE
                  opcToken       = cAppToken. 
                                    
           /* a session will be created page will be redirected after successful login*/
                     
   /*   END. /* IF AVAILABLE CSAMS THEN */ */ 
                   
    END. /* IF cError EQ "":U THEN  */
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcMessage = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      IF VALID-OBJECT(objToken) THEN  
        DELETE OBJECT objToken.
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
    END FINALLY.
                                               
  END METHOD.
  
     /*-----------------------------------------------------------------------------------
   Purpose: This method authenticates the supervisor and also returns the error message 
            if any error exist.
   Input Parameters: 1.ipcSupervisorID  - Supervisor ID(CSAMS.Sales-Rep-Id, Laptop = NO),
                     2.ipcPassword  - valid password for that user,
                     3.ipcLangID    - language id in which user wants to use app,
                     5.ipcCompanyID - company id to which an user logged in.
                     
   Output Parameters:1.opcToken         - token details for which a user needs to 
                                          be validated.
                     2.opcMessage       - user specific message if any.

         
                     3.oplLoginStatus   - login status as Yes - Active,
                                                          No  - Inactive.
                     4.opiStatusCode    - Http Status code.                                      
   Notes:
  --------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID validateSupervisor(INPUT  ipcSupervisorID  AS CHARACTER,
                                        INPUT  ipcPassword      AS CHARACTER,
                                        INPUT  ipcLangID        AS CHARACTER,
                                        INPUT  ipcUserType      AS CHARACTER,
                                        INPUT  ipcCompanyID     AS CHARACTER,  
                                        OUTPUT opcToken         AS CHARACTER,
                                        OUTPUT opcMessage       AS CHARACTER,
                                        OUTPUT oplLoginStatus   AS LOGICAL,
                                        OUTPUT opiStatusCode    AS INTEGER):
    
    DEFINE VARIABLE cAppToken     AS CHARACTER NO-UNDO. 
    DEFINE VARIABLE cTokenStatus  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDeviceId     AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE objCommonSrc AS CLASS CommonSource    NO-UNDO.
    DEFINE VARIABLE objToken     AS CLASS TokenManagement NO-UNDO. 
    
    ASSIGN objToken     = NEW TokenManagement(INPUT cToken)
           objCommonSrc = NEW CommonSource(INPUT cToken).
                               
    /* First Login Approach starts */       
    IF ipcUserType EQ "":U AND TRIM(ipcUserType) EQ ? THEN
    DO:
      /* provides message in selected language when user-type is blank */  
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200UserTypeBlank,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
       IF cError NE "":U THEN 
         UNDO,THROW NEW AppError(cError,1).
    END.
    
    ELSE 
    DO:
      IF ipcUserType NE ConstantInitializer:cWebUser THEN
      DO:
        /* provides message in selected language when user-type is invalid */  
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvalidUserType,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
        
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      END. /* IF ipcUserType NE ConstantInitializer:cWebUser THEN */
      
      ELSE IF ipcUserType EQ ConstantInitializer:cWebUser THEN 
      DO: 
        IF NOT CAN-FIND(FIRST CSAMS WHERE CSAMS.SALES-REP-ID EQ ipcSupervisorID 
                                      AND (CSAMS.PASSWORD    EQ ipcPassword OR CSAMS.Password EQ ENCODE(ipcPassword) )
                                      AND  NOT CSAMS.LAPTOP) THEN 
                           
        DO:
          /* provides message in selected language when username or password is invalid */ 
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200InvalidUserPaswd,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
        
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).           
            
        END. /*IF NOT CAN-FIND(FIRST ccsms*/
                
      END. /* IF ipcUserType EQ "Webuser" THEN */
        
    END. /* ELSE OF ipcUserType EQ "":U AND TRIM(ipcUserType) EQ ? */   
                         
    IF cError EQ "":U THEN 
    DO:          
                        
        /* This method generates token for a valid logged in user  */          
        objToken:generateToken(INPUT  ipcSupervisorID,
                               INPUT  ipcLangID,
                               INPUT  cDeviceId,
                               INPUT  ipcUserType,
                               INPUT  ipcCompanyID, 
                               OUTPUT cAppToken,                                     
                               OUTPUT cTokenStatus,
                               OUTPUT opcMessage,
                               OUTPUT opiStatusCode).
        
         IF cTokenStatus EQ ConstantInitializer:cSuccess THEN                        
           ASSIGN oplLoginStatus = TRUE
                  opcToken       = cAppToken.                                               
                   
    END. /* IF cError EQ "":U THEN  */
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcMessage = errorObj:GetMessage(1).
    END CATCH.
    
    FINALLY:
      IF VALID-OBJECT(objToken) THEN  
        DELETE OBJECT objToken.
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
    END FINALLY.
                                               
  END METHOD.
  
END CLASS.