import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
import 'package:mgrs_maintenance/features/invoices/pdf/invoice_pdf_download.dart';
import 'package:mgrs_maintenance/features/invoices/pdf/invoice_pdf_export_service.dart';
import 'package:mgrs_maintenance/features/schedule/order_model.dart';

void main() {
  group('InvoicePdfPayload & Service', () {
    test('builds payload correctly from InvoiceRecord and OrderanSewa', () {
      final invoice = InvoiceRecord(
        id: 'inv-1',
        orderanId: 'ord-100',
        invoiceReference: 'INV/2026/09/001',
        productName: 'Sewa Misty Fan',
        quantity: 4,
        rentalDays: 2,
        unitPrice: 250000,
        subtotal: 2000000,
        totalAmount: 1900000,
        paidAmount: 500000,
        paymentStatus: InvoicePaymentStatus.partial,
        invoiceDate: '2026-09-11',
        dueDate: '2026-09-12',
        customerName: 'CV Berkah Sentosa',
        customerPhone: '081234567890',
        adjustments: const [
          InvoiceAdjustment(description: 'Diskon Kemitraan', amount: -100000),
        ],
      );

      final payload = InvoicePdfPayload.fromInvoiceRecord(invoice);

      expect(payload.reference, 'INV/2026/09/001');
      expect(payload.date, '11/09/2026');
      expect(payload.dueDate, '12/09/2026');
      expect(payload.customerName, 'CV Berkah Sentosa');
      expect(payload.customerPhone, '081234567890');
      expect(payload.quantity, 4);
      expect(payload.rentalDays, 2);
      expect(payload.shouldShowRentalDays, true);
      expect(payload.tableAmount, 2000000);
      expect(payload.adjustments.length, 1);
      expect(payload.adjustments.first['label'], 'Diskon Kemitraan');
      expect(payload.adjustments.first['amount'], -100000);
      expect(payload.totalAmount, 1900000);
      expect(payload.paidAmount, 500000);
      expect(payload.remainingAmount, 1400000);

      final json = payload.toJson();
      expect(json['reference'], 'INV/2026/09/001');
      expect(json['totalAmount'], 1900000);
    });

    test('fallbacks to OrderanSewa when customer name/phone are empty', () {
      final invoice = const InvoiceRecord(
        id: 'inv-2',
        orderanId: 'ord-101',
        invoiceReference: 'INV/2026/09/002',
        productName: 'Sewa AC Portable',
        quantity: 1,
        rentalDays: 1,
        unitPrice: 500000,
        subtotal: 500000,
        totalAmount: 500000,
        paidAmount: 500000,
        paymentStatus: InvoicePaymentStatus.paid,
        invoiceDate: '11/09/2026',
        dueDate: '11/09/2026',
        customerName: '',
        customerPhone: '',
      );

      final order = OrderanSewa(
        id: 'ord-101',
        namaEvent: 'Konser Musik Solo',
        namaClient: 'Ibu Ratna',
        nomorWhatsapp: '08987654321',
        tanggalPemasangan: DateTime(2026, 9, 11),
        alamat: 'Stadion Manahan',
      );

      final payload = InvoicePdfPayload.fromInvoiceRecord(invoice, order: order);
      expect(payload.customerName, 'Ibu Ratna');
      expect(payload.customerPhone, '08987654321');
      expect(payload.shouldShowRentalDays, false);
      expect(payload.remainingAmount, 0);
    });

    test('sanitizes PDF file name', () {
      expect(sanitizeInvoicePdfFileName('INV/2026/09/001.pdf'), 'INV-2026-09-001.pdf');
      expect(sanitizeInvoicePdfFileName('Invoice Test #123!'), 'Invoice-Test-123.pdf');
      expect(sanitizeInvoicePdfFileName(''), 'invoice.pdf');
    });
  });
}
