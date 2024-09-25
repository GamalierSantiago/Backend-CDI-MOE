 
 /*-----------------------------------------------------------------------------
    File        : UserCart
    Purpose     : 
    Syntax      : 
    Description : This class supports following functionalities of the shopping cart 
                  1. Fetching cart details
                  2. Creating cart records 
                  3. Removing an item from cart
                  4. Empty cart
    Author(s)   : JKTECH
    Created     : Tue Jan 23 12:25:44 IST 2018
    Notes       : Version 1.1
    History     :
    ----------------------------------------------------------------------------
    Date(MM-DD-YY)       Author          Initial(XX-Version)    Description
                                                   
    ----------------------------------------------------------------------------     
  ------------------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS UserCart: 
  /*------------------------------------------------------------------------------
    Purpose:
    Notes:
  ------------------------------------------------------------------------------*/
  
  /* Temp-Table For storing item details presented in the cart */
  DEFINE PRIVATE TEMP-TABLE ttCartProducts NO-UNDO
    FIELD item_number       AS CHARACTER
    FIELD description       AS CHARACTER
    FIELD quantity          AS DECIMAL
    FIELD unit_price        AS DECIMAL
    FIELD item_color        AS CHARACTER
    FIELD item_size         AS CHARACTER
    FIELD unique_id         AS CHARACTER.
    
  DEFINE VARIABLE cError                  AS CHARACTER  NO-UNDO.
  DEFINE VARIABLE lcUserType              AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lcdiscounted_meta_key   AS CHARACTER NO-UNDO.
  DEFINE VARIABLE lcdiscounted_meta_value AS CHARACTER NO-UNDO.
  DEFINE BUFFER bf-ttCartProducts FOR ttCartProducts.     
  DEFINE TEMP-TABLE tt-cartProducts LIKE ttCartProducts
        FIELD seq# AS INTEGER.
  DEFINE TEMP-TABLE tt-cartdetail NO-UNDO 
        FIELD item-number       AS CHARACTER 
        FIELD parentitem-number AS CHARACTER.
        
               
  CONSTRUCTOR PUBLIC UserCart (  ):
                  
  END CONSTRUCTOR.
  
   DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC UserCart (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
    FIND FIRST token WHERE Token.Token = ipcToken NO-LOCK NO-ERROR.
    IF AVAILABLE token THEN 
    ASSIGN lcUserType = Token.User-Type.
       
  END CONSTRUCTOR.
  
  
  /*------------------------------------------------------------------------------
   Purpose: This method creates the records of cartHeader and cartDetail which are 
            selected by user
               
   Input Parameters:
               1. ipcSalesRepId    - Sales Rep ID  
               2. ipcCustNumber    - Customer number  
               3. ipcOperationType - Operation performing on cart -- Add/modify/remove/empty             
               4. ipcLangID        - Language ID of the Logged-In user
               5. iplcCartData     - Array containing information related to products available in the cart
   
   Output Parameters:
               1. oplcCartUniqueIds - Stores the unique-id of all the item  
                                      records added in the cart of a customer
               2. opiStatusCode - HTTP Status code
               3. opcError      - Error occured (if any)
               
   Notes:              
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID performCartOperations(INPUT  ipcSalesRepId        AS CHARACTER,
                                           INPUT  ipcCustNumber        AS CHARACTER,
                                           INPUT  ipcOperationType     AS CHARACTER,                            
                                           INPUT  ipcLangID            AS CHARACTER,
                                           INPUT  TABLE              ttCartProducts,
                                           INPUT  ipiWareHouseNo       AS INTEGER, 
                                           OUTPUT oplcCartUniqueIds    AS LONGCHAR,                                    
                                           OUTPUT opiStatusCode        AS INTEGER,
                                           OUTPUT opcError             AS CHARACTER):
    
    //DEFINE VARIABLE lRetOK       AS LOGICAL                          NO-UNDO.
    DEFINE VARIABLE iNowTimeStamp  AS INT64                            NO-UNDO.
    DEFINE VARIABLE ipdQtyOnHand   AS DECIMAL                          NO-UNDO.
    DEFINE VARIABLE lByColor       AS LOGICAL                          NO-UNDO.
    DEFINE VARIABLE lBySize        AS LOGICAL                          NO-UNDO.
    DEFINE VARIABLE lAddItem       AS LOGICAL                          NO-UNDO.
    
    DEFINE VARIABLE recordIDArr    AS CLASS JsonArray                  NO-UNDO.
    DEFINE VARIABLE recordIDObj    AS CLASS JsonObject                 NO-UNDO.
    DEFINE VARIABLE objCommonSrc   AS CLASS CommonSource               NO-UNDO.
    DEFINE BUFFER bfcinv1 FOR cinv1.
    DEFINE VARIABLE licntr         AS INT                              NO-UNDO.
    DEFINE BUFFER bfCartDetail FOR CartDetail.
    
    ASSIGN objCommonSrc = NEW CommonSource(INPUT cToken)
           recordIDArr  = NEW JsonArray()
           recordIDObj  = NEW JsonObject().
        
    IF VALID-OBJECT(objCommonSrc) THEN 
    DO:
      ASSIGN iNowTimeStamp = objCommonSrc:getTimestamp(INPUT DATETIME-TZ(NOW),
                                                       INPUT ipcLangID,
                                                       OUTPUT cError,      
                                                       OUTPUT opiStatusCode).
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).                                                
    END. 
          
  /*  ASSIGN iplcCartData = REPLACE(iplcCartData, "\", "")
           lRetOK       = TEMP-TABLE ttCartProducts:READ-JSON("longchar", iplcCartData, "empty").*/
    FIND FIRST paramfl WHERE PARAMFL.PARAM-ID = "LEY172-FAMILY" 
                                AND PARAMFL.COMPANY-CODE = SUBSTRING(ipcCustNumber,1,1) 
                                AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.       
    FOR EACH ttCartProducts NO-LOCK:
       CREATE tt-CartProducts.
       BUFFER-COPY ttCartProducts TO tt-cartProducts NO-ERROR. 
       licntr = licntr + 1.
       tt-cartProducts.seq# = licntr.
        IF AVAILABLE paramfl  THEN 
        DO:
           FIND FIRST cinv1 WHERE cinv1.item-number = ttCartProducts.item_number  NO-LOCK NO-ERROR.
           
           
               
               IF AVAILABLE cinv1 AND INDEX(PARAMFL.PARAM-VALUE1, CINV1.FAMILY ) GT 0  THEN 
               DO:
                   FIND FIRST bfcinv1 WHERE bfcinv1.ITEM-NUMBER EQ  PARAMFL.PARAM-VALUE2 NO-LOCK NO-ERROR.
                   IF AVAILABLE bfcinv1 THEN 
                   DO:
                      licntr = licntr + 1. 
                      CREATE tt-CartProducts.
                      ASSIGN tt-CartProducts.item_number = ttCartProducts.item_number + "-LEY172" 
                             tt-CartProducts.description = bfcinv1.DESCRIPTION
                             tt-CartProducts.quantity    = ttCartProducts.quantity
                             tt-CartProducts.unit_price  = bfcinv1.ACCTING-COST
                             tt-cartProducts.seq#        = licntr.
                   END. 
               END.
       END.
       FIND FIRST sethd WHERE SETHD.SET-NO EQ ttCartProducts.item_number NO-LOCK NO-ERROR.
       
       IF AVAILABLE SETHD THEN
       DO:
           
           FOR EACH setdt WHERE SETDT.SET-NO EQ sethd.set-no NO-LOCK:
               
               licntr = licntr + 1. 
               FIND FIRST cinv1 WHERE cinv1.item-number = SETDT.ITEM-NUMBER  NO-LOCK NO-ERROR.
               CREATE tt-CartProducts.
               ASSIGN tt-CartProducts.item_number = ttCartProducts.item_number + "-KIT" + SETDT.ITEM-NUMBER 
                      tt-CartProducts.description = cinv1.description
                      tt-CartProducts.quantity    = ttCartProducts.quantity * SETDT.QTY
                      tt-CartProducts.unit_price  = 0
                      tt-cartProducts.seq#        = licntr.
                      
               CREATE tt-cartdetail.
               ASSIGN tt-cartdetail.item-number        = SETDT.ITEM-NUMBER
                      tt-cartdetail.parentitem-number  = ttCartProducts.item_number no-error.       
           END.    
       END.    
                                        
    END.  
    
    EMPTY TEMP-TABLE ttCartProducts.
    
     FOR EACH tt-CartProducts BY tt-cartProducts.seq# :
        
      CREATE ttCartProducts.
       BUFFER-COPY tt-CartProducts TO ttcartProducts NO-ERROR.   
    END. 
    /*
    OUTPUT TO "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\VariablesCondicionanFind.txt".
    DISPLAY ipcCustNumber.
    OUTPUT CLOSE. */
            
    FIND FIRST CartHeader WHERE CartHeader.Sales-Rep-ID EQ ipcSalesRepId
                            AND CartHeader.Cust-Number  EQ ipcCustNumber
                            AND CartHeader.Cart-Status  NO-LOCK NO-ERROR.
    IF NOT AVAILABLE CartHeader THEN
    DO:          
      CREATE CartHeader.
      ASSIGN CartHeader.Sales-Rep-ID = ipcSalesRepId
             CartHeader.Cust-Number  = ipcCustNumber
             CartHeader.Cart-Status  = TRUE
             CartHeader.Timestamp    = iNowTimeStamp.
     //ErrorBanner No entro a la creacion de CartHeader       
    /* OUTPUT TO "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\CreacionCartHeader.txt".
     DISPLAY "Entro al ASSIGN".
     OUTPUT CLOSE.  */       
                
    END. /* IF NOT AVAILABLE CartHeader THEN */
    
    //ErrorBanner
  /* OUTPUT TO "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\PasaPorAqui.txt".
     DISPLAY "Pase por aqui".
     OUTPUT CLOSE. 
    
    OUTPUT TO "C:\Users\bsantiago\Desktop\ErrorObjetosWebApp\Debug\CreaCartHeader.txt".
    FOR EACH CartHeader WHERE CartHeader.Cust-Number EQ ipcCustNumber NO-LOCK:
        DISPLAY CartHeader WITH 1 COL.
    END.    
    OUTPUT CLOSE. */  
    
      
    CASE ipcOperationType:  
            
      WHEN "a":U THEN
      DO:
        FOR EACH ttCartProducts:
                   
          IF lcUserType EQ "mobileuser"   THEN 
          DO:
              ASSIGN lcdiscounted_meta_key      = ""
                     lcdiscounted_meta_value    = "".
                     
              IF NUM-ENTRIES(ttCartProducts.item_color,"|") EQ 3 THEN
                ASSIGN lcdiscounted_meta_key      =  ENTRY(2,ttCartProducts.item_color,"|")
                       lcdiscounted_meta_value    =  ENTRY(3,ttCartProducts.item_color,"|")
                       ttCartProducts.item_color  =  ENTRY(1,ttCartProducts.item_color,"|").
                       
                      
          END. 
          lAddItem = YES.     
          FIND FIRST CartDetail WHERE CartDetail.Cart-ID     EQ CartHeader.Cart-Id
                                  AND CartDetail.Item-Number EQ ttCartProducts.item_number
                                  AND CartDetail.Size        EQ ttCartProducts.item_size
                                  AND CartDetail.Colour      EQ ttCartProducts.item_color 
                                  NO-LOCK NO-ERROR.
/*          IF AVAILABLE CartDetail THEN                                                                      */
/*          DO:                                                                                               */
/*             FOR FIRST tt-cartdetail WHERE tt-cartdetail.item-number       EQ ttCartProducts.item_number    */
/*                                       AND tt-cartdetail.parentitem-number EQ CartDetail.ext_chr[3] NO-LOCK:*/
/*               lAddItem = NO.                                                                               */
/*                                                                                                            */
/*             END.                                                                                           */
/*          END.                                                                                              */
/*          MESSAGE ttCartProducts.item_number  lAddItem                                                      */
/*          VIEW-AS ALERT-BOX.                                                                                */


          IF AVAILABLE CartDetail  THEN
          DO:            
            ASSIGN recordIDObj = NEW jsonObject().
            
            FIND CURRENT CartDetail EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
            IF AVAIL CartDetail THEN
              ASSIGN CartDetail.Quantity = /*CartDetail.Quantity +*/ ttCartProducts.quantity.
            
            IF CartDetail.ext_chr[1]  NE lcdiscounted_meta_key THEN  
              ASSIGN CartDetail.ext_chr[1]  = lcdiscounted_meta_key .
            
            IF  CartDetail.ext_chr[2]  NE lcdiscounted_meta_value THEN    
              ASSIGN CartDetail.ext_chr[2]  = lcdiscounted_meta_value.
                         
            recordIDObj:ADD(INPUT "temp_id",   INPUT ttCartProducts.unique_id).
            recordIDObj:ADD(INPUT "unique_id", INPUT STRING(ROWID(CartDetail))).              
            recordIDArr:ADD(INPUT recordIDObj).
            
          END. /* IF AVAILABLE CartDetail THEN */
          
          ELSE                                       
          DO:
            
            ASSIGN recordIDObj = NEW jsonObject().
            
            CREATE CartDetail.
            ASSIGN CartDetail.Cart-ID     = IF AVAILABLE CartHeader THEN CartHeader.Cart-Id ELSE ?
                   CartDetail.Item-Number = ttCartProducts.item_number
                   CartDetail.Description = ttCartProducts.description
                   CartDetail.Unit-Price  = ttCartProducts.unit_price
                   CartDetail.Size        = ttCartProducts.item_size
                   CartDetail.Colour      = ttCartProducts.item_color
                   CartDetail.Quantity    = ttCartProducts.quantity 
                   CartDetail.ext_chr[1]  = lcdiscounted_meta_key 
                   CartDetail.ext_chr[2]  = lcdiscounted_meta_value
                   CartDetail.ext_chr[4]  = IF (INDEX (ttCartProducts.item_number,"LEY172") GT 0 OR INDEX (ttCartProducts.description,"LEY") GT 0 ) 
                                                OR (INDEX (ttCartProducts.item_number,"-KIT") GT 0) THEN "NO-MODIFY" ELSE ""
                   NO-ERROR.
            
            // FIND FIRST tt-cartdetail WHERE tt-cartdetail.item-number EQ ttCartProducts.item_number NO-LOCK NO-ERROR.
            
             FOR FIRST tt-cartdetail WHERE tt-cartdetail.item-number EQ SUBSTRING(ttCartProducts.item_number,INDEX(ttCartProducts.item_number,"KIT") + 3) NO-LOCK: //ttCartProducts.item_number NO-LOCK:
                 ASSIGN CartDetail.ext_chr[3] = tt-cartdetail.parentitem-number.
             END.    
            /* IF AVAILABLE tt-cartdetail THEN 
               ASSIGN CartDetail.ext_chr[3] = tt-cartdetail.parentitem-number.     */
                     
                       /* Added error handling */
                     
            IF ERROR-STATUS:ERROR THEN
            DO: 
              ASSIGN cError = ERROR-STATUS:GET-MESSAGE(1).
              IF cError NE "":U THEN 
                UNDO,THROW NEW AppError(cError,1).
            END.
              
            recordIDObj:ADD(INPUT "temp_id",   INPUT ttCartProducts.unique_id).
            recordIDObj:ADD(INPUT "unique_id", INPUT STRING(ROWID(CartDetail))).
              
            recordIDArr:ADD(INPUT recordIDObj).
          END. /* ELSE OF IF AVAILABLE CartDetail THEN*/
          
        END. /* FOR EACH ttCartProducts: */ 
                  
        FIND CURRENT cartHeader EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF AVAIL CartHeader THEN
        DO:
          ASSIGN CartHeader.Timestamp = iNowTimeStamp.
          RELEASE CartHeader.
        END. /* IF AVAIL CartHeader THEN */
                        
      END. /* WHEN "Add":U THEN */
      
      WHEN "r":U THEN
      DO:
        FOR EACH ttCartProducts:
          
          FIND FIRST CartDetail WHERE CartDetail.Cart-ID EQ CartHeader.Cart-Id 
                                AND ROWID(CartDetail)    EQ TO-ROWID(ttCartProducts.unique_id) NO-LOCK NO-ERROR.
                                
          IF AVAILABLE CartDetail THEN
          DO:
            FIND CURRENT CartDetail EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
            IF AVAIL CartDetail THEN
            DO:
                 FIND FIRST bfCartDetail WHERE bfCartDetail.Cart-ID  EQ CartHeader.Cart-Id  
                                        AND bfCartDetail.Item-Number = CartDetail.Item-Number + "-LEY172" EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
                  IF AVAILABLE bfCartDetail THEN 
                  DO:
                  
                   DELETE bfCartDetail.
                  END.
                  FOR EACH bfCartDetail WHERE bfCartDetail.ext_chr[3] = CartDetail.Item-Number EXCLUSIVE-LOCK:
                      DELETE bfCartDetail.
                  END.    
                  DELETE CartDetail.
            END.    
                        
                        
          END. /* IF AVAIL CartDetail THEN */
              
        END. /*FOR EACH ttCartProducts: */
        
        FIND CURRENT cartHeader EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF AVAIL CartHeader THEN
        DO:
          IF NOT CAN-FIND(FIRST CartDetail WHERE CartDetail.Cart-ID EQ CartHeader.Cart-Id NO-LOCK) THEN
            ASSIGN CartHeader.Cart-Status = FALSE.
              
          ASSIGN CartHeader.Timestamp = iNowTimeStamp.
          RELEASE CartHeader.
        END.
            
      END. /* WHEN "Remove":U THEN */
      
      WHEN "m":U THEN
      DO:
        FOR EACH ttCartProducts:
          
          IF lcUserType EQ "mobileuser"   THEN 
          DO:
              ASSIGN lcdiscounted_meta_key      = ""
                     lcdiscounted_meta_value    = "".
                     
              IF NUM-ENTRIES(ttCartProducts.item_color,"|") EQ 3 THEN
                ASSIGN lcdiscounted_meta_key      =  ENTRY(2,ttCartProducts.item_color,"|")
                       lcdiscounted_meta_value    =  ENTRY(3,ttCartProducts.item_color,"|")
                       ttCartProducts.item_color  =  ENTRY(1,ttCartProducts.item_color,"|"). 
                      
          END.
          FIND FIRST CartDetail WHERE CartDetail.Cart-ID  EQ CartHeader.Cart-Id 
                                  AND ROWID(CartDetail)   EQ TO-ROWID(ttCartProducts.unique_id) NO-LOCK NO-ERROR.
          IF AVAILABLE CartDetail THEN
          DO:                             
            FIND CURRENT CartDetail EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
            IF AVAIL CartDetail THEN
            DO:
              ASSIGN CartDetail.Quantity = ttCartProducts.quantity.
              IF CartDetail.ext_chr[1]  NE lcdiscounted_meta_key THEN  
              ASSIGN CartDetail.ext_chr[1]  = lcdiscounted_meta_key .
            
              IF  CartDetail.ext_chr[2]  NE lcdiscounted_meta_value THEN    
              ASSIGN CartDetail.ext_chr[2]  = lcdiscounted_meta_value.
              
              
              FIND FIRST bfCartDetail WHERE bfCartDetail.Cart-ID  EQ CartHeader.Cart-Id  
                                        AND bfCartDetail.Item-Number = CartDetail.Item-Number + "-LEY172" EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
              IF AVAILABLE bfCartDetail THEN 
              DO:
                  
                ASSIGN  bfCartDetail.Quantity = ttCartProducts.quantity.
                 
              END.
             
              FOR EACH bfCartDetail WHERE bfCartDetail.ext_chr[3] = CartDetail.Item-Number 
                                      AND bfCartDetail.Cart-ID  EQ CartHeader.Cart-Id  EXCLUSIVE-LOCK:
                  
                FIND FIRST setdt WHERE SETDT.SET-NO EQ CartDetail.Item-Number 
                                   AND setdt.item-number EQ SUBSTRING(bfCartDetail.Item-Number,INDEX(bfCartDetail.Item-Number,"KIT") + 3) NO-LOCK NO-ERROR.
                IF AVAILABLE setdt THEN 
                DO:
                   ASSIGN bfCartDetail.Quantity = CartDetail.Quantity * SETDT.QTY.
                END.                                
                  
              END.
              RELEASE CartDetail.                                            
            END.          
                        
          END. /* IF AVAIL CartDetail THEN */  
              
        END. /* FOR EACH ttCartProducts: */ 
        
        FIND CURRENT cartHeader EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF AVAIL CartHeader THEN
        DO:
          ASSIGN CartHeader.Timestamp = iNowTimeStamp.
          RELEASE CartHeader.
        END.
               
      END. /* WHEN "Modify":U THEN */    
      
      WHEN "e":U THEN
      DO:
        FOR EACH CartDetail WHERE CartDetail.Cart-ID EQ CartHeader.Cart-Id NO-LOCK:
            
          FIND CURRENT CartDetail EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
          IF AVAIL CartDetail THEN
            DELETE CartDetail.
          
        END. /* FOR EACH CartDetail...*/ 
        
        FIND CURRENT cartHeader EXCLUSIVE-LOCK NO-WAIT NO-ERROR.
        IF AVAIL CartHeader THEN
        DO:   
          ASSIGN CartHeader.Cart-Status = FALSE
                 CartHeader.Timestamp   = iNowTimeStamp.
          RELEASE CartHeader.
        END.
               
      END. /* WHEN "Empty":U THEN */   
    
    END CASE. 
    
    ASSIGN oplcCartUniqueIds = recordIDArr:GetJsonText(). 
           opiStatusCode     = 200.
                              
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.

    FINALLY:
        
      IF VALID-OBJECT(recordIDObj) THEN
        DELETE OBJECT recordIDObj.
      IF VALID-OBJECT(recordIDArr) THEN
        DELETE OBJECT recordIDArr.  
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
        
    END FINALLY.

  END METHOD.  

  /*------------------------------------------------------------------------------
   Purpose: This method return the products available in the cart of a particular customer. 
               
   Input Parameters:
               1. ipcSalesRepId        - Sales Rep ID  
               2. ipcCustNumber        - Customer number               
               3. ipcLangID            - Language ID of the Logged-In user
               4. ipcUserType          - User Type -- Mobile/web user
               5. ipiWareHouseNo       - Warehouse no associated with the company selected
               6. ipiLastSyncTimestamp - Last sync timestamp
   
   Output Parameters:
               1. oplcCartItems - Return all the products added in the cart of a customer
               2. opiStatusCode - HTTP Status code
               3. opcError      - Error occured (if any)
               
   Notes: 
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID getCartProducts(INPUT ipcSalesRepId        AS CHARACTER,
                                     INPUT ipcCustNumber        AS CHARACTER,
                                     INPUT ipcLangID            AS CHARACTER,
                                     INPUT ipcCompanyCode       AS CHARACTER,
                                     INPUT ipcUserType          AS CHARACTER,
                                     INPUT ipiWareHouseNo       AS INTEGER,
                                     INPUT ipiLastSyncTimestamp AS INT64,
                                     OUTPUT oplcCartItems       AS LONGCHAR,
                                     OUTPUT opiStatusCode       AS INTEGER,
                                     OUTPUT opcError            AS CHARACTER):
    
    DEFINE VARIABLE objCommonSrc   AS CLASS CommonSource NO-UNDO.
    DEFINE VARIABLE iNowTimeStamp  AS INT64              NO-UNDO.
    
    ASSIGN objCommonSrc  = NEW CommonSource(INPUT cToken)
           oplcCartItems = "[]":U.
           
    IF ipcUserType EQ ConstantInitializer:cMobileUser THEN
    DO:
      /* get current time stamp */
      IF VALID-OBJECT(objCommonSrc) THEN 
      DO:
        ASSIGN iNowTimeStamp = objCommonSrc:getTimestamp(INPUT DATETIME-TZ(NOW),
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
    
      FIND FIRST CartHeader WHERE CartHeader.Sales-Rep-ID  EQ ipcSalesRepId
                              AND  CartHeader.Cust-Number  EQ ipcCustNumber
                              AND  CartHeader.Timestamp    GT ipiLastSyncTimestamp
                              AND  CartHeader.Cart-Status  NO-LOCK NO-ERROR.
                             
      IF AVAILABLE CartHeader THEN
      DO: 
        THIS-OBJECT:populateCartProducts(INPUT CartHeader.Cart-Id,
                                         INPUT ipcCustNumber,
                                         INPUT ipcCompanyCode,
                                         INPUT ipiWareHouseNo,
                                         OUTPUT oplcCartItems).
       
      END. /* IF AVAILABLE CartHeader THEN */
      
      ELSE
      DO:
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200CartAlreadySync,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1). 
      END. /* ELSE OF IF AVAILABLE CartHeader THEN */ 
              
    END. /* IF ipcUserType EQ ConstantInitializer:cMobileUser THEN */     
                          
    ELSE
    DO:
      FIND FIRST CartHeader WHERE CartHeader.Sales-Rep-ID EQ ipcSalesRepId
                              AND CartHeader.Cust-Number  EQ ipcCustNumber
                              AND CartHeader.Cart-Status  NO-LOCK NO-ERROR.
      IF AVAILABLE CartHeader THEN
      DO:
        THIS-OBJECT:populateCartProducts(INPUT CartHeader.Cart-Id,
                                         INPUT ipcCustNumber,
                                         INPUT ipcCompanyCode,
                                         INPUT ipiWareHouseNo,
                                         OUTPUT oplcCartItems).
       
      END. /* IF AVAILABLE CartHeader THEN */
      
      ELSE
      DO:
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200EmptyCart,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1). 
      END. /* ELSE OF IF AVAILABLE CartHeader THEN */
      
    END. /* ELSE OF IF ipcUserType EQ ConstantInitializer:cMobileUser THEN */
    
    ASSIGN opiStatusCode = 200.
            
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.

    FINALLY:
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
    END FINALLY.

  END METHOD.  

  /*------------------------------------------------------------------------------
   Purpose: This method constructs the JsonArray for the items available in the cart 
            table for a particular customer. 
               
   Input Parameters:
               1. iCartId        - CartId used to identify the records of a particular customer in cart table.  
               2. ipiWareHouseNo - Warehouse no associated with the company selected               
   
   Output Parameters:
               1. oplcCartItems - Return all the products added in the cart of a customer
              
   Notes: 
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID populateCartProducts(INPUT  iCartId        AS INTEGER,
                                          INPUT  ipcCustNumber  AS CHARACTER,
                                          INPUT  ipcCompanyCode AS CHARACTER,                                          
                                          INPUT  ipiWareHouseNo AS INTEGER, 
                                          OUTPUT oplcCartItems  AS LONGCHAR ):
        
    DEFINE VARIABLE objOrderTax     AS CLASS OrderTaxes    NO-UNDO.
    DEFINE VARIABLE ObjCategoryFilterItem  AS CLASS CategoryFilterItem    NO-UNDO.
    DEFINE VARIABLE cartItemsArray  AS CLASS JsonArray  NO-UNDO.
    DEFINE VARIABLE pictureJsonArr  AS CLASS JsonArray  NO-UNDO.
    DEFINE VARIABLE moreProdInfoArr AS CLASS JsonArray  NO-UNDO.
    DEFINE VARIABLE orderTaxArray   AS CLASS JsonArray  NO-UNDO.
    DEFINE VARIABLE cartItemObj     AS CLASS JsonObject NO-UNDO.
    DEFINE VARIABLE prodInfoObj     AS CLASS JsonObject NO-UNDO.
    DEFINE VARIABLE moreProdInfoObj AS CLASS JsonObject NO-UNDO.
    
    DEFINE VARIABLE cItemNumber AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSourceDir  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemImage  AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileType   AS CHARACTER NO-UNDO.
    DEFINE VARIABLE deUnitPrice AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE CDomain     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE objCustomerorder AS CLASS customerorders NO-UNDO.
    DEFINE VARIABLE byitem  AS LOGICAL NO-UNDO.
    DEFINE VARIABLE orderTaxObj         AS CLASS JsonObject              NO-UNDO.
    DEFINE VARIABLE lcDescription AS CHARACTER NO-UNDO.
    DEFINE VARIABLE ldUptoQty            AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldUptoQtyPrice       AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldPercent            AS DECIMAL          NO-UNDO.
    DEFINE VARIABLE ldbuyforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldgetforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldHasOffer           AS CHARACTER NO-UNDO.
    
     
            
    ASSIGN cartItemsArray        = NEW JsonArray()
           prodInfoObj           = NEW JsonObject()
           moreProdInfoObj       = NEW JsonObject()
           pictureJsonArr        = NEW JsonArray()
           moreProdInfoArr       = NEW JsonArray()
           orderTaxArray         = NEW JsonArray()
           objOrderTax           = NEW OrderTaxes(INPUT cToken)
           ObjCategoryFilterItem = NEW CategoryFilterItem(INPUT cToken).
           
    FOR EACH CartDetail WHERE CartDetail.Cart-ID EQ iCartId  NO-LOCK BY CartDetail.Item-Number:
      ASSIGN cartItemObj = NEW JsonObject()
             deUnitPrice = CartDetail.Unit-Price.
      
      lcDescription = REPLACE(CartDetail.Description,"'", "").
      lcDescription = REPLACE(lcDescription,'"', '').
      lcDescription = REPLACE(lcDescription,"/", "").
      lcDescription = REPLACE(lcDescription,"\", "").
            
      cartItemObj:ADD(INPUT "item_number":U, INPUT CartDetail.Item-Number).
      cartItemObj:ADD(INPUT "description":U, INPUT lcDescription ). //CartDetail.Description).
      cartItemObj:ADD(INPUT "quantity":U,    INPUT CartDetail.Quantity).
      cartItemObj:ADD(INPUT "unit_price":U,  INPUT CartDetail.Unit-Price).
      cartItemObj:ADD(INPUT "item_color":U,  INPUT CartDetail.Colour).
      cartItemObj:ADD(INPUT "item_size":U,   INPUT IF CartDetail.Size NE "" OR CartDetail.Size NE ? THEN CartDetail.Size ELSE "Not Applicable":U ).
      
      IF lcUserType EQ "mobileuser"   THEN 
      DO:
          cartItemObj:ADD(INPUT "discounted_meta_key":U,       INPUT CartDetail.ext_chr[1]).
          cartItemObj:ADD(INPUT "discounted_meta_value":U,     INPUT CartDetail.ext_chr[2]).
          cartItemObj:ADD(INPUT "show_button":U,     INPUT IF CartDetail.ext_chr[4] = "NO-MODIFY" THEN "NO" ELSE "YES").
               
      END.                     
      
      FIND FIRST CINV1 WHERE CINV1.ITEM-NUMBER EQ CartDetail.Item-Number NO-LOCK NO-ERROR.
      IF AVAILABLE CINV1 THEN
      DO:
          
        ASSIGN prodInfoObj     = NEW JsonObject()
               pictureJsonArr  = NEW JsonArray()
               moreProdInfoArr = NEW JsonArray()
               cItemNumber     = CINV1.ITEM-NUMBER.
        
        prodInfoObj:ADD(INPUT "class_code":U, INPUT CINV1.CLASS-CODE).
        
        IF cItemNumber MATCHES "*" THEN
           cItemNumber = CAPS(TRIM(REPLACE(cItemNumber, "*", "-") , "-":U)).
           
        objCustomerorder = NEW customerorders(INPUT ctoken).
        cSourceDir = objcustomerorder:ImgDirectory(INPUT cItemNumber, INPUT ipcCompanyCode, OUTPUT byitem). // this-object:ImgDirectory(INPUT cItemNumber).
        CDomain    = objcustomerorder:FINDCDN(ipcCompanyCode). //this-object:FINDCDN().
        IF cSourceDir NE "x" THEN                                                 
        DO:
            FILE-INFO:FILE-NAME = cSourceDir.
            cSourceDir = FILE-INFO:FULL-PATHNAME. 
          INPUT FROM OS-DIR(cSourceDir).
           IF byitem THEN  
           DO:
              REPEAT:
                   IMPORT cItemImage ^ cFileType.
                   IF cFileType EQ "F":U THEN
                   pictureJsonArr:ADD(Cdomain + "/":U + cItemNumber + "/":U + Replace(cItemImage," ","%20")).  
              END.         
          END. 
          ELSE 
          DO:
             REPEAT:
                  IMPORT cItemImage ^ cFileType.
                
                  IF cFileType EQ "F":U AND INDEX(cItemImage , cItemNumber) GT 0 THEN
                    pictureJsonArr:ADD(Cdomain + "/":U + Replace(cItemImage," ","%20")).   
                            
             END.   
         END.      
              
        END. /* IF FILE-INFO:FULL-PATHNAME NE ? THEN */  
        
        prodInfoObj:ADD(INPUT "pictures":U, INPUT pictureJsonArr).
          
        IF CINV1.PICTURE NE "":U THEN
        DO:
          
          FILE-INFO:FILE-NAME = ConstantInitializer:cPDFDir + "/":U + SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1) + ".pdf".
          IF FILE-INFO:FULL-PATHNAME NE ? THEN
          DO:
            prodInfoObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1) + ".pdf").
          END.
          
          ELSE
            prodInfoObj:ADD(INPUT "pdf_link":U, INPUT "":U).
        
        END. /* IF CINV1.PICTURE NE "":U THEN  */
        
        ELSE
          prodInfoObj:ADD(INPUT "pdf_link":U, INPUT "":U).
              
        prodInfoObj:ADD(INPUT "item_uom":U, INPUT CINV1.ITEM-UOM).
        prodInfoObj:ADD(INPUT "uom_qty":U,  INPUT CINV1.UOM-QTY).
        prodInfoObj:ADD(INPUT "on_order":U, INPUT CINV1.QTY-ON-ORDER).
        
        /* Assign value of quantity on hand of specific item */
        FIND FIRST CINV2 
             WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
             AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.
        
        IF AVAILABLE CINV2 THEN
        DO:
          prodInfoObj:ADD(INPUT "qty_on_hand":U, INPUT IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED GT 0 THEN CINV2.QTY-ONHAND - CINV2.QTY-COMMITED ELSE 0 ).
          prodInfoObj:ADD(INPUT "commit_qty":U,  INPUT CINV2.QTY-COMMITED ).
        END.
        
        ELSE
        DO:
          prodInfoObj:ADD(INPUT "qty_on_hand":U, INPUT IF CINV1.QTY-ONHAND GT 0 THEN CINV1.QTY-ONHAND ELSE 0).
          prodInfoObj:ADD(INPUT "commit_qty":U,  INPUT 0).
        END.
                                            
        IF CINV1.BY-SIZE OR CINV1.BY-COLOR THEN
        DO: 
          FOR EACH size WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo AND size.item-number EQ CINV1.ITEM-NUMBER NO-LOCK:
            moreProdInfoObj = NEW jsonObject ().
                       
            moreProdInfoObj:ADD(INPUT "size":U,       INPUT size.size).
            moreProdInfoObj:ADD(INPUT "color":U,      INPUT IF SIZE.DESCRIPTION NE "" THEN REPLACE(SIZE.DESCRIPTION,"'", "") ELSE 'Not Applicable').
            moreProdInfoObj:ADD(INPUT "in_stock":U,   INPUT (SIZE.QTY-ONHAND - SIZE.QTY-COMMITED)).
            moreProdInfoObj:ADD(INPUT "unit_price":U, INPUT CartDetail.Unit-Price).
            moreProdInfoArr:ADD(INPUT moreProdInfoObj).
                      
          END. /* FOR EACH size...*/
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
                
            moreProdInfoObj:ADD(INPUT "unit_price":U, INPUT CartDetail.Unit-Price).
            moreProdInfoArr:ADD(INPUT moreProdInfoObj).
        
        END.
                
        prodInfoObj:Add(INPUT "more_product_data", INPUT moreProdInfoArr).
        
        objOrderTax:getItemTaxForShipping(INPUT CINV1.ITEM-NUMBER,
                                          INPUT ipcCompanyCode, /* not available */
                                          INPUT ipcCustNumber,
                                          INPUT ipiWareHouseNo,
                                          INPUT "",
                                          INPUT deUnitPrice,
                                          OUTPUT orderTaxArray).
          
        IF VALID-OBJECT(prodInfoObj) THEN
          prodInfoObj:ADD(INPUT "item_tax_unit", INPUT orderTaxArray).
      //Movi de lugar
      cartItemObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
      cartItemObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).
        
      END. /* IF AVAILABLE CINV1 THEN */ 
      
      cartItemObj:ADD(INPUT "unique_id",    INPUT STRING(ROWID(CartDetail))).
      cartItemObj:ADD(INPUT "product_info", INPUT prodInfoObj).
     /* cartItemObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
      cartItemObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")). */
        /* Find the discount on item if any */
        FIND FIRST OFERT WHERE OFERT.ITEM-NUMBER EQ cItemNumber 
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
        
        cartItemObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).
        cartItemObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).  
        cartItemObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).
        cartItemObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]). 
        cartItemObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).
        cartItemObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]). 
        cartItemObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).
        cartItemObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]). 
        cartItemObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).
        cartItemObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).
        cartItemObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).  
        cartItemObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).
        cartItemObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty). 
        cartItemObj:ADD(INPUT "has_offer":U,             INPUT ldHasOffer).
        cartItemsArray:ADD(cartItemObj). 
       
    END. /* FOR EACH CartDetail..*/ 
    
    ASSIGN oplcCartItems = cartItemsArray:GetJsonText().
    
    FINALLY:
      
      INPUT CLOSE.
       
      IF VALID-OBJECT(cartItemObj)     THEN
        DELETE OBJECT cartItemObj.
        
      IF VALID-OBJECT(cartItemsArray)  THEN
        DELETE OBJECT cartItemsArray. 
        
      IF VALID-OBJECT(prodInfoObj)     THEN
        DELETE OBJECT prodInfoObj.
       
      IF VALID-OBJECT(moreProdInfoObj) THEN
        DELETE OBJECT moreProdInfoObj.
      
      IF VALID-OBJECT(pictureJsonArr)  THEN
        DELETE OBJECT pictureJsonArr.
      
      IF VALID-OBJECT(moreProdInfoArr) THEN
        DELETE OBJECT moreProdInfoArr.
      
      IF VALID-OBJECT(orderTaxArray)   THEN
        DELETE OBJECT orderTaxArray. 
      
      IF VALID-OBJECT(objOrderTax)     THEN
        DELETE OBJECT objOrderTax.         
         
    END FINALLY.
    

  END METHOD.
  /* Method to return the Image location */
  
   METHOD PUBLIC CHARACTER ImgDirectory (INPUT cItemNumber AS CHARACTER):
     FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
     IF AVAILABLE paramfl THEN 
        ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1 
               FILE-INFO:FILE-NAME =  FILE-INFO:FILE-NAME + "\" + cItemNumber NO-ERROR.
              
     IF FILE-INFO:FULL-PATHNAME NE ? THEN
     RETURN FILE-INFO:FULL-PATHNAME.
     ELSE 
     RETURN "x".    
   END METHOD.  
   
   /* Method to return the Content Delivery Network location */
  
   METHOD PUBLIC CHARACTER FINDCDN ():
     FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
     IF AVAILABLE paramfl THEN 
     RETURN PARAMFL.PARAM-VALUE2.
     
     ELSE 
     RETURN "x".    
   END METHOD. 
END CLASS.