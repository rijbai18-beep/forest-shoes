// Main integration test entry point.
// Run all suites: flutter test integration_test/app_test.dart
//   --dart-define=TEST_EMAIL=user@example.com
//   --dart-define=TEST_PASSWORD=YourPassword
//   -d <device-id>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:forest_shoes/main.dart' as app;
import 'helpers/test_helper.dart';
import 'package:forest_shoes/config/test_keys.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Smoke: full customer journey ──────────────────────────────────────────
  testWidgets('SMOKE: full customer journey — login → add product → checkout → view order', (tester) async {
    app.main();
    await pumpFor(tester, const Duration(seconds: 5));

    // 1. Login
    await waitForKey(tester, TestKeys.emailField, timeout: const Duration(seconds: 15));
    await tester.enterText(find.byKey(const ValueKey(TestKeys.emailField)), testEmail);
    await tester.enterText(find.byKey(const ValueKey(TestKeys.passwordField)), testPassword);
    await tester.tap(find.byKey(const ValueKey(TestKeys.signInButton)));
    await pumpFor(tester, const Duration(seconds: 6));
    await waitForText(tester, 'Forest Shoes', timeout: const Duration(seconds: 20));

    // 2. Navigate to shop and open first product
    await goToShop(tester);
    await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
    await tester.tap(find.byKey(const ValueKey(TestKeys.productCard)).first);
    await settle(tester);

    // 3. Add to cart
    await waitForKey(tester, TestKeys.addToCartButton, timeout: const Duration(seconds: 10));
    await tester.tap(find.byKey(const ValueKey(TestKeys.addToCartButton)));
    await pumpFor(tester, const Duration(seconds: 2));

    // 4. Open cart and proceed
    await goToCart(tester);
    await waitForKey(tester, TestKeys.checkoutButton, timeout: const Duration(seconds: 10));
    await tester.tap(find.byKey(const ValueKey(TestKeys.checkoutButton)));
    await settle(tester);

    // 5. Fill address if fields are empty, then place order
    await waitForKey(tester, TestKeys.placeOrderButton, timeout: const Duration(seconds: 15));

    final nameField    = find.byKey(const ValueKey(TestKeys.checkoutNameField));
    final phoneField   = find.byKey(const ValueKey(TestKeys.checkoutPhoneField));
    final addressField = find.byKey(const ValueKey(TestKeys.checkoutAddressField));
    final cityField    = find.byKey(const ValueKey(TestKeys.checkoutCityField));

    Future<void> fillIfEmpty(Finder f, String value) async {
      if (!tester.any(f)) return;
      final ctrl = tester.widget<TextField>(f).controller;
      if (ctrl == null || ctrl.text.isEmpty) {
        await tester.enterText(f, value);
        await tester.pump();
      }
    }

    await fillIfEmpty(nameField, 'Test Customer');
    await fillIfEmpty(phoneField, '0771234567');
    await fillIfEmpty(addressField, '123 Test Street');
    await fillIfEmpty(cityField, 'Colombo');

    await tester.tap(find.byKey(const ValueKey(TestKeys.placeOrderButton)));
    await pumpFor(tester, const Duration(seconds: 30));

    // 6. Verify order success
    await waitForKey(tester, TestKeys.orderSuccessDialog, timeout: const Duration(seconds: 10));
    expect(find.byKey(const ValueKey(TestKeys.orderSuccessDialog)), findsOneWidget);
    expect(find.textContaining('FS'), findsWidgets);

    // Dismiss dialog
    final trackBtn = find.byKey(const ValueKey(TestKeys.trackOrderButton));
    if (tester.any(trackBtn)) {
      await tester.tap(trackBtn);
      await settle(tester);
    } else {
      await tester.tap(find.text('OK').last);
      await settle(tester);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  // ── Auth edge cases ───────────────────────────────────────────────────────
  testWidgets('AUTH: empty form shows validation errors', (tester) async {
    app.main();
    await pumpFor(tester, const Duration(seconds: 5));
    await waitForKey(tester, TestKeys.signInButton, timeout: const Duration(seconds: 15));
    await tester.tap(find.byKey(const ValueKey(TestKeys.signInButton)));
    await settle(tester);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('AUTH: invalid credentials shows error snackbar', (tester) async {
    app.main();
    await pumpFor(tester, const Duration(seconds: 5));
    await waitForKey(tester, TestKeys.emailField, timeout: const Duration(seconds: 15));
    await tester.enterText(find.byKey(const ValueKey(TestKeys.emailField)), 'nobody@example.com');
    await tester.enterText(find.byKey(const ValueKey(TestKeys.passwordField)), 'wrongpassword');
    await tester.tap(find.byKey(const ValueKey(TestKeys.signInButton)));
    await pumpFor(tester, const Duration(seconds: 8));
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('AUTH: guest browse navigates to home', (tester) async {
    app.main();
    await pumpFor(tester, const Duration(seconds: 5));
    await waitForKey(tester, TestKeys.guestButton, timeout: const Duration(seconds: 15));
    await tester.tap(find.byKey(const ValueKey(TestKeys.guestButton)));
    await settle(tester);
    await waitForText(tester, 'Forest Shoes', timeout: const Duration(seconds: 15));
  });

  // ── Cart regression ───────────────────────────────────────────────────────
  testWidgets('CART: guest user sees sign-in prompt instead of checkout', (tester) async {
    app.main();
    await pumpFor(tester, const Duration(seconds: 5));
    // Browse as guest
    await waitForKey(tester, TestKeys.guestButton, timeout: const Duration(seconds: 15));
    await tester.tap(find.byKey(const ValueKey(TestKeys.guestButton)));
    await settle(tester);

    // Add product to cart
    await goToShop(tester);
    await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
    await tester.tap(find.byKey(const ValueKey(TestKeys.productCard)).first);
    await settle(tester);
    await waitForKey(tester, TestKeys.addToCartButton, timeout: const Duration(seconds: 10));
    await tester.tap(find.byKey(const ValueKey(TestKeys.addToCartButton)));
    await pumpFor(tester, const Duration(seconds: 2));

    await goToCart(tester);
    await settle(tester);

    // Guest should see "Sign In to Checkout" not "Proceed to Checkout"
    expect(find.text('Sign In to Checkout'), findsOneWidget);
  });

  // ── Firebase permissions ──────────────────────────────────────────────────
  testWidgets('PERMISSIONS: order placement does not throw permission-denied', (tester) async {
    app.main();
    await pumpFor(tester, const Duration(seconds: 5));

    await loginAs(tester);

    // Add product
    await goToShop(tester);
    await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
    await tester.tap(find.byKey(const ValueKey(TestKeys.productCard)).first);
    await settle(tester);
    await waitForKey(tester, TestKeys.addToCartButton, timeout: const Duration(seconds: 10));
    await tester.tap(find.byKey(const ValueKey(TestKeys.addToCartButton)));
    await pumpFor(tester, const Duration(seconds: 2));

    // Checkout
    await goToCart(tester);
    await waitForKey(tester, TestKeys.checkoutButton, timeout: const Duration(seconds: 10));
    await tester.tap(find.byKey(const ValueKey(TestKeys.checkoutButton)));
    await settle(tester);
    await waitForKey(tester, TestKeys.placeOrderButton, timeout: const Duration(seconds: 15));

    final nameField    = find.byKey(const ValueKey(TestKeys.checkoutNameField));
    final phoneField   = find.byKey(const ValueKey(TestKeys.checkoutPhoneField));
    final addressField = find.byKey(const ValueKey(TestKeys.checkoutAddressField));
    final cityField    = find.byKey(const ValueKey(TestKeys.checkoutCityField));

    Future<void> fillIfEmpty(Finder f, String value) async {
      if (!tester.any(f)) return;
      final ctrl = tester.widget<TextField>(f).controller;
      if (ctrl == null || ctrl.text.isEmpty) {
        await tester.enterText(f, value);
        await tester.pump();
      }
    }

    await fillIfEmpty(nameField, 'QA Customer');
    await fillIfEmpty(phoneField, '0779876543');
    await fillIfEmpty(addressField, '456 QA Road');
    await fillIfEmpty(cityField, 'Kandy');

    await tester.tap(find.byKey(const ValueKey(TestKeys.placeOrderButton)));
    await pumpFor(tester, const Duration(seconds: 30));

    // Must NOT show a permission-denied error snackbar
    final permDenied = find.textContaining('permission-denied');
    expect(permDenied, findsNothing, reason: 'Firestore permission-denied error should not occur');

    // Must show success dialog
    expect(find.byKey(const ValueKey(TestKeys.orderSuccessDialog)), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
