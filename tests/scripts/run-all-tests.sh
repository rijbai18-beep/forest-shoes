#!/usr/bin/env bash
# Master test runner — runs web + mobile tests and generates a report.
# Exits non-zero if ANY test fails.
#
# Usage:
#   ./run-all-tests.sh                     # web + android
#   ./run-all-tests.sh --both              # web + android + ios
#   ./run-all-tests.sh --smoke             # quick smoke only
#   ./run-all-tests.sh --web-only          # web admin only
#   ./run-all-tests.sh --mobile-only       # mobile only
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

RUN_WEB=true
RUN_MOBILE=true
MOBILE_ARGS=()

for arg in "$@"; do
  case $arg in
    --both)        MOBILE_ARGS+=("--both") ;;
    --smoke)       MOBILE_ARGS+=("--smoke"); SMOKE_WEB=true ;;
    --web-only)    RUN_MOBILE=false ;;
    --mobile-only) RUN_WEB=false ;;
    *)             MOBILE_ARGS+=("$arg") ;;
  esac
done

FAILED=0
mkdir -p "$SCRIPT_DIR/../reports"

# ── Web tests ─────────────────────────────────────────────────────────────────
if $RUN_WEB; then
  WEB_ARGS=()
  if ${SMOKE_WEB:-false}; then WEB_ARGS+=("--smoke"); fi
  if bash "$SCRIPT_DIR/run-web-tests.sh" "${WEB_ARGS[@]}"; then
    log_success "Web tests: PASSED"
  else
    log_fail "Web tests: FAILED"
    FAILED=1
  fi
fi

# ── Mobile tests ──────────────────────────────────────────────────────────────
if $RUN_MOBILE; then
  if bash "$SCRIPT_DIR/run-mobile-tests.sh" "${MOBILE_ARGS[@]}"; then
    log_success "Mobile tests: PASSED"
  else
    log_fail "Mobile tests: FAILED"
    FAILED=1
  fi
fi

# ── Report ────────────────────────────────────────────────────────────────────
REPORT=$(bash "$SCRIPT_DIR/generate-report.sh")
log_info "Report: $REPORT"

if [ $FAILED -eq 0 ]; then
  log_success "ALL TESTS PASSED — safe to commit/release"
  exit 0
else
  log_fail "TESTS FAILED — do not release"
  exit 1
fi
