import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// Importing isar_flutter_libs ensures the native Isar libraries are bundled
// and available during Flutter test runs (host VM).
import 'package:isar_flutter_libs/isar_flutter_libs.dart';

// Ensure this runs before any tests. It initializes Flutter bindings and
// makes the Isar FFI library available in the test environment.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The imported isar_flutter_libs above is intentionally unused in code;
  // its presence ensures native dynamic libraries are available.
  await testMain();
}

