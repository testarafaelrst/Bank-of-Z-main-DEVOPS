#!/usr/bin/env bash
# =============================================================================
# Script  : pipeline-monitor.sh
# Summary : Monitoramento centralizado e logging estruturado da pipeline
#           ZCode → Build do Bank of Z
#
# Funcionalidades:
#   - Logging estruturado com timestamp e nível (INFO/WARN/ERROR/METRIC)
#   - Rastreamento de duração de cada estágio
#   - Captura de métricas: linhas compiladas, RC, artefatos gerados
#   - Geração de relatório JSON de execução (pipeline-run-report.json)
#   - Emite alertas inline (::notice::, ::warning::, ::error:: do GitHub Actions)
#   - Detecta padrões de erro recorrentes e os categoriza
#
# Uso:
#   source pipeline-monitor.sh          # carrega funções
#   monitor_stage_start "ZCodeScan"
#   ... (executar stage) ...
#   monitor_stage_end "ZCodeScan" $RC
#
# Saída:
#   ${MONITOR_LOG_DIR}/pipeline-run-report.json
#   ${MONITOR_LOG_DIR}/pipeline-monitor.log
# =============================================================================

MONITOR_LOG_DIR="${BANK_OF_Z_WORK_DIR:-/tmp}/logs/monitor"
MONITOR_LOG_FILE="${MONITOR_LOG_DIR}/pipeline-monitor.log"
MONITOR_REPORT="${MONITOR_LOG_DIR}/pipeline-run-report.json"
MONITOR_START_TS=$(date +%s)
MONITOR_RUN_ID="${GITHUB_RUN_NUMBER:-local_$(date +%Y%m%d_%H%M%S)}"
MONITOR_BRANCH="${GITHUB_REF_NAME:-unknown}"
MONITOR_TRIGGER="${GITHUB_EVENT_NAME:-manual}"

mkdir -p "$MONITOR_LOG_DIR"

# Inicializa o relatório JSON
cat > "$MONITOR_REPORT" << EOF
{
  "run_id": "${MONITOR_RUN_ID}",
  "branch": "${MONITOR_BRANCH}",
  "trigger": "${MONITOR_TRIGGER}",
  "start_time": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "RUNNING",
  "stages": [],
  "metrics": {},
  "errors": [],
  "warnings": []
}
EOF

# Variáveis de rastreamento por estágio
declare -A _STAGE_START_TS
declare -A _STAGE_STATUS
declare -A _STAGE_METRICS

# ─── Logging ─────────────────────────────────────────────────────────────────

_log() {
    local level="$1"
    local msg="$2"
    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "${ts} [${level}] ${msg}" | tee -a "$MONITOR_LOG_FILE"
}

monitor_info()    { _log "INFO " "$1"; }
monitor_warn()    { _log "WARN " "$1"; echo "::warning:: $1"; }
monitor_error()   { _log "ERROR" "$1"; echo "::error:: $1"; }
monitor_metric()  { _log "METR " "$1"; }

# ─── Controle de estágios ─────────────────────────────────────────────────────

monitor_stage_start() {
    local stage="$1"
    local ts
    ts=$(date +%s)
    _STAGE_START_TS["$stage"]=$ts
    _STAGE_STATUS["$stage"]="RUNNING"
    monitor_info "=== STAGE START: $stage ==="
    echo "::group::🔄 Stage: $stage"
}

monitor_stage_end() {
    local stage="$1"
    local rc="${2:-0}"
    local start_ts="${_STAGE_START_TS["$stage"]:-$(date +%s)}"
    local end_ts
    end_ts=$(date +%s)
    local duration=$((end_ts - start_ts))

    if [ "$rc" -eq 0 ]; then
        _STAGE_STATUS["$stage"]="SUCCESS"
        monitor_info "=== STAGE END: $stage | RC=$rc | Duração=${duration}s ==="
        echo "::notice:: ✅ $stage concluído (${duration}s)"
    elif [ "$rc" -le 4 ]; then
        _STAGE_STATUS["$stage"]="WARNING"
        monitor_warn "=== STAGE END (WARNING): $stage | RC=$rc | Duração=${duration}s ==="
    else
        _STAGE_STATUS["$stage"]="FAILED"
        monitor_error "=== STAGE FAILED: $stage | RC=$rc | Duração=${duration}s ==="
        _record_error "$stage" "Stage falhou com RC=$rc após ${duration}s"
    fi

    _update_report_stage "$stage" "${_STAGE_STATUS["$stage"]}" "$duration" "$rc"
    echo "::endgroup::"
}

# ─── Detecção de padrões de erro conhecidos ──────────────────────────────────

monitor_check_dbb_log() {
    local log_file="$1"
    local stage="${2:-DBB}"

    if [ ! -f "$log_file" ]; then
        monitor_warn "Log DBB não encontrado: $log_file"
        return
    fi

    # Padrões de erro recorrentes identificados na análise
    declare -A ERROR_PATTERNS
    ERROR_PATTERNS["EDC5003I"]="Truncação de dataset — lrecl insuficiente (DBB copyMode mismatch)"
    ERROR_PATTERNS["BGZZB0048E"]="Script Groovy com lifecycle inválido para DBB 3.x (AbstractLoader/AbstractTask ausente)"
    ERROR_PATTERNS["BGZZB0008E"]="Transfer falhou — dataset de destino não existe (normal em preview/scan)"
    ERROR_PATTERNS["IEW2646E"]="Link-edit falhou — módulo externo não encontrado no LOAD"
    ERROR_PATTERNS["IGY"]="Erro de compilação COBOL (ver código IGY específico no log)"
    ERROR_PATTERNS["Build Status : ERROR"]="Build DBB encerrado com status ERROR — verificar log completo"
    ERROR_PATTERNS["RC=-1"]="ZCodeScan retornou RC=-1 — problema de encoding (AUTOCVT/chtag)"
    ERROR_PATTERNS["not in truststore"]="Certificado SSL não confiável — GitHub API pode falhar no clone"
    ERROR_PATTERNS["IGYPS0001-W"]="Aviso de sintaxe COBOL — espaço ausente antes de operador"
    ERROR_PATTERNS["NEXUS_PASSWORD"]="Variável de credencial NEXUS não definida — build pode falhar"

    local found_critical=false
    for pattern in "${!ERROR_PATTERNS[@]}"; do
        if grep -q "$pattern" "$log_file" 2>/dev/null; then
            local desc="${ERROR_PATTERNS[$pattern]}"
            if [[ "$pattern" == "BGZZB0008E" ]]; then
                monitor_info "Padrão esperado detectado: $pattern — $desc"
            elif [[ "$pattern" == "IGYPS0001-W" ]]; then
                monitor_warn "Padrão detectado: $pattern — $desc"
            else
                monitor_error "Padrão de erro detectado: $pattern — $desc"
                _record_error "$stage" "$pattern: $desc"
                found_critical=true
            fi
        fi
    done

    # Métricas de compilação
    local files_processed
    files_processed=$(grep -oP "Total files processed : \K[0-9]+" "$log_file" 2>/dev/null | tail -1 || echo "0")
    if [ -n "$files_processed" ]; then
        monitor_metric "Arquivos processados pelo DBB: $files_processed"
        _update_metric "dbb_files_processed" "$files_processed"
    fi

    # RC máximo de compilação
    local max_rc
    max_rc=$(grep -oP '"rc": \K[0-9]+' "$log_file" 2>/dev/null | sort -n | tail -1 || echo "N/A")
    if [ "$max_rc" != "N/A" ]; then
        monitor_metric "RC máximo de compilação: $max_rc"
        _update_metric "compilation_max_rc" "$max_rc"
    fi

    $found_critical && return 1
    return 0
}

monitor_check_zcodescan_log() {
    local log_file="$1"

    if [ ! -f "$log_file" ]; then
        monitor_warn "Log ZCodeScan não encontrado: $log_file"
        return
    fi

    # Extrair RC do scan
    local scan_rc
    scan_rc=$(grep -oP "RC=\K-?[0-9]+" "$log_file" 2>/dev/null | tail -1 || echo "N/A")
    if [ "$scan_rc" != "N/A" ]; then
        monitor_metric "ZCodeScan RC: $scan_rc"
        _update_metric "zcodescan_rc" "$scan_rc"
        if [ "$scan_rc" -gt 4 ]; then
            monitor_error "ZCodeScan RC=$scan_rc excede maxRC=4 — violações críticas encontradas"
        elif [ "$scan_rc" -eq 4 ]; then
            monitor_warn "ZCodeScan RC=4 — violações de nível INFO/WARNING encontradas"
        fi
    fi

    # Contar violações
    local violations
    violations=$(grep -c "VIOLATION\|violation" "$log_file" 2>/dev/null || echo "0")
    monitor_metric "ZCodeScan violações detectadas: $violations"
    _update_metric "zcodescan_violations" "$violations"
}

# ─── Atualização do relatório JSON ───────────────────────────────────────────

_update_report_stage() {
    local stage="$1"
    local status="$2"
    local duration="$3"
    local rc="$4"

    # Usa Python3 para manipulação segura do JSON
    python3 - "$MONITOR_REPORT" "$stage" "$status" "$duration" "$rc" << 'PYEOF'
import sys, json
report_file, stage, status, duration, rc = sys.argv[1:]
with open(report_file) as f:
    report = json.load(f)
report["stages"].append({
    "name": stage,
    "status": status,
    "duration_seconds": int(duration),
    "rc": int(rc),
    "timestamp": __import__('datetime').datetime.utcnow().isoformat() + "Z"
})
with open(report_file, 'w') as f:
    json.dump(report, f, indent=2)
PYEOF
}

_record_error() {
    local stage="$1"
    local msg="$2"

    python3 - "$MONITOR_REPORT" "$stage" "$msg" << 'PYEOF'
import sys, json
report_file, stage, msg = sys.argv[1:]
with open(report_file) as f:
    report = json.load(f)
report["errors"].append({"stage": stage, "message": msg,
    "timestamp": __import__('datetime').datetime.utcnow().isoformat() + "Z"})
with open(report_file, 'w') as f:
    json.dump(report, f, indent=2)
PYEOF
}

_update_metric() {
    local key="$1"
    local val="$2"

    python3 - "$MONITOR_REPORT" "$key" "$val" << 'PYEOF'
import sys, json
report_file, key, val = sys.argv[1:]
with open(report_file) as f:
    report = json.load(f)
try:
    report["metrics"][key] = int(val)
except ValueError:
    report["metrics"][key] = val
with open(report_file, 'w') as f:
    json.dump(report, f, indent=2)
PYEOF
}

# ─── Finalização do relatório ─────────────────────────────────────────────────

monitor_finalize() {
    local final_status="${1:-UNKNOWN}"
    local end_ts
    end_ts=$(date +%s)
    local total_duration=$((end_ts - MONITOR_START_TS))

    python3 - "$MONITOR_REPORT" "$final_status" "$total_duration" << 'PYEOF'
import sys, json
report_file, status, duration = sys.argv[1:]
with open(report_file) as f:
    report = json.load(f)
report["status"] = status
report["end_time"] = __import__('datetime').datetime.utcnow().isoformat() + "Z"
report["total_duration_seconds"] = int(duration)
with open(report_file, 'w') as f:
    json.dump(report, f, indent=2)
PYEOF

    monitor_info "Pipeline finalizada — status=$final_status | duração total=${total_duration}s"
    monitor_info "Relatório gerado: $MONITOR_REPORT"
    monitor_info "Log completo: $MONITOR_LOG_FILE"

    if [ "$final_status" = "SUCCESS" ]; then
        echo "::notice:: ✅ Pipeline Bank of Z concluída com sucesso (${total_duration}s)"
    else
        echo "::error:: ❌ Pipeline Bank of Z FALHOU — status=$final_status | veja $MONITOR_REPORT"
    fi
}
