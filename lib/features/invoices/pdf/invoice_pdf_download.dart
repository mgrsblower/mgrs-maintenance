import 'dart:typed_data';

import 'invoice_pdf_download_stub.dart'
    if (dart.library.js_interop) 'invoice_pdf_download_web.dart'
    as platform;

typedef InvoicePdfDownload =
    Future<String?> Function(Uint8List bytes, String fileName);

Future<String?> downloadInvoicePdf(Uint8List bytes, String fileName) =>
    platform.downloadInvoicePdf(bytes, sanitizeInvoicePdfFileName(fileName));

Future<void> openInvoicePdf(String? location) =>
    platform.openInvoicePdf(location);

Future<void> shareInvoicePdf(String? location, String fileName) =>
    platform.shareInvoicePdf(location, sanitizeInvoicePdfFileName(fileName));

String stripPdfExtension(String value) {
  var name = value.trim();
  while (name.toLowerCase().endsWith('.pdf')) {
    name = name.substring(0, name.length - 4).trim();
  }
  return name;
}

String sanitizeInvoicePdfFileName(String value) {
  var baseName = stripPdfExtension(value)
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  baseName = stripPdfExtension(baseName);
  return '${baseName.isEmpty ? 'invoice' : baseName}.pdf';
}
