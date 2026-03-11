// E2E App Test — CI Entry Point
// Runs all integration test groups together for CI/CD pipeline.
//
// Run with: flutter test integration_test/app_test.dart --device-id chrome

import 'package:integration_test/integration_test.dart';

// Import all individual test files
import 'auth_flow_test.dart' as auth;
import 'navigation_test.dart' as navigation;
import 'diagnosis_flow_test.dart' as diagnosis;
import 'farm_flow_test.dart' as farm;
import 'profile_flow_test.dart' as profile;
import 'history_flow_test.dart' as history;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Run all test suites
  auth.main();
  navigation.main();
  diagnosis.main();
  farm.main();
  profile.main();
  history.main();
}
