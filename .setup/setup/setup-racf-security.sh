#!/bin/env bash
set -e
# =============================================================================
# Script  : setup-racf-security.sh
# Summary : Creates the Bank of Z RACF groups and FACILITY profiles used by
#           the BNKSECCK security check (see .bobz/specs/BNKSECCK-technical-spec.md).
#
# Usage   : setup-racf-security.sh [--teardown]
#
# Runs on the remote z/OS USS system. Requires RACF SPECIAL authority.
#
# Idempotent: RDEFINE/ADDGROUP on an existing profile returns a non-zero
# return code that is ignored, then PERMIT reapplies the access list.
#
# Created:
#   Groups   : BANKZ (parent), BZTELLER, BZMGR, BZAUDIT, BZSECADM
#   Profiles : BANKZ.CUSTOMER, BANKZ.ACCOUNT, BANKZ.CREATE,
#              BANKZ.PAYMENT, BANKZ.DELETE (class FACILITY, UACC(NONE))
#
# Access (FACILITY):
#   BANKZ.CUSTOMER  READ: BZTELLER BZMGR BZAUDIT    UPDATE: BZMGR
#   BANKZ.ACCOUNT   READ: BZTELLER BZMGR BZAUDIT    UPDATE: BZMGR
#   BANKZ.CREATE    UPDATE: BZTELLER BZMGR
#   BANKZ.PAYMENT   UPDATE: BZTELLER BZMGR
#   BANKZ.DELETE    UPDATE: BZMGR
#
# Users are connected to a role by the security administrator with
#   CONNECT <user> GROUP(<role>)
# This script does not connect any user.
# =============================================================================

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/../config/setenv.sh"

exec > >(while IFS= read -r line; do
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" ]] && continue
    printf "${CYAN}[RACF-SECURITY]${NC} %s\n" "${line}" 2>/dev/null || true
done) 2>&1

MODE="setup"
if [[ "$1" == "--teardown" ]]; then
    MODE="teardown"
fi

PROFILES="BANKZ.CUSTOMER BANKZ.ACCOUNT BANKZ.CREATE BANKZ.PAYMENT BANKZ.DELETE"
GROUPS_BZ="BZTELLER BZMGR BZAUDIT BZSECADM"

finalize_results() {
    RC=$?
    rm -f "$SCRIPTS_DIR/../config/.env" 2> /dev/null || true
    if [[ $RC -eq 0 ]]; then
        print_success "RACF security ${MODE} completed."
    else
        print_error "RACF security ${MODE} failed (return code: $RC)."
    fi
    exit $RC
}

trap finalize_results EXIT

# Return codes of the RACF commands are ignored on purpose: a profile or
# group that already exists (setup) or no longer exists (teardown) is not an
# error. The final RLIST output shows the resulting state.
set +e

if [[ "$MODE" == "teardown" ]]; then
    print_info "Removing Bank of Z FACILITY profiles..."
    for P in $PROFILES; do
        run_tso "RDELETE FACILITY $P"
    done
    run_tso "SETROPTS RACLIST(FACILITY) REFRESH"

    print_info "Removing Bank of Z groups..."
    for G in $GROUPS_BZ; do
        run_tso "DELGROUP $G"
    done
    run_tso "DELGROUP BANKZ"
else
    print_info "Creating Bank of Z groups..."
    run_tso "ADDGROUP BANKZ SUPGROUP(SYS1)"
    for G in $GROUPS_BZ; do
        run_tso "ADDGROUP $G SUPGROUP(BANKZ)"
    done

    print_info "Creating Bank of Z FACILITY profiles..."
    for P in $PROFILES; do
        run_tso "RDEFINE FACILITY $P UACC(NONE)"
    done

    print_info "Granting access..."
    run_tso "PERMIT BANKZ.CUSTOMER CLASS(FACILITY) ID(BZTELLER BZAUDIT) ACCESS(READ)"
    run_tso "PERMIT BANKZ.CUSTOMER CLASS(FACILITY) ID(BZMGR) ACCESS(UPDATE)"
    run_tso "PERMIT BANKZ.ACCOUNT CLASS(FACILITY) ID(BZTELLER BZAUDIT) ACCESS(READ)"
    run_tso "PERMIT BANKZ.ACCOUNT CLASS(FACILITY) ID(BZMGR) ACCESS(UPDATE)"
    run_tso "PERMIT BANKZ.CREATE CLASS(FACILITY) ID(BZTELLER BZMGR) ACCESS(UPDATE)"
    run_tso "PERMIT BANKZ.PAYMENT CLASS(FACILITY) ID(BZTELLER BZMGR) ACCESS(UPDATE)"
    run_tso "PERMIT BANKZ.DELETE CLASS(FACILITY) ID(BZMGR) ACCESS(UPDATE)"

    print_info "Refreshing the FACILITY class..."
    run_tso "SETROPTS CLASSACT(FACILITY) RACLIST(FACILITY)"
    run_tso "SETROPTS RACLIST(FACILITY) REFRESH"

    print_info "Resulting profiles:"
    for P in $PROFILES; do
        run_tso "RLIST FACILITY $P"
    done
fi

set -e
