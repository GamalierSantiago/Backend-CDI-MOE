
/*------------------------------------------------------------------------
    File        : sharedVariables.p
    Purpose     : It defines the shared variables which are used in trigger files 

    Syntax      :

    Description : 

    Author(s)   : JKTECH 
    Created     : Mon May 28 04:25:40 BOT 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* ********************  Preprocessor Definitions  ******************** */    

//&IF DEFINED(sharedVariable) = 0 &THEN
  //  &GLOBAL-DEFINE sharedVariable "Defined" 
    DEFINE NEW GLOBAL SHARED VARIABLE PROG-NAME   AS CHARACTER.
    DEFINE NEW GLOBAL SHARED VARIABLE TERMINAL-ID AS CHARACTER FORMAT "x(15)" NO-UNDO.    
    DEFINE NEW GLOBAL SHARED VARIABLE cliente-no  LIKE ccsms.cust-number      NO-UNDO.    
    DEF NEW GLOBAL SHARED VARIABLE CLIENTE-NO LIKE CCSMS.CUST-NUMBER NO-UNDO. 
    DEF NEW GLOBAL SHARED VARIABLE lStatRes        AS LOGICAL NO-UNDO. /* JKT1 */
    DEF NEW GLOBAL SHARED VARIABLE glloFullScreen  AS LOGICAL NO-UNDO. /* JKT3 */
    DEF NEW GLOBAL SHARED VARIABLE glintSminqCount AS INTEGER NO-UNDO. /* JKT3 */
    ASSIGN lStatRes       = FALSE /* JKT1 */ 
           glloFullScreen  = NO
           glintSminqCount = 0.  /* JKT3 */
    
    
    
    DEFINE NEW GLOBAL SHARED VARIABLE COMP-NAME      AS CHARACTER FORMAT "X(50)".
    DEFINE NEW GLOBAL SHARED VARIABLE PERIOD         AS INTEGER   FORMAT "99".
    DEFINE NEW GLOBAL SHARED VARIABLE ACTUAL-MENU    AS CHARACTER FORMAT "X(8)"  NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE NEXT-MENU      AS CHARACTER FORMAT "X(8)"  NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE LINE-PRINTER   AS CHARACTER FORMAT "X(50)" NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE COMPANY        AS CHARACTER FORMAT "X".
    DEFINE NEW GLOBAL SHARED VARIABLE PROG-NAME      AS CHARACTER.
    DEFINE NEW GLOBAL SHARED VARIABLE PERIOD-DATE    AS DATE.
    DEFINE NEW GLOBAL SHARED VARIABLE LPRINTER-TYPE  AS CHARACTER FORMAT "X(15)".
    DEFINE NEW GLOBAL SHARED VARIABLE TERM-TYPE      AS CHARACTER FORMAT "X(15)".
    DEFINE NEW GLOBAL SHARED VARIABLE STORE-NUMBER   AS INTEGER   FORMAT "99".
    DEFINE NEW GLOBAL SHARED VARIABLE STORE-SNAME    AS CHARACTER FORMAT "X(50)".
    DEFINE NEW GLOBAL SHARED VARIABLE ACTUAL-FI-YR   AS INTEGER   FORMAT ">9999".
    DEFINE NEW GLOBAL SHARED VARIABLE PRINTER-NO     LIKE PRNTR.PRINTER-NO.
    DEFINE NEW GLOBAL SHARED VARIABLE PRINTER-LOC    LIKE PRNTR.PRINTER-LOC.
    DEFINE NEW GLOBAL SHARED VARIABLE JOSUA          AS INTEGER   FORMAT "9999"  NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE TERMINAL-ID    AS CHARACTER FORMAT "X(15)" NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE WAREHOUSE-USER AS INTEGER   FORMAT "99".
     
    DEFINE NEW GLOBAL SHARED VARIABLE excel          AS LOGICAL             NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE word           AS LOGICAL             NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE CDI-VER        AS CHAR FORMAT "X(20)" NO-UNDO.
    /***** 05/23/01 START WAM ***********************************/
    DEFINE NEW GLOBAL SHARED VARIABLE CAPTURE-TERM-ID AS CHARACTER FORMAT "X(30)" NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE UNIX-TTY-ID     AS CHARACTER FORMAT "X(15)" NO-UNDO.
    /***** 05/23/01  END  WAM ***********************************/
     
    DEFINE NEW GLOBAL SHARED VARIABLE USERCODE AS CHAR FORMAT "X(8)" NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE USERPASS AS CHAR FORMAT "X(14)" NO-UNDO.
     
    DEF NEW GLOBAL SHARED VAR ORIG-WIN-WIDTH  AS DECIMAL NO-UNDO.
    DEF NEW GLOBAL SHARED VAR ORIG-WIN-HEIGHT AS DECIMAL NO-UNDO.
     
                        /* 05/05/14 LAGS - para uso de logica de copias a imprimir */
    DEFINE NEW GLOBAL SHARED VARIABLE nCopies        AS INTEGER NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE dmCopies       AS INTEGER NO-UNDO.
    DEFINE NEW GLOBAL SHARED VARIABLE sw_ok-printer  AS LOGICAL NO-UNDO.
                        /* 05/05/14 LAGS - para uso de logica de copias a imprimir */
    
    def new global shared variable iQTY1 as integer initial 1.
     def new global shared variable sminqhandle as handle no-undo.
     iQty1 = 1. 
     
     DEFINE NEW GLOBAL SHARED VARIABLE w-botones AS HANDLE NO-UNDO.
     
    DEFINE NEW GLOBAL  SHARED TEMP-TABLE data-entry
         FIELD field-name AS CHAR
         FIELD field-value AS CHAR
         FIELD field-type AS CHAR
         FIELD prog-name  AS CHAR
         FIELD FRAME-context AS CHAR
         FIELD FRAME-field-FILE AS CHAR
            INDEX  data-entry-idx IS UNIQUE PRIMARY 
              field-name ASCENDING.
    DEFINE NEW GLOBAL SHARED VAR w-win AS HANDLE NO-UNDO.
    
       
//&ENDIF  

 

/* ***************************  Main Block  *************************** */
