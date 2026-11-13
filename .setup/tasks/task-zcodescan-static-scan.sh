#!/bin/env bash
set -eu
# =============================================================================
# Script  : task-zcodescan-static-scan.sh
# Summary : IBM ZCodeScan Static Analysis
#
# - Prepares runtime environment (encoding, Java, PATH)
# - Runs DBB in preview mode to get the list of sources to scan
# - Activates Python environment
# - Executes ZCodeScan with provided configuration and parameters
# - Always produces LOG-PATH result
# - Exposes scan result paths if available
# - Preserves real return code (RC)
# =============================================================================

# =========================
# Source library scripts
# =========================
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/../lib/utilities.sh"
source "$SCRIPTS_DIR/../lib/colors.sh"

exec > >(while IFS= read -r line; do
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    printf "${CYAN}[ZCODESCAN]${NC} %s\n" "${line}"
done) 2>&1


# =========================
# Environment
# =========================
export PATH="${JAVA_HOME}/bin:${REMOTE_EXTRA_PATH:-}:$PATH"

# Resolve ZCodeScan config file:
#   1. Use the environment-specific file ($HOME/zcs_config_file.yml) when present.
#   2. Fall back to the base config checked into the repository.
#   3. Fail with a clear error if neither is found.
REPO_SCAN_CONFIG="${SCAN_RULE_FILE%/*}/zcodescan-config.yml"
if [ ! -f "${SCAN_CONFIG_FILE:-}" ]; then
    if [ -f "${HOME}/zcs_config_file.yml" ]; then
        export SCAN_CONFIG_FILE="${HOME}/zcs_config_file.yml"
    elif [ -f "${REPO_SCAN_CONFIG}" ]; then
        print_warning "ZCodeScan environment config not found: ${SCAN_CONFIG_FILE:-unset}"
        print_warning "Falling back to repository base config: ${REPO_SCAN_CONFIG}"
        export SCAN_CONFIG_FILE="${REPO_SCAN_CONFIG}"
    else
        print_error "ZCodeScan config file not found: ${SCAN_CONFIG_FILE:-unset}"
        print_error "Repository fallback also missing: ${REPO_SCAN_CONFIG}"
        print_error "Create ${HOME}/zcs_config_file.yml or ensure zcodescan/zcodescan-config.yml exists."
        exit 1
    fi
fi

# Expand shell variables in the config file (e.g. license_server: ${ZCS_LICENSE_SERVER:-...})
# ZCodeScan reads YAML directly — sem expansão de shell. Geramos uma cópia
# temporária com os valores reais antes de passar ao scanner.
SCAN_CONFIG_RESOLVED="/tmp/zcodescan_config_$$.yml"
if command -v envsubst >/dev/null 2>&1; then
    envsubst < "${SCAN_CONFIG_FILE}" > "${SCAN_CONFIG_RESOLVED}"
else
    # Fallback: sed expande apenas ZCS_LICENSE_SERVER
    sed "s|\${ZCS_LICENSE_SERVER:-[^}]*}|${ZCS_LICENSE_SERVER:-localhost:27000}|g" \
        "${SCAN_CONFIG_FILE}" > "${SCAN_CONFIG_RESOLVED}"
fi
export SCAN_CONFIG_FILE="${SCAN_CONFIG_RESOLVED}"
print_info "Config file resolvido: ${SCAN_CONFIG_FILE}"

# =========================
# Temporary log
# =========================
TMP_LOG="/tmp/zcodescan_$$.log"
: > "$TMP_LOG"


SCAN_OUTPUT_FILE=${SCAN_OUTPUT_FOLDER}/output/zcs_export.yaml
LOG_DIR="$SCAN_OUTPUT_FOLDER/logs"
LOG_TAR="$SCAN_OUTPUT_FOLDER/zcodescan-log.tar"

# =========================
# Finalize: always publish log tar on exit
# =========================
finalize_results() {
    RC=$?

    if [ -f "$TMP_LOG" ]; then
        cp "$TMP_LOG" "$LOG_DIR/zcodescan-console.log" 2>/dev/null || true
    fi

    if ls "$LOG_DIR"/*.log >/dev/null 2>&1; then
        tar cf "$LOG_TAR" -C "$LOG_DIR" . 2>/dev/null || true
    else
        mkdir -p "$LOG_DIR"
        echo "No ZCodeScan logs found" > "$LOG_DIR/zcodescan-console.log"
        tar cf "$LOG_TAR" -C "$LOG_DIR" . 2>/dev/null || true
    fi

    print_result "[LOG-PATH] $LOG_TAR"

    rm -f "$TMP_LOG" "${SCAN_CONFIG_RESOLVED:-}" 2>/dev/null || true

    exit "$RC"
}

trap finalize_results EXIT

# =========================
# Step 1: DBB preview (get source list)
# =========================
print_info "Running DBB in preview mode to get the list of sources to scan"

set -o pipefail
bash "$SCRIPTS_DIR/../tasks/task-dbb-build.sh" preview 2>&1 | tee "$TMP_LOG" | while read -r line
do
    case "$line" in
        ">"*)
            print_info "${line#> }"
            ;;
        *)
            print_info "$line"
            ;;
    esac
done

# Em modo preview, o task Transfer falha com BGZZB0008E ao tentar copiar
# para datasets que nao existem. Esse erro e esperado em preview e
# nao impede a obtencao da lista de fontes para o ZCodeScan.
# Verificamos se ha outros ERRORs que nao sejam do Transfer em preview.
TRANSFER_PREVIEW_ERROR="BGZZB0008E"
FATAL_ERRORS=$(grep "ERROR" "$TMP_LOG" | grep -v "$TRANSFER_PREVIEW_ERROR" | grep -v "Build Status : ERROR" || true)

if [ -n "$FATAL_ERRORS" ]; then
    print_error "DBB build failed with fatal errors"
    print_error "$FATAL_ERRORS"
    exit 1
fi

# Se houve apenas o erro do Transfer (BGZZB0008E), emite warning e continua
if grep -q "$TRANSFER_PREVIEW_ERROR" "$TMP_LOG"; then
    print_warning "Transfer task failed in preview mode (BGZZB0008E) - expected behavior, continuing scan"
fi

if grep -q "Total files processed : 0$" "$TMP_LOG"; then
    print_info "DBB build list is empty - nothing to scan"
    exit 0
fi

BUILD_LIST=$(sed -n 's/.*\[BUILD-LIST\][[:space:]]*//p' "$TMP_LOG" | tail -1)

cd "${SCAN_CWD_FOLDER}"
source "${SCAN_PYENV_ACTIVATE_PATH}"

# =========================
# Step 2: Run ZCodeScan
# =========================
: > "$TMP_LOG"

rm -rf "$LOG_DIR"
rm -f ./*.log
mkdir -p "$LOG_DIR"

print_info "Starting ZCodeScan analysis ..."
print_info "  SCAN_SOURCE_FOLDER = ${SCAN_SOURCE_FOLDER}"
print_info "  SCAN_CWD_FOLDER    = ${SCAN_CWD_FOLDER}"
print_info "  BUILD_LIST         = ${BUILD_LIST}"
print_info "  SCAN_RULE_FILE     = ${SCAN_RULE_FILE}"
print_info "  SCAN_CONFIG_FILE   = ${SCAN_CONFIG_FILE}"
print_info "  SCAN_ENCODING      = ${SCAN_ENCODING}"
print_info "  SCAN_RULE_FILE exists: $([ -f "${SCAN_RULE_FILE}" ] && echo YES || echo NO)"
print_info "  SCAN_CONFIG_FILE exists: $([ -f "${SCAN_CONFIG_FILE}" ] && echo YES || echo NO)"
print_info "  REPO_SCAN_CONFIG   = ${REPO_SCAN_CONFIG}"
print_info "  REPO_SCAN_CONFIG exists: $([ -f "${REPO_SCAN_CONFIG}" ] && echo YES || echo NO)"

# Estrategia de encoding para o ZCodeScan:
#
# Os fontes mainframe estao em IBM-1047 (EBCDIC) tagados no USS.
# Com _BPXK_AUTOCVT=ON (padrao), ao abrir arquivos TAGADOS IBM-1047 o z/OS
# converte EBCDIC->ASCII automaticamente, fazendo o ZCodeScan receber ASCII
# em vez de EBCDIC (RC=-1). Usando _BPXK_AUTOCVT=OFF o ZCodeScan recebe
# bytes EBCDIC brutos e -e IBM-1047 decodifica correto — MAS isso faz
# 'java -version' retornar EBCDIC que o Python nao decodifica como UTF-8.
#
# Solucao: remover temporariamente a tag dos fontes (chtag -r).
# Arquivo NAO-TAGADO + AUTOCVT=ON = z/OS nao faz conversao automatica
# (trata como EBCDIC/binario). ZCodeScan recebe bytes EBCDIC brutos e
# -e IBM-1047 decodifica. Apos o scan, restaurar tag IBM-1047.
#
# IMPORTANTE: NAO usar pipeline (zcodescan | tee | while read).
# O while read fecha o stdin antes do zcodescan terminar → SIGPIPE → RC=-1
# sem gravar a linha RC= no log. Executar sem pipeline, redirecionar para
# arquivo e exibir em seguida.
print_info "Removendo tag dos fontes mainframe para o scan (evitar AUTOCVT)..."
find "${SCAN_SOURCE_FOLDER}" \( \
  -name "*.cbl" -o -name "*.cpy" -o -name "*.pli" -o -name "*.inc" \
\) -type f -exec chtag -r {} \; 2>/dev/null || true

set +e
PYTHONUNBUFFERED=1 zcodescan \
  -sfl "$BUILD_LIST" \
  -if "${SCAN_SOURCE_FOLDER}" \
  -cf "${SCAN_CONFIG_FILE}" \
  -of "${SCAN_OUTPUT_FILE}" \
  -rf "${SCAN_RULE_FILE}" \
  -et sonarqube,junit \
  -e "${SCAN_ENCODING}" > "$TMP_LOG" 2>&1
ZCS_RC=$?

# Exibir saida do scan em tempo real apos conclusao
while IFS= read -r line; do
    case "$line" in
        ">"*) print_info "${line#> }" ;;
        *)    print_info "$line" ;;
    esac
done < "$TMP_LOG"

# Restaurar tag IBM-1047 nos fontes apos o scan
print_info "Restaurando tag IBM-1047 nos fontes mainframe..."
find "${SCAN_SOURCE_FOLDER}" \( \
  -name "*.cbl" -o -name "*.cpy" -o -name "*.pli" -o -name "*.inc" \
\) -type f -exec chtag -tc IBM-1047 {} \; 2>/dev/null || true

# Exibir as primeiras 80 linhas do zcodescan.log para diagnostico inline
print_info "--- zcodescan.log (primeiras 80 linhas) ---"
head -80 zcodescan.log 2>/dev/null | while IFS= read -r l; do print_info "  $l"; done
print_info "--- fim do zcodescan.log ---"

cp zcodescan.log "$LOG_DIR"

# =========================
# Collect result files
# =========================
while IFS= read -r line; do
    case "$line" in
        *"Generate SonarQube export to "*)
            cp -f "${line##*Generate SonarQube export to }" "$LOG_DIR"
            ;;
        *"Generate JUnit export to "*)
            cp -f "${line##*Generate JUnit export to }" "$LOG_DIR"
            ;;
        *"Generate output to "*)
            cp -f "${line##*Generate output to }" "$LOG_DIR"
            ;;
    esac
done < "$TMP_LOG"

deactivate

# =========================
# Validate return code
# =========================
# Preferência: RC gravado pelo zcodescan no log (ex: "RC=4").
# Fallback: exit code do processo (ZCS_RC) quando o log não contém RC=.
# Isso protege contra crashes ou sinais que não gravam no log.
rc=$(sed -n 's/.*RC=\(-\?[0-9][0-9]*\).*/\1/p' "$TMP_LOG" | tail -1)

if [ -z "$rc" ]; then
    print_warning "RC não encontrado no log — usando exit code do processo: ZCS_RC=$ZCS_RC"
    rc="$ZCS_RC"
fi

print_info "ZCodeScan RC=$rc (ZCS_RC=$ZCS_RC, SCAN_MAX_RC=$SCAN_MAX_RC)"

# RC=255 ou negativo indica crash/sinal (SIGPIPE, SIGKILL, etc.)
if [ "$rc" -eq 255 ] 2>/dev/null || { [ "$rc" -lt 0 ] 2>/dev/null; }; then
    print_error "ZCodeScan terminou com RC=$rc — possível crash ou sinal"
    exit 1
fi

if [ "$rc" -gt "$SCAN_MAX_RC" ]; then
    print_error "RC=$rc excede máximo permitido (SCAN_MAX_RC=$SCAN_MAX_RC)"
    exit 1
fi

print_success "ZCodeScan concluído com RC=$rc (≤ SCAN_MAX_RC=$SCAN_MAX_RC)"
exit 0
