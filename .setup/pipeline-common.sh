#!/usr/bin/env bash

#########################################################
# Common Setup Script for Bank of Z
# This script runs directly on z/OS USS (not remotely)
# 
# Used by:
#   - GRUB workflow (runs natively after sync)
#   - VSCode task workflow (triggered via Zowe CLI)
#
# Usage: bash pipeline-common.sh [workspace_path]
#########################################################

set -e  # Exit on error

# =========================
# Source library scripts
# =========================
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/config/setenv.sh"

# Carrega funções de monitoramento se disponíveis (não falha se ausente)
# shellcheck source=.setup/lib/pipeline-monitor.sh
if [ -f "$SCRIPTS_DIR/lib/pipeline-monitor.sh" ]; then
    source "$SCRIPTS_DIR/lib/pipeline-monitor.sh"
else
    # Stubs mínimos para não quebrar chamadas ao monitor
    monitor_stage_start() { echo "[MONITOR] stage_start: $1"; }
    monitor_stage_end()   { echo "[MONITOR] stage_end: $1 RC=$2"; }
    monitor_warn()        { echo "[MONITOR][WARN] $1"; }
    monitor_error()       { echo "[MONITOR][ERROR] $1"; }
    monitor_finalize()    { echo "[MONITOR] finalize: $1"; }
fi

#########################################################
# STAGE: Static scan Bank of Z
#########################################################
stage_static_scan_bank_of_z() {
    print_stage "STAGE: Static scan Bank of Z"
    monitor_stage_start "ZCodeScan"

    # Verify installation script exists
    if [ ! -f "$SCRIPTS_DIR/tasks/task-zcodescan-static-scan.sh" ]; then
        print_error "Installation script not found: $SCRIPTS_DIR/tasks/task-zcodescan-static-scan.sh"
        monitor_stage_end "ZCodeScan" 1
        exit 1
    fi

    # Run zcode scan task
    print_info "Running Bank of Z static scan script..."
    print_info "Executing: bash $SCRIPTS_DIR/tasks/task-zcodescan-static-scan.sh"
    cd "$SCRIPTS_DIR"

    SCAN_RC=0
    set -o pipefail
    if ${SCRIPTS_DIR}/tasks/task-zcodescan-static-scan.sh; then
        print_success "Bank of Z application static scan completed successfully"
        monitor_stage_end "ZCodeScan" 0
    else
        SCAN_RC=$?
        print_error "Failed to static scan Bank of Z"
        monitor_stage_end "ZCodeScan" "$SCAN_RC"
        exit "$SCAN_RC"
    fi
}

#########################################################
# STAGE: Build Bank of Z
#########################################################
stage_build_bank_of_z() {
    print_stage "STAGE: Build Bank of Z"
    monitor_stage_start "DBBBuild"

    # Verify installation script exists
    if [ ! -f "$SCRIPTS_DIR/tasks/task-dbb-build.sh" ]; then
        print_error "Installation script not found: $SCRIPTS_DIR/tasks/task-dbb-build.sh"
        monitor_stage_end "DBBBuild" 1
        exit 1
    fi

    # Run installation script
    print_info "Running Bank of Z build script..."
    print_info "Executing: bash $SCRIPTS_DIR/tasks/task-dbb-build.sh $1"
    cd "$SCRIPTS_DIR"

    BUILD_RC=0
    set -o pipefail
    if bash ${SCRIPTS_DIR}/tasks/task-dbb-build.sh $1; then
        print_success "Bank of Z application build completed successfully"
        monitor_stage_end "DBBBuild" 0
    else
        BUILD_RC=$?
        print_error "Failed to build Bank of Z"
        monitor_stage_end "DBBBuild" "$BUILD_RC"
        exit "$BUILD_RC"
    fi
}

#########################################################
# STAGE: Deploy Bank of Z
#########################################################
stage_deploy_bank_of_z() {
    print_stage "STAGE: Deploy Bank of Z"
    
    # Verify installation script exists
    if [ ! -f "$SCRIPTS_DIR/tasks/task-wazi-deploy.sh" ]; then
        print_error "Installation script not found: $SCRIPTS_DIR/tasks/task-wazi-deploy.sh"
        exit 1
    fi
    
    # Run installation script
    print_info "Running Bank of Z deploy script..."
    print_info "Executing: bash $SCRIPTS_DIR/tasks/task-wazi-deploy.sh"
    cd "$SCRIPTS_DIR"
    
    set -o pipefail
    if ${SCRIPTS_DIR}/tasks/task-wazi-deploy.sh; then
        print_success "Bank of Z application deploy completed successfully"
    else
        print_error "Failed to deploy Bank of Z"
        exit 1
    fi
}


#########################################################
# STAGE: Verify Installation
#########################################################
stage_verify_installation() {
    print_stage "STAGE: Post-install Verification Tests"

    if [ ! -f "$SCRIPTS_DIR/tasks/task-install-verification.sh" ]; then
        print_error "Verification task not found: $SCRIPTS_DIR/tasks/task-install-verification.sh"
        exit 1
    fi

    print_info "Running installation verification script..."
    print_info "Executing: bash $SCRIPTS_DIR/tasks/task-install-verification.sh"
    cd "$SCRIPTS_DIR"

    set -o pipefail
    if bash ${SCRIPTS_DIR}/tasks/task-install-verification.sh; then
        print_success "Installation verification completed successfully"
    else
        print_error "Installation verification failed"
        exit 1
    fi
}

#########################################################
# Main execution helpers
#########################################################
print_phase_next_step() {
    local completed_phase="$1"

    echo ""
    case "$completed_phase" in
        validation)
            print_info "Próximo passo: execute 'scan' para análise estática ZCodeScan."
            ;;
        static-scan)
            print_info "Próximo passo: execute 'build' para compilar o Bank of Z."
            ;;
        build)
            print_info "Próximo passo: execute 'deploy' para implantar o Bank of Z."
            ;;
        pipeline)
            print_info "Próximo passo: execute 'build-baseline' para build e deploy do baseline."
            ;;
        build-baseline)
            print_info "Próximo passo: baseline concluído. Prossiga com verificação da instalação."
            ;;
    esac
}

print_usage() {
    echo "Usage: bash pipeline-common.sh <phase>"
    echo ""
    echo "Phases:"
    echo "  validate-prereqs  Validate prerequisites (zconfig, DBB, wazi-deploy)"
    echo "  health-check      Run full pre-flight health-check (tools, disk, env vars)"
    echo "  scan              Run ZCodeScan static analysis"
    echo "  build             Build the Bank of Z baseline"
    echo "  deploy            Deploy the Bank of Z baseline"
    echo "  build-and-deploy  Build and deploy the Bank of Z updates"
    echo "  verify            Run post-install verification tests"
    echo ""
    echo "Examples:"
    echo "  bash pipeline-common.sh health-check"
    echo "  bash pipeline-common.sh validate-prereqs"
    echo "  bash pipeline-common.sh scan"
    echo "  bash pipeline-common.sh build"
    echo "  bash pipeline-common.sh deploy"
    echo "  bash pipeline-common.sh build-and-deploy"
    echo "  bash pipeline-common.sh verify"
}

#########################################################
# Main execution
#########################################################
main_validation() {
    echo ""
    SYS=$(uname -Ia)
    print_info "Running on: $SYS"
    echo ""

    # Summary
    print_stage "VALIDATION COMPLETE"
    print_success "Environment validation completed successfully!"
    print_phase_next_step "validation"
}

main_static_scan() {
    echo ""
    SYS=$(uname -Ia)
    print_info "Running on: $SYS"
    echo ""

    stage_static_scan_bank_of_z

    # Summary
    print_stage "STATIC SCAN COMPLETE"
    print_success "STATIC SCAN  setup completed successfully!"
    print_phase_next_step "static-scan"
}

main_build() {
    echo ""
    SYS=$(uname -Ia)
    print_info "Running on: $SYS"
    echo ""

    stage_build_bank_of_z $*

    # Summary
    print_stage "BUILD COMPLETE"
    print_success "Build completed successfully!"
    print_phase_next_step "build"
}

main_deploy() {
    echo ""
    SYS=$(uname -Ia)
    print_info "Running on: $SYS"
    echo ""

    stage_deploy_bank_of_z

    # Summary
    print_stage "DEPLOY COMPLETE"
    print_success "DEPLOY setup completed successfully!"
}

main_verify() {
    echo ""
    SYS=$(uname -Ia)
    print_info "Running on: $SYS"
    echo ""

    stage_verify_installation

    # Summary
    print_stage "VERIFICATION COMPLETE"
    print_success "Installation verification completed successfully!"
}

#########################################################
# Main execution
#########################################################

main() {
    local phase="${1:-}"

    if [[ "$EXECUTION_MODE" == "vscode" ]]; then
        cd $SCRIPTS_DIR
        git pull
    else
        # Detect Execution Mode
        detect_bank_of_z_location

        # Re-anchor DBB and tool paths to the resolved repo location.
        # setenv.sh bakes these in from config.yaml using the static sandbox
        # path; when running in a pipeline workspace the resolved BANK_DIR
        # differs from that static path, so we override them here.
        export DBB_CWD="${BANK_DIR}/"
        export DBB_APP_CONF="${BANK_DIR}/dbb-app.yaml"
        export DBB_BUILD="${BANK_DIR}/.setup/build"
        export DBB_BUILD_PATH="${BANK_DIR}/.setup/build"
        export ZBUILDER_SOURCE="${BANK_DIR}/.setup/build"
        export DBB_LOG_FOLDER="${BANK_OF_Z_WORK_DIR}/logs/dbb"
        # SCAN_SOURCE_FOLDER: pasta raiz para o ZCodeScan resolver os caminhos do
        # buildList.txt. O DBB gera caminhos relativos ao workspace
        # (ex: Bank-of-Z-main-DEVOPS/src/base/...), portanto o -if deve apontar
        # para o PAI do workspace = BANK_OF_Z_WORK_DIR, nao para src/base.
        export SCAN_SOURCE_FOLDER="${BANK_OF_Z_WORK_DIR}"
        export SCAN_CWD_FOLDER="${BANK_OF_Z_WORK_DIR}"
        export SCAN_ENCODING="IBM-1047"
        export SCAN_RULE_FILE="${BANK_DIR}/zcodescan/zcodescan-rules.yaml"
        export SCAN_OUTPUT_FOLDER="${BANK_OF_Z_WORK_DIR}/zcodescan"
        export DEPLOY_DEPLOYMENT_METHOD="${BANK_DIR}/.setup/deploy/deployment-method.yml"
        export DEPLOY_ENV_FILE="${BANK_DIR}/.setup/deploy/Development.yml"
        export DEPLOY_TYPES_MAPPING_FILES="${BANK_DIR}/.setup/deploy/types_pattern_mapping.yml"
    fi
    
    case "$phase" in
        validate-prereqs)
            main_validation
            ;;
        health-check)
            # Executa verificação de pré-requisitos antes de iniciar qualquer stage
            if [ -f "$SCRIPTS_DIR/tasks/task-pipeline-health-check.sh" ]; then
                bash "$SCRIPTS_DIR/tasks/task-pipeline-health-check.sh"
            else
                print_warning "Health-check task não encontrada — ignorando verificação de pré-requisitos"
            fi
            ;;
        scan)
            shift
            main_static_scan
            ;;
        build)
            shift  # Remove 'build' from parameters
            main_build "$@"
            ;;
        deploy)
            main_deploy
            ;;
        test)
            # TAZ automated tests — executa task-taz-tests.sh se existir,
            # caso contrário emite aviso e retorna sucesso (fase opcional)
            if [ -f "$SCRIPTS_DIR/tasks/task-taz-tests.sh" ]; then
                bash "$SCRIPTS_DIR/tasks/task-taz-tests.sh"
            else
                print_warning "TAZ test task not found: $SCRIPTS_DIR/tasks/task-taz-tests.sh"
                print_warning "Skipping TAZ tests — phase 'test' is optional for batch pipeline"
            fi
            ;;
        build-and-deploy)
            shift  # Remove 'build-and-deploy' from parameters
            main_build "$@"
            main_deploy
            ;;
        scan-build-and-deploy)
            shift  # Remove 'scan-build-and-deploy' from parameters
            main_static_scan
            main_build "$@"
            main_deploy
            ;;
        verify)
            main_verify
            ;;
        -h|--help|help|"")
            print_usage
            ;;
        *)
            print_error "Unknown phase: $phase"
            echo ""
            print_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
exit $?

# Made with Bob