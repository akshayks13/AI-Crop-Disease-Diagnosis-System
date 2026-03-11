// Test driver for running integration tests on Web (Chrome)
// This file is required for `flutter drive` to work with integration_test on web.
//
// Run with:
// flutter drive \
//   --driver=test_driver/integration_test.dart \
//   --target=integration_test/app_test.dart \
//   -d chrome

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
