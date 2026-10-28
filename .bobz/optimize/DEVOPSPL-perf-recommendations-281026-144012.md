## Performance Optimization Recommendations

I've analyzed `src/base/batch/cobol/DEVOPSPL.cbl` and identified 4 optimization opportunities across data definitions and loop/control flow patterns.

---

### Recommendation 1: Use `BINARY` for Numeric Counter and Index Fields

**Location**: [`WS-CONTROLE`](src/base/batch/cobol/DEVOPSPL.cbl:23) — lines 23–37

**Issue**: The numeric fields `WS-IDX`, `WS-NUM-ETAPA`, `WS-QTD-ETAPAS`, `WS-QTD-OK`, `WS-IDX-FALHA`, `WS-FALHA-SIMULADA`, `WS-TAM`, and `WS-RC-EXIBIR` are all defined with `USAGE DISPLAY` (the default). These fields are used exclusively for loop control (`PERFORM VARYING`), counting (`ADD 1`), comparisons (`IF WS-IDX = WS-FALHA-SIMULADA`), and arithmetic — not for I/O or display formatting. The compiler must convert `DISPLAY` numeric items to an internal binary representation before every arithmetic or comparison operation, adding unnecessary overhead.

**Recommendation**: Redefine all of these numeric counter and index fields as `USAGE BINARY` (with a `SYNC` clause and a signed picture). This eliminates the conversion overhead on every loop iteration and comparison.

```cobol
*  Before
05 WS-IDX             PIC 9(02) VALUE 0.
05 WS-NUM-ETAPA       PIC 9(01) VALUE 0.
05 WS-QTD-ETAPAS      PIC 9(02) VALUE 7.
05 WS-QTD-OK          PIC 9(02) VALUE 0.
05 WS-IDX-FALHA       PIC 9(02) VALUE 0.
05 WS-FALHA-SIMULADA  PIC 9(02) VALUE 0.
05 WS-RC-EXIBIR       PIC 9(04) VALUE 0.

*  After
05 WS-IDX             PIC S9(04) USAGE BINARY SYNC VALUE 0.
05 WS-NUM-ETAPA       PIC S9(04) USAGE BINARY SYNC VALUE 0.
05 WS-QTD-ETAPAS      PIC S9(04) USAGE BINARY SYNC VALUE 7.
05 WS-QTD-OK          PIC S9(04) USAGE BINARY SYNC VALUE 0.
05 WS-IDX-FALHA       PIC S9(04) USAGE BINARY SYNC VALUE 0.
05 WS-FALHA-SIMULADA  PIC S9(04) USAGE BINARY SYNC VALUE 0.
05 WS-RC-EXIBIR       PIC S9(04) USAGE BINARY SYNC VALUE 0.
```

**Considerations**:
- `WS-RC-EXIBIR` is used in a `DISPLAY` statement at line 204; changing it to `BINARY` will display the raw binary value unless it is first moved to a `DISPLAY` item for output.
- `WS-NUM-ETAPA` appears directly in `DISPLAY` statements (lines 132, 138, etc.); the same applies — convert to a `DISPLAY` work field before outputting, or keep `WS-NUM-ETAPA` as `DISPLAY` and only change the pure counters/indexes.
- Verify that the `TRUNC` compiler option matches your intended binary truncation behavior when using signed `BINARY` items.

**Value Assessment**:
| Dimension | Rating |
|---|---|
| Effort | Low |
| Complexity | Low |
| Expected Impact | Moderate |
| Maintainability | Easy |

---

### Recommendation 2: Replace the Status-Initialization Loop with a Single `INITIALIZE`

**Location**: [`110-CARREGAR-TABELA`](src/base/batch/cobol/DEVOPSPL.cbl:73) — lines 74–77

**Issue**: The paragraph `110-CARREGAR-TABELA` uses a `PERFORM VARYING` loop to move `'PENDENTE'` into `WS-ET-STATUS` for each of the 7 table entries one at a time. This is unnecessary because `INITIALIZE` can reset an entire table group in a single statement, and `WS-TABELA-ETAPAS` could alternatively have its `WS-ET-STATUS` sub-field given a `VALUE 'PENDENTE'` clause at definition time, which requires no runtime initialization at all.

**Recommendation**: Remove the `PERFORM` loop and add a `VALUE 'PENDENTE'` clause to `WS-ET-STATUS` in the data definition, or replace the loop with a single `INITIALIZE WS-TABELA-ETAPAS REPLACING ALPHANUMERIC DATA BY 'PENDENTE'` call — though the `VALUE` clause approach has zero runtime cost.

```cobol
*  Before (in data division)
10 WS-ET-STATUS  PIC X(10).

*  After (in data division) — no runtime initialization needed
10 WS-ET-STATUS  PIC X(10) VALUE 'PENDENTE'.

*  Then remove the PERFORM loop in 110-CARREGAR-TABELA (lines 74-77) entirely.
```

**Considerations**:
- `WS-ET-STATUS` is later overwritten per stage in `240-AVALIAR-STATUS` and `900-RESUMO-FINAL`, so pre-initializing with `VALUE` is safe and produces the same runtime state.
- If this program can be re-invoked (e.g., as a subroutine), ensure the `WORKING-STORAGE` section is appropriately re-initialized on each call since `VALUE` clauses only apply at initial program load. In that case, a single `INITIALIZE WS-TABELA-ETAPAS` call in `100-INICIALIZAR` is preferable to the loop.

**Value Assessment**:
| Dimension | Rating |
|---|---|
| Effort | Low |
| Complexity | Low |
| Expected Impact | Minor |
| Maintainability | Easy |

---

### Recommendation 3: Inline Small Single-Purpose Display Paragraphs Called Inside the Main Loop

**Location**: [`200-EXECUTAR-ETAPA`](src/base/batch/cobol/DEVOPSPL.cbl:121) — lines 121–127

**Issue**: `200-EXECUTAR-ETAPA` is called on every iteration of the main loop in `000-MAIN` and immediately chains four `PERFORM` calls to `210-EXIBIR-INICIO`, `220-EXIBIR-PRODUTO`, `230-EXIBIR-ATIVIDADE`, and `250-EXIBIR-CONCLUSAO`. Each of these paragraphs contains only 1–3 `DISPLAY` statements. Each out-of-line `PERFORM` introduces control-flow overhead (branch, return) for trivial work. With 7 iterations, the main loop generates at least 35 `PERFORM` dispatches just for display work.

**Recommendation**: Move the `DISPLAY` statements from `210-EXIBIR-INICIO`, `220-EXIBIR-PRODUTO`, `230-EXIBIR-ATIVIDADE`, and `250-EXIBIR-CONCLUSAO` directly into `200-EXECUTAR-ETAPA` (or inline them into the main loop body), eliminating the nested `PERFORM` overhead.

```cobol
*  Before
200-EXECUTAR-ETAPA.
    MOVE WS-IDX TO WS-NUM-ETAPA
    PERFORM 210-EXIBIR-INICIO
    PERFORM 220-EXIBIR-PRODUTO
    PERFORM 230-EXIBIR-ATIVIDADE
    PERFORM 240-AVALIAR-STATUS
    PERFORM 250-EXIBIR-CONCLUSAO.

*  After
200-EXECUTAR-ETAPA.
    MOVE WS-IDX TO WS-NUM-ETAPA
    DISPLAY '--------------------------------------------------'
    DISPLAY '[' WS-NUM-ETAPA '/7] INICIO   : '
            FUNCTION TRIM(WS-ET-NOME(WS-IDX) TRAILING)
    DISPLAY '[' WS-NUM-ETAPA '/7] PRODUTO  : '
            FUNCTION TRIM(WS-ET-PRODUTO(WS-IDX) TRAILING)
    DISPLAY '[' WS-NUM-ETAPA '/7] ATIVIDADE: '
            FUNCTION TRIM(WS-ET-ATIVIDADE(WS-IDX) TRAILING)
    PERFORM 240-AVALIAR-STATUS
    ... (inline 250 logic similarly)
```

**Considerations**:
- `240-AVALIAR-STATUS` contains meaningful business logic and should remain a named paragraph for clarity and maintainability; only the pure display paragraphs are candidates for inlining.
- If any of the display paragraphs are called from other locations in the program (they currently are not), inlining them would require duplicating that code.

**Value Assessment**:
| Dimension | Rating |
|---|---|
| Effort | Low |
| Complexity | Low |
| Expected Impact | Minor |
| Maintainability | Easy |

---

### Recommendation 4: Eliminate Redundant `MOVE WS-IDX TO WS-NUM-ETAPA` via Direct Reference

**Location**: [`200-EXECUTAR-ETAPA`](src/base/batch/cobol/DEVOPSPL.cbl:121) — lines 122, 132, 138, 144, 163, 168, 173

**Issue**: `WS-NUM-ETAPA` is defined solely as an intermediate copy of `WS-IDX` used within the display paragraphs. On every loop iteration, `WS-IDX` is moved to `WS-NUM-ETAPA` (line 122), which then appears in five separate `DISPLAY` statements across three paragraphs. This introduces an unnecessary data movement and an additional `DISPLAY` data item. Since `WS-IDX` already holds the same value throughout the iteration, the intermediate field serves no purpose.

**Recommendation**: Remove `WS-NUM-ETAPA` from `WS-CONTROLE` and replace every occurrence in the `DISPLAY` statements with `WS-IDX` directly. This eliminates the `MOVE` on every iteration and removes an unused data item.

```cobol
*  Before
MOVE WS-IDX TO WS-NUM-ETAPA
DISPLAY '[' WS-NUM-ETAPA '/7] INICIO : ' ...

*  After (remove the MOVE entirely, reference WS-IDX directly)
DISPLAY '[' WS-IDX '/7] INICIO : ' ...
```

**Considerations**:
- If `WS-IDX` is changed to `BINARY` (per Recommendation 1), using it directly in `DISPLAY` will show its raw internal value. In that case, keep `WS-NUM-ETAPA` as a `DISPLAY` field and move `WS-IDX` to it only once per iteration for display purposes — which is exactly the current pattern. Therefore, **apply this recommendation only if Recommendation 1 is not implemented**, or keep a single `DISPLAY`-typed `WS-NUM-ETAPA` as a display-only conversion target.

**Value Assessment**:
| Dimension | Rating |
|---|---|
| Effort | Low |
| Complexity | Low |
| Expected Impact | Minor |
| Maintainability | Easy |