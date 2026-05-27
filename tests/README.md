# Forest Shoes — Test Automation Suite

Full regression suite covering the web admin (Playwright) and mobile app (Flutter integration tests).

---

## Quick start

```bash
# 1. Copy environment template and fill in credentials
cp tests/.env.test.example tests/.env.test

# 2. Install the pre-commit hook (once per clone)
bash tests/scripts/install-hooks.sh

# 3. Install Playwright browser
cd tests/web && npm install && npx playwright install chromium && cd ../..

# 4. Run everything
bash tests/scripts/run-all-tests.sh
```

---

## Directory layout

```
tests/
├── .env.test.example        # Credential template (copy to .env.test)
├── reports/                 # Generated reports (gitignored)
│   ├── web/                 # Playwright HTML + JUnit XML
│   ├── mobile/              # Flutter text results
│   └── summary.html         # Combined summary
├── scripts/
│   ├── _common.sh           # Shared helpers and .env.test loader
│   ├── run-all-tests.sh     # Master runner (web + mobile)
│   ├── run-web-tests.sh     # Playwright only
│   ├── run-mobile-tests.sh  # Flutter integration tests
│   ├── generate-report.sh   # Combines results into summary.html
│   └── install-hooks.sh     # Installs pre-commit git hook
└── web/
    ├── package.json
    ├── playwright.config.ts
    └── tests/
        ├── fixtures.ts      # Shared login helper + test fixture
        ├── smoke.spec.ts    # @smoke — fast login + nav check
        ├── auth.spec.ts     # Auth edge cases + redirect protection
        ├── products.spec.ts # Product list, search, columns
        ├── orders.spec.ts   # Order list, FS-format IDs, detail
        ├── settings.spec.ts # Email/bank settings cards
        └── coupons.spec.ts  # Coupon management

mobile/integration_test/
├── app_test.dart            # Main entry point (all tests here)
└── helpers/
    └── test_helper.dart     # waitForKey, loginAs, navigation helpers
```

---

## Running specific suites

### Web admin (Playwright)

```bash
# All web tests
bash tests/scripts/run-web-tests.sh

# Only @smoke tests (fast, <60s)
bash tests/scripts/run-web-tests.sh --smoke

# Headed mode (see the browser)
bash tests/scripts/run-web-tests.sh --headed
```

### Mobile (Flutter integration tests)

```bash
# Android only (default)
bash tests/scripts/run-mobile-tests.sh

# iOS only
bash tests/scripts/run-mobile-tests.sh --ios

# Both platforms
bash tests/scripts/run-mobile-tests.sh --both

# Or run directly with Flutter:
cd mobile
flutter test integration_test/app_test.dart \
  --device-id emulator-5554 \
  --dart-define=TEST_EMAIL=user@example.com \
  --dart-define=TEST_PASSWORD=Test@1234
```

### Full suite

```bash
# Web + Android
bash tests/scripts/run-all-tests.sh

# Web + Android + iOS
bash tests/scripts/run-all-tests.sh --both

# Smoke only (used by pre-commit hook)
bash tests/scripts/run-all-tests.sh --smoke
```

---

## Pre-commit hook

After running `install-hooks.sh`, every `git commit` will run the web smoke tests.
Commits are blocked if smoke tests fail.

To bypass in an emergency (never do this before a release):

```bash
SKIP_TESTS=1 git commit -m "emergency fix"
```

---

## CI / Release checklist

Before releasing a new build to Firebase App Distribution:

1. `bash tests/scripts/run-all-tests.sh --both`  — must exit 0
2. Open `tests/reports/summary.html` — must show **ALL PASSED ✔**
3. Build release APK: `cd mobile && flutter build apk --release`
4. Distribute: `firebase appdistribution:distribute ...`

---

## Environment variables (`.env.test`)

| Variable | Description |
|---|---|
| `TEST_EMAIL` | Firebase test user email (mobile app) |
| `TEST_PASSWORD` | Firebase test user password |
| `ADMIN_EMAIL` | Web admin login email |
| `ADMIN_PASSWORD` | Web admin login password |
| `WEB_ADMIN_URL` | Dev server URL (default `http://localhost:3000`) |
| `ANDROID_DEVICE_ID` | Android emulator/device ID (`flutter devices`) |
| `IOS_DEVICE_ID` | iOS simulator UDID (`xcrun simctl list`) |
