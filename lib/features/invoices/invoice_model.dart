import 'package:flutter/foundation.dart';

enum InvoicePaymentStatus {
  unpaid,
  partial,
  paid;

  String toJson() => switch (this) {
        InvoicePaymentStatus.unpaid => 'unpaid',
        InvoicePaymentStatus.partial => 'partial',
        InvoicePaymentStatus.paid => 'paid',
      };

  static InvoicePaymentStatus fromJson(Object? value) {
    if (value is InvoicePaymentStatus) return value;
    final str = value?.toString().toLowerCase().trim();
    return switch (str) {
      'paid' || 'lunas' => InvoicePaymentStatus.paid,
      'partial' || 'dp' || 'sebagian' => InvoicePaymentStatus.partial,
      _ => InvoicePaymentStatus.unpaid,
    };
  }

  String get label => switch (this) {
        InvoicePaymentStatus.unpaid => 'Belum Bayar',
        InvoicePaymentStatus.partial => 'Sebagian',
        InvoicePaymentStatus.paid => 'Lunas',
      };
}

@immutable
class InvoiceAdjustment {
  const InvoiceAdjustment({required this.description, required this.amount});

  final String description;
  final num amount;

  factory InvoiceAdjustment.fromJson(Map<String, Object?> json) =>
      InvoiceAdjustment(
        description: (json['description'] ?? '').toString(),
        amount: json['amount'] is num
            ? (json['amount'] as num)
            : num.tryParse((json['amount'] ?? 0).toString()) ?? 0,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'description': description,
        'amount': amount,
      };
}

class InvoiceCalculation {
  const InvoiceCalculation({
    required this.subtotal,
    required this.adjustmentTotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
  });

  final num subtotal;
  final num adjustmentTotal;
  final num totalAmount;
  final num paidAmount;
  final num remainingAmount;
}

abstract final class InvoiceCalculator {
  static InvoiceCalculation calculate({
    required num quantity,
    required num rentalDays,
    required num unitPrice,
    required InvoicePaymentStatus paymentStatus,
    Iterable<InvoiceAdjustment> adjustments = const <InvoiceAdjustment>[],
    num paidAmount = 0,
  }) {
    final subtotal =
        _nonNegative(quantity) * _nonNegative(rentalDays) * _nonNegative(unitPrice);
    final adjustmentTotal = adjustments.fold<num>(
      0,
      (total, adjustment) => total + adjustment.amount,
    );
    final totalAmount = _nonNegative(subtotal + adjustmentTotal);
    final resolvedPaidAmount = switch (paymentStatus) {
      InvoicePaymentStatus.unpaid => 0,
      InvoicePaymentStatus.partial => paidAmount.clamp(0, totalAmount),
      InvoicePaymentStatus.paid => totalAmount,
    };

    return InvoiceCalculation(
      subtotal: subtotal,
      adjustmentTotal: adjustmentTotal,
      totalAmount: totalAmount,
      paidAmount: resolvedPaidAmount,
      remainingAmount: totalAmount - resolvedPaidAmount,
    );
  }

  static num _nonNegative(num amount) => amount < 0 ? 0 : amount;
}

class SaveInvoiceInput {
  const SaveInvoiceInput({
    required this.invoiceId,
    this.orderanId,
    required this.invoiceReference,
    required this.invoiceDate,
    required this.dueDate,
    required this.productName,
    required this.quantity,
    required this.rentalDays,
    required this.unitPrice,
    required this.subtotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentStatus,
    this.invoiceSource = 'order',
    this.customerName = '',
    this.customerPhone = '',
    this.adjustments = const <InvoiceAdjustment>[],
    this.printedAt,
  });

  final String invoiceId;
  final String? orderanId;
  final String invoiceReference;
  final String invoiceDate;
  final String dueDate;
  final String productName;
  final num quantity;
  final num rentalDays;
  final num unitPrice;
  final num subtotal;
  final num totalAmount;
  final num paidAmount;
  final InvoicePaymentStatus paymentStatus;
  final String invoiceSource;
  final String customerName;
  final String customerPhone;
  final List<InvoiceAdjustment> adjustments;
  final String? printedAt;

  Map<String, Object?> toPayload() => <String, Object?>{
        'orderan_id': orderanId,
        'invoice_reference': invoiceReference,
        'invoice_date': invoiceDate,
        'due_date': dueDate,
        'product_name': productName,
        'quantity': quantity,
        'rental_days': rentalDays,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'payment_status': paymentStatus.toJson(),
        'invoice_source': invoiceSource,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'adjustments':
            adjustments.map((adjustment) => adjustment.toJson()).toList(),
        if (printedAt != null) 'printed_at': printedAt,
      };
}

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    this.orderanId,
    required this.invoiceReference,
    required this.invoiceDate,
    required this.dueDate,
    required this.productName,
    required this.quantity,
    required this.rentalDays,
    required this.unitPrice,
    required this.subtotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentStatus,
    this.invoiceSource = 'order',
    this.customerName = '',
    this.customerPhone = '',
    this.adjustments = const <InvoiceAdjustment>[],
    this.printedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? orderanId;
  final String invoiceReference;
  final String invoiceDate;
  final String dueDate;
  final String productName;
  final num quantity;
  final num rentalDays;
  final num unitPrice;
  final num subtotal;
  final num totalAmount;
  final num paidAmount;
  final InvoicePaymentStatus paymentStatus;
  final String invoiceSource;
  final String customerName;
  final String customerPhone;
  final List<InvoiceAdjustment> adjustments;
  final String? printedAt;
  final String? createdAt;
  final String? updatedAt;

  num get remainingAmount =>
      (totalAmount - paidAmount) > 0 ? (totalAmount - paidAmount) : 0;

  bool get isPaid =>
      paymentStatus == InvoicePaymentStatus.paid ||
      (totalAmount > 0 && paidAmount >= totalAmount);

  bool get isDp =>
      paymentStatus == InvoicePaymentStatus.partial ||
      (paidAmount > 0 && paidAmount < totalAmount);

  bool get isUnpaid => !isPaid && !isDp;

  String get paymentStatusDisplay => paymentStatus.label;

  static String formatRupiah(num value) {
    final str = value.toInt().toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  static String formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String get totalAmountFormatted => formatRupiah(totalAmount);
  String get paidAmountFormatted => formatRupiah(paidAmount);
  String get remainingAmountFormatted => formatRupiah(remainingAmount);

  String get formattedInvoiceDate {
    try {
      final dt = DateTime.parse(invoiceDate);
      return formatDate(dt);
    } catch (_) {
      return invoiceDate;
    }
  }

  String get formattedDueDate {
    try {
      final dt = DateTime.parse(dueDate);
      return formatDate(dt);
    } catch (_) {
      return dueDate;
    }
  }

  factory InvoiceRecord.fromJson(Map<String, Object?> json) {
    num parseNum(Object? val) {
      if (val is num) return val;
      if (val is String) return num.tryParse(val) ?? 0;
      return 0;
    }

    final adjustmentsRaw = json['adjustments'];
    final adjustments = <InvoiceAdjustment>[];
    if (adjustmentsRaw is List) {
      for (final item in adjustmentsRaw) {
        if (item is Map<String, Object?>) {
          adjustments.add(InvoiceAdjustment.fromJson(item));
        } else if (item is Map) {
          adjustments.add(InvoiceAdjustment.fromJson(Map<String, Object?>.from(item)));
        }
      }
    }

    return InvoiceRecord(
      id: (json['id'] ?? '').toString(),
      orderanId: json['orderan_id']?.toString(),
      invoiceReference:
          (json['invoice_reference'] ?? json['nomor_invoice'] ?? '-').toString(),
      invoiceDate: (json['invoice_date'] ?? '').toString(),
      dueDate: (json['due_date'] ?? '').toString(),
      productName: (json['product_name'] ?? 'Sewa Mistyfan').toString(),
      quantity: parseNum(json['quantity']),
      rentalDays: parseNum(json['rental_days']),
      unitPrice: parseNum(json['unit_price']),
      subtotal: parseNum(json['subtotal']),
      totalAmount: parseNum(json['total_amount']),
      paidAmount: parseNum(json['paid_amount']),
      paymentStatus: InvoicePaymentStatus.fromJson(json['payment_status']),
      customerName:
          (json['customer_name'] ?? json['nama_client'] ?? '').toString(),
      customerPhone:
          (json['customer_phone'] ?? json['nomor_whatsapp'] ?? '').toString(),
      invoiceSource: (json['invoice_source'] ?? 'order').toString(),
      adjustments: adjustments,
      printedAt: json['printed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'orderan_id': orderanId,
        'invoice_reference': invoiceReference,
        'invoice_date': invoiceDate,
        'due_date': dueDate,
        'product_name': productName,
        'quantity': quantity,
        'rental_days': rentalDays,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'payment_status': paymentStatus.toJson(),
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'invoice_source': invoiceSource,
        'adjustments': adjustments.map((a) => a.toJson()).toList(),
        'printed_at': printedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
