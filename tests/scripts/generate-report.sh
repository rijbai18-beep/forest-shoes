#!/usr/bin/env bash
# Combine Playwright HTML report + Flutter text results into one summary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$SCRIPT_DIR/../reports"
SUMMARY="$REPORT_DIR/summary.html"

source "$SCRIPT_DIR/_common.sh"

log_header "Generating Test Report"

mkdir -p "$REPORT_DIR"

# --- Collect Flutter results ---
MOBILE_PASS=0
MOBILE_FAIL=0
MOBILE_DETAILS=""

for result_file in "$REPORT_DIR"/mobile/*_results.txt; do
  [ -f "$result_file" ] || continue
  platform=$(basename "$result_file" _results.txt)
  pass=$(grep -c "All tests passed\|✓\|PASSED" "$result_file" 2>/dev/null || true)
  fail=$(grep -c "FAILED\|Some tests failed" "$result_file" 2>/dev/null || true)
  MOBILE_PASS=$((MOBILE_PASS + pass))
  MOBILE_FAIL=$((MOBILE_FAIL + fail))
  MOBILE_DETAILS+="<h3>$platform</h3><pre>$(cat "$result_file")</pre>"
done

# --- Playwright XML results ---
WEB_PASS=0
WEB_FAIL=0
WEB_SKIPPED=0
if [ -f "$REPORT_DIR/web/results.xml" ]; then
  WEB_PASS=$(grep -o 'tests="[0-9]*"' "$REPORT_DIR/web/results.xml" | grep -o '[0-9]*' | head -1 || echo 0)
  WEB_FAIL=$(grep -o 'failures="[0-9]*"' "$REPORT_DIR/web/results.xml" | grep -o '[0-9]*' | head -1 || echo 0)
fi

TOTAL_PASS=$((MOBILE_PASS + WEB_PASS))
TOTAL_FAIL=$((MOBILE_FAIL + WEB_FAIL))
STATUS_COLOR=$([ "$TOTAL_FAIL" -eq 0 ] && echo "#22c55e" || echo "#ef4444")
STATUS_TEXT=$([ "$TOTAL_FAIL" -eq 0 ] && echo "ALL PASSED ✔" || echo "FAILURES DETECTED ✘")

cat > "$SUMMARY" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <title>Forest Shoes — Test Report</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 20px; color: #1a1a1a; }
    h1   { color: #1B5E20; }
    .badge { display: inline-block; padding: 6px 18px; border-radius: 20px; color: white; font-weight: bold; background: ${STATUS_COLOR}; font-size: 1.1rem; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
    th { background: #f0fdf4; }
    .pass { color: #16a34a; font-weight: bold; }
    .fail { color: #dc2626; font-weight: bold; }
    pre  { background: #f5f5f5; padding: 16px; overflow-x: auto; font-size: 12px; border-radius: 6px; }
    a    { color: #1B5E20; }
  </style>
</head>
<body>
  <h1>🌲 Forest Shoes — Automation Report</h1>
  <p>Generated: $(date)</p>
  <p class="badge">${STATUS_TEXT}</p>

  <h2>Summary</h2>
  <table>
    <tr><th>Suite</th><th>Tests Passed</th><th>Tests Failed</th></tr>
    <tr>
      <td>Mobile (Flutter)</td>
      <td class="pass">$MOBILE_PASS</td>
      <td class="$([ "$MOBILE_FAIL" -eq 0 ] && echo pass || echo fail)">$MOBILE_FAIL</td>
    </tr>
    <tr>
      <td>Web Admin (Playwright)</td>
      <td class="pass">$WEB_PASS</td>
      <td class="$([ "$WEB_FAIL" -eq 0 ] && echo pass || echo fail)">$WEB_FAIL</td>
    </tr>
    <tr>
      <td><strong>Total</strong></td>
      <td class="pass"><strong>$TOTAL_PASS</strong></td>
      <td class="$([ "$TOTAL_FAIL" -eq 0 ] && echo pass || echo fail)"><strong>$TOTAL_FAIL</strong></td>
    </tr>
  </table>

  <p>📊 <a href="web/index.html">Full Playwright HTML Report →</a></p>

  <h2>Mobile Details</h2>
  ${MOBILE_DETAILS:-<p><em>No mobile results found.</em></p>}
</body>
</html>
EOF

log_success "Report saved: $SUMMARY"
echo "$SUMMARY"
