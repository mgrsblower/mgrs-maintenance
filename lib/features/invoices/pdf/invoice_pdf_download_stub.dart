import 'package:flutter/services.dart';

const _invoicePdfChannel = MethodChannel(
  'com.mgrs.mgrs_maintenance/invoice_pdf',
);

Future<String?> downloadInvoicePdf(Uint8List bytes, String fileName) async {
  return _invoicePdfChannel.invokeMethod<String>('saveInvoicePdf', {
    'bytes': bytes,
    'fileName': fileName,
  });
}

Future<void> openInvoicePdf(String? location) async {
  if (location == null || location.isEmpty) return;
  await _invoicePdfChannel.invokeMethod<void>('openInvoicePdf', {
    'location': location,
  });
}

Future<void> shareInvoicePdf(String? location, String fileName) async {
  if (location == null || location.isEmpty) return;
  await _invoicePdfChannel.invokeMethod<void>('shareInvoicePdf', {
    'location': location,
    'fileName': fileName,
  });
}
