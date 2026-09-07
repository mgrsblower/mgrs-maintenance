import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  await integrationDriver(
    driver: driver,
    writeResponseOnFailure: true,
    onScreenshot: (name, bytes, [arguments]) async {
      final directory = Directory('docs/evidence/screenshots');
      await directory.create(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(bytes, flush: true);
      return true;
    },
  );
}
