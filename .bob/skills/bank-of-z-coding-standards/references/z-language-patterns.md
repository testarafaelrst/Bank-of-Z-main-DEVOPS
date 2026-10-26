# Z Language Patterns — Bank of Z

Pattern detection rules and language-specific knowledge for working with the Bank of Z codebase.

---

## Subsystem Detection

Use these indicators to identify what subsystem a COBOL program uses:

| Indicator | Subsystem |
|-----------|-----------|
| `CBL CICS(...)` or `EXEC CICS` | CICS |
| `CBL LIST,MAP,XREF,FLAG(I)` + `GU`/`GN` 77-levels | IMS |
| `CBL SQL` or `EXEC SQL` | DB2 |
| `CBL CICS('SP,EDF,DLI')` | CICS + IMS (hybrid) |
| Neither CICS nor IMS | Batch |
| `DFHCOMMAREA` in LINKAGE SECTION | CICS |
| `IOPCBA POINTER` in LINKAGE SECTION | IMS |

---

## Code Era Detection for this Project

| Feature observed | Era |
|-----------------|-----|
| `END-IF`, `END-EXEC`, `END-EVALUATE`, inline PERFORM | Enterprise COBOL (modern, standard) |
| `EXEC CICS HANDLE ABEND LABEL(...)` | Older style — seen in INQCUST, avoid in new code |
| `PROGRAM-ID. "NAME" recursive.` | Java-interop IMS programs (IBTRAN, IBLOGIN1) |
| `COMP-5` for IMS binary fields | Modern IMS convention for platform-independence |
| `FREE FORMAT PL/I` syntax | Modern PL/I (BNKSTMT.pli, IBLOGIN.pli) |

---

## COBOL Data Type Quick Reference

| Usage | COBOL Picture |
|-------|--------------|
| CICS RESP/RESP2 | `PIC S9(8) COMP` |
| Packed decimal time | `PIC S9(15) COMP-3` |
| Packed decimal money | `PIC S9(10)V99 COMP-3` |
| Packed decimal rate | `PIC S9(4)V99 COMP-3` |
| DB2 integer (null ind) | `PIC S9(4) COMP` (CICS) or `PIC S9(4) COMP-5` (Batch) |
| IMS binary segment field | `PIC S9(9) COMP-5` or `PIC S9(18) COMP-5` |
| Binary counter | `PIC S9(8) COMP` or `PIC S9(4) COMP` |
| Customer number | `PIC 9(10) DISPLAY` |
| Sort code | `PIC 9(6) DISPLAY` |
| Account number | `PIC 9(8)` or `PIC X(8)` (depending on context) |
| Date stored as integer (YYYYMMDD) | `PIC S9(9) COMP` (CICS) or `PIC S9(9) COMP-5` (Batch) |
| Date for display | `PIC X(10)` |
| Program name | `PIC X(8)` |
| CICS transaction ID | `PIC X(4)` |

---

## IMS Segment Field Types

| Usage | COBOL type |
|-------|-----------|
| 32-bit customer/account ID | `PIC S9(9) COMP-5` |
| 64-bit transaction ID | `PIC S9(18) COMP-5` |
| Balance (packed) | `PIC S9(13)V9(2) COMP-3` |
| Account type | `PIC X(01)` |
| Timestamp | `PIC X(23)` |

---

## JCL Dataset Naming Conventions

Observed pattern for Bank of Z datasets:

```
<USER_HLQ>.BANK.<PURPOSE>.<QUALIFIER>
```

Examples:
- `RAFAELT.BANK.LSTCUST.REPORT` — report output
- `BANKZ.V0R1M0.LOAD` — application load library
- `BANKZ.V0R1M0.DBRMLIB` — DBRM library
- `<HLQ>.BANKZ.OBJ` — object library

DB2 system libraries pattern: `DB2V13.SDSNEXIT`, `DB2V13.SDSNLOAD`

---

## DB2 Table Name Mapping

COBOL column names map to DB2 table names with underscores replacing hyphens:

| COBOL copybook field | DB2 column name |
|---------------------|----------------|
| `CUSTOMER-EYECATCHER` | `CUSTOMER_EYECATCHER` |
| `CUSTOMER-SORTCODE` | `CUSTOMER_SORTCODE` |
| `CUSTOMER-NUMBER` | `CUSTOMER_NUMBER` |
| `ACCOUNT-AVAIL-BAL` | `ACCOUNT_AVAILABLE_BALANCE` |
| `HV-CUSTOMER-CS-REVIEW-DATE` | `CUSTOMER_CS_REVIEW_DATE` |

Always check the `EXEC SQL INCLUDE <TABLE>DB2 END-EXEC` copybook for the actual column names before writing SQL.

---

## CICS Transaction IDs (observed in codebase)

| Transaction | Program |
|-------------|---------|
| `OMEN` | BNKMENU (main menu) |
| `ODCS` | Customer display |
| `ODAC` | Account display |

---

## Program Communication Patterns

### CICS LINK (synchronous sub-program call)

```cobol
       EXEC CICS LINK PROGRAM(WS-ABEND-PGM)
                 COMMAREA(ABNDINFO-REC)
       END-EXEC
```

### CICS RETURN with TRANSID (pseudo-conversational)

```cobol
       EXEC CICS
          RETURN TRANSID('OMEN')
          COMMAREA(COMMUNICATION-AREA)
          LENGTH(1)
          RESP(WS-CICS-RESP)
          RESP2(WS-CICS-RESP2)
       END-EXEC.
```

### CICS Async (child task) — used in CRECUST for credit agency calls

CRECUST.cbl uses `EXEC CICS RUN ACQACTIVITY` and channel-based communication for async credit scoring. See CRECUST.cbl for the full pattern using `WS-CHILD-ARRAY` and `WS-CHILD-TOKENS`.

---

## Abend Handler: ABNDPROC

`ABNDPROC` is the centralized abend handler for the entire CICS application:
- All CICS programs that encounter an error LINK to `ABNDPROC` via `EXEC CICS LINK PROGRAM(WS-ABEND-PGM) COMMAREA(ABNDINFO-REC)`
- The ABNDINFO-REC copybook (`src/base/cics/copy/ABNDINFO.cpy`) defines the structure
- Fields populated before LINK: ABND-RESPCODE, ABND-RESP2CODE, ABND-APPLID, ABND-TASKNO-KEY, ABND-TRANID, ABND-DATE, ABND-TIME, ABND-UTIME-KEY, ABND-CODE ('HBNK'), ABND-PROGRAM, ABND-SQLCODE, ABND-FREEFORM (free-text diagnostic)

---

## PL/I Type Quick Reference

| Usage | PL/I type |
|-------|----------|
| 32-bit integer | `FIXED BIN(31)` |
| Null indicator | `FIXED BIN(15)` |
| Packed decimal money | `FIXED DEC(10,2)` |
| Interest rate | `FIXED DEC(4,2)` |
| Character | `CHAR(n)` |
| Pointer to PCB | `POINTER` |

---

## Common COBOL Idioms in this Project

### "Storm Drain" — re-entry guard (INQCUST only)

```cobol
       01 WS-STORM-DRAIN               PIC X VALUE 'N'.
       01 STORM-DRAIN-CONDITION        PIC X(20).
```
Used to prevent recursive abend handling. Not in all programs — only copy if you understand the pattern.

### Named Counter Server (NCS) — Customer number generation

```cobol
       01 NCS-CUST-NO-STUFF.
          03 NCS-CUST-NO-NAME.
             05 NCS-CUST-NO-ACT-NAME   PIC X(9) VALUE 'BANKZCUST'.
             05 NCS-CUST-NO-TEST-SORT  PIC X(6) VALUE '      '.
             05 NCS-CUST-NO-FILL       PIC XX VALUE '  '.
          03 NCS-CUST-NO-INC           PIC 9(16) COMP VALUE 0.
          03 NCS-CUST-NO-VALUE         PIC 9(16) COMP VALUE 0.
          03 NCS-CUST-NO-RESP          PIC XX VALUE '00'.
```
Used in INQCUST and CRECUST to get the last-used customer number from a CICS Named Counter.

### SORTCODE — Bank sort code

```cobol
       LOCAL-STORAGE SECTION.
       COPY SORTCODE.
```
The sort code is a constant defined in the `SORTCODE` copybook (`src/base/cics/copy/SORTCODE.cpy`). Copy it into LOCAL-STORAGE (not WORKING-STORAGE) in CICS programs that need it, to ensure thread safety.

### DATA-STORE-TYPE — Multi-backend dispatcher

```cobol
       01 DATA-STORE-TYPE               PIC X.
          88 DATASTORE-TYPE-DLI                       VALUE '1'.
          88 DATASTORE-TYPE-DB2                       VALUE '2'.
          88 DATASTORE-TYPE-VSAM                      VALUE 'V'.
```
Used in DBCRFUN, ABNDPROC, and other programs to dispatch to the correct backend datastore (IMS DL/I, DB2, or VSAM).
