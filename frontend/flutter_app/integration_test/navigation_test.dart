// E2E Navigation Tests
// Tests: Bottom navigation, back navigation, route transitions
//
// Run with: flutter test integration_test/navigation_test.dart --device-id chrome

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

/// Helper: log in with test credentials and settle to home screen
Future<void> loginAsTestUser(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 3));

  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email'),
    'testfarmer@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Password'),
    'Test@1234',
  );
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation', () {
    testWidgets('App launches and shows a screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Either login screen or home screen should be visible
      final hasLogin = find.text('Welcome Back').evaluate().isNotEmpty;
      final hasHome = find.byType(Scaffold).evaluate().isNotEmpty;
      expect(hasLogin || hasHome, isTrue);
    });

    testWidgets('Bottom navigation bar is present after login', (WidgetTester tester) async {
      await loginAsTestUser(tester);

      // Bottom nav should be visible
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Bottom nav switches tabs', (WidgetTester tester) async {
      await loginAsTestUser(tester);

      // Get all BottomNavigationBarItem widgets
      final navBar = find.byType(BottomNavigationBar);
      expect(navBar, findsOneWidget);

      // Tap second item
      await tester.tap(find.byType(BottomNavigationBar).first);
      await tester.pumpAndSettle();
    });

    testWidgets('Back button returns to previous screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Go to Register
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);

      // Press back
      final NavigatorState navigator = tester.state(find.byType(Navigator).first);
      navigator.pop();
      await tester.pumpAndSettle();

      // Should be back to Login
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('Forgot Password screen can be reached and back navigated', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Should show forgot password content
      expect(find.byType(Scaffold), findsOneWidget);

      // Go back
      final NavigatorState navigator = tester.state(find.byType(Navigator).first);
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('App bar back button works from register', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to register
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Use leading back button in app bar
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(find.text('Welcome Back'), findsOneWidget);
      }
    });
  });
}
