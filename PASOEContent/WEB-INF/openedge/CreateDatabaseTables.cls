 
 /*------------------------------------------------------------------------
    File        : CreateDatabaseTables
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : jvelez
    Created     : Tue Feb 20 14:01:43 BOT 2024
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS CreateDatabaseTables: 

    {OEHDDT.i} 
    
    METHOD PUBLIC VOID createOrdersInBackendTables(INPUT orderNumber AS CHAR):
        
        DEFINE VARIABLE ACTUAL-MENU AS CHAR NO-UNDO.
        DEFINE VARIABLE COMPANY AS CHAR NO-UNDO.  
        DEFINE VARIABLE PERIOD AS INTEGER NO-UNDO.
        DEFINE VARIABLE ACTUAL-FI-YR AS INTEGER NO-UNDO.
        DEFINE VARIABLE BEG-ERROR AS CHAR NO-UNDO.
        DEFINE VARIABLE END-ERROR AS CHAR NO-UNDO.
        DEFINE VARIABLE TRANS-DATE AS DATE NO-UNDO. 
        
        FIND FIRST CMPNY WHERE CMPNY.COMPANY-CODE = COMPANY NO-LOCK NO-ERROR.
        IF AVAIL CMPNY THEN DO:
            
            
            RUN oeinvup-new.p (orderNumber, "2", "No", "").    
            
        END.           
            
  
    END METHOD.

END CLASS.