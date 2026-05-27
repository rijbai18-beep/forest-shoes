import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:forest_shoes/config/test_keys.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:integration_test/integration_test.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

// Set via --dart-define=TEST_EMAIL=... TEST_PASSWORD=...
const testEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: 'testuser@forestshoes.com');
const testPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: 'Test@1234');

// ── Setup ─────────────────────────────────────────────────────────────────────

void setupIntegrationTestBinding() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
}

// ── Navigation ────────────────────────────────────────────────────────────────

/// Waits until a widget with [key] is visible, pumping frames.
Future<void> waitForKey(WidgetTester tester, String key, {Duration timeout = const Duration(seconds: 15)}) async {
  final finder = find.byKey(ValueKey(key));
  final deadline = DateTime.now().add(timeout);
  while (!tester.any(finder)) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Timed out waiting for key "$key"');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Waits until a widget with [text] is visible.
Future<void> waitForText(WidgetTester tester, String text, {Duration timeout = const Duration(seconds: 15)}) async {
  final finder = find.text(text);
  final deadline = DateTime.now().add(timeout);
  while (!tester.any(finder)) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Timed out waiting for text "$text"');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Waits until a widget with [text] anywhere in subtree.
Future<void> waitForTextContaining(WidgetTester tester, String text, {Duration timeout = const Duration(seconds: 15)}) async {
  final finder = find.textContaining(text);
  final deadline = DateTime.now().add(timeout);
  while (!tester.any(finder)) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Timed out waiting for text containing "$text"');
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Pumps until no more animations are running (max [seconds]).
Future<void> settle(WidgetTester tester, {int seconds = 10}) async {
  await tester.pumpAndSettle(Duration(seconds: seconds));
}

// ── Auth helpers ──────────────────────────────────────────────────────────────

/// Signs in the test user. Assumes the app is already showing the login screen
/// or navigates there if the guest option routes to /login.
Future<void> loginAs(WidgetTester tester, {String? email, String? password}) async {
  final targetEmail = email ?? testEmail;
  final targetPass  = password ?? testPassword;

  await waitForKey(tester, TestKeys.emailField);

  final emailField = find.byKey(const ValueKey(TestKeys.emailField));
  final passField  = find.byKey(const ValueKey(TestKeys.passwordField));
  final signInBtn  = find.byKey(const ValueKey(TestKeys.signInButton));

  await tester.enterText(emailField, targetEmail);
  await tester.pump();
  await tester.enterText(passField, targetPass);
  await tester.pump();
  await tester.tap(signInBtn);
  await tester.pump();

  // Wait for home screen to load
  await waitForText(tester, 'Forest Shoes', timeout: const Duration(seconds: 20));
}

/// Taps "Browse as Guest" on the login screen.
Future<void> continueAsGuest(WidgetTester tester) async {
  await waitForKey(tester, TestKeys.guestButton);
  await tester.tap(find.byKey(const ValueKey(TestKeys.guestButton)));
  await settle(tester);
}

// ── Navigation helpers ────────────────────────────────────────────────────────

Future<void> goToShop(WidgetTester tester) async {
  await waitForKey(tester, TestKeys.navShop);
  await tester.tap(find.byKey(const ValueKey(TestKeys.navShop)));
  await settle(tester);
}

Future<void> goToCart(WidgetTester tester) async {
  await waitForKey(tester, TestKeys.navCart);
  await tester.tap(find.byKey(const ValueKey(TestKeys.navCart)));
  await settle(tester);
}

Future<void> goToProfile(WidgetTester tester) async {
  await waitForKey(tester, TestKeys.navProfile);
  await tester.tap(find.byKey(const ValueKey(TestKeys.navProfile)));
  await settle(tester);
}

// ── Pump helpers ──────────────────────────────────────────────────────────────

/// Pump for a fixed duration without settling (useful for animations).
Future<void> pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
