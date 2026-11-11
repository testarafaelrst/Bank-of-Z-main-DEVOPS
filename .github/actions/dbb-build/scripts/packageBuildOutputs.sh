#!/usr/bin/env bash
# =============================================================================
# packageBuildOutputs.sh — Empacotamento de artefatos do build DBB
#
# Localiza o .tar gerado pelo DBB no workspace e produz:
#   logs/build-<identifier>.tar  — artefatos de build (renomeado do DBB tar)
#   logs/logs-<identifier>.tar   — logs e listings (*.log, *.lst)
#
# Parâmetros:
#   -w  workspace dir
#   -a  application name
#   -b  branch ref
#   -p  pipeline type
#   -i  build identifier  (ex: build_42_attempt_1)
#   -l  extensões de log  (ex: *.log,*.lst)
# =============================================================================
set -eu

# ─── Defaults ────────────────────────────────────────────────────────────────
WORKSPACE=""
APP_NAME=""
BRANCH_REF=""
PIPELINE_TYPE="build"
BUILD_IDENTIFIER=""
INCLUDE_LOGS="*.log,*.lst"

# ─── Parse argumentos ────────────────────────────────────────────────────────
while getopts "w:a:b:p:i:l:" opt; do
    case $opt in
        w) WORKSPACE="$OPTARG"        ;;
        a) APP_NAME="$OPTARG"         ;;
        b) BRANCH_REF="$OPTARG"       ;;
        p) PIPELINE_TYPE="$OPTARG"    ;;
        i) BUILD_IDENTIFIER="$OPTARG" ;;
        l) INCLUDE_LOGS="$OPTARG"     ;;
        *) echo "Opção inválida: -$OPTARG"; exit 1 ;;
    esac
done

# ─── Validações ──────────────────────────────────────────────────────────────
for var in WORKSPACE APP_NAME BUILD_IDENTIFIER; do
    eval val=\$$var
    if [ -z "$val" ]; then
        echo "::error:: [ERR] ❌ Parâmetro obrigatório ausente: $var"
        exit 1
    fi
done

LOG_DIR="${WORKSPACE}/logs"
mkdir -p "$LOG_DIR"

echo "[INFO] Workspace      : $WORKSPACE"
echo "[INFO] Build ID       : $BUILD_IDENTIFIER"
echo "[INFO] Log dir        : $LOG_DIR"
echo "[INFO] Exts de log    : $INCLUDE_LOGS"

# ─── Localizar o tar do DBB ──────────────────────────────────────────────────
# O task-dbb-build.sh publica o tar em  <workspace>/logs/*-*.tar
SRC_TAR=$(ls -t "${LOG_DIR}"/*-*.tar 2>/dev/null | head -1 || true)

if [ -z "$SRC_TAR" ]; then
    echo "[WARN] ⚠️  Nenhum artefato .tar encontrado em ${LOG_DIR} — nada processado"
    exit 0
fi

echo "[INFO] Tar de origem  : $SRC_TAR"

# ─── Renomear para convenção build-<identifier>.tar ──────────────────────────
BUILD_TAR="${LOG_DIR}/build-${BUILD_IDENTIFIER}.tar"
if [ "$SRC_TAR" != "$BUILD_TAR" ]; then
    cp "$SRC_TAR" "$BUILD_TAR"
    echo "[OK] ✅ Artefato de build: $BUILD_TAR"
fi

# ─── Empacotar logs/listings ─────────────────────────────────────────────────
LOGS_TAR="${LOG_DIR}/logs-${BUILD_IDENTIFIER}.tar"
TMP_LOGS_DIR=$(mktemp -d)

# Converter extensões separadas por vírgula para lista de padrões find
IFS=',' read -ra EXT_LIST <<< "$INCLUDE_LOGS"

FILES_FOUND=0
for ext in "${EXT_LIST[@]}"; do
    # Busca recursiva no workspace excluindo o próprio diretório de logs
    while IFS= read -r f; do
        cp "$f" "$TMP_LOGS_DIR/" 2>/dev/null && FILES_FOUND=$((FILES_FOUND + 1)) || true
    done < <(find "$WORKSPACE" -name "$ext" -not -path "${LOG_DIR}/*" 2>/dev/null || true)
done

if [ "$FILES_FOUND" -gt 0 ]; then
    tar cf "$LOGS_TAR" -C "$TMP_LOGS_DIR" . 2>/dev/null
    echo "[OK] ✅ Logs empacotados ($FILES_FOUND arquivo(s)): $LOGS_TAR"
else
    echo "[INFO] Nenhum arquivo de log encontrado para empacotar"
fi

rm -rf "$TMP_LOGS_DIR"
echo "[OK] ✅ Empacotamento concluído"
