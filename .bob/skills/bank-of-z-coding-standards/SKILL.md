---
name: bank-of-z-coding-standards
description: >
  Enforces Bank of Z coding standards for COBOL (CICS, IMS, Batch), PL/I, and JCL.
  Discovered by automated codebase analysis of 20 representative files.
  Use when: "review code", "check standards", "generate code", "refactor code",
  "new COBOL program", "new JCL", "new PL/I", "does this follow our standards",
  "create a program", "write a program".
metadata:
  author: Discovered by Bob Z Coding Standards Builder
  version: 1.0.0
  enforcement-level: strict
  target-languages: COBOL CICS, COBOL IMS, COBOL Batch, PL/I, JCL
  discovery-date: 2025-07-14
  files-analyzed: 20
  confidence-threshold: 80%
---

# Bank of Z — Coding Standards

These standards were **discovered by automated analysis** of the Bank of Z codebase.
All rules marked **MUST** have 80%+ adoption in the analyzed files.
Rules marked **SHOULD** have 60–79% adoption. Rules marked **MAY** are advisory.

---

## 1. COBOL — General (All Subsystems)

### 1.1 File Header (MUST)

Every COBOL source file MUST begin with a copyright block before IDENTIFICATION DIVISION:

```cobol
      ******************************************************************
      *                                                                *
      *  Copyright IBM Corp. 2023                                      *
      *                                                                *
      ******************************************************************
```

Followed immediately by a description block:

```cobol
      ******************************************************************
      * This program <one-line purpose summary>
      *
      * <detailed description of inputs, outputs, and logic>
      *
      ******************************************************************
```

The IDENTIFICATION DIVISION MUST include `AUTHOR.`:

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MYPROG.
       AUTHOR. <author name>.
```

### 1.2 ENVIRONMENT DIVISION (MUST)

Always include CONFIGURATION SECTION with these exact entries. The `WITH DEBUGGING MODE` line MUST be commented out (not active):

```cobol
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
      *SOURCE-COMPUTER.   IBM-370 WITH DEBUGGING MODE.
       SOURCE-COMPUTER.  IBM-370.
       OBJECT-COMPUTER.  IBM-370.
       INPUT-OUTPUT SECTION.
```

Batch programs (non-CICS) use `IBM-Z` instead of `IBM-370`.

### 1.3 Working-Storage Naming (MUST)

- All WORKING-STORAGE variables MUST use the `WS-` prefix on 01-levels.
- DB2 host variables MUST use the `HV-` prefix, grouped as `HV-<TABLENAME>-<COLUMN>`.
  - Example: `HV-CUSTOMER-SORTCODE`, `HV-ACCOUNT-AVAIL-BAL`
- DB2 null indicators MUST use the `NI-` prefix.
  - Example: `NI-TITLE`, `NI-CREDIT-SCORE`
- Local retry counters (77-level or 01-level) use the pattern `<CONTEXT>-RETRY` (e.g., `SYSIDERR-RETRY`, `FILE-RETRY`).

### 1.4 Switches and Flags (MUST)

Switches and flags MUST be declared as distinct 01-level groups named `SWITCHES` and `FLAGS`.
All boolean switches use PIC X with 88-level conditions:

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

### 1.5 Date and Time Working-Storage Block (MUST — CICS programs)

Every CICS program with abend handling MUST include this exact block in WORKING-STORAGE:

```cobol
       01 WS-U-TIME                    PIC S9(15) COMP-3.
       01 WS-ORIG-DATE                 PIC X(10).
       01 WS-ORIG-DATE-GRP REDEFINES WS-ORIG-DATE.
          03 WS-ORIG-DATE-DD           PIC 99.
          03 FILLER                    PIC X.
          03 WS-ORIG-DATE-MM           PIC 99.
          03 FILLER                    PIC X.
          03 WS-ORIG-DATE-YYYY         PIC 9999.

       01 WS-ORIG-DATE-GRP-X.
          03 WS-ORIG-DATE-DD-X         PIC XX.
          03 FILLER                    PIC X VALUE '.'.
          03 WS-ORIG-DATE-MM-X         PIC XX.
          03 FILLER                    PIC X VALUE '.'.
          03 WS-ORIG-DATE-YYYY-X       PIC X(4).

       01 WS-TIME-DATA.
           03 WS-TIME-NOW              PIC 9(6).
           03 WS-TIME-NOW-GRP REDEFINES WS-TIME-NOW.
              05 WS-TIME-NOW-GRP-HH    PIC 99.
              05 WS-TIME-NOW-GRP-MM    PIC 99.
              05 WS-TIME-NOW-GRP-SS    PIC 99.
```

### 1.6 Abend Handler Reference (MUST — CICS programs)

Every CICS program MUST declare the abend program reference and info record:

```cobol
       01 WS-ABEND-PGM                 PIC X(8) VALUE 'ABNDPROC'.

       01 ABNDINFO-REC.
           COPY ABNDINFO.
```

### 1.7 PROCEDURE DIVISION Structure (MUST)

Sections use VERB-NOUN naming. Each section has a three-character + `010` opening paragraph and a `999` closing paragraph with `EXIT.`:

```cobol
       RECEIVE-MENU-MAP SECTION.
       RMM010.
      *
      *    <one-line description>
      *
           <statements>

       RMM999.
           EXIT.
```

The main entry section MUST be named `PREMIERE SECTION` with opening paragraph `A010`:

```cobol
       PROCEDURE DIVISION.
       PREMIERE SECTION.
       A010.
           ...
       A999.
           EXIT.
```

Inline comments above PERFORMs use the pattern:
```cobol
      *
      *    <description of what is about to happen>
      *
           PERFORM <section-name>.
```

### 1.8 LOCAL-STORAGE SECTION (SHOULD)

Use `LOCAL-STORAGE SECTION` for variables that must be re-initialized on every invocation (especially loop counters, retry flags, and work areas passed to sub-programs). Do NOT put these in WORKING-STORAGE for re-entrant programs.

---

## 2. COBOL CICS — Specific Standards

### 2.1 Compilation Header (MUST)

CICS programs MUST use only `CBL` directives — no `PROCESS` statement:

```cobol
       CBL CICS('SP,EDF')
```

For programs that also use DB2:

```cobol
       CBL CICS('SP,EDF')
       CBL SQL
```

For programs that also use DL/I:

```cobol
       CBL CICS('SP,EDF,DLI')
```

### 2.2 CICS Work Area (MUST)

MUST be declared exactly as follows (level `05` inside `WS-CICS-WORK-AREA`):

```cobol
       01 WS-CICS-WORK-AREA.
          05 WS-CICS-RESP               PIC S9(8) COMP.
          05 WS-CICS-RESP2              PIC S9(8) COMP.
```

### 2.3 CICS Command Error Handling (MUST)

Every EXEC CICS command MUST include `RESP` and `RESP2`, and MUST be followed by an immediate check:

```cobol
           EXEC CICS
              <COMMAND>
              RESP(WS-CICS-RESP)
              RESP2(WS-CICS-RESP2)
           END-EXEC.

           IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
              <abend block — see 2.4>
           END-IF.
```

Never use `EXEC CICS HANDLE CONDITION` — always use inline RESP checking.

### 2.4 Standard Abend Block (MUST)

When a CICS command fails, use this exact sequence:

```cobol
           INITIALIZE ABNDINFO-REC
           MOVE EIBRESP    TO ABND-RESPCODE
           MOVE EIBRESP2   TO ABND-RESP2CODE
      *
      *    Get supplemental information
      *
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
                  WS-TIME-NOW-GRP-SS DELIMITED BY SIZE
                  INTO ABND-TIME
           END-STRING

           MOVE WS-U-TIME   TO ABND-UTIME-KEY
           MOVE 'HBNK'      TO ABND-CODE

           EXEC CICS ASSIGN PROGRAM(ABND-PROGRAM)
           END-EXEC

           MOVE ZEROS      TO ABND-SQLCODE

           STRING '<PARAGRAPH_ID> - <COMMAND> FAIL.'
                 DELIMITED BY SIZE,
                 ' EIBRESP=' DELIMITED BY SIZE,
                 ABND-RESPCODE DELIMITED BY SIZE,
                 ' RESP2=' DELIMITED BY SIZE,
                 ABND-RESP2CODE DELIMITED BY SIZE
                 INTO ABND-FREEFORM
           END-STRING

           EXEC CICS LINK PROGRAM(WS-ABEND-PGM)
                     COMMAREA(ABNDINFO-REC)
           END-EXEC

           INITIALIZE WS-FAIL-INFO
           MOVE '<PROGRAM> - <PARAGRAPH_ID> - <COMMAND> FAIL' TO
              WS-CICS-FAIL-MSG
           MOVE WS-CICS-RESP  TO WS-CICS-RESP-DISP
           MOVE WS-CICS-RESP2 TO WS-CICS-RESP2-DISP
           PERFORM ABEND-THIS-TASK
```

Replace `<PARAGRAPH_ID>`, `<COMMAND>`, and `<PROGRAM>` with actual values.

### 2.5 LINKAGE SECTION for CICS (MUST)

Programs receiving a COMMAREA MUST declare it in LINKAGE SECTION and use `COPY` from the corresponding copybook:

```cobol
       LINKAGE SECTION.
       01 DFHCOMMAREA.
           COPY <COMMAREA-COPYBOOK>.

       PROCEDURE DIVISION USING DFHCOMMAREA.
```

### 2.6 CICS FAIL-INFO Area (MUST)

Every CICS program MUST declare `WS-FAIL-INFO` with the program name embedded as a literal:

```cobol
       01 WS-FAIL-INFO.
          03 FILLER                    PIC X(9) VALUE '<PROGNAME>  '.
          03 WS-CICS-FAIL-MSG          PIC X(70) VALUE ' '.
          03 FILLER                    PIC X(6)  VALUE ' RESP='.
          03 WS-CICS-RESP-DISP         PIC 9(10) VALUE 0.
          03 FILLER                    PIC X(7)  VALUE ' RESP2='.
          03 WS-CICS-RESP2-DISP        PIC 9(10) VALUE 0.
          03 FILLER                   PIC X(15) VALUE ' ABENDING TASK.'.
```

---

## 3. COBOL IMS — Specific Standards

### 3.1 Compilation Header (MUST)

IMS programs MUST use:

```cobol
       CBL LIST,MAP,XREF,FLAG(I)
```

No CICS directives. No PROCESS statement.

### 3.2 DL/I Call Codes as 77-Levels (MUST)

All DL/I function codes MUST be declared as 77-level items at the top of WORKING-STORAGE:

```cobol
       77  GU                  PIC  X(04)        VALUE "GU  ".
       77  GHU                 PIC  X(04)        VALUE "GHU ".
       77  GN                  PIC  X(04)        VALUE "GN  ".
       77  GHN                 PIC  X(04)        VALUE "GHN ".
       77  ISRT                PIC  X(04)        VALUE "ISRT".
       77  REPL                PIC  X(04)        VALUE "REPL".
```

IMS status codes:

```cobol
       77  GE                  PIC  X(02)        VALUE "GE".
       77  GB                  PIC  X(02)        VALUE "GB".
```

### 3.3 Bad-Status Capture Area (MUST)

```cobol
       01  BAD-STATUS.
           05  SC-MSG  PIC X(30) VALUE "BAD STATUS CODE WAS RECEIVED: ".
           05  SC             PIC X(2).
```

### 3.4 IMS Message Areas (MUST)

Input and output message areas MUST begin with LL and ZZ fields (COMP, 4 bytes each):

```cobol
       01  INPUT-AREA.
           05  LL-IN           PIC  9(04) COMP.
           05  ZZ-IN           PIC  9(04) COMP.
           05  TRAN-CODE       PIC  X(08).
           <remaining fields>

       01  OUTPUT-AREA.
           05  LL-OUT          PIC  9(04) COMP.
           05  ZZ-OUT          PIC  9(04) COMP.
           05  MSG-OUT         PIC  X(<n>).
           <remaining fields>
```

### 3.5 Segment Search Arguments (MUST)

SSAs MUST be declared as 01-level items with FILLER fields carrying the segment name, qualifier, field name, operator, and value:

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

Unqualified SSAs (for sequential reads):

```cobol
       01  HISTORY-SSA1.
           05  FILLER          PIC  X(08)        VALUE "HISTORY ".
           05  FILLER          PIC  X(01)        VALUE ' '.
```

### 3.6 LINKAGE SECTION for IMS (MUST)

```cobol
       LINKAGE SECTION.

       01  IOPCBA POINTER.
       01  DBPCB1 POINTER.

       PROCEDURE DIVISION USING IOPCBA DBPCB1.
```

---

## 4. COBOL — DB2 Standards (All Subsystems)

### 4.1 DB2 Includes (MUST)

Use `EXEC SQL INCLUDE` — never `COPY` — for DB2 table definitions and SQLCA:

```cobol
      * <Table description> DB2 copybook
            EXEC SQL
               INCLUDE CUSTDB2
            END-EXEC.

      * Pull in the SQL COMMAREA
       EXEC SQL
          INCLUDE SQLCA
       END-EXEC.
```

Place table INCLUDEs before the corresponding host variable 01-level. Place SQLCA last among DB2 includes.

### 4.2 Host Variable Groups (MUST)

Host variables MUST form a named 01-level group with `HV-<TABLE>-` prefix on all fields:

```cobol
       01 HOST-CUSTOMER-ROW.
          03 HV-CUSTOMER-EYECATCHER     PIC X(4).
          03 HV-CUSTOMER-SORTCODE       PIC X(6).
          03 HV-CUSTOMER-NUMBER         PIC X(10).
          ...
```

### 4.3 DB2 Declare Section (MUST — Batch programs)

Batch programs with DB2 MUST use an explicit DECLARE SECTION to wrap host variables:

```cobol
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  HOST-CUSTOMER-ROW.
           ...
           EXEC SQL END DECLARE SECTION END-EXEC.
```

### 4.4 Null Indicators (MUST — Batch programs)

Use `NI-` prefix, PIC S9(4) COMP-5, in a separate 01-level group:

```cobol
       01  NULL-INDICATORS.
           05  NI-TITLE                 PIC S9(4) COMP-5.
           05  NI-FIRST-NAME            PIC S9(4) COMP-5.
           ...
```

Reference null indicators in FETCH with space-separated syntax:
`:HV-CUSTOMER-TITLE :NI-TITLE`

### 4.5 SQL SELECT Formatting (MUST)

Each selected column on its own line, aligned:

```cobol
           EXEC SQL
              SELECT CUSTOMER_EYECATCHER,
                     CUSTOMER_SORTCODE,
                     CUSTOMER_NUMBER,
                     ...
                INTO :HV-CUSTOMER-EYECATCHER,
                     :HV-CUSTOMER-SORTCODE,
                     ...
                FROM CUSTOMER
               WHERE CUSTOMER_SORTCODE = :HV-CUSTOMER-SORTCODE
                 AND CUSTOMER_NUMBER   = :HV-CUSTOMER-NUMBER
           END-EXEC.
```

### 4.6 Cursors (MUST)

All SELECT-only cursors MUST include `FOR FETCH ONLY`. Cursor name uses format `<TABLE>-CURSOR`:

```cobol
           EXEC SQL DECLARE CUST-CURSOR CURSOR FOR
              SELECT ...
              FROM CUSTOMER
              WHERE ...
              FOR FETCH ONLY
           END-EXEC.
```

Batch programs MUST use the "first FETCH before loop" pattern:

```cobol
           EXEC SQL OPEN CUST-CURSOR END-EXEC.

      *   First FETCH before loop — PERFORM UNTIL tests condition BEFORE body
           EXEC SQL
               FETCH CUST-CURSOR INTO ...
           END-EXEC.

           PERFORM FETCH-LOOP
               UNTIL SQLCODE NOT EQUAL ZERO.
```

### 4.7 SQLCODE Checking (MUST)

After all EXEC SQL statements check `SQLCODE`. Use +100 for end-of-data:

```cobol
           IF SQLCODE NOT EQUAL ZERO
               PERFORM DB2-ERROR-HANDLING
           END-IF.

           ...

           IF SQLCODE = +100
               <end of data handling>
           ELSE
               PERFORM DB2-ERROR-HANDLING
           END-IF.
```

---

## 5. Copybook Standards (MUST)

### 5.1 Level Numbers

Copybooks start at level `03` (not `01`) so the calling program can embed them inside a named `01` group.

### 5.2 Eyecatcher with 88-Level

Every entity copybook MUST include an eyecatcher field with a 88-level validation:

```cobol
       03 CUSTOMER-RECORD.
          05 CUSTOMER-EYECATCHER                 PIC X(4).
             88 CUSTOMER-EYECATCHER-VALUE        VALUE 'CUST'.
```

### 5.3 Status Fields with 88-Levels

Status/type fields MUST enumerate all valid values as 88-levels:

```cobol
          05 CUSTOMER-STATUS                     PIC X(10).
             88 CUSTOMER-STATUS-ACTIVE           VALUE 'ACTIVE'.
             88 CUSTOMER-STATUS-INACTIVE         VALUE 'INACTIVE'.
             88 CUSTOMER-STATUS-SUSPENDED        VALUE 'SUSPENDED'.
```

### 5.4 Date Subfields

Date fields MUST be broken into DD/MM/YYYY subfields using DISPLAY format:

```cobol
          05 CUSTOMER-DOB.
             07 CUSTOMER-DOB-DAY                 PIC 99 DISPLAY.
             07 CUSTOMER-DOB-MONTH               PIC 99 DISPLAY.
             07 CUSTOMER-DOB-YEAR                PIC 9999 DISPLAY.
```

### 5.5 REDEFINES for Multiple Interpretations

Use REDEFINES to overlay date/time fields for formatted output, and to model alternative data structures (e.g., XFR transfer description, DELACC delete description) — see `PROCTRAN.cpy` as canonical example.

---

## 6. JCL Standards

### 6.1 Job Card (MUST)

```jcl
//JOBNAME  JOB 'description',NOTIFY=&SYSUID,CLASS=A,
//          MSGCLASS=H,MSGLEVEL=(1,1),REGION=4M
```

Use `REGION=4M` for standard jobs; `REGION=256M` for compile jobs.

### 6.2 Job Header Comment Block (MUST — production JCL)

```jcl
//*=============================================================
//* JOB:  <jobname>
//* DESC: <description in caps>
//* PROG: <program name>
//*
//* CODIGOS DE RETORNO:
//*   RC= 0  <meaning>
//*   RC= 4  <meaning>
//*   RC= 8  <meaning>
//*  RC=12  <meaning>
//*
//* PRE-REQUISITOS:
//*   - <prerequisite 1>
//*=============================================================
```

### 6.3 DB2 Program Execution (MUST)

All DB2 batch programs MUST execute via `IKJEFT01` with DSN commands:

```jcl
//STEP1    EXEC PGM=IKJEFT01
//STEPLIB  DD  DISP=SHR,DSN=DB2V13.SDSNEXIT
//         DD  DISP=SHR,DSN=DB2V13.SDSNLOAD
//         DD  DISP=SHR,DSN=BANKZ.V0R1M0.LOAD
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSTSPRT DD  SYSOUT=*
//SYSTSIN  DD *
 DSN SYSTEM(DBD1)
 RUN  PROGRAM(<progname>) PLAN(BANKZPLN) -
      LIB('BANKZ.V0R1M0.LOAD')
 END
/*
```

STEPLIB MUST list SDSNEXIT first, then SDSNLOAD, then the application LOAD library.

### 6.4 Compile JCL (MUST)

- Use symbolic variables with `SET` at the top for all library names and HLQs.
- Chain steps with `COND=(4,LT,STEP_PREVIOUS)` to stop on error.
- DB2 programs require 3 steps: DSNHPC (pre-compiler) → IGYCRCTL (compiler) → IEWL (link-editor).
- After compilation, DB2 programs MUST be BINDed: `BIND PACKAGE` then `BIND PLAN(BANKZPLN)`.

### 6.5 Output Dataset Allocation (MUST)

New sequential output datasets use `DISP=(NEW,CATLG,DELETE)` with explicit DCB:

```jcl
//LSTOUT   DD  DSN=<HLQ>.BANK.<JOBNAME>.REPORT,
//             DISP=(NEW,CATLG,DELETE),
//             SPACE=(TRK,(50,10),RLSE),
//             DCB=(RECFM=FB,LRECL=133,BLKSIZE=27930)
```

---

## 7. PL/I Standards

### 7.1 File Header (MUST)

```pli
  /*------------------------------------------------------------*
   * Licensed Materials - Property of IBM
   *
   * (c) Copyright IBM Corp. <year>.
   *
   * US Government Users Restricted Rights - Use, duplication or
   * disclosure restricted by GSA ADP Schedule Contract
   * with IBM Corp.
  *------------------------------------------------------------*/

  /*------------------------------------------------------------*
  * Procedure: <NAME>
  * Description: <one-line description>
  *
  * Purpose: <detailed purpose>
  *
  * Input:  <input description>
  * Output: <output description>
  *
  * DB2 Tables Used: (if applicable)
  *   - <TABLE>: <description>
  *------------------------------------------------------------*/
```

### 7.2 IMS PL/I — Process Statement (MUST)

IMS PL/I programs MUST begin with:

```pli
*PROCESS SYSTEM(IMS);
```

### 7.3 Naming Conventions (MUST)

PL/I uses **underscores**, not hyphens:
- Host variables: `HV_<TABLE>_<COLUMN>` (e.g., `HV_CUST_SORTCODE`)
- Group levels: 1 and 5 (not 01/03 as in COBOL)
- Null indicators: `HV_<TABLE>_NULL_IND` group, fields `HV_<FIELD>_NULL`
- Constants: ALL_CAPS with underscores (e.g., `LOGINSUCCESSFUL`, `NO_MORE_MESSAGE`)

### 7.4 Data Types (MUST)

| Use case | PL/I type |
|----------|-----------|
| 32-bit integer | `FIXED BIN(31)` |
| 16-bit (null indicator) | `FIXED BIN(15)` |
| Packed decimal money | `FIXED DEC(10,2)` |
| Interest rate | `FIXED DEC(4,2)` |
| Character strings | `CHAR(<n>)` |

### 7.5 IMS PL/I — PROCEDURE Signature (MUST)

```pli
PROCNAME: PROCEDURE(IOPCB_PTR, DBPCB_PTR) OPTIONS(MAIN);
DCL PLITDLI ENTRY EXTERNAL;
DCL IOPCB_PTR POINTER;
DCL DBPCB_PTR POINTER;
```

### 7.6 Section Delimiters (MUST)

Use comment blocks to visually separate logical sections:

```pli
  /*------------------------------------------------------------*
  * CONSTANTS
  * ERROR MESSAGES & MESSAGE PROCESSING
  *------------------------------------------------------------*/
  ...
  /*---------------------------------------------------------*
  * DATABASE CALL CODES
  *----------------------------------------------------------*/
```

---

## 8. Code Era Notes

### CICS Programs (modern standard)

- Enterprise COBOL with `END-IF`, `END-EXEC`, `END-STRING`, `END-EVALUATE`
- No GO TO (except in error handling last-resort)
- No ALTER statement
- Structured error handling via RESP/RESP2, never `EXEC CICS HANDLE CONDITION`

### IMS Programs

- Use `PROGRAM-ID. "<NAME>" recursive.` when the program is re-entrant
- Java class interop via `REPOSITORY.` section (as in IBTRAN.cbl) is acceptable for hybrid programs
- `COMP-5` for binary IMS segment fields (platform-independent)

### Batch Programs

- `MAIN-PROCESS` as the top-level paragraph (no SECTION wrapper for main control)
- `STOP RUN` at the end of MAIN-PROCESS only; sub-paragraphs use `EXIT PARAGRAPH` for early exit
- `MOVE <rc> TO WS-RETURN-CODE` + `MOVE WS-RETURN-CODE TO RETURN-CODE` before `STOP RUN`

---

## Quick Reference: Standard Patterns Checklist

When generating or reviewing ANY COBOL program, verify:

- [ ] Copyright block before IDENTIFICATION DIVISION
- [ ] Description block after copyright
- [ ] `AUTHOR.` in IDENTIFICATION DIVISION
- [ ] `*SOURCE-COMPUTER.` commented out with `WITH DEBUGGING MODE`
- [ ] `WS-` prefix on all WORKING-STORAGE 01-levels
- [ ] CICS: `CBL CICS('SP,EDF')` as first line (no PROCESS statement)
- [ ] CICS: `WS-CICS-WORK-AREA` with level-05 `WS-CICS-RESP` and `WS-CICS-RESP2`
- [ ] CICS: `WS-ABEND-PGM VALUE 'ABNDPROC'` declared
- [ ] CICS: `ABNDINFO-REC` with `COPY ABNDINFO.`
- [ ] CICS: Date/time block (WS-U-TIME, WS-ORIG-DATE, WS-TIME-DATA) present
- [ ] CICS: Every EXEC CICS has `RESP(WS-CICS-RESP) RESP2(WS-CICS-RESP2)`
- [ ] CICS: Immediate `IF WS-CICS-RESP NOT = DFHRESP(NORMAL)` after every EXEC CICS
- [ ] CICS: `PREMIERE SECTION. A010.` as first section
- [ ] All sections end with `<XXX>999. EXIT.`
- [ ] DB2: `EXEC SQL INCLUDE` (not COPY) for table definitions and SQLCA
- [ ] DB2: Host variables grouped as `HOST-<TABLE>-ROW` with `HV-<TABLE>-` prefix
- [ ] IMS: `CBL LIST,MAP,XREF,FLAG(I)` as first line
- [ ] IMS: DL/I call codes as 77-levels
- [ ] IMS: `BAD-STATUS` area declared
- [ ] IMS: INPUT-AREA and OUTPUT-AREA start with LL/ZZ COMP fields
