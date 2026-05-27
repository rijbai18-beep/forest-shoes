#!/usr/bin/env bash
# Run Flutter integration tests on Android and/or iOS simulators.
# Usage:
#   ./run-mobile-tests.sh               # Android only
#   ./run-mobile-tests.sh --ios         # iOS only (Mac required)
#   ./run-mobile-tests.sh --both        # Android + iOS
#   ./run-mobile-tests.sh --smoke       # Quick smoke test only
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$SCRIPT_DIR/../../mobile"
REPORT_DIR="$SCRIPT_DIR/../reports/mobile"

source "$SCRIPT_DIR/_common.sh"

RUN_ANDROID=true
RUN_IOS=false
SMOKE_ONLY=false

for arg in "$@"; do
  case $arg in
    --ios)   RUN_ANDROID=false; RUN_IOS=true ;;
    --both)  RUN_ANDROID=true;  RUN_IOS=true ;;
    --smoke) SMOKE_ONLY=true ;;
  esac
done

ANDROID_DEVICE="${ANDROID_DEVICE_ID:-}"
IOS_DEVICE="${IOS_DEVICE_ID:-}"

TEST_FILE="integration_test/app_test.dart"
DART_DEFINES="--dart-define=TEST_EMAIL=${TEST_EMAIL:-} --dart-define=TEST_PASSWORD=${TEST_PASSWORD:-}"

mkdir -p "$REPORT_DIR"

run_on_device() {
  local platform="$1"
  local device_id="$2"
  local label="$3"
  local result_file="$REPORT_DIR/${platform}_results.txt"

  log_header "Flutter Integration Tests — $label"

  if [ -z "$device_id" ]; then
    log_fail "No device ID set for $platform. Set ${platform^^}_DEVICE_ID in .env.test"
    return 1
  fi

  cd "$MOBILE_DIR"

  # Ensure dependencies are fetched
  flutter pub get --quiet

  local test_args=("--device-id" "$device_id" $DART_DEFINES "$TEST_FILE")
  if $SMOKE_ONLY; then
    test_args+=("--name" "SMOKE")
  fi

  log_info "Running on device: $device_id"
  if flutter test "${test_args[@]}" 2>&1 | tee "$result_file"; then
    log_success "$label tests passed"
    return 0
  else
    log_fail "$label tests failed — see $result_file"
    return 1
  fi
}

FAILED=0

if $RUN_ANDROID; then
  run_on_device "android" "$ANDROID_DEVICE" "Android" || FAILED=1
fi

if $RUN_IOS; then
  run_on_device "ios" "$IOS_DEVICE" "iOS" || FAILED=1
fi

if [ $FAILED -eq 0 ]; then
  log_success "All mobile tests passed"
  exit 0
else
  log_fail "One or more mobile test suites failed"
  exit 1
fi
