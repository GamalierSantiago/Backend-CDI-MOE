/*---------------------------------------------------------------------------------
   File        : CategoryFilterItem
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : JKTECH
   Created     : Tue Oct 10 10:30:57 IST 2017
   Notes       : Version 1.1
   History     :
  --------------------------------------------------------------------------------
  Date(MM-DD-YY)        Author            Initial(XX-Version)      Description
                                                   
  --------------------------------------------------------------------------------     
 ----------------------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS CategoryFilterItem: 
    
  /*-----------------------------------------------------------------------------------
   Purpose: This class shows Category records along with their sub-category records and 
            their filters and items records by using jsonObject and jsonArray.
           
   Notes:
  -------------------------------------------------------------------------------------*/
  
  /* Define buffer for IVBRAND table to establish parent-child relationship between categories */ 
  DEFINE PRIVATE BUFFER bufIvbrand1 FOR IVBRAND.
  DEFINE PRIVATE BUFFER bufIvbrand2 FOR IVBRAND.
  DEFINE PRIVATE BUFFER bufIvbrand3 FOR IVBRAND.
  DEFINE PRIVATE BUFFER bufIvbrand4 FOR IVBRAND.
  DEFINE PRIVATE BUFFER bfCsahf     FOR CSAHF.
  DEFINE PRIVATE BUFFER bfCCSMS     FOR CCSMS.
  
  
  /*This temp-table is taken in place of wkfile which stores the custype and class-codes 
  which can be accesed by this custype in terminal-id field and criteria of how these entries 
  are assigned to wkfile is not known.This table taken for testing purpose till then*/
  /* DEFINE TEMP-TABLE ttwkfile NO-UNDO    
     FIELD TERMINAL-ID LIKE WKFILE.TERMINAL-ID
     FIELD prog-name   LIKE WKFILE.PROG-NAME. */
  
  DEFINE PRIVATE TEMP-TABLE ttCustNumber NO-UNDO
    FIELD cCustNum  AS CHARACTER 
    INDEX ixCustNum AS PRIMARY UNIQUE cCustNum. 
  
  /* Temp-table for purchasing history items */  
  DEFINE PRIVATE TEMP-TABLE ttPurchaseItem NO-UNDO
    FIELD item_number LIKE CINV1.item-number    
    FIELD class_code  LIKE CINV1.class-code
    FIELD qty_on_hand LIKE CINV1.QTY-ONHAND     
    FIELD item_count  AS INTEGER
    FIELD price       AS DECIMAL    
    INDEX ixItemNum AS PRIMARY UNIQUE item_number.
  
  DEFINE TEMP-TABLE ttIndexTable NO-UNDO
    FIELD field-name AS CHARACTER
    FIELD data-type  AS CHARACTER
    FIELD index-name AS CHARACTER
    FIELD iWordIndex AS INTEGER  
    INDEX idxField AS PRIMARY UNIQUE field-name iWordIndex.
  
  DEFINE TEMP-TABLE ttVendorFilter NO-UNDO
    FIELD item_number LIKE CINV1.ITEM-NUMBER
    FIELD filter_data AS CHARACTER
    INDEX ixFilterData AS PRIMARY UNIQUE filter_data.
  
  DEFINE TEMP-TABLE ttFamilyFilter NO-UNDO LIKE ttVendorFilter.
  
  DEFINE TEMP-TABLE ttFabricFilter NO-UNDO LIKE ttVendorFilter.
  
  DEFINE TEMP-TABLE ttMakeFilter   NO-UNDO LIKE ttVendorFilter.
    
  DEFINE TEMP-TABLE ttSizeFilter   NO-UNDO LIKE ttVendorFilter.
  
  DEFINE TEMP-TABLE ttColorFilter  NO-UNDO LIKE ttVendorFilter.  
            
  DEFINE PRIVATE VARIABLE cError AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC CategoryFilterItem ():
                                                                                           
  END CONSTRUCTOR.
  
  DEFINE PUBLIC  VARIABLE cToken           AS CHARACTER NO-UNDO.
  DEFINE PUBLIC  VARIABLE cusertype        AS CHARACTER NO-UNDO.
  DEFINE PUBLIC  VARIABLE lcDescription    AS CHARACTER NO-UNDO.
  DEFINE BUFFER bf-cinv2   FOR cinv2.
  CONSTRUCTOR PUBLIC CategoryFilterItem (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
    FIND FIRST token WHERE Token.Token = ipcToken NO-LOCK NO-ERROR.
    IF AVAILABLE token THEN 
      ASSIGN cusertype = Token.User-Type.
  END CONSTRUCTOR.
  /*----------------------------------------------------------------------------------------------------
  Purpose: This method provides the functionality of free form product search. It will return the results
           according to the specified keyword(s), if such keyword(s) exists in CINV1 table.
  
  Input-Parameter: 1.ipcInputString - search keyword
                                      
  Output Parameter: 1.opiTotalRecords - total number of records satisifying search query.                         
                    2.ttSearchData    - temp-table to store searched items.          
  -----------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID freeformProductSearch(INPUT ipcCustNumber    AS CHARACTER,
                                           INPUT ipcInputString   AS LONGCHAR,
                                           INPUT ipcCompanyCode   AS CHARACTER,
                                           INPUT ipiWareHouseNo   AS INTEGER,
                                           INPUT ipcLangID        AS CHARACTER,
                                           OUTPUT opiTotalRecords AS INTEGER,
                                           OUTPUT opiStatusCode   AS INTEGER,
                                           OUTPUT opcError        AS CHARACTER,
                                           OUTPUT oplcSearchData  AS LONGCHAR):
                                               
    
    DEFINE VARIABLE objCustProductsPrice AS CLASS     ProductPrices     NO-UNDO.
    DEFINE VARIABLE objOrderTax          AS CLASS     OrderTaxes        NO-UNDO.
    DEFINE VARIABLE orderTaxArray        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE objCommonSrc         AS CLASS     CommonSource      NO-UNDO.
    DEFINE VARIABLE itemJsonObj          AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE prodInfoObj          AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE prodInfoArr          AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE pictureJsonArr       AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE itemJsonArray        AS CLASS     JsonArray         NO-UNDO. 
    DEFINE VARIABLE objcustomerOrder     AS CLASS     customerorders    NO-UNDO.  
    DEFINE VARIABLE hQuery               AS HANDLE    NO-UNDO.
    DEFINE VARIABLE hBuffer              AS HANDLE    NO-UNDO.
    DEFINE VARIABLE iCount               AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iarrayIndex          AS INTEGER   NO-UNDO.
    DEFINE VARIABLE cKeyword             AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSearchPattern       AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cTable               AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cQuery               AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cInitialQuery        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cBreakString         AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cNonASCIIString      AS CHARACTER NO-UNDO.
    
    
    DEFINE VARIABLE discount-perc        LIKE CCSMS.DISC-PERC    NO-UNDO.
    DEFINE VARIABLE contract-ind         LIKE CCSMS.CONTRACT-IND NO-UNDO.
    DEFINE VARIABLE spec-dist-i          LIKE CCSMS.SPEC-DICT-I  NO-UNDO.
    DEFINE VARIABLE qty-brk-cd           LIKE CCSMS.QTY-BRK-CD   NO-UNDO.
    DEFINE VARIABLE cCustType            LIKE CCSMS.CUST-TYPE    NO-UNDO.
    
    DEFINE VARIABLE SELLING-PRC          AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE BASE-PRC             AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE cPriceList           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSourceDir           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemImage           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileType            AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemNumber          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lByColor             AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE SHIP-NO              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE QTY-FULL             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE QTY-UNIT             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    
    DEFINE VARIABLE cPictureFieldVal     AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPicturePDFName      AS CHARACTER NO-UNDO. /* file name without path */
    DEFINE VARIABLE ldMinPrice           AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldUptoQty            AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldUptoQtyPrice       AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldPercent            AS DECIMAL          NO-UNDO.
    DEFINE VARIABLE ldbuyforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldgetforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldHasOffer           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcallPrice           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDomain              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPackSize            AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPalletQuantity      AS CHARACTER NO-UNDO.
    DEFINE VARIABLE byitem               AS LOGICAL NO-UNDO.
    DEFINE BUFFER buff-cinv1 FOR cinv1.
    DEFINE VARIABLE liQtyonHand AS INT64 NO-UNDO.
    DEFINE VARIABLE liCommitQty AS INT64 NO-UNDO.
    /* Limiting search string to only 50 characters */
    IF LENGTH(ipcInputString) GT 50 THEN
      ASSIGN ipcInputString = SUBSTRING(ipcInputString,1,50).
       
    ASSIGN 
      itemJsonArray        = NEW JsonArray()
      objCommonSrc         = NEW CommonSource(INPUT cToken)
      objCustProductsPrice = NEW ProductPrices(INPUT cToken)
      orderTaxArray        = NEW JsonArray()
      objOrderTax          = NEW OrderTaxes(INPUT cToken)
      objcustomerOrder     = NEW customerorders(INPUT cToken).
                    
    FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
    IF AVAIL CCSMS THEN
    DO: 
      ASSIGN 
        cCustType     = CCSMS.CUST-TYPE
        qty-brk-cd    = CCSMS.QTY-BRK-CD
        spec-dist-i   = CCSMS.SPEC-DICT-I
        contract-ind  = CCSMS.CONTRACT-IND
        discount-perc = CCSMS.DISC-PERC
        cPriceList    = CCSMS.PRICE-LIST.  
                
      FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
        ASSIGN cPriceList = SHPTO.PRICE-LIST.

    END. /* IF AVAIL CCSMS THEN */
    
    /* Logic for breaking the string word by word and making a complete word when a delimiter is found */
    DO iCount = 1 TO LENGTH(ipcInputString):
      ASSIGN 
        cBreakString = SUBSTRING(ipcInputString, iCount, 1).
  
      IF (ASC(cBreakString) GE 0  AND ASC(cBreakString) LE 38) OR
         (ASC(cBreakString) GE 40 AND ASC(cBreakString) LE 44) OR
         (ASC(cBreakString) GE 58 AND ASC(cBreakString) LE 64) OR
         (ASC(cBreakString) GE 91 AND ASC(cBreakString) LE 96) OR
         ASC(cBreakString)  GE 123                             THEN 
 
        ASSIGN cNonASCIIString = cNonASCIIString + ",":U.
 
      ELSE
        ASSIGN cNonASCIIString = cNonASCIIString + cBreakString.
  
    END. /*DO i = 1 TO LENGTH(cInputString):*/

    /* cTable EQ "CINV1" can be parameteric and can be replaced later with other tables also */
    ASSIGN 
      cTable        = "CINV1":U
      cInitialQuery = 'FOR EACH CINV1 WHERE (CINV1.HIDE-IN-WM-APPS NE "Y":U) AND (CINV1.LINE-UP NE "D":U AND CINV1.LINE-UP NE "W":U AND CINV1.LINE-UP NE "X":U ) AND CINV1.item-number':U + ' BEGINS ':U  + '"':U + ipcCompanyCode + '"':U.
      // Query condition of lineup changed from OR to AND so it ignores all items with line-up D, X and Wss
    /*      
    FOR FIRST _file WHERE _File._File-name EQ cTable NO-LOCK:
      /* Loop over all indexes */
      FOR EACH _index OF _file NO-LOCK:

        FOR EACH _index-field OF _index NO-LOCK:
          /* go get _field record */
          FIND _field OF _index-field NO-LOCK NO-ERROR.
          IF AVAILABLE (_field) THEN
          DO: 
            IF NOT CAN-FIND(FIRST ttIndexTable WHERE field-name EQ _field-name AND iWordIndex EQ _Wordidx NO-LOCK) THEN
            DO:
              CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = _field-name
                ttIndexTable.data-type  = _data-type
                ttIndexTable.index-name = _index-name
                ttIndexTable.iWordIndex = _Wordidx.
                    
            END. /* IF NOT CAN-FIND(FIRST ttIndexTable..*/

          END. /* IF AVAILABLE (_field) THEN */
           
        END. /* FOR EACH _index-field..*/
        
      END. /* FOR EACH _index..*/
      
    END. /* FOR FIRST _file..*/
   */

   
   
    //WHILE Counter <= 5 DO:
        
    CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "ALT-ITEM-NO"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "alt-item-number"
                ttIndexTable.iWordIndex = ?.
                
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "BAR-CODE"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "BAR-C"
                ttIndexTable.iWordIndex = ?.
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "DESCRIPTION"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "DESC-IX"
                ttIndexTable.iWordIndex = ?.
                
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "DESCRIPTION"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "DESC-WORD"
                ttIndexTable.iWordIndex = 1.
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "ITEM-NUMBER"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "ITEM-NUMBER"
                ttIndexTable.iWordIndex = ?.
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "OTHER-DESC"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "other-desc"
                ttIndexTable.iWordIndex = ?.
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "OTHER-DESC"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "other-desc"
                ttIndexTable.iWordIndex = ?.
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "VDR-ITEM-NO"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "VDR-ITEM-NO"
                ttIndexTable.iWordIndex = ?.
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "VDR-ITEM-NO"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "VDR-ITEM-NO"
                ttIndexTable.iWordIndex = ?.
   CREATE ttIndexTable.
              ASSIGN 
                ttIndexTable.field-name = "VIN-NUMBER"
                ttIndexTable.data-type  = "character"
                ttIndexTable.index-name = "vin-number"
                ttIndexTable.iWordIndex = ?.            
    //END.
    
      
    /* Prepare dynamic query 
     cNonASCIIString now stores the comma seperated list of words*/
    DO iCount = 1 TO NUM-ENTRIES(cNonASCIIString):
  
      ASSIGN 
        cKeyword = TRIM(ENTRY(iCount, cNonASCIIString)).
  
      IF cKeyword EQ "":U THEN
        NEXT. 
    
      CREATE BUFFER hBuffer FOR TABLE cTable.
      CREATE QUERY hQuery.      
               
      hQuery:SET-BUFFERS(hBuffer). 
    
      //DO iFieldIndex = 1 TO hBuffer:NUM-FIELDS:
      FOR EACH ttIndexTable NO-LOCK :
        
        // Originally cSearchPatters = cKeyword. Changed since search result was considering only the first searched word 9-22-23     
        ASSIGN 
          cSearchPattern = cNonASCIIString.
    
        CASE ttIndexTable.data-type:
            
          WHEN "INTEGER":U THEN 
            ASSIGN 
              cQuery = cInitialQuery + " AND ":U + ttIndexTable.field-name + " EQ ":U +  STRING(INTEGER(cSearchPattern)) + " No-Lock ":U NO-ERROR.

          WHEN "DECIMAL":U THEN 
            ASSIGN 
              cQuery = cInitialQuery + " AND ":U + ttIndexTable.field-name + " EQ ":U + STRING(DECIMAL(cSearchPattern)) +  " No-Lock ":U NO-ERROR.

          WHEN "DATE":U THEN
            ASSIGN 
              cQuery = cInitialQuery + " AND ":U + ttIndexTable.field-name + " EQ ":U  + STRING(DATE(cSearchPattern)) +  " No-Lock ":U NO-ERROR.

          WHEN "LOGICAL":U THEN
            NEXT.
          
          WHEN "INT64":U THEN
            NEXT.
          
          WHEN "CHARACTER":U THEN
            DO:                
              IF ttIndexTable.iWordIndex EQ 1 THEN
                ASSIGN 
                  cSearchPattern = '"':U + cSearchPattern + '*':U + '"':U
                  cQuery         = cInitialQuery + " AND ":U + ttIndexTable.field-name + " CONTAINS ":U  +  cSearchPattern  + " No-Lock ":U NO-ERROR.
    
              ELSE       
                ASSIGN 
                  cSearchPattern = '"':U + cSearchPattern + '"':U
                  cQuery         = cInitialQuery + " AND ":U + ttIndexTable.field-name + " BEGINS ":U  +  cSearchPattern  + " No-Lock ":U NO-ERROR.
   
            END. /* WHEN "CHARACTER":U THEN */    

        END CASE. 
       
        IF NOT ERROR-STATUS:ERROR THEN
        DO:       
          
          hQuery:QUERY-PREPARE(cQuery).  

          hQuery:QUERY-OPEN().         
          DEFINE VARIABLE wasWKFILEAlreadyFound AS LOGICAL INITIAL FALSE NO-UNDO.
          //Gets the first element of the FOR EACH to verify whether there is even a field to
          hQuery:GET-FIRST().

          IF hQuery:QUERY-OFF-END AND NOT wasWKFILEAlreadyFound THEN DO:
                DEF VAR charInputString AS CHAR NO-UNDO.
                charInputString = STRING(ipcInputString).


                //FIND IVMULTBAR WHERE IVMULTBAR.BAR-CODE BEGINS charInputString NO-LOCK NO-ERROR. //Uncomment when using IVMULTBAR
                FIND WKFILE WHERE PROG-NAME = "MULTBAR" AND CHAR1 BEGINS charInputString NO-LOCK NO-ERROR. //Uncomment when using WKFILE
                
/*                MESSAGE "CHAR1 " CHAR1*/
/*                VIEW-AS ALERT-BOX.    */

                //Uncomment when using WHITEMRD.p
/*                DEF VAR box-item-number AS CHAR NO-UNDO.    */
/*                DEF VAR boxes AS INTEGER NO-UNDO.           */
/*                DEF VAR box-lotnumber AS CHAR NO-UNDO.      */
/*                DEF VAR box-number AS CHAR NO-UNDO.         */
/*                DEF VAR BOX-prep-date AS DATE NO-UNDO.      */
/*                DEF VAR box-expire-date AS DATE NO-UNDO.    */
/*                DEF VAR box-pack-date AS DATE NO-UNDO.      */
/*                DEF VAR box-sellby-date AS DATE NO-UNDO.    */
/*                DEF VAR bar-code-scan AS CHAR NO-UNDO.      */
/*                DEF VAR poundsInBarCode AS DECIMAL NO-UNDO. */
/*                                                            */
/*                RUN WHITEMRD.p (   INPUT charInputString,   */
/*/*                                   INPUT ipcCompanyCode,*/*/
/*                                   OUTPUT box-item-number,  */
/*                                   OUTPUT boxes,            */
/*                                   OUTPUT poundsInBarCode,  */
/*                                   OUTPUT box-lotnumber,    */
/*                                   OUTPUT box-prep-date,    */
/*                                   OUTPUT box-expire-date,  */
/*                                   OUTPUT box-pack-date,    */
/*                                   OUTPUT box-sellby-date,  */
/*                                   OUTPUT box-number,       */
/*                                   OUTPUT bar-code-scan).   */


                //IF AVAIL IVMULTBAR THEN DO:   //Uncomment when using IVMULTBAR
                IF AVAIL WKFILE THEN DO:        //Uncomment when using WKFILE
                //IF box-item-number <> "" THEN DO: //Uncomment when using WHITEMRD.p
                    DELETE OBJECT hBuffer.
                    DELETE OBJECT hQuery.
                    ASSIGN

                        //cQuery = cInitialQuery + ' AND ITEM-NUMBER BEGINS "':U + IVMULTBAR.ITEM-NUMBER + '" NO-LOCK ':U NO-ERROR. //Uncomment when using IVMULTBAR
                        cQuery = cInitialQuery + ' AND ITEM-NUMBER BEGINS "':U + WKFILE.TERMINAL-ID + '" NO-LOCK ':U NO-ERROR. //Uncomment when using WKFILE
                        //cQuery = cInitialQuery + ' AND ITEM-NUMBER BEGINS "':U + box-item-number + '" NO-LOCK ':U NO-ERROR.  //Uncomment when using WHITEMRD.p
                    CREATE BUFFER hBuffer FOR TABLE cTable.
                    CREATE QUERY hQuery.
                    hQuery:SET-BUFFERS(hBuffer).

                    hQuery:QUERY-PREPARE(cQuery).

                    hQuery:QUERY-OPEN().
                    hQuery:GET-FIRST().

                    wasWKFILEAlreadyFound = TRUE.
                END.
            END.
          hQuery:QUERY-OPEN.
          
          
          repeat_blk:
          REPEAT:            
            hQuery:GET-NEXT().
            IF hQuery:QUERY-OFF-END THEN 
                LEAVE.
                
                /*MESSAGE "hBuffer:BUFFER-FIELD(item-number:U):BUFFER-VALUE " skip
                hBuffer:BUFFER-FIELD("item-number":U):BUFFER-VALUE
                VIEW-AS ALERT-BOX.*/
              
            ASSIGN 
              cItemNumber = hBuffer:BUFFER-FIELD("item-number":U):BUFFER-VALUE
              cPackSize   = hBuffer:BUFFER-FIELD("PACK":U):BUFFER-VALUE.
              cPalletQuantity = hBuffer:BUFFER-FIELD("PALLET-QTY":U):BUFFER-VALUE.
            FIND buff-cinv1 WHERE buff-cinv1.ITEM-NUMBER EQ cItemNumber NO-LOCK NO-ERROR. 
            IF AVAILABLE buff-cinv1 AND buff-cinv1.LINE-UP EQ "D" THEN NEXT. 
            FIND FIRST CINV2 
              WHERE CINV2.ITEM-NUMBER  EQ cItemNumber
              AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.
/*            FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"*/
/*                                 AND PARAMFL.COMPANY-CODE = ipcCompanyCode               */
/*                                 AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.        */
/*            IF AVAILABLE paramfl AND AVAILABLE cinv2 THEN                                */
/*            DO:                                                                          */
/*                IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN NEXT.                 */
/*            END.                                                                         */
            IF CCSMS.CONTRACT-IND EQ "A" THEN 
            DO:
                IF NOT CAN-FIND(CINV3 WHERE CINV3.ITEM-NUMBER EQ cItemNumber AND CINV3.PRICE-LIST EQ CCSMS.PRICE-LIST ) THEN NEXT.
            END.                                                  
            /* avoid duplicate records */
            IF itemJsonArray:LENGTH NE 0 THEN 
            DO iarrayIndex = 1 TO itemJsonArray:LENGTH:
            
              ASSIGN 
                itemJsonObj = itemJsonArray:GetJsonObject(INPUT iarrayIndex).
          
              IF itemJsonObj:Has(INPUT "item_number":U) THEN
              DO:
                IF itemJsonObj:GetCharacter(INPUT "item_number") = cItemNumber THEN
                DO:
                  NEXT repeat_blk.           
                END. /* IF CSAHF.ITEM-NUMBER EQ itemJsonObj:GetCharacter(INPUT "item_number":U) THEN*/
               
              END. /* IF itemJsonObj:Has(INPUT "item_number":U) THEN */
                    
            END. /* IF itemJsonArray:LENGTH NE 0 THEN */
                                                                         
            ASSIGN 
              itemJsonObj    = NEW JsonObject()
              prodInfoArr    = NEW JsonArray () 
              pictureJsonArr = NEW jsonArray ()
              lByColor       = hBuffer:BUFFER-FIELD("by-color":U):BUFFER-VALUE.           
            
            ASSIGN 
              opiTotalRecords = opiTotalRecords + 1.
          
            lcDescription = REPLACE(hBuffer:BUFFER-FIELD("Description":U):BUFFER-VALUE,"'", "").
            lcDescription = REPLACE(lcDescription,'"', '').
            lcDescription = REPLACE(lcDescription,"/", "").
            lcDescription = REPLACE(lcDescription,"\", "").
            
            itemJsonObj:ADD(INPUT "class_code":U,   INPUT hBuffer:BUFFER-FIELD("class-code":U):BUFFER-VALUE).
            itemJsonObj:ADD(INPUT "item_number":U,  INPUT cItemNumber).
            itemJsonObj:ADD(INPUT "description":U,  INPUT lcDescription ). //REPLACE(hBuffer:BUFFER-FIELD("Description":U):BUFFER-VALUE,"'", "") ). 
            itemJsonObj:ADD(INPUT "item_uom":U,     INPUT hBuffer:BUFFER-FIELD("ITEM-UOM":U):BUFFER-VALUE).
            itemJsonObj:ADD(INPUT "uom_qty":U,      INPUT hBuffer:BUFFER-FIELD("UOM-QTY":U):BUFFER-VALUE).
            itemJsonObj:ADD(INPUT "on_order":U,     INPUT hBuffer:BUFFER-FIELD("QTY-ON-ORDER":U):BUFFER-VALUE).
            itemJsonObj:ADD(INPUT "category_id":U,  INPUT hBuffer:BUFFER-FIELD("CLASS-CODE":U):BUFFER-VALUE). 
            itemJsonObj:ADD(INPUT "family_code":U,  INPUT hBuffer:BUFFER-FIELD("FAMILY":U):BUFFER-VALUE).                                  
                                  
            /* Assign value of quantity on hand of specific item */
            
                               
            IF AVAILABLE CINV2 THEN
            DO:
               IF CAN-FIND(FIRST sethd WHERE SETHD.SET-NO EQ CINV2.ITEM-NUMBER) THEN 
               DO:
                  liQtyonHand = 0.
                  IF CAN-FIND(FIRST sethd WHERE SETHD.SET-NO EQ CINV2.ITEM-NUMBER) THEN 
                  DO:
                     FOR EACH setdt WHERE SETDT.SET-NO EQ CINV2.ITEM-NUMBER NO-LOCK:
                       FIND FIRST bf-cinv2 WHERE bf-cinv2.ITEM-NUMBER EQ SETDT.ITEM-NUMBER NO-LOCK NO-ERROR.
                       IF AVAILABLE bf-cinv2 THEN 
                       DO:
                         IF liQtyonHand EQ 0 OR liQtyonHand GT bf-CINV2.QTY-ONHAND THEN 
                         ASSIGN liQtyonHand = bf-CINV2.QTY-ONHAND 
                                liCommitQty = bf-CINV2.QTY-COMMITED.
                       END.    
                     END.
                     
                     IF liQtyonHand GT 0 THEN 
                        itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT liQtyonHand ).
                     ELSE 
                        itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0 ).
                        
                     itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT liCommitQty ).      
                  END. 
               END. 
               ELSE 
               DO:
                 IF CINV2.QTY-ONHAND GT 0 THEN 
                    itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT CINV2.QTY-ONHAND ).
                  ELSE 
                    itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0 ).
                    
                  itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT CINV2.QTY-COMMITED ).
               END.   
            END.
            
            ELSE
            DO:
              IF hBuffer:BUFFER-FIELD("QTY-ONHAND":U):BUFFER-VALUE GT 0 THEN
                itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT hBuffer:BUFFER-FIELD("QTY-ONHAND":U):BUFFER-VALUE).
              ELSE 
                itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0).
                
              itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT 0).
            END.  
               
            /*By-calling getPrice() method, assign selling-price of a specific Item corresponding to a specific customer*/           
            
            objCustProductsPrice:getProductPrices(INPUT ipcLangID,
                                                  INPUT ipcCustNumber,
                                                  INPUT cItemNumber,
                                                  INPUT YES,
                                                  INPUT discount-perc, 
                                                  OUTPUT SELLING-PRC,
                                                  OUTPUT BASE-PRC,
                                                  INPUT  SHIP-NO,
                                                  INPUT  QTY-FULL,
                                                  INPUT QTY-UNIT,
                                                  INPUT cPriceList,
                                                  INPUT ipcCompanyCode).
            
            
             
            IF hBuffer:BUFFER-FIELD("by-size":U):BUFFER-VALUE OR lByColor THEN
            DO:  
              FOR EACH size WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo 
                              AND SIZE.ITEM-NUMBER  EQ cItemNumber    NO-LOCK:
                                    
                ASSIGN 
                  prodInfoObj = NEW jsonObject ().
                                        
                prodInfoObj:ADD(INPUT "size",       INPUT if size.size NE "" then size.size ELSE 'Not Applicable':U).
                prodInfoObj:ADD(INPUT "color",      INPUT IF SIZE.DESCRIPTION NE "" THEN REPLACE(SIZE.DESCRIPTION,"'", "")  ELSE 'Not Applicable':U).
                prodInfoObj:ADD(INPUT "in_stock",   INPUT (SIZE.QTY-ONHAND - SIZE.QTY-COMMITED)).
                prodInfoObj:ADD(INPUT "unit_price", INPUT SELLING-PRC).
                prodInfoArr:ADD(INPUT prodInfoObj).
                              
              END. /* FOR EACH size...*/
            END. /* IF hBuffer:BUFFER-FIELD("by-size":U):BUFFER-VALUE THEN */            
            
            IF prodInfoArr:LENGTH EQ 0 THEN
            DO:
              ASSIGN 
                prodInfoObj = NEW jsonObject ().
                
              prodInfoObj:ADD(INPUT "size":U,  INPUT 'Not Applicable':U).
              prodInfoObj:ADD(INPUT "color":U, INPUT 'Not Applicable':U).
                
              IF AVAILABLE CINV2 THEN
                prodInfoObj:ADD(INPUT "in_stock":U, INPUT CINV2.QTY-ONHAND - CINV2.QTY-COMMITED ).
              ELSE
                prodInfoObj:ADD(INPUT "in_stock":U, INPUT hBuffer:BUFFER-FIELD("QTY-ONHAND":U):BUFFER-VALUE ).
                
              prodInfoObj:ADD(INPUT "unit_price":U, INPUT SELLING-PRC).
              prodInfoArr:ADD(INPUT prodInfoObj).
              
            END.
            
            IF cItemNumber MATCHES "*" THEN
              cItemNumber = CAPS(TRIM(REPLACE(cItemNumber, "*", "-") , "-":U)).
     
          /*  FILE-INFO:FILE-NAME = ConstantInitializer:cImageDir + "/":U + cItemNumber.
            IF FILE-INFO:FULL-PATHNAME EQ ? THEN 
            DO:
                FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
                IF AVAILABLE paramfl THEN 
                  ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1 
                         FILE-INFO:FILE-NAME =  FILE-INFO:FILE-NAME + "\" + cItemNumber NO-ERROR.
            END.
            IF FILE-INFO:FULL-PATHNAME NE ? THEN
            DO: */
            cSourceDir = objcustomerorder:ImgDirectory(INPUT cItemNumber, INPUT ipcCompanyCode, OUTPUT byitem). //this-object:ImgDirectory(INPUT cItemNumber).
            CDomain    = objcustomerorder:FINDCDN(ipcCompanyCode).  //THIS-OBJECT:FINDCDN().
           
           IF cSourceDir NE "x" THEN 
           DO:
              
/*              ASSIGN                                 */
/*                cSourceDir = FILE-INFO:FULL-PATHNAME.*/
              FILE-INFO:FILE-NAME = cSourceDir.
              
              cSourceDir = FILE-INFO:FULL-PATHNAME.
              INPUT FROM OS-DIR(cSourceDir).
              IF byitem THEN 
              DO:
                REPEAT:
                     IMPORT cItemImage ^ cFileType.
                     IF cFileType EQ "F":U THEN
                     do:
                        pictureJsonArr:ADD(CDomain + "/":U + cItemNumber + "/":U + Replace(cItemImage," ","%20")).
                     end.             
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
            END. /* IF cSourceDir NE "x" THEN */
                                   
            /* Populate itemJsonObj jsonArray with all items record correspond to specific category by calling PopulateItem() method */
          
            ASSIGN 
              cPictureFieldVal = (hBuffer:BUFFER-FIELD("picture":U):BUFFER-VALUE)
              cPicturePDFName  = SUBSTRING(cPictureFieldVal, R-INDEX(cPictureFieldVal, "\" ) + 1). /* Gives the last value of picture field */         
            
            itemJsonObj:ADD(INPUT "price":U, INPUT SELLING-PRC).
            
            IF cPictureFieldVal NE "":U THEN 
            DO:
              FILE-INFO:FILE-NAME = ConstantInitializer:cPDFDir + "/":U + cPicturePDFName + ".pdf".              
              IF FILE-INFO:FULL-PATHNAME NE ? THEN
              DO:
                //itemJsonObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + hBuffer:BUFFER-FIELD("picture":U):BUFFER-VALUE).
                itemJsonObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + cPicturePDFName + ".pdf").
              END.
              
              ELSE
                itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(cItemNumber,ipcCompanyCode ) ).
            END. /* IF cPictureFieldVal NE "":U THEN  */
            
            ELSE
              itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(cItemNumber, ipcCompanyCode)).
            
            itemJsonObj:ADD(INPUT "pictures":U,        INPUT pictureJsonArr).
            itemJsonObj:Add(INPUT "more_product_data", INPUT prodInfoArr).
            
            
            objOrderTax:getItemTaxForShipping(INPUT cItemNumber,
                                              INPUT ipcCompanyCode,
                                              INPUT ipcCustNumber,
                                              INPUT ipiWareHouseNo,
                                              INPUT "",
                                              INPUT SELLING-PRC,
                                              OUTPUT orderTaxArray).
         
            IF VALID-OBJECT(itemJsonObj) THEN
              itemJsonObj:ADD(INPUT "item_tax_unit", INPUT orderTaxArray).
            
             itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(cPackSize),"'", "") ).
             itemJsonObj:ADD(INPUT "pallet_quantity":U,      INPUT REPLACE(STRING(cPalletQuantity),"'", "") ).
            /* Find minimum price of item if SalesRep is allowed to modify the price on mobile app*/
          /*  FIND FIRST cinv3 WHERE CINV3.ITEM-NUMBER  EQ cItemNumber 
                                and CINV3.price-list  EQ "Z" NO-LOCK NO-ERROR.
                                
            IF AVAILABLE CINV3 THEN 
                ASSIGN ldMinPrice = CINV3.BREAK-PRICE.
            ELSE 
                ASSIGN ldMinPrice= 0. */
          
            IF cusertype = "mobileuser":u THEN 
            DO:
                ldMinPrice = THIS-OBJECT:FindLowPrice(INPUT ipcCompanyCode,
                                                      INPUT ipcCustNumber,
                                                      INPUT cItemNumber,
                                                      INPUT IF AVAILABLE CCSMS THEN CCSMS.DISC-PERC ELSE 0 ).
                itemJsonObj:ADD(INPUT "min_price":U,      INPUT ldMinPrice).
                lcallPrice = "".
                
                
                FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = ipcCompanyCode
                               AND PARAMFL.PARAM-ID     = "show-all-cinv3"
                               AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
                if available PARAMFL AND CCSMS.CONTRACT-IND NE "A" then 
                DO:
                    
                   lcallPrice = THIS-OBJECT:FindAllItemPrice(INPUT ipcCompanyCode,
                                                             INPUT ipcCustNumber,
                                                             INPUT cItemNumber,
                                                             INPUT IF AVAILABLE CCSMS THEN CCSMS.DISC-PERC ELSE 0 ). 
                   lcallPrice = STRING(SELLING-PRC) + "|" +  lcallPrice. 
                                                                             
                   itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT lcallPrice). 
                END.
                ELSE 
                 itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT STRING(SELLING-PRC)).                      
            END.
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
            
/*            IF cusertype = "mobileuser":u THEN                                            */
/*            DO:                                                                           */
/*                itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).*/
/*                itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]).*/
/*                itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]).*/
/*                itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]).*/
/*                itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).*/
/*                itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).        */
/*                itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).  */
/*                itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty).  */
/*            END.                                                                          */
            itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).
            itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).  
            itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).
            itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]). 
            itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).
            itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]). 
            itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).
            itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]). 
            itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).
            itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).
            itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).  
            itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).
            itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty). 
            itemJsonObj:ADD(INPUT "has_offer":U,             INPUT ldHasOffer).
            itemJsonArray:ADD(INPUT itemJsonObj).
                                                   
          END. /* REPEAT: */
         
        END. /* IF NOT ERROR-STATUS:ERROR THEN */ 
            
      END. /* FOR EACH ttIndexTable.. */
    
    END. /* DO iCount = 1 TO NUM-ENTRIES(cNonASCIIString) */
    
    ASSIGN 
      oplcSearchData = itemJsonArray:GetJsonText().       
    
    IF itemJsonArray:LENGTH EQ 0 THEN
    DO:
      /* Get multilingual message when no record found for search criteria */
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200NoProductFound,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
        
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).  
    END. /* IF itemJsonArray:LENGTH EQ 0 THEN */   
      
    /* Provide error message, if any */
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).  
    END CATCH.
   
    FINALLY:
      
      INPUT CLOSE.
        
      IF VALID-HANDLE(hQuery) THEN
      DO:
        hQuery:QUERY-CLOSE.
        DELETE OBJECT hQuery.
      END.
  
      IF VALID-HANDLE(hBuffer) THEN
        DELETE OBJECT hBuffer.  
      
      IF VALID-OBJECT(itemJsonArray) THEN
        DELETE OBJECT itemJsonArray.
      
      IF VALID-OBJECT(objCommonSrc) THEN
        DELETE OBJECT objCommonSrc.
          
      IF VALID-OBJECT(objCustProductsPrice) THEN
        DELETE OBJECT objCustProductsPrice.
      
      IF VALID-OBJECT(itemJsonObj) THEN
        DELETE OBJECT itemJsonObj.
     
      IF VALID-OBJECT(prodInfoObj) THEN
        DELETE OBJECT prodInfoObj.
     
      IF VALID-OBJECT(prodInfoArr) THEN
        DELETE OBJECT prodInfoArr. 
      
      IF VALID-OBJECT(pictureJsonArr) THEN
        DELETE OBJECT pictureJsonArr.  
      
      IF VALID-OBJECT(orderTaxArray) THEN
        DELETE OBJECT orderTaxArray.
        
      IF VALID-OBJECT(objOrderTax) THEN
        DELETE OBJECT objOrderTax.        
    END FINALLY.
                     
  END METHOD.
  
  /*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID getAllProducts(INPUT ipcSalesRepId  AS CHARACTER,
                                    INPUT ipcCompanyCode AS CHARACTER,
                                    INPUT ipiWareHouseNo AS INTEGER,
                                    OUTPUT itemJsonArray AS JsonArray,
                                    OUTPUT opcError      AS CHARACTER):
      
    
    DEFINE VARIABLE objCustProductsPrice AS CLASS     ProductPrices     NO-UNDO.
        
    DEFINE VARIABLE itemInfoObj          AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE itemFilterObj        AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE customerItemObj      AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE moreProdInfoObj      AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE itemInfoArray        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE moreProdInfoArr      AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE sizeJsonArr          AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE colorJsonArr         AS CLASS     JsonArray         NO-UNDO.

    DEFINE VARIABLE cPriceList           AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE Selling-PRC          AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE BASE-PRC             AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deQtyOnHand          AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE lByColor             AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE SHIP-NO              AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE QTY-FULL             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE QTY-UNIT             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE ldMinPrice           AS DECIMAL NO-UNDO.
    DEFINE VARIABLE lcallPrice AS CHARACTER NO-UNDO.
    
    ASSIGN 
      itemJsonArray        = NEW JsonArray()
      objCustProductsPrice = NEW ProductPrices(INPUT cToken).
           
    FOR /*FIRST*/ EACH CCSMS WHERE CCSMS.SALES-REP-ID EQ ipcSalesRepId NO-LOCK :
      
      ASSIGN 
        customerItemObj = NEW JsonObject()
        itemInfoArray   = NEW JsonArray ().
             
      customerItemObj:Add(INPUT "customer_number", INPUT CCSMS.CUST-NUMBER).
      customerItemObj:Add(INPUT "name", INPUT REPLACE(CCSMS.CUST-NAME,"'", "") ).
      
      FOR EACH CINV1 WHERE NOT ( CINV1.ITEM-NUMBER BEGINS "A*":U OR CINV1.ITEM-NUMBER BEGINS "1*":U OR CINV1.LINE-UP NE "D" OR CINV1.LINE-UP NE "W":U OR CINV1.LINE-UP NE "X":U ) 
                       AND CINV1.ITEM-NUMBER BEGINS ipcCompanyCode NO-LOCK:
      
        IF  CINV1.LINE-UP EQ "D" THEN NEXT.  
        
         FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"
                                 AND PARAMFL.COMPANY-CODE = ipcCompanyCode
                                 AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.
            IF AVAILABLE paramfl THEN
            DO:
                FIND FIRST CINV2
                WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
                AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.
                IF AVAILABLE CINV2 THEN
                DO:
                  IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN NEXT.
                END.
            END.
            
        ASSIGN 
          itemInfoObj     = NEW JsonObject()
          itemFilterObj   = NEW JsonObject()              
          moreProdInfoArr = NEW JsonArray ()
          sizeJsonArr     = NEW JsonArray ()
          colorJsonArr    = NEW JsonArray ()
          lByColor        = CINV1.BY-COLOR.
        /* This code is to check if any customer has contract pricing. Requested by SabaTier */
        IF CCSMS.CONTRACT-IND EQ "A" THEN 
        DO:
           IF NOT CAN-FIND(CINV3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER AND CINV3.PRICE-LIST EQ CCSMS.PRICE-LIST ) THEN NEXT.
           
        END.      
         
        lcDescription = REPLACE(CINV1.DESCRIPTION,"'", "").
        lcDescription = REPLACE(lcDescription,'"', '').
        lcDescription = REPLACE(lcDescription,"/", "").
        lcDescription = REPLACE(lcDescription,"\", "").
        
        itemInfoObj:add(INPUT "item_number",      INPUT CINV1.ITEM-NUMBER).
        itemInfoObj:add(INPUT "item_description", INPUT lcDescription ). //REPLACE(CINV1.DESCRIPTION,"'", "")). 
        itemInfoObj:ADD(INPUT "category_id":U,    INPUT CINV1.CLASS-CODE).
        itemInfoObj:ADD(INPUT "family_code":U,    INPUT CINV1.FAMILY).      
        /* Assign value of quantity on hand of specific item */
        FIND FIRST CINV2 
          WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
          AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.
        IF AVAILABLE CINV2 THEN
          ASSIGN deQtyOnHand = CINV2.QTY-ONHAND . //CINV2.QTY-ONHAND - CINV2.QTY-COMMITED. 
          
        IF deQtyOnHand GT 0 THEN
            itemInfoObj:add(INPUT "qty_on_hand", INPUT deQtyOnHand).
        ELSE 
            itemInfoObj:add(INPUT "qty_on_hand", INPUT 0).  
     
        /*By-calling getPrice() method ,  assign selling-price of a specific Item corresponding to a specific customer */
        
        FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
        IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
          ASSIGN cPriceList = SHPTO.PRICE-LIST.
        ELSE
          ASSIGN cPriceList = CCSMS.PRICE-LIST.   
         
                    
        objCustProductsPrice:getProductPrices(INPUT '1',
                                              INPUT CCSMS.CUST-NUMBER,
                                              INPUT CINV1.ITEM-NUMBER,
                                              INPUT YES,
                                              INPUT CCSMS.DISC-PERC, 
                                              OUTPUT SELLING-PRC,
                                              OUTPUT BASE-PRC,
                                              INPUT  SHIP-NO,
                                              INPUT  QTY-FULL,
                                              INPUT QTY-UNIT,
                                              INPUT cPriceList,
                                              INPUT ipcCompanyCode).
                                                   
        /*PriceChange objCustProductsPrice:getPrice(INPUT CCSMS.CUST-NUMBER, 
          INPUT CINV1.ITEM-NUMBER,
          INPUT ipcCompanyCode,       
          INPUT CCSMS.DISC-PERC,                     
          INPUT cPriceList, 
          INPUT  YES,
          INPUT  CCSMS.CONTRACT-IND,
          INPUT  CCSMS.SPEC-DICT-I,
          INPUT  CCSMS.QTY-BRK-CD,
          INPUT  CCSMS.CUST-TYPE,           
          OUTPUT SELLING-PRC,      
          OUTPUT BASE-PRC ). */
        
        itemInfoObj:add(INPUT "price", INPUT SELLING-PRC).   
        
       /* FIND FIRST cinv3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER NO-LOCK NO-ERROR.
        IF AVAILABLE CINV3 THEN 
          ASSIGN ldMinPrice = CINV3.BREAK-PRICE.
        ELSE 
          ASSIGN ldMinPrice= 0. */
        IF cusertype = "mobileuser":u THEN
        DO:   
           ldMinPrice = THIS-OBJECT:FindLowPrice(INPUT ipcCompanyCode,
                                                 INPUT CCSMS.CUST-NUMBER,
                                                 INPUT CINV1.ITEM-NUMBER,
                                                 INPUT CCSMS.DISC-PERC ).
                                                 
           itemInfoObj:ADD(INPUT "min_price":U,      INPUT ldMinPrice).
            lcallPrice = "".
          
           FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = ipcCompanyCode
                               AND PARAMFL.PARAM-ID     = "show-all-cinv3"
                               AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
          if available PARAMFL AND CCSMS.CONTRACT-IND NE "A" THEN 
          DO:
             
             lcallPrice = THIS-OBJECT:FindAllItemPrice(INPUT ipcCompanyCode,
                                                       INPUT CCSMS.CUST-NUMBER,
                                                       INPUT CINV1.ITEM-NUMBER,
                                                       INPUT CCSMS.DISC-PERC ). 
           lcallPrice = STRING(SELLING-PRC) + "|" + lCallPrice.                                                  
           itemInfoObj:ADD(INPUT "item_all_price":U,      INPUT lcallPrice). 
           END.
           ELSE 
           itemInfoObj:ADD(INPUT "item_all_price":U,      INPUT STRING(SELLING-PRC)).  
        END.                            
      
        IF CINV1.BY-SIZE OR lByColor THEN
        DO: 
          FOR EACH size WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo AND SIZE.ITEM-NUMBER EQ CINV1.ITEM-NUMBER NO-LOCK:
            moreProdInfoObj = NEW jsonObject ().
            
            IF size.size NE "":U THEN 
              sizeJsonArr:ADD(INPUT size.size).
            
            IF lByColor AND size.Description NE "":U THEN   
              colorJsonArr:ADD(INPUT REPLACE(SIZE.Description,"'", "") ).
	        
            
            moreProdInfoObj:ADD(INPUT "size",       INPUT size.size).
            moreProdInfoObj:ADD(INPUT "color",      INPUT REPLACE(SIZE.Description,"'", "")).
            moreProdInfoObj:ADD(INPUT "in_stock",   INPUT (SIZE.QTY-ONHAND - SIZE.QTY-COMMITED)).
            moreProdInfoObj:ADD(INPUT "unit_price", INPUT SELLING-PRC).
            
            moreProdInfoArr:ADD(INPUT moreProdInfoObj).
                      
          END. /* FOR EACH size...*/
        END. /* IF iplSize EQ YES THEN */
        
        IF moreProdInfoArr:LENGTH EQ 0 THEN
        DO:
          ASSIGN 
            moreProdInfoObj = NEW jsonObject ().
            
          moreProdInfoObj:ADD(INPUT "size":U,  INPUT 'Not Applicable':U).
          moreProdInfoObj:ADD(INPUT "color":U, INPUT 'Not Applicable':U).
          moreProdInfoObj:ADD(INPUT "in_stock":U, INPUT deQtyOnHand).
          moreProdInfoObj:ADD(INPUT "unit_price":U, INPUT SELLING-PRC).
          moreProdInfoArr:ADD(INPUT moreProdInfoObj).
        
        END. /* IF moreProdInfoArr:LENGTH EQ 0 */
        
        itemFilterObj:ADD(INPUT "size":U,   INPUT sizeJsonArr).
        itemFilterObj:ADD(INPUT "color":U,  INPUT colorJsonArr).
           
        itemInfoObj:ADD(INPUT "more_product_data":U, INPUT moreProdInfoArr).
        itemInfoObj:ADD(INPUT "item_filters":U,      INPUT itemFilterObj).
                       
        itemInfoArray:Add(itemInfoObj).
        
      END. /* FOR EACH CINV1..*/         
      customerItemObj:Add(INPUT "all_products", INPUT itemInfoArray).
      itemJsonArray:Add(customerItemObj).
      
    END. /* FOR EACH CCSMS..*/
        
    
    //itemJsonArray:WriteFile("D:\src\all_items.txt").
       
    /* Provide error message, if any */
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).  
    END CATCH. 
           
    /* Delete objects instances */
    FINALLY:

      IF VALID-OBJECT(moreProdInfoArr) THEN
        DELETE OBJECT moreProdInfoArr. 
         
      IF VALID-OBJECT(moreProdInfoObj) THEN
        DELETE OBJECT moreProdInfoObj.
      
      IF VALID-OBJECT(itemInfoObj) THEN
        DELETE OBJECT itemInfoObj.
      
      IF VALID-OBJECT(itemFilterObj) THEN
        DELETE OBJECT itemFilterObj.
                                      
      IF VALID-OBJECT(customerItemObj) THEN
        DELETE OBJECT customerItemObj.                                 
                                      
      IF VALID-OBJECT(itemInfoArray) THEN
        DELETE OBJECT itemInfoArray.
         
      IF VALID-OBJECT(sizeJsonArr) THEN
        DELETE OBJECT sizeJsonArr.
       
      IF VALID-OBJECT(colorJsonArr) THEN
        DELETE OBJECT colorJsonArr.        
                                      
    END FINALLY. /* Finally block */
           
  END METHOD.
  
  
  /*----------------------------------------------------------------------------------------------------
   Purpose: This method shows Category records along with their sub-category records and their filters 
            by calling populateSubcat(..) 
   
   Input-Parameter: 1.ipcCatId   - Category Id.
                    
   Output Parameter: 1.opcError      - errors if any.                         
                     2.oplcSetupJSON - JSON response.          
   -----------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getData(INPUT  ipcCatId       AS CHARACTER,
                             INPUT  ipcCompanyCode AS CHARACTER,
                             INPUT  ipiWareHouseNo AS INTEGER,
                             OUTPUT opcError       AS CHARACTER,
                             OUTPUT oplcSetupJSON  AS LONGCHAR ):
     
     
    /* Define jsonArray which are used in this method */   
    DEFINE VARIABLE catLevelJsonArr  AS CLASS     jsonArray  NO-UNDO.
    DEFINE VARIABLE catLevel1JsonArr AS CLASS     jsonArray  NO-UNDO.
    DEFINE VARIABLE catLevel2JsonArr AS CLASS     jsonArray  NO-UNDO.
    DEFINE VARIABLE catLevel3JsonArr AS CLASS     jsonArray  NO-UNDO.
    DEFINE VARIABLE catLevel4JsonArr AS CLASS     jsonArray  NO-UNDO.
    DEFINE VARIABLE catLevel5JsonArr AS CLASS     jsonArray  NO-UNDO.

    /* Define jsonObject which are used in this method */   
    DEFINE VARIABLE setUpJsonObj     AS CLASS     jsonObject NO-UNDO.
    DEFINE VARIABLE subCatJsonObj    AS CLASS     jsonObject NO-UNDO.
   
    DEFINE VARIABLE cParentID        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDescription     AS CHARACTER NO-UNDO.
                 
    /* Initialise jsonObject()*/  
    ASSIGN 
      setUpJsonObj  = NEW jsonObject()
      subCatJsonObj = NEW jsonObject().
    
    /* Initialise jsonArray()*/  
    ASSIGN 
      catLevelJsonArr  = NEW jsonArray()
      catLevel1JsonArr = NEW jsonArray()
      catLevel2JsonArr = NEW jsonArray()
      catLevel3JsonArr = NEW jsonArray()
      catLevel4JsonArr = NEW jsonArray()
      catLevel5JsonArr = NEW jsonArray(). 

    /* If value of ipCatId is "*" then shows all Category along with their sub-category, filters and items record.*/    
    IF  ipcCatId EQ "*":U THEN
      ASSIGN cParentID = "":U.            
    ELSE 
      ASSIGN cParentID = "*":U. 
      
    /* Establish parent-child relationship between category and Shows category along with their subcategory, filters and items records */ 
   /* FOR EACH CINV1 WHERE CINV1.COMPANY-CODE = ipcCompanyCode USE-INDEX CLASS-KEY NO-LOCK: */
        
    
       FOR EACH ivbrand WHERE (ivbrand.class-code EQ ipcCatId) 
                            OR (ivbrand.parent-cat EQ cParentID) NO-LOCK : 
        
                            
      /* FOR EACH ivbrand WHERE ivbrand.class-code EQ CINV1.CLASS-CODE NO-LOCK :  */       
          IF ivbrand.class-code EQ "":U THEN
            NEXT.
          IF  ivbrand.hide-in-wm-apps EQ "Y" THEN NEXT.
          ASSIGN 
            ipcCatId     = IVBRAND.CLASS-CODE
            cDescription = REPLACE(IVBRAND.DESCRIPTION,"'", "") 
            cParentID    = IVBRAND.parent-cat.
              
          FOR EACH bufIvbrand1 WHERE bufIvbrand1.Parent-cat EQ ivbrand.class-code NO-LOCK : 
                                        
            FOR EACH bufIvbrand2 WHERE bufIvbrand2.Parent-cat EQ bufIvbrand1.class-code NO-LOCK : 
                                            
              FOR EACH bufIvbrand3 WHERE bufIvbrand3.Parent-cat EQ bufIvbrand2.class-code NO-LOCK : 
                                                  
                FOR EACH bufIvbrand4 WHERE bufIvbrand4.Parent-cat EQ bufIvbrand3.class-code NO-LOCK : 
                                                     
                  /* 5-Level */
                  /* Shows 5-level Category and their Filters and items record */  
                  IF  bufIvbrand4.hide-in-wm-apps EQ "Y" THEN NEXT.
                      
                  THIS-OBJECT:populateSubcat(INPUT  bufIvbrand4.class-code,
                                             INPUT  REPLACE(bufIvbrand4.DESCRIPTION,"'", ""),
                                             INPUT  bufIvbrand4.parent-cat,
                                             INPUT  ipcCompanyCode,
                                             INPUT  ipiWareHouseNo,
                                             OUTPUT subCatJsonObj,
                                             INPUT-OUTPUT catLevelJsonArr ).
                  
                  /* Condition used to add only those categories which contains items related to logged in company */
                  IF subCatJsonObj:Has(INPUT "filter":U) OR subCatJsonObj:GetLogical(INPUT "isDepartment":U) THEN                                  
                    catLevel5JsonArr:ADD(INPUT subCatJsonObj). 
                
                END. /* END OF FOR EACH bufIvbrand4..*/
      
                /* 4-Level */
                /* Shows 4-level Category and their Filters and items record. 
                   Here catLevel5JsonArr jsonArray add as a subCategory of 4-level Category  */
                IF  bufIvbrand3.hide-in-wm-apps EQ "Y" THEN NEXT.  
                THIS-OBJECT:populateSubcat(INPUT  bufIvbrand3.class-code,
                                           INPUT  REPLACE(bufIvbrand3.DESCRIPTION,"'", "") ,
                                           INPUT  bufIvbrand3.parent-cat,
                                           INPUT  ipcCompanyCode,
                                           INPUT  ipiWareHouseNo,
                                           OUTPUT subCatJsonObj,
                                           INPUT-OUTPUT catLevel5JsonArr ).
                
                /* Condition used to add only those categories which contains items related to logged in company */
                IF subCatJsonObj:Has(INPUT "filter":U) OR subCatJsonObj:GetLogical(INPUT "isDepartment":U) THEN                                    
                  catLevel4JsonArr:ADD(INPUT subCatJsonObj).    
                         
              END.  /* END OF FOR EACH bufIvbrand3 */ 
            
              /* 3-Level*/
              /* Shows 3-level Category and their Filters and items record.
                 Here catLevel4JsonArr jsonArray add as a subCategory of 3-level Category  */ 
               IF  bufIvbrand2.hide-in-wm-apps EQ "Y" THEN NEXT.  
              THIS-OBJECT:populateSubcat(INPUT  bufIvbrand2.class-code,
                                         INPUT  REPLACE(bufIvbrand2.DESCRIPTION,"'", ""),
                                         INPUT  bufIvbrand2.parent-cat,
                                         INPUT  ipcCompanyCode,
                                         INPUT  ipiWareHouseNo,
                                         OUTPUT subCatJsonObj,
                                         INPUT-OUTPUT catLevel4JsonArr ).
              
              /* Condition used to add only those categories which contains items related to logged in company */                           
              IF subCatJsonObj:Has(INPUT "filter":U) OR subCatJsonObj:GetLogical(INPUT "isDepartment":U) THEN                   
                catLevel3JsonArr:ADD(INPUT subCatJsonObj).          
                          
            END.  /* END OF bufIvbrand2.. */
       
            /* 2-Level*/
            /* Shows 2-level Category and their Filters and items record.
               Here catLevel3JsonArr jsonArray add as a subCategory of 2-level Category */
            IF  bufIvbrand1.hide-in-wm-apps EQ "Y" THEN NEXT.   
            THIS-OBJECT:populateSubcat(INPUT  bufIvbrand1.class-code,
                                       INPUT  REPLACE(bufIvbrand1.DESCRIPTION,"'", ""),
                                       INPUT  bufIvbrand1.parent-cat,
                                       INPUT  ipcCompanyCode,
                                       INPUT  ipiWareHouseNo,
                                       OUTPUT subCatJsonObj,
                                       INPUT-OUTPUT catLevel3JsonArr ).
            
            /* Condition used to add only those categories which contains items related to logged in company */
            IF subCatJsonObj:Has(INPUT "filter":U) OR subCatJsonObj:GetLogical(INPUT "isDepartment":U) THEN                     
              catLevel2JsonArr:ADD(INPUT subCatJsonObj).
                
          END.   /* END OF FOR EACH bufIvbrand1 */   
      
          /* 1-Level*/
          /* Shows 1-level Category and their Filters and items record.
             Here catLevel2JsonArr jsonArray add as a subCategory of 1-level Category */
             
          THIS-OBJECT:populateSubcat(INPUT  ipcCatId,
                                     INPUT  REPLACE(cDescription,"'", "") ,
                                     INPUT  cParentID,
                                     INPUT  ipcCompanyCode,
                                     INPUT  ipiWareHouseNo,
                                     OUTPUT subCatJsonObj,
                                     INPUT-OUTPUT catLevel2JsonArr).
          
          /* Condition used to add only those categories which contains items related to logged in company */                           
          IF subCatJsonObj:Has(INPUT "filter":U) OR subCatJsonObj:GetLogical(INPUT "isDepartment":U) THEN                    
            catLevel1JsonArr:ADD(INPUT subCatJsonObj). 
                   
        END. /*  FOR EACH IVBRAND.. */ 
    /* END. */
    setUpJsonObj:ADD(INPUT "categories":U, INPUT catLevel1JsonArr). 
    
    ASSIGN 
      oplcSetupJSON = setUpJsonObj:GetJsonText().
     
    /* Provide error message, if any */
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).   
    END CATCH. 
    
    /* Delete all objects instances */
      
    FINALLY:
     
      IF VALID-OBJECT(setUpJsonObj)     THEN
        DELETE OBJECT setUpJsonObj.
      
      IF VALID-OBJECT(subCatJsonObj)    THEN
        DELETE OBJECT subCatJsonObj.
        
      IF VALID-OBJECT(catLevel1JsonArr) THEN
        DELETE OBJECT catLevel1JsonArr.
        
      IF VALID-OBJECT(catLevel2JsonArr) THEN
        DELETE OBJECT catLevel2JsonArr.
        
      IF VALID-OBJECT(catLevel3JsonArr) THEN
        DELETE OBJECT catLevel3JsonArr.
        
      IF VALID-OBJECT(catLevel4JsonArr) THEN
        DELETE OBJECT catLevel4JsonArr.
        
      IF VALID-OBJECT(catLevel5JsonArr) THEN
        DELETE OBJECT catLevel5JsonArr.
        
      IF VALID-OBJECT(catLevelJsonArr)  THEN
        DELETE OBJECT catLevelJsonArr.
        
    END FINALLY. /* Finally block */
 
  END METHOD. /*  getData(..) */  
  
  /*--------------------------------------------------------------------------------------------------------
     Purpose:This method is used to display items in the items recommended by your purchasing history
     Input  Parameter:1.ipcCustNumber  - customer number 
                      2.ipcCompany     - company code which is used to display items which begins with this
                      3.ipiWareHouseNo - warehouse no for the logged in company.
                       
     Output Parameter:1.oplcPurchaseData - It contains the items to be displayed in recommended 
                                           by purchasing history
  ------------------------------------------------------------------------------------------------------------*/ 
  METHOD PUBLIC VOID inspiredByPurchasingHistory(INPUT ipcCustNumber     AS CHARACTER,
                                                 INPUT ipcCompany        AS CHARACTER,
                                                 INPUT ipiWareHouseNo    AS INTEGER,
                                                 OUTPUT opcError         AS CHARACTER,
                                                 OUTPUT oplcPurchaseData AS LONGCHAR):
                                                                         
    //DEFINE VARIABLE classcode  LIKE ivbrand.CLASS-CODE.
    DEFINE VARIABLE objOrderTax          AS CLASS     OrderTaxes        NO-UNDO.
    DEFINE VARIABLE orderTaxArr          AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE objcustomerorder     AS CLASS     customerorders    NO-UNDO.
    
    DEFINE VARIABLE cCustType            AS CHARACTER NO-UNDO. 
    DEFINE VARIABLE cItemNumber          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSourceDir           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemImage           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileType            AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPriceList           AS CHARACTER NO-UNDO.
     
    DEFINE VARIABLE iSaleHistoryDays     AS INTEGER   NO-UNDO.
    DEFINE VARIABLE iarrayIndex          AS INTEGER   NO-UNDO.
    
    DEFINE VARIABLE deSellingPrc         AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deBasePrc            AS DECIMAL   NO-UNDO.
           
    DEFINE VARIABLE lCheck               AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE SHIP-NO              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE QTY-FULL             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE QTY-UNIT             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE iRecCount            AS INTEGER                  NO-UNDO.
      
    DEFINE VARIABLE objCustProductsPrice AS CLASS     ProductPrices     NO-UNDO.
    DEFINE VARIABLE itemJsonArray        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE prodInfoArray        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE itemPictureArray     AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE prodInfoObj          AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE itemJsonObj          AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE ldMinPrice           AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldUptoQty            AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldUptoQtyPrice       AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldPercent            AS DECIMAL          NO-UNDO.
    DEFINE VARIABLE ldbuyforFreeQty      AS DECIMAL          NO-UNDO.
    DEFINE VARIABLE ldgetforFreeQty      AS DECIMAL          NO-UNDO.
    DEFINE VARIABLE ldHasOffer           AS CHARACTER        NO-UNDO.
    DEFINE VARIABLE lcItemInthearray     AS CHARACTER        NO-UNDO.
    DEFINE VARIABLE lcallPrice           AS CHARACTER        NO-UNDO.   
    DEFINE VARIABLE cDomain              AS CHARACTER        NO-UNDO.
    DEFINE VARIABLE byitem               AS LOGICAL          NO-UNDO.
    DEFINE VARIABLE liQtyonHand          AS INT64          NO-UNDO.
    DEFINE VARIABLE liCommitQty          AS INT64            NO-UNDO.
    ASSIGN 
      itemJsonArray        = NEW JsonArray()
      orderTaxArr          = NEW JsonArray()
      objOrderTax          = NEW OrderTaxes(INPUT cToken)
      objCustProductsPrice = NEW ProductPrices(INPUT cToken)
      objcustomerorder     = NEW customerorders(INPUT cToken).
           
   
    /*Currently there is no transaction record available in csahf with
      iSaleHistoryDays = 180 days before today's date thats why using 2000 */
      
    FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = ipcCompany
                   AND PARAMFL.PARAM-ID     = "SALE-HISTORY-DAYS":U
                   AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR.
                   
    IF AVAILABLE PARAMFL THEN
      ASSIGN iSaleHistoryDays = INTEGER(PARAMFL.PARAM-VALUE1).
    ELSE
      ASSIGN iSaleHistoryDays = 180.
    

    purchasingHistBlock:
    DO:                       
      FIND CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR .
      
      IF AVAILABLE CCSMS THEN
      DO:
        ASSIGN 
          cCustType = CCSMS.CUST-TYPE.
        
        FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
        IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
          ASSIGN cPriceList = SHPTO.PRICE-LIST.
        ELSE
          ASSIGN cPriceList = CCSMS.PRICE-LIST.
                              
        FOR EACH CSAHF WHERE CSAHF.CUST-NUMBER     EQ CCSMS.CUST-NUMBER  
                         AND CSAHF.ITEM-NUMBER     BEGINS ipcCompany
                         AND CSAHF.INVOICE-DATE    GE (TODAY - iSaleHistoryDays)
                         AND CSAHF.QTY-SHIPPED     NE 0               
                         AND NOT CSAHF.ITEM-NUMBER BEGINS ipcCompany + "*":U
                         AND CSAHF.CLASS-CODE      NE "":U NO-LOCK BREAK BY CSAHF.INVOICE-DATE DESCENDING :
          
          iRecCount = iRecCount + 1. 
          IF iRecCount GT 5 THEN LEAVE. 
          if index(lcItemInthearray,string(CSAHF.ITEM-NUMBER)) GT 0 THEN 
            NEXT.
          else 
           lcItemInthearray = lcItemInthearray + string(CSAHF.ITEM-NUMBER). 
          FIND CINV1 WHERE CINV1.ITEM-NUMBER = CSAHF.ITEM-NUMBER
                       AND CINV1.HIDE-IN-WM-APPS <> "Y" 
                       AND (CINV1.LINE-UP NE "D" OR CINV1.LINE-UP NE "W":U OR CINV1.LINE-UP NE "X":U ) NO-LOCK NO-ERROR.
          IF AVAILABLE CINV1 AND CINV1.LINE-UP NE "D" THEN
          DO: 
            ASSIGN 
              lCheck = FALSE.
            
            
/*            FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"*/
/*                                 AND PARAMFL.COMPANY-CODE = ipcCompany                   */
/*                                 AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.        */
/*            IF AVAILABLE paramfl THEN                                                    */
/*            DO:                                                                          */
/*                FIND FIRST CINV2                                                         */
/*                WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER                            */
/*                AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.             */
/*                IF AVAILABLE CINV2 THEN                                                  */
/*                DO:                                                                      */
/*                  IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN NEXT.               */
/*                END.                                                                     */
/*            END.                                                                         */
                              
            /********************************************************/
            /* VERIFY IF CUSTOMER SALES RECORD EXIST                */
            /********************************************************/        
            IF itemJsonArray:LENGTH NE 0 THEN
            item_blk:  
            DO iarrayIndex = 1 TO itemJsonArray:LENGTH:
              
              ASSIGN 
                itemJsonObj = itemJsonArray:GetJsonObject(INPUT iarrayIndex).
            
              IF itemJsonObj:Has(INPUT "item_number":U) THEN
              DO:
                IF CSAHF.ITEM-NUMBER EQ itemJsonObj:GetCharacter(INPUT "item_number":U) THEN
                DO:
                  ASSIGN 
                    lCheck = TRUE.
                  LEAVE item_blk.            
                END. /* IF CSAHF.ITEM-NUMBER EQ itemJsonObj:GetCharacter(INPUT "item_number":U) THEN*/
                 
              END. /* IF itemJsonObj:Has(INPUT "item_number":U) THEN */
                      
            END. /* IF itemJsonArray:LENGTH NE 0 THEN */
                
            IF NOT lCheck THEN
            DO:
              ASSIGN 
                itemJsonObj      = NEW JsonObject()
                itemPictureArray = NEW JsonArray()
                prodInfoArray    = NEW JsonArray().  
              
              /* Get the prices of items */            
              objCustProductsPrice:getProductPrices(INPUT '0',
                                                    INPUT CCSMS.CUST-NUMBER,
                                                    INPUT CINV1.ITEM-NUMBER,
                                                    INPUT YES,
                                                    INPUT CCSMS.DISC-PERC, 
                                                    OUTPUT deSellingPrc,
                                                    OUTPUT deBasePrc,
                                                    INPUT  SHIP-NO,
                                                    INPUT  QTY-FULL,
                                                    INPUT QTY-UNIT,
                                                    INPUT cPriceList,
                                                    INPUT ipcCompany).
              
                            
              IF CINV1.BY-SIZE OR CINV1.BY-COLOR THEN
              DO:                 
                FOR EACH size WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo AND SIZE.ITEM-NUMBER EQ CSAHF.ITEM-NUMBER NO-LOCK:
                  ASSIGN 
                    prodInfoObj = NEW jsonObject ().
                  
                  prodInfoObj:ADD(INPUT "size",       INPUT if size.size NE "" then size.size ELSE 'Not Applicable':U).
                  prodInfoObj:ADD(INPUT "color",      INPUT IF SIZE.DESCRIPTION NE "" THEN REPLACE(SIZE.DESCRIPTION,"'", "")  ELSE 'Not Applicable':U).
                  if SIZE.QTY-ONHAND - SIZE.QTY-COMMITED NE ? then 
                  prodInfoObj:ADD(INPUT "in_stock",   INPUT (SIZE.QTY-ONHAND - SIZE.QTY-COMMITED)).
                  else 
                  prodInfoObj:ADD(INPUT "in_stock",   INPUT (0)).
                  prodInfoObj:ADD(INPUT "unit_price", INPUT deSellingPrc).
                  //prodInfoObj:ADD(INPUT "unit_price", INPUT CSAHF.PRICE).
                  prodInfoArray:ADD(INPUT prodInfoObj).
                        
                END. /* FOR EACH size...*/
                
              END. /* IF CINV1.BY-SIZE THEN */
              
              /* If the records of that item exists in CINV2 then assign value 
                 of qty_on_hand of specific item from CINV2 else from CINV1 */
              FIND FIRST CINV2 
                WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
                AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.
                   
              IF prodInfoArray:LENGTH EQ 0 THEN
              DO:
                ASSIGN 
                  prodInfoObj = NEW jsonObject ().
                  
                prodInfoObj:ADD(INPUT "size":U,  INPUT 'Not Applicable':U).
                prodInfoObj:ADD(INPUT "color":U, INPUT 'Not Applicable':U).
                
                
                  
                IF AVAILABLE CINV2 THEN
                DO:
                   
                    liQtyonHand = 0.
                    IF CAN-FIND(FIRST sethd WHERE SETHD.SET-NO EQ CINV2.ITEM-NUMBER) THEN 
                    DO:
                        FOR EACH setdt WHERE SETDT.SET-NO EQ CINV2.ITEM-NUMBER NO-LOCK:
                          FIND FIRST bf-cinv2 WHERE bf-cinv2.ITEM-NUMBER EQ SETDT.ITEM-NUMBER NO-LOCK NO-ERROR.
                          IF AVAILABLE bf-cinv2 THEN 
                          DO:
                  
                             IF liQtyonHand EQ 0 OR liQtyonHand GT bf-CINV2.QTY-ONHAND THEN 
                             ASSIGN liQtyonHand = bf-CINV2.QTY-ONHAND 
                                    liCommitQty = bf-CINV2.QTY-COMMITED.                      
                          END.    
                        END.
                        prodInfoObj:ADD(INPUT "in_stock":U, INPUT liQtyonHand ).
                     END.   
                     ELSE if CINV2.QTY-ONHAND - CINV2.QTY-COMMITED NE ? then 
                     DO:
                       prodInfoObj:ADD(INPUT "in_stock":U, INPUT CINV2.QTY-ONHAND - CINV2.QTY-COMMITED ).
                       liCommitQty = CINV2.QTY-COMMITED.
                     END.  
                     else 
                     DO:
                     prodInfoObj:ADD(INPUT "in_stock":U, INPUT 0 ).
                     liCommitQty = 0.
                     END.
                END.   
                ELSE
                DO:
                  prodInfoObj:ADD(INPUT "in_stock":U, INPUT CINV1.QTY-ONHAND ).
                  liCommitQty = CINV1.QTY-TO-ORDER.
                END.      
                prodInfoObj:ADD(INPUT "unit_price":U, INPUT deSellingPrc).
                prodInfoArray:ADD(INPUT prodInfoObj).
              
              END. /* IF prodInfoArray:LENGTH EQ 0 */
              
              ASSIGN 
                cItemNumber = TRIM(CSAHF.ITEM-NUMBER).
  
              IF cItemNumber MATCHES "*" THEN
                ASSIGN cItemNumber = CAPS(TRIM(REPLACE(cItemNumber, "*", "-") , "-":U)).
       
            /*  FILE-INFO:FILE-NAME = ConstantInitializer:cImageDir + "/":U + cItemNumber.
              IF FILE-INFO:FULL-PATHNAME EQ ? THEN 
              DO:
                 FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
                 IF AVAILABLE paramfl THEN 
                 ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1 
                        FILE-INFO:FILE-NAME =  FILE-INFO:FILE-NAME + "\" + cItemNumber NO-ERROR.
              END.
              
              IF FILE-INFO:FULL-PATHNAME NE ? THEN */
             // cSourceDir = this-object:ImgDirectory(INPUT cItemNumber).
             // Cdomain = THIS-OBJECT:FINDCDN().
              cSourceDir = objcustomerorder:ImgDirectory(INPUT cItemNumber, INPUT ipcCompany, OUTPUT byitem). //this-object:ImgDirectory(INPUT cItemNumber).
              CDomain    = objcustomerorder:FINDCDN(ipcCompany).  //THIS-OBJECT:FINDCDN().
              IF cSourceDir NE "x" THEN 
        
              DO:
                ASSIGN 
                   FILE-INFO:FILE-NAME = cSourceDir.
              
                   cSourceDir = FILE-INFO:FULL-PATHNAME.
              
                INPUT FROM OS-DIR(cSourceDir).
                IF byitem THEN 
                DO:
                   REPEAT:
                         IMPORT cItemImage ^ cFileType.
                         IF cFileType EQ "F":U THEN
                           itemPictureArray:ADD(Cdomain + "/":U + cItemNumber + "/":U + Replace(cItemImage," ","%20")).
                   
                   END. /* REPEAT */    
                
                 END. 
                 ELSE 
                 DO:
                    REPEAT:
                          IMPORT cItemImage ^ cFileType.
                          IF cFileType EQ "F":U AND INDEX(cItemImage , cItemNumber) GT 0 THEN
                          itemPictureArray:ADD(Cdomain + "/":U + Replace(cItemImage," ","%20")).              
                    END. 
                 END.
               END. /* If cSourceDir NE "x" */ 
                
             lcDescription = REPLACE(CINV1.DESCRIPTION,"'", "").
             lcDescription = REPLACE(lcDescription,'"', '').
             lcDescription = REPLACE(lcDescription,"/", "").
             lcDescription = REPLACE(lcDescription,"\", "").
        
              itemJsonObj:ADD(INPUT "item_number":U,       INPUT CSAHF.ITEM-NUMBER).
              itemJsonObj:ADD(INPUT "description":U,       INPUT lcDescription). //REPLACE(CINV1.DESCRIPTION,"'", "") ).
              itemJsonObj:ADD(INPUT "class_code":U,        INPUT CSAHF.CLASS-CODE).      
              itemJsonObj:ADD(INPUT "price":U,             INPUT deSellingPrc).
              itemJsonObj:ADD(INPUT "item_uom":U,          INPUT CINV1.ITEM-UOM).
              itemJsonObj:ADD(INPUT "uom_qty":U,           INPUT CINV1.UOM-QTY).
              itemJsonObj:ADD(INPUT "on_order":U,          INPUT CINV1.QTY-ON-ORDER).
              itemJsonObj:ADD(INPUT "category_id":U,       INPUT CINV1.CLASS-CODE).
               itemJsonObj:ADD(INPUT "family_code":U,      INPUT CINV1.FAMILY).
                                
              IF AVAILABLE CINV2 THEN
              DO:
                 IF CAN-FIND(FIRST sethd WHERE SETHD.SET-NO EQ CINV2.ITEM-NUMBER) THEN 
                 DO:
                    liQtyonHand = 0.
                    IF CAN-FIND(FIRST sethd WHERE SETHD.SET-NO EQ CINV2.ITEM-NUMBER) THEN 
                    DO:
                        FOR EACH setdt WHERE SETDT.SET-NO EQ CINV2.ITEM-NUMBER NO-LOCK:
                          FIND FIRST bf-cinv2 WHERE bf-cinv2.ITEM-NUMBER EQ SETDT.ITEM-NUMBER NO-LOCK NO-ERROR.
                          IF AVAILABLE bf-cinv2 THEN 
                          DO:
                  
                             IF liQtyonHand EQ 0 OR liQtyonHand GT bf-CINV2.QTY-ONHAND THEN 
                             ASSIGN liQtyonHand = bf-CINV2.QTY-ONHAND 
                                    liCommitQty = bf-CINV2.QTY-COMMITED .
                             
                          END.    
                        END.
                        
                        IF liQtyonHand GT 0 THEN
                            itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT liQtyonHand ).
                        ELSE 
                            itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0 ).
                            
                        itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT liCommitQty ).
                     END. 
                 END.     
                ELSE if CINV2.QTY-ONHAND - CINV2.QTY-COMMITED NE ? OR CINV2.QTY-ONHAND - CINV2.QTY-COMMITED GT 0 then  
                DO:
                  IF CINV2.QTY-ONHAND GT 0 THEN 
                    itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT CINV2.QTY-ONHAND ).
                  ELSE 
                    itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0).
                    
                  itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT CINV2.QTY-COMMITED ).
                END.   
                else 
                DO:
                  itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0 ).
                  itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT CINV2.QTY-COMMITED ).
                END.  
              END.
              
              ELSE
              DO:
                IF CINV1.QTY-ONHAND GT 0 THEN
                    itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT CINV1.QTY-ONHAND).
                ELSE 
                    itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0).
                     
                itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT 0).
              END.
              
              IF CINV1.PICTURE NE "":U THEN
              DO:
                FILE-INFO:FILE-NAME = ConstantInitializer:cPDFDir + "/":U + SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1) + ".pdf".
  
                IF FILE-INFO:FULL-PATHNAME NE ? THEN
                DO:
                  /*itemJsonObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + CINV1.PICTURE).*/
                  itemJsonObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1) + ".pdf").
                END.
                
                ELSE
                  itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(CSAHF.ITEM-NUMBER, ipcCompany) ).
                  //itemJsonObj:ADD(INPUT "pdf_link":U, INPUT "").
                
              END.
                
              ELSE
                itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(CSAHF.ITEM-NUMBER, ipcCompany) ).
                //itemJsonObj:ADD(INPUT "pdf_link":U, INPUT "":U).
                
              itemJsonObj:ADD(INPUT "pictures":U,          INPUT itemPictureArray).
              itemJsonObj:ADD(INPUT "more_product_data":U, INPUT prodInfoArray).
               
            END. /* IF NOT lCheck THEN */ 
            
           
                     
            objOrderTax:getItemTaxForShipping(INPUT CINV1.ITEM-NUMBER,
                                              INPUT ipcCompany,
                                              INPUT ipcCustNumber,
                                              INPUT ipiWareHouseNo,
                                              INPUT "",
                                              INPUT deSellingPrc,
                                              OUTPUT orderTaxArr).
            
            IF NOT lCheck THEN
              IF VALID-OBJECT(itemJsonObj) THEN
                itemJsonObj:ADD(INPUT "item_tax_unit", INPUT orderTaxArr).
              ELSE
                IF VALID-OBJECT(itemJsonObj) THEN
                  itemJsonObj:SET(INPUT "item_tax_unit", INPUT orderTaxArr).
                  
             itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
             itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")).     
        /*    FIND FIRST cinv3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER 
                               and CINV3.price-list  EQ "Z" NO-LOCK NO-ERROR.
            IF AVAILABLE CINV3 THEN 
              ASSIGN ldMinPrice = CINV3.BREAK-PRICE.
            ELSE 
             ASSIGN ldMinPrice= 0. */
             
            IF cusertype = "mobileuser":u THEN 
            DO:
                ldMinPrice = THIS-OBJECT:FindLowPrice(INPUT ipcCompany,
                                                 INPUT CCSMS.CUST-NUMBER,
                                                 INPUT CINV1.ITEM-NUMBER,
                                                 INPUT CCSMS.DISC-PERC ).
                                                 
                 itemJsonObj:ADD(INPUT "min_price":U,      INPUT ldMinPrice).
                 lcallPrice = "".
                 
           
                 FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = ipcCompany
                               AND PARAMFL.PARAM-ID     = "show-all-cinv3"
                               AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
                if available PARAMFL AND CCSMS.CONTRACT-IND NE "A" THEN  
                DO:
                    
                   lcallPrice = THIS-OBJECT:FindAllItemPrice(INPUT ipcCompany,
                                                             INPUT CCSMS.CUST-NUMBER,
                                                             INPUT CINV1.ITEM-NUMBER,
                                                             INPUT CCSMS.DISC-PERC ). 
                   lcallprice = STRING(deSellingPrc) + "|" +  lcallprice.                                         
                   itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT lcallPrice). 
               END.  
               ELSE 
                  itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT STRING(deSellingPrc)). 
            END.
            /* Find the discount on item if any */
            FIND FIRST OFERT WHERE OFERT.ITEM-NUMBER EQ CINV1.ITEM-NUMBER  
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
                       
/*             IF cusertype = "mobileuser":u THEN                                           */
/*            DO:                                                                           */
/*                itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).*/
/*                itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]).*/
/*                itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]).*/
/*                itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]).*/
/*                itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).     */
/*                itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).*/
/*                itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).        */
/*                itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).  */
/*                itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty).  */
/*            END.                                                                          */

            itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).
            itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).  
            itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).
            itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]). 
            itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).
            itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]). 
            itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).
            itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]). 
            itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).
            itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).
            itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).  
            itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).
            itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty). 
            itemJsonObj:ADD(INPUT "has_offer":U,             INPUT ldHasOffer).
            
            IF lCheck THEN
              itemJsonArray:Set(INPUT iarrayIndex, INPUT itemJsonObj).
            ELSE
              itemJsonArray:ADD(INPUT itemJsonObj).
                            
          END. /* IF AVAILABLE cinv1 THEN */
               
        END.  /*FOR EACH CSAHF*/
            
      END. /*IF AVAILABLE ccsms THEN*/
    END.
    
    /*DO iarrayIndex = 1 TO itemJsonArray:LENGTH:
      ASSIGN itemJsonObj = itemJsonArray:GetJsonObject(INPUT iarrayIndex).
       
      IF itemJsonObj:Has( INPUT "invoice_date":U) THEN 
      DO:  
        itemJsonObj:Remove(INPUT "invoice_date":U).
        itemJsonArray:Set( INPUT iarrayIndex, INPUT itemJsonObj).
      END.
                                     
    END. /* DO iarrayIndex = 1 TO itemJsonArray:LENGTH */*/
         
    ASSIGN 
      oplcPurchaseData = itemJsonArray:GetJsonText().
     
    
    /* Provide error message, if any */
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).  
    END CATCH. 
        
    /* Delete objects instances */
    FINALLY:
      INPUT CLOSE. 
             
      IF VALID-OBJECT(objCustProductsPrice) THEN
        DELETE OBJECT objCustProductsPrice.
      IF VALID-OBJECT(itemJsonArray)        THEN
        DELETE OBJECT itemJsonArray.
      IF VALID-OBJECT(itemJsonObj)          THEN
        DELETE OBJECT itemJsonObj. 
      IF VALID-OBJECT(prodInfoArray)        THEN
        DELETE OBJECT prodInfoArray. 
      IF VALID-OBJECT(itemPictureArray)     THEN
        DELETE OBJECT itemPictureArray. 
      IF VALID-OBJECT(prodInfoObj)          THEN
        DELETE OBJECT prodInfoObj.           
    END FINALLY.
      
  END METHOD. 
  
  /*------------------------------------------------------------------------------------
   Purpose: This method is used get the list of top selling items in a week/month
            
   Input Parameters:1.ipcFetchCriteria - Top selling items fetching criteria e.g. week/month 
                    2.ipcCustNum       - Selected customer for which the list of 
                                         top selling items have to be populated
                    3.ipcCompanyCode   - logged-in user company code
                    4.ipcToken         - active User-token,
                     
   Output Parameters:1.opcError          - Errors if any,
                     2.oplcTopSellerData - storing top selling items
                                         
   Notes:
   -------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getTopSellerItems(INPUT  ipcCustNumber     AS CHARACTER,                                       
                                       INPUT  ipcCompanyCode    AS CHARACTER,                                      
                                       INPUT  ipiWareHouseNo    AS INTEGER,                                       
                                       OUTPUT opcError          AS CHARACTER,
                                       OUTPUT oplcTopSellerData AS LONGCHAR):
     
    DEFINE VARIABLE objCustProductsPrice AS CLASS     ProductPrices     NO-UNDO.
    DEFINE VARIABLE jsonArrTopSeller     AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE prodInfoArray        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE itemPictureArray     AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE orderTaxArray        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE prodInfoObj          AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE itemJsonObj          AS CLASS     JsonObject        NO-UNDO.   
    DEFINE VARIABLE objOrderTax          AS CLASS     OrderTaxes        NO-UNDO.  
    DEFINE VARIABLE objCustomerOrder     AS CLASS     customerorders    NO-UNDO. 
     
    DEFINE VARIABLE cCustType            AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemNumber          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSourceDir           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemImage           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileType            AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPriceList           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iDayBefore           AS DATE      NO-UNDO.
    DEFINE VARIABLE iCount               AS INTEGER   NO-UNDO.   
    DEFINE VARIABLE deSellingPrc         AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deBasePrc            AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deDiscountPrc        AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE cContractInd         AS CHARACTER NO-UNDO.                    
    DEFINE VARIABLE cSpecDictI           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cQtyBrkCd            AS CHARACTER NO-UNDO.
    DEFINE VARIABLE SHIP-NO              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE QTY-FULL             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE QTY-UNIT             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE ldMinPrice           AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE ldUptoQty            AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldUptoQtyPrice       AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldPercent            AS DECIMAL          NO-UNDO.
    DEFINE VARIABLE ldbuyforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldgetforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldHasOffer           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcallPrice           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDomain              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE byitem               AS LOGICAL  NO-UNDO.
    DEFINE  VARIABLE liQtyonHand         AS INT64 NO-UNDO. 
    DEFINE  VARIABLE liCommitQty         AS INT64 NO-UNDO.
    ASSIGN 
      objCustProductsPrice = NEW ProductPrices(INPUT cToken) 
      jsonArrTopSeller     = NEW JsonArray()
      orderTaxArray        = NEW JsonArray()
      objOrderTax          = NEW OrderTaxes(INPUT cToken)
      objCustomerOrder     = NEW CustomerOrders(INPUT cToken). 
    
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "TOP-SELLING-ITEM":U 
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
    IF AVAILABLE PARAMFL THEN
    DO:
      CASE PARAMFL.param-value1: 
        
        WHEN "week":U THEN 
          ASSIGN 
            iDayBefore = TODAY - 7.
/*            iDayBefore = DATE((TODAY - WEEKDAY(TODAY)) + 1 ).*/
       
        WHEN "month":U THEN
          ASSIGN 
              iDayBefore = TODAY - 30.
/*            iDayBefore = DATE(MONTH(TODAY),01,YEAR(TODAY)).*/
          
      END CASE.  
    END. /* IF AVAILABLE PARAMFL .. */
    
    ELSE 
     /*  ASSIGN 
        iDayBefore =  DATE((TODAY - WEEKDAY(TODAY)) + 1 ). */
   DO:  
      /* value of iDayBefore will be changed to DATE((TODAY - WEEKDAY(TODAY)) + 1 ) 
         when such records will be available in DB */
         
      IF ipcCompanyCode BEGINS "O" OR ipcCompanyCode BEGINS "J" THEN 
      ASSIGN 
        iDayBefore = 3/27/18  /* DATE((TODAY - WEEKDAY(TODAY)) + 1 ) */.          
      
      ELSE
        ASSIGN iDayBefore = 3/27/18.             
    END. /* ELSE OF IF AVAILABLE PARAMFL.. */
                 
    /* Finding topSeller items on the basis of Customer Type */
    /* IF iplCustType THEN */      
   // MESSAGE  "iDayBefore:" iDayBefore .
    FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
    IF AVAILABLE CCSMS THEN
    DO: 
      ASSIGN 
        cCustType     = CCSMS.CUST-TYPE
        deDiscountPrc = CCSMS.DISC-PERC
        cContractInd  = CCSMS.CONTRACT-IND
        cSpecDictI    = CCSMS.SPEC-DICT-I
        cQtyBrkCd     = CCSMS.QTY-BRK-CD.
                  
      FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
      
      IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
        ASSIGN cPriceList = SHPTO.PRICE-LIST.
        
      ELSE
        ASSIGN cPriceList = CCSMS.PRICE-LIST.
        
    END. /* IF AVAILABLE CCSMS THEN */
    
    EMPTY TEMP-TABLE ttPurchaseItem.  
    iCOUNT = 0. 
    FOR EACH TopSellingItems WHERE (TopSellingItems.CUST-NUMBER  EQ CCSMS.CUST-NUMBER OR TopSellingItems.CUST-NUMBER EQ "ALL")
                               AND TopSellingItems.COMPANY-CODE EQ ipcCompanyCode
                               AND TopSellingItems.ITEM-NUMBER BEGINS ipcCompanyCode 
                               AND TopSellingItems.LAST_PURCHASED GE iDayBefore NO-LOCK
                               BY TopSellingItems.COUNT DESCENDING:
     iCOUNT = iCount + 1.                              
     CREATE ttPurchaseItem.
     ASSIGN 
            ttPurchaseItem.item_number = TopSellingItems.ITEM-NUMBER
            ttPurchaseItem.item_count = TopSellingItems.COUNT.     
     IF iCount GE 10 THEN LEAVE.                                     
                                         
    END.                                 
       
    
    ASSIGN iCount = 0.
    
    FOR EACH ttPurchaseItem BY ttPurchaseItem.item_count DESCENDING :
              
      FIND FIRST CINV1 WHERE CINV1.ITEM-NUMBER EQ ttPurchaseItem.item_number 
                         AND CINV1.HIDE-IN-WM-APPS <> "Y"
                         AND (CINV1.LINE-UP NE "D" OR CINV1.LINE-UP NE "W":U OR CINV1.LINE-UP NE "X":U ) NO-LOCK NO-ERROR.
      IF AVAILABLE CINV1 AND CINV1.LINE-UP NE "D" THEN
      DO:  
/*        FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"*/
/*                     AND PARAMFL.COMPANY-CODE = ipcCompanyCode                       */
/*                     AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.                */
/*            IF AVAILABLE paramfl THEN                                                */
/*            DO:                                                                      */
/*                FIND FIRST CINV2                                                     */
/*                WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER                        */
/*                AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.         */
/*                IF AVAILABLE CINV2 THEN                                              */
/*                DO:                                                                  */
/*                  IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN NEXT.           */
/*                END.                                                                 */
/*            END.                                                                     */
        ASSIGN 
          iCount = iCount + 1.
        
        /* Show only 15 items in This week's top seller section */
       // IF iCount > 5 THEN LEAVE.
           
        ASSIGN 
          itemJsonObj      = NEW JsonObject()
          itemPictureArray = NEW JsonArray()
          prodInfoArray    = NEW JsonArray().
                               
        /*By-calling getPrice() method , assign selling-price of a specific Item corresponding to a specific customer*/
                    
        objCustProductsPrice:getProductPrices(INPUT '0',
                                              INPUT ipcCustNumber,
                                              INPUT CINV1.ITEM-NUMBER,
                                              INPUT YES,
                                              INPUT deDiscountPrc, 
                                              OUTPUT deSellingPrc,
                                              OUTPUT deBasePrc,
                                              INPUT  SHIP-NO,
                                              INPUT  QTY-FULL,
                                              INPUT QTY-UNIT,
                                              INPUT cPriceList,
                                              INPUT ipcCompanyCode).              
                             
        /* If the records of that item exists in CINV2 then assign value 
           of qty_on_hand of specific item from CINV2 else from CINV1 */
           
        FIND FIRST CINV2 WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
                           AND CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR. 
             
        IF CINV1.BY-SIZE OR CINV1.BY-COLOR THEN
        DO:                 
          FOR EACH SIZE WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo 
                          AND SIZE.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER NO-LOCK:
                            
            ASSIGN prodInfoObj = NEW jsonObject ().
            
            prodInfoObj:ADD(INPUT "size",       INPUT if size.size NE "" then size.size ELSE 'Not Applicable':U).
            prodInfoObj:ADD(INPUT "color",      INPUT IF SIZE.DESCRIPTION NE "" THEN REPLACE(SIZE.DESCRIPTION,"'", "")  ELSE 'Not Applicable':U).
            prodInfoObj:ADD(INPUT "in_stock",   INPUT (SIZE.QTY-ONHAND - SIZE.QTY-COMMITED)).
            prodInfoObj:ADD(INPUT "unit_price", INPUT deSellingPrc).
            prodInfoArray:ADD(INPUT prodInfoObj).
                      
          END. /* FOR EACH size...*/
              
        END. /* IF CINV1.BY-SIZE OR CINV1.BY-COLOR THEN */
         
        IF prodInfoArray:LENGTH EQ 0 THEN
        DO:
          ASSIGN 
            prodInfoObj = NEW jsonObject ().
            
          prodInfoObj:ADD(INPUT "size":U,  INPUT 'Not Applicable':U).
          prodInfoObj:ADD(INPUT "color":U, INPUT 'Not Applicable':U).
            
          IF AVAILABLE CINV2 THEN
            prodInfoObj:ADD(INPUT "in_stock":U, INPUT CINV2.QTY-ONHAND - CINV2.QTY-COMMITED ).
          ELSE
            prodInfoObj:ADD(INPUT "in_stock":U, INPUT CINV1.QTY-ONHAND ).
            
          prodInfoObj:ADD(INPUT "unit_price":U, INPUT deSellingPrc).
          prodInfoArray:ADD(INPUT prodInfoObj).
            
        END. /* IF prodInfoArray:LENGTH EQ 0 THEN */
           
        ASSIGN 
          cItemNumber = TRIM(CINV1.ITEM-NUMBER).

        IF cItemNumber MATCHES "*" THEN
          ASSIGN cItemNumber = CAPS(TRIM(REPLACE(cItemNumber, "*", "-") , "-":U)).
          
        //cSourceDir = this-object:ImgDirectory(INPUT cItemNumber).
        //CDomain    = THIS-OBJECT:FINDCDN().
        cSourceDir = objcustomerorder:ImgDirectory(INPUT cItemNumber, INPUT ipcCompanyCode, OUTPUT byitem). //this-object:ImgDirectory(INPUT cItemNumber).
        CDomain    = objcustomerorder:FINDCDN(ipcCompanyCode).  //THIS-OBJECT:FINDCDN().
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
                  itemPictureArray:ADD(CDomain + "/":U + cItemNumber + "/":U + Replace(cItemImage," ","%20")). 
                  //itemPictureArray:ADD(INPUT ConstantInitializer:cImageDir + "/":U + cItemNumber + "/":U + cItemImage).
                 // itemPictureArray:ADD(INPUT "demo.comdist.com/images" + "/":U + cItemNumber + "/":U + cItemImage).   
             
              END.    
          END.
          ELSE 
              DO:
                REPEAT:
                IMPORT cItemImage ^ cFileType.
                IF cFileType EQ "F":U AND INDEX(cItemImage , cItemNumber) GT 0 THEN
                  //pictureJsonArr:ADD(INPUT ConstantInitializer:cImageDir + "/":U + ipcItemNumber + "/":U + cItemImage).  
                  itemPictureArray:ADD(Cdomain + "/":U + Replace(cItemImage," ","%20")).              
                END. 
              END.    
        END. /*  IF cSourceDir NE "x" THEN  */
        
        lcDescription = REPLACE(CINV1.DESCRIPTION,"'", "").
        lcDescription = REPLACE(lcDescription,'"', '').
        lcDescription = REPLACE(lcDescription,"/", "").
        lcDescription = REPLACE(lcDescription,"\", "").
              
        itemJsonObj:ADD(INPUT "item_number":U, INPUT CINV1.ITEM-NUMBER).
        itemJsonObj:ADD(INPUT "description":U, INPUT lCdescription). //REPLACE(CINV1.DESCRIPTION,"'", "") ).
        itemJsonObj:ADD(INPUT "class_code":U,  INPUT CINV1.CLASS-CODE).      
        itemJsonObj:ADD(INPUT "price":U,       INPUT deSellingPrc).
        itemJsonObj:ADD(INPUT "item_uom":U,    INPUT CINV1.ITEM-UOM).
        itemJsonObj:ADD(INPUT "uom_qty":U,     INPUT CINV1.UOM-QTY). 
        itemJsonObj:ADD(INPUT "on_order":U,    INPUT CINV1.QTY-ON-ORDER).  
        itemJsonObj:ADD(INPUT "category_id":U, INPUT CINV1.CLASS-CODE).
        itemJsonObj:ADD(INPUT "family_code":U, INPUT CINV1.FAMILY).
                                         
        /* If the records of that item exists in CINV2 then assign value 
           of qty_on_hand of specific item from CINV2 else from CINV1 */           
        /*FIND FIRST CINV2 
             WHERE CINV2.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER
             AND   CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.*/
                 
        IF AVAILABLE CINV2 THEN
        DO:
            IF CAN-FIND(FIRST sethd WHERE SETHD.SET-NO EQ CINV2.ITEM-NUMBER) THEN 
            DO:
              liQtyonHand = 0.
              IF CAN-FIND(FIRST sethd WHERE SETHD.SET-NO EQ CINV2.ITEM-NUMBER) THEN 
              DO:
                 FOR EACH setdt WHERE SETDT.SET-NO EQ CINV2.ITEM-NUMBER NO-LOCK:
                   FIND FIRST bf-cinv2 WHERE bf-cinv2.ITEM-NUMBER EQ SETDT.ITEM-NUMBER NO-LOCK NO-ERROR.
                   IF AVAILABLE bf-cinv2 THEN 
                   DO:
                  
                       IF liQtyonHand EQ 0 OR liQtyonHand GT bf-CINV2.QTY-ONHAND THEN 
                       ASSIGN liQtyonHand = bf-CINV2.QTY-ONHAND - bf-CINV2.QTY-COMMITED
                              liCommitQty = bf-CINV2.QTY-COMMITED.
                             
                    END.    
                  END.
                        
                  IF liQtyonHand GT 0 THEN      
                    itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT liQtyonHand ).
                  ELSE 
                    itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0 ).
                    
                  itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT liCommitQty ).      
               END. 
            END.
            ELSE 
            DO:
              IF CINV2.QTY-ONHAND GT 0 THEN 
                itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT CINV2.QTY-ONHAND ).
              ELSE 
                itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0 ).
                
              itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT CINV2.QTY-COMMITED ).
            END.  
        END.
        
        ELSE
        DO:
          IF CINV1.QTY-ONHAND GT 0 THEN 
            itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT CINV1.QTY-ONHAND).
          ELSE 
            itemJsonObj:ADD(INPUT "qty_on_hand":U, INPUT 0).
            
          itemJsonObj:ADD(INPUT "commit_qty":U,  INPUT 0).
        END.
                            
        itemJsonObj:ADD(INPUT "no_of_times_purchased":U, INPUT ttPurchaseItem.item_count).
              
        IF CINV1.PICTURE NE "":U THEN
        DO:
          FILE-INFO:FILE-NAME = ConstantInitializer:cPDFDir + "/":U + SUBSTRING(cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1) + ".pdf".

          IF FILE-INFO:FULL-PATHNAME NE ? THEN
          DO:
            itemJsonObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + substring(Cinv1.picture, R-INDEX(cinv1.picture, "\" ) + 1) + ".pdf").
          END.
          
          ELSE
            itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(CINV1.ITEM-NUMBER, ipcCompanyCode ) ).
           // itemJsonObj:ADD(INPUT "pdf_link":U, INPUT "":U). /* PDF doesn't exists on server */
        END. /* IF CINV1.PICTURE NE "":U THEN */
        
        ELSE
          itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(CINV1.ITEM-NUMBER, ipcCompanyCode ) ).
         // itemJsonObj:ADD(INPUT "pdf_link":U, INPUT "":U).
              
        itemJsonObj:ADD(INPUT "pictures":U,          INPUT itemPictureArray).
        itemJsonObj:ADD(INPUT "more_product_data":U, INPUT prodInfoArray).
                       
        objOrderTax:getItemTaxForShipping(INPUT  CINV1.ITEM-NUMBER,
                                          INPUT  ipcCompanyCode,
                                          INPUT  ipcCustNumber,
                                          INPUT  ipiWareHouseNo,
                                          INPUT "",
                                          INPUT  deSellingPrc,
                                          OUTPUT orderTaxArray).
          
        IF VALID-OBJECT(itemJsonObj) THEN
          itemJsonObj:ADD(INPUT "item_tax_unit", INPUT orderTaxArray). 
        
        itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "") ).
        itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")). 
      /*  FIND FIRST cinv3 WHERE CINV3.ITEM-NUMBER EQ CINV1.ITEM-NUMBER 
                           and CINV3.price-list  EQ "Z" NO-LOCK NO-ERROR.
        IF AVAILABLE CINV3 THEN 
          ASSIGN ldMinPrice = CINV3.BREAK-PRICE.
        ELSE 
         ASSIGN ldMinPrice= 0. */
        // MESSAGE "before mobileuser".
         IF cusertype = "mobileuser":u THEN
         DO: 
             ldMinPrice = THIS-OBJECT:FindLowPrice(INPUT ipcCompanyCode,
                                                 INPUT CCSMS.CUST-NUMBER,
                                                 INPUT CINV1.ITEM-NUMBER,
                                                 INPUT CCSMS.DISC-PERC ).
                                                 
             itemJsonObj:ADD(INPUT "min_price":U,      INPUT ldMinPrice).
              lcallPrice = "".
             
               
             FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = ipcCompanyCode
                               AND PARAMFL.PARAM-ID     = "show-all-cinv3"
                               AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
                if available PARAMFL AND CCSMS.CONTRACT-IND NE "A" THEN  
                DO:
                    
                   lcallPrice = THIS-OBJECT:FindAllItemPrice(INPUT ipcCompanyCode,
                                                             INPUT CCSMS.CUST-NUMBER,
                                                             INPUT CINV1.ITEM-NUMBER,
                                                             INPUT CCSMS.DISC-PERC ). 
                   lcallprice = STRING(deSellingPrc) + "|" + lcallprice.                                          
                   itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT lcallPrice). 
               END. 
               ELSE 
                itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT STRING(deSellingPrc)).  
         END.
        /* Find the discount on item if any */
        FIND FIRST OFERT WHERE OFERT.ITEM-NUMBER EQ CINV1.ITEM-NUMBER  
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
/*        IF cusertype = "mobileuser":u THEN                                            */
/*        DO:                                                                           */
/*            itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).     */
/*            itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).*/
/*            itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).     */
/*            itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]).*/
/*            itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).     */
/*            itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]).*/
/*            itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).     */
/*            itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]).*/
/*            itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).     */
/*            itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).*/
/*            itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).        */
/*            itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).  */
/*            itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty).  */
/*        END.                                                                          */
        itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).
        itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).  
        itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).
        itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]). 
        itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).
        itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]). 
        itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).
        itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]). 
        itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).
        itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).
        itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).  
        itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).
        itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty). 
        itemJsonObj:ADD(INPUT "has_offer":U,             INPUT ldHasOffer).
        jsonArrTopSeller:add(itemJsonObj).
                                             
      END. /* IF AVAIL CINV1.. */
           
    END.  /*  FOR EACH ttPurchaseItem .. */  
                 
    ASSIGN 
      oplcTopSellerData = jsonArrTopSeller:GetJsonText(). 
             
   
    /* Provide error message, if any */
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).  
    END CATCH. 
        
    /* Delete objects instances */
    FINALLY:
      INPUT CLOSE.          
      IF VALID-OBJECT(objCustProductsPrice) THEN
        DELETE OBJECT objCustProductsPrice.
        
      IF VALID-OBJECT(jsonArrTopSeller)     THEN
        DELETE OBJECT jsonArrTopSeller.
        
      IF VALID-OBJECT(prodInfoArray)        THEN
        DELETE OBJECT prodInfoArray.
         
      IF VALID-OBJECT(itemPictureArray)     THEN
        DELETE OBJECT itemPictureArray.
         
      IF VALID-OBJECT(prodInfoObj)          THEN
        DELETE OBJECT prodInfoObj.
         
      IF VALID-OBJECT(itemJsonObj)          THEN
        DELETE OBJECT itemJsonObj.
               
      IF VALID-OBJECT(orderTaxArray)        THEN
        DELETE OBJECT orderTaxArray.
             
      IF VALID-OBJECT(objOrderTax)          THEN
        DELETE OBJECT objOrderTax.
         
    END FINALLY.  
    
  END METHOD. /* getTopSellerItems(..) */
  
  /*-------------------------------------------------------------------------------------------------------------------------------------
  Purpose: This method is used to find Topseller-Item of a specific category.
  
  INPUT Parameter: 1. ipcClassCode - Category Id.
    
  OUTPUT Parameter: 1. opcItem     - Item number of topseller item.
  -----------------------------------------------------------------------------------------------------------------------------------------*/ 
  METHOD PUBLIC VOID topSellerItem(INPUT  ipcClassCode  AS CHARACTER,
                                   INPUT  ipcCmpnyCode  AS CHARACTER,
                                   OUTPUT opcItem       AS CHARACTER):
                                                                        
    DEFINE VARIABLE iCount AS INTEGER NO-UNDO.
    DEFINE VARIABLE lCheck AS LOGICAL NO-UNDO.
    
    DEFINE BUFFER bfcsahf  FOR CSAHF.
    DEFINE BUFFER bfcsahf1 FOR CSAHF.
        
    EMPTY TEMP-TABLE ttPurchaseItem.
    
    /* Populate ttPurchaseItem with unique items record */     
    FOR EACH bfcsahf WHERE bfcsahf.class-code      EQ ipcClassCode     
                       AND bfcsahf.item-number     BEGINS ipcCmpnyCode 
                       AND NOT bfcsahf.item-number BEGINS ipcCmpnyCode + "*":U NO-LOCK :
                
      IF bfcsahf.item-number NE "":U AND 
        NOT CAN-FIND( FIRST ttPurchaseItem WHERE ttPurchaseItem.item_number EQ bfcsahf.item-number NO-LOCK ) THEN                                                                   
      DO:  
       
        CREATE ttPurchaseItem.
        ASSIGN 
          ttPurchaseItem.item_number = bfcsahf.item-number
          ttPurchaseItem.class_code  = bfcsahf.class-code.
        
        /* Assign value to iCount field of ttPurchaseItem temp-table where iCount shows no. of times item got purchased. */  
         
        ASSIGN 
          iCount = 0.
      
        FOR EACH bfcsahf1 WHERE bfcsahf1.item-number EQ ttPurchaseItem.item_number NO-LOCK:
          
          ASSIGN iCount = iCount + 1. 
                                                      
        END. /*  FOR EACH bfcsahf1... */
      
        ASSIGN ttPurchaseItem.item_count = iCount.
           
      END.  /*  IF csahf.item-number NE "":U AND NOT CAN-FIND(FIRST... */
        
    END. /*  FOR EACH bfcsahf... */

    /* Find topSeller item by finding greatest value of iCount */
    
    FOR EACH ttPurchaseItem NO-LOCK BY ttPurchaseItem.item_count DESCENDING :
      
      ASSIGN opcItem = ttPurchaseItem.item_number.
      LEAVE.
      
    END.  /*  FOR EACH ttPurchaseItem .. */
              
  END METHOD. /* End of topSellerItem(..) */
  
  /*---------------------------------------------------------------------------------------------------------------
   Purpose: This method is used to populate the images array used for promotions into a jsonArray. 
  
   INPUT Parameter:  1.ipcCustNumber  = Customer Number.
                     2.ipcCompanyCode = Company Code.
   
   OUTPUT Parameter: 1.opcError = Errors, if any.
                     2.oplcPromoImagesData = Storing Promo Images Data.
  ----------------------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID getPromoImages(INPUT   ipcCustNumber       AS CHARACTER,
                                 INPUT   ipcCompanyCode     AS CHARACTER,
                                 OUTPUT  opcError           AS CHARACTER,
                                 OUTPUT  oplcPromoImagesData AS LONGCHAR):

    DEFINE VARIABLE promoImageJsonObject AS CLASS JsonObject NO-UNDO.
    DEFINE VARIABLE promoImagesJsonArray AS CLASS JsonArray  NO-UNDO. 

    DEFINE VARIABLE objcustomerorder    AS CLASS CustomerOrders NO-UNDO.

    DEFINE VARIABLE cSourceDir          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDomain             AS CHARACTER NO-UNDO.    
    DEFINE VARIABLE cItemImage          AS CHARACTER NO-UNDO. 
    DEFINE VARIABLE cFileType           AS CHARACTER NO-UNDO. 

    DEFINE VARIABLE cLogFileName        AS CHARACTER NO-UNDO.
    DEFINE VARIABLE hLogFile            AS HANDLE   NO-UNDO.

    /* Define the log file name and path */
    ASSIGN cLogFileName = "c:\temp\promo_images_log.txt".

    /* Open the log file for output */
    OUTPUT TO VALUE(cLogFileName).

    /* Add log statement to track the progress */
    PUT UNFORMATTED "Method getPromoImages starting..." SKIP.

    ASSIGN
        promoImagesJsonArray = NEW JsonArray()
        objcustomerorder     = NEW customerorders(INPUT cToken).

    /* Verify cToken value */
    PUT UNFORMATTED "cToken value: " cToken SKIP.

    /* Verify ipcCompanyCode and CDomain values */
    PUT UNFORMATTED "ipcCompanyCode value: " ipcCompanyCode " - CDomain value: " CDomain SKIP.

    FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "CDIPREMIUM-FOTOS"
                        AND PARAMFL.COMPANY-CODE = ipcCompanyCode
                        AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR. 

    IF AVAILABLE PARAMFL THEN DO:
        ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1.
        CSourceDir = FILE-INFO:FULL-PATHNAME.
    END.
    ELSE DO:
        cSourceDir = "x".
    END. 

    CDomain = objcustomerorder:FINDCDN(ipcCompanyCode).

    /* Add log statement to check ipcCompanyCode and CDomain values */
    PUT UNFORMATTED "ipcCompanyCode value: " ipcCompanyCode " - CDomain value: " CDomain SKIP.

    FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
    IF AVAILABLE CCSMS THEN DO:         
             
        /* Check if Today is within the range of dates between the promotion start and ending dates */
        FOR EACH WKFILE WHERE WKFILE.PROG-NAME EQ "PROMO-IMAGE" AND TODAY GE WKFILE.DATE1 AND TODAY LE WKFILE.DATE2 NO-LOCK:
            IF AVAILABLE WKFILE THEN DO:
                ASSIGN
                    promoImageJsonObject = NEW JsonObject(). 
                
                /* Add log statement to check WKFILE values */
                PUT UNFORMATTED "WKFILE values - TERMINAL-ID: " WKFILE.TERMINAL-ID
                        " - CHAR2: " WKFILE.CHAR2
                        " - DECIMAL1: " WKFILE.DECIMAL1
                        " - DECIMAL2: " WKFILE.DECIMAL2
                        " - DECIMAL3: " WKFILE.DECIMAL3
                        " - DATE1: " WKFILE.DATE1
                        " - DATE2: " WKFILE.DATE2 SKIP.
    
                promoImageJsonObject:ADD(INPUT "promoId",         INPUT WKFILE.TERMINAL-ID).
                promoImageJsonObject:ADD(INPUT "height",          INPUT WKFILE.DECIMAL1).
                promoImageJsonObject:ADD(INPUT "width",           INPUT WKFILE.DECIMAL2).
                promoImageJsonObject:ADD(INPUT "sizePercentage",  INPUT WKFILE.DECIMAL3).
                promoImageJsonObject:ADD(INPUT "promoStartDate",  INPUT WKFILE.DATE1).
                promoImageJsonObject:ADD(INPUT "promoEndDate",    INPUT WKFILE.DATE2).
                
                /* Store the required image path information */
                IF cSourceDir NE "x" THEN DO:    
                    PUT UNFORMATTED "CSourceDir: " (cSourceDir) SKIP.
                    FILE-INFO:FILE-NAME = cSourceDir. 
                    INPUT FROM OS-DIR(cSourceDir).
                      
                    REPEAT:
                        IMPORT cItemImage ^ cFileType.
                        IF cFileType EQ "F":U AND INDEX(cItemImage , WKFILE.CHAR2) GT 0 THEN 
                            promoImageJsonObject:ADD(INPUT "imageURL", INPUT (CDomain + "/":U + Replace(cItemImage," ","%20"))).
                    END.
                    PUT UNFORMATTED "ImageType: " (cFileType) SKIP.
                    /* Add log statement to track the imageURL */
                    PUT UNFORMATTED "ImageURL: " (CDomain + "/":U + Replace(cItemImage, " ", "%20")) SKIP.
                END.
                COPY-LOB promoIMageJsonObject:GetJsonText() TO FILE "c:\temp\promo_images_objects.txt" APPEND.
                promoImagesJsonArray:ADD(INPUT promoImageJsonObject).
            END. /* IF AVAILABLE WKFILE */
        END. /* For Each WKFILE*/
    END. /* If AVAILABLE CCSMS*/
    
    /* Close the log file */
    OUTPUT CLOSE.

    ASSIGN 
        oplcPromoImagesData = promoImagesJsonArray:GetJsonText(). 
        COPY-LOB oplcPromoImagesData TO FILE "c:\temp\promo_images_data.txt".
    
        /* Add log statement to indicate the method has finished */
    OUTPUT TO VALUE(cLogFileName) APPEND.
    PUT UNFORMATTED "Method getPromoImages completed." SKIP.
    OUTPUT CLOSE.  
    
    /* Provide error message, if any */
    CATCH errorObj AS AppError:           
        ASSIGN 
            opcError = errorObj:GetMessage(1).  
    END CATCH. 
      
    FINALLY:
        IF VALID-OBJECT(promoImageJsonObject) THEN DELETE OBJECT promoImageJsonObject.
        IF VALID-OBJECT(promoImagesJsonArray) THEN DELETE OBJECT promoImagesJsonArray.
    END FINALLY. 

END METHOD. /* End of getPromoImages() */
 
                                 
  /*---------------------------------------------------------------------------------------------------------------
   Purpose: This method is used to populate all items record (specific to a category) into a jsonArray.
   
   INPUT Parameter: 1.ipcCustNumber   = Customer Number.
                    2.ipcClassCode    = Category of Item.
                    3.ipcItemNumber   = Item Number.
                    4.ipcItemDesc     = Description of Item.                 
                    5.ipdQtyOnHand    = Quantity on hand of specific Item Number.
                    6.ipcPDFLink      = Root location of the pdf.
                    7.ipcFabric       = Fabric filter data.
                    8.ipcFamily       = Family filter data.
                    9.ipcVendor       = Vendor filter data.
                    10.ipcMake        = Make filter data.
                    11.iplSize        = Size filter data.
                    12.iplTopSeller   = Ture, if item is topseller item.
                    13.ipiWareHouseNo = Warehouse no for the logged in company.
                    
   OUTPUT Parameter: 1.itemJsonObj = jsonObject stores item information specific to a category.                 
   ----------------------------------------------------------------------------------------------------------------*/   
  METHOD PUBLIC VOID getCategoryAllItems(INPUT  ipcCustNumber  AS CHARACTER,
                                         INPUT  ipcClassCode   AS CHARACTER,
                                         INPUT  ipcItemNumber  AS CHARACTER,
                                         INPUT  ipcItemDesc    AS CHARACTER,
                                         INPUT  ipdQtyOnHand   AS DECIMAL,
                                         INPUT  ipcPDFLink     AS CHARACTER,                                         
                                         INPUT  ipcFabric      AS CHARACTER,
                                         INPUT  ipcFamily      AS CHARACTER,
                                         INPUT  ipcVendor      AS CHARACTER,
                                         INPUT  ipcMake        AS CHARACTER,
                                         INPUT  iplSize        AS LOGICAL,
                                         INPUT  iplByColor     AS LOGICAL,
                                         INPUT  iplTopSeller   AS LOGICAL, 
                                         INPUT  ipcCompanyCode AS CHARACTER,
                                         INPUT  ipiWareHouseNo AS INTEGER,
                                         OUTPUT itemJsonObj    AS CLASS JsonObject):
                                       
    DEFINE VARIABLE objCustProductsPrice AS CLASS     ProductPrices     NO-UNDO. 
    DEFINE VARIABLE objOrderTax          AS CLASS     OrderTaxes        NO-UNDO. 
    DEFINE VARIABLE itemFilterObj        AS CLASS     JsonObject        NO-UNDO.
    DEFINE VARIABLE fabricJsonArr        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE familyJsonArr        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE makeJsonArr          AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE vendorJsonArr        AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE sizeJsonArr          AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE colorJsonArr         AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE pictureJsonArr       AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE prodInfoObj          AS CLASS     JsonObject        NO-UNDO.    
    DEFINE VARIABLE prodInfoArr          AS CLASS     JsonArray         NO-UNDO.
    DEFINE VARIABLE orderTaxArr          AS CLASS     JsonArray         NO-UNDO.    
    DEFINE VARIABLE orderTaxObj          AS CLASS     JsonObject        NO-UNDO. 
    DEFINE VARIABLE objcustomerorder     AS CLASS     CustomerOrders    NO-UNDO.
    DEFINE VARIABLE cItemNumber          AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cSourceDir           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cItemImage           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileType            AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cPriceList           AS CHARACTER NO-UNDO.
      
    DEFINE VARIABLE Selling-PRC          AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE BASE-PRC             AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE deQtyCommit          AS DECIMAL   NO-UNDO. 
    DEFINE VARIABLE SHIP-NO              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE QTY-FULL             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE QTY-UNIT             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE ldMinPrice           AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldUptoQty            AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldUptoQtyPrice       AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldPercent            AS DECIMAL          NO-UNDO.
    DEFINE VARIABLE ldbuyforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldgetforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldHasOffer           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE lcallPrice           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cDomain              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE byitem               AS LOGICAL   NO-UNDO.     
    
    DEFINE VARIABLE oplcItemsJSON        AS LONGCHAR.         
     ASSIGN 
      objCustProductsPrice = NEW ProductPrices(INPUT cToken)
      objOrderTax          = NEW OrderTaxes(INPUT cToken)
      itemJsonObj          = NEW JsonObject() 
      itemFilterObj        = NEW JsonObject()
      orderTaxArr          = NEW JsonArray () 
      fabricJsonArr        = NEW JsonArray ()
      familyJsonArr        = NEW JsonArray ()
      makeJsonArr          = NEW JsonArray ()
      vendorJsonArr        = NEW JsonArray ()
      sizeJsonArr          = NEW JsonArray ()
      colorJsonArr         = NEW JsonArray ()
      pictureJsonArr       = NEW JsonArray ()
      prodInfoArr          = NEW JsonArray ()
      objcustomerorder     = NEW customerorders(INPUT cToken). 
  
    /* Assign value of quantity on hand of specific item */
    FIND FIRST CINV2 WHERE CINV2.ITEM-NUMBER  EQ ipcItemNumber
                       AND CINV2.WAREHOUSE-NO EQ ipiWareHouseNo NO-LOCK NO-ERROR.
                       
    IF AVAILABLE CINV2 THEN
    DO:
        ipdQtyOnHand = 0.
        IF CAN-FIND(FIRST sethd WHERE SETHD.SET-NO EQ CINV2.ITEM-NUMBER) THEN 
        DO:
            FOR EACH setdt WHERE SETDT.SET-NO EQ CINV2.ITEM-NUMBER NO-LOCK:
              FIND FIRST bf-cinv2 WHERE bf-cinv2.ITEM-NUMBER EQ SETDT.ITEM-NUMBER NO-LOCK NO-ERROR.
              IF AVAILABLE bf-cinv2 THEN 
              DO:
                  
                  IF ipdQtyOnHand EQ 0 OR ipdQtyOnHand GT bf-CINV2.QTY-ONHAND THEN 
                  ASSIGN ipdQtyOnHand = bf-CINV2.QTY-ONHAND - bf-CINV2.QTY-COMMITED
                         deQtyCommit  = bf-CINV2.QTY-COMMITED.
              END.    
            END.
        END.
        ELSE
         ASSIGN ipdQtyOnHand = CINV2.QTY-ONHAND //CINV2.QTY-ONHAND - CINV2.QTY-COMMITED
                deQtyCommit  = CINV2.QTY-COMMITED.   
    END.    
       
/*            FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID = "DO-NOT-ALLOW-NEGATIVE-INV-ORDER"*/
/*                                 AND PARAMFL.COMPANY-CODE = ipcCompanyCode               */
/*                                 AND PARAMFL.PARAM-STATUS = yes NO-LOCK NO-ERROR.        */
/*            IF AVAILABLE paramfl THEN                                                    */
/*            DO:                                                                          */
/*                IF AVAILABLE CINV2 THEN                                                  */
/*                DO:                                                                      */
/*                  IF CINV2.QTY-ONHAND - CINV2.QTY-COMMITED LE 0 THEN RETURN.             */
/*                END.                                                                     */
/*            END.                                                                         */
             
    FIND FIRST CCSMS WHERE CCSMS.CUST-NUMBER EQ ipcCustNumber NO-LOCK NO-ERROR.
    IF AVAIL CCSMS THEN
    DO:   
            
      FIND FIRST SHPTO WHERE SHPTO.CUST-NUMBER EQ CCSMS.CUST-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE SHPTO AND SHPTO.PRICE-LIST NE "":U THEN
        ASSIGN cPriceList = SHPTO.PRICE-LIST.
      ELSE
        ASSIGN cPriceList = CCSMS.PRICE-LIST.   
        
      /*By-calling getPrice() method ,  assign selling-price of a specific Item corresponding to a specific customer*/
                  
      objCustProductsPrice:getProductPrices(INPUT '0',
                                            INPUT CCSMS.CUST-NUMBER,
                                            INPUT ipcItemNumber,
                                            INPUT YES,
                                            INPUT CCSMS.DISC-PERC, 
                                            OUTPUT SELLING-PRC,
                                            OUTPUT BASE-PRC,
                                            INPUT  SHIP-NO,
                                            INPUT  QTY-FULL,
                                            INPUT QTY-UNIT,
                                            INPUT cPriceList,
                                            INPUT ipcCompanyCode).
           
        
    END. /* IF AVAIL CCSMS THEN */                                    
      
    IF iplSize OR iplByColor THEN
    DO: 
      FOR EACH size WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo AND SIZE.ITEM-NUMBER EQ ipcItemNumber NO-LOCK:
        prodInfoObj  = NEW jsonObject ().
            
        IF SIZE.SIZE NE "":U THEN 
          sizeJsonArr:ADD(INPUT SIZE.SIZE).
        
        IF iplByColor AND SIZE.DESCRIPTION NE "":U THEN   
          colorJsonArr:ADD(INPUT REPLACE(SIZE.DESCRIPTION,"'", "") ).
                     
        prodInfoObj:ADD(INPUT "size",       INPUT if size.size NE "" then size.size ELSE 'Not Applicable':U  ).
        prodInfoObj:ADD(INPUT "color",      INPUT IF SIZE.DESCRIPTION NE "" THEN REPLACE(SIZE.DESCRIPTION,"'", "") ELSE 'Not Applicable':U). 
        prodInfoObj:ADD(INPUT "in_stock",   INPUT (SIZE.QTY-ONHAND - SIZE.QTY-COMMITED)).
        prodInfoObj:ADD(INPUT "unit_price", INPUT SELLING-PRC).
        prodInfoArr:ADD(INPUT prodInfoObj).
                      
      END. /* FOR EACH size...*/
    END. /* IF iplSize OR iplByColor THEN */
    
    IF prodInfoArr:LENGTH EQ 0 THEN
    DO:
      ASSIGN 
        prodInfoObj = NEW jsonObject ().
        
      prodInfoObj:ADD(INPUT "size":U,       INPUT 'Not Applicable':U).
      prodInfoObj:ADD(INPUT "color":U,      INPUT 'Not Applicable':U).
      prodInfoObj:ADD(INPUT "in_stock":U,   INPUT ipdQtyOnHand ).
      prodInfoObj:ADD(INPUT "unit_price":U, INPUT SELLING-PRC).
      prodInfoArr:ADD(INPUT prodInfoObj).
    
    END. /* IF prodInfoArr:LENGTH EQ 0 THEN */
                
    IF ipcFabric NE "":U THEN
      fabricJsonArr:ADD(INPUT REPLACE(ipcFabric,"'","")).
        
    IF ipcFamily NE "":U THEN  
      familyJsonArr:ADD(INPUT REPLACE(ipcFamily,"'","")).
      
    IF ipcVendor NE "":U THEN  
      vendorJsonArr:ADD(INPUT REPLACE(ipcVendor,"'","")).
        
    IF ipcMake NE "":U THEN  
      makeJsonArr:ADD(INPUT REPLACE(ipcMake,"'","")).
                    
    ASSIGN  
      cItemNumber = TRIM(ipcItemNumber).

    IF cItemNumber MATCHES "*" THEN
      ASSIGN cItemNumber = CAPS(TRIM(REPLACE(cItemNumber, "*", "-") , "-":U)).
     
   /* FILE-INFO:FILE-NAME = ConstantInitializer:cImageDir + "/":U + cItemNumber.
    
    IF FILE-INFO:FULL-PATHNAME EQ ? THEN 
    DO:
            FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
            IF AVAILABLE paramfl THEN 
              ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1 
                     FILE-INFO:FILE-NAME =  FILE-INFO:FILE-NAME + "\" + cItemNumber NO-ERROR.
    END.        
    IF FILE-INFO:FULL-PATHNAME NE ? THEN
    DO:
      ASSIGN 
        cSourceDir = FILE-INFO:FULL-PATHNAME. */
     // cSourceDir = this-object:ImgDirectory(INPUT cItemNumber).
     // CDomain    = THIS-OBJECT:FINDCDN().
     cSourceDir = objcustomerorder:ImgDirectory(INPUT cItemNumber, INPUT ipcCompanyCode, OUTPUT byitem). //this-object:ImgDirectory(INPUT cItemNumber).
     CDomain    = objcustomerorder:FINDCDN(ipcCompanyCode).  //THIS-OBJECT:FINDCDN().
     
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
                pictureJsonArr:ADD(CDomain + "/":U + cItemNumber + "/":U + Replace(cItemImage," ","%20")).
             END.     
          END.
          ELSE 
              DO:
                REPEAT:
                IMPORT cItemImage ^ cFileType.
                IF cFileType EQ "F":U AND INDEX(cItemImage , cItemNumber) GT 0 THEN
                  //pictureJsonArr:ADD(INPUT ConstantInitializer:cImageDir + "/":U + ipcItemNumber + "/":U + cItemImage).  
                  pictureJsonArr:ADD(Cdomain + "/":U + Replace(cItemImage," ","%20")).  
                           
                END. 
              END.    
    END. /* IF FILE-INFO:FULL-PATHNAME NE ? THEN */

    itemFilterObj:ADD(INPUT "fabric":U, INPUT fabricJsonArr).
    itemFilterObj:ADD(INPUT "family":U, INPUT familyJsonArr).
    itemFilterObj:ADD(INPUT "vendor":U, INPUT vendorJsonArr).
    itemFilterObj:ADD(INPUT "make":U,   INPUT makeJsonArr).
    itemFilterObj:ADD(INPUT "size":U,   INPUT sizeJsonArr).
    itemFilterObj:ADD(INPUT "color":U,  INPUT colorJsonArr).
     
    lcDescription = REPLACE(ipcItemDesc,"'", "").
    lcDescription = REPLACE(lcDescription,'"', '').
    lcDescription = REPLACE(lcDescription,"/", "").
    lcDescription = REPLACE(lcDescription,"\", "").
     
        
    /* Populate itemJsonObj jsonArray with all items record correspond to specific category by calling PopulateItem() method */           
    itemJsonObj:ADD(INPUT "class_code":U,      INPUT ipcClassCode).
    itemJsonObj:ADD(INPUT "item_number":U,     INPUT ipcItemNumber).
    
    itemJsonObj:ADD(INPUT "description":U,     INPUT lcDescription ). //REPLACE(ipcItemDesc,"'", "") ).
    itemJsonObj:ADD(INPUT "price":U,           INPUT SELLING-PRC).
    IF ipdQtyOnHand GT 0 THEN
        itemJsonObj:ADD(INPUT "qty_on_hand":U,     INPUT ipdQtyOnHand).
    ELSE 
        itemJsonObj:ADD(INPUT "qty_on_hand":U,     INPUT 0).
        
    itemJsonObj:ADD(INPUT "commit_qty":U,      INPUT deQtyCommit).
    
    
    FOR FIRST CINV1 WHERE CINV1.ITEM-NUMBER EQ ipcItemNumber NO-LOCK:
      itemJsonObj:ADD(INPUT "item_uom":U,      INPUT CINV1.ITEM-UOM).
      itemJsonObj:ADD(INPUT "uom_qty":U,       INPUT CINV1.UOM-QTY).
      itemJsonObj:ADD(INPUT "on_order":U,      INPUT CINV1.QTY-ON-ORDER).
      itemJsonObj:ADD(INPUT "category_id":U,   INPUT CINV1.CLASS-CODE).
      itemJsonObj:ADD(INPUT "family_code":U,   INPUT CINV1.FAMILY).  
    END. /* FOR FIRST CINV1 */
      
    IF ipcPDFLink NE "":U THEN
    DO:
      FILE-INFO:FILE-NAME = ConstantInitializer:cPDFDir + "/":U + ipcPDFLink + ".pdf".

      IF FILE-INFO:FULL-PATHNAME NE ? THEN
      DO:
        itemJsonObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + ipcPDFLink + ".pdf").
      END.
      
      ELSE
        itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(CINV1.ITEM-NUMBER, ipcCompanyCode ) ).
        //itemJsonObj:ADD(INPUT "pdf_link":U, INPUT "":U).
    END.
    
    ELSE
      itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(CINV1.ITEM-NUMBER, ipcCompanyCode ) ).
      //itemJsonObj:ADD(INPUT "pdf_link":U, INPUT "":U).
       
    itemJsonObj:ADD(INPUT "isTopSeller":U,     INPUT iplTopSeller).
    itemJsonObj:ADD(INPUT "pictures":U,        INPUT pictureJsonArr).
    itemJsonObj:Add(INPUT "more_product_data", INPUT prodInfoArr).
    itemJsonObj:ADD(INPUT "item_filters":U,    INPUT itemFilterObj).
      
    objOrderTax:getItemTaxForShipping(INPUT ipcItemNumber,
                                      INPUT ipcCompanyCode,
                                      INPUT ipcCustNumber,
                                      INPUT ipiWareHouseNo,
                                      INPUT "",
                                      INPUT SELLING-PRC,
                                      OUTPUT orderTaxArr).
                                        
    itemJsonObj:Add(INPUT "item_tax_unit", INPUT orderTaxArr).
    itemJsonObj:ADD(INPUT "pack_size":U,      INPUT REPLACE(STRING(CINV1.PACK),"'", "")).  
    itemJsonObj:ADD(INPUT "pallet_quantity":U,   INPUT REPLACE(STRING(CINV1.PALLET-QTY), "'", "")). 
    /* Find minimum price of item if SalesRep is allowed to modify the price on mobile app*/
    FIND FIRST cinv3 WHERE CINV3.ITEM-NUMBER EQ ipcItemNumber 
                       and CINV3.price-list  EQ "Z" NO-LOCK NO-ERROR.
    IF AVAILABLE CINV3 THEN 
      ASSIGN ldMinPrice = CINV3.BREAK-PRICE.
    ELSE 
      ASSIGN ldMinPrice= 0.
     IF cusertype = "mobileuser":u THEN     
     do:  
        itemJsonObj:ADD(INPUT "min_price":U,      INPUT ldMinPrice).
        lcallPrice = "".
       
                 
        FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = ipcCompanyCode
                               AND PARAMFL.PARAM-ID     = "show-all-cinv3"
                               AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
         if available PARAMFL AND CCSMS.CONTRACT-IND NE "A" then 
         DO:
           
            lcallPrice = THIS-OBJECT:FindAllItemPrice(INPUT ipcCompanyCode,
                                                      INPUT CCSMS.CUST-NUMBER,
                                                      INPUT CINV1.ITEM-NUMBER,
                                                      INPUT CCSMS.DISC-PERC ). 
             lcallPrice = STRING(SELLING-PRC) + "|" + lcallPrice.                                                
            itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT lcallPrice). 
           END. 
           ELSE 
           itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT STRING(SELLING-PRC)). 
        
           
     end.   
    
    /* Find the discount on item if any */
    FIND FIRST OFERT WHERE OFERT.ITEM-NUMBER EQ ipcItemNumber 
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
/*     IF cusertype = "mobileuser":u THEN                                           */
/*     DO:                                                                          */
/*        itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).     */
/*        itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).*/
/*        itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).     */
/*        itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]).*/
/*        itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).     */
/*        itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]).*/
/*        itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).     */
/*        itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]).*/
/*        itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).     */
/*        itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).*/
/*        itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).        */
/*        itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).  */
/*        itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty).  */
/*     END.                                                                         */
    itemJsonObj:ADD(INPUT "up_to_qty1":U,            INPUT ldUptoQty[1]).
    itemJsonObj:ADD(INPUT "up_to_price1":U,          INPUT ldUptoQtyPrice[1]).  
    itemJsonObj:ADD(INPUT "up_to_qty2":U,            INPUT ldUptoQty[2]).
    itemJsonObj:ADD(INPUT "up_to_price2":U,          INPUT ldUptoQtyPrice[2]). 
    itemJsonObj:ADD(INPUT "up_to_qty3":U,            INPUT ldUptoQty[3]).
    itemJsonObj:ADD(INPUT "up_to_price3":U,          INPUT ldUptoQtyPrice[3]). 
    itemJsonObj:ADD(INPUT "up_to_qty4":U,            INPUT ldUptoQty[4]).
    itemJsonObj:ADD(INPUT "up_to_price4":U,          INPUT ldUptoQtyPrice[4]). 
    itemJsonObj:ADD(INPUT "up_to_qty5":U,            INPUT ldUptoQty[5]).
    itemJsonObj:ADD(INPUT "up_to_price5":U,          INPUT ldUptoQtyPrice[5]).
    itemJsonObj:ADD(INPUT "item_percent_for_disc":U, INPUT ldPercent).  
    itemJsonObj:ADD(INPUT "buy_qty_to_get_free":U,   INPUT ldbuyforFreeQty).
    itemJsonObj:ADD(INPUT "get_free_item":U,         INPUT ldgetforFreeQty). 
    itemJsonObj:ADD(INPUT "has_offer":U,             INPUT ldHasOffer).
    
     ASSIGN 
      oplcItemsJSON = itemJsonObj:GetJsonText().
/*    COPY-LOB oplcItemsJSON to file "c:\temp\json_string.txt".*/
    
    FINALLY:
      IF VALID-OBJECT(objOrderTax) THEN
        DELETE OBJECT objOrderTax.
        
      IF VALID-OBJECT(objCustProductsPrice) THEN
        DELETE OBJECT objCustProductsPrice.     
    END FINALLY.  
                                        
  END METHOD. /* populateItem(...) */   
  
  /*--------------------------------------------------------------------------------------------------
  Purpose: This method is used to add all different filter data (specific to a category) into their corresponding Filter jsonArray.
 
  INPUT Parameter: 1.ipcFabric = Stores Fabric specific filterData.
                   2.ipcFamily = Stores Family specific filterData.
                   3.ipcVendor = Stores Vendor specific filterData.
                   4.ipcMake   = Stores Make   specific filterData.
                   5.iplSize   = Stores Size   specific filterData.
 
  INPUT-OUTPUT Parameter: 1.fabricJsonArr = jsonArray stores all Fabric filterData.
                          2.familyJsonArr = jsonArray stores all Family filterData.
                          3.makeJsonArr   = jsonArray stores all Make   filterData.
                          4.vendorJsonArr = jsonArray stores all Vendor filterData.
                          5.sizeJsonArr   = jsonArray stores all Size   filterData.
                          6.colorJsonArr  = jsonArray stores all colors filterData.
  ------------------------------------------------------------------------------------------------------*/  
  METHOD PUBLIC VOID populateFilter(INPUT ipiWareHouseNo AS INTEGER,
    INPUT-OUTPUT fabricJsonArr AS CLASS jsonArray,
    INPUT-OUTPUT familyJsonArr AS CLASS jsonArray,
    INPUT-OUTPUT makeJsonArr   AS CLASS jsonArray,
    INPUT-OUTPUT vendorJsonArr AS CLASS jsonArray,
    INPUT-OUTPUT sizeJsonArr   AS CLASS jsonArray, 
    INPUT-OUTPUT colorJsonArr  AS CLASS jsonArray):

    /* Check for non-blank and non-repeated Fabric filter data of a specific category */    
    IF CINV1.FABRIC NE "":U THEN
    DO:
      IF NOT CAN-FIND(FIRST ttFabricFilter WHERE ttFabricFilter.filter_data EQ CINV1.FABRIC) THEN
      DO:
        CREATE ttFabricFilter.
        ASSIGN 
          ttFabricFilter.item_number = CINV1.ITEM-NUMBER
          ttFabricFilter.filter_data = CINV1.FABRIC.
         
        fabricJsonArr:Add(INPUT ttFabricFilter.filter_data).       
      END.     
    END. /* IF CINV1.FABRIC NE "":U THEN */   
    
      
    /* Check for non-blank and non-repeated Family filter data of a specific category */ 
    IF CINV1.FAMILY NE "":U THEN
    DO:
      IF NOT CAN-FIND(FIRST ttFamilyFilter WHERE ttFamilyFilter.filter_data EQ CINV1.FAMILY) THEN
      DO:
        CREATE ttFamilyFilter.
        ASSIGN 
          ttFamilyFilter.item_number = CINV1.ITEM-NUMBER
          ttFamilyFilter.filter_data = CINV1.FAMILY.
         
        familyJsonArr:Add(INPUT ttFamilyFilter.filter_data).       
      END.     
    END. /* IF CINV1.FAMILY NE "":U THEN */
    
   
    /* Check for non-blank and non-repeated Make filter data of a specific category */ 
    IF CINV1.MAKE NE "":U THEN
    DO:
      IF NOT CAN-FIND(FIRST ttMakeFilter WHERE ttMakeFilter.filter_data EQ REPLACE(CINV1.MAKE,"'","")) THEN
      DO:
        CREATE ttMakeFilter.
        ASSIGN 
          ttMakeFilter.item_number = CINV1.ITEM-NUMBER
          ttMakeFilter.filter_data = REPLACE(CINV1.MAKE,"'","").
         
        makeJsonArr:Add(INPUT ttMakeFilter.filter_data).       
      END.     
    END. /* IF CINV1.MAKE NE "":U THEN */
    
                  
    /* Check for non-blank and non-repeated Vendor filter data of a specific category */ 
    IF CINV1.VENDOR-NO NE "":U THEN
    DO:
      IF NOT CAN-FIND(FIRST ttVendorFilter WHERE ttVendorFilter.filter_data EQ REPLACE(CINV1.VENDOR-NO,"'","")) THEN
      DO:
        CREATE ttVendorFilter.
        ASSIGN 
          ttVendorFilter.item_number = CINV1.ITEM-NUMBER
          ttVendorFilter.filter_data = REPLACE(CINV1.VENDOR-NO,"'","").
                         
        vendorJsonArr:Add(INPUT ttVendorFilter.filter_data).       
      END.     
    END. /* IF CINV1.VENDOR-NO NE "":U THEN */
    
     
    /* Check for non-blank and non-repeated Size filter data of a specific category */ 
               
    IF CINV1.BY-SIZE OR CINV1.BY-COLOR THEN
    DO:  
      FOR EACH SIZE WHERE SIZE.WAREHOUSE-NO EQ ipiWareHouseNo 
        AND SIZE.ITEM-NUMBER  EQ CINV1.ITEM-NUMBER NO-LOCK:
        
        IF SIZE.SIZE NE "":U THEN
        DO:
          IF NOT CAN-FIND(FIRST ttSizeFilter WHERE ttSizeFilter.filter_data EQ SIZE.SIZE) THEN
          DO:
            CREATE ttSizeFilter.
            ASSIGN 
              ttSizeFilter.item_number = CINV1.ITEM-NUMBER
              ttSizeFilter.filter_data = if size.size NE "" then size.size ELSE 'Not Applicable':U.
         
            sizeJsonArr:Add(INPUT ttSizeFilter.filter_data).       
          END.     
        END. /* IF SIZE.SIZE NE "":U THEN */
            
        IF CINV1.BY-COLOR AND SIZE.DESCRIPTION NE "":U THEN
        DO:
          IF NOT CAN-FIND(FIRST ttColorFilter WHERE ttColorFilter.filter_data EQ SIZE.DESCRIPTION) THEN
          DO:
            CREATE ttColorFilter.
            ASSIGN 
              ttColorFilter.item_number = CINV1.ITEM-NUMBER
              ttColorFilter.filter_data = REPLACE(SIZE.DESCRIPTION,"'", "") .
         
            colorJsonArr:Add(INPUT ttColorFilter.filter_data).       
          END.     
        END. /* IF CINV1.BY-COLOR AND SIZE.DESCRIPTION NE "":U THEN */
              
      END. /* FOR EACH size .. */
      
    END. /* IF CINV1.BY-SIZE OR CINV1.BY-COLOR THEN */ 

  END METHOD. /* populateFilter(..) */  
  
  /*------------------------------------------------------------------------------------------------------
 Purpose: This method is used to add different filter array (specific to a category) into a filter jsonObject.
 
 INPUT Parameter:1. makeJsonArr   = jsonArray store all make   filterdata.
                 2. familyJsonArr = jsonArray store all Family filterdata.
                 3. fabricJsonArr = jsonArray store all Fabric filterdata.
                 4. vendorJsonArr = jsonArray store all vendor filterdata.
                 5. sizeJsonArr   = jsonArray store all size   filterdata.
                 6. colorJsonArr  = jsonArray store all colors filterdata.
                 
 OUTPUT Parameter: 1. filterJsonObj = JsonObject store jsonArray of all filterData.               
 --------------------------------------------------------------------------------------------------------*/ 
  METHOD PUBLIC VOID populateJsonFilter(INPUT  makeJsonArr   AS CLASS JsonArray,
    INPUT  familyJsonArr AS CLASS JsonArray,
    INPUT  fabricJsonArr AS CLASS JsonArray,
    INPUT  vendorJsonArr AS CLASS JsonArray,
    INPUT  sizeJsonArr   AS CLASS JsonArray,
    INPUT  colorJsonArr  AS CLASS JsonArray,
    OUTPUT filterJsonObj AS CLASS JsonObject ):
                                       
    ASSIGN 
      filterJsonObj = NEW JsonObject().
      
    IF makeJsonArr:length NE 0 THEN
      filterJsonObj:ADD(INPUT "make":U, INPUT makeJsonArr).
      
    IF vendorJsonArr:length NE 0  THEN
      filterJsonObj:ADD(INPUT "vendor":U, INPUT vendorJsonArr).
      
    IF familyJsonArr:length NE 0  THEN
      filterJsonObj:ADD(INPUT "family":U, INPUT familyJsonArr).
      
    IF fabricJsonArr:length NE 0  THEN
      filterJsonObj:ADD(INPUT "fabric":U, INPUT fabricJsonArr).
      
    IF sizeJsonArr:length NE 0  THEN
      filterJsonObj:ADD(INPUT "size":U, INPUT sizeJsonArr).
    
    IF colorJsonArr:length NE 0  THEN
      filterJsonObj:ADD(INPUT "color":U, INPUT colorJsonArr).  
    
  END METHOD. /* populateJsonFilter(...) */   
  
  /*----------------------------------------------------------------------------------------------------------
  Purpose: This method is used to populate jsonArray of subcategory along with their filters and items record.
  
  INPUT Parameters: 1. ipcClassCode   - Category Id
                   
  OUTPUT Parameters:1. categoryJsonObj - JsonObject stores category record along with their filters and items record.  
                     
  INPUT-OUPUT Parameters: 2. catLevelJsonArr - jsonArray of subcategory, filters and items records.                         
  ----------------------------------------------------------------------------------------------------------------*/ 
  METHOD PUBLIC VOID populateSubcat(INPUT  ipcClassCode          AS CHARACTER,
                                    INPUT  ipcDescription        AS CHARACTER,
                                    INPUT  ipcParentCat          AS CHARACTER,
                                    INPUT  ipcCompanyCode        AS CHARACTER,
                                    INPUT  ipiWareHouseNo        AS INTEGER,
                                    OUTPUT categoryJsonObj       AS jsonObject,
                                    INPUT-OUTPUT catLevelJsonArr AS jsonArray ):
       
    /* Define different jsonArray which are used in this method */
    DEFINE VARIABLE fabricJsonArr     AS CLASS jsonArray  NO-UNDO.
    DEFINE VARIABLE makeJsonArr       AS CLASS jsonArray  NO-UNDO.
    DEFINE VARIABLE familyJsonArr     AS CLASS jsonArray  NO-UNDO.
    DEFINE VARIABLE vendorJsonArr     AS CLASS jsonArray  NO-UNDO.
    DEFINE VARIABLE sizeJsonArr       AS CLASS jsonArray  NO-UNDO.
    DEFINE VARIABLE colorJsonArr      AS CLASS jsonArray  NO-UNDO. 
    
    /* Define jsonObject which are used in this method */   
    DEFINE VARIABLE itemJsonObj       AS CLASS jsonObject NO-UNDO.
    DEFINE VARIABLE filterDataJsonObj AS CLASS JsonObject NO-UNDO.

    /* Initialise jsonobject */      
    ASSIGN 
      categoryJsonObj = NEW jsonObject(). 
    
    categoryJsonObj:ADD(INPUT "class_code":U,  INPUT ipcClassCode).
    categoryJsonObj:ADD(INPUT "description":U, INPUT REPLACE(ipcDescription,"'", "") ).
    categoryJsonObj:ADD(INPUT "parent_cat":U,  INPUT ipcParentCat).
                
    IF catLevelJsonArr:LENGTH NE 0 THEN
    DO:
      categoryJsonObj:ADD(INPUT "isDepartment":U, INPUT TRUE).
      categoryJsonObj:ADD(INPUT "subcategory":U,  INPUT catLevelJsonArr). 
      catLevelJsonArr = NEW jsonArray().  
    END. /* End of IF catLevelJsonArr:length.. */
    ELSE
      categoryJsonObj:ADD(INPUT "isDepartment":U, INPUT FALSE).
    
    /* This condition is used to fetch only that category which contains items that are related to logged-in company*/
    IF CAN-FIND(FIRST CINV1 WHERE CINV1.ITEM-NUMBER BEGINS ipcCompanyCode 
                              AND CINV1.CLASS-CODE  EQ     ipcClassCode   NO-LOCK) THEN
    DO:
      
      /* Empty Filter Temp-Tables */
      EMPTY TEMP-TABLE ttVendorFilter.
      EMPTY TEMP-TABLE ttFabricFilter.
      EMPTY TEMP-TABLE ttFamilyFilter.
      EMPTY TEMP-TABLE ttSizeFilter.
      EMPTY TEMP-TABLE ttColorFilter.
      EMPTY TEMP-TABLE ttMakeFilter.  
        
      /* Initialise different jsonArray */
      ASSIGN 
        fabricJsonArr = NEW jsonArray()
        makeJsonArr   = NEW jsonArray()
        familyJsonArr = NEW jsonArray()
        vendorJsonArr = NEW jsonArray()
        sizeJsonArr   = NEW jsonArray()
        colorJsonArr  = NEW jsonArray().
                                                      
      /* Populate categoryJsonObj jsonObject with category records along with filters.*/   
     
      FOR EACH CINV1 WHERE CINV1.COMPANY-CODE EQ ipcCompanyCode  
                       AND CINV1.CLASS-CODE   EQ     ipcClassCode 
                       AND CINV1.ITEM-NUMBER  BEGINS ipcCompanyCode
                       AND (CINV1.LINE-UP      NE "D" OR CINV1.LINE-UP NE "W":U OR CINV1.LINE-UP NE "X":U ) NO-LOCK:
        IF CINV1.LINE-UP EQ "D" THEN NEXT.                                                               
        /* Populate all Filter jsonarray with filters record correspond 
           to specific category by calling PopulateFilter() method */                                
                                          
        THIS-OBJECT:populateFilter(INPUT ipiWareHouseNo,
                                   INPUT-OUTPUT fabricJsonArr,
                                   INPUT-OUTPUT familyJsonArr,
                                   INPUT-OUTPUT makeJsonArr,
                                   INPUT-OUTPUT vendorJsonArr,
                                   INPUT-OUTPUT sizeJsonArr,
                                   INPUT-OUTPUT colorJsonArr). 
                                                              
      END. /* FOR EACH cinv1 WHERE..*/ 
         
      /* Populate filter jsonObect and add this filter jsonObect to corresponding category */
          
      THIS-OBJECT:populateJsonFilter(INPUT  makeJsonArr,
                                     INPUT  familyJsonArr,
                                     INPUT  fabricJsonArr,
                                     INPUT  vendorJsonArr,
                                     INPUT  sizeJsonArr,
                                     INPUT  colorJsonArr,
                                     OUTPUT filterDataJsonObj ).
         
      categoryJsonObj:ADD(INPUT "filter":U, INPUT filterDataJsonObj).  
             
    END. /* IF CAN-FIND(FIRST CINV1..*/
                     
  END METHOD. /* populateSubcat(..) */
  
  METHOD PUBLIC DECIMAL FindLowPrice(INPUT ipcCompany AS CHARACTER,
                                     INPUT ipcCustNumber AS CHARACTER,
                                     INPUT ipcitem-number AS CHARACTER,
                                     INPUT ipdPRECIO-DISC-PERC AS DECIMAL):
   
      DEFINE VARIABLE ObjProductPrice     AS CLASS ProductPrices  NO-UNDO.
      DEFINE VARIABLE opLowestPrice       AS DECIMAL NO-UNDO.
      ObjProductPrice  = NEW ProductPrices (INPUT cToken).
      ObjProductPrice:getLowPrice(INPUT  ipcCompany, 
                                  INPUT  ipcCustNumber, 
                                  INPUT  ipcitem-number, 
                                  INPUT  ipdPRECIO-DISC-PERC, 
                                  OUTPUT opLowestPrice).
                                  
    // opLowestPrice = 1.25. // Remove this after testing.                                  
                 
     RETURN opLowestPrice.                                    
    
   END.   
   
   METHOD PUBLIC CHARACTER FindAllItemPrice(INPUT ipcCompany AS CHARACTER,
                                            INPUT ipcCustNumber AS CHARACTER,
                                            INPUT ipcitem-number AS CHARACTER,
                                            INPUT ipdPRECIO-DISC-PERC AS DECIMAL):
   
      DEFINE VARIABLE ObjProductPrice     AS CLASS ProductPrices  NO-UNDO.
      DEFINE VARIABLE opAllPrice          AS CHARACTER NO-UNDO.
      ObjProductPrice  = NEW ProductPrices (INPUT cToken).
      ObjProductPrice:getAllItemPrice(INPUT  ipcCompany, 
                                      INPUT  ipcCustNumber, 
                                      INPUT  ipcitem-number, 
                                      INPUT  ipdPRECIO-DISC-PERC, 
                                      OUTPUT opAllPrice).
                                  
     RETURN opAllPrice.                                    
    
   END.
     
   METHOD PUBLIC CHARACTER PdfLink(INPUT cItemNumber AS CHARACTER, 
                                   INPUT ipcCompanyCode AS CHARACTER):
     DEFINE VARIABLE lcPdfpath  AS CHARACTER NO-UNDO.
     DEFINE VARIABLE lCSource   AS CHARACTER NO-UNDO.  
     DEFINE VARIABLE lCDomain   AS CHARACTER NO-UNDO.
     DEFINE VARIABLE cItemImage AS CHARACTER NO-UNDO.
     DEFINE VARIABLE cFileType  AS CHARACTER NO-UNDO.
     DEFINE VARIABLE objCustomerorder AS CLASS customerorders NO-UNDO.
     DEFINE VARIABLE byitem  AS LOGICAL NO-UNDO.
 
     objCustomerorder = NEW customerorders(INPUT ctoken).
     // lCSource   = this-object:ImgDirectory(INPUT cItemNumber).
     // lCDomain    = THIS-OBJECT:FINDCDN().
      lCSource = objcustomerorder:ImgDirectory(INPUT cItemNumber, INPUT ipcCompanyCode, OUTPUT byitem). //this-object:ImgDirectory(INPUT cItemNumber).
      lCDomain    = objcustomerorder:FINDCDN(ipcCompanyCode).  //THIS-OBJECT:FINDCDN().
      
      IF lCSource NE "x" THEN 
      DO: 
           FILE-INFO:FILE-NAME = lCSource.
           lCSource = FILE-INFO:FULL-PATHNAME. 
          
         INPUT FROM OS-DIR(lCSource).
         IF byitem THEN 
         DO:
            REPEAT:
               IMPORT cItemImage ^ cFileType.
               IF cFileType EQ "F":U AND INDEX(cItemImage,".pdf") GT 0 THEN
               lcPdfpath = lCDomain + "/":U + cItemNumber + "/":U + Replace(cItemImage," ","%20").
                      
            END. 
         END.
         ELSE 
         DO:
            REPEAT: 
              IMPORT cItemImage ^ cFileType.
            
              IF cFileType EQ "F":U AND INDEX(cItemImage,".pdf") GT 0 AND INDEX(cItemImage , cItemNumber) GT 0  THEN
              lcPdfpath = lCDomain + "/":U +  Replace(cItemImage," ","%20").
            END.   
         END.    
      END.    
      RETURN lcPdfpath.
      
   END.  
 /*  
  /* Method to return the Image location */
  
   METHOD PUBLIC CHARACTER ImgDirectory (INPUT cItemNumber AS CHARACTER):
     FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
     IF AVAILABLE paramfl THEN 
        ASSIGN FILE-INFO:FILE-NAME = PARAMFL.PARAM-VALUE1 
               FILE-INFO:FILE-NAME =  FILE-INFO:FILE-NAME + "\" + cItemNumber NO-ERROR.
              
     IF FILE-INFO:FULL-PATHNAME NE ? THEN
     RETURN FILE-INFO:FULL-PATHNAME.
     ELSE 
     RETURN "".    
   END METHOD.  
   
   /* Method to return the Content Delivery Network location */
  
   METHOD PUBLIC CHARACTER FINDCDN ():
     FIND FIRST paramfl WHERE PARAMFL.PARAM-ID EQ "IMAGE-LOCATION":U NO-LOCK NO-ERROR.
     IF AVAILABLE paramfl THEN 
     RETURN PARAMFL.PARAM-VALUE2.
     
     ELSE 
     RETURN "".    
   END METHOD. */
                                          
END CLASS. /* finalCategoryFilterItem */