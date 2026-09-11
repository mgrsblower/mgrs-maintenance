import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/services/native_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativePdfService', () {
    const channel = MethodChannel('mgrs/native_pdf');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'previewPdf') {
          final path = methodCall.arguments['path'] as String?;
          if (path == 'not_found.pdf') {
            throw PlatformException(code: 'FILE_NOT_FOUND', message: 'File not found');
          }
          if (path == 'no_app.pdf') {
            throw PlatformException(code: 'NO_PDF_APP', message: 'No app found');
          }
          return null;
        }
        if (methodCall.method == 'sharePdf') {
          return null;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('throws EMPTY_PATH when path is empty or whitespace', () async {
      final service = NativePdfService(channel: channel, isNativePlatform: true);
      expect(
        () => service.previewPdf('   '),
        throwsA(isA<NativePdfException>().having((e) => e.code, 'code', 'EMPTY_PATH')),
      );
      expect(
        () => service.sharePdf(''),
        throwsA(isA<NativePdfException>().having((e) => e.code, 'code', 'EMPTY_PATH')),
      );
      expect(log, isEmpty);
    });

    test('previewPdf invokes channel with path', () async {
      final service = NativePdfService(channel: channel, isNativePlatform: true);
      await service.previewPdf('/data/user/0/app/test.pdf');

      expect(log, hasLength(1));
      expect(log.first.method, 'previewPdf');
      expect(log.first.arguments, {'path': '/data/user/0/app/test.pdf'});
    });

    test('sharePdf invokes channel with path and title', () async {
      final service = NativePdfService(channel: channel, isNativePlatform: true);
      await service.sharePdf('/data/user/0/app/test.pdf', title: 'INV/2026/09/001');

      expect(log, hasLength(1));
      expect(log.first.method, 'sharePdf');
      expect(log.first.arguments, {
        'path': '/data/user/0/app/test.pdf',
        'title': 'INV/2026/09/001',
      });
    });

    test('maps PlatformException FILE_NOT_FOUND to friendly error', () async {
      final service = NativePdfService(channel: channel, isNativePlatform: true);
      expect(
        () => service.previewPdf('not_found.pdf'),
        throwsA(isA<NativePdfException>().having((e) => e.code, 'code', 'FILE_NOT_FOUND')),
      );
    });

    test('maps PlatformException NO_PDF_APP to friendly error', () async {
      final service = NativePdfService(channel: channel, isNativePlatform: true);
      expect(
        () => service.previewPdf('no_app.pdf'),
        throwsA(isA<NativePdfException>().having((e) => e.code, 'code', 'NO_PDF_APP')),
      );
    });

    test('debounces rapid duplicate calls', () async {
      final service = NativePdfService(channel: channel, isNativePlatform: true);
      // Fire 3 calls without waiting
      final future1 = service.previewPdf('/data/user/0/app/test.pdf');
      final future2 = service.previewPdf('/data/user/0/app/test.pdf');
      final future3 = service.previewPdf('/data/user/0/app/test.pdf');

      await Future.wait([future1, future2, future3]);

      // Only the first one should have been invoked because of debounce lock
      expect(log, hasLength(1));
    });
  });
}
