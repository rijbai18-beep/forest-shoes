#!/usr/bin/env bash
# Shared helpers sourced by all test scripts.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

log_header() { echo -e "\n${BOLD}${BLUE}══ $1 ══${RESET}\n"; }
log_info()   { echo -e "  ${YELLOW}▶${RESET} $1"; }
log_success(){ echo -e "  ${GREEN}✔${RESET} $1"; }
log_fail()   { echo -e "  ${RED}✘${RESET} $1" >&2; }

# Load .env.test if it exists
ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env.test"
if [ -f "$ENV_FILE" ]; then
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
else
  echo "Warning: $ENV_FILE not found. Copy .env.test.example to .env.test and fill in values."
fi
