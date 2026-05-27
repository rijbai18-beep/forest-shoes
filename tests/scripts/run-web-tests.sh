#!/usr/bin/env bash
# Run Playwright web admin tests.
# Usage: ./run-web-tests.sh [--smoke] [--headed]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$SCRIPT_DIR/../web"
REPORT_DIR="$SCRIPT_DIR/../reports/web"

source "$SCRIPT_DIR/_common.sh"

SMOKE=false
HEADED=false
for arg in "$@"; do
  case $arg in
    --smoke)  SMOKE=true ;;
    --headed) HEADED=true ;;
  esac
done

log_header "Web Admin Tests (Playwright)"

# Install deps if needed
if [ ! -d "$WEB_DIR/node_modules" ]; then
  log_info "Installing Playwright dependencies..."
  cd "$WEB_DIR" && npm install
  npx playwright install chromium
fi

cd "$WEB_DIR"

ARGS=()
if $SMOKE; then ARGS+=("--grep" "@smoke"); fi
if $HEADED; then HEADED=true; fi

export HEADED=$HEADED

log_info "Running tests..."
if npx playwright test "${ARGS[@]}" --reporter=html,list; then
  log_success "All web tests passed"
  exit 0
else
  log_fail "Web tests failed — see $REPORT_DIR/index.html"
  exit 1
fi
