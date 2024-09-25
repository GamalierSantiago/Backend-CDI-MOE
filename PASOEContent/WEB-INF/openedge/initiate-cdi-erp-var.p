
/*------------------------------------------------------------------------
    File        : initiate-cdi-erp-var
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : nm01
    Created     : Sun Apr 11 08:34:40 BOT 2021
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* ********************  Preprocessor Definitions  ******************** */
DEFINE INPUT PARAMETER ipcCompany AS CHARACTER NO-UNDO.
DEFINE SHARED VARIABLE COMPANY        AS CHARACTER FORMAT "X".

/* ***************************  Main Block  *************************** */
COMPANY = ipcCompany.