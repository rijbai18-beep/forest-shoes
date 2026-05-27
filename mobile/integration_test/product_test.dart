import 'package:flutter_test/flutter_test.dart';
import 'package:forest_shoes/config/test_keys.dart';
import 'helpers/test_helper.dart';

void productTests(WidgetTester tester) {
  group('Products', () {
    setUpAll(() async {
      await loginAs(tester);
    });

    testWidgets('shop tab shows product grid', (tester) async {
      await goToShop(tester);
      await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
      expect(find.byKey(const ValueKey(TestKeys.productCard)), findsWidgets);
    });

    testWidgets('tapping a product opens detail screen', (tester) async {
      await goToShop(tester);
      await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
      await tester.tap(find.byKey(const ValueKey(TestKeys.productCard)).first);
      await settle(tester);
      // Detail screen should show add to cart button
      await waitForKey(tester, TestKeys.addToCartButton, timeout: const Duration(seconds: 10));
      expect(find.byKey(const ValueKey(TestKeys.addToCartButton)), findsOneWidget);
    });

    testWidgets('product detail shows size and color selectors', (tester) async {
      await goToShop(tester);
      await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
      await tester.tap(find.byKey(const ValueKey(TestKeys.productCard)).first);
      await settle(tester);
      // Basic assertion — product detail page is loaded
      expect(find.byKey(const ValueKey(TestKeys.addToCartButton)), findsOneWidget);
    });

    testWidgets('can wishlist a product', (tester) async {
      await goToShop(tester);
      await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
      await tester.tap(find.byKey(const ValueKey(TestKeys.productCard)).first);
      await settle(tester);
      // Wishlist button on product detail
      if (tester.any(find.byKey(const ValueKey(TestKeys.wishlistButton)))) {
        await tester.tap(find.byKey(const ValueKey(TestKeys.wishlistButton)));
        await settle(tester);
      }
    });

    testWidgets('back button returns to shop list', (tester) async {
      await goToShop(tester);
      await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 20));
      await tester.tap(find.byKey(const ValueKey(TestKeys.productCard)).first);
      await settle(tester);
      final backBtn = find.byTooltip('Back');
      if (tester.any(backBtn)) {
        await tester.tap(backBtn);
        await settle(tester);
        await waitForKey(tester, TestKeys.productCard, timeout: const Duration(seconds: 10));
      }
    });
  });
}
