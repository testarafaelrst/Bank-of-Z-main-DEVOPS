# Z Language Patterns — Bank of Z

Detection rules, idioms, and subsystem identification patterns for IBM Z languages in this codebase.

---

## Subsystem Detection

### CICS Program
Any file containing:
- `CBL CICS(` on line 1
- `EXEC CICS` anywhere in body
- `DFHCOMMAREA` in LINKAGE SECTION
- `WS-CICS-WORK-AREA` in WORKING-STORAGE

### IMS Program (Online — MPP)
Any file containing:
- `CBL LIST,MAP,XREF,FLAG(I)` on line 1
- `CALL 'CBLTDLI'`
- `ENTRY "DLITCBL"`
- `IOPCBA POINTER` in LINKAGE SECTION

### IMS Program (Batch — BMP/DLB)
Any file containing:
- `CALL 'CBLTDLI'` AND file I/O (SELECT ... ASSIGN)
- No `EXEC CICS`

### DB2 Program
Any file containing:
- `EXEC SQL`
- `SQLCA` or `INCLUDE SQLCA`

### Batch (No Subsystem)
Any file containing:
- No `EXEC CICS`, no `CALL 'CBLTDLI'`, no `EXEC SQL`
- `STOP RUN` in PROCEDURE DIVISION
- Typically has `FILE SECTION` with SELECT/FD

### PL/I (Batch with DB2)
Any file containing:
- `PROCEDURE OPTIONS(MAIN)` (not `PROGRAM-ID.`)
- `EXEC SQL` in PL/I syntax (without COBOL EXEC spacing)

---

## COBOL Idioms Specific to Bank of Z

### Eyecatcher Pattern
```cobol
05 ACCOUNT-EYE-CATCHER    PIC X(4).
88 ACCOUNT-EYECATCHER-VALUE   VALUE 'ACCT'.
```
Every DB2 row structure in this codebase has a 4-byte eyecatcher as the first field. Valid values: `'ACCT'`, `'CUST'`, `'PRTR'` (PROCTRAN).

### Named Counter (NCS) Pattern
Used in CREACC and CRECUST for generating unique account/customer numbers via CICS Named Counter Service:
```cobol
01 NCS-CUST-NO-STUFF.
   03 NCS-CUST-NO-NAME.
      05 FILLER   PIC X(16) VALUE 'CUST_NO         '.
   03 NCS-CUST-NO-INC   PIC 9(16) COMP VALUE 0.
   03 NCS-CUST-NO-VALUE PIC 9(16) COMP VALUE 0.
   03 NCS-CUST-NO-RESP  PIC XX VALUE '00'.
```
Operations: `EXEC CICS ENQ` → `EXEC CICS GET COUNTER` → increment → `EXEC CICS DEQ`.

### Storm Drain Pattern
VSAM RLS abends (AFCR, AFCS, AFCT) are intercepted and handled as "storm drain" conditions — the program issues SYNCPOINT ROLLBACK and returns gracefully instead of hard-abending. Indicates CPSM WLM integration.

### COMM-SUCCESS / COMM-FAIL-CODE Pattern
Every CICS program that can be called via COMMAREA returns results through:
```cobol
MOVE 'Y' TO COMM-SUCCESS    (or 'N' on failure)
MOVE '0' TO COMM-FAIL-CODE  (or specific code on failure)
```
Failure codes: `'0'`=success, `'1'`=data error, `'2'`=datastore error, `'S'`=security denied, `'X'`=security unavailable.

### SORTCODE Copybook
`COPY SORTCODE.` provides the bank sort code as a numeric constant used throughout the application for all DB2 queries and IMS lookups. First statement in WORKING-STORAGE of every CICS program.

### PROCTRAN (Processed Transaction) Table
Every financial operation (debit, credit, transfer, account create) writes a record to PROCTRAN. Host variable structure: `01 HOST-PROCTRAN-ROW.` with `HV-PROCTRAN-*` fields. The `COPY PROCTRAN.` copybook provides the data structure for VSAM-based PROCTRAN access; `EXEC SQL INCLUDE PROCDB2` for DB2 access.

---

## Code Era Indicators

### Enterprise COBOL (modern — use for new code)
- `END-IF`, `END-EXEC`, `END-STRING`, `END-EVALUATE` scope terminators
- `EVALUATE TRUE WHEN ... END-EVALUATE`
- `FUNCTION` built-ins: `FUNCTION NUMVAL(...)`, `FUNCTION CURRENT-DATE`
- `LENGTH OF <data-name>` (not numeric literal)
- `PERFORM ... VARYING ... UNTIL ...` with in-line body
- `LOCAL-STORAGE SECTION`
- `EXEC CICS CHANNELS` (CRECUST uses async child tasks)

### Legacy indicators (do not replicate)
- `PROCESS CICS,NODYNAM,NSYMBOL(NATIONAL),TRUNC(STD)` on line 1
- `SOURCE-COMPUTER. IBM-370.` (use `IBM-Z` instead)
- `AUTHOR. Jon Collett.` (original developer, replaced by `IBM Bank-of-Z.`)
- `77` level items in WORKING-STORAGE (use `01` instead for new work)
- `GO TO` in main logic (acceptable only for `GO TO SC999` / `GO TO AH999` exit jumps)

---

## IMS DL/I Function Codes Reference

| Variable | Value | Operation |
|----------|-------|-----------|
| `GU` | `"GU  "` | Get Unique (exact key) |
| `GHU` | `"GHU "` | Get Hold Unique (for update) |
| `GN` | `"GN  "` | Get Next (sequential) |
| `GHN` | `"GHN "` | Get Hold Next (for update) |
| `ISRT` | `"ISRT"` | Insert |
| `REPL` | `"REPL"` | Replace (update held segment) |

| Status | Value | Meaning |
|--------|-------|---------|
| `GE` | `"GE"` | Get End — not found |
| `GB` | `"GB"` | Get Next reached end of database |
| Spaces | `"  "` | Success |

---

## DB2 SQLCODE Reference (used in this codebase)

| SQLCODE | Meaning in context |
|---------|--------------------|
| `0` | Success |
| `+100` | End of result set (FETCH) / Row not found |
| `-811` | More than one row returned by singleton SELECT |
| `-803` | Duplicate key on INSERT |
| `-904` | Resource unavailable (lock timeout) |
| `-911` / `-913` | Deadlock / timeout → triggers `AD2Z` abend in CICS |

---

## CICS ABEND Codes Reference (specific to Bank of Z)

| Code | Issued by | Meaning |
|------|-----------|---------|
| `HBNK` | BNKMENU | EXEC CICS RETURN failed |
| `HROL` | DBCRFUN, XFRFUN | SYNCPOINT ROLLBACK failed after VSAM RLS abend |
| `AD2Z` | DB2 | DB2 deadlock — intercepted in ABEND-HANDLING |
| `AFCR`/`AFCS`/`AFCT` | VSAM RLS | VSAM RLS abend — storm drain candidate |

---

## Copybook Naming Conventions

| Copybook | Purpose | Used in |
|----------|---------|---------|
| `SORTCODE` | Bank sort code constant | All CICS programs (WS) |
| `BNKSEC` | Security COMMAREA for BNKSECCK | All CICS data programs |
| `ABNDINFO` | Abend info record for ABNDPROC | All CICS programs |
| `ACCOUNT` | ACCOUNT data structure | INQACC, UPDACC, DELACC, etc. |
| `CUSTOMER` | CUSTOMER data structure | INQCUST, CRECUST, UPDCUST, etc. |
| `PROCTRAN` | PROCTRAN record for VSAM access | Transaction programs |
| `ACCDB2` | ACCOUNT DB2 include | CICS programs with DB2 |
| `PROCDB2` | PROCTRAN DB2 include | CICS programs with DB2 |
| `CUSTDB2` | CUSTOMER DB2 include | LSTCUST, INQCUST |
| `DFHAID` | CICS AID key constants | BMS programs (BNK1*, BNKMENU) |
| `CEEIGZCT` | LE condition token | CRECUST (CEEDAYS date conversion) |
| `CUSTCTRL` | Customer control copybook | CRECUST |

---

## BMS Programs (CICS Screen Programs)

Programs that interact with BMS maps follow an additional pattern:
1. Line 1: `PROCESS CICS,NODYNAM,NSYMBOL(NATIONAL),TRUNC(STD)` (legacy, keep as-is)
2. `COPY DFHAID.` in WORKING-STORAGE for PF key constants
3. `COPY BNK1Mxx.` for map field definitions (generated by BMS compiler)
4. `EIBAID` checked against `DFHENTER`, `DFHPF3`, `DFHPF12`, `DFHCLEAR`, `DFHPA1/2/3`
5. `EIBCALEN = ZERO` checked to detect first invocation
6. `SET SEND-ERASE/SEND-DATAONLY/SEND-DATAONLY-ALARM TO TRUE` before `PERFORM SEND-MAP`

BMS programs in this codebase: `BNKMENU`, `BNK1CAC`, `BNK1CCA`, `BNK1CCS`, `BNK1CRA`, `BNK1DAC`, `BNK1DCS`, `BNK1TFN`, `BNK1UAC`.

---

## CICS Transaction Flow

```
OMEN → BNKMENU → (user selects option)
         ↓
  BNK1xxx (BMS screen program)
         ↓
  CRECUSt / INQCUST / UPDCUST / DELCUS  (customer operations)
  CREACC / INQACC / UPDACC / DELACC     (account operations)
  DBCRFUN / XFRFUN                       (financial transactions)
         ↓
  BNKSECCK (security check, called via LINK by every data program)
         ↓
  ABNDPROC (abend processor, called on CICS error or ABEND)
```
