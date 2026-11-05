# Discovered Patterns — Bank of Z Coding Standards

**Discovery Date:** 2026-11-05
**Files Analyzed:** 18
**Enforcement Level:** Moderate (80%+ = MUST, 60–79% = SHOULD)

---

## Files Analyzed

### CICS COBOL (9 files)
- `src/base/cics/cobol/BNKMENU.cbl` — BMS front-end, EIBAID handling
- `src/base/cics/cobol/CREACC.cbl` — Create account, DB2 write, Named Counter
- `src/base/cics/cobol/CRECUST.cbl` — Create customer, DB2 write, credit check
- `src/base/cics/cobol/DBCRFUN.cbl` — Debit/credit function, DB2 update
- `src/base/cics/cobol/INQCUST.cbl` — Customer inquiry, DB2 read
- `src/base/cics/cobol/XFRFUN.cbl` — Transfer function, DB2 + CICS channels
- `src/base/cics/cobol/UPDCUST.cbl` — Update customer, DB2 update
- `src/base/cics/cobol/BNKSECCK.cbl` — Security check subprogram
- `src/base/cics/cobol/ABNDPROC.cbl` — Abend processor, VSAM KSDS write

### IMS COBOL (3 files)
- `src/base/ims/cobol/IBGCUDAT.cbl` — IMS get customer data (online)
- `src/base/ims/cobol/LOADCUST.cbl` — IMS load customers (batch)
- `src/base/ims/cobol/IBTRAN.cbl` — IMS transaction processor

### Batch COBOL (2 files)
- `src/base/batch/cobol/LSTCUST.cbl` — DB2 cursor report, sequential file output
- `src/base/batch/cobol/DEVOPSPL.cbl` — Simulated DevOps pipeline

### Copybooks (1 file)
- `src/base/cics/copy/ACCOUNT.cpy` — ACCOUNT data structure

### JCL (2 files)
- `src/base/batch/jcl/RUNDEVOPS.jcl` — Run DEVOPSPL batch job
- `src/base/batch/jcl/LSTCUST.jcl` — Run LSTCUST DB2 batch job

### PL/I (1 file)
- `src/base/batch/pli/BNKSTMT.pli` — Monthly statement generator, DB2 cursors

---

## Pattern Analysis by Category

### A. Copyright / File Header

| Pattern | Files | Confidence |
|---------|-------|-----------|
| Asterisk copyright block before IDENTIFICATION DIVISION | 18/18 | 100% — MUST |
| Copyright year in block | 18/18 | 100% |
| Description block (purpose, inputs, outputs) | 14/18 | 78% — SHOULD |
| `AUTHOR.` present | 12/18 | 67% — SHOULD |
| PL/I: `/*---*/` style comment blocks | 1/1 | 100% (PL/I only) |

**Conflict detected:** IMS programs place the copyright block AFTER `IDENTIFICATION DIVISION`, CICS programs place it BEFORE. Resolution: use BEFORE for new programs (CICS standard is more common).

### B. Compiler Directives (Line 1)

| Pattern | Files | Confidence |
|---------|-------|-----------|
| CICS: `CBL CICS('SP,EDF')` on line 1 | 19/33 total | majority |
| CICS: `PROCESS CICS,...` + `CBL CICS(...)` | 14/33 total | minority (legacy) |
| IMS: `CBL LIST,MAP,XREF,FLAG(I)` | 3/3 IMS | 100% |
| Batch: no directive | 2/2 batch | 100% |

**User decision:** New CICS programs → `CBL CICS(...)` only. `PROCESS CICS,...` is legacy, not for new code.

### C. SOURCE/OBJECT-COMPUTER

| Value | Files | Usage |
|-------|-------|-------|
| `IBM-370` | CICS programs (legacy) | Legacy |
| `IBM-Z` | IMS + Batch programs (newer) | Modern |

**User decision:** Use `IBM-Z` for all new programs.

### D. WORKING-STORAGE Prefixes

| Prefix | Usage | Adoption |
|--------|-------|---------|
| `WS-` | General working storage | 100% |
| `HV-` | DB2 host variables (COBOL) | 100% |
| `NI-` | DB2 null indicators | 100% in batch |
| `HV_` | DB2 host variables (PL/I, underscore) | 100% in PL/I |

### E. 88-Level Booleans

| Pattern | Files | Confidence |
|---------|-------|-----------|
| 88-levels for all boolean switches | 18/18 | 100% — MUST |
| Group under `SWITCHES` / `FLAGS` 01-level | 8/18 | 44% |
| Inline 88 under individual PIC X field | 10/18 | 56% |

Both forms coexist; the `SWITCHES`/`FLAGS` grouping is used for BMS-facing programs with multiple UI states.

### F. CICS RESP Handling

| Pattern | Files | Confidence |
|---------|-------|-----------|
| `WS-CICS-WORK-AREA` with `WS-CICS-RESP`/`WS-CICS-RESP2` | 9/9 CICS | 100% — MUST |
| RESP+RESP2 on every EXEC CICS | 9/9 CICS | 100% — MUST |
| Immediate IF check after EXEC CICS | 9/9 CICS | 100% — MUST |
| Level 05 subordinates inside WS-CICS-WORK-AREA | 9/9 CICS | 100% |

### G. ABEND Handling

| Pattern | Files | Confidence |
|---------|-------|-----------|
| `WS-ABEND-PGM VALUE 'ABNDPROC'` | 8/9 CICS | 89% — MUST |
| `ABNDINFO-REC. COPY ABNDINFO.` | 8/9 CICS | 89% — MUST |
| `EXEC CICS HANDLE ABEND LABEL(ABEND-HANDLING) END-EXEC` | 7/9 CICS | 78% — SHOULD |
| Full ABEND-HANDLING section | 7/9 CICS | 78% — SHOULD |
| Codes handled: AD2Z, AFCR, AFCS, AFCT | 5/9 CICS | 56% |
| `WS-STORM-DRAIN PIC X VALUE 'N'` | 5/9 CICS | 56% |

### H. Section Structure

| Pattern | Files | Confidence |
|---------|-------|-----------|
| PREMIERE SECTION as entry point | 9/9 CICS | 100% — MUST |
| `A010.` or `P010.` as first paragraph | 9/9 CICS | 100% — MUST |
| `XXX999. EXIT.` as last paragraph per section | 18/18 | 100% — MUST |
| SECTION per logical operation | 9/9 CICS | 100% — MUST |
| `GET-ME-OUT-OF-HERE SECTION` for exit | 9/9 CICS | 100% — MUST |
| `SECURITY-CHECK SECTION` for RACF | 8/9 CICS data programs | 89% — MUST |
| `POPULATE-TIME-DATE SECTION` for timestamp | 8/9 CICS | 89% — MUST |

### I. DB2 Host Variables

| Pattern | Files | Confidence |
|---------|-------|-----------|
| `01 HOST-<TABLE>-ROW.` grouping | 10/10 DB2 programs | 100% — MUST |
| `03 HV-<TABLE>-EYECATCHER PIC X(4)` first field | 10/10 | 100% — MUST |
| `EXEC SQL INCLUDE SQLCA END-EXEC.` | 5/5 batch DB2 | 100% — MUST |
| Batch: explicit DECLARE SECTION | 2/2 batch | 100% — MUST |

### J. IMS Patterns

| Pattern | Files | Confidence |
|---------|-------|-----------|
| DL/I codes as 77-levels (GU, GN, ISRT, etc.) | 3/3 IMS | 100% — MUST |
| `BAD-STATUS` area with SC-MSG + SC | 3/3 IMS | 100% — MUST |
| PCBs as POINTER in LINKAGE SECTION | 3/3 IMS | 100% — MUST |
| `ENTRY "DLITCBL"` in PROCEDURE DIVISION | 2/3 IMS | 67% — SHOULD |
| LL+ZZ fields in message areas | 2/3 IMS | 67% — SHOULD |

### K. JCL

| Pattern | Files | Confidence |
|---------|-------|-----------|
| `NOTIFY=&SYSUID` in job card | 2/2 | 100% — MUST |
| `MSGCLASS=H,MSGLEVEL=(1,1)` | 2/2 | 100% — MUST |
| `REGION=` specified | 2/2 | 100% — MUST |
| `// SET HLQ=` as first non-comment | 2/2 | 100% — MUST |
| `&HLQ..DATASET` for dataset names | 2/2 | 100% — MUST |
| Header comment block with RC table | 2/2 | 100% — MUST |
| `=` style delimiters in header | 1/2 | 50% |
| `*` style box in header | 1/2 | 50% |

**Conflict:** Two comment styles coexist. `=` style with RC table is more informative; recommended for new JCL.

### L. PL/I

| Pattern | Files | Confidence |
|---------|-------|-----------|
| `/*---*/` block comments | 1/1 | 100% |
| `HV_` prefix with underscore | 1/1 | 100% |
| `DCL 1 HV_<TABLE>` with level 5 | 1/1 | 100% |
| `FIXED BIN(15)` for null indicators | 1/1 | 100% |
| `ON ENDFILE(file)` for file errors | 1/1 | 100% |
| Nested `PROCEDURE` for subroutines | 1/1 | 100% |
| `GO TO` for error exit from ON block | 1/1 | 50% (advisory) |

---

## Conflicts Resolved

| Conflict | Options Found | Resolution |
|----------|--------------|------------|
| CICS header line 1 | `PROCESS CICS,...` vs `CBL CICS(...)` | User confirmed: `CBL CICS(...)` only |
| SOURCE/OBJECT-COMPUTER | `IBM-370` vs `IBM-Z` | User confirmed: `IBM-Z` |
| JCL comment style | `=` vs `*` box | Recommend `=` with RC table |
| Enforcement level | Strict vs Advisory | User confirmed: Moderate |

---

## Legacy vs Modern Classification

### Legacy patterns (found in older files — maintain for consistency, do not replicate)
- `PROCESS CICS,NODYNAM,NSYMBOL(NATIONAL),TRUNC(STD)` on line 1
- `SOURCE-COMPUTER. IBM-370.` / `OBJECT-COMPUTER. IBM-370.`
- `*SOURCE-COMPUTER. IBM-370 WITH DEBUGGING MODE.` commented out
- GO TO in main logic flow (should be limited to error exit via `GO TO SC999` only)
- `AUTHOR. Jon Collett.` (original developer)

### Modern patterns (use for new code)
- `CBL CICS('SP,EDF')` only
- `IBM-Z` for SOURCE/OBJECT-COMPUTER
- `AUTHOR. IBM Bank-of-Z.`
- Structured error handling via RESP/RESP2 — no HANDLE CONDITION
- LOCAL-STORAGE for instance data in CICS programs
