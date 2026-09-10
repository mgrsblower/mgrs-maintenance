import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<String?> downloadInvoicePdf(Uint8List bytes, String fileName) async {
  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = fileName
    ..style.display = 'none';

  web.document.body?.append(anchor);
  try {
    anchor.click();
  } finally {
    anchor.remove();
  }
  return objectUrl;
}

Future<void> openInvoicePdf(String? location) async {
  if (location == null || location.isEmpty) return;
  web.window.open(location, '_blank');
}

Future<void> shareInvoicePdf(String? location, String fileName) async {
  if (location == null || location.isEmpty) return;
  web.window.open(location, '_blank');
}
