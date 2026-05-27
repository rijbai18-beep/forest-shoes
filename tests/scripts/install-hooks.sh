#!/usr/bin/env bash
# Installs the pre-commit git hook that blocks commits when tests fail.
# Run once after cloning: ./tests/scripts/install-hooks.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_FILE="$ROOT_DIR/.git/hooks/pre-commit"

if [ ! -d "$ROOT_DIR/.git" ]; then
  echo "Error: $ROOT_DIR is not a git repository." >&2
  exit 1
fi

cat > "$HOOK_FILE" <<'HOOK'
#!/usr/bin/env bash
# pre-commit: run smoke tests before every commit.
# Set SKIP_TESTS=1 to bypass in an emergency.

if [ "${SKIP_TESTS:-0}" = "1" ]; then
  echo "⚠️  SKIP_TESTS=1 — bypassing test suite (use with caution)"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../tests/scripts" 2>/dev/null && pwd)"

if [ ! -f "$SCRIPT_DIR/run-all-tests.sh" ]; then
  echo "⚠️  Test suite not found at $SCRIPT_DIR — skipping pre-commit tests"
  exit 0
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Forest Shoes Pre-commit: Running smoke tests...  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

if bash "$SCRIPT_DIR/run-all-tests.sh" --smoke --web-only; then
  echo ""
  echo "✔ Smoke tests passed — proceeding with commit"
  exit 0
else
  echo ""
  echo "✘ Smoke tests FAILED — commit blocked"
  echo "  Fix failing tests or use SKIP_TESTS=1 git commit ... (emergency only)"
  exit 1
fi
HOOK

chmod +x "$HOOK_FILE"
echo "✔ Pre-commit hook installed at $HOOK_FILE"
