import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/gateway.dart';
import 'invoice_adjustment_editor.dart';
import 'invoice_model.dart';

class InvoiceBuilderDialog extends StatefulWidget {
  const InvoiceBuilderDialog({
    super.key,
    required this.invoice,
    required this.gateway,
    required this.onSaved,
    this.initiallyEditing = false,
  });

  final InvoiceRecord invoice;
  final MaintenanceGateway gateway;
  final ValueChanged<InvoiceRecord> onSaved;
  final bool initiallyEditing;

  @override
  State<InvoiceBuilderDialog> createState() => _InvoiceBuilderDialogState();
}

class _InvoiceBuilderDialogState extends State<InvoiceBuilderDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;
  bool _isSaving = false;

  late final TextEditingController _refController;
  late final TextEditingController _orderIdController;
  late final TextEditingController _productController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _invoiceDateController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _qtyController;
  late final TextEditingController _daysController;
  late final TextEditingController _unitPriceController;
  late final TextEditingController _paidAmountController;
  late InvoicePaymentStatus _paymentStatus;

  final List<_AdjustmentItem> _adjustments = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initiallyEditing;

    _refController = TextEditingController(text: widget.invoice.invoiceReference);
    _orderIdController = TextEditingController(text: widget.invoice.orderanId ?? '');
    _productController = TextEditingController(text: widget.invoice.productName);
    _customerNameController = TextEditingController(text: widget.invoice.customerName);
    _customerPhoneController = TextEditingController(text: widget.invoice.customerPhone);
    _invoiceDateController = TextEditingController(text: widget.invoice.invoiceDate);
    _dueDateController = TextEditingController(text: widget.invoice.dueDate);
    _qtyController = TextEditingController(text: widget.invoice.quantity.toString());
    _daysController = TextEditingController(text: widget.invoice.rentalDays.toString());
    _unitPriceController = TextEditingController(text: widget.invoice.unitPrice.toString());
    _paidAmountController = TextEditingController(text: widget.invoice.paidAmount.toString());
    _paymentStatus = widget.invoice.paymentStatus;

    for (final adj in widget.invoice.adjustments) {
      _adjustments.add(_AdjustmentItem(
        descCtrl: TextEditingController(text: adj.description),
        amountCtrl: TextEditingController(text: adj.amount.toString()),
      ));
    }

    for (final c in [_qtyController, _daysController, _unitPriceController, _paidAmountController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _refController.dispose();
    _orderIdController.dispose();
    _productController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _invoiceDateController.dispose();
    _dueDateController.dispose();
    _qtyController.dispose();
    _daysController.dispose();
    _unitPriceController.dispose();
    _paidAmountController.dispose();
    for (final a in _adjustments) {
      a.dispose();
    }
    super.dispose();
  }

  InvoiceCalculation get _calculation {
    final qty = num.tryParse(_qtyController.text.trim()) ?? 1;
    final days = num.tryParse(_daysController.text.trim()) ?? 1;
    final unitPrice = num.tryParse(_unitPriceController.text.trim()) ?? 250000;
    final paid = num.tryParse(_paidAmountController.text.trim()) ?? 0;

    final resolvedAdjustments = _adjustments.map((a) {
      final desc = a.descCtrl.text.trim();
      final amt = num.tryParse(a.amountCtrl.text.trim()) ?? 0;
      return InvoiceAdjustment(description: desc, amount: amt);
    }).where((a) => a.description.isNotEmpty || a.amount != 0).toList();

    return InvoiceCalculator.calculate(
      quantity: qty,
      rentalDays: days,
      unitPrice: unitPrice,
      paymentStatus: _paymentStatus,
      adjustments: resolvedAdjustments,
      paidAmount: paid,
    );
  }

  Future<void> _shareToWhatsApp() async {
    final calc = _calculation;
    final cleanPhone = _customerPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    var targetPhone = cleanPhone;
    if (targetPhone.startsWith('0')) {
      targetPhone = '62${targetPhone.substring(1)}';
    }

    final message = '''Halo *${_customerNameController.text.trim().isNotEmpty ? _customerNameController.text.trim() : 'Klien MGRS'}*,

Berikut rincian tagihan resmi dari *MGRS Blower*:
📄 *No. Invoice:* ${_refController.text.trim()}
🎉 *Acara / Produk:* ${_productController.text.trim()}
📅 *Tanggal:* ${_invoiceDateController.text.trim()} (Jatuh Tempo: ${_dueDateController.text.trim()})
📦 *Rincian Sewa:* ${_qtyController.text.trim()} Unit x ${_daysController.text.trim()} Hari @ ${InvoiceRecord.formatRupiah(num.tryParse(_unitPriceController.text) ?? 250000)}
${_adjustments.isNotEmpty ? '📝 *Penyesuaian Biaya:* ${InvoiceRecord.formatRupiah(calc.adjustmentTotal)}\n' : ''}
💰 *Total Tagihan:* ${InvoiceRecord.formatRupiah(calc.totalAmount)}
💳 *Terbayar:* ${InvoiceRecord.formatRupiah(calc.paidAmount)} (${_paymentStatus.label})
${calc.remainingAmount > 0 ? '⚠️ *Sisa Pembayaran:* ${InvoiceRecord.formatRupiah(calc.remainingAmount)}\n' : ''}
Rekening Pembayaran:
*BCA: 2302619141 a/n MADNUR*

Terima kasih atas kerja sama dan kepercayaannya!''';

    final uri = Uri.parse(
      targetPhone.isNotEmpty
          ? 'https://wa.me/$targetPhone?text=${Uri.encodeComponent(message)}'
          : 'whatsapp://send?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka WhatsApp.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final calc = _calculation;
    final resolvedAdjustments = _adjustments.map((a) {
      final desc = a.descCtrl.text.trim();
      final amt = num.tryParse(a.amountCtrl.text.trim()) ?? 0;
      return InvoiceAdjustment(description: desc, amount: amt);
    }).where((a) => a.description.isNotEmpty || a.amount != 0).toList();

    final input = SaveInvoiceInput(
      invoiceId: widget.invoice.id,
      orderanId: _orderIdController.text.trim().isEmpty ? null : _orderIdController.text.trim(),
      invoiceReference: _refController.text.trim(),
      invoiceDate: _invoiceDateController.text.trim(),
      dueDate: _dueDateController.text.trim(),
      productName: _productController.text.trim(),
      quantity: num.tryParse(_qtyController.text.trim()) ?? 1,
      rentalDays: num.tryParse(_daysController.text.trim()) ?? 1,
      unitPrice: num.tryParse(_unitPriceController.text.trim()) ?? 250000,
      subtotal: calc.subtotal,
      totalAmount: calc.totalAmount,
      paidAmount: calc.paidAmount,
      paymentStatus: _paymentStatus,
      invoiceSource: widget.invoice.invoiceSource,
      customerName: _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      adjustments: resolvedAdjustments,
      printedAt: widget.invoice.printedAt,
    );

    setState(() => _isSaving = true);
    try {
      final saved = await widget.gateway.saveInvoice(input);
      if (!mounted) return;
      widget.onSaved(saved);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice ${saved.invoiceReference} berhasil disimpan.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan invoice: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calc = _calculation;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _isEditing ? 'Edit Formulir Invoice' : 'Rincian Invoice',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _isEditing ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isEditing ? 'Mode Edit' : 'Pratinjau',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _isEditing ? const Color(0xFFB45309) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.invoice.invoiceReference,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.visibility_outlined : Icons.edit_outlined,
                          size: 20,
                          color: const Color(0xFF2563EB),
                        ),
                        tooltip: _isEditing ? 'Lihat Pratinjau' : 'Edit Invoice',
                        onPressed: () => setState(() => _isEditing = !_isEditing),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              // Body (Scrollable Form)
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer & Order Info
                        const Text(
                          'Informasi Klien & Order',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _customerNameController,
                                readOnly: !_isEditing,
                                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Nama Klien',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _customerPhoneController,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'No. WhatsApp',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _productController,
                          readOnly: !_isEditing,
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Nama Acara / Keterangan',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Dates
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _invoiceDateController,
                                readOnly: !_isEditing,
                                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Tanggal Invoice',
                                  hintText: 'YYYY-MM-DD',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _dueDateController,
                                readOnly: !_isEditing,
                                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Jatuh Tempo',
                                  hintText: 'YYYY-MM-DD',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Unit & Price Matrix
                        const Text(
                          'Kuantitas & Biaya Sewa',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _qtyController,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Jumlah Unit',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _daysController,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Durasi (Hari)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _unitPriceController,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Harga Satuan',
                                  prefixText: 'Rp ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Adjustments
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Penyesuaian Biaya / Diskon',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                            if (_isEditing)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _adjustments.add(_AdjustmentItem(
                                      descCtrl: TextEditingController(),
                                      amountCtrl: TextEditingController(text: '0'),
                                    ));
                                  });
                                },
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Tambah', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        if (_adjustments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Tidak ada penyesuaian biaya tambahan.',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_adjustments.length, (i) {
                            final item = _adjustments[i];
                            return InvoiceAdjustmentEditor(
                              index: i,
                              descriptionController: item.descCtrl,
                              amountController: item.amountCtrl,
                              readOnly: !_isEditing,
                              canRemove: _isEditing,
                              onChanged: () => setState(() {}),
                              onRemove: () {
                                setState(() {
                                  _adjustments.removeAt(i).dispose();
                                });
                              },
                            );
                          }),
                        const SizedBox(height: 18),
                        // Payment reconciliation
                        const Text(
                          'Status & Pembayaran',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<InvoicePaymentStatus>(
                                key: ValueKey<InvoicePaymentStatus>(_paymentStatus),
                                initialValue: _paymentStatus,
                                decoration: InputDecoration(
                                  labelText: 'Status Pembayaran',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                items: InvoicePaymentStatus.values.map((s) {
                                  return DropdownMenuItem(value: s, child: Text(s.label));
                                }).toList(),
                                onChanged: _isEditing
                                    ? (val) {
                                        if (val != null) {
                                          setState(() {
                                            _paymentStatus = val;
                                            if (val == InvoicePaymentStatus.unpaid) {
                                              _paidAmountController.text = '0';
                                            } else if (val == InvoicePaymentStatus.paid) {
                                              _paidAmountController.text = calc.totalAmount.toString();
                                            }
                                          });
                                        }
                                      }
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _paidAmountController,
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Nominal Terbayar',
                                  prefixText: 'Rp ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Live Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              _summaryRow('Subtotal Sewa', InvoiceRecord.formatRupiah(calc.subtotal)),
                              if (calc.adjustmentTotal != 0) ...[
                                const SizedBox(height: 6),
                                _summaryRow('Total Penyesuaian', InvoiceRecord.formatRupiah(calc.adjustmentTotal)),
                              ],
                              const Divider(height: 18),
                              _summaryRow(
                                'Total Tagihan',
                                InvoiceRecord.formatRupiah(calc.totalAmount),
                                isBold: true,
                              ),
                              const SizedBox(height: 6),
                              _summaryRow(
                                'Terbayar',
                                InvoiceRecord.formatRupiah(calc.paidAmount),
                                valueColor: const Color(0xFF059669),
                              ),
                              const SizedBox(height: 6),
                              _summaryRow(
                                'Sisa Tagihan',
                                InvoiceRecord.formatRupiah(calc.remainingAmount),
                                isBold: true,
                                valueColor: calc.remainingAmount > 0
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF059669),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 24),
              // Footer Action Buttons
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _shareToWhatsApp,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text(
                      'Kirim WA',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Simpan Invoice',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _AdjustmentItem {
  _AdjustmentItem({required this.descCtrl, required this.amountCtrl});
  final TextEditingController descCtrl;
  final TextEditingController amountCtrl;

  void dispose() {
    descCtrl.dispose();
    amountCtrl.dispose();
  }
}
