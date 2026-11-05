---
name: bank-of-z-coding-standards
description: 'Enforces Bank of Z coding standards for COBOL (CICS, IMS, Batch), PL/I, and JCL. Discovered by automated codebase analysis of 20 representative files. Use when: "review code", "check standards", "generate code", "refactor code", "new COBOL program", "new JCL", "new PL/I", "does this follow our standards", "create a program", "write a program".'
metadata:
  author: Discovered by Bob Z Coding Standards Builder
  version: 1.0.0
  enforcement-level: moderate
  target-languages: COBOL, JCL, PL/I
  discovery-date: 2026-11-05
  confidence-threshold: 80%
---

# Bank of Z — Coding Standards

These standards were extracted from the actual Bank of Z codebase. Apply them whenever generating, reviewing, or modifying COBOL, PL/I, or JCL code in this repository.

---

## COBOL Standards

### Program Header (MUST — 100% adoption)

Every COBOL program begins with a copyright block of asterisks **before** the IDENTIFICATION DIVISION:

```cobol
      ******************************************************************
      *                                                                *
      *  Copyright IBM Corp. 2023                                      *
      *                                                                *
      ******************************************************************
      ******************************************************************
      * <One-paragraph description of the program purpose>
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROGNAME.
       AUTHOR. IBM Bank-of-Z.
```

- Description block: one block of `*` lines with free-text explaining the purpose
- `SOURCE-COMPUTER. IBM-Z.` and `OBJECT-COMPUTER. IBM-Z.` in CONFIGURATION SECTION (MUST — use `IBM-Z`, not `IBM-370`)
- `AUTHOR.` clause: use `IBM Bank-of-Z.`

### CICS Program Compiler Directives (MUST)

New CICS programs use only `CBL CICS(...)` on line 1 — **do not add** `PROCESS CICS,NODYNAM,...`:

```cobol
       CBL CICS('SP,EDF')
```

If the program also uses DB2:
```cobol
       CBL CICS('SP,EDF')
       CBL SQL
```

If the program uses both CICS and IMS DL/I:
```cobol
       CBL CICS('SP,EDF,DLI')
```

IMS-only batch programs use:
```cobol
       CBL LIST,MAP,XREF,FLAG(I)
```

Batch COBOL programs (no subsystem) have **no** CBL directive on line 1.

### WORKING-STORAGE vs LOCAL-STORAGE (SHOULD — 80% adoption)

For CICS programs with re-entrant requirements:

- **WORKING-STORAGE**: shared/static data only — `WS-CICS-WORK-AREA`, `WS-ABEND-PGM`, `ABNDINFO-REC`, copybooks for DB2 host variable structures, `SORTCODE` copybook
- **LOCAL-STORAGE**: all instance-level variables (keys, flags, work areas, counters) — re-entrant safe

For IMS and batch COBOL: use only WORKING-STORAGE.

### Naming Conventions (MUST — 100% adoption)

| Prefix | Usage | Example |
|--------|-------|---------|
| `WS-` | General working storage variables | `WS-CICS-RESP`, `WS-EOF-SW` |
| `HV-` | DB2 host variables (COBOL) | `HV-CUSTOMER-NUMBER`, `HV-ACCOUNT-SORTCODE` |
| `NI-` | DB2 null indicators | `NI-TITLE`, `NI-DOB` |
| `HV_` | DB2 host variables (PL/I) | `HV_CUST_NUMBER`, `HV_ACCT_SORTCODE` |
| No prefix | IMS segment areas, SSAs, PCB structures | `CUSTOMER-SEG`, `CUSTOMER-SSA1` |

- Paragraph/section names: VERB-NOUN format, all uppercase, hyphenated (`SECURITY-CHECK`, `WRITE-CUSTOMER-DB2`, `GET-ME-OUT-OF-HERE`)
- 88-level condition names: all uppercase, hyphenated, named for the true state (`SEC-OK`, `WS-EOF`, `DATASTORE-TYPE-DB2`)

### 88-Level Boolean Pattern (MUST — 100% adoption)

Use 88-levels for all boolean flags and switches. Group under named 01-level:

```cobol
       01 SWITCHES.
           03 VALID-DATA-SW        PIC X VALUE 'Y'.
              88 VALID-DATA             VALUE 'Y'.

       01 FLAGS.
           03 SEND-FLAG            PIC X.
              88 SEND-ERASE             VALUE '1'.
              88 SEND-DATAONLY          VALUE '2'.
              88 SEND-DATAONLY-ALARM    VALUE '3'.
```

For simple single-field booleans (outside a SWITCHES group):
```cobol
       01 WS-SEC-SW                PIC X VALUE 'N'.
           88 SEC-OK                   VALUE 'Y'.
           88 SEC-NOT-OK               VALUE 'N'.
```

### CICS RESP Handling (MUST — 100% adoption)

Always declare in WORKING-STORAGE (CICS programs):
```cobol
       01 WS-CICS-WORK-AREA.
           05 WS-CICS-RESP         PIC S9(8) COMP.
           05 WS-CICS-RESP2        PIC S9(8) COMP.
```

Every EXEC CICS command that can fail must specify `RESP` and `RESP2`, checked immediately after:
```cobol
           EXEC CICS LINK PROGRAM('BNKSECCK')
                COMMAREA(BNKSEC-COMMAREA)
                LENGTH(LENGTH OF BNKSEC-COMMAREA)
                RESP(WS-CICS-RESP)
                RESP2(WS-CICS-RESP2)
           END-EXEC.

           IF WS-CICS-RESP NOT = DFHRESP(NORMAL)
              ...error handling...
           END-IF.
```

When handling a CICS error that leads to ABEND, always populate `ABNDINFO-REC` fully before linking to `ABNDPROC`:
```cobol
               INITIALIZE ABNDINFO-REC
               MOVE EIBRESP    TO ABND-RESPCODE
               MOVE EIBRESP2   TO ABND-RESP2CODE
               EXEC CICS ASSIGN APPLID(ABND-APPLID) END-EXEC
               MOVE EIBTASKN   TO ABND-TASKNO-KEY
               MOVE EIBTRNID   TO ABND-TRANID
               PERFORM POPULATE-TIME-DATE
               MOVE WS-ORIG-DATE TO ABND-DATE
               ...populate ABND-TIME, ABND-UTIME-KEY, ABND-CODE, ABND-PROGRAM, ABND-FREEFORM...
               EXEC CICS LINK PROGRAM(WS-ABEND-PGM)
                      COMMAREA(ABNDINFO-REC)
               END-EXEC
               EXEC CICS ABEND ABCODE('XXXX') CANCEL END-EXEC
```

### CICS Security Check Pattern (MUST — every program that touches data)

```cobol
       01 BNKSEC-COMMAREA.
           COPY BNKSEC.
       01 WS-SEC-SW                PIC X VALUE 'N'.
           88 SEC-OK                   VALUE 'Y'.
           88 SEC-NOT-OK               VALUE 'N'.
```

In PREMIERE section, always first action:
```cobol
           PERFORM SECURITY-CHECK.
           IF SEC-NOT-OK
              PERFORM GET-ME-OUT-OF-HERE
           END-IF.
```

Followed immediately by:
```cobol
           EXEC CICS HANDLE ABEND
              LABEL(ABEND-HANDLING)
           END-EXEC.
```

### CICS ABEND Handling Section (MUST)

Every CICS program with data access must have an `ABEND-HANDLING` section that:
1. Reads abend code: `EXEC CICS ASSIGN ABCODE(MY-ABEND-CODE) END-EXEC`
2. Uses `EVALUATE MY-ABEND-CODE` to handle specific codes (`AD2Z`, `AFCR`, `AFCS`, `AFCT`)
3. If not a storm-drain case: re-abends with `EXEC CICS ABEND ABCODE(MY-ABEND-CODE) NODUMP CANCEL END-EXEC`

Also declare:
```cobol
       01 WS-ABEND-PGM             PIC X(8) VALUE 'ABNDPROC'.
       01 ABNDINFO-REC.
           COPY ABNDINFO.
```

### CICS Exit Pattern (MUST — 100% adoption)

All CICS programs exit via a dedicated section:
```cobol
       GET-ME-OUT-OF-HERE SECTION.
       GMOFH010.
           EXEC CICS RETURN
           END-EXEC.

       GMOFH999.
           EXIT.
```

The last paragraph of every section is always `XYZ999.` with `EXIT.` — no code after EXIT.

### Procedure Division SECTION Structure (MUST)

Procedure Division is organized into SECTIONs, not flat paragraphs:
- Entry section always named `PREMIERE SECTION`
- First paragraph in each section: `VERB010.` or `A010.`
- Last paragraph in each section: `VERB999.` with `EXIT.`
- Use `PERFORM <SECTION-NAME>` to call sections (not paragraph ranges)

### Date/Time Standard Variables (SHOULD — 90% adoption)

Declare this block in every CICS program that needs timestamp for ABEND record:
```cobol
       01 WS-U-TIME                PIC S9(15) COMP-3.
       01 WS-ORIG-DATE             PIC X(10).
       01 WS-ORIG-DATE-GRP REDEFINES WS-ORIG-DATE.
           03 WS-ORIG-DATE-DD      PIC 99.
           03 FILLER               PIC X.
           03 WS-ORIG-DATE-MM      PIC 99.
           03 FILLER               PIC X.
           03 WS-ORIG-DATE-YYYY    PIC 9999.
       01 WS-ORIG-DATE-GRP-X.
           03 WS-ORIG-DATE-DD-X    PIC XX.
           03 FILLER               PIC X VALUE '.'.
           03 WS-ORIG-DATE-MM-X    PIC XX.
           03 FILLER               PIC X VALUE '.'.
           03 WS-ORIG-DATE-YYYY-X  PIC X(4).
       01 WS-TIME-DATA.
           03 WS-TIME-NOW          PIC 9(6).
           03 WS-TIME-NOW-GRP REDEFINES WS-TIME-NOW.
              05 WS-TIME-NOW-GRP-HH   PIC 99.
              05 WS-TIME-NOW-GRP-MM   PIC 99.
              05 WS-TIME-NOW-GRP-SS   PIC 99.
```

With `POPULATE-TIME-DATE` section using `EXEC CICS ASKTIME` + `EXEC CICS FORMATTIME DDMMYYYY(WS-ORIG-DATE)`.

### LINKAGE SECTION — DFHCOMMAREA (MUST for CICS programs)

```cobol
       LINKAGE SECTION.
       01 DFHCOMMAREA.
           COPY <COMMAREA-COPYBOOK>.

       PROCEDURE DIVISION USING DFHCOMMAREA.
```

### DB2 Host Variable Naming (MUST — 100% adoption)

Host variables grouped under a named 01-level, prefixed with the table abbreviation:
```cobol
       01 HOST-CUSTOMER-ROW.
           03 HV-CUSTOMER-EYECATCHER    PIC X(4).
           03 HV-CUSTOMER-SORTCODE      PIC X(6).
           03 HV-CUSTOMER-NUMBER        PIC X(10).
           ...
```

Pattern: `01 HOST-<TABLE>-ROW.` → `03 HV-<TABLE>-<FIELD>`.

Every table row structure has an `EYE-CATCHER` field as first element (PIC X(4)) — used for validation.

### IMS COBOL Conventions (MUST for IMS programs)

1. DL/I function codes declared as 77-level constants:
```cobol
       77  GU     PIC X(04) VALUE "GU  ".
       77  GHU    PIC X(04) VALUE "GHU ".
       77  GN     PIC X(04) VALUE "GN  ".
       77  ISRT   PIC X(04) VALUE "ISRT".
       77  REPL   PIC X(04) VALUE "REPL".
       77  GE     PIC X(02) VALUE "GE".
       77  GB     PIC X(02) VALUE "GB".
```

2. Error status area:
```cobol
       01  BAD-STATUS.
           05  SC-MSG  PIC X(30) VALUE "BAD STATUS CODE WAS RECEIVED: ".
           05  SC      PIC X(2).
```

3. PCBs declared in LINKAGE SECTION as POINTER, then mapped via SET ADDRESS:
```cobol
       LINKAGE SECTION.
       01  IOPCBA POINTER.
       01  DBPCB1 POINTER.
       ...
       PROCEDURE DIVISION.
             ENTRY "DLITCBL"
             USING IOPCBA, DBPCB1.
```

4. Check `DBSTAT = SPACES` (success), `GE` / `GB` (end of data), else `BAD-STATUS`.

### Batch COBOL — Return Codes (SHOULD — 100% in batch programs)

Document all return codes in the header comment block:
```
*  Return codes:
*    0  = Successful execution
*    4  = Warning condition
*    8  = I/O error
*   12  = DB2 error (negative SQLCODE)
```

DB2 Null indicators declared as `PIC S9(4) COMP-5` under a group `01 NULL-INDICATORS`.

### Formatting (MUST)

- COBOL indentation: 1 space per level (configured in `zcodeformat.yaml`)
- Copybook code: always UPPERCASE
- Comments: dedicated line starting with `*` in column 7, never inline after code
- Separate logical blocks with blank comment lines (`*` alone or blank line above/below paragraph names)

---

## JCL Standards

### Job Card (MUST — 100% adoption)

```jcl
//JOBNAME  JOB 'Description',NOTIFY=&SYSUID,CLASS=A,
//          MSGCLASS=H,MSGLEVEL=(1,1),REGION=4M
```

Always add `REGION=` (typically 4M or 144M for larger jobs).

### HLQ Parametrization (MUST — 100% adoption)

Always parametrize the HLQ on the first non-comment line after the job card:
```jcl
//    SET HLQ='RAFAELT'                       *TSO USER ID
```

Never hardcode HLQs directly in DD statements — always use `&HLQ..DATASET`.

### JCL Header Comment Block (MUST)

```jcl
//*=============================================================
//* JOB:  PROGNAME
//* DESC: Brief description in Portuguese
//* PROG: PROGNAME
//* SAIDA: HLQ.OUTPUT.DATASET
//*        RECFM=FB  LRECL=nnn
//*
//* CODIGOS DE RETORNO:
//*   RC= 0  ...
//*   RC= 4  ...
//*   RC= 8  ...
//*   RC=12  ...
//*=============================================================
```

### Standard DD Names (SHOULD)

| DD Name | Purpose |
|---------|---------|
| `STEPLIB` | Load library |
| `SYSOUT` | SYSOUT=* |
| `SYSUDUMP` | SYSOUT=* (core dumps) |
| `SYSPRINT` | Utility/compiler output |
| `SYSTSPRT` | TSO print output |

---

## PL/I Standards

### Program Header (MUST)

```pli
  /*------------------------------------------------------------*
   * Licensed Materials - Property of IBM
   *
   * (c) Copyright IBM Corp. YYYY.
   *------------------------------------------------------------*/

  /*------------------------------------------------------------*
  * Procedure: PROGNAME
  * Description: Brief description
  * Input:  ...
  * Output: ...
  * DB2 Tables Used: (if applicable)
  *------------------------------------------------------------*/

  PROGNAME: PROCEDURE OPTIONS(MAIN);
```

### Naming Conventions (MUST)

- Host variables: `HV_` prefix with UNDERSCORE (not hyphen), grouped in `DCL 1 HV_<TABLE>` structures
- Null indicators: `HV_<TABLE>_NULL_IND` group with `HV_<FIELD>_NULL FIXED BIN(15)` members
- Working variables: all UPPERCASE, underscore-separated (`TRANS_COUNT`, `END_OF_DATA`)
- Subroutines: `VERB_NOUN` pattern with underscores, declared as nested `PROCEDURE`

### PL/I Error Handling (SHOULD)

Use `ON ENDFILE(<file>)` and `ON ERROR` conditions, not simple IF checks for file I/O:
```pli
   ON ENDFILE(SORTCODE)
     BEGIN;
       PUT SKIP LIST('SORTCODE FILE NOT FOUND - USING DEFAULT');
       ...fallback logic...
       GO TO LABEL;
     END;
```

### PL/I SQL Cursor Pattern (MUST for DB2 programs)

```pli
   EXEC SQL DECLARE CURSOR_NAME CURSOR FOR
     SELECT ...
     FROM TABLE
     WHERE ... = :HV_FIELD
     ORDER BY ...;
```

---

## Cross-Cutting Rules

### SORTCODE Copybook (MUST for all CICS programs)

`COPY SORTCODE.` is the first statement in WORKING-STORAGE of every CICS program. It provides the bank sort code constant used throughout the application.

### Eye-Catcher Fields (MUST for all data structures)

Every DB2 table row structure (both COBOL and PL/I) has a 4-byte eye-catcher as its first field:
- COBOL: `HV-<TABLE>-EYECATCHER PIC X(4)`
- PL/I: `HV_<TABLE>_EYECATCHER CHAR(4)`

The copybook versions define the valid value: e.g., `88 ACCOUNT-EYECATCHER-VALUE VALUE 'ACCT'.`

### Copybook Locations (MUST)

- CICS copybooks: `src/base/cics/copy/*.cpy`
- IMS copybooks: `src/base/ims/copy/*.cpy`
- Do NOT place copybooks in program directories
- Generated API copybooks: `src/api/src/main/zosAssets/<PROGNAME>/providerFiles/gen/` — never edit manually

### Documentation Sync (MUST)

After modifying any COBOL program:
1. Check `.bobz/specs/<PROGNAME>-technical-spec.md` — if it exists, flag for update
2. Check `docs/program/src/base/cics/cobol/<PROGNAME>.md` — if it exists, update accordingly
3. Specs are written in **Portuguese**
