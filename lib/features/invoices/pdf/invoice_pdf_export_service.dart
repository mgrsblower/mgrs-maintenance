import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../schedule/order_model.dart';
import '../invoice_model.dart';
import 'invoice_pdf_download.dart';

const String defaultInvoiceExportUrl = String.fromEnvironment(
  'INVOICE_EXPORT_URL',
  defaultValue: 'https://www.mgrs.biz.id/api/invoice/export',
);

class InvoicePdfPayload {
  const InvoicePdfPayload({
    required this.reference,
    required this.date,
    required this.dueDate,
    required this.customerName,
    required this.customerPhone,
    required this.description,
    required this.quantity,
    required this.rentalDays,
    required this.unitPrice,
    required this.tableAmount,
    required this.adjustments,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.bankNote,
    required this.noteDate,
    required this.shouldShowRentalDays,
  });

  factory InvoicePdfPayload.fromInvoiceRecord(
    InvoiceRecord invoice, {
    SaveInvoiceInput? currentInput,
    OrderanSewa? order,
    DateTime? exportedAt,
  }) {
    final reference =
        currentInput?.invoiceReference ?? invoice.invoiceReference;
    final invoiceDate = currentInput?.invoiceDate ?? invoice.invoiceDate;
    final dueDate = currentInput?.dueDate ?? invoice.dueDate;
    final description = currentInput?.productName ?? invoice.productName;
    final quantity = currentInput?.quantity ?? invoice.quantity;
    final rentalDays = currentInput?.rentalDays ?? invoice.rentalDays;
    final unitPrice = currentInput?.unitPrice ?? invoice.unitPrice;
    final totalAmount = currentInput?.totalAmount ?? invoice.totalAmount;
    final paidAmount = currentInput?.paidAmount ?? invoice.paidAmount;
    final adjustments = currentInput?.adjustments ?? invoice.adjustments;
    final customerName = currentInput?.customerName.trim().isNotEmpty == true
        ? currentInput!.customerName.trim()
        : invoice.customerName.trim().isNotEmpty
            ? invoice.customerName.trim()
            : _customerName(order);
    final customerPhone = currentInput?.customerPhone.trim().isNotEmpty == true
        ? currentInput!.customerPhone.trim()
        : invoice.customerPhone.trim().isNotEmpty
            ? invoice.customerPhone.trim()
            : order?.nomorWhatsapp?.trim() ?? '';
    final shouldShowRentalDays = rentalDays > 1;
    final tableAmount =
        quantity * unitPrice * (shouldShowRentalDays ? rentalDays : 1);
    final remainingAmount = totalAmount - paidAmount;

    return InvoicePdfPayload(
      reference: reference,
      date: _formatSlashDate(invoiceDate),
      dueDate: _formatSlashDate(dueDate),
      customerName: customerName,
      customerPhone: customerPhone,
      description: description,
      quantity: quantity,
      rentalDays: rentalDays,
      unitPrice: unitPrice,
      tableAmount: tableAmount,
      adjustments: adjustments
          .where(
            (adjustment) =>
                adjustment.description.trim().isNotEmpty &&
                adjustment.amount != 0,
          )
          .map(
            (adjustment) => <String, Object?>{
              'label': adjustment.description.trim(),
              'amount': adjustment.amount,
            },
          )
          .toList(growable: false),
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount > 0 ? remainingAmount : 0,
      bankNote: '2302619141 A/N MADNUR',
      noteDate: _formatLongIndonesianDate(exportedAt ?? DateTime.now()),
      shouldShowRentalDays: shouldShowRentalDays,
    );
  }

  final String reference;
  final String date;
  final String dueDate;
  final String customerName;
  final String customerPhone;
  final String description;
  final num quantity;
  final num rentalDays;
  final num unitPrice;
  final num tableAmount;
  final List<Map<String, Object?>> adjustments;
  final num totalAmount;
  final num paidAmount;
  final num remainingAmount;
  final String bankNote;
  final String noteDate;
  final bool shouldShowRentalDays;

  Map<String, Object?> toJson() => <String, Object?>{
        'reference': reference,
        'date': date,
        'dueDate': dueDate,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'description': description,
        'quantity': quantity,
        'rentalDays': rentalDays,
        'unitPrice': unitPrice,
        'tableAmount': tableAmount,
        'adjustments': adjustments,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'remainingAmount': remainingAmount,
        'bankNote': bankNote,
        'noteDate': noteDate,
        'shouldShowRentalDays': shouldShowRentalDays,
      };
}

String _customerName(OrderanSewa? order) {
  final clientName = order?.namaClient?.trim() ?? '';
  if (clientName.isNotEmpty) return clientName;
  return order?.namaEvent.trim() ?? '';
}

String _formatSlashDate(String value) {
  final trimmed = value.trim();
  if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(trimmed)) return trimmed;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(trimmed);
  if (match == null) return trimmed;
  return '${match.group(3)}/${match.group(2)}/${match.group(1)}';
}

String _formatLongIndonesianDate(DateTime date) {
  const weekdays = <String>[
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '${weekdays[date.weekday - 1]}, $day ${months[date.month - 1]} ${date.year}';
}

class InvoicePdfExportResult {
  const InvoicePdfExportResult({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

class InvoicePdfExportException implements Exception {
  const InvoicePdfExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvoicePdfExportService {
  InvoicePdfExportService({
    http.Client? client,
    Uri? exportUrl,
    this.timeout = const Duration(seconds: 30),
  })  : _client = client ?? http.Client(),
        exportUrl = exportUrl ?? Uri.parse(defaultInvoiceExportUrl);

  final http.Client _client;
  final Uri exportUrl;
  final Duration timeout;

  Future<InvoicePdfExportResult> export({
    required InvoicePdfPayload payload,
    required String fileName,
  }) async {
    final cleanBaseName = stripPdfExtension(fileName);
    try {
      final response = await _client
          .post(
            exportUrl,
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, Object?>{
              'fileName': cleanBaseName.isEmpty ? 'invoice' : cleanBaseName,
              'invoice': payload.toJson(),
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw InvoicePdfExportException(
          'Server gagal merespons (HTTP ${response.statusCode}): ${response.body.isNotEmpty ? response.body : 'Respon kosong'}',
        );
      }
      final contentType = response.headers['content-type']
          ?.split(';')
          .first
          .trim()
          .toLowerCase();
      if (contentType != 'application/pdf') {
        throw InvoicePdfExportException(
          'Ekspor gagal: Server tidak mengembalikan file PDF (Content-Type: ${contentType ?? 'unknown'}).',
        );
      }
      if (response.bodyBytes.isEmpty) {
        throw const InvoicePdfExportException(
          'Ekspor PDF gagal karena file yang dihasilkan kosong.',
        );
      }

      return InvoicePdfExportResult(
        bytes: Uint8List.fromList(response.bodyBytes),
        fileName: sanitizeInvoicePdfFileName(
          _fileNameFromContentDisposition(
                response.headers['content-disposition'],
              ) ??
              fileName,
        ),
      );
    } on InvoicePdfExportException {
      rethrow;
    } on TimeoutException {
      throw const InvoicePdfExportException(
        'Ekspor PDF melebihi batas waktu (timeout). Silakan coba lagi.',
      );
    } on Object catch (e) {
      throw InvoicePdfExportException(
        'Ekspor PDF gagal: $e',
      );
    }
  }

  /// Helper untuk mengunduh dan membuka file PDF invoice secara langsung
  Future<String?> exportAndDownload({
    required InvoiceRecord invoice,
    SaveInvoiceInput? currentInput,
    OrderanSewa? order,
  }) async {
    final payload = InvoicePdfPayload.fromInvoiceRecord(
      invoice,
      currentInput: currentInput,
      order: order,
    );
    final fileName = sanitizeInvoicePdfFileName(
      invoice.invoiceReference.replaceAll('/', '-'),
    );
    final result = await export(payload: payload, fileName: fileName);
    try {
      final location = await downloadInvoicePdf(result.bytes, result.fileName);
      return location;
    } catch (e) {
      throw InvoicePdfExportException('Gagal menyimpan file PDF: $e');
    }
  }
}

String? _fileNameFromContentDisposition(String? value) {
  if (value == null) return null;

  final encodedMatch = RegExp(
    r"filename\*=UTF-8''([^;]+)",
    caseSensitive: false,
  ).firstMatch(value);
  if (encodedMatch != null) {
    try {
      return Uri.decodeComponent(encodedMatch.group(1)!);
    } on ArgumentError {
      return null;
    }
  }

  final match = RegExp(
    r'filename\s*=\s*(?:"([^"]+)"|([^;\s]+))',
    caseSensitive: false,
  ).firstMatch(value);
  return match?.group(1) ?? match?.group(2);
}
