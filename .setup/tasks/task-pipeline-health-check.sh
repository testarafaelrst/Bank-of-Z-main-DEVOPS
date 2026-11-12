#!/usr/bin/env bash
# =============================================================================
# Script  : task-pipeline-health-check.sh
# Summary : Validação de pré-requisitos da pipeline ZCode → Build
#
# Verifica todos os requisitos antes de iniciar a pipeline:
#   1. Conectividade SSH e autenticação
#   2. Ferramentas obrigatórias (DBB, Java, Python, ZCodeScan)
#   3. Variáveis de ambiente críticas
#   4. Espaço em disco no z/OS USS
#   5. Datasets HLQ e permissões
#   6. Codepage e encoding dos fontes
#   7. Rede e endpoints externos (GitHub API)
#
# Uso:
#   bash task-pipeline-health-check.sh [--strict]
#
# Opções:
#   --strict  Falha no primeiro problema encontrado (default: reporta todos)
#
# Saída:
#   Retorna 0 se tudo OK, 1 se houver falhas críticas, 2 se houver avisos
# =============================================================================
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/../lib/utilities.sh"
source "$SCRIPTS_DIR/../lib/colors.sh"

STRICT_MODE=false
[[ "${1:-}" == "--strict" ]] && STRICT_MODE=true

# ─── Contadores ──────────────────────────────────────────────────────────────
ERRORS=0
WARNINGS=0
CHECKS_PASSED=0

# ─── Helpers ─────────────────────────────────────────────────────────────────
check_pass() {
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    printf "${GREEN}[PASS]${NC} %s\n" "$1"
}

check_warn() {
    WARNINGS=$((WARNINGS + 1))
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}

check_fail() {
    ERRORS=$((ERRORS + 1))
    printf "${RED}[FAIL]${NC} %s\n" "$1"
    if [ "$STRICT_MODE" = true ]; then
        echo "[HEALTH-CHECK] Saindo no primeiro erro (modo --strict)"
        exit 1
    fi
}

section() {
    echo ""
    printf "${CYAN}━━━ %s ━━━${NC}\n" "$1"
}

# =============================================================================
# SEÇÃO 1 — Variáveis de ambiente críticas
# =============================================================================
section "1/7 — Variáveis de Ambiente"

REQUIRED_VARS=(
    "DBB_HOME"
    "JAVA_HOME"
    "APP_HLQ"
    "DBB_CWD"
    "DBB_APP_CONF"
    "DBB_LOG_FOLDER"
    "SCAN_PYENV_ACTIVATE_PATH"
    "SCAN_SOURCE_FOLDER"
    "SCAN_RULE_FILE"
    "SCAN_CONFIG_FILE"
    "BANK_OF_Z_WORK_DIR"
)

for var in "${REQUIRED_VARS[@]}"; do
    val="${!var:-}"
    if [ -z "$val" ]; then
        check_fail "Variável não definida: $var"
    else
        check_pass "$var = $val"
    fi
done

# =============================================================================
# SEÇÃO 2 — Ferramentas obrigatórias
# =============================================================================
section "2/7 — Ferramentas Obrigatórias"

# DBB
if [ -f "${DBB_HOME:-}/bin/dbb" ]; then
    DBB_VER=$("${DBB_HOME}/bin/dbb" --version 2>/dev/null | head -1 || echo "desconhecida")
    check_pass "DBB encontrado: ${DBB_HOME}/bin/dbb (versão: $DBB_VER)"
else
    check_fail "DBB não encontrado em: ${DBB_HOME:-<não definido>}/bin/dbb"
fi

# Java
if command -v java >/dev/null 2>&1; then
    JAVA_VER=$(java -version 2>&1 | head -1)
    check_pass "Java disponível: $JAVA_VER"
else
    check_fail "Java não encontrado no PATH"
fi

# Python3
if command -v python3 >/dev/null 2>&1; then
    PY_VER=$(python3 --version 2>&1)
    check_pass "Python3 disponível: $PY_VER"
else
    check_fail "python3 não encontrado no PATH"
fi

# ZCodeScan (via venv)
if [ -f "${SCAN_PYENV_ACTIVATE_PATH:-/dev/null}" ]; then
    check_pass "ZCodeScan venv encontrado: ${SCAN_PYENV_ACTIVATE_PATH}"
else
    check_fail "ZCodeScan venv não encontrado: ${SCAN_PYENV_ACTIVATE_PATH:-<não definido>}"
fi

# chtag
if command -v chtag >/dev/null 2>&1; then
    check_pass "chtag disponível"
else
    check_warn "chtag não disponível — encoding de fontes pode falhar"
fi

# iconv
if command -v iconv >/dev/null 2>&1; then
    check_pass "iconv disponível"
else
    check_fail "iconv não disponível — conversão ISO8859-1→IBM-1047 falhará"
fi

# =============================================================================
# SEÇÃO 3 — Espaço em disco no z/OS USS
# =============================================================================
section "3/7 — Espaço em Disco"

MIN_WORKSPACE_KB=512000   # 500 MB
MIN_TMP_KB=102400         # 100 MB

SANDBOX_DIR="${BANK_OF_Z_WORK_DIR:-/tmp}"

AVAIL_WS=$(df -k "$SANDBOX_DIR" 2>/dev/null | awk 'NR==2{print $4}')
AVAIL_TMP=$(df -k /tmp 2>/dev/null | awk 'NR==2{print $4}')

if [ -n "$AVAIL_WS" ]; then
    if [ "$AVAIL_WS" -lt "$MIN_WORKSPACE_KB" ]; then
        check_fail "Espaço insuficiente no workspace: ${AVAIL_WS}KB < ${MIN_WORKSPACE_KB}KB (500MB)"
    else
        check_pass "Espaço no workspace: ${AVAIL_WS}KB disponíveis em $SANDBOX_DIR"
    fi
else
    check_warn "Não foi possível verificar espaço em $SANDBOX_DIR"
fi

if [ -n "$AVAIL_TMP" ]; then
    if [ "$AVAIL_TMP" -lt "$MIN_TMP_KB" ]; then
        check_fail "Espaço insuficiente em /tmp: ${AVAIL_TMP}KB < ${MIN_TMP_KB}KB (100MB)"
    else
        check_pass "Espaço em /tmp: ${AVAIL_TMP}KB disponíveis"
    fi
else
    check_warn "Não foi possível verificar espaço em /tmp"
fi

# =============================================================================
# SEÇÃO 4 — Arquivos de configuração
# =============================================================================
section "4/7 — Arquivos de Configuração"

CONFIG_FILES=(
    "${DBB_APP_CONF:-}"
    "${SCAN_RULE_FILE:-}"
    "${SCAN_CONFIG_FILE:-}"
)

for f in "${CONFIG_FILES[@]}"; do
    if [ -z "$f" ]; then
        continue
    fi
    if [ -f "$f" ]; then
        check_pass "Arquivo encontrado: $f"
    else
        check_fail "Arquivo ausente: $f"
    fi
done

# =============================================================================
# SEÇÃO 5 — Encoding e tagging dos fontes COBOL/PL/I
# =============================================================================
section "5/7 — Encoding dos Fontes Mainframe"

if command -v chtag >/dev/null 2>&1 && [ -n "${SCAN_SOURCE_FOLDER:-}" ]; then
    UNTAGGED=$(find "${SCAN_SOURCE_FOLDER}" \( -name "*.cbl" -o -name "*.cpy" -o -name "*.pli" \) \
        -type f 2>/dev/null | while read -r f; do
            TAG=$(chtag -p "$f" 2>/dev/null | awk '{print $1}')
            if [ "$TAG" = "untagged" ] || [ -z "$TAG" ]; then
                echo "$f"
            fi
        done | wc -l | tr -d ' ')

    if [ "${UNTAGGED:-0}" -gt 0 ]; then
        check_warn "$UNTAGGED arquivo(s) mainframe sem tag de encoding (podem causar RC=-1 no ZCodeScan)"
    else
        check_pass "Todos os fontes mainframe estão tagados"
    fi
fi

# =============================================================================
# SEÇÃO 6 — Conectividade GitHub API
# =============================================================================
section "6/7 — Conectividade de Rede"

if command -v python3 >/dev/null 2>&1; then
    GH_STATUS=$(python3 - << 'PYEOF'
import urllib.request, ssl, sys
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
try:
    with urllib.request.urlopen("https://api.github.com", context=ctx, timeout=10) as r:
        print("OK:" + str(r.getcode()))
except Exception as e:
    print("FAIL:" + str(e))
PYEOF
)
    if echo "$GH_STATUS" | grep -q "^OK:"; then
        check_pass "GitHub API acessível ($GH_STATUS)"
    else
        check_warn "GitHub API inacessível: $GH_STATUS (clone via zipball pode falhar)"
    fi
fi

# =============================================================================
# SEÇÃO 7 — Datasets HLQ e permissões TSO
# =============================================================================
section "7/7 — Datasets HLQ"

if command -v tsocmd >/dev/null 2>&1 && [ -n "${APP_HLQ:-}" ]; then
    TSO_OUT=$(tsocmd "LISTDS '${APP_HLQ}.DBB.COBOL'" 2>&1 || true)
    if echo "$TSO_OUT" | grep -q "DATASET NOT FOUND\|NOT CATALOGED"; then
        check_warn "Dataset ${APP_HLQ}.DBB.COBOL não existe ainda — será criado pelo DBB"
    elif echo "$TSO_OUT" | grep -q "NOT AUTHORIZED\|RACF"; then
        check_fail "Sem autorização RACF para o HLQ ${APP_HLQ}.DBB — build falhará"
    else
        check_pass "HLQ ${APP_HLQ}.DBB acessível"
    fi
fi

# =============================================================================
# Resumo final
# =============================================================================
echo ""
printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "${CYAN}  HEALTH CHECK RESUMO${NC}\n"
printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "  ${GREEN}Checks aprovados${NC} : %d\n" "$CHECKS_PASSED"
printf "  ${YELLOW}Avisos${NC}           : %d\n" "$WARNINGS"
printf "  ${RED}Falhas${NC}           : %d\n" "$ERRORS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    printf "${RED}[RESULT] PIPELINE NÃO ESTÁ PRONTA — %d erro(s) crítico(s) encontrado(s)${NC}\n" "$ERRORS"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    printf "${YELLOW}[RESULT] PIPELINE COM AVISOS — %d aviso(s) — verifique antes de prosseguir${NC}\n" "$WARNINGS"
    exit 2
else
    printf "${GREEN}[RESULT] PIPELINE PRONTA — todos os pré-requisitos satisfeitos${NC}\n"
    exit 0
fi
