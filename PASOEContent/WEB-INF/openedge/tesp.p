USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.
DEFINE VARIABLE itemJsonObj1          AS CLASS     JsonObject        NO-UNDO.
DEFINE VARIABLE itemJsonArr   AS CLASS     JsonArray          NO-UNDO.
itemJsonArr  = NEW JsonArray().
FOR EACH cinv1 WHERE  CINV1.COMPANY-CODE EQ "1"
        AND  CINV1.CLASS-CODE   EQ     "1115" NO-LOCK:
   RUN createItemData (INPUT CINV1.ITEM-NUMBER,
                       OUTPUT itemJsonObj1).  
   itemJsonArr:ADD(INPUT itemJsonObj1).       
END. 

PROCEDURE createItemData:
DEFINE INPUT PARAMETER ipcItemNumber AS CHARACTER NO-UNDO.  
DEFINE OUTPUT PARAMETER itemJsonObj          AS CLASS     JsonObject        NO-UNDO.  
DEFINE VARIABLE ipdQtyOnHand  AS DECIMAL NO-UNDO.
DEFINE VARIABLE deQtyCommit   AS DECIMAL NO-UNDO.
DEFINE VARIABLE ipcCustNumber AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPriceList    AS CHARACTER NO-UNDO.

DEFINE VARIABLE cItemNumber   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cCompnyCode  AS CHARACTER NO-UNDO.
DEFINE VARIABLE ipcClassCode  AS CHARACTER NO-UNDO.
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
    DEFINE VARIABLE ipcPDFLink           AS CHARACTER NO-UNDO.
    
    DEFINE VARIABLE cSourceDir AS CHARACTER NO-UNDO.
   DEFINE VARIABLE CDomain    AS CHARACTER NO-UNDO.
   
   DEFINE VARIABLE ldMinPrice AS DECIMAL NO-UNDO.
     DEFINE VARIABLE cusertype AS CHARACTER NO-UNDO.
     DEFINE VARIABLE lcallPrice AS CHARACTER NO-UNDO.
     DEFINE VARIABLE ldUptoQty            AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldUptoQtyPrice       AS DECIMAL EXTENT 5 NO-UNDO.
    DEFINE VARIABLE ldPercent            AS DECIMAL          NO-UNDO.
    DEFINE VARIABLE ldbuyforFreeQty      AS DECIMAL NO-UNDO.
    DEFINE VARIABLE ldgetforFreeQty      AS DECIMAL NO-UNDO.
   DEFINE VARIABLE cItemImage           AS CHARACTER NO-UNDO.
    DEFINE VARIABLE cFileType            AS CHARACTER NO-UNDO.
    DEFINE VARIABLE Selling-PRC          AS DECIMAL   NO-UNDO.
    DEFINE VARIABLE BASE-PRC             AS DECIMAL   NO-UNDO.
   
    DEFINE VARIABLE SHIP-NO              AS CHARACTER NO-UNDO.
    DEFINE VARIABLE QTY-FULL             AS INTEGER   FORMAT "->>>9" NO-UNDO.
    DEFINE VARIABLE QTY-UNIT             AS INTEGER   FORMAT "->>>9" NO-UNDO.
 ASSIGN itemJsonObj          = NEW JsonObject() 
      itemFilterObj        = NEW JsonObject()
      orderTaxArr          = NEW JsonArray () 
      fabricJsonArr        = NEW JsonArray ()
      familyJsonArr        = NEW JsonArray ()
      makeJsonArr          = NEW JsonArray ()
      vendorJsonArr        = NEW JsonArray ()
      sizeJsonArr          = NEW JsonArray ()
      colorJsonArr         = NEW JsonArray ().
      pictureJsonArr       = NEW JsonArray ().
      prodInfoArr          = NEW JsonArray (). 
      
      objCustProductsPrice = NEW ProductPrices().
      objOrderTax          = NEW OrderTaxes().
  FIND FIRST cinv1 WHERE CINV1.ITEM-NUMBER =  ipcItemNumber.   
  ASSIGN ipcClassCode  = "1115"
         ipcCustNumber = "100075".    
 DEFINE VARIABLE iWareHouseNo AS INTEGER NO-UNDO.     
FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE = "1" NO-LOCK NO-ERROR.
IF AVAILABLE cmpny THEN 
        ASSIGN 
          iWareHouseNo = CMPNY.WHS-LOCATION 
          cCompnyCode  = CMPNY.COMPANY-CODE. 

    ipcItemNumber = CINV1.ITEM-NUMBER.        
    FIND FIRST CINV2 WHERE CINV2.ITEM-NUMBER  EQ ipcItemNumber
                       AND CINV2.WAREHOUSE-NO EQ iWareHouseNo NO-LOCK NO-ERROR.
                       
    IF AVAILABLE CINV2 THEN
      ASSIGN ipdQtyOnHand = CINV2.QTY-ONHAND - CINV2.QTY-COMMITED
             deQtyCommit  = CINV2.QTY-COMMITED.   

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
                                            INPUT cCompnyCode).
           
        
    END. /* IF AVAIL CCSMS THEN */
    DEFINE VAR iplSize like  cinv1.by-size NO-UNDO.
    DEFINE VAR iplByColor like  CINV1.BY-COLOR NO-UNDO.                                   
    iplSize = cinv1.by-size.
    iplByColor = CINV1.BY-COLOR.
    IF iplSize OR iplByColor THEN
    DO: 
      FOR EACH size WHERE SIZE.WAREHOUSE-NO EQ iWareHouseNo AND SIZE.ITEM-NUMBER EQ ipcItemNumber NO-LOCK:
        prodInfoObj  = NEW jsonObject ().
            
        IF SIZE.SIZE NE "":U THEN 
          sizeJsonArr:ADD(INPUT SIZE.SIZE).
        
        IF iplByColor AND SIZE.DESCRIPTION NE "":U THEN   
          colorJsonArr:ADD(INPUT SIZE.DESCRIPTION).
                     
        prodInfoObj:ADD(INPUT "size",       INPUT if size.size NE "" then size.size ELSE 'Not Applicable':U  ).
        prodInfoObj:ADD(INPUT "color",      INPUT IF iplByColor THEN SIZE.DESCRIPTION ELSE 'Not Applicable':U). 
        prodInfoObj:ADD(INPUT "in_stock",   INPUT (SIZE.QTY-ONHAND - SIZE.QTY-COMMITED)).
      //  prodInfoObj:ADD(INPUT "unit_price", INPUT SELLING-PRC).
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
            
    IF CINV1.FABRIC NE "":U THEN
      fabricJsonArr:ADD(INPUT CINV1.FABRIC).
        
    IF CINV1.FAMILY NE "":U THEN  
      familyJsonArr:ADD(INPUT CINV1.FAMILY).
      
    IF CINV1.VENDOR-NO NE "":U THEN  
      vendorJsonArr:ADD(INPUT CINV1.VENDOR-NO).
        
    IF CINV1.MAKE NE "":U THEN  
      makeJsonArr:ADD(INPUT CINV1.MAKE).
                    
    ASSIGN 
      cItemNumber = TRIM(ipcItemNumber).

    IF cItemNumber MATCHES "*" THEN
      ASSIGN cItemNumber = CAPS(TRIM(REPLACE(cItemNumber, "*", "-") , "-":U)).
     
   
      //cSourceDir = this-object:ImgDirectory(INPUT cItemNumber).
      //CDomain    = THIS-OBJECT:FINDCDN().
      IF cSourceDir NE "" THEN 
      DO:    
            
      INPUT FROM OS-DIR(cSourceDir).

      REPEAT:
        IMPORT cItemImage ^ cFileType.
        IF cFileType EQ "F":U THEN
          pictureJsonArr:ADD(CDomain + "/":U + cItemNumber + "/":U + Replace(cItemImage," ","%20")).
          //pictureJsonArr:ADD(INPUT ConstantInitializer:cImageDir + "/":U + cItemNumber + "/":U + cItemImage).             
      END.     
              
    END. /* IF FILE-INFO:FULL-PATHNAME NE ? THEN */

   itemFilterObj:ADD(INPUT "fabric":U, INPUT fabricJsonArr).
   itemFilterObj:ADD(INPUT "family":U, INPUT familyJsonArr).
    itemFilterObj:ADD(INPUT "vendor":U, INPUT vendorJsonArr).
    itemFilterObj:ADD(INPUT "make":U,   INPUT makeJsonArr).
    itemFilterObj:ADD(INPUT "size":U,   INPUT sizeJsonArr).
   itemFilterObj:ADD(INPUT "color":U,  INPUT colorJsonArr).
     
    /* Populate itemJsonObj jsonArray with all items record correspond to specific category by calling PopulateItem() method */           
    itemJsonObj:ADD(INPUT "class_code":U,      INPUT ipcClassCode).
    itemJsonObj:ADD(INPUT "item_number":U,     INPUT ipcItemNumber).
    itemJsonObj:ADD(INPUT "description":U,     INPUT CINV1.DESCRIPTION).
    itemJsonObj:ADD(INPUT "price":U,           INPUT SELLING-PRC).
    itemJsonObj:ADD(INPUT "qty_on_hand":U,     INPUT ipdQtyOnHand).
    itemJsonObj:ADD(INPUT "commit_qty":U,      INPUT deQtyCommit).


      itemJsonObj:ADD(INPUT "item_uom":U,      INPUT CINV1.ITEM-UOM).
      itemJsonObj:ADD(INPUT "uom_qty":U,       INPUT CINV1.UOM-QTY).
      itemJsonObj:ADD(INPUT "on_order":U,      INPUT CINV1.QTY-ON-ORDER).
   
      
    IF ipcPDFLink NE "":U THEN
    DO:
      FILE-INFO:FILE-NAME = ConstantInitializer:cPDFDir + "/":U + ipcPDFLink + ".pdf".

      IF FILE-INFO:FULL-PATHNAME NE ? THEN
      DO:
        itemJsonObj:ADD(INPUT "pdf_link":U, INPUT ConstantInitializer:cPDFDir + "/":U + ipcPDFLink + ".pdf").
      END.
      
/*      ELSE                                                                                  */
/*        itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(CINV1.ITEM-NUMBER ) ).*/
/*        itemJsonObj:ADD(INPUT "pdf_link":U, INPUT "":U).                                    */
    END.
    
/*    ELSE                                                                                  */
/*      itemJsonObj:ADD(INPUT "pdf_link":U, INPUT THIS-OBJECT:PdfLink(CINV1.ITEM-NUMBER ) ).*/
/*      itemJsonObj:ADD(INPUT "pdf_link":U, INPUT "":U).                                    */
       
    itemJsonObj:ADD(INPUT "isTopSeller":U,     INPUT "").
    itemJsonObj:ADD(INPUT "pictures":U,        INPUT pictureJsonArr).
    itemJsonObj:Add(INPUT "more_product_data", INPUT prodInfoArr).
    itemJsonObj:ADD(INPUT "item_filters":U,    INPUT itemFilterObj).
      
    objOrderTax:getItemTaxForShipping(INPUT ipcItemNumber,
                                      INPUT cCompnyCode,
                                      INPUT ipcCustNumber,
                                      INPUT iWareHouseNo,
                                      INPUT "",
                                      INPUT SELLING-PRC,
                                      OUTPUT orderTaxArr). 
                                        
    itemJsonObj:Add(INPUT "item_tax_unit", INPUT orderTaxArr).
     
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
       
                 
        FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = CMPNY.COMPANY-CODE
                               AND PARAMFL.PARAM-ID     = "show-all-cinv3"
                               AND PARAMFL.PARAM-STATUS = YES NO-LOCK NO-ERROR. 
         if available PARAMFL then 
         DO:
           
           FOR EACH  CINV3 WHERE CINV3.ITEM-NUMBER   =  ipcItemNumber 
                        AND NOT CINV3.PRICE-LIST MATCHES "*TAX*"  /*20160625 MFA*/
                        AND CINV3.PRIVATE-CODE <> "P"  NO-LOCK:  
        
            if lcallPrice NE "" THEN 
             assign lcallPrice = lcallPrice + "|".
                               
            assign lcallPrice = lcallPrice + STRING(CINV3.BREAK-PRICE) .
                             
           END.  
      
            
            itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT lcallPrice).
           END. 
           ELSE 
           itemJsonObj:ADD(INPUT "item_all_price":U,      INPUT lcallPrice).
           lcallPrice = "".
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
               ldgetforFreeQty    = OFERT.FREE-CASES.
               
               
    END.
     IF cusertype = "mobileuser":u THEN 
     DO:
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
     END.
    
            
            

END PROCEDURE. 
              