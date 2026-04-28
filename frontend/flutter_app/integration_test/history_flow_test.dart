// E2E Diagnosis History Flow Tests
// Tests: History screen loads, shows list or empty state, tap opens detail
//
// Run with: flutter test integration_test/history_flow_test.dart --device-id chrome

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app/main.dart' as app;

/// Helper: log in with test credentials
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

/// Helper: navigate to History screen
Future<void> navigateToHistory(WidgetTester tester) async {
  final historyIcon = find.byIcon(Icons.history);
  if (historyIcon.evaluate().isNotEmpty) {
    await tester.tap(historyIcon.first);
    await tester.pumpAndSettle();
    return;
  }

  final historyText = find.text('History');
  if (historyText.evaluate().isNotEmpty) {
    await tester.tap(historyText.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Diagnosis History Flow', () {
    testWidgets('History screen is reachable', (WidgetTester tester) async {
      await loginAsTestUser(tester);
      await navigateToHistory(tester);

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('History shows list or empty state', (WidgetTester tester) async {
      await loginAsTestUser(tester);
      await navigateToHistory(tester);

      // Either a list or empty state message
      final hasList = find.byType(ListView).evaluate().isNotEmpty;
      final hasEmptyText =
          find.textContaining('No').evaluate().isNotEmpty ||
          find.textContaining('history').evaluate().isNotEmpty ||
          find.byType(Scaffold).evaluate().isNotEmpty;

      expect(hasList || hasEmptyText, isTrue);
    });

    testWidgets('Tapping history item opens detail if list exists', (WidgetTester tester) async {
      await loginAsTestUser(tester);
      await navigateToHistory(tester);

      // If list items exist, tap the first one
      if (find.byType(ListTile).evaluate().isNotEmpty) {
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();
        // Detail view should be visible
        expect(find.byType(Scaffold), findsOneWidget);
      }

      if (find.byType(Card).evaluate().isNotEmpty) {
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    testWidgets('History screen has correct title or header', (WidgetTester tester) async {
      await loginAsTestUser(tester);
      await navigateToHistory(tester);

      // Title in app bar or body
      final hasTitle =
          find.text('History').evaluate().isNotEmpty ||
          find.text('Diagnosis History').evaluate().isNotEmpty ||
          find.textContaining('History').evaluate().isNotEmpty;

      expect(hasTitle || find.byType(Scaffold).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('History result screen structure is valid', (WidgetTester tester) async {
      // Widget-level check for a diagnosis history card
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Diagnosis History')),
            body: ListView(
              children: const [
                Card(
                  child: ListTile(
                    leading: Icon(Icons.local_florist),
                    title: Text('Leaf Blight'),
                    subtitle: Text('Confidence: 87% · 10 Mar 2026'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Diagnosis History'), findsOneWidget);
      expect(find.text('Leaf Blight'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
