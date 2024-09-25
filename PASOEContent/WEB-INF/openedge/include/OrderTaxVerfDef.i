
/*------------------------------------------------------------------------
    File        : OrderTaxVerfDef.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : 
    Created     : Mon Jan 15 13:58:16 IST 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

DEFINE VARIABLE error-msg-line-1    AS CHARACTER NO-UNDO.
DEFINE VARIABLE error-msg-line-2    AS CHARACTER NO-UNDO.
DEFINE VARIABLE IVU-SIEMPRE-SHPTO   AS LOGICAL   NO-UNDO.
DEFINE VARIABLE PUT-ON-HOLD         AS LOGICAL   NO-UNDO.
DEFINE VARIABLE sc2916-billing-date AS LOGICAL   NO-UNDO.
DEFINE VARIABLE start-new-law-date  AS DATE      NO-UNDO.
DEFINE VARIABLE from-invoice-date   AS DATE      NO-UNDO.
DEFINE VARIABLE warning-days        AS INTEGER   NO-UNDO.
DEFINE VARIABLE SHP-SC2916-EXP      AS DATE      NO-UNDO.

DEF VARIABLE ivu-exp-exe   AS DATE      NO-UNDO.
DEFINE VARIABLE ivu-code   AS CHARACTER NO-UNDO.
DEFINE VARIABLE SC2916-EXP AS DATE      NO-UNDO.
DEFINE VARIABLE TEMP-CHAR  AS CHARACTER NO-UNDO.
DEFINE VARIABLE SHP-CODE   AS CHARACTER NO-UNDO.
DEFINE VARIABLE SHP-EXP    AS DATE      NO-UNDO.

DEF VARIABLE i-company                       AS CHAR         NO-UNDO.
DEF VARIABLE i-cust-number                   AS CHAR         NO-UNDO.
DEF VARIABLE i-ship-to-no                    AS CHAR         NO-UNDO. 
DEF VARIABLE i-INVOICE-DATE                  AS DATE         NO-UNDO.
DEF VARIABLE i-trans-type                    AS CHAR         NO-UNDO.
DEF VARIABLE i-dsp-msg                       AS CHAR         NO-UNDO.
 
DEF VARIABLE io-CITY-TAX-EXEMPT      AS LOGICAL      NO-UNDO.
DEF VARIABLE io-state-TAX-EXEMPT     AS LOGICAL      NO-UNDO.
DEF VARIABLE fecha-exempt-vencio     AS LOGICAL      NO-UNDO. 
DEF VARIABLE IVU-HOLD-CODE           AS CHAR         NO-UNDO.
DEF VARIABLE TAX-RET-VAL             AS CHAR         NO-UNDO.