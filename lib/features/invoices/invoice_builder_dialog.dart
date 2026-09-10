import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
import 'invoice_adjustment_editor.dart';
import 'invoice_model.dart';
import 'quick_payment_dialog.dart';

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

    _refController =
        TextEditingController(text: widget.invoice.invoiceReference);
    _orderIdController =
        TextEditingController(text: widget.invoice.orderanId ?? '');
    _productController =
        TextEditingController(text: widget.invoice.productName);
    _customerNameController =
        TextEditingController(text: widget.invoice.customerName);
    _customerPhoneController =
        TextEditingController(text: widget.invoice.customerPhone);
    _invoiceDateController =
        TextEditingController(text: widget.invoice.invoiceDate);
    _dueDateController = TextEditingController(text: widget.invoice.dueDate);
    _qtyController =
        TextEditingController(text: widget.invoice.quantity.toString());
    _daysController =
        TextEditingController(text: widget.invoice.rentalDays.toString());
    _unitPriceController =
        TextEditingController(text: widget.invoice.unitPrice.toString());
    _paidAmountController =
        TextEditingController(text: widget.invoice.paidAmount.toString());
    _paymentStatus = widget.invoice.paymentStatus;

    for (final adj in widget.invoice.adjustments) {
      _adjustments.add(_AdjustmentItem(
        descCtrl: TextEditingController(text: adj.description),
        amountCtrl: TextEditingController(text: adj.amount.toString()),
      ));
    }

    for (final c in [
      _qtyController,
      _daysController,
      _unitPriceController,
      _paidAmountController
    ]) {
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

    final resolvedAdjustments = _adjustments
        .map((a) {
          final desc = a.descCtrl.text.trim();
          final amt = num.tryParse(a.amountCtrl.text.trim()) ?? 0;
          return InvoiceAdjustment(description: desc, amount: amt);
        })
        .where((a) => a.description.isNotEmpty || a.amount != 0)
        .toList();

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
    final cleanPhone =
        _customerPhoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    var targetPhone = cleanPhone;
    if (targetPhone.startsWith('0')) {
      targetPhone = '62${targetPhone.substring(1)}';
    }

    final message =
        '''Halo *${_customerNameController.text.trim().isNotEmpty ? _customerNameController.text.trim() : 'Klien MGRS'}*,

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
          backgroundColor: Color(0xFF9F2F2D),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final calc = _calculation;
    final resolvedAdjustments = _adjustments
        .map((a) {
          final desc = a.descCtrl.text.trim();
          final amt = num.tryParse(a.amountCtrl.text.trim()) ?? 0;
          return InvoiceAdjustment(description: desc, amount: amt);
        })
        .where((a) => a.description.isNotEmpty || a.amount != 0)
        .toList();

    final input = SaveInvoiceInput(
      invoiceId: widget.invoice.id,
      orderanId: _orderIdController.text.trim().isEmpty
          ? null
          : _orderIdController.text.trim(),
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
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice ${saved.invoiceReference} berhasil disimpan.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF346538),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan invoice: $e'),
          backgroundColor: const Color(0xFF9F2F2D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildDialogHeader(),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              const SizedBox(height: 14),
              // Body: Mode Pratinjau (Document Receipt) vs Mode Edit
              Expanded(
                child: _isEditing ? _buildEditForm() : _buildReceiptView(),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              const SizedBox(height: 12),
              // Footer Actions
              _buildFooterActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    final (statusBg, statusText) = switch (_paymentStatus) {
      InvoicePaymentStatus.paid => (
          const Color(0xFFEDF3EC),
          const Color(0xFF346538)
        ),
      InvoicePaymentStatus.partial => (
          const Color(0xFFFBF3DB),
          const Color(0xFF956400)
        ),
      InvoicePaymentStatus.unpaid => (
          const Color(0xFFFDEBEC),
          const Color(0xFF9F2F2D)
        ),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _refController.text,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    _paymentStatus.label,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _isEditing ? 'Mode Ubah Rincian' : 'Dokumen Tagihan Resmi',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11.5,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
        Row(
          children: [
            PressableScale(
              onTap: () => setState(() => _isEditing = !_isEditing),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isEditing ? Icons.visibility_outlined : Icons.edit_outlined,
                      size: 13,
                      color: const Color(0xFF18181B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isEditing ? 'Pratinjau' : 'Ubah',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 20, color: Color(0xFF71717A)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  // Minimalist Receipt / Document Style (Read-only)
  Widget _buildReceiptView() {
    final calc = _calculation;
    final clientName = _customerNameController.text.trim().isNotEmpty
        ? _customerNameController.text.trim()
        : 'Klien MGRS';
    final eventName = _productController.text.trim().isNotEmpty
        ? _productController.text.trim()
        : 'Sewa Mistyfan';
    final phone = _customerPhoneController.text.trim();
    final qty = _qtyController.text.trim();
    final days = _daysController.text.trim();
    final unitPrice = num.tryParse(_unitPriceController.text.trim()) ?? 250000;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client & Event block
          Text(
            clientName,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$eventName${phone.isNotEmpty ? " • $phone" : ""}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tgl Invoice: ${_invoiceDateController.text.trim()} • Jatuh Tempo: ${_dueDateController.text.trim()}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              color: Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          const SizedBox(height: 12),
          // Rincian Item Sewa
          const Text(
            'RINCIAN SEWA',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFA1A1AA),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sewa Mistyfan Blower MGRS',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$qty Unit × $days Hari @ ${InvoiceRecord.formatRupiah(unitPrice)}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                InvoiceRecord.formatRupiah(calc.subtotal),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          // Adjustments if any
          if (_adjustments.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final adj in _adjustments)
              if (adj.descCtrl.text.trim().isNotEmpty ||
                  (num.tryParse(adj.amountCtrl.text) ?? 0) != 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        adj.descCtrl.text.trim().isNotEmpty
                            ? adj.descCtrl.text.trim()
                            : 'Penyesuaian Biaya',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: Color(0xFF71717A),
                        ),
                      ),
                      Text(
                        InvoiceRecord.formatRupiah(
                            num.tryParse(adj.amountCtrl.text) ?? 0),
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          const SizedBox(height: 12),
          // Summary Rows
          _receiptRow('Subtotal Tagihan', InvoiceRecord.formatRupiah(calc.subtotal)),
          if (calc.adjustmentTotal != 0) ...[
            const SizedBox(height: 4),
            _receiptRow('Penyesuaian', InvoiceRecord.formatRupiah(calc.adjustmentTotal)),
          ],
          const SizedBox(height: 6),
          _receiptRow('Total Tagihan', InvoiceRecord.formatRupiah(calc.totalAmount), isBold: true),
          const SizedBox(height: 4),
          _receiptRow('Terbayar', InvoiceRecord.formatRupiah(calc.paidAmount), valueColor: const Color(0xFF346538)),
          const SizedBox(height: 6),
          _receiptRow(
            calc.remainingAmount > 0 ? 'Sisa Pembayaran' : 'Status Tagihan',
            calc.remainingAmount > 0
                ? InvoiceRecord.formatRupiah(calc.remainingAmount)
                : 'Lunas',
            isBold: true,
            valueColor: calc.remainingAmount > 0
                ? const Color(0xFF9F2F2D)
                : const Color(0xFF346538),
          ),
          const SizedBox(height: 14),
          // Bank info
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance_outlined,
                    size: 16, color: Color(0xFF71717A)),
                SizedBox(width: 8),
                Text(
                  'BCA 2302619141 a/n MADNUR',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF18181B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF71717A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: isBold ? 13.5 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? const Color(0xFF18181B),
          ),
        ),
      ],
    );
  }

  // Edit Mode (Clean, spacious form without cramped labels)
  Widget _buildEditForm() {
    final calc = _calculation;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INFORMASI KLIEN & ACARA',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA1A1AA),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customerNameController,
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 13),
              decoration: _inputDecoration('Nama Klien'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 13),
              decoration: _inputDecoration('No. WhatsApp Klien'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _productController,
              style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 13),
              decoration: _inputDecoration('Nama Acara / Keterangan'),
            ),
            const SizedBox(height: 14),
            // Dates in 2 balanced columns
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invoiceDateController,
                    style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans', fontSize: 12.5),
                    decoration: _inputDecoration('Tanggal Invoice'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _dueDateController,
                    style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans', fontSize: 12.5),
                    decoration: _inputDecoration('Jatuh Tempo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'KUANTITAS & HARGA SEWA',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFA1A1AA),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Balanced quantity and price row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                    decoration: _inputDecoration('Unit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                    decoration: _inputDecoration('Durasi (Hari)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                    decoration: _inputDecoration('Harga Satuan', prefix: 'Rp '),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Adjustments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PENYESUAIAN / DISKON',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA1A1AA),
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _adjustments.add(_AdjustmentItem(
                        descCtrl: TextEditingController(),
                        amountCtrl: TextEditingController(text: '0'),
                      ));
                    });
                  },
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('Tambah', style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (_adjustments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Tidak ada penyesuaian biaya tambahan.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    color: Color(0xFFA1A1AA),
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
                  readOnly: false,
                  canRemove: true,
                  onChanged: () => setState(() {}),
                  onRemove: () {
                    setState(() {
                      _adjustments.removeAt(i).dispose();
                    });
                  },
                );
              }),
            const SizedBox(height: 14),
            // Payment fields
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<InvoicePaymentStatus>(
                    key: ValueKey<InvoicePaymentStatus>(_paymentStatus),
                    initialValue: _paymentStatus,
                    decoration: _inputDecoration('Status'),
                    items: InvoicePaymentStatus.values.map((s) {
                      return DropdownMenuItem(
                          value: s, child: Text(s.label, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _paymentStatus = val;
                          if (val == InvoicePaymentStatus.unpaid) {
                            _paidAmountController.text = '0';
                          } else if (val == InvoicePaymentStatus.paid) {
                            _paidAmountController.text =
                                calc.totalAmount.toString();
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                    decoration: _inputDecoration('Terbayar', prefix: 'Rp '),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? prefix}) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 12,
        color: Color(0xFF71717A),
      ),
      prefixText: prefix,
      prefixStyle: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontWeight: FontWeight.w700,
        color: Color(0xFF18181B),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF18181B)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildFooterActions() {
    if (_isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: const Text('Batal Ubah',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 12)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Simpan Perubahan',
                    style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
          ),
        ],
      );
    }

    return Row(
      children: [
        PressableScale(
          onTap: _shareToWhatsApp,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF3EC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_rounded, size: 14, color: Color(0xFF346538)),
                SizedBox(width: 6),
                Text(
                  'Kirim WA',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF346538),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => QuickPaymentDialog(
                invoice: widget.invoice,
                gateway: widget.gateway,
                onPaymentUpdated: (updated) {
                  _paidAmountController.text = updated.paidAmount.toString();
                  _paymentStatus = updated.paymentStatus;
                  widget.onSaved(updated);
                  setState(() {});
                },
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF18181B),
            side: const BorderSide(color: Color(0xFFE4E4E7)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          ),
          child: const Text('Atur Bayar',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF18181B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          ),
          child: const Text('Selesai',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
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
