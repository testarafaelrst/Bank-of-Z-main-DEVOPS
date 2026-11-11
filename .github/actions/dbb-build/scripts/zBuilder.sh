#!/usr/bin/env bash
# =============================================================================
# zBuilder.sh — Wrapper da action dbb-build para o Bank of Z
#
# Recebe os parâmetros da composite action e delega ao pipeline-common.sh
# que já existe no repositório clonado no z/OS USS.
#
# Parâmetros:
#   -w  workspace dir (raiz do pipeline run no USS)
#   -a  application name (nome do repo)
#   -b  branch ref
#   -p  pipeline type  (build | deploy | ...)
#   -q  build HLQ
#   -t  dbb build type (full | pipeline)
# =============================================================================
set -eu

# ─── Defaults ────────────────────────────────────────────────────────────────
WORKSPACE=""
APP_NAME=""
BRANCH_REF=""
PIPELINE_TYPE="build"
BUILD_HLQ=""
DBB_BUILD_TYPE="pipeline"

# ─── Parse argumentos ────────────────────────────────────────────────────────
while getopts "w:a:b:p:q:t:" opt; do
    case $opt in
        w) WORKSPACE="$OPTARG"     ;;
        a) APP_NAME="$OPTARG"      ;;
        b) BRANCH_REF="$OPTARG"    ;;
        p) PIPELINE_TYPE="$OPTARG" ;;
        q) BUILD_HLQ="$OPTARG"     ;;
        t) DBB_BUILD_TYPE="$OPTARG";;
        *) echo "Opção inválida: -$OPTARG"; exit 1 ;;
    esac
done

# ─── Validações ──────────────────────────────────────────────────────────────
for var in WORKSPACE APP_NAME BUILD_HLQ; do
    eval val=\$$var
    if [ -z "$val" ]; then
        echo "::error:: [ERR] ❌ Parâmetro obrigatório ausente: $var"
        exit 1
    fi
done

# ─── Localizar o repositório clonado ─────────────────────────────────────────
# O gitClone.sh clona em  <workspace>/<app_name>/
REPO_DIR="${WORKSPACE}/${APP_NAME}"

if [ ! -d "$REPO_DIR" ]; then
    echo "::error:: [ERR] ❌ Repositório não encontrado em: $REPO_DIR"
    exit 1
fi

echo "[INFO] Workspace  : $WORKSPACE"
echo "[INFO] Repositório: $REPO_DIR"
echo "[INFO] Branch     : $BRANCH_REF"
echo "[INFO] Build HLQ  : $BUILD_HLQ"
echo "[INFO] Build type : $DBB_BUILD_TYPE"

# ─── Exportar variáveis esperadas pelo pipeline-common.sh ────────────────────
export APP_HLQ="$BUILD_HLQ"
export DBB_LOG_FOLDER="${WORKSPACE}/logs"
mkdir -p "$DBB_LOG_FOLDER"

# ─── Delegar ao pipeline-common.sh ───────────────────────────────────────────
PIPELINE_SCRIPT="${REPO_DIR}/.setup/pipeline-common.sh"

if [ ! -f "$PIPELINE_SCRIPT" ]; then
    echo "::error:: [ERR] ❌ pipeline-common.sh não encontrado em: $PIPELINE_SCRIPT"
    exit 1
fi

echo "[INFO] Executando: bash $PIPELINE_SCRIPT build $DBB_BUILD_TYPE"
bash "$PIPELINE_SCRIPT" build "$DBB_BUILD_TYPE"
