 /*------------------------------------------------------------------------
    File        : PaymentProcessing
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : JKTECH
    Created     : Sat Feb 03 18:59:53 IST 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS PaymentProcessing: 
    
    DEF TEMP-TABLE TT-PAYMENTS
      FIELD p-type         AS CHARACTER
      FIELD p-pay          AS DECIMAL
      FIELD p-ref          AS CHARACTER FORMAT "x(41)"
      FIELD p-change       AS DECIMAL
      FIELD p-D-REF4       AS CHARACTER FORMAT "x(32)"
      FIELD p-D-REF5       AS CHARACTER FORMAT "x(32)"
      FIELD p-D-REF6       AS CHARACTER FORMAT "x(32)"
      FIELD p-D-REF7       AS CHARACTER FORMAT "x(32)"
      FIELD P-TMP-DESC     AS CHARACTER FORMAT "X(12)"
      FIELD p-cobros       AS CHARACTER FORMAT "x(41)".
        
    DEF TEMP-TABLE TT-DELIV
      FIELD DC-SEQ   LIKE COODT.ORDER-SEQ
      FIELD DC-ITEM  LIKE COODT.ITEM-NUMBER
      FIELD DC-DESC  LIKE COODT.DESCRIPTION
      FIELD DC-QTY   LIKE COODT.ORDER-QTY
      FIELD DC-PRICE LIKE COODT.ORDERED-PRC
      FIELD DC-WH    AS INTEGER FORMAT "99" LABEL "WH"
      FIELD DC-DT    AS CHAR    FORMAT "X"  LABEL "D/T/P".
    
    DEFINE BUFFER BUF-COOHD   FOR COOHD.          
    DEFINE BUFFER botones     FOR wkfile.
    DEFINE BUFFER b-COPTR     FOR COPTR. 
    DEFINE BUFFER TRAN-COPTR  FOR COPTR.
    DEFINE BUFFER TRAN-COPAR  FOR COPAR.  
    DEFINE BUFFER buf-ccsms   FOR ccsms.
    
    
    DEFINE VARIABLE PS-INV-NO          AS CHARACTER INITIAL "":U                             NO-UNDO.    
    DEFINE VARIABLE opiStatusCode      AS INTEGER                                            NO-UNDO.
    DEFINE VARIABLE cError             AS CHARACTER                                          NO-UNDO.     
    DEFINE VARIABLE cCompany           AS CHARACTER FORMAT  "X"                              NO-UNDO.
    DEFINE VARIABLE MB-ACCOUNT         AS CHARACTER FORMAT "X(20)"                           NO-UNDO.
    DEFINE VARIABLE MB-NAME            AS CHARACTER FORMAT "X(30)"                           NO-UNDO.        
    DEFINE VARIABLE COD-AMOUNT         AS DECIMAL                                            NO-UNDO. 
    DEFINE VARIABLE ES-LAYAWAY3        AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE PAGO-DE-ORDEN      AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE TIENDA             AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE ROW-NUMERO         AS ROWID                                              NO-UNDO.
    DEFINE VARIABLE LOAN-PMT           AS DECIMAL                                            NO-UNDO. 
    DEFINE VARIABLE LOAN-ORDER-PMT     AS DECIMAL INITIAL 0                                  NO-UNDO. 
    DEFINE VARIABLE TOT-PAY-PRO        AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE TOT-PAY-COD        AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE TOT-PAY-OTH        AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE TOT-PAY-LOAN       AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE POINT-STORE        AS INTEGER                                            NO-UNDO. 
    DEFINE VARIABLE TMP-DESC           AS CHARACTER FORMAT "X(12)"                           NO-UNDO. 
    DEFINE VARIABLE D-ref4             AS CHARACTER FORMAT "x(20)"                           NO-UNDO.
    DEFINE VARIABLE D-ref5             AS CHARACTER FORMAT "x(20)"                           NO-UNDO.
    DEFINE VARIABLE D-ref6             AS CHARACTER FORMAT "x(20)"                           NO-UNDO.
    DEFINE VARIABLE D-ref7             AS CHARACTER FORMAT "x(20)"                           NO-UNDO.
    DEFINE VARIABLE D-ref4-txt         AS CHARACTER FORMAT "x(20)"                           NO-UNDO.
    DEFINE VARIABLE D-ref5-txt         AS CHARACTER FORMAT "x(20)"                           NO-UNDO.
    DEFINE VARIABLE D-ref6-txt         AS CHARACTER FORMAT "x(20)"                           NO-UNDO.
    DEFINE VARIABLE D-ref7-txt         AS CHARACTER FORMAT "x(20)"                           NO-UNDO.
    DEFINE VARIABLE D-REF4-cd          AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE D-REF5-cd          AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE D-REF6-cd          AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE D-REF7-cd          AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE SALIDA             AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE botones-data       AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE btn-handle         AS HANDLE EXTENT 9                                    NO-UNDO. 
    DEFINE VARIABLE new-inv-balance    AS DECIMAL                                            NO-UNDO.   
    DEFINE VARIABLE pago-multiple      AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE fact-MULTIPLE      AS CHARACTER EXTENT 10                                NO-UNDO.
    DEFINE VARIABLE fecha-entrega      AS DATE                                               NO-UNDO.
    DEFINE VARIABLE temp-log           AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE temp-int           AS INTEGER                                            NO-UNDO. 
    DEFINE VARIABLE TRANS-DATE         AS DATE                                               NO-UNDO.  /* jkt */
    DEFINE VARIABLE w-APPLY-DEPO       AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE FORCE-DEPOS        AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE PSCSHDE-NO-SP      AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE PSCONDPA           AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE auto-banco         AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE MB-FIN             AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE QTY                AS DECIMAL   FORMAT "->>>>>9.99"                      NO-UNDO.
    DEFINE VARIABLE NEW-BAL            AS DECIMAL   FORMAT "->>>>>9.99"                      NO-UNDO.
    DEFINE VARIABLE TEMP-CHAR          AS CHARACTER FORMAT "X(20)"                           NO-UNDO.
    DEFINE VARIABLE TEMP-CHAR1         AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE FACTURANDO         AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE FACTURA-O-ORDEN    AS CHARACTER INITIAL "BALANCE:"                       NO-UNDO.
    DEFINE VARIABLE NUMERO-FAC-ORD     AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE PREV-PAGO-ONACC    AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE PREV-PAGO-CREDIT   AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE CANCEL-LAYAWAY     AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE pago-ar            AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE pago-la            AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE sin-credito        AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE choice             AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE TEMP-HANDLE        AS HANDLE                                             NO-UNDO.
    DEFINE VARIABLE SALDO-LAYAWAY      AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE LAYAWAY            AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE LAYAWAY-ORIG       AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE LAYAWAY-WH         AS INTEGER                                            NO-UNDO.
    DEFINE VARIABLE TOTAL-PAGADO       AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE PAGO               AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE TOTAL-FACTURA      AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE PS-CHANGE          AS DECIMAL INITIAL 0                                  NO-UNDO.
    DEFINE VARIABLE FLAG               AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE BALANCE            AS DECIMAL FORMAT "->,>>>,>>>.99"                     NO-UNDO.
    DEFINE VARIABLE CHK-NO             AS CHARACTER FORMAT "X(16)" LABEL "REFERENCE"         NO-UNDO.
    DEFINE VARIABLE INV-AMT            AS DECIMAL FORMAT "->,>>>,>>>.99"                     NO-UNDO.
    DEFINE VARIABLE CHECK-BALANCE      AS DECIMAL FORMAT "->>>>>.99"                         NO-UNDO.
    DEFINE VARIABLE ON-ACCT            AS DECIMAL FORMAT ">>>>>>.99"                         NO-UNDO.
    DEFINE VARIABLE PAY-DATE           AS DATE LABEL "PAYMENT DATE"                          NO-UNDO.
    DEFINE VARIABLE RECEIPT-COPY       AS LOGICAL  VIEW-AS TOGGLE-BOX                        NO-UNDO.
    DEFINE VARIABLE PAR                AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE R-NUMBER           AS CHARACTER FORMAT "X(6)"                            NO-UNDO.
    DEFINE VARIABLE CHECK-AMOUNT       AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE MANUAL-RECEIPT     AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE RECEIPT-NO         AS INTEGER FORMAT ">>>>>>>>"                          NO-UNDO.
    DEFINE VARIABLE RECIBO-STAT        AS CHARACTER FORMAT "X(20)"                           NO-UNDO.
    DEFINE VARIABLE deliv-order        AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE ENABLE-RECEIPT     AS LOGICAL                                            NO-UNDO.        
    DEFINE VARIABLE P-1                AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE PSCSHDE-NOCKCHANGE AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE PSCSHDE-fast-reg   AS LOGICAL                                            NO-UNDO. 
    DEFINE VARIABLE TMP-INVOICE-NO     AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE NUEVO-DIA          AS LOGICAL                                            NO-UNDO.  
    DEFINE VARIABLE S-TAX              AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE C-TAX              AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE INV-GROSS          AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE via-wanted         AS LOGICAL                                            NO-UNDO.
    DEFINE VARIABLE abono-layaway      AS DECIMAL                                            NO-UNDO.                
    DEFINE VARIABLE SS-LABEL           AS CHARACTER FORMAT "X(19)" INITIAL "ABONO LAYAWAY:"  NO-UNDO.
    DEFINE VARIABLE SP-ON-ACC          AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE SP-ON-ACC-NUMBER   AS CHARACTER FORMAT "X(6)"                            NO-UNDO.
    DEFINE VARIABLE SP-CREDIT          AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE ddd1               AS CHARACTER FORMAT "xxxx"                            NO-UNDO.
    DEFINE VARIABLE ddd2               AS CHARACTER FORMAT "x(12)"                           NO-UNDO.
    DEFINE VARIABLE ddd3               AS CHARACTER FORMAT "x(8)"                            NO-UNDO. 
    DEFINE VARIABLE ddd4               AS CHARACTER FORMAT "x(12)"                           NO-UNDO.
    DEFINE VARIABLE ddd5               AS CHARACTER FORMAT "x(16)"                           NO-UNDO.
    DEFINE VARIABLE ddd6               AS CHARACTER FORMAT "x(12)"                           NO-UNDO.
    DEFINE VARIABLE DDD8               AS CHARACTER FORMAT "X(8)"                            NO-UNDO.
    DEFINE VARIABLE pago-work          AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE BALANCE-MULTIPLE   AS DECIMAL                                            NO-UNDO.
    DEFINE VARIABLE TERMINAL-ID        AS CHARACTER                                          NO-UNDO.
    DEFINE VARIABLE P-NEGATIVO         AS CHARACTER                                          NO-UNDO.
        
    DEFINE VARIABLE LOAN-ORDER-PMT-TYPE AS CHARACTER                                         NO-UNDO.
    DEFINE VARIABLE maximo-dias-layaway AS INTEGER                                           NO-UNDO.
    
    
    DEFINE VARIABLE CUSTOMER-NUMBER       LIKE CCSMS.CUST-NUMBER                     NO-UNDO.
    DEFINE VARIABLE CUSTOMER-NAME         LIKE CCSMS.CUST-NAME                       NO-UNDO.
    DEFINE VARIABLE CUSTOMER-OPEN-INVOICE LIKE CCSMS.OPEN-INVOICE                    NO-UNDO. 
    DEFINE VARIABLE CUSTOMER-ON-ACCOUNT   LIKE CCSMS.ON-ACCOUNT                      NO-UNDO.   
    DEFINE VARIABLE CUSTOMER-CREDIT-AMT   LIKE CCSMS.CREDIT-AMT                      NO-UNDO.   
    DEFINE VARIABLE CUSTOMER-DEBIT-AMT    LIKE CCSMS.DEBIT-AMT                       NO-UNDO.
    DEFINE VARIABLE PAY-TYPE              LIKE TERMS.CUS-TERMS-CD                    NO-UNDO.
    DEFINE VARIABLE PAID-AMT              LIKE CCSMS.OPEN-INVOICE                    NO-UNDO.
    DEFINE VARIABLE YTD-PAYMENTS          LIKE CCSMS.YTD-PAYMENTS                    NO-UNDO.
    DEFINE VARIABLE ON-ACCOUNT            LIKE CCSMS.ON-ACCOUNT                      NO-UNDO.
    DEFINE VARIABLE CUS-CHG-NO            LIKE COPAR.CUS-CHG-NO  LABEL "INVOICE-NO"  NO-UNDO.
    DEFINE VARIABLE INVOICE-2             LIKE COPAR.CUS-CHG-NO                      NO-UNDO. 
    DEFINE VARIABLE Invoice-discount      AS   DECIMAL                               NO-UNDO.
        
    /* DEFINE PRIVATE TEMP-TABLE ttPayment NO-UNDO  SERIALIZE-NAME "payment":U  
      FIELD invoice_num         AS CHARACTER 
      FIELD customerNum         AS CHARACTER 
      FIELD order-number        AS CHARACTER
      FIELD payment_type        AS CHARACTER
      FIELD payment_amt         AS DECIMAL
      FIELD cheque_num          AS CHARACTER
      FIELD discount_amt        AS DECIMAL. */
    
     DEFINE PRIVATE TEMP-TABLE ttPayment NO-UNDO 
        FIELD invoice_num   AS CHARACTER
        FIELD order_number  AS CHARACTER    
        FIELD payment_type  AS CHARACTER
        FIELD payment_amt   AS DECIMAL
        FIELD cheque_num    AS CHARACTER
        FIELD discount_amt  AS DECIMAL.
        
      
      DEFINE VARIABLE totalPayment  AS DECIMAL NO-UNDO.
      DEFINE VARIABLE invoiceamt    AS DECIMAL NO-UNDO. 
      DEFINE VARIABLE lastinvoice# AS CHARACTER NO-UNDO.  
    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
        
    CONSTRUCTOR PUBLIC PaymentProcessing (  ):
      
                         
        
    END CONSTRUCTOR.
    
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC PaymentProcessing (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
  END CONSTRUCTOR.
  
  /* Method to process the multiple payments */
  METHOD PUBLIC VOID Pay-invoice-mobile-web(INPUT cCustNumber AS CHARACTER,
                                            INPUT ipcLangID    AS CHARACTER,
                                            INPUT TABLE ttpayment,
                                            OUTPUT opcError AS CHARACTER,
                                            OUTPUT opiStatusCode AS INTEGER):
                                                
      DEFINE VARIABLE lastOrder#   AS CHARACTER NO-UNDO.
      FIND FIRST ttPayment WHERE ttPayment.payment_type NE "invoice":U NO-LOCK NO-ERROR. 
      IF AVAILABLE ttPayment THEN totalPayment = ttPayment.payment_amt.
      
/*      FOR EACH ttpayment:                                                                                                                      */
/*        MESSAGE " Hello ttPayment.invoice_num=" ttpayment.invoice_num " ttpayment.cheque_num "  ttpayment.cheque_num " ttpayment.order_number "*/
/*        ttpayment.order_number " ttpayment.payment_amt " ttpayment.payment_amt                                                                 */
/*        VIEW-AS ALERT-BOX.                                                                                                                     */
/*      END.                                                                                                                                     */
                                                  
      FOR EACH ttPayment:
        
        IF ttPayment.payment_type EQ "invoice":U THEN
          NEXT.
         

        FIND COPAR WHERE COPAR.CUST-NUMBER = cCustNumber
                     AND COPAR.CUS-CHG-NO  = ttPayment.invoice_num NO-LOCK NO-ERROR.
        IF AVAILABLE COPAR THEN invoiceamt = COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT - COPAR.PAY-DISC-AMT -  
                                             COPAR.OTH-ALLOWANC - COPAR.INV-CR-TOT  + COPAR.INV-DR-TOT.
        ELSE  invoiceamt = 0.
        IF invoiceamt GT totalPayment THEN invoiceamt = totalPayment.
        
        ASSIGN ttPayment.payment_amt = invoiceamt
               totalPayment = totalPayment - ttPayment.payment_amt.
                                          
        /* initiate payment processing */
        this-object:mainBlock(INPUT ttPayment.invoice_num,  
                                    INPUT cCustNumber,
                                    INPUT ttPayment.order_number, 
                                    INPUT ttPayment.payment_type,
                                    INPUT ttPayment.payment_amt,
                                    INPUT ttPayment.cheque_num,
                                    INPUT ipcLangID,
                                    INPUT ttPayment.discount_amt,          
                                    OUTPUT opcError,
                                    OUTPUT opiStatusCode). 
          ASSIGN lastinvoice# = ttPayment.invoice_num 
                 lastOrder#   = ttPayment.order_number.                                   
                               
     END.  
     IF totalPayment GT 0 THEN 
     DO:
         
         FIND FIRST ttPayment WHERE ttPayment.payment_type NE "invoice":U NO-LOCK NO-ERROR.
         IF AVAILABLE ttPayment THEN 
         DO:
         
           pago-work = totalPayment.
           IF ttPayment.payment_type = "CASH" THEN ASSIGN TMP-DESC = "CASH"
                                                          PAY-TYPE   = "1".
           ELSE IF ttPayment.payment_type = "Online" THEN ASSIGN TMP-DESC = "ONLINE"
                                                                 PAY-TYPE = "11".
           ELSE  ASSIGN TMP-DESC = "CHECK"
                        pAY-TYPE = "2".
           
           IF TMP-DESC = "CHECK" THEN 
             ASSIGN D-REF4-txt = ttPayment.cheque_num
                    D-REF4-cd  = "chk":U.
                    
           CREATE TT-PAYMENTS. 
            ASSIGN 
              TT-PAYMENTS.p-type     = PAY-TYPE 
              TT-PAYMENTS.p-pay      = 0
              TT-PAYMENTS.p-ref      = ttPayment.order_number
              TT-PAYMENTS.p-change   = 0
              TT-PAYMENTS.p-D-REF4   = D-REF4-cd + D-REF4-txt
              TT-PAYMENTS.p-D-REF5   = D-REF5-cd + D-REF5-txt
              TT-PAYMENTS.p-D-REF6   = D-REF6-cd + D-REF6-txt
              TT-PAYMENTS.p-D-REF7   = D-REF7-cd + D-REF7-txt
              TT-PAYMENTS.P-TMP-DESC = TMP-DESC.
              
           THIS-OBJECT:PROC-UPDATE(INPUT "ON/ACC",
                                   INPUT cCustNumber,
                                   INPUT ttPayment.order_number,
                                   INPUT ipcLangID,
                                   OUTPUT cError).   
        END.      
           
       END.                     
                                      
  END.    
  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID CLOSE-SERVICE-JOB():
    
    /* Verificar que la factura no tenga balance */

    ASSIGN
      new-inv-balance = COPAR.CUS-INV-NET  
                      - COPAR.CUS-PAYMENT 
                      - COPAR.PAY-DISC-AMT 
                      - COPAR.OTH-ALLOWANC 
                      + COPAR.INV-DR-TOT  
                      - COPAR.INV-CR-TOT.
                      
    IF new-inv-balance <= 0 THEN
    DO:
        
        /* FIND ORDER */
        
        FIND FIRST BUF-COOHD WHERE BUF-COOHD.ORDER-NUMBER EQ SUBSTRING(COPAR.DESCRIPTION1,1,6)
                               AND BUF-COOHD.CUST-NUMBER  EQ COPAR.CUST-NUMBER NO-LOCK NO-ERROR.
        IF  AVAIL BUF-COOHD THEN
        DO:
            
            /* VERIFY IF THIS ORDER IS A SERVICE CALL JOB */
            
            IF  BUF-COOHD.picking-ind  BEGINS "CALL-NO-" THEN
            DO:
                /* UPDATE CALL STATUS TO CLOSE */
                
                FIND FIRST calls WHERE calls.call-no      = INTEGER(SUBSTRING(BUF-COOHD.picking-ind,9)) 
                                                            EXCLUSIVE-LOCK NO-ERROR.
                IF  AVAILABLE calls  THEN
                DO:
                    /* MARK SERVICE JOB AS CLOSED */
                    
                    ASSIGN
                      calls.dt-finished   = TODAY
                      CALLS.HR-FINISHED   = STRING(TIME,"hh:mm:ss") 
                      calls.call-status   = "OK"   .
                    
                    /* CREATE JOB LOG ENTRY  */
                    
                    CREATE CALLG.
                    ASSIGN 
                      CALLG.CALL-no       = calls.call-no
                      CALLG.CALL-DATE     = calls.call-dt
                      callg.entry-date    = TODAY
                      CALLG.entry-TIME    = TIME
                      CALLG.LOG-ENTRY     = "CLOSED ":U 
                                          + USER("CDI":U) 
                                          + " " 
                                          + terminal-id 
                                          + "(pscshde)":U
                      callg.user-code     = USER("CDI":U)
                      callg.terminal-id   = terminal-id.
                END. /* IF AVAILABLE calls */
            END. /* BUF-COOHD.picking-ind BEGINS "CALL-NO-" */
        END. /* IF AVAIL COOHD */
    END.  /* IF new-inv-balance <= 0 */
    
  END METHOD.

  /*----------------------------------------------------------------------------------
   Purpose: This method is used to get the recommended items. (Pg. 6)
   Input Parameters: 1. ipcPaymentMethod - Type of payment method selected by User
                     2 .ipcCustNumber    - Customer Number,                     
                     3. ipcOrderNum      - Order number generated during submit order                     
                     
   Output Parameters:1. opcAppToken       - it contains new token if old token expired 
                                            otherwise return old token.
                     2. opcError          - returns error if any.
                     3. oplcTopSellerData - stores data related to top selling items.
                     4. opiStatusCode     - HTTP status code.
   Notes:
  -------------------------------------------------------------------------------------*/

    METHOD PUBLIC VOID mainBlock(INPUT PS-INV-NO        AS CHARACTER,
                                 INPUT PS-CUST-NUMBER   AS CHARACTER,
                                 INPUT ORDER-NUMBER     AS CHARACTER,
                                 INPUT ipcPaymentMethod AS CHARACTER,
                                 INPUT ipdePaymentAmt   AS DECIMAL,
                                 INPUT ipcChequeNumber  AS CHARACTER,
                                 INPUT ipcLangID        AS CHARACTER,
                                 INPUT ipdeDiscountAmt  AS DECIMAL,
                                 OUTPUT opcError        AS CHARACTER,
                                 OUTPUT opiStatusCode   AS INTEGER):
       

        DEFINE VARIABLE objCommonSrc AS CLASS CommonSource NO-UNDO.
        objCommonSrc = NEW commonSource(INPUT cToken).
        
        /* Find the user type. If the login is from web use the termila-id as Online othereise terminal id as salesrep*/
        FIND FIRST token WHERE Token.Token EQ cToken NO-LOCK NO-ERROR.
        IF AVAILABLE token THEN 
        DO:
            IF Token.User-Type begins "WEB" THEN 
            ASSIGN TERMINAL-ID  = "ONLINE".
            else 
            ASSIGN TERMINAL-ID = Token.User-ID no-error.
        END.     
        
          
        
        /* Return Error when invalid payment type is enetered */
        IF ( TRIM(ipcPaymentMethod) NE "CASH":U     AND 
             TRIM(ipcPaymentMethod) NE "CHEQUE":U   AND 
             TRIM(ipcPaymentMethod) NE "INVOICE":U  AND 
             TRIM(ipcPaymentMethod) NE "ONLINE":U ) OR 
             TRIM(ipcPaymentMethod) EQ "":U         THEN
        DO:
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200InvalidPaymentMethod,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
            
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
           
        END. /* IF (TRIM(ipcPaymentMethod) NE "CASH":U ))... */
        
        /* Return error when Cheque payment type is selected but chque number is blank */
        IF TRIM(ipcPaymentMethod) EQ "CHEQUE":U AND TRIM(ipcChequeNumber) EQ "":U THEN 
        DO:
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200ChequeNumCannotBlank,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).          
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
        END. /* IF TRIM(ipcPaymentMethod) EQ "CHEQUE":U.. */
        
        
        IF TRIM(ipcLangID) EQ "":U OR TRIM(ipcLangID) EQ ? THEN
        DO:
           /* Get multilingual message for blank language id */
           objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200LangBlank,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
                  
           IF cError NE "":U THEN 
             UNDO,THROW NEW AppError(cError,1).
        END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
         
        IF TRIM(ORDER-NUMBER) EQ "":U OR TRIM(ORDER-NUMBER) EQ ? THEN
        DO:
           /* Return error for blank order number */
           objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200OrderBlank,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
                  
           IF cError NE "":U THEN 
             UNDO,THROW NEW AppError(cError,1).
        END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
         
        /* Commented for collect payment API, because it throws message when order does not exists
           and doesn't let user pay for invoice. */
        /*
        ELSE
        DO: 
           IF NOT CAN-FIND(FIRST COOHD WHERE COOHD.ORDER-NUMBER EQ TRIM(ORDER-NUMBER) NO-LOCK) THEN
           DO:
             /* Return error when invalid order number is entered */
             objCommonSrc:getMessages(INPUT  ipcLangID,
                                      INPUT  ConstantInitializer:c200InvalidOrder,                                                              
                                      OUTPUT cError,
                                      OUTPUT opiStatusCode).
                                            
             IF cError NE "":U THEN 
               UNDO,THROW NEW AppError(cError,1).
           END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
        END. /* ELSE */ 
        */
        
        IF TRIM(PS-CUST-NUMBER) EQ "":U OR TRIM(PS-CUST-NUMBER) EQ ? THEN
        DO:
           /* Return error when blank customer number is entered */
           objCommonSrc:getMessages(INPUT  ipcLangID,
                                    INPUT  ConstantInitializer:c200CustBlank,                                                              
                                    OUTPUT cError,
                                    OUTPUT opiStatusCode).
                  
           IF cError NE "":U THEN 
             UNDO,THROW NEW AppError(cError,1).
        END. /* IF TRIM(ipcLangID) EQ "":U OR.. */
         
        ELSE
        DO: 
           IF NOT CAN-FIND(FIRST ccsms WHERE CCSMS.CUST-NUMBER EQ TRIM(PS-CUST-NUMBER) NO-LOCK) THEN
           DO:
             /* Return error when invalid customer is entered */
             objCommonSrc:getMessages(INPUT  ipcLangID,
                                      INPUT  ConstantInitializer:c200InvalidCustomer,                                                              
                                      OUTPUT cError,
                                      OUTPUT opiStatusCode).
                                            
             IF cError NE "":U THEN 
               UNDO,THROW NEW AppError(cError,1).
           END. /* IF NOT CAN-FIND(CDILANGUAGE WHERE.. */        
        END.   /* ELSE */ 
        
        
        ASSIGN 
          TRANS-DATE       = TODAY /* Set the transaction date, logged in company and payment amount */
          cCompany         = SUBSTRING(PS-CUST-NUMBER,1,1)
          Invoice-discount = ipdeDiscountAmt
          PAGO             = ipdePaymentAmt.  /* JKT */
        
        
        
        FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE EQ cCompany      NO-LOCK NO-ERROR. 
        
        FIND FIRST POINT WHERE POINT.TERMINAL-DEV EQ USERID("cdi") NO-LOCK NO-ERROR.
        
        IF AVAILABLE POINT THEN 
          ASSIGN POINT-STORE = INTEGER(POINT.PRINTER-NUM).
        ELSE 
          ASSIGN POINT-STORE = IF AVAILABLE CMPNY THEN CMPNY.WHS-LOCATION ELSE 0.
        
        FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID     EQ "via-wanted":U
                             AND PARAMFL.COMPANY-CODE EQ cCompany
                             AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
        IF AVAILABLE PARAMFL THEN                            
          ASSIGN via-wanted = TRUE.
        
        /* This param activates that the windows-serial box opens when entering this program (so that the box is faster) */
        FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID     EQ "PSCSHDE-fast-reg":U
                             AND PARAMFL.COMPANY      EQ cCompany
                             AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
        
        IF AVAILABLE PARAMFL THEN
        DO:
          ASSIGN PSCSHDE-fast-reg = YES.
          THIS-OBJECT:proc-abre-caja().
        END.
        
        FIND FIRST PARAMFL WHERE PARAMFL.PARAM-ID     EQ "MB-FIN":U
                             AND PARAMFL.COMPANY-CODE EQ cCompany
                             AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                             
        IF AVAILABLE PARAMFL THEN 
          ASSIGN MB-FIN =  TRUE.
                
        /* It forces to apply in an Invoice Order all the DEPO that has the invoice */
        FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "PSCSH-FORCE-DEPOS":U
                       AND PARAMFL.COMPANY      EQ cCompany
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
        IF AVAILABLE PARAMFL THEN 
          ASSIGN FORCE-DEPOS = TRUE.        
        
        FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "PSCSHDE-NOCKCHANGE":U
                       AND PARAMFL.COMPANY      EQ cCompany
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
        IF AVAILABLE PARAMFL THEN            
          ASSIGN PSCSHDE-NOCKCHANGE = TRUE.  
        
        FIND PASWD   WHERE PASWD.COMPANY-CODE EQ cCompany  
                       AND PASWD.FILE-NAME    EQ "PSCSHDE" 
                       AND PASWD.FIELD-NAME   EQ "NEG" NO-LOCK NO-ERROR.
        
        IF AVAILABLE PASWD THEN 
          ASSIGN P-NEGATIVO    = PASWD.P-PASSWORD.
        
        
        FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "PSCSHDE-NO-SP":U
                       AND PARAMFL.COMPANY      EQ cCompany
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
        
        IF AVAILABLE PARAMFL THEN     
          ASSIGN PSCSHDE-NO-SP = TRUE.
         
        FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "DELIV-ORDER":U
                       AND PARAMFL.COMPANY      EQ cCompany
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
                   
        IF AVAILABLE PARAMFL  THEN   
        DO:
           ASSIGN 
             DELIV-ORDER         = AVAILABLE PARAMFL
             maximo-dias-layaway = INTEGER(paramfl.PARAM-value1).
        END.
        
        FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "MAN-REC":U
                       AND PARAMFL.COMPANY-CODE EQ cCompany
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
       
        IF AVAILABLE PARAMFL THEN 
          ASSIGN MANUAL-RECEIPT = TRUE.
        ELSE 
          ASSIGN MANUAL-RECEIPT = FALSE.
          
        FIND PARAMFL WHERE PARAMFL.PARAM-ID     EQ "NUEVO-DIA":U
                       AND PARAMFL.COMPANY-CODE EQ cCompany
                       AND PARAMFL.PARAM-STATUS NO-LOCK NO-ERROR.
        
        IF AVAILABLE PARAMFL THEN
          ASSIGN NUEVO-DIA = TRUE.       
       
        ASSIGN PAY-DATE = TODAY.
        
        /* BROWSER MUEBLERY SYSTEM FOR CHANGE OF WAREHOUSE AND DELIVERY */
        FIND PARAMFL WHERE PARAMFL.COMPANY-CODE EQ cCompany
                       AND PARAMFL.PARAM-ID     EQ "RECEIPT":U 
                       AND PARAM-STATUS         NO-LOCK NO-ERROR.
        IF AVAILABLE PARAMFL THEN
        DO:
          
          IF PARAMFL.PARAM-VALUE2 <> "NEVER":U THEN 
            ASSIGN 
              ENABLE-RECEIPT = TRUE
              RECEIPT-COPY   = TRUE.
          
          IF PARAMFL.PARAM-VALUE3 = "AR-ONLY":U THEN
            ASSIGN  RECEIPT-COPY  = FALSE.
           
        END. /* IF AVAILABLE PARAMFL THEN */
        
        FIND CCSMS WHERE CCSMS.CUST-NUMBER = PS-CUST-NUMBER NO-LOCK NO-ERROR.
        IF AVAILABLE CCSMS THEN
          ASSIGN 
            BALANCE               = CCSMS.OPEN-INVOICE - 
                                    CCSMS.ON-ACCOUNT   - 
                                    CCSMS.CREDIT-AMT   + 
                                    CCSMS.DEBIT-AMT
            CUSTOMER-NUMBER       = CCSMS.CUST-NUMBER
            CUSTOMER-NAME         = CCSMS.CUST-NAME
            CUSTOMER-OPEN-INVOICE = CCSMS.OPEN-INVOICE 
            CUSTOMER-ON-ACCOUNT   = CCSMS.ON-ACCOUNT   
            CUSTOMER-CREDIT-AMT   = CCSMS.CREDIT-AMT   
            CUSTOMER-DEBIT-AMT    = CCSMS.DEBIT-AMT.   
                    
        IF ORDER-NUMBER <> "" THEN 
        DO: 
           FIND FIRST coohd WHERE coohd.cust-number  EQ CCSMS.CUST-NUMBER 
                              AND coohd.order-number EQ ORDER-NUMBER NO-LOCK NO-ERROR.
           IF AVAILABLE coohd THEN 
           DO: 
             ASSIGN         
               TOTAL-FACTURA    = COOHD.ORDER-AMOUNT /* Total amount that has to be paid */
               FACTURA-O-ORDEN  = "ORDER BALANCE:":U
               NUMERO-FAC-ORD   = ORDER-NUMBER
               PAGO-DE-ORDEN    = TRUE.
             
             IF LOAN-ORDER-PMT <> 0 THEN 
               ASSIGN TOTAL-FACTURA    = LOAN-ORDER-PMT.
             
             IF (COOHD.LAYER-TYPE = "3":U OR COOHD.LAYER-TYPE = "2":U)  THEN
               ASSIGN COD-AMOUNT  = DECIMAL(SUBSTRING(COOHD.TP-APPL,6)) NO-ERROR.
             
             IF COD-AMOUNT = ? THEN 
               ASSIGN COD-AMOUNT = 0.
             
             IF COOHD.LAYER-TYPE  = "3":U THEN
               ASSIGN ES-LAYAWAY3 = TRUE. 
             ELSE 
               ASSIGN ES-LAYAWAY3 = FALSE.  
   
             
             FOR EACH COODT OF COOHD NO-LOCK:
               IF COODT.ITEM-NUMBER MATCHES "*STATE-TAX*":U THEN
                 ASSIGN S-TAX = s-tax + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY).
               
               ELSE
                 IF COODT.ITEM-NUMBER MATCHES "*CITY-TAX*":U THEN
                 
                   ASSIGN C-TAX = c-tax + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY).
                 
                 ELSE INV-GROSS = INV-GROSS + (COODT.ORDERED-PRC * COODT.ORIGINAL-QTY).
   
             END. /*  FOR EACH COODT OF COOHD */
             
             ASSIGN INV-GROSS = INV-GROSS - C-TAX - S-TAX.

           END. /* IF AVAILABLE coohd THEN  */
           
           /* IF AVAILABLE coohd THEN  */
           ELSE  
           DO:
               ASSIGN total-factura    = 0.
           END.
               
        END. /* IF ORDER-NUMBER <> "" THEN  */
               
        /*------facturas regulares----------*/
        IF pago-multiple THEN
        DO: 
          /*------facturas multiples (pscondpa)----------*/
          ASSIGN 
            FACTURA-O-ORDEN  = "MULTIPLE INVOICES:":U 
            NUMERO-FAC-ORD   = "":U 
            TOTAL-FACTURA    = 0 
            C-TAX            = 0
            S-TAX            = 0
            INV-GROSS        = 0 .
            
          REPEAT temp-int  = 1 TO 10:
            FIND COPAR WHERE COPAR.CUST-NUMBER  EQ CCSMS.CUST-NUMBER 
                         AND COPAR.CUS-CHG-NO   EQ fact-multiple[temp-int] 
            NO-LOCK NO-ERROR.
            IF AVAILABLE COPAR THEN 
              ASSIGN 
                TOTAL-FACTURA  = TOTAL-FACTURA 
                               + CUS-INV-NET  
                               - CUS-PAYMENT 
                               - PAY-DISC-AMT 
                               - OTH-ALLOWANC 
                               + INV-DR-TOT  
                               - INV-CR-TOT
                NUMERO-FAC-ORD = NUMERO-FAC-ORD + fact-multiple[temp-int] + " ":U .
 
            FOR EACH CSAHF WHERE CSAHF.INVOICE-NO   EQ      COPAR.CUS-CHG-NO 
                             AND CSAHF.INVOICE-DATE EQ      COPAR.CUS-INV-DATE 
                             AND CSAHF.ITEM-NUMBER  MATCHES "*TAX*":U  NO-LOCK:
             
              IF CSAHF.ITEM-NUMBER MATCHES "*STATE-TAX*":U THEN
                ASSIGN S-TAX = s-tax + CSAHF.PRICE-EXT.
              IF CSAHF.ITEM-NUMBER MATCHES "*CITY-TAX*":U THEN
                ASSIGN C-TAX = c-tax + CSAHF.PRICE-EXT.
            END.
 
          END. /* REPEAT temp-int  = 1 TO 10 */
          
          INV-GROSS = TOTAL-FACTURA - C-TAX - S-TAX.
 
        END. /*------facturas multiples (pscondpa)----------*/
        ELSE
        DO: /*------facturas una a una (oedslde,ect)----------*/

          FIND COPAR WHERE COPAR.CUST-NUMBER EQ CCSMS.CUST-NUMBER
                       AND COPAR.CUS-CHG-NO  EQ PS-INV-NO 
          NO-LOCK NO-ERROR.
          
          
          IF AVAILABLE COPAR THEN 
          DO: 
            ASSIGN 
              FACTURA-O-ORDEN = "INVOICE BALANCE:":U 
              NUMERO-FAC-ORD  = PS-INV-NO.
 
            ASSIGN  
              TOTAL-FACTURA   = CUS-INV-NET  
                              - CUS-PAYMENT 
                              - PAY-DISC-AMT 
                              - OTH-ALLOWANC 
                              + INV-DR-TOT  
                              - INV-CR-TOT.
 
            ASSIGN C-TAX = 0
                   S-TAX = 0
                   INV-GROSS = 0.
            
            FOR EACH CSAHF WHERE CSAHF.INVOICE-NO   EQ NUMERO-FAC-ORD 
                             AND CSAHF.INVOICE-DATE EQ COPAR.CUS-INV-DATE 
                             AND CSAHF.ITEM-NUMBER  MATCHES "*TAX*":U NO-LOCK:
              
              IF CSAHF.ITEM-NUMBER MATCHES "*STATE-TAX*":U THEN
                ASSIGN S-TAX = CSAHF.PRICE-EXT.
              IF CSAHF.ITEM-NUMBER MATCHES "*CITY-TAX*":U THEN
                ASSIGN C-TAX = CSAHF.PRICE-EXT.
                
            END. /* FOR EACH CSAHF */
            
            INV-GROSS = TOTAL-FACTURA - C-TAX - S-TAX.
 
            IF TRIM(PS-INV-NO)    NE "":U AND 
               TRIM(ORDER-NUMBER) EQ "":U AND
               copar.cus-inv-date NE ?    AND                
               NOT pago-ar              THEN
            DO:
              PAY-DATE = COPAR.CUS-INV-DATE.              
            END.
 
          END. /* IF AVAILABLE COPAR THEN */
            
        END. /*------facturas una a una (oedslde,ect)----------*/
        
        ASSIGN 
          SP-ON-ACC        = 0.
          SP-ON-ACC-NUMBER = "".
          SP-ON-ACC-NUMBER = ORDER-NUMBER.
       
       
        IF SP-ON-ACC-NUMBER <> ""  AND NOT PSCSHDE-NO-SP  THEN

          FOR EACH coptr WHERE coptr.cust-number                 EQ CCSMS.CUST-NUMBER 
                           AND coptr.cus-chg-no                  EQ "ON/ACC"  
                           AND SUBSTRING(COPTR.DESCRIPTION,1,11) EQ SP-ON-ACC-NUMBER NO-LOCK:
            
            ASSIGN SP-ON-ACC  = SP-ON-ACC + DECIMAL(SUBSTRING(COPTR.DESCRIPTION,16)). 
            
            
          END. /* FOR EACH coptr */
        
        /* When paid amount is < 0 */
        IF PAGO < 0 THEN
        DO: 
          IF P-NEGATIVO <> "" THEN
          DO:
              ASSIGN TMP-INVOICE-NO = PS-INV-NO.
              IF ORDER-NUMBER <> "" THEN
                 ASSIGN TMP-INVOICE-NO = ORDER-NUMBER.                                                                    
     
          END.  /* IF P-NEGATIVO <> "" AND PAGO < 0 */
          
          IF TOTAL-FACTURA > 0 THEN
          DO:

             /* ALLOW CASH BACK UP TO PAYMENTS ALREADY MADE          
                CURRENT PAYMENT < OR = PREVIOUS PAYMENT + DEPOSIT */

             IF ABSOLUTE(PAGO) > (TOTAL-PAGADO + SP-ON-ACC) THEN
             DO:
               objCommonSrc:getMessages(INPUT  ipcLangID,
                                        INPUT  ConstantInitializer:c200CashbackGreaterAmtPaid,                                                              
                                        OUTPUT cError,
                                        OUTPUT opiStatusCode).
                                                               
              IF cError NE "":U THEN 
                UNDO,THROW NEW AppError(cError,1).
     
              RETURN.
     
             END. /* IF ABSOLUTE(PAGO) > (TOTAL-PAGADO + SP-ON-ACC) */
          END. /* IF TOTAL-FACTURA > 0 */

          ELSE
          DO:     
             /* CREDIT WITHOUT DEPOSITS */
             
             IF TOTAL-FACTURA <> PAGO THEN
             DO:
                IF ABSOLUTE(TOTAL-PAGADO + PAGO) > ABSOLUTE( TOTAL-FACTURA + SP-ON-ACC /* 06/20/2014 SP-ON-ACC los depositos anteriores*/ ) THEN 
                DO:
                  objCommonSrc:getMessages(INPUT  ipcLangID,
                                           INPUT  ConstantInitializer:c200CashbackGreaterInvoice,                                                              
                                           OUTPUT cError,
                                           OUTPUT opiStatusCode).
                                      
                  IF cError NE "":U THEN 
                    UNDO,THROW NEW AppError(cError,1).                    
     
                  RETURN.
     
                END. /* IF ABSOLUTE(TOTAL-PAGADO + PAGO) > TOTAL-FACTURA */
             END. /* IF TOTAL-FACTURA <> PAGO */
     
          END. /* ELSE - IF TOTAL-FACTURA > 0 */
       
        END. /* IF PAGO < 0 */
        
        IF SP-ON-ACC-NUMBER <> "" AND
           MB-FIN                 AND 
           LOAN-ORDER-PMT <> 0    THEN
        DO:
          
          THIS-OBJECT:OEMB-BAL(INPUT CCSMS.CUST-NUMBER,
                               INPUT SP-ON-ACC-NUMBER,
                               OUTPUT TOT-PAY-PRO,
                               OUTPUT TOT-PAY-COD,
                               OUTPUT TOT-PAY-OTH,
                               OUTPUT TOT-PAY-LOAN).
                         
          IF LOAN-ORDER-PMT-TYPE = "COD":U THEN  
            ASSIGN SP-ON-ACC = TOT-PAY-COD.
          ELSE 
            ASSIGN SP-ON-ACC = TOT-PAY-PRO + TOT-PAY-OTH.
        
        END. /* IF SP-ON-ACC-NUMBER <> "" AND */
        
        
        IF ORDER-NUMBER <> "":U AND ORDER-NUMBER <> "LOAN-PMT":U THEN 
          ASSIGN total-factura = total-factura - sp-on-acc. 
        
        /* stores the amount left after making payment
           stores the partial amt paid out of total amt  
        */
         
        ASSIGN CHECK-BALANCE = TOTAL-FACTURA.   
        
        IF ORDER-NUMBER <> "LOAN-PMT":U THEN
          FIND FIRST TRAN-COPAR WHERE  TRAN-COPAR.CUST-NUMBER EQ CCSMS.CUST-NUMBER 
                                  AND  TRAN-COPAR.CUS-CHG-NO  BEGINS  cCompany + "C":U
                                  AND (TRAN-COPAR.CUS-INV-NET 
                                    -  TRAN-COPAR.CUS-PAYMENT 
                                    -  TRAN-COPAR.PAY-DISC-AMT 
                                    -  TRAN-COPAR.OTH-ALLOWANC 
                                    -  TRAN-COPAR.INV-CR-TOT 
                                    +  TRAN-COPAR.INV-DR-TOT) LT 0 NO-LOCK NO-ERROR.
           
          IF AVAILABLE TRAN-COPAR AND NOT PSCSHDE-NO-SP   THEN
            ASSIGN 
              INVOICE-2 =   TRAN-COPAR.CUS-CHG-NO
              SP-CREDIT = -(TRAN-COPAR.CUS-INV-NET 
                          - TRAN-COPAR.CUS-PAYMENT 
                          - TRAN-COPAR.PAY-DISC-AMT 
                          - TRAN-COPAR.OTH-ALLOWANC 
                          - TRAN-COPAR.INV-CR-TOT 
                          + TRAN-COPAR.INV-DR-TOT).
          ELSE 
            ASSIGN SP-CREDIT = 0.
           
           
          IF PSCSHDE-NO-SP THEN 
            ASSIGN 
              SP-CREDIT = 0 
              SP-ON-ACC = 0.
        
        IF ORDER-NUMBER NE "" THEN
          ASSIGN ddd8  = ORDER-NUMBER.
        ELSE 
          ASSIGN DDD8  = "".
     
        IF SP-ON-ACC NE 0 THEN
          ASSIGN ddd1  = "DEPO" 
                 ddd2  = STRING(SP-ON-ACC, "->>>>>>9.99").
        ELSE 
          ASSIGN DDD1  = "" DDD2 = "".
         
        IF SP-CREDIT NE 0 THEN
          ASSIGN ddd3  = "CREDIT"
                 ddd4  = STRING(SP-CREDIT).
        ELSE 
          ASSIGN DDD3  = "" DDD4 = "".
         
        IF LAYAWAY THEN
          ASSIGN ddd5  = "ORIGINAL AMOUNT:" 
                 ddd6  = STRING(LAYAWAY-ORIG). 
        ELSE 
          ASSIGN DDD5  = ""  
                 DDD6  = "".  
        
        FIND FIRST BOTONES WHERE BOTONES.PROG-NAME = "PSCSHDE-BTN" NO-LOCK NO-ERROR.
         
        IF AVAILABLE botones THEN 
          ASSIGN botones-data = YES .               
                
        CASE ipcPaymentMethod:

          WHEN "CASH":U THEN
          DO:
            
            ASSIGN PAY-TYPE = "1".
            THIS-OBJECT:proc-btn-reference(INPUT PS-INV-NO,
                                           INPUT ORDER-NUMBER,
                                           INPUT pay-type,
                                           INPUT ipcLangId).
            ASSIGN tmp-desc = "CASH":U.
            
                                                                   
          END. /*  WHEN "CASH":U THEN */
          
          WHEN "CHEQUE":U THEN
          DO:
            ASSIGN PAY-TYPE = "2".
              
            IF botones-data THEN /* check for botones-data */
            DO:

              THIS-OBJECT:proc-btn-reference(INPUT PS-INV-NO,
                                             INPUT ORDER-NUMBER,
                                             INPUT pay-type,
                                             INPUT ipcLangId).                                    
                                        
              ASSIGN 
                tmp-desc   = "CHECK":U
                D-REF4-txt = ipcChequeNumber
                D-REF4-cd  = "chk":U.
            //  MESSAGE 'D-REF4-txt ' D-REF4-txt  " " " D-REF4-cd " D-REF4-cd.
                 

            END. /* IF botones-data THEN */
             
          END. /* WHEN "CHEQUE":U THEN */
          
          WHEN "INVOICE":U THEN
          DO:
            ASSIGN PAY-TYPE = "10".
            THIS-OBJECT:proc-btn-reference(INPUT PS-INV-NO,
                                           INPUT ORDER-NUMBER,
                                           INPUT pay-type,
                                           INPUT ipcLangId).
                                           
            ASSIGN tmp-desc = "INVOICE":U.
            
          END. /*  WHEN "INVOICE":U THEN */
          
          /* When online payment is made then DB will capture Type-Tran-Ar as ONLINE */
          
          WHEN "ONLINE":U THEN
          DO:
            ASSIGN PAY-TYPE = "11".
            THIS-OBJECT:proc-btn-reference(INPUT PS-INV-NO,
                                           INPUT ORDER-NUMBER,
                                           INPUT pay-type,
                                           INPUT ipcLangId).
                                           
            ASSIGN tmp-desc = "ONLINE":U.
            
          END. /*  WHEN "ONLINE":U THEN */
          
        END CASE. /* ipcPaymentMethod */
          
        COLLECT:
        DO ON ERROR  UNDO COLLECT TRANSACTION:
          
         FOR EACH TT-PAYMENTS:
           DELETE TT-PAYMENTS.
         END.
         
         ASSIGN  
           TOTAL-PAGADO     = 0 
           CHECK-BALANCE    = TOTAL-FACTURA 
           PS-CHANGE        = 0 
           CHK-NO           = "".
         
         ASSIGN 
           PREV-PAGO-CREDIT = 0 
           PREV-PAGO-ONACC  = 0.
         
         REPEAT: 
           IF PAGO-DE-ORDEN THEN 
             ASSIGN CHECK-BALANCE = TOTAL-FACTURA - TOTAL-PAGADO - COD-AMOUNT.
           
           IF ES-LAYAWAY3 THEN 
           DO:
              IF NOT AVAILABLE COOHD THEN
              DO: 
                objCommonSrc:getMessages(INPUT  ipcLangID,
                                         INPUT  ConstantInitializer:c200OrderNtAvail,                                                              
                                         OUTPUT cError,
                                         OUTPUT opiStatusCode).
            
                IF cError NE "":U THEN 
                  UNDO,THROW NEW AppError(cError,1).                          
                      
              END. /* IF NOT AVAILABLE COOHD */      
              
              ASSIGN CHECK-BALANCE = TOTAL-FACTURA - TOTAL-PAGADO - COD-AMOUNT.                           
           END. /* IF  ES-LAYAWAY3 THEN */
           

           IF PAY-TYPE = "0" THEN 
             LEAVE. 

           IF PAY-TYPE = "" THEN 
             LEAVE. /*  CANCEL*/
             
           IF PAGO = 0 THEN 
             UNDO, RETRY.

           IF cancel-layaway AND ABS(pago) > ABS(check-balance) THEN 
             UNDO, RETRY.
           /*NP Condition when paid amount is gt total i.e check-balance*/

           ASSIGN 
             TOTAL-PAGADO  = TOTAL-PAGADO + PAGO
             CHECK-BALANCE = TOTAL-FACTURA - TOTAL-PAGADO - COD-AMOUNT. 
           
           IF LAYAWAY AND NOT cancel-layaway THEN            
             IF abono-layaway - total-pagado LE 0  THEN 
               ASSIGN PS-CHANGE = TOTAL-PAGADO - abono-layaway.
           
           IF CHECK-BALANCE LT 0  AND 
             NOT CANCEL-LAYAWAY   AND 
             NOT PS-INV-NO BEGINS cCompany + "C" THEN 
           
           DO:
             
             ASSIGN CHECK-BALANCE = 0.
             IF layaway THEN 
                PS-CHANGE = TOTAL-PAGADO - abono-layaway.
             ELSE 
                PS-CHANGE = TOTAL-PAGADO - (TOTAL-FACTURA - COD-AMOUNT).
                
           END. /* IF CHECK-BALANCE < 0 */

            CREATE TT-PAYMENTS. 
            ASSIGN 
              TT-PAYMENTS.p-type     = PAY-TYPE
              TT-PAYMENTS.p-pay      = pago
              TT-PAYMENTS.p-ref      = chk-no
              TT-PAYMENTS.p-change   = 0
              TT-PAYMENTS.p-D-REF4   = D-REF4-cd + D-REF4-txt
              TT-PAYMENTS.p-D-REF5   = D-REF5-cd + D-REF5-txt
              TT-PAYMENTS.p-D-REF6   = D-REF6-cd + D-REF6-txt
              TT-PAYMENTS.p-D-REF7   = D-REF7-cd + D-REF7-txt
              TT-PAYMENTS.P-TMP-DESC = TMP-DESC.
            
           // MESSAGE " TT-PAYMENTS.p-D-REF4 "  TT-PAYMENTS.p-D-REF4. 
            
            ASSIGN 
              CHK-NO = "":U 
              PAGO   = 0.
            
            
            IF (NOT LAYAWAY AND ABS(TOTAL-PAGADO) >= ABS(TOTAL-FACTURA) - ABS(COD-AMOUNT)) THEN
            DO:
              
              IF (PAY-TYPE = "2":U  OR PAY-TYPE  = "3":U) AND
                  PS-INV-NO = "on/acc":U                  THEN 
              DO:
                ASSIGN ps-change = 0.                  
              END.
              ELSE  
                ASSIGN TT-PAYMENTS.p-change = ps-change.
              
              /* If amount paid is greater than total amount then leave */
              
              LEAVE.
            END. /* IF (NOT LAYAWAY AND ABS(TOTAL-PAGADO) >= ABS(TOTAL-FACTURA) - ABS(COD-AMOUNT))  */
            
            IF LAYAWAY AND ABS(total-pagado) >= abs(ABONO-LAYAWAY) THEN   
            DO:
               ASSIGN TT-PAYMENTS.p-change = ps-change.
               
               LEAVE.
            END.
           
         END. /* REPEAT */ 
         
         IF CANCEL-LAYAWAY AND check-balance <> 0 THEN
         DO:  
           
            UNDO COLLECT.
         END.
         
         IF NOT CANCEL-LAYAWAY AND layaway AND abono-layaway <> (total-pagado - ps-change) THEN
         DO:  
                 
            UNDO COLLECT.
         END.
         
         IF NOT PSCSHDE-fast-reg THEN 
           THIS-OBJECT:proc-abre-caja().
                
         /* canceled the entry */
         IF PAY-TYPE = "":U THEN 
         DO:
            UNDO COLLECT.
         END. /* IF PAY-TYPE = "":U THEN   */
         
         IF TOTAL-PAGADO NE 0 THEN
         DO:                           
            ASSIGN
              TEMP-CHAR = STRING(PS-CHANGE,"->>,>>>.99")
              CHOICE    = YES.
       
            IF w-APPLY-DEPO THEN UNDO COLLECT.
         END. /* IF TOTAL-PAGADO NE 0 THEN :U */
         
         IF RECEIPT-COPY AND NOT ORDER-NUMBER = "LOAN-PMT":U THEN
         DO:           
            ASSIGN 
              TEMP-INT = NEXT-VALUE(Next-receipt)
              R-NUMBER = cCompany  + STRING (TEMP-INT, "99999").
       
         END.              
              
         ELSE 
           ASSIGN R-NUMBER = "":U.
         
         IF PAGO-DE-ORDEN 
            AND VIA-WANTED 
            AND (COOHD.LAYER-TYPE = "3" OR COOHD.LAYER-TYPE = "2") THEN 
         DO:
          FIND COOHD WHERE COOHD.ORDER-NUMBER EQ ORDER-NUMBER EXCLUSIVE-LOCK NO-ERROR.
          IF AVAILABLE COOHD THEN
          DO:
             IF COD-AMOUNT NE 0 THEN 
               ASSIGN COOHD.TP-APPL = "COD: " + STRING(COD-AMOUNT,">>,>>>.99-"). 
             
             ELSE 
               ASSIGN COOHD.TP-APPL = "":U.
               
          END. /*  IF AVAILABLE COOHD */
         END. /* IF PAGO-DE-ORDEN.. */
         
         CASH-APPLY:
         FOR EACH TT-PAYMENTS WHERE TT-PAYMENTS.p-pay NE 0:
           ASSIGN pago-work = TT-PAYMENTS.p-pay.
           
           IF pago-multiple THEN
           DO:
              ASSIGN BALANCE-MULTIPLE = TT-PAYMENTS.p-pay.
              DIST-MULT:
              REPEAT temp-int = 1 TO 10:
                IF fact-multiple[temp-int] = "" THEN 
                  LEAVE DIST-MULT.
                IF BALANCE-MULTIPLE = 0  THEN 
                  LEAVE DIST-MULT.
     
                ASSIGN 
                  PS-INV-NO      = fact-multiple[temp-int]
                  NUMERO-FAC-ORD = PS-INV-NO.
     
                FIND COPAR WHERE COPAR.CUST-NUMBER = CCSMS.CUST-NUMBER
                             AND COPAR.CUS-CHG-NO  = PS-INV-NO EXCLUSIVE-LOCK NO-ERROR.
     
                IF NOT AVAILABLE COPAR THEN
                DO:                    
                   objCommonSrc:getMessages(INPUT  ipcLangID,
                                            INPUT  ConstantInitializer:c200InvoiceNtFound,                                                              
                                            OUTPUT cError,
                                            OUTPUT opiStatusCode).
                   cError = 'Copar not available'.                  
                   IF cError NE "":U THEN 
                     UNDO,THROW NEW AppError(cError,1).   
                
                END. /* IF NOT AVAILABLE COPAR THEN  */
     
                ASSIGN INV-AMT = COPAR.CUS-INV-NET  
                               - COPAR.CUS-PAYMENT
                               - COPAR.PAY-DISC-AMT 
                               - COPAR.OTH-ALLOWANC
                               + COPAR.INV-DR-TOT   
                               - COPAR.INV-CR-TOT.
     
                IF INV-AMT >= BALANCE-MULTIPLE THEN 
                  ASSIGN 
                    PAGO-WORK        = BALANCE-MULTIPLE 
                    BALANCE-MULTIPLE = 0.
                ELSE 
                  ASSIGN 
                    PAGO-WORK        = INV-AMT 
                    BALANCE-MULTIPLE = BALANCE-MULTIPLE - INV-AMT.
     
                IF inv-amt > 0 THEN
                DO:                   
                  THIS-OBJECT:PROC-UPDATE(INPUT PS-INV-NO,
                                          INPUT PS-CUST-NUMBER,
                                          INPUT ORDER-NUMBER,
                                          INPUT ipcLangID,
                                          OUTPUT cError).
                  IF cError NE "":U THEN
                    UNDO,THROW NEW AppError(cError,1).
                END. 
              END. /* REPEAT temp-int = 1 TO 10 */
     
              IF TT-PAYMENTS.P-CHANGE <> 0 THEN 
                THIS-OBJECT:proc-change().
         
           END. /* IF pago-multiple */
           
           ELSE
           DO:
             
             THIS-OBJECT:PROC-UPDATE(INPUT PS-INV-NO,
                                     INPUT PS-CUST-NUMBER,
                                     INPUT ORDER-NUMBER,
                                     INPUT ipcLangID,
                                     OUTPUT cError).
             IF cError NE "":U THEN
               UNDO,THROW NEW AppError(cError,1). 
           END. /* ELSE  */
         
         END. /*FOR EACH TT-PAYMENTS:*/
         
         ASSIGN CHECK-AMOUNT = TOTAL-PAGADO.          
   
        END. /* DO ON ERROR  UNDO COLLECT TRANSACTION, COLLECT BLK */  
        
        CATCH errorObj AS AppError:           
        ASSIGN 
          opcError = errorObj:GetMessage(1).
        END CATCH.

    END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID oemb-bal(INPUT CUST-NUMBER   AS CHARACTER,
                              INPUT ORDER-NUMBER  AS CHARACTER,
                              OUTPUT TOT-PAY-PRO  AS DECIMAL,
                              OUTPUT TOT-PAY-COD  AS DECIMAL,
                              OUTPUT TOT-PAY-OTH  AS DECIMAL,
                              OUTPUT TOT-PAY-LOAN AS DECIMAL):
                                
        FOR EACH coptr WHERE coptr.cust-number                  EQ CUST-NUMBER 
                         AND coptr.cus-chg-no                   EQ "ON/ACC":U 
                         AND SUBSTRING(COPTR.DESCRIPTION,1,11)  EQ ORDER-NUMBER NO-LOCK:
         
          IF SUBSTRING(COPTR.DESCRIPTION,12,4) = "LOAN":U THEN 
            ASSIGN TOT-PAY-LOAN = TOT-PAY-LOAN + DECIMAL(SUBSTRING(COPTR.DESCRIPTION,16)). 
          
          ELSE
          IF SUBSTRING(COPTR.DESCRIPTION,12,3) = "COD":U THEN 
            ASSIGN TOT-PAY-COD = TOT-PAY-COD + DECIMAL(SUBSTRING(COPTR.DESCRIPTION,16)). 
          
          ELSE
          IF SUBSTRING(COPTR.DESCRIPTION,12,3) = "PRO":U THEN 
            ASSIGN TOT-PAY-PRO = TOT-PAY-PRO + DECIMAL(SUBSTRING(COPTR.DESCRIPTION,16)). 
             
          ELSE 
            ASSIGN TOT-PAY-OTH = TOT-PAY-OTH + DECIMAL(SUBSTRING(COPTR.DESCRIPTION,16)). 
        
        END. /* FOR EACH coptr */                                
    
  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID PROC-APLICAR-CREDIT(INPUT PS-INV-NO      AS CHARACTER,
                                         INPUT PS-CUST-NUMBER AS CHARACTER,
                                         INPUT ipcLangID      AS CHARACTER,
                                         OUTPUT opcError      AS CHARACTER):
   DEFINE VARIABLE objCommonSrc AS  CLASS commonSource NO-UNDO.
   objCommonSrc = NEW commonSource(INPUT cToken).
    
   FIND CCSMS WHERE CCSMS.CUST-NUMBER = PS-CUST-NUMBER EXCLUSIVE-LOCK NO-ERROR.
 
   DO:
      FIND TRAN-COPAR WHERE TRAN-COPAR.CUST-NUMBER = CCSMS.CUST-NUMBER
                        AND TRAN-COPAR.CUS-CHG-NO  = INVOICE-2 EXCLUSIVE-LOCK NO-ERROR.
      
      IF NOT AVAILABLE TRAN-COPAR THEN
      DO:           
        /* get multilingual message for Memo not found */
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200MemoNtFound,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).
      
      END. /* IF NOT AVAILABLE TRAN-COPAR THEN  */
 
      ASSIGN 
        TRAN-COPAR.CUS-NO-TRAN = TRAN-COPAR.CUS-NO-TRAN + 1.
      
      ASSIGN QTY        = TRAN-COPAR.CUS-INV-NET  - TRAN-COPAR.CUS-PAYMENT
                        - TRAN-COPAR.PAY-DISC-AMT - TRAN-COPAR.OTH-ALLOWANC
                        + TRAN-COPAR.INV-DR-TOT   - TRAN-COPAR.INV-CR-TOT
             CUS-CHG-NO = PS-INV-NO.
   
   
      FIND COPAR WHERE COPAR.CUST-NUMBER = CCSMS.CUST-NUMBER
                   AND COPAR.CUS-CHG-NO  = CUS-CHG-NO EXCLUSIVE-LOCK NO-ERROR.
      IF NOT AVAILABLE COPAR THEN
      DO:       
        objCommonSrc:getMessages(INPUT  ipcLangID,
                                 INPUT  ConstantInitializer:c200InvoiceNtFound,                                                              
                                 OUTPUT cError,
                                 OUTPUT opiStatusCode).
                                      
        IF cError NE "":U THEN 
          UNDO,THROW NEW AppError(cError,1).               
                  
      END.
 
      ASSIGN INV-AMT = COPAR.CUS-INV-NET  - COPAR.CUS-PAYMENT
                     - COPAR.PAY-DISC-AMT - COPAR.OTH-ALLOWANC
                     + COPAR.INV-DR-TOT   - COPAR.INV-CR-TOT.
                    
      CREATE COPTR. 
 
      ASSIGN  
        COPTR.INV-CR-TOT = pago-work
        NEW-BAL          = INV-AMT - COPTR.INV-CR-TOT.
                
                /* RECORD FOR THE CUSTOMER MASTER FILE */
      ASSIGN CCSMS.CREDIT-AMT = CCSMS.CREDIT-AMT - COPTR.INV-CR-TOT.
     
      IF CUS-CHG-NO BEGINS cCompany + "D" THEN
         ASSIGN CCSMS.DEBIT-AMT = CCSMS.DEBIT-AMT - COPTR.INV-CR-TOT.
     
      ELSE
         IF CUS-CHG-NO BEGINS cCompany + "C" THEN
            ASSIGN CCSMS.CREDIT-AMT = CCSMS.CREDIT-AMT - COPTR.INV-CR-TOT.
         ELSE
            IF CUS-CHG-NO = "ON/ACC" OR CUS-CHG-NO = "OA" THEN
               ASSIGN CCSMS.ON-ACCOUNT = CCSMS.ON-ACCOUNT - COPTR.INV-CR-TOT.
            ELSE
               ASSIGN CCSMS.OPEN-INVOICE = CCSMS.OPEN-INVOICE - COPTR.INV-CR-TOT.
      
      /* RECORD FOR THE INVOICE */
      ASSIGN 
        COPAR.INV-CR-TOT   = COPAR.INV-CR-TOT + COPTR.INV-CR-TOT
        COPAR.CUS-PAY-DATE = TRANS-DATE.
      /* RECORD FOR THE TRANSACTION */
      ASSIGN 
        COPTR.CUST-NUMBER  = COPAR.CUST-NUMBER
        COPTR.CUS-CHG-NO   = COPAR.CUS-CHG-NO
        COPTR.TYPE-TRAN-AR = TRAN-COPAR.CUS-CHG-NO
        COPTR.TRAN-SEQ     = TRAN-COPAR.CUS-NO-TRAN
        COPTR.CUS-INV-DATE = COPAR.CUS-INV-DATE
        COPTR.CUS-ORDER-NO = "CR MEMO":U
        COPTR.CUS-PAY-DATE = TRANS-DATE
        COPTR.SALES-REP-ID = COPAR.SALES-REP-ID.
        
      /* RECORD FOR THE INVOICE JOURNAL */
      CREATE CAPLY.
      ASSIGN 
        CAPLY.CUST-NUMBER  = COPTR.CUST-NUMBER
        CAPLY.CHECK-NUMBER = COPTR.CUS-ORDER-NO
        CAPLY.CUS-CHG-NO   = COPTR.CUS-CHG-NO
        CAPLY.TYPE-TRAN-NO = COPTR.TYPE-TRAN-AR
        CAPLY.CUST-NAME    = CCSMS.CUST-NAME
        CAPLY.INV-OLD-BAL  = INV-AMT
        CAPLY.CUS-PAYMENT  = COPTR.INV-CR-TOT
        CAPLY.INV-NEW-BAL  = NEW-BAL
        CAPLY.CUS-PAY-DATE = COPTR.CUS-PAY-DATE
        CAPLY.COMPANY-CODE = cCompany.
        
      /* RECORD FOR THE DEBIT MEMO */
      ASSIGN 
        TRAN-COPAR.INV-DR-TOT   = TRAN-COPAR.INV-DR-TOT
                                + COPTR.INV-CR-TOT.
      /* RECORD FOR THE DB/MEMO TRANSACTION */
      CREATE TRAN-COPTR.
      ASSIGN 
        TRAN-COPTR.CUST-NUMBER  = COPTR.CUST-NUMBER
        TRAN-COPTR.CUS-CHG-NO   = COPTR.TYPE-TRAN-AR
        TRAN-COPTR.TYPE-TRAN-AR = COPTR.CUS-CHG-NO
        TRAN-COPTR.TRAN-SEQ     = COPTR.TRAN-SEQ
        TRAN-COPTR.INV-DR-TOT   = COPTR.INV-CR-TOT
        TRAN-COPTR.CUS-INV-DATE = COPTR.CUS-INV-DATE
        TRAN-COPTR.SALES-REP-ID = COPTR.SALES-REP-ID
        TRAN-COPTR.CUS-PAY-DATE = TRANS-DATE.
       
   
   END. /* FIND CCSMS WHERE CCSMS.CUST-NUMBER = PS-CUST-NUMBER EXCLUSIVE-LOCK NO-ERROR */
      
   CATCH errorObj AS AppError:           
     ASSIGN 
       opcError = errorObj:GetMessage(1).
   END CATCH.
  
  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID PROC-APLICAR-ON-ACC(INPUT PS-INV-NO      AS CHARACTER,
                                         INPUT PS-CUST-NUMBER AS CHARACTER,
                                         INPUT order-number   AS CHARACTER,
                                         INPUT ipcLangID      AS CHARACTER,
                                         OUTPUT opcError      AS CHARACTER):
    
    DEFINE VARIABLE objCommonSrc AS CLASS COmmonSource NO-UNDO.
    FIND CCSMS WHERE CCSMS.CUST-NUMBER = PS-CUST-NUMBER EXCLUSIVE-LOCK.
 
    FIND TRAN-COPAR WHERE TRAN-COPAR.CUST-NUMBER EQ CCSMS.CUST-NUMBER
                      AND TRAN-COPAR.CUS-CHG-NO  EQ "ON/ACC":U EXCLUSIVE-LOCK NO-ERROR.
    
    IF NOT AVAILABLE TRAN-COPAR THEN
    DO: 
      objCommonSrc:getMessages(INPUT  ipcLangID,
                               INPUT  ConstantInitializer:c200MemoNtFound,                                                              
                               OUTPUT cError,
                               OUTPUT opiStatusCode).
                                      
      IF cError NE "":U THEN 
        UNDO,THROW NEW AppError(cError,1).      
        
    END.
    
    ASSIGN QTY =  TRAN-COPAR.CUS-INV-NET 
                - TRAN-COPAR.CUS-PAYMENT
                - TRAN-COPAR.PAY-DISC-AMT 
                - TRAN-COPAR.OTH-ALLOWANC
                + TRAN-COPAR.INV-DR-TOT 
                - TRAN-COPAR.INV-CR-TOT.
 
    ASSIGN CUS-CHG-NO = PS-INV-NO.
 
    FIND FIRST COPAR WHERE COPAR.CUST-NUMBER EQ CCSMS.CUST-NUMBER
                       AND COPAR.CUS-CHG-NO  EQ CUS-CHG-NO EXCLUSIVE-LOCK NO-ERROR.
    IF NOT AVAILABLE COPAR THEN
    DO:        
        UNDO, RETRY.
    END.
 
    ASSIGN INV-AMT = COPAR.CUS-INV-NET  
                   - COPAR.CUS-PAYMENT
                   - COPAR.PAY-DISC-AMT 
                   - COPAR.OTH-ALLOWANC
                   + COPAR.INV-DR-TOT   
                   - COPAR.INV-CR-TOT.
 
    CREATE COPTR.  

    ASSIGN COPTR.INV-CR-TOT = pago-work.      
 
    ASSIGN NEW-BAL = INV-AMT 
                   - COPTR.INV-CR-TOT 
                   - COPTR.PAY-DISC-AMT 
                   - COPTR.OTH-ALLOWANC.
 
    /* RECORD FOR THE CUSTOMER MASTER FILE */
    ASSIGN CCSMS.ON-ACCOUNT   = CCSMS.ON-ACCOUNT - COPTR.INV-CR-TOT.
 
    IF CUS-CHG-NO BEGINS cCompany + "D" THEN
      ASSIGN CCSMS.DEBIT-AMT = CCSMS.DEBIT-AMT - COPTR.INV-CR-TOT .
    
    ELSE
      IF CUS-CHG-NO BEGINS cCompany + "C" THEN
        ASSIGN CCSMS.CREDIT-AMT = CCSMS.CREDIT-AMT - COPTR.INV-CR-TOT .
      
      ELSE
        IF CUS-CHG-NO = "ON/ACC"  OR 
           CUS-CHG-NO = "OA"      THEN
          ASSIGN CCSMS.ON-ACCOUNT = CCSMS.ON-ACCOUNT
                                  - COPTR.INV-CR-TOT.
        ELSE
          ASSIGN CCSMS.OPEN-INVOICE = CCSMS.OPEN-INVOICE
                                    - COPTR.INV-CR-TOT.
 
    /* RECORD FOR THE INVOICE */
    ASSIGN 
      COPAR.CUS-NO-TRAN  = COPAR.CUS-NO-TRAN + 1
  
      COPAR.INV-CR-TOT  = COPAR.INV-CR-TOT
                         + COPTR.INV-CR-TOT 
      COPAR.PAY-DISC-AMT = COPAR.PAY-DISC-AMT
                         + COPTR.PAY-DISC-AMT
      COPAR.OTH-ALLOWANC = COPAR.OTH-ALLOWANC
                         + COPTR.OTH-ALLOWANC
      COPAR.CUS-PAY-DATE = TRANS-DATE.
 
    /* RECORD FOR THE TRANSACTION */
    ASSIGN 
      COPTR.CUST-NUMBER  = COPAR.CUST-NUMBER
      COPTR.CUS-CHG-NO   = COPAR.CUS-CHG-NO
      COPTR.TYPE-TRAN-AR = "O/A"
                         + STRING(COPAR.CUS-NO-TRAN,"99999")  
      COPTR.CUS-INV-DATE = COPAR.CUS-INV-DATE
      COPTR.CUS-ORDER-NO = "ON ACCOUNT"
      COPTR.CUS-PAY-DATE = TRANS-DATE
      COPTR.SALES-REP-ID = COPAR.SALES-REP-ID.
 
    /* RECORD FOR THE INVOICE JOURNAL */
    CREATE CAPLY.
    ASSIGN 
      CAPLY.CUST-NUMBER  = COPTR.CUST-NUMBER
      CAPLY.CHECK-NUMBER = COPTR.CUS-ORDER-NO
      CAPLY.CUS-CHG-NO   = COPTR.CUS-CHG-NO
      CAPLY.TYPE-TRAN-NO = COPTR.TYPE-TRAN-AR
      CAPLY.CUST-NAME    = CCSMS.CUST-NAME
      CAPLY.INV-OLD-BAL  = INV-AMT
      CAPLY.CUS-PAYMENT  = COPTR.INV-CR-TOT 
      CAPLY.PAYMENT-DISC = COPTR.PAY-DISC-AMT
      CAPLY.OTH-ALLOWANC = COPTR.OTH-ALLOWANC
      CAPLY.INV-NEW-BAL  = NEW-BAL
      CAPLY.CUS-PAY-DATE = COPTR.CUS-PAY-DATE
      CAPLY.COMPANY-CODE = cCompany.
 
    /* RECORD FOR THE ON/ACC INVOICE */
    FIND TRAN-COPAR WHERE TRAN-COPAR.CUST-NUMBER = CCSMS.CUST-NUMBER
                      AND TRAN-COPAR.CUS-CHG-NO  = "ON/ACC":U EXCLUSIVE-LOCK NO-ERROR.
    ASSIGN 
      TRAN-COPAR.CUS-NO-TRAN  = TRAN-COPAR.CUS-NO-TRAN + 1
      TRAN-COPAR.INV-DR-TOT   = TRAN-COPAR.INV-DR-TOT + COPTR.INV-CR-TOT.
 
    /* RECORD FOR THE ON/ACC TRANSACTION */
    CREATE TRAN-COPTR.
    ASSIGN 
      TRAN-COPTR.CUST-NUMBER                 = COPTR.CUST-NUMBER
      TRAN-COPTR.CUS-CHG-NO                  = "ON/ACC"
      TRAN-COPTR.TYPE-TRAN-AR                = "O/A" + STRING(TRAN-COPAR.CUS-NO-TRAN,"99999")     
      TRAN-COPTR.INV-DR-TOT                  = COPTR.INV-CR-TOT 
      tran-coptr.cus-pay-date                = trans-date 
      TRAN-COPTR.SALES-REP-ID                = CCSMS.SALES-REP-ID
      TRAN-COPTR.CUS-ORDER-NO                = COPTR.CUS-CHG-NO
      TRAN-COPTR.ORDER-NUMBER                = order-number
      TRAN-COPTR.ORDER-BALANCE               = DECIMAL(SUBSTRING(tran-COPTR.DESCRIPTION,16)) - coptr.inv-cr-tot 
      tran-coptr.DESCRIPTION                 = " "
      SUBSTRING(tran-coptr.DESCRIPTION,1,11) = order-number 
      SUBSTRING(tran-COPTR.DESCRIPTION,16)   = STRING(DECIMAL(SUBSTRING(tran-COPTR.DESCRIPTION,16)) - coptr.inv-cr-tot , "->>,>>>,>>>.99").
    
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.
    
  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID proc-btn-reference(INPUT PS-INV-NO    AS CHARACTER,
                                        INPUT ORDER-NUMBER AS CHARACTER,
                                        INPUT pay-type     AS CHARACTER,
                                        INPUT ipcLangID    AS CHARACTER):
      IF MB-FIN AND PS-INV-NO = "ON/ACC":U  AND CCSMS.CUST-TYPE = "COBROS":U THEN
        ASSIGN TEMP-CHAR = "":U.
      
      ASSIGN
        D-REF4-cd  = "" 
        D-REF4-txt = "" 
        D-REF4     = ""
        D-REF5-cd  = "" 
        D-REF5-txt = "" 
        D-REF5     = ""
        D-REF6-cd  = "" 
        D-REF6-txt = "" 
        D-REF6     = ""
        D-REF7-cd  = "" 
        D-REF7-txt = "" 
        D-REF7     = "".
 
      IF NOT botones-data THEN RETURN.
     
      IF ((SP-ON-ACC - PREV-PAGO-ONACC) <> 0  AND 
          ORDER-NUMBER = "") AND FORCE-DEPOS THEN 
      DO:        
        ASSIGN w-APPLY-DEPO = TRUE. 
        RETURN.
      END.
     
      ASSIGN w-APPLY-DEPO = FALSE.
      
      FIND FIRST BOTONES WHERE BOTONES.PROG-NAME EQ "PSCSHDE-BTN":U 
                           AND botones.integer1  EQ INTEGER(pay-type) NO-LOCK NO-ERROR . 
                       
      IF NOT AVAILABLE botones THEN RETURN.
      
      IF NOT botones.logical3 
         AND  CHECK-BALANCE - pago <> 0 
         AND NOT PS-INV-NO = "ON/ACC" THEN
      DO:
        
        /********************************************************/
        /* CHECK FOR PAYMENTS OVER BALANCE DUE                  */
        /********************************************************/
     
        IF ABSOLUTE ( PAGO ) > ABSOLUTE ( CHECK-BALANCE )  AND NOT pago < 0 THEN
        DO:          
            ASSIGN 
              pay-type = "":U               
              SALIDA   = "CANCEL":U.
            RETURN.
     
        END. /* IF PAGO > CHECK-BALANCE */
        
        ELSE
        /********************************************************/
        /* ALLOW PARTIAL PAYMENTS                               */
        /********************************************************/
        DO:
            "1".
        END.
     
      END. /* IF NOT botones.logical3 AND  CHECK-BALANCE - pago <> 0 */
     
      /********************************************************/
      /* CHAR2 HAS SPECIAL INSTRUCCTIONS                      */
      /********************************************************/ 
      IF botones.char2 = "":U 
         AND botones.char4 = "non":U
         AND botones.char5 = "non":U
         AND botones.char6 = "non":U 
         AND botones.char7 = "non":U    THEN RETURN.     
     
      IF BOTONES.CHAR4 <> "non":U THEN 
        ASSIGN D-REF4 = SUBSTRING(BOTONES.CHAR4,5) D-REF4-cd = SUBSTRING(BOTONES.CHAR4,1,3).
      
      ELSE 
        ASSIGN 
          D-REF4    = "":U
          D-REF4-cd = "":U.
     
      IF BOTONES.CHAR5 <> "non":U THEN 
        ASSIGN D-REF5 = SUBSTRING(BOTONES.CHAR5,5) D-REF5-cd = SUBSTRING(BOTONES.CHAR5,1,3).
      ELSE 
        ASSIGN 
          D-REF5    = "":U 
          d-ref5-cd = "":U.
     
      IF BOTONES.CHAR6 <> "non":U THEN 
        ASSIGN D-REF6 = SUBSTRING(BOTONES.CHAR6,5) D-REF6-cd = SUBSTRING(BOTONES.CHAR6,1,3).
      ELSE 
        ASSIGN 
          D-REF6    = "":U 
          d-ref6-cd = "":U.
     
      IF BOTONES.CHAR7 <> "non":U THEN 
        ASSIGN D-REF7 = SUBSTRING(BOTONES.CHAR7,5) D-REF7-cd = SUBSTRING(BOTONES.CHAR7,1,3).
      ELSE 
        ASSIGN
          D-REF7    = "":U
          D-REF7-cd = "":U.                                   
        
      /*ON 'CHOOSE' OF BTN-CANCEL IN FRAME FR-REF
      DO:
          SALIDA = "CANCEL".
          
      END.*/              
      
      /*IF salida = "cancel" THEN PAY-TYPE = "".*/

  END METHOD.    

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID proc-abre-caja(  ):
    /*DEFINE VARIABLE printer-orig AS CHARACTER FORMAT "x(32)" NO-UNDO.
    
    ASSIGN printer-orig = SESSION:PRINTER-NAME NO-ERROR.
 
    //{SMCAJA.i} /*ACEROS 03/21/2007*/  /*jkt*/
 
    IF printer-orig <> "" THEN 
      ASSIGN SESSION:PRINTER-NAME = printer-orig.*/
    
  END METHOD.   

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID proc-change():
      
      FIND ccrir WHERE CCRIR.CUST-NUMBER   EQ CCSMS.CUST-NUMBER  AND
                        CCRIR.CHECK-NUMBER EQ TT-PAYMENTS.P-TYPE AND
                        CCRIR.CUS-CHG-NO   EQ NUMERO-FAC-ORD     AND            
                        CCRIR.TYPE-TRAN-NO EQ "CHANGE":U         EXCLUSIVE-LOCK NO-ERROR.
 
      IF NOT AVAILABLE ccrir THEN 
        CREATE CCRIR.
 
      ASSIGN
         CCRIR.CUST-NUMBER  = CCSMS.CUST-NUMBER
         CCRIR.CHECK-NUMBER = TT-PAYMENTS.P-TYPE
         CCRIR.CUS-CHG-NO   = NUMERO-FAC-ORD
         CCRIR.TYPE-TRAN-NO = "CHANGE"
         CCRIR.CUST-NAME    = CCSMS.CUST-NAME
         CCRIR.TERMINAL-ID  = TERMINAL-ID
         CCRIR.CUS-PAYMENT  = CCRIR.CUS-PAYMENT + TT-PAYMENTS.P-CHANGE
         CCRIR.CUS-PAY-DATE = PAY-DATE
         CCRIR.COMPANY-CODE = cCompany
         CCRIR.SALES-REP-ID = COPAR.SALES-REP-ID
         CCRIR.CASHIER-CD   = STRING(COPAR.INVEN-WHS-CD)
         CCRIR.PAYMENT-DISC = Invoice-discount.
      
     
      
           /*02/17/2015 SIMPRE DEBE USAR EL WAREHOUSE DEL CAJERO PARA QUE LA ENTRADA APAREZCA EN SU CUADRE*/
      IF POINT-STORE NE 0 THEN
        ASSIGN CCRIR.CASHIER-CD = STRING(POINT-STORE). 
 
      ASSIGN CCRIR.RECEIPT-NUM  = INTEGER(SUBSTRING(R-NUMBER,2,5)).
 
      IF MB-FIN AND LOAN-ORDER-PMT <> 0 THEN 
      DO:
        IF LOAN-ORDER-PMT-TYPE = "COD":U THEN  
          SUBSTRING(CCRIR.CUST-NAME,31,18)  = "LOAN-ORDER-PMT-COD":U. 
        
        ELSE 
          SUBSTRING(CCRIR.CUST-NAME,31,14)  = "LOAN-ORDER-PMT":U. 
          
      END. /* IF MB-FIN AND LOAN-ORDER-PMT <> 0 THEN   */
 
      IF MB-FIN AND LOAN-PMT <> 0 THEN 
        ASSIGN SUBSTRING(CCRIR.CUST-NAME,31,8)  = "LOAN-PMT":U. 
    
  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID PROC-ORDEN-PAGADA-CON-CREDITO(INPUT PS-CUST-NUMBER AS CHARACTER,
                                                   INPUT ORDER-NUMBER   AS CHARACTER,
                                                   OUTPUT opcError      AS CHARACTER,
                                                   INPUT ipcLangID      AS CHARACTER):
                                                     
    
     DEFINE VARIABLE objCommonSrc AS CLASS commonSource NO-UNDO.
     
     FIND CCSMS WHERE CCSMS.CUST-NUMBER = PS-CUST-NUMBER EXCLUSIVE-LOCK NO-ERROR.
     IF AVAILABLE ccsms THEN
     DO:
        FIND TRAN-COPAR WHERE TRAN-COPAR.CUST-NUMBER = CCSMS.CUST-NUMBER
                          AND TRAN-COPAR.CUS-CHG-NO  = INVOICE-2 EXCLUSIVE-LOCK NO-ERROR.
        
        IF NOT AVAILABLE TRAN-COPAR THEN
        DO:
           /* get multilingual message for Memo not found */
            objCommonSrc:getMessages(INPUT  ipcLangID,
                                     INPUT  ConstantInitializer:c200MemoNtFound,                                                              
                                     OUTPUT cError,
                                     OUTPUT opiStatusCode).
                                          
            IF cError NE "":U THEN 
              UNDO,THROW NEW AppError(cError,1).
        END. /* IF NOT AVAILABLE TRAN-COPAR THEN  */
     
        ASSIGN 
          TRAN-COPAR.CUS-NO-TRAN = TRAN-COPAR.CUS-NO-TRAN + 1.
     
         /* RECORD FOR THE CUSTOMER MASTER FILE */
        ASSIGN CCSMS.CREDIT-AMT = CCSMS.CREDIT-AMT - PAGO-WORK.
     
         /* RECORD FOR THE DEBIT MEMO */
        ASSIGN 
           TRAN-COPAR.INV-DR-TOT   = TRAN-COPAR.INV-DR-TOT
                                   + PAGO-WORK.
     
         /* RECORD FOR THE DB/MEMO TRANSACTION */
         CREATE TRAN-COPTR.
         ASSIGN 
           TRAN-COPTR.CUST-NUMBER  = TRAN-COPAR.CUST-NUMBER
           TRAN-COPTR.CUS-CHG-NO   = TRAN-COPAR.CUS-CHG-NO
           TRAN-COPTR.TYPE-TRAN-AR = ORDER-NUMBER   
           TRAN-COPTR.TRAN-SEQ     = TRAN-COPAR.CUS-NO-TRAN
           TRAN-COPTR.CUS-INV-DATE = TRAN-COPAR.CUS-INV-DATE 
           TRAN-COPTR.SALES-REP-ID = TRAN-COPAR.SALES-REP-ID
           TRAN-COPTR.CUS-PAY-DATE = TRANS-DATE 
           TRAN-COPTR.INV-DR-TOT   = PAGO-WORK
           TRAN-COPTR.ORDER-NUMBER  = order-number
           TRAN-COPTR.ORDER-BALANCE = 0          
           TRAN-COPTR.CUS-ORDER-NO = "CR-ONACC" .
       END. /* IF AVAILABLE ccsms THEN */
         
    CATCH errorObj AS AppError:           
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    END CATCH.

  END METHOD.

  /*------------------------------------------------------------------------------
   Purpose:
   Notes:
  ------------------------------------------------------------------------------*/

  METHOD PUBLIC VOID PROC-UPDATE(INPUT PS-INV-NO      AS CHARACTER,
                                 INPUT PS-CUST-NUMBER AS CHARACTER,
                                 INPUT ORDER-NUMBER   AS CHARACTER,
                                 INPUT ipcLangId      AS CHARACTER,
                                 OUTPUT opcError      AS CHARACTER):
      
      DEFINE VARIABLE objCommonSrc AS CLASS CommonSource NO-UNDO.
      objCommonSrc = NEW commonSource(INPUT cToken).
      
      FIND COPAR WHERE COPAR.CUST-NUMBER EQ CCSMS.CUST-NUMBER
                   AND COPAR.CUS-CHG-NO  EQ PS-INV-NO EXCLUSIVE-LOCK NO-ERROR.
 
     IF PS-INV-NO EQ "ON/ACC" THEN 
     DO:
         FIND FIRST TT-PAYMENTS WHERE TT-PAYMENTS.p-ref = ORDER-NUMBER NO-LOCK NO-ERROR.
         NUMERO-FAC-ORD = lastinvoice#.
         
     END.    
    /*PAGOS O APLICACION DE ON-ACCOUNT */
      IF TT-PAYMENTS.P-TYPE = "ONACC" THEN
      DO:
         
        IF NOT AVAILABLE COPAR THEN
        DO:    
            objCommonSrc:getMessages(INPUT  ipcLangID,
                                     INPUT  ConstantInitializer:c200InvoiceNtFound,                                                              
                                     OUTPUT cError,
                                     OUTPUT opiStatusCode).
                                      
           IF cError NE "":U THEN 
             UNDO,THROW NEW AppError(cError,1).        
           NEXT.  // JKT discuss 
        END. /* IF NOT AVAILABLE COPAR THEN */
   
        THIS-OBJECT:PROC-APLICAR-ON-ACC(INPUT PS-INV-NO,
                                        INPUT PS-CUST-NUMBER,
                                        INPUT ORDER-NUMBER,
                                        INPUT ipcLangId,
                                        OUTPUT cError).
         
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).                               
          
        FIND FIRST coptr WHERE coptr.cust-number                 EQ CCSMS.CUST-NUMBER 
                           AND coptr.cus-chg-no                  EQ "ON/ACC":U 
                           AND SUBSTRING(COPTR.DESCRIPTION,1,11) EQ SP-ON-ACC-NUMBER EXCLUSIVE-LOCK NO-ERROR.
        IF NOT AVAILABLE coptr THEN
        DO:
          
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200OnAccPayNtFound, //JKT replace SP-ON-ACC-NUMBER with message                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
                              
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1). 
                                  
        END.
        
        ELSE
        DO:
           SUBSTRING(COPTR.DESCRIPTION,16) = STRING(DECIMAL(SUBSTRING(COPTR.DESCRIPTION,16)) - pago-work,"->>,>>>,>>>.99").
        END.
        
        NEXT. 
      END. /*  IF TT-PAYMENTS.P-TYPE = "ONACC" THEN */
   
      /*PAGOS O APLICACION DE ON-ACCOUNT */
      IF TT-PAYMENTS.P-TYPE = "CREDIT" THEN
      DO:
        IF NOT AVAILABLE COPAR THEN
        DO: 
           
          objCommonSrc:getMessages(INPUT  ipcLangID,
                                   INPUT  ConstantInitializer:c200InvoiceNtFound,                                                              
                                   OUTPUT cError,
                                   OUTPUT opiStatusCode).
                                      
          IF cError NE "":U THEN 
            UNDO,THROW NEW AppError(cError,1).
                      
          NEXT. // JKT discuss next
        END.
   
        THIS-OBJECT:PROC-APLICAR-CREDIT(INPUT PS-INV-NO,
                                        INPUT PS-CUST-NUMBER,
                                        INPUT ipcLangID,
                                        OUTPUT cError).
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1).
        
        NEXT. 
      END. /* IF TT-PAYMENTS.P-TYPE = "CREDIT" THEN  */
   
         
      IF TT-PAYMENTS.P-TYPE = "ORDEN-PAGADA-CON-CREDITO" THEN
      DO:
        THIS-OBJECT:PROC-ORDEN-PAGADA-CON-CREDITO(INPUT PS-CUST-NUMBER,
                                                  INPUT ORDER-NUMBER,
                                                  OUTPUT cError,
                                                  INPUT ipcLangID). 
       
        IF cError NE "":U THEN
          UNDO,THROW NEW AppError(cError,1). 
      END. /* IF TT-PAYMENTS.P-TYPE = "ORDEN-PAGADA-CON-CREDITO"  */
   
      IF NOT AVAILABLE COPAR THEN
      DO:
        FIND COOHD WHERE COOHD.ORDER-NUMBER = ORDER-NUMBER NO-LOCK NO-ERROR.
        FIND COPAR WHERE COPAR.CUST-NUMBER  = CCSMS.CUST-NUMBER 
                     AND COPAR.CUS-CHG-NO   = "ON/ACC":U EXCLUSIVE-LOCK NO-ERROR.
                             
        IF NOT AVAILABLE COPAR THEN 
          CREATE COPAR.
        
        ASSIGN 
          COPAR.CUST-NUMBER  = CCSMS.CUST-NUMBER
          COPAR.CUS-CHG-NO   = "ON/ACC":U.
   
        IF AVAILABLE coohd THEN   
        ASSIGN 
          COPAR.INVEN-WHS-CD = COOHD.WAREHOUSE-NO
          COPAR.COMPANY-CODE = COOHD.COMPANY-CODE
          COPAR.SALES-REP-ID = COOHD.SALES-REP-ID
          COPAR.TERMS-CODE   = COOHD.CUS-TERMS-CD.
        
        ELSE 
          ASSIGN COPAR.INVEN-WHS-CD = POINT-STORE. 
   
      END. /* IF NOT AVAILABLE COPAR */
   
    
      FIND COOHD WHERE COOHD.ORDER-NUMBER = ORDER-NUMBER NO-LOCK NO-ERROR.
      IF AVAILABLE COOHD AND COPAR.CUS-CHG-NO = "ON/ACC":U THEN
      DO:
        ASSIGN COPAR.INVEN-WHS-CD = COOHD.WAREHOUSE-NO.
      END.
     
      ASSIGN INV-AMT =   COPAR.CUS-INV-NET  
                       - COPAR.CUS-PAYMENT 
                       - COPAR.PAY-DISC-AMT 
                       - COPAR.OTH-ALLOWANC 
                       + COPAR.INV-DR-TOT  
                       - COPAR.INV-CR-TOT.
     
     
      CREATE CCRIR.
      CCRIR.PAYMENT-DISC = Invoice-discount.
      IF COPAR.CUS-CHG-NO = "ON/ACC" THEN 
      DO:
        /* pago-work = entered amount 
           TT-PAYMENTS.p-change = entered amount - order total 
           for new orders,it assigns the payment from here.
        */
         
        ASSIGN CCRIR.CUS-PAYMENT = pago-work - TT-PAYMENTS.p-change.
      END.
        
      ELSE 
      DO:
         
         IF abs(pago-work) >= abs(INV-AMT) THEN
         DO:
           
           ASSIGN CCRIR.CUS-PAYMENT = INV-AMT.
           
         END.
         
         ELSE
         DO: 
           
           ASSIGN CCRIR.CUS-PAYMENT = pago-work.
           
         END.
      END. /* ELSE  */
   
      /* RECORD FOR THE INVOICE */
      ASSIGN 
        COPAR.CUS-NO-TRAN  = COPAR.CUS-NO-TRAN  + 1
        COPAR.CUS-PAYMENT  = COPAR.CUS-PAYMENT  + CCRIR.CUS-PAYMENT  
        COPAR.PAY-DISC-AMT = COPAR.PAY-DISC-AMT + CCRIR.PAYMENT-DISC 
        COPAR.OTH-ALLOWANC = COPAR.OTH-ALLOWANC + CCRIR.OTH-ALLOWANC 
        COPAR.CUS-PAY-DATE = PAY-DATE.
     
      
      /* RECORD FOR THE TRANSACTION */
      CREATE COPTR. 
      ASSIGN
        COPTR.CUST-NUMBER  = COPAR.CUST-NUMBER
        COPTR.CUS-CHG-NO    = COPAR.CUS-CHG-NO
        COPTR.CUS-INV-DATE  = COPAR.CUS-INV-DATE
        COPTR.CUS-PAYMENT   = CCRIR.CUS-PAYMENT
        COPTR.CUS-PAY-DATE  = PAY-DATE
        COPTR.PAY-DISC-AMT  = CCRIR.PAYMENT-DISC
        COPTR.OTH-ALLOWANC  = CCRIR.OTH-ALLOWANC
        COPTR.CUS-ORDER-NO  = TT-PAYMENTS.p-ref
        COPTR.SALES-REP-ID  = COPAR.SALES-REP-ID 
        COPTR.TERMINAL-ID   = TT-PAYMENTS.p-type + TERMINAL-ID
        COPTR.ORDER-NUMBER  = NUMERO-FAC-ORD  //order-number
        COPTR.ORDER-BALANCE = CCRIR.CUS-PAYMENT           
        SUBSTRING(coptr.DESCRIPTION,1,11) = NUMERO-FAC-ORD 
        SUBSTRING(coptr.DESCRIPTION,16)   = STRING(CCRIR.CUS-PAYMENT,"->>,>>>,>>>.99").    
  
      
      
      IF MB-FIN AND LOAN-ORDER-PMT <> 0 THEN 
      DO:
        IF LOAN-ORDER-PMT-TYPE = "COD" THEN 
          SUBSTRING(coptr.DESCRIPTION,12,3) = "COD".
        
        ELSE 
          SUBSTRING(coptr.DESCRIPTION,12,3) = "PRO".
             
      END. /* IF MB-FIN AND LOAN-ORDER-PMT <> 0 THEN   */
     
      IF MB-FIN AND PS-INV-NO = "ON/ACC" AND CCSMS.CUST-TYPE = "COBROS"  THEN
      DO:
           COPTR.CUS-ORDER-NO = TT-PAYMENTS.p-cobros. 
      END. /* IF MB-FIN AND PS-INV-NO = "ON/ACC" AND CCSMS.CUST-TYPE = "COBROS" */
      
      ELSE
      IF botones-data THEN
      DO:
          COPTR.CUS-ORDER-NO = TT-PAYMENTS.p-D-REF4.
         // MESSAGE 'assign cheque no ' COPTR.CUS-ORDER-NO. 
          
          IF LENGTH(TT-PAYMENTS.p-D-REF5) > 3 
              THEN COPTR.CUS-ORDER-NO = COPTR.CUS-ORDER-NO + "," + TT-PAYMENTS.p-D-REF5.
          IF LENGTH(TT-PAYMENTS.p-D-REF6) > 3 
              THEN COPTR.CUS-ORDER-NO = COPTR.CUS-ORDER-NO + "," + TT-PAYMENTS.p-D-REF6.
          IF LENGTH(TT-PAYMENTS.p-D-REF7) > 3 
              THEN COPTR.CUS-ORDER-NO = COPTR.CUS-ORDER-NO + "," + TT-PAYMENTS.p-D-REF7.
      END. /* IF botones-data  */
   
    
      IF      TT-PAYMENTS.P-TYPE = "1" THEN COPTR.TYPE-TRAN-AR   = "CA$H". 
      ELSE IF TT-PAYMENTS.P-TYPE = "2" THEN COPTR.TYPE-TRAN-AR   = "CHK ". 
      ELSE IF TT-PAYMENTS.P-TYPE = "3" THEN COPTR.TYPE-TRAN-AR   = "CHK3". 
      ELSE IF TT-PAYMENTS.P-TYPE = "4" THEN COPTR.TYPE-TRAN-AR   = "VISA". 
      ELSE IF TT-PAYMENTS.P-TYPE = "5" THEN COPTR.TYPE-TRAN-AR   = "AMEX". 
      ELSE IF TT-PAYMENTS.P-TYPE = "6" THEN COPTR.TYPE-TRAN-AR   = "ATH ". 
      ELSE IF TT-PAYMENTS.P-TYPE = "7" THEN COPTR.TYPE-TRAN-AR   = "OTH1". 
      ELSE IF TT-PAYMENTS.P-TYPE = "8" THEN COPTR.TYPE-TRAN-AR   = "OTH2". 
      ELSE IF TT-PAYMENTS.P-TYPE = "9" THEN COPTR.TYPE-TRAN-AR   = "OTH3".
      ELSE IF TT-PAYMENTS.P-TYPE = "10" THEN COPTR.TYPE-TRAN-AR  = "INVOICE".
      ELSE IF TT-PAYMENTS.P-TYPE = "11" THEN COPTR.TYPE-TRAN-AR  = "CHK". // COPTR.TYPE-TRAN-AR  = "ONLINE".  //As per Wanda, if payment type is Online then set Type-TRAN-AP = CHK
      ELSE                                   COPTR.TYPE-TRAN-AR  = "OTHX". 
        
      IF COPAR.CUS-CHG-NO = "ON/ACC":U THEN 
      DO:
         ASSIGN
           temp-log = FALSE 
           temp-int = 0.
           
         DO WHILE NOT temp-log.
            temp-int  = temp-int + 1.
            FIND FIRST B-COPTR WHERE B-COPTR.CUST-NUMBER   = copar.cust-number 
                                 AND B-COPTR.CUS-CHG-NO    = "ON/ACC" 
                                 AND B-COPTR.TYPE-TRAN-AR  = COPTR.TYPE-TRAN-AR + STRING(temp-int,"99999") NO-LOCK NO-ERROR.
              
            IF NOT AVAILABLE B-COPTR THEN 
              ASSIGN temp-log = YES.
         END. /* DO WHILE NOT temp-log. */
   
         ASSIGN COPTR.TYPE-TRAN-AR = COPTR.TYPE-TRAN-AR + STRING(temp-int,"99999"). 
   
      END. /* IF COPAR.CUS-CHG-NO = "ON/ACC":U THEN  */
      
      ELSE  
        ASSIGN COPTR.TYPE-TRAN-AR = COPTR.TYPE-TRAN-AR + STRING(COPAR.CUS-NO-TRAN,"99999").   
     
      /* RECORD FOR CASH RECEIPT JOURNAL */
      ASSIGN
        CCRIR.CUST-NUMBER  = CCSMS.CUST-NUMBER
        CCRIR.CUST-NAME    = CCSMS.CUST-NAME
        CCRIR.PAYMENT-TYPE = TT-PAYMENTS.p-type 
        CCRIR.CUS-CHG-NO   = IF COPAR.CUS-CHG-NO = "ON/ACC" THEN "ON/ACC" ELSE NUMERO-FAC-ORD
        CCRIR.INV-OLD-BAL  = INV-AMT
        CCRIR.TERMINAL-ID  = TERMINAL-ID
        CCRIR.INV-NEW-BAL  = INV-AMT - COPTR.CUS-PAYMENT
                                     - COPTR.OTH-ALLOWANC - COPTR.PAY-DISC-AMT
        CCRIR.CHECK-NUMBER = TT-PAYMENTS.p-ref  
        CCRIR.TYPE-TRAN-NO = COPTR.TYPE-TRAN-AR 
        CCRIR.CUS-PAY-DATE = PAY-DATE
        CCRIR.SALES-REP-ID = COPTR.SALES-REP-ID
        CCRIR.CASHIER-CD   = STRING(COPAR.INVEN-WHS-CD)   
        CCRIR.COMPANY-CODE = COPAR.COMPANY-CODE
        CCRIR.RECEIPT-NUM  = INTEGER(SUBSTRING(R-NUMBER,2,5)) 
        coptr.WITHhold-%   = DECIMAL(copar.inven-whs-cd).
        
        IF POINT-STORE <> 0 THEN
          CCRIR.CASHIER-CD = STRING(POINT-STORE). 
     
        IF MB-FIN AND LOAN-ORDER-PMT <> 0 THEN 
        DO:
          IF LOAN-ORDER-PMT-TYPE = "COD" THEN 
            SUBSTRING(CCRIR.CUST-NAME,31,18)  = "LOAN-ORDER-PMT-COD":U. 
          
          ELSE 
            SUBSTRING(CCRIR.CUST-NAME,31,14)  = "LOAN-ORDER-PMT":U.
             
        END. /* IF MB-FIN AND LOAN-ORDER-PMT <> 0  */
     
        IF MB-FIN AND LOAN-PMT <> 0 THEN SUBSTRING(CCRIR.CUST-NAME,31,8)  = "LOAN-PMT":U.                        
        
        IF botones-data THEN 
        DO:
          ASSIGN CCRIR.CHECK-NUMBER = TT-PAYMENTS.p-D-REF4.
          
          IF LENGTH(TT-PAYMENTS.p-D-REF5) > 3 THEN
            CCRIR.CHECK-NUMBER = CCRIR.CHECK-NUMBER + "," + TT-PAYMENTS.p-D-REF5.
          IF LENGTH(TT-PAYMENTS.p-D-REF6) > 3 THEN 
            CCRIR.CHECK-NUMBER = CCRIR.CHECK-NUMBER + "," + TT-PAYMENTS.p-D-REF6.
          IF LENGTH(TT-PAYMENTS.p-D-REF7) > 3 THEN 
            CCRIR.CHECK-NUMBER = CCRIR.CHECK-NUMBER + "," + TT-PAYMENTS.p-D-REF7.
         
       //  MESSAGE ' CCRIR.CHECK-NUMBER New ' CCRIR.CHECK-NUMBER.
            
        END. /* IF botones-data THEN  */
                     
        IF order-number <> "" AND ps-inv-no = "" THEN
          ASSIGN CCRIR.TYPE-TRAN-NO = "DEPO" + STRING(COPAR.CUS-NO-TRAN,"9999"). 
     
     
        ASSIGN PAID-AMT =  COPTR.CUS-PAYMENT + COPTR.OTH-ALLOWANC + COPTR.PAY-DISC-AMT.
     
        FIND CCSMS WHERE CCSMS.CUST-NUMBER = PS-CUST-NUMBER EXCLUSIVE-LOCK NO-ERROR.
        IF AVAILABLE CCSMS THEN 
        DO:
          IF  COPAR.CUS-CHG-NO = "ON/ACC" THEN 
            ASSIGN CCSMS.ON-ACCOUNT = CCSMS.ON-ACCOUNT + COPTR.CUS-PAYMENT.
          
          ELSE 
            IF  PS-INV-NO BEGINS cCompany + "C" THEN 
              ASSIGN CCSMS.CREDIT-AMT  = CCSMS.CREDIT-AMT + PAID-AMT.
            
            ELSE 
              ASSIGN CCSMS.OPEN-INVOICE = CCSMS.OPEN-INVOICE - PAID-AMT.
       
          ASSIGN 
            CCSMS.YTD-PAYMENTS = CCSMS.YTD-PAYMENTS + PAID-AMT
            CCSMS.LAST-PAY-DT  = PAY-DATE.
          
          IF  NOT pago-multiple AND TT-PAYMENTS.P-CHANGE  <> 0 THEN 
            THIS-OBJECT:proc-change().
       
          IF layaway THEN
          DO: 
            ASSIGN ccsms.on-order-amt = ccsms.on-order-amt - COPTR.CUS-PAYMENT.
            
            IF ccsms.on-order-amt < 0  THEN 
              ccsms.on-order-amt = 0.
          END.  
        END. /* IF AVAILABLE CCSMS THEN   */        
        
        /* MARK SERVICE JOB AS CLOSED                           */
        
        THIS-OBJECT:CLOSE-SERVICE-JOB().

        IF TT-PAYMENTS.P-TYPE = "ORDEN-PAGADA-CON-CREDITO" THEN 
        DO:
           DELETE CCRIR.
        END.
        
    CATCH errorObj AS AppError:           
      
      ASSIGN 
        opcError = errorObj:GetMessage(1).
    
    END CATCH.
    
  END METHOD.  
  
  
   

END CLASS.