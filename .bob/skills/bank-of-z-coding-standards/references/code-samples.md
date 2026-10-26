# Code Samples — Bank of Z Coding Standards

Real examples extracted from the analyzed codebase, showing both good patterns and anti-patterns to avoid.

---

## COBOL CICS — Good Examples

### ✅ CICS Program Header (from BNKMENU.cbl)

```cobol
       CBL CICS('SP,EDF')
      ******************************************************************
      *                                                                *
      *  Copyright IBM Corp. 2023                                      *
      *                                                                *
      ******************************************************************


      ******************************************************************
      * This is the BANK MENU (i.e. the first program initiated by the
      * BMS suite). It displays the map and allows the user to select
      * an option, validates the option number/letter and returns with
      * the appropriate transaction.
      *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BNKMENU.
       AUTHOR. Jon Collett.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *SOURCE-COMPUTER.   IBM-370 WITH DEBUGGING MODE.
        SOURCE-COMPUTER.  IBM-370.
       OBJECT-COMPUTER.  IBM-370.
```

### ✅ WS-CICS-WORK-AREA and Abend Variables (from CRECUST.cbl)

```cobol
       01 WS-CICS-WORK-AREA.
          05 WS-CICS-RESP               PIC S9(8) COMP.
          05 WS-CICS-RESP2              PIC S9(8) COMP.

       01 WS-ABEND-PGM                  PIC X(8)      VALUE 'ABNDPROC'.
       01 ABNDINFO-REC.
           COPY ABNDINFO.
```

### ✅ Switches and Flags (from BNKMENU.cbl)

```cobol
       01 SWITCHES.
           03 VALID-DATA-SW            PIC X VALUE 'Y'.
              88 VALID-DATA                VALUE 'Y'.

       01 FLAGS.
           03 SEND-FLAG                PIC X.
              88 SEND-ERASE              VALUE '1'.
              88 SEND-DATAONLY           VALUE '2'.
              88 SEND-DATAONLY-ALARM     VALUE '3'.
```

### ✅ WS-FAIL-INFO (from BNKMENU.cbl)

```cobol
       01 WS-FAIL-INFO.
          03 FILLER                    PIC X(9) VALUE 'BNKMENU  '.
          03 WS-CICS-FAIL-MSG          PIC X(70) VALUE ' '.
          03 FILLER                    PIC X(6)  VALUE ' RESP='.
          03 WS-CICS-RESP-DISP         PIC 9(10) VALUE 0.
          03 FILLER                    PIC X(7)  VALUE ' RESP2='.
          03 WS-CICS-RESP2-DISP        PIC 9(10) VALUE 0.
          03 FILLER                   PIC X(15) VALUE ' ABENDING TASK.'.
```

### ✅ CICS Command with RESP Checking (from BNKMENU.cbl)

```cobol
           EXEC CICS
              RECEIVE MAP('BNK1ME')
              MAPSET('BNK1MAI')
              INTO(BNK1MEI)
              RESP(WS-CICS-RESP)
              RESP2(WS-CICS-RESP2)
           END-EXEC.

           IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
              IF WS-CICS-RESP = DFHRESP(MAPFAIL)
                 MOVE LOW-VALUES TO BNK1MEO
                 ...
              ELSE
                 INITIALIZE ABNDINFO-REC
                 MOVE EIBRESP    TO ABND-RESPCODE
                 MOVE EIBRESP2   TO ABND-RESP2CODE
                 ...
              END-IF
           END-IF.
```

### ✅ Section Naming Pattern (from BNKMENU.cbl)

```cobol
       RECEIVE-MENU-MAP SECTION.
       RMM010.
      *
      *    Retrieve the data
      *
           EXEC CICS
              RECEIVE MAP('BNK1ME')
              ...

       RMM999.
           EXIT.


       EDIT-MENU-DATA SECTION.
       EMD010.
      *
      *    Perform validation on the incoming field
      *
           IF ACTIONI NOT = '1' AND ...
```

---

## COBOL IMS — Good Examples

### ✅ IMS Program Header (from IBGCUDAT.cbl)

```cobol
       CBL LIST,MAP,XREF,FLAG(I)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IBGCUDAT.

      ******************************************************************
      * Licensed Materials - Property of IBM
      *
      * (c) Copyright IBM Corp. 2026.
      *
      * US Government Users Restricted Rights - Use, duplication or
      * disclosure restricted by GSA ADP Schedule Contract
      * with IBM Corp.
      ******************************************************************
```

### ✅ IMS DL/I Declarations (from IBGCUDAT.cbl)

```cobol
      ******************************************************************
      *DATABASE CALL CODES
      ******************************************************************

       77  GU                  PIC  X(04)        VALUE "GU  ".
       77  GHU                 PIC  X(04)        VALUE "GHU ".
       77  GN                  PIC  X(04)        VALUE "GN  ".
       77  GHN                 PIC  X(04)        VALUE "GHN ".
       77  ISRT                PIC  X(04)        VALUE "ISRT".
       77  REPL                PIC  X(04)        VALUE "REPL".

      ******************************************************************
      *IMS STATUS CODES
      ******************************************************************

       77  GE                  PIC  X(02)        VALUE "GE".
       77  GB                  PIC  X(02)        VALUE "GB".

      ******************************************************************
      *ERROR STATUS CODE AREA
      ******************************************************************

       01  BAD-STATUS.
           05  SC-MSG  PIC X(30) VALUE "BAD STATUS CODE WAS RECEIVED: ".
           05  SC             PIC X(2).
```

### ✅ IMS Message Areas (from IBTRAN.cbl)

```cobol
      ******************************************************************
      *INPUT/OUTPUT MESSAGE AREA
      ******************************************************************
       01  INPUT-AREA.
           05  LL-IN           PIC  9(04) COMP.
           05  ZZ-IN           PIC  9(04) COMP.
           05  TRAN-CODE       PIC  X(08).
           05  IN-ACCID        PIC  X(18).
           05  IN-AMOUNT       PIC  X(16).
           05  IN-TRXTYPE      PIC  X(01).
           05  IN-CUSTID       PIC  X(09).

       01  OUTPUT-AREA.
           05  LL-OUT          PIC  9(04) COMP.
           05  ZZ-OUT          PIC  9(04) COMP.
           05  MSG-OUT         PIC  X(43).
```

### ✅ IMS SSA (Qualified) (from IBGCUDAT.cbl)

```cobol
       01  CUSTOMER-SSA1.
           05  FILLER          PIC  X(08)        VALUE "CUSTOMER".
           05  FILLER          PIC  X(01)        VALUE "(".
           05  FILLER          PIC  X(08)        VALUE "CUSTID  ".
           05  FILLER          PIC  X(02)        VALUE "EQ".
           05  CUSTID          PIC  S9(9) COMP-5 VALUE +0.
           05  FILLER          PIC  X(01)        VALUE ")".
           05  FILLER          PIC  X(01)        VALUE ' '.
```

### ✅ IMS SSA (Unqualified) (from IBTRAN.cbl)

```cobol
       01  HISTORY-SSA1.
           05  FILLER          PIC  X(08)        VALUE "HISTORY ".
           05  FILLER          PIC  X(01)        VALUE ' '.
```

---

## DB2 COBOL — Good Examples

### ✅ DB2 Includes in WORKING-STORAGE (from INQCUST.cbl)

```cobol
      * CUSTOMER DB2 copybook
          EXEC SQL
             INCLUDE CUSTDB2
          END-EXEC.

      * CUSTOMER host variables for DB2
       01 HOST-CUSTOMER-ROW.
          03 HV-CUSTOMER-EYECATCHER     PIC X(4).
          03 HV-CUSTOMER-SORTCODE       PIC X(6).
          03 HV-CUSTOMER-NUMBER         PIC X(10).
          03 HV-CUSTOMER-TITLE          PIC X(10).
          03 HV-CUSTOMER-FIRST-NAME     PIC X(50).
          03 HV-CUSTOMER-LAST-NAME      PIC X(50).
          03 HV-CUSTOMER-DOB            PIC S9(9) COMP.
          ...

      * Pull in the SQL COMMAREA
       EXEC SQL
          INCLUDE SQLCA
       END-EXEC.
```

### ✅ DB2 Cursor (from INQACC.cbl)

```cobol
      * Declare the CURSOR for ACCOUNT table
           EXEC SQL DECLARE ACC-CURSOR CURSOR FOR
              SELECT ACCOUNT_EYECATCHER,
                     ACCOUNT_CUSTOMER_NUMBER,
                     ACCOUNT_SORTCODE,
                     ACCOUNT_NUMBER,
                     ACCOUNT_TYPE,
                     ACCOUNT_INTEREST_RATE,
                     ACCOUNT_OPENED,
                     ACCOUNT_OVERDRAFT_LIMIT,
                     ACCOUNT_LAST_STATEMENT,
                     ACCOUNT_NEXT_STATEMENT,
                     ACCOUNT_AVAILABLE_BALANCE,
                     ACCOUNT_ACTUAL_BALANCE
                     FROM ACCOUNT
                     WHERE ACCOUNT_SORTCODE =
                        :HV-ACCOUNT-SORTCODE AND
                        ACCOUNT_NUMBER =
                        :HV-ACCOUNT-ACC-NO
                     FOR FETCH ONLY
           END-EXEC.
```

### ✅ Batch DB2 Declare Section and Null Indicators (from LSTCUST.cbl)

```cobol
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

       01  HOST-CUSTOMER-ROW.
           03  HV-CUSTOMER-EYECATCHER   PIC X(4).
           ...

      * Null Indicators — PIC S9(4) COMP-5 para qualquer tipo nullable
       01  NULL-INDICATORS.
           05  NI-EYECATCHER            PIC S9(4) COMP-5.
           05  NI-TITLE                 PIC S9(4) COMP-5.
           ...

           EXEC SQL END DECLARE SECTION END-EXEC.
```

---

## Copybook — Good Examples

### ✅ CUSTOMER.cpy Structure

```cobol
           03 CUSTOMER-RECORD.
              05 CUSTOMER-EYECATCHER                 PIC X(4).
                 88 CUSTOMER-EYECATCHER-VALUE        VALUE 'CUST'.
              05 CUSTOMER-KEY.
                 07 CUSTOMER-SORTCODE                PIC 9(6) DISPLAY.
                 07 CUSTOMER-NUMBER                  PIC 9(10) DISPLAY.
              05 CUSTOMER-NAME.
                 07 CUSTOMER-TITLE                   PIC X(10).
                 07 CUSTOMER-FIRST-NAME              PIC X(50).
                 07 CUSTOMER-LAST-NAME               PIC X(50).
              05 CUSTOMER-DOB.
                 07 CUSTOMER-DOB-DAY                 PIC 99 DISPLAY.
                 07 CUSTOMER-DOB-MONTH               PIC 99 DISPLAY.
                 07 CUSTOMER-DOB-YEAR                PIC 9999 DISPLAY.
              05 CUSTOMER-STATUS                     PIC X(10).
                 88 CUSTOMER-STATUS-ACTIVE           VALUE 'ACTIVE'.
                 88 CUSTOMER-STATUS-INACTIVE         VALUE 'INACTIVE'.
                 88 CUSTOMER-STATUS-SUSPENDED        VALUE 'SUSPENDED'.
```

---

## JCL — Good Examples

### ✅ DB2 Batch Job Card and Execution (from LSTCUST.jcl)

```jcl
//LSTCUST  JOB 'Customer List',NOTIFY=&SYSUID,CLASS=A,
//          MSGCLASS=H,MSGLEVEL=(1,1),REGION=4M
//*=============================================================
//* JOB:  LSTCUST
//* DESC: LISTAGEM GERAL DE CUSTOMERS - BANCO XYZ
//* PROG: LSTCUST
//*
//* CODIGOS DE RETORNO:
//*   RC= 0  Execucao bem-sucedida
//*   RC= 4  Nenhum customer encontrado (tabela vazia)
//*   RC= 8  Erro de I/O no dataset de saida
//*  RC=12  Erro DB2 (SQLCODE negativo)
//*=============================================================
//STEP1    EXEC PGM=IKJEFT01
//STEPLIB  DD  DISP=SHR,DSN=DB2V13.SDSNEXIT
//         DD  DISP=SHR,DSN=DB2V13.SDSNLOAD
//         DD  DISP=SHR,DSN=BANKZ.V0R1M0.LOAD
//LSTOUT   DD  DSN=RAFAELT.BANK.LSTCUST.REPORT,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(50,10),RLSE),
//             DCB=(RECFM=FB,LRECL=133,BLKSIZE=27930)
//SYSPRINT DD  SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DBD1)
 RUN  PROGRAM(LSTCUST) PLAN(BANKZPLN) -
      LIB('BANKZ.V0R1M0.LOAD')
 END
/*
```

---

## PL/I — Good Examples

### ✅ PL/I Batch Program Header (from BNKSTMT.pli)

```pli
  /*------------------------------------------------------------*
   * Licensed Materials - Property of IBM
   *
   * (c) Copyright IBM Corp. 2026.
   *
   * US Government Users Restricted Rights - Use, duplication or
   * disclosure restricted by GSA ADP Schedule Contract
   * with IBM Corp.
  *------------------------------------------------------------*/

  /*------------------------------------------------------------*
  * Procedure: BNKSTMT
  * Description: PL/I Batch Program for Bank Monthly Statement Generation
  *
  * Purpose: Generate monthly account statements for bank customers
  *
  * Input:  JCL parameters - Account number range and statement period
  * Output: Formatted monthly statement report to SYSPRINT
  *
  * DB2 Tables Used:
  *   - ACCOUNT: Account information and balances
  *   - CUSTOMER: Customer demographic information
  *   - PROCTRAN: Transaction history (processed transactions)
  *------------------------------------------------------------*/

  BNKSTMT: PROCEDURE OPTIONS(MAIN);
```

### ✅ PL/I Host Variable Group with Underscores (from BNKSTMT.pli)

```pli
  DCL
   1 HV_CUSTOMER,
    5 HV_CUST_EYECATCHER      CHAR(4),
    5 HV_CUST_SORTCODE        CHAR(6),
    5 HV_CUST_NUMBER          CHAR(10),
    5 HV_CUST_FIRST_NAME      CHAR(50),
    5 HV_CUST_LAST_NAME       CHAR(50),
    5 HV_CUST_DOB             FIXED BIN(31),
    5 HV_CUST_CREDIT_SCORE    FIXED BIN(15);

  /* Null indicators for customer table */
  DCL
   1 HV_CUST_NULL_IND,
    5 HV_CUST_TITLE_NULL      FIXED BIN(15),
    5 HV_CUST_PHONE_NULL      FIXED BIN(15);
```

---

## Anti-Patterns (DO NOT use in new code)

### ❌ `PROCESS CICS,...` instead of `CBL CICS(...)`

```cobol
       PROCESS CICS,NODYNAM,NSYMBOL(NATIONAL),TRUNC(STD)  ← DO NOT USE
       CBL CICS('SP,EDF')                                  ← CORRECT
```

### ❌ Level 03 in WS-CICS-WORK-AREA

```cobol
       01 WS-CICS-WORK-AREA.
          03 WS-CICS-RESP    PIC S9(8) COMP.   ← DO NOT USE level 03
          05 WS-CICS-RESP    PIC S9(8) COMP.   ← CORRECT level 05
```

### ❌ Missing RESP/RESP2 on EXEC CICS

```cobol
       EXEC CICS RETURN              ← DO NOT omit RESP/RESP2
       END-EXEC.

       EXEC CICS RETURN              ← CORRECT
          RESP(WS-CICS-RESP)
          RESP2(WS-CICS-RESP2)
       END-EXEC.
```

### ❌ EXEC CICS HANDLE CONDITION (legacy, not to be used)

```cobol
       EXEC CICS HANDLE CONDITION   ← DO NOT USE
          MAPFAIL(MAPFAIL-ROUTINE)
       END-EXEC.

       ← CORRECT: use inline RESP checking instead
```

### ❌ COPY instead of EXEC SQL INCLUDE for DB2 table definitions

```cobol
       COPY CUSTDB2.               ← DO NOT USE for DB2 table copybooks

       EXEC SQL                    ← CORRECT
          INCLUDE CUSTDB2
       END-EXEC.
```
