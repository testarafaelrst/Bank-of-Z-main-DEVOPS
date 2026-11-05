# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Workspace Type

**Application platform: IBM Z**
**Detected Languages:** IBM Enterprise COBOL for z/OS, PL/I, HLASM (Assembler), REXX, JCL

---

## Project Overview

**Bank of Z** — a full-stack IBM Z banking sample application demonstrating modern z/OS development. The CICS/IMS COBOL programs form the core; a z/OS Connect API layer (Gradle) exposes them as REST, and a Liberty-hosted HTML/JS frontend consumes those APIs.

---

## Source Layout (non-obvious)

| Path | Contents |
|------|----------|
| `src/base/cics/cobol/` | CICS COBOL programs (transaction processing) |
| `src/base/cics/copy/` | COBOL copybooks for CICS path (`.cpy`) |
| `src/base/cics/bms/` | BMS map source (`.bms`) |
| `src/base/ims/cobol/` | IMS COBOL programs |
| `src/base/ims/copy/` | COBOL copybooks for IMS path |
| `src/base/ims/DBD/` | IMS Database Descriptor sources (`.asm`) |
| `src/base/ims/PSB/` | IMS Program Specification Block sources (`.asm`) |
| `src/base/batch/cobol/` | Batch COBOL programs |
| `src/base/batch/jcl/` | JCL for batch jobs |
| `src/base/batch/pli/` | PL/I batch programs |
| `src/api/` | z/OS Connect API project — Gradle build, generates `api.war` |
| `src/api/src/main/zosAssets/` | One subdirectory per CICS/IMS program; contains provider files and generated copybooks |
| `src/frontend/` | Plain HTML/CSS/JS frontend (no framework, no build step) |
| `multiroot/` | VS Code multi-root workspace example (SAM programs + separate copybooks) |
| `preprocessor/` | COBOL and PL/I local/remote preprocessor examples |
| `.setup/` | All z/OS provisioning, build, and deploy automation (shell scripts + Jinja2 YAML) |
| `.setup/config/config.yaml` | **Single source of truth** for all environment values (ports, HLQs, tool paths). Edit this file before running any setup script. |
| `dbb-app.yaml` | DBB application descriptor — maps source glob patterns to language tasks and compiler vars |
| `zapp.yaml` | Z Open Editor ZAPP manifest — property groups, user-build profiles, preprocessor, EDT test profile |
| `zcodeformat.yaml` | Z Open Editor formatter config (COBOL indentation = 1, copybook case = upper) |
| `zcodescan/` | ZCodeScan configuration (`zcodescan-config.yml`, `zcodescan-rules.yaml`) |
| `.bobz/specs/` | Technical specifications for individual programs (Markdown, in Portuguese) |

---

## Build & Deploy

There is **no local `npm` or `make`** — all real compilation happens on z/OS via DBB or User Build.

| Action | Command |
|--------|---------|
| User Build (single program) | Right-click program in VS Code → **Run IBM User Build** |
| Default User Build profile | `zowe-upload-userbuild2` (defined in `zapp.yaml`, activated in `.vscode/settings.json`) |
| Full pipeline (GRUB) | `.setup/pipeline-common.sh` (configured as `grub.buildCommand` in `.vscode/settings.json`) |
| Full setup on z/OS | `zowe/zowecli-cobol-upload-run-simple.sh` (run from workspace root) |
| z/OS Connect API build | `./gradlew build` in `src/api/` — requires Gradle 9.5.1 on USS |
| Run all integration tests | `BASE_URL=http://<host>:9080/api FRONTEND_URL=http://<host>:9081 tests/run-all.sh` |
| Run a single test | `BASE_URL=... FRONTEND_URL=... bash tests/test_get_customer_cics.sh` |
| Skip IMS tests | Set `IMS_DISABLED=true` before running tests |

Tests are **integration tests** that hit a live z/OS Connect API and Liberty frontend — they cannot run without a deployed z/OS environment.

---

## COBOL Coding Conventions (discovered from source)

- CICS programs begin with `PROCESS CICS,NODYNAM,NSYMBOL(NATIONAL),TRUNC(STD)` on line 1.
- Formatter enforces: Data Division indent = 1, Procedure Division indent = 1; copybook code always uppercase (`zcodeformat.yaml`).
- CICS RESP/RESP2 always captured in `WS-CICS-WORK-AREA` (PIC S9(8) COMP), checked after every CICS command.
- 88-level condition names are used for all boolean switches and flags (pattern: `SWITCHES`, `FLAGS` groups in WORKING-STORAGE).
- Compiler options: `LIB,MAP,NODYN` for COBOL; `PP(INCLUDE(...))` for PL/I (see `build.properties`).
- Max acceptable return code from compilation: **4** (both COBOL and PL/I).
- ZCodeScan scans COBOL and PL/I with encoding `IBM-1047`; `maxReturnCode: 4` (`zcodescan/zcodescan-config.yml`).

---

## Copybook Resolution

- CICS copybooks: `src/base/cics/copy/*.cpy` (library name `syslib`, type `local` in `zapp.yaml`).
- IMS copybooks: `src/base/ims/copy/*.cpy`.
- Multi-root workspace: copybooks live in the `copybooks` workspace; programs in `sam` workspace. ZAPP in `copybooks` workspace resolves them transparently — **do not add a property group to the `sam` ZAPP**.

---

## z/OS Connect API Assets

- Each exposed CICS/IMS program has its own subdirectory under `src/api/src/main/zosAssets/<PROGNAME>/`.
- Generated copybooks live in `providerFiles/gen/` — **do not edit these manually**; regenerate via z/OS Connect tooling.
- The API runs on HTTP port **9080** and HTTPS port **9444**; the frontend Liberty server runs on **9081** / **9445**.

---

## Technical Specifications

- Per-program technical specs are stored as Markdown in `.bobz/specs/` (in Portuguese). Example: `.bobz/specs/LSTCUST-technical-spec.md`.
- When modifying a COBOL program that has a spec file, update (or flag for update) the corresponding spec.
- `DEVOPSPL.cbl` and `BANKTRX.cbl` are standalone batch programs with no file I/O; their specs live in `.bobz/specs/`.

---

## COBOL Program → Technical Documentation Mapping

| Program | Spec / Documentation |
|---------|----------------------|
| `src/base/batch/cobol/LSTCUST.cbl` | `.bobz/specs/LSTCUST-technical-spec.md` |
| `src/base/cics/cobol/BANKDATA.cbl` | `docs/docs/architecture/application-components.md` |
| All CICS programs | `docs/docs/architecture/application-components.md`, `docs/docs/architecture/application-flow.md` |
| All IMS programs | `docs/docs/architecture/application-components.md` |

**Auto-update rules:** When a COBOL program is modified, check whether a spec exists in `.bobz/specs/` and prompt to sync it. When new programs are added, create a spec in `.bobz/specs/<PROGNAME>-technical-spec.md` following the existing structure.

---

## Configuration Reference

- All z/OS system values (HLQs, ports, tool paths, middleware versions) are in `.setup/config/config.yaml`. The Jinja2 `{{ }}` references resolve at script execution time.
- **Do not hardcode HLQs or ports in scripts** — reference `config.yaml` values instead.
- The default Zowe RSE profile name is `bankz` (set in `config.yaml` under `zowe.rse_profile`).
