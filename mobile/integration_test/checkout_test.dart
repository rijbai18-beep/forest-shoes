import 'package:flutter_test/flutter_test.dart';
import 'package:forest_shoes/config/test_keys.dart';
import 'helpers/test_helper.dart';

void checkoutTests(WidgetTester tester) {
  group('Checkout', () {
    setUpAll(() async {
      await loginAs(tester);
      // Ensure at least one item is in cart before checkout tests
      await goToShop(tester);
      await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
      await tester.tap(find.byKey(const ValueKey(TestKeys.productCard)).first);
      await settle(tester);
      await waitForKey(tester, TestKeys.addToCartButton, timeout: const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey(TestKeys.addToCartButton)));
      await pumpFor(tester, const Duration(seconds: 2));
    });

    testWidgets('proceed to checkout from cart', (tester) async {
      await goToCart(tester);
      await waitForKey(tester, TestKeys.checkoutButton, timeout: const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey(TestKeys.checkoutButton)));
      await settle(tester);
      // Checkout screen should have the place order button
      await waitForKey(tester, TestKeys.placeOrderButton, timeout: const Duration(seconds: 15));
      expect(find.byKey(const ValueKey(TestKeys.placeOrderButton)), findsOneWidget);
    });

    testWidgets('checkout form is pre-filled with user data', (tester) async {
      await goToCart(tester);
      await waitForKey(tester, TestKeys.checkoutButton, timeout: const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey(TestKeys.checkoutButton)));
      await settle(tester);
      await waitForKey(tester, TestKeys.placeOrderButton, timeout: const Duration(seconds: 15));
      // Name field should be pre-filled
      final nameField = find.byKey(const ValueKey(TestKeys.checkoutNameField));
      if (tester.any(nameField)) {
        final widget = tester.widget<TextField>(nameField);
        expect(widget.controller?.text.isNotEmpty ?? false, isTrue);
      }
    });

    testWidgets('form validation prevents empty submission', (tester) async {
      await goToCart(tester);
      await waitForKey(tester, TestKeys.checkoutButton, timeout: const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey(TestKeys.checkoutButton)));
      await settle(tester);
      await waitForKey(tester, TestKeys.placeOrderButton, timeout: const Duration(seconds: 15));

      // Clear all fields then try to place order
      final nameField = find.byKey(const ValueKey(TestKeys.checkoutNameField));
      if (tester.any(nameField)) {
        await tester.enterText(nameField, '');
      }
      await tester.tap(find.byKey(const ValueKey(TestKeys.placeOrderButton)));
      await settle(tester);
      // Should stay on checkout screen (no success dialog)
      expect(find.byKey(const ValueKey(TestKeys.placeOrderButton)), findsOneWidget);
    });

    testWidgets('full order placement flow', (tester) async {
      await goToCart(tester);
      await waitForKey(tester, TestKeys.checkoutButton, timeout: const Duration(seconds: 10));
      await tester.tap(find.byKey(const ValueKey(TestKeys.checkoutButton)));
      await settle(tester);
      await waitForKey(tester, TestKeys.placeOrderButton, timeout: const Duration(seconds: 15));

      // Fill in all required address fields
      final nameField    = find.byKey(const ValueKey(TestKeys.checkoutNameField));
      final phoneField   = find.byKey(const ValueKey(TestKeys.checkoutPhoneField));
      final addressField = find.byKey(const ValueKey(TestKeys.checkoutAddressField));
      final cityField    = find.byKey(const ValueKey(TestKeys.checkoutCityField));

      if (tester.any(nameField)) {
        await tester.enterText(nameField, 'Test Customer');
      }
      if (tester.any(phoneField)) {
        await tester.enterText(phoneField, '0771234567');
      }
      if (tester.any(addressField)) {
        await tester.enterText(addressField, '123 Test Street');
      }
      if (tester.any(cityField)) {
        await tester.enterText(cityField, 'Colombo');
      }
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey(TestKeys.placeOrderButton)));
      // Wait up to 30 seconds for order to be placed (network call)
      await pumpFor(tester, const Duration(seconds: 30));

      // Expect success dialog with order number
      await waitForKey(tester, TestKeys.orderSuccessDialog, timeout: const Duration(seconds: 10));
      expect(find.byKey(const ValueKey(TestKeys.orderSuccessDialog)), findsOneWidget);
      // Order number format: FS followed by digits
      expect(find.textContaining('FS'), findsWidgets);
    });
  });
}
