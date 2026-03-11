// E2E Auth Flow Tests
// Tests: Splash → Login, Login (valid/invalid), Navigate to Register, Form Validation
//
// Run with: flutter test integration_test/auth_flow_test.dart --device-id chrome

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow', () {
    testWidgets('Login screen renders correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show login screen (after splash)
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Login form validation - empty fields', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap Sign In without filling anything
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Login form validation - invalid email', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'notanemail',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Navigate to Register screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap Sign Up link
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should now be on Register screen
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('I am a...'), findsOneWidget);
      expect(find.text('Farmer'), findsOneWidget);
      expect(find.text('Expert'), findsOneWidget);
    });

    testWidgets('Register form validation - empty fields', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to register
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Tap Create Account without filling anything
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('Navigate back from Register to Login', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Go to Register
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Tap Sign In link at the bottom
      await tester.tap(find.text('Sign In').last);
      await tester.pumpAndSettle();

      // Should be back on Login screen
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('Navigate to Forgot Password screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap Forgot Password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Should be on Forgot Password screen
      expect(find.text('Forgot Password?'), findsWidgets);
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find the password field and enter text
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'mypassword',
      );
      await tester.pumpAndSettle();

      // Tap visibility icon to reveal password
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();
    });

    testWidgets('Expert role selection on Register screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to register
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Select Expert role
      await tester.tap(find.text('Expert'));
      await tester.pumpAndSettle();

      // Expert-specific fields should appear
      expect(find.text('Area of Expertise'), findsOneWidget);
      expect(find.text('Qualifications'), findsOneWidget);
      expect(find.text('Years of Experience'), findsOneWidget);
      expect(find.text('Submit Application'), findsOneWidget);
    });
  });
}
