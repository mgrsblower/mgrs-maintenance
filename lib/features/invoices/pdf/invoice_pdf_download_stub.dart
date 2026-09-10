import 'dart:io';
import 'package:flutter/services.dart';

const _invoicePdfChannel = MethodChannel(
  'com.mgrs.mgrs_maintenance/invoice_pdf',
);

Future<String?> downloadInvoicePdf(Uint8List bytes, String fileName) async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final location = await _invoicePdfChannel.invokeMethod<String>('saveInvoicePdf', {
        'bytes': bytes,
        'fileName': fileName,
      });
      if (location != null && location.isNotEmpty) return location;
    } catch (_) {
      // Fall back to direct file write if native channel is not registered
    }
  }

  return _saveDirectToFile(bytes, fileName);
}

Future<String> _saveDirectToFile(Uint8List bytes, String fileName) async {
  Directory? targetDir;
  if (Platform.isIOS) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      targetDir = Directory('$home/Documents/MGRS');
    }
  } else if (Platform.isWindows) {
    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      targetDir = Directory('$userProfile\\Downloads\\MGRS');
    }
  } else if (Platform.isMacOS || Platform.isLinux) {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      targetDir = Directory('$home/Downloads/MGRS');
    }
  }

  targetDir ??= Directory.systemTemp.createTempSync('mgrs_invoice_');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }
  final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<void> openInvoicePdf(String? location) async {
  if (location == null || location.isEmpty) return;

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await _invoicePdfChannel.invokeMethod<void>('openInvoicePdf', {
        'location': location,
      });
      return;
    } catch (_) {}
  }

  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', location], runInShell: true);
    return;
  }
  if (Platform.isMacOS) {
    await Process.run('open', [location]);
    return;
  }
  if (Platform.isLinux) {
    await Process.run('xdg-open', [location]);
    return;
  }
}

Future<void> shareInvoicePdf(String? location, String fileName) async {
  if (location == null || location.isEmpty) return;

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await _invoicePdfChannel.invokeMethod<void>('shareInvoicePdf', {
        'location': location,
        'fileName': fileName,
      });
      return;
    } catch (_) {}
  }

  await openInvoicePdf(location);
}

