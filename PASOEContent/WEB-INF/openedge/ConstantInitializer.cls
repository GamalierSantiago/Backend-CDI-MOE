
 /*---------------------------------------------------------------------------------
    File        : ConstantInitializer
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : JKTECH
    Created     : Wed Nov 22 14:45:25 IST 2017
    Notes       : Version 1.1
    History     :
    --------------------------------------------------------------------------------
    Date(MM-DD-YY)        Author            Initial(XX-Version)      Description
                                                   
    --------------------------------------------------------------------------------     
  ----------------------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ConstantInitializer: 
 /*------------------------------------------------------------------------------------
   Purpose: This class contains various constants used in the application and their 
            initialized values            
   Notes: 
  ---------------------------------------------------------------------------------------*/
  
DEFINE PUBLIC STATIC PROPERTY c200UserBlank               AS CHARACTER INITIAL "200_user_blank":U                      NO-UNDO GET.     
DEFINE PUBLIC STATIC PROPERTY c200PswdBlank               AS CHARACTER INITIAL "200_pswd_blank":U                      NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200UserPswdBlank           AS CHARACTER INITIAL "200_user_pswd_blank":U                 NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c403InvalidToken            AS CHARACTER INITIAL "403_invalid_token":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200SessionExpired          AS CHARACTER INITIAL "200_session_expired":U                 NO-UNDO GET.    
DEFINE PUBLIC STATIC PROPERTY c200InvalidLang             AS CHARACTER INITIAL "200_invalid_lang":U                    NO-UNDO GET.    
DEFINE PUBLIC STATIC PROPERTY c200InvalidCmpny            AS CHARACTER INITIAL "200_invalid_cmpny":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidCustomer         AS CHARACTER INITIAL "200_invalid_customer":U                NO-UNDO GET.   
DEFINE PUBLIC STATIC PROPERTY c200SortbyBlank             AS CHARACTER INITIAL "200_sortby_blank":U                    NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200ReportTypeBlank         AS CHARACTER INITIAL "200_reporttype_blank":U                NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidOrder            AS CHARACTER INITIAL "200_invalid_order":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200LongLatBlank            AS CHARACTER INITIAL "200_longLat_blank":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200CustBlank               AS CHARACTER INITIAL "200_cust_blank":U                      NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200OrderBlank              AS CHARACTER INITIAL "200_order_blank":U                     NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200DeviceidBlank           AS CHARACTER INITIAL "200_deviceid_blank":U                  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200TokenRenew              AS CHARACTER INITIAL "200_token_renew":U                     NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidUserType         AS CHARACTER INITIAL "200_invalid_usertype":U                NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200MobMultiLogin           AS CHARACTER INITIAL "200_mob_multilogin":U                  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvoicesNtFound         AS CHARACTER INITIAL "200_no_invoices":U                     NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c403MisMatchUserTypeToken   AS CHARACTER INITIAL "403_mismatch_usertype_token":U         NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c403MisMatchDeviceIdToken   AS CHARACTER INITIAL "403_mismatch_deviceid_token":U         NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c403MisMatchUserToken       AS CHARACTER INITIAL "403_mismatch_user_token":U             NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c403MisMatchLangToken       AS CHARACTER INITIAL "403_mismatch_lang_token":U             NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200LangBlank               AS CHARACTER INITIAL "200_lang_blank":U                      NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200CmpnyBlank              AS CHARACTER INITIAL "200_cmpny_blank":U                     NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidUser             AS CHARACTER INITIAL "200_invalid_user":U                    NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidPaswd            AS CHARACTER INITIAL "200_invalid_paswd":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidUserPaswd        AS CHARACTER INITIAL "200_invalid_user_paswd":U              NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200UserTypeBlank           AS CHARACTER INITIAL "200_usertype_blank":U                  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidDateTime         AS CHARACTER INITIAL "200_invalid_datetime":U                NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidSortby           AS CHARACTER INITIAL "200_invalid_sortby":U                  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200CheckinTimeStampBlank   AS CHARACTER INITIAL "200_checkinTimestamp_blank":U          NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200CatBlank                AS CHARACTER INITIAL "200_cat_blank":U                       NO-UNDO GET.    
DEFINE PUBLIC STATIC PROPERTY c200InvalidCategory         AS CHARACTER INITIAL "200_invalid_category":U                NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidTimeStamp        AS CHARACTER INITIAL "200_invalid_timestamp":U               NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200NoProductFound          AS CHARACTER INITIAL "200_no_product_found":U                NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c500UnknownError            AS CHARACTER INITIAL "500_unknown_error":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200EmptyCart               AS CHARACTER INITIAL "200_empty_cart":U                      NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200CartAlreadySync         AS CHARACTER INITIAL "200_cart_already_sync":U               NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200BlankCartOperation      AS CHARACTER INITIAL "200_blank_cart_operation":U            NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidCartOperation    AS CHARACTER INITIAL "200_invalid_cart_operation":U          NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200ProductNotOnContract    AS CHARACTER INITIAL "200_product_not_on_contract":U         NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200ProductNotOnContractShpTo AS CHARACTER INITIAL "200_product_not_on_contract_shpTo":U NO-UNDO GET.

DEFINE PUBLIC STATIC PROPERTY c200OnlineAmountExceed      AS CHARACTER INITIAL "200_online_amount_exceed":U            NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200NoOpenOrderFound        AS CHARACTER INITIAL "200_No_Open_Order_Found":U             NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200LessPayAmount           AS CHARACTER INITIAL "200_less_pay_amount":U                 NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvoiceAmountExceed     AS CHARACTER INITIAL "200_invoice_amount_exceed":U           NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidPaymentMethod    AS CHARACTER INITIAL "200_invalid_payment_method":U          NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200ChequeNumCannotBlank    AS CHARACTER INITIAL "200_cheque_num_cannot_blank":U         NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200OrderNumCannotBlank     AS CHARACTER INITIAL "200_order_num_cannot_blank":U          NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidOrderNum         AS CHARACTER INITIAL "200_invalid_order_num":U               NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200MemoNtFound             AS CHARACTER INITIAL "200_memo_not_found"                    NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvoiceNtFound          AS CHARACTER INITIAL "200_invoice_not_found"                 NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200OnAccPayNtFound         AS CHARACTER INITIAL "200_on_acc_pay_ntfound"                NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200VerifyEntry             AS CHARACTER INITIAL "200_verify_entry"                      NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200OrderNtAvail            AS CHARACTER INITIAL "200_order_not_available"               NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200CashbackGreaterInvoice  AS CHARACTER INITIAL "200_cashback_cntbe_greater_invoice":U  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200CashbackGreaterAmtPaid  AS CHARACTER INITIAL "200_cashback_cntbe_greater_amtpaid":U  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidRowID            AS CHARACTER INITIAL "200_invalid_rowid":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200NoMoreItemRecords       AS CHARACTER INITIAL "200_no_more_records":U                 NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200NoOrderHistory          AS CHARACTER INITIAL "200_no_order_history":U                NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200PONumberBlank           AS CHARACTER INITIAL "200_po_number_blank":U                 NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200SigneeNameBlank         AS CHARACTER INITIAL "200_signee_name_blank":U               NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200OrderDateTimeBlank      AS CHARACTER INITIAL "200_order_date_time_blank":U           NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200ItemForInvoice          AS CHARACTER INITIAL "200_item_fr_invoice":U                 NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200NotFound                AS CHARACTER INITIAL "200_not_found":U                       NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200AmtLessEQZero           AS CHARACTER INITIAL "200_pay_amt_lessEqual_zero":U          NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200AlrdyChckIn             AS CHARACTER INITIAL "200_already_checkin":U                 NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200ChckInFirst             AS CHARACTER INITIAL "200_checkin":U                         NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidShipNum          AS CHARACTER INITIAL "200_invalid_ship_num":U                NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200BlankShipNum            AS CHARACTER INITIAL "200_blank_ship_num":U                  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200CheckoutTimeStampBlank  AS CHARACTER INITIAL "200_blank_checkout_time":U             NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200BlankMode               AS CHARACTER INITIAL "200_blank_mode":U                      NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidMode             AS CHARACTER INITIAL "200_invalid_mode":U                    NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200ErrorOccured            AS CHARACTER INITIAL "200_error_occur":U                     NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200NoLiveTrackingRec       AS CHARACTER INITIAL "200_no_live_tracking_rec":U            NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200InvalidReportType       AS CHARACTER INITIAL "200_invalid_report_type":U             NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY c200MaxOrderQty             AS CHARACTER INITIAL "200_max_order_qty":U                   NO-UNDO GET.

DEFINE PUBLIC STATIC PROPERTY cMobileUser               AS CHARACTER INITIAL "mobileuser":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cNoOfDays                 AS CHARACTER INITIAL "SALE-HISTORY-DAYS":U            NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cWebUser                  AS CHARACTER INITIAL "Webuser":U                      NO-UNDO GET.    
DEFINE PUBLIC STATIC PROPERTY cSuccess                  AS CHARACTER INITIAL "Success":U                      NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cAllRecords               AS CHARACTER INITIAL "*":U                            NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cA-Z                      AS CHARACTER INITIAL "A-Z":U                          NO-UNDO GET. 
DEFINE PUBLIC STATIC PROPERTY cNearMe                   AS CHARACTER INITIAL "nearme":U                       NO-UNDO GET. 
DEFINE PUBLIC STATIC PROPERTY cRecentVisit              AS CHARACTER INITIAL "recentvisit":U                  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cdePercentCkHold          AS CHARACTER INITIAL "dePercentCkHold":U              NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cCCSMSFileName            AS CHARACTER INITIAL "CCSMS":U                        NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cOpenInvoice              AS CHARACTER INITIAL "OPEN-INVOICE":U                 NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cOnAcc                    AS CHARACTER INITIAL "ON/ACC":U                       NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cPutOnHold                AS CHARACTER INITIAL "PUT-ON-HOLD":U                  NO-UNDO GET. 
DEFINE PUBLIC STATIC PROPERTY cDateRange                AS CHARACTER INITIAL "DATE-RANGE":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cImageDir                 AS CHARACTER INITIAL "static/images":U                       NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cPDFDir                   AS CHARACTER INITIAL "static/PDF":U                   NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cSalesmanPicDir           AS CHARACTER INITIAL "users_images/salesperson_images":U NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cCustomerPicDir           AS CHARACTER INITIAL "users_images/customer_images":U    NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cIncludeAllDue            AS CHARACTER INITIAL "include-all-DUE":U                  NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY cSessionTimeOut           AS CHARACTER INITIAL "SESSION-TIMEOUT"                    NO-UNDO GET.
DEFINE PUBLIC STATIC PROPERTY iTokenTimeout             AS INTEGER   INITIAL 1800                                 NO-UNDO GET.
 
//DEFINE PUBLIC STATIC PROPERTY cHTTPstatusCode           AS INTEGER   INITIAL 200                              NO-UNDO GET.            

DEFINE PUBLIC STATIC PROPERTY deParamFlValue            AS DECIMAL INITIAL    0.25                            NO-UNDO GET.      

DEFINE PUBLIC STATIC PROPERTY c200InvalidCheck          AS CHARACTER NO-UNDO
    GET.
    
    PRIVATE SET(INPUT lc200InvalidLang AS CHARACTER):
      ASSIGN 
        c200InvalidCheck = lc200InvalidLang.    
    END SET.     

  CONSTRUCTOR PUBLIC ConstantInitializer ():
  
  END CONSTRUCTOR.
  DEFINE PUBLIC  VARIABLE cToken      AS CHARACTER NO-UNDO.
  
  CONSTRUCTOR PUBLIC ConstantInitializer (INPUT ipcToken AS CHARACTER):
    ASSIGN cToken =  ipcToken.
    
  END CONSTRUCTOR.

END CLASS.


