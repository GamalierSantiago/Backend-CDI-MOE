/*---------------------------------------------------------------------------------
   File        : Discount
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : NM
   Created     : Jan 02 2020
   Notes       : Version 1.0
   History     :
  --------------------------------------------------------------------------------
  Date(MM-DD-YY)        Author            Initial(XX-Version)      Description
                                                   
  --------------------------------------------------------------------------------     
 ----------------------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Discount: 
    
  /*-----------------------------------------------------------------------------------
   Purpose: This program will have business logic related to all the discounts 
           
   Notes:
  -------------------------------------------------------------------------------------*/
    
  CONSTRUCTOR PUBLIC Discount ():
    
                
                                                                                         
  END CONSTRUCTOR.
  
  /*----------------------------------------------------------------------------------------------------
  Purpose: This method provides the functionality of applying the discount on selected invoice.
  
  Input-Parameter: 1. Customer number
                   2. Invoice Number
                   3. Promo Code
                   
                                      
  Output Parameter: 1. Discount Percentage
                    2. Maximum Discount for invoice
                    3. Error if any         
  -----------------------------------------------------------------------------------------------------*/
  METHOD PUBLIC VOID DiscountOnInvoice(INPUT ipcCustNumber       AS CHARACTER,
                                       INPUT ipcinvoiceNumber    AS CHARACTER,
                                       INPUT ipcPromocode        AS CHARACTER,
                                       OUTPUT opcDiscountPercent AS CHARACTER,
                                       OUTPUT opcMaxDiscount     AS CHARACTER,
                                       OUTPUT opcError           AS CHARACTER):
                                       
      DEFINE VARIABLE llValidPromo      AS LOGICAL NO-UNDO.
      DEFINE VARIABLE ldDueDate         AS DATE    NO-UNDO.
      DEFINE VARIABLE liGraceDays       AS INTEGER   NO-UNDO INITIAL 0.
      
      FIND copar WHERE copar.cust-number  EQ ipcCustNumber
                   AND copar.cus-chg-no   EQ ipcinvoiceNumber NO-LOCK NO-ERROR.            
      IF AVAILABLE copar THEN
      DO:
         FIND TERMS WHERE TERMS.CUS-TERMS-CD EQ copar.TERMS-CODE NO-LOCK NO-ERROR.
         IF AVAILABLE Terms THEN
         DO:
            
            FIND FIRST PARAMFL WHERE PARAMFL.COMPANY-CODE EQ ipcCustNumber AND PARAMFL.PARAM-ID EQ "OVERRIDE-TERMS":U NO-LOCK NO-ERROR.
            IF AVAILABLE PARAMFL THEN
              ASSIGN liGraceDays = INTEGER (PARAMFL.PARAM-VALUE1) NO-ERROR. /*supply*/
              
            ASSIGN ldDueDate = COPAR.CUS-INV-DATE + TERMS.TERMS-DAYS + liGraceDays. /*supply*/
            
            llvalidPromo = CheckPromoCodeValidity(ipcCustNumber, ipcPromocode).
            IF llvalidPromo AND ldDueDate LE TODAY THEN
              ASSIGN opcDiscountPercent  = STRING(TERMS.TERMS-PERCEN / 100) /*supply*/ 
              /* max number of days, grace. percentage allowed */
                     opcMaxDiscount      = STRING(INTEGER(opcDiscountPercent) * (COPAR.GROSS-INVAMT - COPAR.CUS-DISC-AMT)).
            ELSE ASSIGN llvalidPromo = FALSE.          
         END.
         ELSE 
           ASSIGN llvalidPromo = FALSE. 
      END.
      ELSE
        ASSIGN llvalidPromo = FALSE. 
      
      
      IF NOT llvalidPromo THEN
         ASSIGN opcError = "Invalide Promo code":u
                opcDiscountPercent = "0"
                opcMaxDiscount = "0". 
      
                    
  END METHOD. /* DiscountOnInvoice */
  
  /*----------------------------------------------------------------------------------------------------
  Purpose: This method provides the functionality to find the validity of Promo code.
  
  Input-Parameter: 1.  Customer number
                   2. Promo Code
                                      
  Output Parameter: 1.  None                      
                        
  -----------------------------------------------------------------------------------------------------*/
  
  METHOD PUBLIC LOGICAL CheckPromoCodeValidity (INPUT ipcCustNumber AS CHARACTER,
                                                INPUT ipcPromoCode  AS CHARACTER):
                                                
/*      IF CAN-FIND(FIRST promo_master WHERE promo_master.cust_number EQ ipcCustNumber
                                       AND promo_master.promo_code EQ ipcPromoCode 
                                       AND promo_master.promo_startdate LE DATETIME(TODAY)
                                       AND promo_master.promo_enddate GE DATETIME(TODAY)  ) THEN 
        RETURN TRUE.
      ELSE 
        RETURN FALSE.
          */
  
  END METHOD.
    
END CLASS. /* Discount */
