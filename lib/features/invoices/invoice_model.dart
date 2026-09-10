class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.orderanId,
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
    this.customerName = '',
    this.customerPhone = '',
    this.invoiceSource = 'order',
  });

  final String id;
  final String orderanId;
  final String invoiceReference;
  final String invoiceDate;
  final String dueDate;
  final String productName;
  final int quantity;
  final int rentalDays;
  final num unitPrice;
  final num subtotal;
  final num totalAmount;
  final num paidAmount;
  final String paymentStatus;
  final String customerName;
  final String customerPhone;
  final String invoiceSource;

  num get remainingAmount =>
      (totalAmount - paidAmount) > 0 ? (totalAmount - paidAmount) : 0;

  bool get isPaid =>
      paymentStatus.toLowerCase() == 'lunas' ||
      paymentStatus.toLowerCase() == 'paid' ||
      (totalAmount > 0 && paidAmount >= totalAmount);

  bool get isDp =>
      paymentStatus.toLowerCase() == 'dp' ||
      paymentStatus.toLowerCase() == 'partial' ||
      (paidAmount > 0 && paidAmount < totalAmount);

  bool get isUnpaid => !isPaid && !isDp;

  String get paymentStatusDisplay {
    if (isPaid) return 'Lunas';
    if (isDp) return 'DP';
    return 'Belum Lunas';
  }

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

    int parseInt(Object? val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return InvoiceRecord(
      id: (json['id'] ?? '').toString(),
      orderanId: (json['orderan_id'] ?? '').toString(),
      invoiceReference:
          (json['invoice_reference'] ?? json['nomor_invoice'] ?? '-').toString(),
      invoiceDate: (json['invoice_date'] ?? '').toString(),
      dueDate: (json['due_date'] ?? '').toString(),
      productName: (json['product_name'] ?? 'Sewa Mistyfan').toString(),
      quantity: parseInt(json['quantity']),
      rentalDays: parseInt(json['rental_days']),
      unitPrice: parseNum(json['unit_price']),
      subtotal: parseNum(json['subtotal']),
      totalAmount: parseNum(json['total_amount']),
      paidAmount: parseNum(json['paid_amount']),
      paymentStatus: (json['payment_status'] ?? 'Belum Lunas').toString(),
      customerName:
          (json['customer_name'] ?? json['nama_client'] ?? '').toString(),
      customerPhone:
          (json['customer_phone'] ?? json['nomor_whatsapp'] ?? '').toString(),
      invoiceSource: (json['invoice_source'] ?? 'order').toString(),
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
    'payment_status': paymentStatus,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'invoice_source': invoiceSource,
  };
}
