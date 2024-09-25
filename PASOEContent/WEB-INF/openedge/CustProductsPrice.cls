 
 /*------------------------------------------------------------------------
    File        : CustProductsPrice
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : JKTECH
    Created     : Fri Oct 06 13:35:55 IST 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS CustProductsPrice: 
  /*------------------------------------------------------------------------------
   Purpose: 
   Notes:
  ------------------------------------------------------------------------------*/
  
  CONSTRUCTOR PUBLIC CustProductsPrice ():
   
  END CONSTRUCTOR.
  
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC CustProductsPrice (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
  END CONSTRUCTOR.
  
  /*-------------------------------------------------------------------------------------------------------------------
   Purpose: This method is used to assign price to a specific item correspond to specific customer.
  --------------------------------------------------------------------------------------------------------------------*/ 
  METHOD PUBLIC VOID getPrice(INPUT  CUST-NUMBER       AS CHARACTER ,
                              INPUT  ITEM-NUMBER       AS CHARACTER,
                              INPUT  COMPANY           AS CHARACTER, 
                              INPUT  PERCENT           AS DECIMAL,
                              INPUT  PRICE-LIST        AS CHARACTER,
                              INPUT  LOOKUP-LIST       AS LOGICAL,
                              INPUT  contract-ind      LIKE CCSMS.CONTRACT-IND,
                              INPUT  SPEC-DICT-I       LIKE CCSMS.SPEC-DICT-I,
                              INPUT  qty-brk-cd        LIKE CCSMS.QTY-BRK-CD,
                              INPUT  TMP-CUST-TYPE     LIKE CCSMS.CUST-TYPE,
                              OUTPUT SELLING-PRC       AS DECIMAL /*CHARACTER*/,
                              OUTPUT BASE-PRC          AS DECIMAL /*CHARACTER*/ ):
                            
                                 
    DEF VARIABLE  QTY-FULL   AS INTEGER INITIAL 0 NO-UNDO.  /* Comes always zero because cart is empty           */
    DEF VARIABLE  QTY-UNIT   AS INTEGER INITIAL 0 NO-UNDO. /* This variable is always zero in existing ERP also */
    
 
    DEF VAR used-cost       AS DECIMAL.
    DEF VAR BLANK-LIST      AS LOGICAL.

    DEF VAR USE-SLSMN-COST  AS LOG  NO-UNDO.  
  
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "BLANK-LIST":U 
                   AND PARAMFL.COMPANY-CODE EQ COMPANY 
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.  
    IF AVAILABLE PARAMFL THEN 
      ASSIGN BLANK-LIST = YES. 
    ELSE 
      ASSIGN BLANK-LIST = NO.
      
    /* 02/17/2016 WAM NUÑEZ START */
    /********************************************************/
    /* use salesman cost for price calculations             */
    /********************************************************/
    FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "PRICE-USE-SLSMN-COST" 
                   AND PARAMFL.COMPANY-CODE EQ COMPANY 
                   AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR. 
    
      ASSIGN USE-SLSMN-COST = AVAILABLE PARAMFL.
    /* 02/17/2016 WAM NUÑEZ  END */
 
    /* WARNING THIS PROGRAM IS EXECUTED FROM THE ITEM INQUIRY  */ 
    FIND CINV1 WHERE CINV1.ITEM-NUMBER EQ ITEM-NUMBER NO-LOCK NO-ERROR. 
    IF AVAIL CINV1 THEN
    DO:     
      FIND SETHD WHERE SETHD.SET-NO EQ ITEM-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE SETHD THEN 
        ASSIGN used-cost = qty-unit / 100.    
      ELSE
        IF CINV1.ACCTING-COST > CINV1.LANDED-COST THEN
          ASSIGN used-cost = CINV1.ACCTING-COST.
        ELSE
          ASSIGN used-cost = CINV1.LANDED-COST.
     
      /* en garcia freight-pct tiene el trade-cost de ford*/
      IF blank-list AND CINV1.FREIGHT-PCT > 0 THEN USED-COST = CINV1.FREIGHT-PCT.
     
      /* 02/17/2016 WAM NUÑEZ START*/
      IF USE-SLSMN-COST THEN   
        ASSIGN USED-COST = CINV1.SLSMN-COST.
      /* 02/17/2016 WAM NUÑEZ END */ 
     
      ASSIGN SELLING-PRC = CINV1.BASE-PRICE.
     
      IF LOOKUP-LIST THEN
      DO: 
        IF CONTRACT-IND = "S" AND 
           CAN-FIND (CINV3 WHERE CINV3.ITEM-NUMBER = ITEM-NUMBER
                             AND CINV3.PRICE-LIST  = "S") THEN
          DO: 
            FIND CINV3 WHERE CINV3.ITEM-NUMBER  = ITEM-NUMBER
                         AND CINV3.PRICE-LIST   = "S" NO-LOCK NO-ERROR.
                           
            IF AVAILABLE CINV3 THEN
              ASSIGN 
                SELLING-PRC = CINV3.BREAK-PRICE
                BASE-PRC    = SELLING-PRC.
                
          END. /* IF CONTRACT-IND = "S" AND CAN-FIND */
          ELSE
          DO: 
            IF PRICE-LIST <> " " OR BLANK-LIST THEN
            DO: 
              /* victor  nunez 06/27/16*/
              FIND CINV3 WHERE CINV3.ITEM-NUMBER = ITEM-NUMBER
                           AND CINV3.PRICE-LIST  = CUST-NUMBER NO-LOCK NO-ERROR.
              
              IF NOT AVAILABLE CINV3 THEN     
     
                FIND CINV3 WHERE CINV3.ITEM-NUMBER = ITEM-NUMBER
                             AND CINV3.PRICE-LIST  = PRICE-LIST NO-LOCK NO-ERROR.
     
                IF NOT AVAILABLE CINV3 AND (CONTRACT-IND = "E" OR CONTRACT-IND = "A") THEN
                DO:
                  ASSIGN LOOKUP-LIST = NO.
                  /*  MESSAGE 
                    "PRODUCT NOT ON CONTRACT" 
                    VIEW-AS ALERT-BOX. */ /* JKT */
                  UNDO, RETRY. 
                END.
              
             /* We don't require this functionality as we don't have ship-no */
             /*   IF AVAILABLE CINV3    AND 
                   CONTRACT-IND = "E"   AND  
                 /*  SHIP-NO <> " "     AND */ /* this condition is always true as ship-no always be ? */  
                   CINV3.PRC-BREAK-ID <> " " AND 
                   (
                   (SUBSTRING(CINV3.PRC-BREAK-ID,1,3) = "NOT"  AND 
                    SUBSTRING(CINV3.PRC-BREAK-ID,5) = SHIP-NO) OR 
                   (SUBSTRING(CINV3.PRC-BREAK-ID,1,3) <> "NOT" AND 
                    CINV3.PRC-BREAK-ID <> SHIP-NO)
                   ) THEN
                DO:
                  ASSIGN LOOKUP-LIST = NO.
                  MESSAGE 
                  "PRODUCT NOT ON CONTRACT FOR THAT SHIP-TO".
                  UNDO, RETRY.
                END. */ /* We don't require this functionality */
                  
              /********************************************************/
              /* CHECK FOR RECORD BY CLASS CODE                       */
              /********************************************************/
              
              /*DEBUG-FIX-II*/
                IF NOT AVAILABLE cinv3 THEN 
                  FIND CINV3 WHERE CINV3.ITEM-NUMBER = cinv1.class-code 
                               AND CINV3.PRICE-LIST  = PRICE-LIST 
                               AND cinv3.PRC-BREAK-ID = "C" NO-LOCK NO-ERROR.
     
                IF NOT AVAILABLE cinv3 THEN 
                  FIND CINV3 WHERE CINV3.ITEM-NUMBER = cinv1.class-code 
                               AND CINV3.PRICE-LIST  = PRICE-LIST 
                               AND cinv3.PRC-BREAK-ID = "F" NO-LOCK NO-ERROR.
     
                IF NOT AVAILABLE cinv3 THEN 
                  FIND CINV3 WHERE CINV3.ITEM-NUMBER = cinv1.class-code 
                               AND CINV3.PRICE-LIST  = PRICE-LIST 
                               AND cinv3.PRC-BREAK-ID = "%" NO-LOCK NO-ERROR.
     
                /***** COMMONWEALTH 08/14/09 START WAM *******************************/
                /********************************************************/
                /* RECORD TO APPLY MARK UP PERCENT TO THE COST          */
                /********************************************************/
                IF NOT AVAILABLE cinv3 THEN 
                  FIND CINV3 WHERE CINV3.ITEM-NUMBER = cinv1.class-code 
                               AND CINV3.PRICE-LIST  = PRICE-LIST 
                               AND cinv3.PRC-BREAK-ID = "M" NO-LOCK NO-ERROR.
     
               /***** COMMONWEALTH 08/14/09  END  WAM *******************************/
     
               /*** 10/17/2012 wam start atonit ***/
               /********************************************************/
               /* LISTA de precio para todos los items de un cliente   */
               /********************************************************/
               IF NOT AVAILABLE cinv3 THEN 
                 FIND CINV3 WHERE CINV3.ITEM-NUMBER   = CUST-NUMBER 
                              AND CINV3.PRICE-LIST    = PRICE-LIST NO-LOCK NO-ERROR.
               /*** 10/17/2012 wam  end  atonit ***/
     
               /**
               IF USERID("cdi") BEGINS "cdi" THEN
               DO:
                 MESSAGE
                 "1" SKIP 
                 "AVAIL CINV3"   AVAILABLE CINV3 SKIP
                 "cinv1.class-code"      cinv1.class-code    SKIP
                 "PRICE-LIST"            PRICE-LIST          SKIP
                 "SELLING-PRC"           SELLING-PRC         SKIP 
                 "USED-COST"             USED-COST           SKIP
                 "cinv1.accting-cost"    cinv1.accting-cost  SKIP
                 "cinv1.landed-cost"     cinv1.landed-cost   SKIP
                 "cinv3.prc-break-id"    cinv3.prc-break-id  SKIP
                 "cinv3.break-price "    cinv3.break-price   SKIP
                 "PERCENT"               PERCENT             SKIP
                 VIEW-AS ALERT-BOX
                 TITLE "DEBUG - OEPRICE.p".
     
               END.
     
     
                **/
     
               /*DEBUG-FIX-II*/
     
               IF NOT AVAILABLE CINV3 THEN
               DO:
                /* MESSAGE 
                  "Price List "      PRICE-LIST
                  " For Item Number " ITEM-NUMBER
                  " Not Found".
     
                 MESSAGE  "Base Price of Inventory File Will Be Used". */ /* JKT */
     
                 IF SPEC-DICT-I = "" THEN
                   SELLING-PRC = CINV1.BASE-PRICE * (1 - (PERCENT / 100)).
                 ELSE
                   SELLING-PRC = CINV1.BASE-PRICE.
     
                 IF SPEC-DICT-I = "A" THEN
                   SELLING-PRC = CINV1.BASE-PRICE.
     
                 ASSIGN BASE-PRC    = SELLING-PRC.
               END. /* IF NOT AVAILABLE CINV3 */
               ELSE
               DO:
                 IF SPEC-DICT-I = "" THEN
                 DO:
                   IF cinv3.prc-break-id = "c" THEN
                      selling-prc = 
                      used-cost / (1 - cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                   ELSE
                     IF cinv3.prc-break-id = "F" THEN
                       selling-prc = 
                       used-cost / (1 - cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                     ELSE
                       IF CINV3.PRC-BREAK-ID = "%" THEN
                         ASSIGN 
                           SELLING-PRC  = CINV1.BASE-PRICE 
                                        - (CINV3.BREAK-PRICE * CINV1.BASE-PRICE / 100)
                                        * (1 - (PERCENT / 100)).
                       ELSE
                       /***** COMMONWEALTH 08/14/09 START WAM *******************************/
                       /********************************************************/
                       /* APPLY MARK UP PERCENT TO THE COST                    */
                       /********************************************************/
                         IF cinv3.prc-break-id = "M" THEN 
                           ASSIGN
                             selling-prc = 
                             used-cost * (1 + cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                        /***** COMMONWEALTH 08/14/09  END  WAM *******************************/
                        /*** blanks or any other value ****/
                         ELSE
                           IF CINV3.PRC-BREAK-ID <> "%" THEN
                             ASSIGN 
                               SELLING-PRC = CINV3.BREAK-PRICE * (1 - (PERCENT / 100)).
                 END. /*  IF SPEC-DICT-I = "" */
                 ELSE
                 DO:
                   IF CINV3.PRC-BREAK-ID <> "%" THEN
                   DO:
                     IF CINV3.PRC-BREAK-ID = "C" THEN
                     DO:
                       ASSIGN selling-prc = used-cost / ( 1 - cinv3.break-price * 100).
                     END. /* IF CINV3.PRC-BREAK-ID = "C" */
                     ELSE
                     IF CINV3.PRC-BREAK-ID = "F" THEN
                     DO:
                       ASSIGN selling-prc = used-cost / ( 1 - cinv3.break-price * 100).
                     END.  /* IF CINV3.PRC-BREAK-ID = "F" */
                     ELSE
                     DO:
                       /***** COMMONWEALTH 08/14/09 START WAM *******************************/
                       /********************************************************/
                       /* APPLY MARK UP PERCENT TO THE COST                    */
                       /********************************************************/
                       IF cinv3.prc-break-id = "M" THEN 
                         ASSIGN
                           selling-prc = 
                           used-cost * (1 + cinv3.break-price / 100) * (1 - (PERCENT / 100)).
                           /***** COMMONWEALTH 08/14/09  END  WAM *******************************/
                       ELSE
                       DO:
                         ASSIGN SELLING-PRC = CINV3.BREAK-PRICE.
     
                         IF SPEC-DICT-I = "A" THEN
                           ASSIGN 
                             SELLING-PRC = CINV3.BREAK-PRICE
                             BASE-PRC    = SELLING-PRC.
                       END. /*  IF cinv3.prc-break-id = "M" */
     
                     END. /* ELSE IF CINV3.PRC-BREAK-ID = "F" */
                   END. /* IF CINV3.PRC-BREAK-ID <> "%" */
                   ELSE
                   DO:
                     ASSIGN 
                       SELLING-PRC = CINV1.BASE-PRICE 
                                   - (CINV3.BREAK-PRICE * CINV1.BASE-PRICE / 100) 
                                   * (1 - (PERCENT / 100)).
     
                     IF SPEC-DICT-I = "A" THEN
                       ASSIGN 
                         SELLING-PRC  = CINV1.BASE-PRICE 
                                      -(CINV3.BREAK-PRICE * CINV1.BASE-PRICE / 100) 
                                      * (1 - (PERCENT / 100))
                         BASE-PRC     = SELLING-PRC.
                   END. /* else IF CINV3.PRC-BREAK-ID <> "%" */
                 END. /* else IF SPEC-DICT-I = "" */
               END. /* IF NOT AVAILABLE CINV3 */
             END. /* IF PRICE-LIST <> " " OR BLANK-LIST */
             ELSE
             DO: 
               IF SPEC-DICT-I = "" THEN
               DO:
                 ASSIGN SELLING-PRC = CINV1.BASE-PRICE * (1 - (PERCENT / 100)).
               END.   
               ELSE
                 ASSIGN SELLING-PRC = CINV1.BASE-PRICE.
     
               IF SPEC-DICT-I = "A" THEN
                 ASSIGN 
                 SELLING-PRC = CINV1.BASE-PRICE
                 BASE-PRC    = SELLING-PRC.
     
               IF SPEC-DICT-I = "" AND PERCENT <> 0 THEN
                 ASSIGN PERCENT = PERCENT.
     
               /* HELAPAN */
               IF PERCENT < 0 AND 
                 qty-brk-cd = "" THEN
                 
                 SELLING-PRC = (used-cost /*CINV1.ACCTING-COST*/ / PERCENT * -1). /* 11/07/2012 wam atonit */
               ELSE
               IF PERCENT < 0 AND 
                  qty-brk-cd = "S" THEN
                  
                  SELLING-PRC = (used-cost /*CINV1.slsmn-COST*/ / PERCENT * -1). /* 11/07/2012 wam atonit */ 
     
               BASE-PRC    = CINV1.BASE-PRICE.
                 
            /* HELAPAN LISTA DE PRECIOS ESPECIAL PARA ITEM INV-TYPE = UOM
               CUANDO SE VENDE UNIDADES Y NO CAJAS */
                   
            /* This piece of code will never execute
               because QTY-FULL is zero and in legacy application
               this condition is not executing */ /* JKT Uncomment if required */
                
            /*   IF CINV1.INV-TYPE = "UOM"     AND 
                 abs(QTY-FULL) < 100 AND 
                 ABS(qty-full) > 0   AND
                 /*QTY-UNIT       <> 0        AND*/
                 int(QTY-full / 100 * cinv1.uom-qty) <= CINV1.UOM-QTY THEN
               DO: 
                 FIND PARAMFL WHERE PARAMFL.COMPANY-CODE = SUBSTRING(CINV1.ITEM-NUMBER,1,1)
                                AND PARAMFL.PARAM-ID     = "PRECIO-UOM"
                                AND PARAMFL.PARAM-STATUS   NO-LOCK NO-ERROR.
                 IF AVAILABLE PARAMFL THEN 
                 DO:
                   FIND CINV3 WHERE CINV3.ITEM-NUMBER = CINV1.ITEM-NUMBER 
                                 AND CINV3.PRICE-LIST = PARAMFL.PARAM-VALUE1 
                   NO-LOCK NO-ERROR.
     
                   IF AVAILABLE CINV3 THEN
                   DO:
                     SELLING-PRC = CINV3.BREAK-PRICE.
     
                     IF CINV1.BY-WEIGHT <> "F" AND 
                        CINV1.BY-WEIGHT <> "V" THEN
                        SELLING-PRC = SELLING-PRC * CINV1.UOM-QTY.
                     ELSE 
                        selling-prc = selling-prc * qty-unit.  /*HOTLINE #88303 */
                   END.  /* IF AVAILABLE CINV3 */
                 END. /* IF AVAILABLE PARAMFL */
               END. /* IF CINV1.INV-TYPE = "UOM" AND abs(QTY-FULL) < 100 AND ABS(qty-full) > 0...*/ */
     
                /* -------------------------------------------------- */
             END.  /* else IF PRICE-LIST <> " " OR BLANK-LIST */
     
            /*DO:   HL#120930(ACASIGN)20080818*/
             DEF BUFFER binv3 FOR cinv3.
             DEF VAR cant     AS DECIMAL NO-UNDO.
             DEF VAR prc-sell AS DECIMAL.
             DEF VAR cnt      AS INTEGER.
     
             cant = qty-full / 100.
             /*HL#120930(20080818)*/
             IF TMP-CUST-TYPE = "TIENDA"  OR 
                TMP-CUST-TYPE = "STORE"   THEN
             DO:
              
             END. /* IF TMP-CUST-TYPE = "TIENDA"  OR TMP-CUST-TYPE = "STORE" */
             ELSE
             DO:  
               /*HL#120930(ACASIGN): EVITAR LAS OFERTAS CUANDO SON TRANSFERS*/
               FIND ofert WHERE ofert.price-list  = cinv1.item-uom
                            AND ofert.item-number = "OFERTAS"
                            AND OFERT.FROM-DT     <= TODAY
                            AND OFERT.TO-DT       >= TODAY NO-LOCK NO-ERROR.
     
               IF AVAILABLE OFERT THEN
               DO:
                 IF CANT > UP-TO-QTY[5]  AND 
                  CAN-FIND (BINV3 WHERE BINV3.PRICE-LIST  = "6" 
                                    AND BINV3.ITEM-NUMBER = CINV1.ITEM-NUMBER) THEN
                 DO:
                   FIND BINV3 WHERE BINV3.PRICE-LIST  = "6"
                                AND BINV3.ITEM-NUMBER = CINV1.ITEM-NUMBER NO-LOCK NO-ERROR.
                      /*DEBUG-FIX-II*/
                   IF NOT AVAILABLE Binv3  THEN 
                     FIND BINV3 WHERE BINV3.ITEM-NUMBER = cinv1.class-code 
                                  AND BINV3.PRICE-LIST  = "6" 
                                  AND Binv3.PRC-BREAK-ID = "C"
                     NO-LOCK NO-ERROR.
                       /*DEBUG-FIX-II*/
     
                     IF AVAILABLE binv3 THEN
                     DO:
                       IF binv3.PRC-BREAK-ID = "C" THEN
                         ASSIGN 
                           PRC-SELL = used-cost / (1 - (binv3.break-price / 100)).
                       ELSE
                       IF binv3.prc-break-id = "%" THEN                        
                         ASSIGN 
                           prc-sell = cinv1.base-price * (1 - (binv3.break-price / 100)).
                       ELSE
                         ASSIGN prc-sell = binv3.break-price.
                     END. /*  IF AVAILABLE binv3*/
                     
                 END. /*  IF CANT > UP-TO-QTY[5]  AND CAN-FIND ... */
                 ELSE
                 DO CNT = 5 TO 1 BY -1:
                   IF CANT <= UP-TO-QTY[CNT] THEN
                   DO:
                     FIND BINV3 WHERE BINV3.PRICE-LIST  = string(CNT,"9")
                                  AND BINV3.ITEM-NUMBER = CINV1.ITEM-NUMBER NO-LOCK NO-ERROR.
                          /*DEBUG-FIX-II*/
                     IF NOT AVAILABLE Binv3 THEN 
                       FIND BINV3 WHERE BINV3.ITEM-NUMBER = cinv1.class-code 
                                    AND BINV3.PRICE-LIST  = string(CNT,"9") 
                                    AND Binv3.PRC-BREAK-ID = "C" NO-LOCK NO-ERROR.
                          /*DEBUG-FIX-II*/
     
                       IF AVAILABLE binv3 THEN
                       DO:
                         IF binv3.PRC-BREAK-ID = "C" THEN
                           ASSIGN 
                             PRC-SELL = used-cost /  (1 - (binv3.break-price / 100)).
                         ELSE
                         IF binv3.prc-break-id = "%" THEN
                           ASSIGN 
                             prc-sell = cinv1.base-price * (1 - (binv3.break-price / 100)).
                         ELSE
                           ASSIGN prc-sell = binv3.break-price.
                       END. /* IF AVAILABLE binv3 */
                   END. /* IF CANT <= UP-TO-QTY[CNT]*/
                 END. /* DO CNT = 5 TO 1 BY -1:*/
     
                 IF PRC-SELL < SELLING-PRC AND prc-sell > 0 THEN
                   ASSIGN 
                     SELLING-PRC = PRC-SELL
                     base-prc = SELLING-PRC.
   
               END.  /* IF AVAILABLE OFERT */
                
             END. /* else IF TMP-CUST-TYPE = "TIENDA"  OR TMP-CUST-TYPE = "STORE" */
              
           END. /* else IF CONTRACT-IND = "S" AND CAN-FIND  */
            
         END. /* IF LOOKUP-LIST */
          
  END. /* IF AVAIL CINV1 THEN */
      
  END METHOD. /*END of getPrice(...)*/  
  
END CLASS.