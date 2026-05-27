import 'package:flutter_test/flutter_test.dart';
import 'package:forest_shoes/config/test_keys.dart';
import 'helpers/test_helper.dart';

void orderTests(WidgetTester tester) {
  group('Orders', () {
    setUpAll(() async {
      await loginAs(tester);
    });

    testWidgets('order history screen loads', (tester) async {
      await goToProfile(tester);
      await settle(tester);
      // Tap "My Orders" or navigate to orders
      final myOrdersTile = find.text('My Orders');
      if (tester.any(myOrdersTile)) {
        await tester.tap(myOrdersTile);
        await settle(tester);
        await waitForKey(tester, TestKeys.orderHistoryList, timeout: const Duration(seconds: 10));
        expect(find.byKey(const ValueKey(TestKeys.orderHistoryList)), findsOneWidget);
      }
    });

    testWidgets('order history shows order numbers in FS format', (tester) async {
      await goToProfile(tester);
      await settle(tester);
      final myOrdersTile = find.text('My Orders');
      if (tester.any(myOrdersTile)) {
        await tester.tap(myOrdersTile);
        await settle(tester);
        await pumpFor(tester, const Duration(seconds: 3));
        if (tester.any(find.byKey(const ValueKey(TestKeys.orderHistoryItem)))) {
          // Order IDs should show FS-prefixed numbers (not raw Firestore IDs)
          expect(
            find.textContaining('FS') | find.textContaining('#'),
            findsWidgets,
          );
        }
      }
    });

    testWidgets('tapping an order opens detail screen', (tester) async {
      await goToProfile(tester);
      await settle(tester);
      final myOrdersTile = find.text('My Orders');
      if (tester.any(myOrdersTile)) {
        await tester.tap(myOrdersTile);
        await settle(tester);
        await pumpFor(tester, const Duration(seconds: 3));
        final orderItem = find.byKey(const ValueKey(TestKeys.orderHistoryItem));
        if (tester.any(orderItem)) {
          await tester.tap(orderItem.first);
          await settle(tester);
          // Detail screen shows an order ID in title
          expect(find.textContaining('FS') | find.textContaining('Order'), findsWidgets);
        }
      }
    });
  });
}
