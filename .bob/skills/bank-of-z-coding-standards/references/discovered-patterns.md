# Discovered Patterns — Bank of Z Coding Standards

**Analysis date:** 2025-07-14
**Files analyzed:** 20
**Languages:** COBOL CICS (11), COBOL IMS (4), COBOL Batch (1), COBOL Copybooks (4), PL/I (2), JCL (3)

---

## Pattern Statistics by Category

### COBOL — General

| Pattern | Files Matching | Confidence |
|---------|---------------|------------|
| Copyright block before IDENTIFICATION DIVISION | 16/16 | 100% |
| `AUTHOR.` in IDENTIFICATION DIVISION | 11/11 CICS | 100% |
| `*SOURCE-COMPUTER. IBM-370 WITH DEBUGGING MODE.` commented | 10/11 CICS | 91% |
| `SOURCE-COMPUTER. IBM-370.` + `OBJECT-COMPUTER. IBM-370.` | 11/11 CICS | 100% |
| `WS-` prefix on WORKING-STORAGE 01-levels | 12/12 | 100% |
| `HV-<TABLE>-` prefix on DB2 host variables | 5/5 DB2 | 100% |
| `NI-` prefix on DB2 null indicators | 3/5 DB2 | 60% |
| `SWITCHES` and `FLAGS` as named 01-levels | 9/11 CICS | 82% |
| `LOCAL-STORAGE SECTION` for re-entrant locals | 7/11 CICS | 64% |
| Date/time standard block (WS-U-TIME, WS-ORIG-DATE…) | 9/11 CICS | 82% |
| `WS-ABEND-PGM PIC X(8) VALUE 'ABNDPROC'` | 9/11 CICS | 82% |
| `ABNDINFO-REC. COPY ABNDINFO.` | 9/11 CICS | 82% |
| VERB-NOUN section naming | 11/11 CICS | 100% |
| `<XXX>010` opening paragraph + `<XXX>999. EXIT.` | 11/11 CICS | 100% |
| `PREMIERE SECTION. A010.` as main entry | 9/11 CICS | 82% |
| Inline comment above PERFORM | 11/11 CICS | 100% |

### COBOL CICS

| Pattern | Files Matching | Confidence |
|---------|---------------|------------|
| `CBL CICS('SP,EDF')` on line 1 | 11/11 | 100% |
| `CBL SQL` when DB2 used | 6/6 | 100% |
| `PROCESS CICS,...` NOT present (resolved conflict) | — | User confirmed |
| `WS-CICS-WORK-AREA` with level-05 fields | 8/11 | 73% |
| `RESP(WS-CICS-RESP) RESP2(WS-CICS-RESP2)` on every EXEC CICS | 11/11 | 100% |
| Immediate RESP check after every EXEC CICS | 11/11 | 100% |
| Standard abend block with ABNDINFO-REC + LINK ABNDPROC | 9/11 | 82% |
| `WS-FAIL-INFO` declared with embedded program name | 8/11 | 73% |

### COBOL IMS

| Pattern | Files Matching | Confidence |
|---------|---------------|------------|
| `CBL LIST,MAP,XREF,FLAG(I)` on line 1 | 4/4 | 100% |
| DL/I call codes as 77-levels (GU, GHU, GN, GHN, ISRT, REPL) | 4/4 | 100% |
| IMS status codes as 77-levels (GE, GB) | 4/4 | 100% |
| `BAD-STATUS` with `SC-MSG` + `SC` | 4/4 | 100% |
| INPUT-AREA starts with LL-IN + ZZ-IN (COMP, 4-byte) | 4/4 | 100% |
| OUTPUT-AREA starts with LL-OUT + ZZ-OUT | 4/4 | 100% |
| SSAs as 01-levels with FILLER text fields | 4/4 | 100% |
| LINKAGE SECTION with IOPCBA + DBPCB1 POINTER | 3/4 | 75% |

### DB2 Patterns

| Pattern | Files Matching | Confidence |
|---------|---------------|------------|
| `EXEC SQL INCLUDE` not `COPY` | 5/5 | 100% |
| SQLCA included last among DB2 includes | 5/5 | 100% |
| `HOST-<TABLE>-ROW` as 01-level group name | 5/5 | 100% |
| SQL columns each on own line | 4/5 | 80% |
| `FOR FETCH ONLY` on all read cursors | 3/3 | 100% |
| First-FETCH-before-loop pattern (batch) | 1/1 batch | 100% |
| EXEC SQL BEGIN/END DECLARE SECTION (batch only) | 1/1 batch | 100% |

### Copybooks

| Pattern | Files Matching | Confidence |
|---------|---------------|------------|
| Start at level 03 (not 01) | 3/3 CICS | 100% |
| Eyecatcher field with 88-level VALUE | 3/3 | 100% |
| Status field with 88-levels for each valid value | 3/3 | 100% |
| Date broken into DD/MM/YYYY DISPLAY subfields | 3/3 | 100% |
| REDEFINES for alternative interpretations | 2/3 | 67% |

### JCL

| Pattern | Files Matching | Confidence |
|---------|---------------|------------|
| Job card: `JOB 'desc',NOTIFY=&SYSUID,CLASS=A,MSGCLASS=H,MSGLEVEL=(1,1),REGION=4M` | 3/3 | 100% |
| DB2 programs via IKJEFT01 + DSN commands | 3/3 | 100% |
| STEPLIB: SDSNEXIT first, then SDSNLOAD, then LOAD | 3/3 | 100% |
| Header comment block with JOB/DESC/RC documentation | 2/3 | 67% |
| Symbolic SET variables in compile JCL | 1/1 compile | 100% |
| `COND=(4,LT,STEP_N)` for step chaining | 1/1 compile | 100% |

### PL/I

| Pattern | Files Matching | Confidence |
|---------|---------------|------------|
| `/*---…---*/` block header with License + Procedure description | 2/2 | 100% |
| Underscore naming (`HV_CUST_SORTCODE`) | 2/2 | 100% |
| Level 1 + level 5 for groups (not 01/03) | 2/2 | 100% |
| `FIXED BIN(31)` for 32-bit integers | 2/2 | 100% |
| `FIXED BIN(15)` for null indicators | 2/2 | 100% |
| `*PROCESS SYSTEM(IMS);` first line for IMS PL/I | 1/1 | 100% |
| `PROCEDURE(IOPCB_PTR, DBPCB_PTR) OPTIONS(MAIN)` for IMS | 1/1 | 100% |

---

## Conflicts Resolved

| Conflict | Resolution | Rationale |
|----------|-----------|-----------|
| `PROCESS CICS,...` vs only `CBL CICS(...)` | Use `CBL CICS('SP,EDF')` only | User confirmed |
| Level 03 vs 05 in WS-CICS-WORK-AREA | Level 05 | User confirmed |
| `PREMIERE SECTION` paragraph `A010` vs `P010` | Use `A010` | Majority (9/11) |

---

## Legacy Patterns Observed (do not replicate in new code)

- `PROGRAM-ID. "IBTRAN" recursive.` — quoted program-ID and recursive keyword in IMS programs (Java interop)
- `EXEC CICS HANDLE ABEND LABEL(...)` in INQCUST — older style, replaced by inline RESP checking in newer programs
- `77 SYSIDERR-RETRY PIC 999` declared with 77-level — newer programs use 01-level for consistency
- `WS-STORM-DRAIN` pattern in INQCUST — internal re-entry guard, not standard across all programs
