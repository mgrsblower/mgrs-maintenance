import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> withViewport(
  WidgetTester tester,
  Size size,
  Future<void> Function() body, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await body();
  final exception = tester.takeException();
  expect(exception, isNull);
}
