import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Host side of integration_test/screenshots_test.dart: saves every
/// screenshot the test takes as `$SHOT_DIR/<name>.png`.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final dir = Platform.environment['SHOT_DIR'] ?? 'build/screenshots';
    File('$dir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return true;
  },
);
