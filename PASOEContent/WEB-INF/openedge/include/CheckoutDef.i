
/*------------------------------------------------------------------------
    File        : CheckoutDef.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Fri Jan 12 15:53:52 IST 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */

DEF TEMP-TABLE TMP-DETAIL
    FIELD TMP-NUMBER            AS CHARACTER FORMAT "X(8)"
    FIELD TMP-SEQ               AS INTEGER FORMAT ">>9"
    FIELD ITEM-NUMBER           AS CHARACTER FORMAT "X(20)"
    FIELD DESCRIPTION           AS CHARACTER FORMAT "X(30)"
    FIELD ITEM-UOM              AS CHARACTER
    FIELD BASE-PRICE            AS DECIMAL
    FIELD PRICE                 AS DECIMAL   FORMAT "->>>>>>>9.99"   /*wam 08/22/2006*/
    FIELD QUANTITY              AS DECIMAL
    FIELD EXTENSION             AS DECIMAL   FORMAT "->>>>>>>9.99"   /*wam 08/22/2006*/
    FIELD SALES-TX-CODE         AS CHARACTER FORMAT "XX"
    FIELD PRICE-CATGRY          AS CHARACTER FORMAT "X"
    FIELD SET-ID                AS CHARACTER FORMAT "X"
    FIELD SET-LINE              AS INTEGER FORMAT ">>9"
    FIELD CASE-QTY              AS INTEGER FORMAT "->>>>>>"
    FIELD UNIT-QTY              AS INTEGER FORMAT "->>>>>"
    FIELD BOXES                 AS DECIMAL FORMAT "->>>>>.<<<"
    FIELD FASE-1                AS DATE
    FIELD FASE-2                AS DATE
    FIELD SALES-TX-AMT          AS DECIMAL
    FIELD CONTRACT-NO           AS CHARACTER FORMAT "X(6)"
    FIELD DISPATCH-LOT          AS CHARACTER FORMAT "X(12)"
    FIELD COMMITED-LOT          AS CHARACTER FORMAT "X(12)"
    FIELD ACCTING-COST          AS DECIMAL
    FIELD SALES-COMM-%          AS CHARACTER
    FIELD CLASS-CODE            AS CHARACTER
    FIELD ORIGINAL-QTY          AS DECIMAL
    FIELD WAREHOUSE-NO          AS INTEGER
    FIELD ORDERED-CST           AS DECIMAL
    FIELD VDR-ITEM-NO           AS CHARACTER
    FIELD QTY-BKORDER           AS DECIMAL
    FIELD COMMISION-%           AS DECIMAL
    FIELD ITEM-CLASS            AS CHARACTER
    FIELD SALE-TAX-AMT          AS DECIMAL
    FIELD SALE-TX-CODE          AS CHARACTER
    FIELD UNIT-MEASURE          AS CHARACTER
    FIELD QTY-ORDERED           AS DECIMAL
    FIELD ACTION-REQUIRED       AS LOGICAL INITIAL NO
    FIELD SELECTED-TYPE         AS CHARACTER INITIAL "0"
    FIELD DELIV-STATUS          AS CHAR
    FIELD WEIGHT                AS DECIMAL
    FIELD OEPRECIO              AS LOGICAL
    FIELD LAST-PRICE            AS DECIMAL
    FIELD USED-COST             AS DECIMAL
    FIELD DELIVERD-QTY          AS DECIMAL 
    FIELD damaged               AS LOGICAL
    FIELD conduce-qty           AS DECIMAL 
 
    /* para uso de oeuomcv.p ----------------------- */
    FIELD LOG-FACT              AS LOGICAL
    FIELD USER-FACT             AS DECIMAL FORMAT "->>,>>9.9999"
    FIELD MULT-FACT             AS DECIMAL FORMAT "->>,>>9.9999" EXTENT 5
    FIELD DIV-FACT              AS DECIMAL FORMAT "->>,>>9.9999" EXTENT 5
    FIELD MULT-DESC             AS CHAR FORMAT "X(15)"           EXTENT 5
    FIELD DIV-DESC              AS CHAR FORMAT "X(15)"           EXTENT 5
    /* para uso de oeuomcv.p ----------------------- */
 
    /* casas -------------------------------*/
    FIELD SA-PRICE              AS DECIMAL  
    FIELD SA-orig-price         AS DECIMAL  
    FIELD SA-orig-qty           AS DECIMAL
    FIELD SA-ADDED-ITEM         AS LOGICAL 
    FIELD SA-SUB-LINE           AS INTEGER 
    /* casas  -------------------------------*/
    FIELD tech-id               AS CHAR
    FIELD DT-ASSIGNED           AS DATE
    FIELD uom-qty               LIKE cinv1.uom-qty 
    FIELD AUTOMOVIL             AS LOGICAL 
    FIELD auto-lic              AS CHAR FORMAT "x(7)"
    FIELD auto-fin              AS CHAR FORMAT "x" 
    FIELD SASI-CODE             AS CHAR FORMAT "X(12)"
    /* BERRIOS START ----------------------*/ 
    FIELD ORG-ITEM-NO           AS CHAR    FORMAT "X(16)"
    FIELD ORG-ITEM-SEQ          AS INTEGER FORMAT ">>9"
    FIELD org-order-seq         AS INTEGER FORMAT ">>9"
    /* BERRIOS END  ----------------------*/ 
 
    FIELD RATE-COMPONENTE       AS DECIMAL 
 
    /*** wam Toledo start ***/
    FIELD dt-char1              AS CHAR
    FIELD dt-char2              AS CHAR
    FIELD dt-char3              AS CHAR
    FIELD call-no               AS CHAR
    FIELD po-number             AS CHAR
    FIELD ref-no                AS CHAR 
    /*** wam Toledo  end  ***/
 
    /*** wam Steel start ***/
    FIELD dt-city-tax-amt       AS DEC
    FIELD dt-state-tax-amt      AS DEC
    FIELD dt-city-tax-pct       AS DEC
    FIELD dt-state-tax-pct      AS DEC
    /*** wam Steel start ***/
 
    /* wam NUÑEZ start */
    FIELD LINEA-NUEVA           AS CHAR
    /*  wam NUÑEZ start */
    INDEX DETAIL-KEY IS UNIQUE 
    TMP-NUMBER
    TMP-SEQ
    ITEM-NUMBER /* whrfupd2.p when using replacement items*/
 
    INDEX ACTION-REQ ACTION-REQUIRED
 
    /* BERRIOS START ----------------------*/ 
    INDEX warranty-KEY 
    TMP-NUMBER
    ORG-ITEM-SEQ
    ORG-ITEM-NO.
    
DEF TEMP-TABLE TMP-HEADER
    FIELD TMP-NUMBER            AS CHARACTER FORMAT "X(8)"
    FIELD CUST-NUMBER           AS CHARACTER FORMAT "X(8)"
    FIELD CUST-NAME             AS CHARACTER FORMAT "X(30)"
    FIELD ADDRESS-L1            AS CHARACTER FORMAT "X(30)"
    FIELD ADDRESS-L2            AS CHARACTER FORMAT "X(30)"
    FIELD ADDRESS-L3            AS CHARACTER FORMAT "X(30)"
    FIELD CUST-PHONE-NUMBER     AS CHARACTER FORMAT "(XXX) XXX-XXXX" /* wam BERRIOS */
    FIELD SHIP-TO-NAME          AS CHARACTER FORMAT "X(30)"
    FIELD SHIP-ADDR-L1          AS CHARACTER FORMAT "X(30)"
    FIELD SHIP-ADDR-L2          AS CHARACTER FORMAT "X(30)"
    FIELD SHIP-ADDR-L3          AS CHARACTER FORMAT "X(30)"
    FIELD shipto-PHONE-NUMBER   AS CHARACTER FORMAT "(XXX) XXX-XXXX" /* wam BERRIOS */
    FIELD ORDER-DATE            AS DATE
    FIELD INVOICE-DATE          AS DATE
    FIELD SHIP-DATE             AS DATE
    FIELD SHIP-VIA-CD           AS CHARACTER FORMAT "X(4)"
    FIELD SHIP-VIA-DS           AS CHARACTER FORMAT "X(20)"
    FIELD SALES-REP-ID          AS CHARACTER FORMAT "X(6)"
    FIELD COMPANY-CODE          AS CHARACTER FORMAT "X"
    FIELD CUS-TERMS-DS          AS CHARACTER FORMAT "X(30)"
    FIELD CUS-TERMS-CD          AS CHARACTER FORMAT "XX"
    FIELD FORM-ID               AS CHARACTER FORMAT "XX"
    FIELD SALE-TX-CODE          AS CHARACTER FORMAT "XX"
    FIELD OPERATOR-CODE         AS CHARACTER
    FIELD DROP-SHIP             AS LOGICAL
    FIELD CONDUCE-NUM           AS CHARACTER FORMAT "X(8)"
    FIELD ORDER-NUMBER          AS CHARACTER FORMAT "X(8)"
    FIELD LAPTOP                AS LOGICAL
    FIELD ORDER-AMOUNT          AS DECIMAL
    FIELD ROUTE                 AS CHARACTER
    FIELD CUS-ORDER-NO          AS CHARACTER FORMAT "X(8)"
    FIELD CUS-ORDER-DT          AS DATE
    FIELD GROSS-AMOUNT          AS DECIMAL   FORMAT "->>,>>>.99"
    FIELD DISCOUNT-AMT          AS DECIMAL   FORMAT "->>,>>>.99"
    FIELD DISC-PERC             AS DECIMAL   FORMAT "->>,>>>.99"
    FIELD FREIGHT-AMT           AS DECIMAL   FORMAT "->>,>>>.99"
    FIELD MISC-CHG-AMT          AS DECIMAL   FORMAT "->>,>>>.99"
    FIELD TERMINAL-ID           AS CHARACTER FORMAT "X(20)"
    FIELD OPERATOR              AS CHARACTER FORMAT "X(8)"
    FIELD HOUR                  AS CHARACTER FORMAT "X(8)"
    FIELD WAREHOUSE-NO          AS INTEGER   FORMAT "99"
    FIELD SALES-TX-AMT          AS DECIMAL
    FIELD COMMISION-AMT         AS DECIMAL
    FIELD SHIP-TO-NO            AS CHARACTER
    FIELD CITY-TAX-AMT          AS DECIMAL
    FIELD STATE-TAX-AMT         AS DECIMAL
    FIELD CITY-TAX-EXEMPT       AS LOGICAL VIEW-AS TOGGLE-BOX
    FIELD STATE-TAX-EXEMPT      AS LOGICAL VIEW-AS TOGGLE-BOX
    FIELD ON-ORDER-AMT          AS DECIMAL
    FIELD DATE-WANTED           AS DATE
    FIELD PICKER                AS CHAR
    FIELD credit-approved       AS LOGICAL INITIAL NO
    FIELD CONFIRM-IND           AS CHAR
    FIELD JOB-ORDER             AS LOGICAL  
    FIELD cr-reason             AS CHAR     /* msc mr price*/
    FIELD call-no               AS CHAR     /* wam commonwealth */
    FIELD INSURE-SALESMAN       AS CHAR /* BERRIOS*/
    FIELD EXPORT-INV            AS LOGICAL  /* REF.  */
    /*** 03/10/2014 wam toledo start ***/
    FIELD total-boxes           AS DEC
    FIELD total-pallets         AS DEC
    /*** 03/10/2014 wam toledo  end  ***/
 
    FIELD LAYER-TYPE            AS CHAR /*BERRIOS 06/09/2014*/
    FIELD PHYSICAL-ZIP          AS CHAR /*05/17/2023*/
    
    /*** 09/04/2014 wam Toledo start ***/
    FIELD alfa-1                AS CHAR
    FIELD alfa-2                AS CHAR
    FIELD alfa-3                AS CHAR
    FIELD cod-no                AS CHAR     FORMAT "x(10)"
    FIELD cod-amt               AS DEC
    FIELD org-order-number      AS CHAR     FORMAT "x(10)"
    FIELD org-cust-number       AS CHAR     FORMAT "x(10)"
    FIELD org-account-no        AS CHAR     FORMAT "x(10)"
    FIELD po-number             AS CHAR
    FIELD ref-no                AS CHAR
    /*** 09/04/2014 wam Toledo  end  ***/
    
    /*** 11/12/2015 wam NUÑEZ start ***/
    FIELD route-stop            AS CHAR
    FIELD route-stop-seq        AS CHAR
    /*** 11/12/2015 wam NUÑEZ start ***/
    INDEX HEADER-KEY IS UNIQUE
    TMP-NUMBER .
  
 DEF TEMP-TABLE TMP-DETAIL-TAX
    /* UNIQUE KEY */
    FIELD TMP-NUMBER            AS CHAR      FORMAT "X(8)"
    FIELD TMP-SEQ               AS INTEGER   FORMAT ">>>9"
    FIELD ITEM-NUMBER           AS CHAR      FORMAT "X(20)"
    FIELD SALES-TX-CODE         AS CHARACTER FORMAT "XX"
    FIELD SALES-TX-AMT          AS DECIMAL 
    FIELD dt-prc-ext-city-tax   AS DEC
    FIELD dt-prc-ext-state-tax  AS DEC
    FIELD dt-city-tax-amt       AS DEC
    FIELD dt-state-tax-amt      AS DEC
    FIELD dt-city-tax-pct       AS DEC
    FIELD dt-state-tax-pct      AS DEC
    FIELD dt-char1              AS CHAR
    FIELD dt-char2              AS CHAR
    FIELD dt-char3              AS CHAR
  
    INDEX DETAIL-KEY IS UNIQUE
    TMP-NUMBER
    TMP-SEQ
    ITEM-NUMBER.
 
DEFINE VARIABLE COMPANY                   AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE DOC-NUMBER                AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE WAREHOUSE-NO              AS INTEGER                    NO-UNDO.
DEFINE VARIABLE tmp_city_tax_amt          AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE tmp_state_tax_amt         AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE CITY-TAXABLE-AMT          AS INTEGER                    NO-UNDO.
DEFINE VARIABLE CITY-OTHER-TAX            AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE CITY-regular-TAX          AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE STATE-TAXABLE-AMT         AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE STATE-OTHER-TAX           AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE STATE-regular-TAX         AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE IVU-SIEMPRE-SHPTO         AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE OETAXES-CLASS-CODE        AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE TENGO-CT-BB-tax-percent   AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE TENGO-ST-BB-tax-percent   AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE BB-cust-sales-tax-cd      AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE labor-line-up             AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE CT-BB-tax-percent         AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE ST-BB-tax-percent         AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE BB-dif-list               AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE selected-sales-tax-cd     AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE shpt-prev-ST-tax          AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE shpt-prev-CT-tax          AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE io-state-TAX-EXEMPT       AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE io-CITY-TAX-EXEMPT        AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE fecha-exempt-vencio       AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE IVU-HOLD-CODE             AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE tax-ret-val               AS CHARACTER                  NO-UNDO.
DEFINE VARIABLE cust-city-BB-tax-code     AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE cust-state-BB-tax-code    AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE estoy-city-tax            AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE estoy-state-tax           AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE TENGO-CT-LIMIT            AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE ct-over-limit             AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE ct-tax-percent            AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE CT-applied-pct            AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE extended-price            AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE TENGO-CT-SP-ITEM-TAX-PCT  AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE TENGO-ST-SP-ITEM-TAX-PCT  AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE tmp-prc-ext-city-tax      AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE tmp-prc-ext-state-tax     AS DECIMAL                    NO-UNDO.

DEFINE VARIABLE item-is-labor             AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE item-no-tax               AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE CT-SP-ITEM-TAX-PCT        AS INTEGER                    NO-UNDO.
DEFINE VARIABLE ST-SP-ITEM-TAX-PCT        AS INTEGER                    NO-UNDO.
DEFINE VARIABLE ST-applied-pct            AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE TENGO-ST-LIMIT            AS LOGICAL                    NO-UNDO.
DEFINE VARIABLE st-over-limit             AS DECIMAL                    NO-UNDO.
DEFINE VARIABLE st-tax-percent            AS DECIMAL                    NO-UNDO.
 
 DEFINE VARIABLE EXIST-SMHDLFLD           AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE CALL-PROG                AS CHARACTER                  NO-UNDO.   
 DEFINE VARIABLE route-via                AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE NO-CUCNF-MESSG           AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE PRECIO-AL-COMPONENTE     AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE cucnf-contract-no        AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE price-ext-eam            AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE SASI                     AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE AUTO-SALES               AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE deliv-multi-whs          AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE no-borre-quote           AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE LINE-UP-VALUE            AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE CR-REASON                AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE cr-field                 AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE set-casas                AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE mante-crea               AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE oeinvup-backorder        AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE no-backorders            AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE inv-no-print             AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE TP-SHIP                  AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE H-PICKER                 AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE BIN-DELETE               AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE SPECIAL-COST             AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE SPECIAL-COST-T           AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE SPECIAL-COST-V           AS DECIMAL                    NO-UNDO.
 DEFINE VARIABLE WHS-MOD                  AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE PO-DIST                  AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE RENT-INTER               AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE oedslde-bin-upd          AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE whsmod-ADJ-store-BIN-LOC AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE INVOICE-BIN-ZONE         AS INTEGER                    NO-UNDO.
 DEFINE VARIABLE INVOICE-BIN-LOC          AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE DIRECT-SALES-BIN         AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE DIRECT-SALES-BIN-LOC     AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE FREIGHT-BY-QTY           AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE COST-BY-WH               AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE which-cost-by-wh         AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE NEW-NUMBER               AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE popup-type               AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE MSG-FILE-NAME            AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE INVOICE-COST             AS INTEGER                    NO-UNDO.
 DEFINE VARIABLE INVOICE-TOTAL            AS INTEGER                    NO-UNDO.
 DEFINE VARIABLE temp-char                AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE inv-qty                  AS DECIMAL /*JKT INTEGER*/    NO-UNDO. /* JKT - INT to DEC */
 DEFINE VARIABLE TEMP-LOG                 AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE temp-int                 AS INTEGER                    NO-UNDO.
 DEFINE VARIABLE tmp-line-up              AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE PERCENT                  AS DECIMAL    FORMAT "->9.99" NO-UNDO.
 DEFINE VARIABLE INVOICE-NUM              AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE TRANS-TYPE               AS CHARACTER                  NO-UNDO.             
 DEFINE VARIABLE VOP-WARE                 AS INTEGER                    NO-UNDO.
 DEFINE VARIABLE VOP-ITEM                 AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE VOP-QTY                  AS DECIMAL /*JKT INTEGER*/    NO-UNDO. /* JKT - INT to DEC */
 DEFINE VARIABLE VOP-TIPO                 AS CHARACTER                  NO-UNDO.             
 DEFINE VARIABLE UPDATE-ORDER             AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE CURRENT-STATUS           AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE jblog-date               AS DATE                       NO-UNDO.
 DEFINE VARIABLE jblog-date-CHAR          AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE jblog-date-DT            AS DATETIME                   NO-UNDO.
 DEFINE VARIABLE TERMINAL-ID              AS CHARACTER                  NO-UNDO. /* shared var */
 DEFINE VARIABLE NUMERO-VIEJO             AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE DELIV-ORDER              AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE MB-FIN                   AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE via-wanted               AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE t-city-tax-amt           AS DECIMAL                    NO-UNDO.  /* JKT - INT TO DEC */
 DEFINE VARIABLE t-state-tax-amt          AS DECIMAL                    NO-UNDO. /*JKT - INT TO DEC  */
 DEFINE VARIABLE tax-on-order             AS LOGICAL                    NO-UNDO.
 DEFINE VARIABLE cLongitude               AS CHARACTER                  NO-UNDO.
 DEFINE VARIABLE cLatitude                AS CHARACTER                  NO-UNDO.
 
//DEFINE VARIABLE TABLILLA-CLASS AS CHARACTER NO-UNDO. 
//DEFINE VARIABLE actual-menu AS CHARACTER NO-UNDO.   /* shared var */

 DEF BUFFER BUF-MESSG       FOR MESSG.
 DEF BUFFER BUF-CINV1       FOR CINV1.
 DEF BUFFER buf-wkfile      FOR wkfile.
 DEF BUFFER JOB-STATUS      FOR WKFILE.
 DEF BUFFER HST-STATUS      FOR WKFILE.
 DEF BUFFER buf-tmp-detail  FOR tmp-detail.
  
 DEFINE TEMP-TABLE handles_file
        FIELD FILE_NAME     AS CHAR
        FIELD FILE_handle   AS HANDLE
 
        INDEX h_index AS PRIMARY UNIQUE
           FILE_name.
                     
DEFINE TEMP-TABLE SIZE-SELECTED
  FIELD INVOICE-NUMBER LIKE CIVSZ.INVOICE-NO
  FIELD INVOICE-SEQ    LIKE CIVSZ.INVOICE-SEQ
  FIELD ITEM-NUMBER    LIKE CIVSZ.ITEM-NUMBER
  FIELD STYLE-COLOR    LIKE CIVSZ.STYLE-COLOR
  FIELD SIZE           LIKE CIVSZ.SIZE
  FIELD SIZE-QTY      /* LIKE CIVSZ.SIZE-QTY */ AS DECIMAL FORMAT "->>>>>.999<"
  FIELD UNIT-QTY       LIKE CIVSZ.SIZE-QTY
  FIELD ONHAND         LIKE SIZE.QTY-ONHAND
  FIELD QTY-COMMITED   LIKE SIZE.QTY-COMMITED 
  FIELD QTY-ON-ORDER   LIKE SIZE.QTY-ON-ORDER
  FIELD DESCRIPTION    LIKE SIZE.DESCRIPTION
  FIELD ORDER-SEQ      LIKE CIVSZ.INVOICE-SEQ
  FIELD ORD-QTY        AS DECIMAL FORMAT "->>>>>.999<"
  FIELD pre-receiving  AS CHAR
  FIELD purchase-order AS CHAR
 
  INDEX SIZE-SEL IS UNIQUE PRIMARY
        INVOICE-NUMBER 
        INVOICE-SEQ 
        ITEM-NUMBER
        STYLE-COLOR
        SIZE.
        
/* DEFINE TEMP-TABLE SERIAL-SELECTED
       FIELD ITEM-NUMBER    LIKE CIVDT.ITEM-NUMBER
       FIELD SERIAL-NUMBER  LIKE SALEH.SERIAL-NUMBE
       FIELD invoice-number LIKE CIVDT.INVOICE-NO
       FIELD INVOICE-SEQ    LIKE CIVDT.INVOICE-SEQ
 
       INDEX SER-SEL IS UNIQUE PRIMARY
             INVOICE-NUMBER
             INVOICE-SEQ
             SERIAL-NUMBER
             ITEM-NUMBER. */ /* R.S */
             
/*DEFINE TEMP-TABLE lot-SELECTED
       FIELD ITEM-NUMBER    LIKE ivlot.ITEM-NUMBER
       FIELD lot-NUMBER     LIKE IVLOT.LOT-NUMBER
       FIELD invoice-number LIKE CIVDT.INVOICE-NO
       FIELD INVOICE-SEQ    LIKE CIVDT.INVOICE-SEQ
       FIELD QTY            LIKE CIVDT.QTY-SHIPPED
 
       INDEX LOT-SEL IS UNIQUE PRIMARY
            INVOICE-NUMBER
            INVOICE-SEQ
            ITEM-NUMBER
            LOT-NUMBER. */ /* R.S */
            
/*DEFINE TEMP-TABLE WEIGHT-SELECTED
       FIELD INVOICE-NUMBER LIKE CIVSZ.INVOICE-NO
       FIELD INVOICE-SEQ    LIKE CIVSZ.INVOICE-SEQ
       FIELD ITEM-NUMBER    LIKE CIVSZ.ITEM-NUMBER
       FIELD BOX-TYPE       AS CHAR
       FIELD BOX-ID         AS CHAR FORMAT "X(12)"
       FIELD BOX-WEIGHT     AS DECIMAL FORMAT ">>>.99-"
       FIELD BOX-SEQ        AS INTEGER
       FIELD LOT-NUMBER     AS CHAR
       FIELD WEIGHT-SUM     AS DECIMAL
       FIELD WEIGHT-CLR     AS LOGICAL  VIEW-AS TOGGLE-BOX
 
       /* 05/16/2007 para uso de oeuomcv.p ----------------------- */
       FIELD USER-FACT    AS DECIMAL FORMAT "->>,>>9.9999"
       FIELD MULT-FACT    AS DECIMAL FORMAT "->>,>>9.9999" EXTENT 5
       FIELD DIV-FACT     AS DECIMAL FORMAT "->>,>>9.9999" EXTENT 5
       FIELD MULT-DESC    AS CHAR FORMAT "X(15)" EXTENT 5
       FIELD DIV-DESC     AS CHAR FORMAT "X(15)" EXTENT 5
       /* 05/16/2007 para uso de oeuomcv.p ----------------------- */
 
 
 
       INDEX WEIGHT-KEY IS UNIQUE PRIMARY
             INVOICE-NUMBER 
             INVOICE-SEQ 
             ITEM-NUMBER
             BOX-TYPE
             BOX-ID.         */ /* R.S */                
             
//DEFINE TEMP-TABLE TT-WKFILE LIKE WKFILE. /* R.S */
 

/*DEFINE INPUT-OUTPUT PARAMETER INVOICE-NUM   AS CHARACTER    NO-UNDO.
DEFINE INPUT        PARAMETER TRANS-TYPE    AS CHARACTER    NO-UNDO. 
DEFINE INPUT-OUTPUT PARAMETER upd-bin-PICK  AS CHAR         NO-UNDO.    /* 01/20/2016 wam NUÑEZ */
DEFINE INPUT-OUTPUT PARAMETER io-char       AS CHAR         NO-UNDO.    /* 01/20/2016 wam NUÑEZ */
 
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR TMP-HEADER      APPEND.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR TMP-DETAIL      APPEND.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR SERIAL-SELECTED APPEND.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR LOT-SELECTED    APPEND.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR SIZE-SELECTED   APPEND.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR WEIGHT-SELECTED APPEND.
DEFINE INPUT-OUTPUT PARAMETER TABLE FOR TT-WKFILE       APPEND.*/ /* R.S */