import 'package:flutter_test/flutter_test.dart';
import 'package:forest_shoes/config/test_keys.dart';
import 'helpers/test_helper.dart';

void authTests(WidgetTester tester) {
  group('Auth', () {
    testWidgets('login screen renders correctly', (tester) async {
      await waitForKey(tester, TestKeys.emailField);
      expect(find.byKey(const ValueKey(TestKeys.emailField)), findsOneWidget);
      expect(find.byKey(const ValueKey(TestKeys.passwordField)), findsOneWidget);
      expect(find.byKey(const ValueKey(TestKeys.signInButton)), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await waitForKey(tester, TestKeys.signInButton);
      await tester.tap(find.byKey(const ValueKey(TestKeys.signInButton)));
      await settle(tester);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows error on invalid credentials', (tester) async {
      await waitForKey(tester, TestKeys.emailField);
      await tester.enterText(find.byKey(const ValueKey(TestKeys.emailField)), 'bad@example.com');
      await tester.enterText(find.byKey(const ValueKey(TestKeys.passwordField)), 'wrongpass');
      await tester.tap(find.byKey(const ValueKey(TestKeys.signInButton)));
      await pumpFor(tester, const Duration(seconds: 6));
      // Should show a snackbar with an error message
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('guest browsing navigates to home', (tester) async {
      await continueAsGuest(tester);
      await waitForText(tester, 'Forest Shoes');
    });

    testWidgets('successful login navigates to home', (tester) async {
      await loginAs(tester);
      await waitForText(tester, 'Forest Shoes');
    });

    testWidgets('forgot password dialog appears', (tester) async {
      await waitForText(tester, 'Forgot Password?');
      await tester.tap(find.text('Forgot Password?'));
      await settle(tester);
      expect(find.text('Reset Password'), findsOneWidget);
      // Dismiss
      await tester.tap(find.text('Cancel'));
      await settle(tester);
    });
  });
}
