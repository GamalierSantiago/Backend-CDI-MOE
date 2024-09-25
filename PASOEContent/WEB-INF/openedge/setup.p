
/*------------------------------------------------------------------------
    File        : setup.p
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : nm01
    Created     : Thu Mar 04 04:37:09 BOT 2021
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */


/* Setup the data for Top Purchase items */

/***********************************************************************/
    
//DEFINE TEMP-TABLE ttPurchaseItem LIKE  TopSellingItems. 

DEFINE VARIABLE ipcCompanyCode AS CHARACTER   NO-UNDO.
DEFINE buffer bfCsahf FOR CSAHF.
DEFINE VARIABLE iCount AS INTEGER     NO-UNDO.
ipcCompanyCode = "1". 

FOR EACH CCSMS WHERE CCSMS.cust-type = "WH" NO-LOCK:
  FOR EACH CSAHF WHERE CSAHF.CUST-NUMBER  EQ CCSMS.CUST-NUMBER 
                    AND CSAHF.INVOICE-DATE GE TODAY - 30
                       AND CSAHF.ITEM-NUMBER  BEGINS ipcCompanyCode NO-LOCK:
        
        IF CSAHF.ITEM-NUMBER BEGINS ipcCompanyCode + "*":U THEN NEXT.    
        
        IF NOT CAN-FIND (FIRST TopSellingItems WHERE TopSellingItems.item-number EQ CSAHF.ITEM-NUMBER) THEN
        DO:
          
          CREATE TopSellingItems.
          ASSIGN 
            topSellingItems.Item-number  = CSAHF.ITEM-NUMBER
            topSellingItems.cust-number  = CCSMS.CUST-NUMBER
            topSellingItems.Company-CODE = ipcCompanyCode
            topSellingItems.LAST_PURCHASED = Today.
            iCount                     = 0.
                                                                                               
                    
          /* Count how many times item got purchased */  
          FOR EACH bfCsahf FIELD(bfCsahf.item-number bfCsahf.COMPANY-CODE) 
                           WHERE bfCsahf.item-number  EQ CSAHF.ITEM-NUMBER
                             AND bfCsahf.COMPANY-CODE EQ ipcCompanyCode  NO-LOCK:         
                       
            ASSIGN iCount = iCount + 1.
              
          END. /* FOR EACH bfCsahf.. */
                 
          ASSIGN topSellingItems.count = iCount.           
                 
        END. /* IF NOT CAN-FIND (ttPurchaseItem ..) */ 
        
      END. /* FOR EACH CSAHF... */
                         
    END. /* FOR EACH CCSMS... */ 
/*********************************************************************************************/