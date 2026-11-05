# Code Samples — Bank of Z Coding Standards

Real code excerpts extracted from the Bank of Z codebase illustrating each standard.

---

## COBOL — Program Header (GOOD example from XFRFUN.cbl)

```cobol
       CBL CICS('SP,EDF')
       CBL SQL
      ******************************************************************
      *                                                                *
      *  Copyright IBM Corp. 2023                                      *
      *                                                                *
      ******************************************************************

      ******************************************************************
      * This program gets called when someone initiates a transfer
      * of funds (perhaps) over the counter or via a web application.
      *
      * This program takes an incoming sortcode/account number (key)
      * from the account where the money is transfered from and a
      * sortcode/acount number (key) combination for the account where
      * the money is being transferred to. Additionally, there will
      * also be an incoming amount.
      *
      * If the transfer can be made successfully after looking up
      * the account information then the account information will be
      * updated and the PROCTRAN (Processed Transaction) datastore
      * will be updated to record the successful transaction.
      *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. XFRFUN.
       AUTHOR. Jon Collett.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *SOURCE-COMPUTER.   IBM-370 WITH DEBUGGING MODE.
       SOURCE-COMPUTER.  IBM-370.
       OBJECT-COMPUTER.  IBM-370.
```

**Note:** `SOURCE-COMPUTER. IBM-370.` is legacy. Use `IBM-Z` for new programs.

---

## COBOL — Batch Program Header with Return Codes (GOOD example from LSTCUST.cbl)

```cobol
      ******************************************************************
      *                                                                *
      *  Copyright IBM Corp. 2025                                      *
      *                                                                *
      *  Program:     LSTCUST                                          *
      *  Type:        Batch — Relatorio Sequencial                     *
      *  Description: Lista todos os customers da tabela DB2 CUSTOMER  *
      *               gerando relatorio sequencial com cabecalho de    *
      *               pagina, colunas alinhadas e totalizador final.   *
      *                                                                *
      *  Input:       Tabela DB2 CUSTOMER (cursor sequencial)          *
      *  Output:      DD LSTOUT — RAFAELT.BANK.LSTCUST.REPORT          *
      *               LRECL=133 RECFM=FB                               *
      *                                                                *
      *  Return codes:                                                 *
      *    0  = Execucao bem-sucedida                                  *
      *    4  = Aviso — nenhum customer encontrado                     *
      *    8  = Erro de I/O no arquivo de saida                        *
      *   12  = Erro DB2 (SQLCODE negativo)                            *
      *                                                                *
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    LSTCUST.
       AUTHOR.        IBM Bank-of-Z.
       DATE-WRITTEN.  2025-07-09.
```

---

## COBOL — CICS Work Area + Security Switch (GOOD from BNKMENU.cbl)

```cobol
       01 WS-CICS-WORK-AREA.
          03 WS-CICS-RESP              PIC S9(8) COMP VALUE 0.
          03 WS-CICS-RESP2             PIC S9(8) COMP VALUE 0.

       01 SWITCHES.
           03 VALID-DATA-SW            PIC X VALUE 'Y'.
              88 VALID-DATA                VALUE 'Y'.

       01 FLAGS.
           03 SEND-FLAG                PIC X.
              88 SEND-ERASE              VALUE '1'.
              88 SEND-DATAONLY           VALUE '2'.
              88 SEND-DATAONLY-ALARM     VALUE '3'.
```

---

## COBOL — Security Check Pattern (GOOD from DBCRFUN.cbl)

```cobol
      * Ask BNKSECCK if the user may debit/credit accounts.
      * Fail-closed: only an allowed result with a NORMAL response
      * gives SEC-OK. S = not authorised, X = security unavailable.
      *
       SECURITY-CHECK SECTION.
       SC010.

           SET SEC-NOT-OK TO TRUE.
           INITIALIZE BNKSEC-COMMAREA.
           MOVE 'DBCRFUN ' TO BNKSEC-OPERATION.

           EXEC CICS LINK PROGRAM('BNKSECCK')
                COMMAREA(BNKSEC-COMMAREA)
                LENGTH(LENGTH OF BNKSEC-COMMAREA)
                RESP(WS-CICS-RESP)
                RESP2(WS-CICS-RESP2)
           END-EXEC.

           IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
              MOVE 'N' TO COMM-SUCCESS
              MOVE 'X' TO COMM-FAIL-CODE
              GO TO SC999
           END-IF.

           EVALUATE TRUE
              WHEN BNKSEC-ALLOWED
                 SET SEC-OK TO TRUE
              WHEN BNKSEC-DENIED
                 MOVE 'N' TO COMM-SUCCESS
                 MOVE 'S' TO COMM-FAIL-CODE
              WHEN OTHER
                 MOVE 'N' TO COMM-SUCCESS
                 MOVE 'X' TO COMM-FAIL-CODE
           END-EVALUATE.

       SC999.
           EXIT.
```

---

## COBOL — ABEND-HANDLING Section (GOOD from DBCRFUN.cbl)

```cobol
       ABEND-HANDLING SECTION.
       AH010.

           EXEC CICS ASSIGN ABCODE(MY-ABEND-CODE)
           END-EXEC.

           EVALUATE MY-ABEND-CODE
      *
      *       DB2 AD2Z abend
      *
               WHEN 'AD2Z'
                  MOVE SQLCODE TO SQLCODE-DISPLAY
                  DISPLAY 'DB2 DEADLOCK DETECTED IN DBCRFUN, SQLCODE='
                     SQLCODE-DISPLAY

      *
      *          VSAM RLS abends, subject to CPSM WLM Storm Drain check
      *
               WHEN 'AFCR'
               WHEN 'AFCS'
               WHEN 'AFCT'
                  MOVE 'Y' TO WS-STORM-DRAIN
                  DISPLAY 'DBCRFUN: Check-For-Storm-Drain-VSAM: Storm '
                         'Drain condition (Abend ' MY-ABEND-CODE ') '
                         'has been met.'

                  EXEC CICS SYNCPOINT
                     ROLLBACK
                     RESP(WS-CICS-RESP)
                     RESP2(WS-CICS-RESP2)
                  END-EXEC

                  IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
                     INITIALIZE ABNDINFO-REC
                     MOVE EIBRESP    TO ABND-RESPCODE
                     MOVE EIBRESP2   TO ABND-RESP2CODE
                     EXEC CICS ASSIGN APPLID(ABND-APPLID)
                     END-EXEC
                     MOVE EIBTASKN   TO ABND-TASKNO-KEY
                     MOVE EIBTRNID   TO ABND-TRANID
                     PERFORM POPULATE-TIME-DATE
                     MOVE WS-ORIG-DATE TO ABND-DATE
                     STRING WS-TIME-NOW-GRP-HH DELIMITED BY SIZE,
                        ':' DELIMITED BY SIZE,
                         WS-TIME-NOW-GRP-MM DELIMITED BY SIZE,
                         ':' DELIMITED BY SIZE,
                         WS-TIME-NOW-GRP-MM DELIMITED BY SIZE
                         INTO ABND-TIME
                     END-STRING
                     MOVE WS-U-TIME   TO ABND-UTIME-KEY
                     MOVE 'HROL'      TO ABND-CODE
                     EXEC CICS ASSIGN PROGRAM(ABND-PROGRAM)
                     END-EXEC
                     MOVE ZEROS      TO ABND-SQLCODE
                     STRING 'AH010 - Unable to perform Synpoint '
                        DELIMITED BY SIZE,
                        'Rollback.' DELIMITED BY SIZE
                        INTO ABND-FREEFORM
                     END-STRING
                     EXEC CICS LINK PROGRAM(WS-ABEND-PGM)
                            COMMAREA(ABNDINFO-REC)
                     END-EXEC
                     EXEC CICS ABEND
                        ABCODE ('HROL')
                        CANCEL
                     END-EXEC
                  END-IF
           END-EVALUATE.

           IF WS-STORM-DRAIN = 'N'
              EXEC CICS ABEND
                 ABCODE( MY-ABEND-CODE)
                 NODUMP
                 CANCEL
              END-EXEC
           END-IF.

       AH999.
           EXIT.
```

---

## COBOL — POPULATE-TIME-DATE Section (GOOD from DBCRFUN.cbl)

```cobol
       POPULATE-TIME-DATE SECTION.
       PTD10.

           EXEC CICS ASKTIME
              ABSTIME(WS-U-TIME)
           END-EXEC.

           EXEC CICS FORMATTIME
                     ABSTIME(WS-U-TIME)
                     DDMMYYYY(WS-ORIG-DATE)
                     TIME(WS-TIME-NOW)
                     DATESEP
           END-EXEC.

       PTD999.
           EXIT.
```

---

## COBOL — GET-ME-OUT-OF-HERE Section (GOOD from INQCUST.cbl)

```cobol
       GET-ME-OUT-OF-HERE SECTION.
       GMOFH010.
      *
      *    Finish
      *
           EXEC CICS RETURN
           END-EXEC.

       GMOFH999.
           EXIT.
```

---

## COBOL — IMS Program Structure (GOOD from LOADCUST.cbl)

```cobol
       CBL LIST,MAP,XREF,FLAG(I)
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOADCUST.

      ******************************************************************
      * Licensed Materials - Property of IBM
      * (c) Copyright IBM Corp. 2026.
      ******************************************************************

       WORKING-STORAGE SECTION.

      ******************************************************************
      *DATABASE CALL CODES
      ******************************************************************

       77  GU                  PIC  X(04)        VALUE "GU  ".
       77  GHU                 PIC  X(04)        VALUE "GHU ".
       77  GN                  PIC  X(04)        VALUE "GN  ".
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

       LINKAGE SECTION.
       01  IOPCBA POINTER.
       01  DBPCB1 POINTER.

       PROCEDURE DIVISION.
             ENTRY "DLITCBL"
             USING  IOPCBA, DBPCB1.
```

---

## COBOL — DB2 Host Variable Group (GOOD from LSTCUST.cbl)

```cobol
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.

       01  HOST-CUSTOMER-ROW.
           03  HV-CUSTOMER-EYECATCHER   PIC X(4).
           03  HV-CUSTOMER-SORTCODE     PIC X(6).
           03  HV-CUSTOMER-NUMBER       PIC X(10).
           03  HV-CUSTOMER-TITLE        PIC X(10).
           03  HV-CUSTOMER-FIRST-NAME   PIC X(50).
           03  HV-CUSTOMER-LAST-NAME    PIC X(50).
           03  HV-CUSTOMER-DOB          PIC S9(9) COMP-5.

      * Null Indicators — PIC S9(4) COMP-5 para qualquer tipo nullable
       01  NULL-INDICATORS.
           05  NI-TITLE                 PIC S9(4) COMP-5.
           05  NI-FIRST-NAME            PIC S9(4) COMP-5.
           05  NI-DOB                   PIC S9(4) COMP-5.

           EXEC SQL END DECLARE SECTION END-EXEC.
```

---

## JCL — DB2 Batch Job (GOOD example from LSTCUST.jcl)

```jcl
//LSTCUST  JOB 'Customer List',NOTIFY=&SYSUID,CLASS=A,
//          MSGCLASS=H,MSGLEVEL=(1,1),REGION=4M
//*=============================================================
//* JOB:  LSTCUST
//* DESC: LISTAGEM GERAL DE CUSTOMERS - BANCO XYZ
//* PROG: LSTCUST
//* SAIDA: RAFAELT.BANK.LSTCUST.REPORT
//*        RECFM=FB  LRECL=133  BLKSIZE=27930
//*
//* CODIGOS DE RETORNO:
//*   RC= 0  Execucao bem-sucedida
//*   RC= 4  Nenhum customer encontrado (tabela vazia)
//*   RC= 8  Erro de I/O no dataset de saida
//*   RC=12  Erro DB2 (SQLCODE negativo)
//*
//* PRE-REQUISITOS:
//*   - Plano DB2 BANKZPLN deve incluir o programa LSTCUST
//*   - Dataset de saida NAO deve existir (DISP=NEW)
//*=============================================================
//    SET HLQ='RAFAELT'
//*
//STEP1    EXEC PGM=IKJEFT01
//STEPLIB  DD  DISP=SHR,DSN=DSN1310.DB2.SDSNEXIT
//         DD  DISP=SHR,DSN=DSN1310.DB2.SDSNLOAD
//         DD  DISP=SHR,DSN=RAFAELT.BANKZ.LOAD
//LSTOUT   DD  DSN=RAFAELT.BANK.LSTCUST.REPORT,
//             DISP=(MOD,CATLG,DELETE),
//             SPACE=(TRK,(50,10),RLSE),
//             DCB=(RECFM=FB,LRECL=133,BLKSIZE=27930)
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DSNT)
 RUN  PROGRAM(LSTCUST) PLAN(BANKZPLN) -
      LIB('RAFAELT.BANKZ.LOAD')
 END
/*
```

---

## PL/I — Program Header (GOOD from BNKSTMT.pli)

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
  *          using DB2 tables for account, customer, and transaction data
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

---

## PL/I — Host Variable Group (GOOD from BNKSTMT.pli)

```pli
  DCL
   1 HV_CUSTOMER,
    5 HV_CUST_EYECATCHER      CHAR(4),
    5 HV_CUST_SORTCODE        CHAR(6),
    5 HV_CUST_NUMBER          CHAR(10),
    5 HV_CUST_FIRST_NAME      CHAR(50),
    5 HV_CUST_LAST_NAME       CHAR(50),
    5 HV_CUST_DOB             FIXED BIN(31),
    5 HV_CUST_CREDIT_SCORE    FIXED BIN(15),
    5 HV_CUST_CS_REVIEW_DATE  FIXED BIN(31);

  /* Null indicators for customer table */
  DCL
   1 HV_CUST_NULL_IND,
    5 HV_CUST_TITLE_NULL      FIXED BIN(15),
    5 HV_CUST_DOB_NULL        FIXED BIN(15),
    5 HV_CUST_CREDIT_SCORE_NULL FIXED BIN(15);
```

---

## PL/I — ON Condition Error Handling (GOOD from BNKSTMT.pli)

```pli
   ON ENDFILE(SORTCODE)
     BEGIN;
       PUT SKIP LIST('SORTCODE FILE NOT FOUND - USING DEFAULT');
       HV_ACCT_SORTCODE = '123456';  /* Default sort code */
       GO TO READ_DATECARD;
     END;
   
   OPEN FILE(SORTCODE);
   READ FILE(SORTCODE) INTO(SORTCODE_INPUT);
   CLOSE FILE(SORTCODE);
```

---

## Copybook — Structure Pattern (GOOD from ACCOUNT.cpy)

```cobol
      ******************************************************************
      *                                                                *
      *  Copyright IBM Corp. 2023                                      *
      *                                                                *
      ******************************************************************
              03 ACCOUNT-DATA.
                 05 ACCOUNT-EYE-CATCHER        PIC X(4).
                 88 ACCOUNT-EYECATCHER-VALUE        VALUE 'ACCT'.
                 05 ACCOUNT-CUST-NO            PIC 9(10).
                 05 ACCOUNT-KEY.
                    07 ACCOUNT-SORT-CODE       PIC 9(6).
                    07 ACCOUNT-NUMBER          PIC 9(8).
                 05 ACCOUNT-TYPE               PIC X(8).
                 05 ACCOUNT-AVAILABLE-BALANCE  PIC S9(10)V99.
                 05 ACCOUNT-ACTUAL-BALANCE     PIC S9(10)V99.
```

Note: Copybooks start at level `03` — they are embedded inside a calling program's `01` level.
