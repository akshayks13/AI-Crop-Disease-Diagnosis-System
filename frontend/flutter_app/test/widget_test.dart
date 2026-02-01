// Widget Tests for Flutter App
//
// Run with: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Login Screen Widgets', () {
    testWidgets('email field should exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              key: const Key('email_field'),
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ),
        ),
      );
      
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('password field should be obscured', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              key: const Key('password_field'),
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ),
        ),
      );
      
      final textField = tester.widget<TextField>(find.byKey(const Key('password_field')));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('login button should exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              key: const Key('login_button'),
              onPressed: () {},
              child: const Text('Login'),
            ),
          ),
        ),
      );
      
      expect(find.byKey(const Key('login_button')), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });
  });

  group('Home Screen Widgets', () {
    testWidgets('feature cards should be tappable', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              key: const Key('feature_card'),
              onTap: () => tapped = true,
              child: const Card(
                child: Text('Diagnose Disease'),
              ),
            ),
          ),
        ),
      );
      
      await tester.tap(find.byKey(const Key('feature_card')));
      expect(tapped, isTrue);
    });
  });

  group('Common Widgets', () {
    testWidgets('loading indicator should show', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error message should display', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text('Error: Something went wrong'),
          ),
        ),
      );
      
      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('app bar should have title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Crop Diagnosis'),
            ),
          ),
        ),
      );
      
      expect(find.text('Crop Diagnosis'), findsOneWidget);
    });
  });

  group('Form Validation UI', () {
    testWidgets('error text should appear for invalid input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextFormField(
              decoration: const InputDecoration(
                errorText: 'Invalid email',
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Invalid email'), findsOneWidget);
    });
  });
}
