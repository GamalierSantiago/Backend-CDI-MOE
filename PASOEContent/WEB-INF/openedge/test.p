
/*------------------------------------------------------------------------
    File        : test.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : jvelez
    Created     : Wed Aug 07 09:02:25 BOT 2024
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */

USING Progress.Lang.*.
USING Progress.Json.ObjectModel.*.

DEFINE VARIABLE cTable AS CHAR NO-UNDO.
DEFINE VARIABLE cInitialQuery AS CHAR NO-UNDO.
DEFINE VARIABLE hBuffer              AS HANDLE    NO-UNDO.
DEFINE VARIABLE hQuery               AS HANDLE    NO-UNDO.
DEFINE VARIABLE cQuery               AS CHARACTER NO-UNDO.
/*DEFINE VARIABLE charInputString      AS CHARACTER INITIAL "x":U NO-UNDO.*/
DEFINE VARIABLE charInputString      AS CHARACTER INITIAL "00088076151598":U NO-UNDO.
DEFINE VARIABLE ipcCompanyCode       AS CHARACTER INITIAL "F":U NO-UNDO.

ASSIGN
cTable = "CINV1":U
cInitialQuery = 'FOR EACH CINV1 WHERE (CINV1.HIDE-IN-WM-APPS NE "Y":U) AND (CINV1.LINE-UP NE "D":U AND CINV1.LINE-UP NE "W":U AND CINV1.LINE-UP NE "X":U )':U              
cQuery = cInitialQuery + ' AND CINV1.ITEM-NUMBER BEGINS "':U  + charInputString + '" No-LOCK':U NO-ERROR . 

CREATE BUFFER hBuffer FOR TABLE cTable.
CREATE QUERY hQuery.

hQuery:SET-BUFFERS(hBuffer).  

hQuery:QUERY-PREPARE(cQuery).  

hQuery:QUERY-OPEN().
hQuery:GET-NEXT().


IF hQuery:QUERY-OFF-END THEN DO:
    //IF VALID-HANDLE(hBuffer) THEN
        DELETE OBJECT hBuffer.
        DELETE OBJECT hQuery.
    MESSAGE "I have nothing"
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
        
    DEF VAR box-item-number AS CHAR NO-UNDO.
    DEF VAR boxes AS INTEGER NO-UNDO.
    DEF VAR box-lotnumber AS CHAR NO-UNDO.
    DEF VAR box-number AS CHAR NO-UNDO.
    DEF VAR BOX-prep-date AS DATE NO-UNDO.
    DEF VAR box-expire-date AS DATE NO-UNDO.
    DEF VAR box-pack-date AS DATE NO-UNDO.
    DEF VAR box-sellby-date AS DATE NO-UNDO.
    DEF VAR bar-code-scan AS CHAR NO-UNDO.
    DEF VAR poundsInBarCode AS DECIMAL NO-UNDO.

    RUN "P:\Cdipremium-Plus\WHITEMRD.p" (  INPUT charInputString,
                                           INPUT ipcCompanyCode,
                                           OUTPUT box-item-number,
                                           OUTPUT boxes,
                                           OUTPUT poundsInBarCode,
                                           OUTPUT box-lotnumber,
                                           OUTPUT box-prep-date,
                                           OUTPUT box-expire-date,
                                           OUTPUT box-pack-date,
                                           OUTPUT box-sellby-date,
                                           OUTPUT box-number,
                                           OUTPUT bar-code-scan).
                            
    IF box-item-number <> "" THEN DO:
        ASSIGN
            cQuery = cInitialQuery + ' AND CINV1.ITEM-NUMBER BEGINS "':U  + box-item-number + '" No-LOCK':U NO-ERROR . 
        
        CREATE BUFFER hBuffer FOR TABLE cTable.
        CREATE QUERY hQuery.
/*        DO ON ERROR UNDO, THROW:*/
            hQuery:SET-BUFFERS(hBuffer).  
        
            hQuery:QUERY-PREPARE(cQuery).  
        
            hQuery:QUERY-OPEN().
            hQuery:GET-NEXT().
             
             
            //IF NOT hQuery:QUERY-OFF-END THEN 
                MESSAGE "box-item-number value -> " box-item-number skip
                        "Multbar Found something -> " hBuffer:BUFFER-FIELD("item-number":U):BUFFER-VALUE
                VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
            
            
/*            CATCH errorObj AS AppError:                      */
/*                MESSAGE "catch block " errorObj:GetMessage(1)*/
/*                  VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.  */
/*            END CATCH.                                       */
        
        //END.
    END.
    ELSE 
        MESSAGE "Box-item-number is empty"
        VIEW-AS ALERT-BOX.
END.    
ELSE DO:
    MESSAGE "CINV1 -> " hBuffer:BUFFER-FIELD("item-number":U):BUFFER-VALUE
    VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
END.
