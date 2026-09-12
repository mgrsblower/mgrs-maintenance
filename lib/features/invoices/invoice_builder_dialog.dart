import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../schedule/order_model.dart';
import '../../shared/pressable.dart';
import 'invoice_adjustment_editor.dart';
import 'invoice_model.dart';
import 'pdf/invoice_pdf_dialogs.dart';
import 'quick_payment_dialog.dart';

class InvoiceBuilderDialog extends StatefulWidget {
  const InvoiceBuilderDialog({
    super.key,
    required this.invoice,
    required this.gateway,
    required this.onSaved,
    this.selectedOrder,
    this.initiallyEditing = false,
  });

  final InvoiceRecord invoice;
  final MaintenanceGateway gateway;
  final ValueChanged<InvoiceRecord> onSaved;
  final OrderanSewa? selectedOrder;
  final bool initiallyEditing;

  @override
  State<InvoiceBuilderDialog> createState() => _InvoiceBuilderDialogState();
}

class _InvoiceBuilderDialogState extends State<InvoiceBuilderDialog> {
  static const _footerActionHeight = AppTokens.minTouchTarget;
  static const _footerActionRadius = AppTokens.controlRadius;
  static const _footerActionGap = AppTokens.space4;
  static const _footerLabelSize = 12.0;
  static const _footerInk = AppTokens.ink;
  static const _footerMutedSurface = AppTokens.porcelain;
  static const _footerBorder = AppTokens.mist;
  static const _footerShareSurface = AppTokens.successSurface;
  static const _footerShareBorder = AppTokens.success;
  static const _footerShareInk = AppTokens.success;

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

    _refController = TextEditingController(
      text: widget.invoice.invoiceReference,
    );
    _orderIdController = TextEditingController(
      text: widget.invoice.orderanId ?? '',
    );
    _productController = TextEditingController(
      text: widget.invoice.productName,
    );
    _customerNameController = TextEditingController(
      text: widget.invoice.customerName,
    );
    _customerPhoneController = TextEditingController(
      text: widget.invoice.customerPhone,
    );
    _invoiceDateController = TextEditingController(
      text: widget.invoice.invoiceDate,
    );
    _dueDateController = TextEditingController(text: widget.invoice.dueDate);
    _qtyController = TextEditingController(
      text: widget.invoice.quantity.toString(),
    );
    _daysController = TextEditingController(
      text: widget.invoice.rentalDays.toString(),
    );
    _unitPriceController = TextEditingController(
      text: widget.invoice.unitPrice.toString(),
    );
    _paidAmountController = TextEditingController(
      text: widget.invoice.paidAmount.toString(),
    );
    _paymentStatus = widget.invoice.paymentStatus;

    for (final adj in widget.invoice.adjustments) {
      _adjustments.add(
        _AdjustmentItem(
          descCtrl: TextEditingController(text: adj.description),
          amountCtrl: TextEditingController(text: adj.amount.toString()),
        ),
      );
    }

    for (final c in [
      _qtyController,
      _daysController,
      _unitPriceController,
      _paidAmountController,
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
    final colors = Theme.of(context).colorScheme;
    final calc = _calculation;
    final cleanPhone = _customerPhoneController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
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
        SnackBar(
          content: const Text('Tidak dapat membuka WhatsApp.'),
          backgroundColor: colors.errorContainer,
          contentTextStyle: TextStyle(color: colors.onErrorContainer),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>();
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: operational?.onSuccess ?? colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: operational?.success ?? colors.surfaceContainer,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan invoice: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onErrorContainer,
            ),
          ),
          backgroundColor: colors.errorContainer,
        ),
      );
    }
  }

  bool _isExporting = false;

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final calc = _calculation;
      final resolvedAdjustments = _adjustments
          .map((adj) {
            final desc = adj.descCtrl.text.trim();
            final amt = num.tryParse(adj.amountCtrl.text.trim()) ?? 0;
            return InvoiceAdjustment(description: desc, amount: amt);
          })
          .where((a) => a.description.isNotEmpty || a.amount != 0)
          .toList();

      final currentInput = SaveInvoiceInput(
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

      await InvoicePdfExportHelper.exportWithModalProgress(
        context: context,
        invoice: widget.invoice,
        currentInput: currentInput,
        order: widget.selectedOrder,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDialogHeader(),
              const SizedBox(height: AppTokens.space12),
              const Divider(),
              const SizedBox(height: AppTokens.space16),
              Expanded(
                child: _isEditing ? _buildEditForm() : _buildReceiptView(),
              ),
              const SizedBox(height: AppTokens.space16),
              const Divider(),
              const SizedBox(height: AppTokens.space12),
              _buildFooterActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>();
    final (statusBg, statusBorder, statusText) = switch (_paymentStatus) {
      InvoicePaymentStatus.paid => (
        operational?.success ?? colors.surfaceContainer,
        operational?.onSuccess ?? colors.onSurface,
        operational?.onSuccess ?? colors.onSurface,
      ),
      InvoicePaymentStatus.partial => (
        operational?.warning ?? colors.surfaceContainer,
        operational?.onWarning ?? colors.onSurface,
        operational?.onWarning ?? colors.onSurface,
      ),
      InvoicePaymentStatus.cancelled => (
        operational?.danger ?? colors.errorContainer,
        operational?.onDanger ?? colors.onErrorContainer,
        operational?.onDanger ?? colors.onErrorContainer,
      ),
      InvoicePaymentStatus.unpaid => (
        colors.surfaceContainer,
        colors.outlineVariant,
        colors.onSurfaceVariant,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _refController.text,
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTokens.space4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space8,
                      vertical: AppTokens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
                      border: Border.all(color: statusBorder),
                    ),
                    child: Text(
                      _paymentStatus.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusText,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Text(
                    _isEditing ? 'Mode Edit Rincian' : 'Dokumen Tagihan Resmi',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.space8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              icon: Icon(
                _isEditing
                    ? Icons.visibility_outlined
                    : Icons.edit_outlined,
              ),
              label: Text(_isEditing ? 'Pratinjau' : 'Ubah'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppTokens.minTouchTarget),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space12,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Tutup',
            ),
          ],
        ),
      ],
    );
  }

  // Minimalist Receipt / Document Style (Read-only)
  Widget _buildReceiptView() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>();
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
          Text(clientName, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTokens.space4),
          Text(
            '$eventName${phone.isNotEmpty ? " • $phone" : ""}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            'Tgl Invoice: ${_invoiceDateController.text.trim()} • Jatuh Tempo: ${_dueDateController.text.trim()}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppTokens.space16),
          const Divider(),
          const SizedBox(height: AppTokens.space12),
          Text('RINCIAN SEWA', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppTokens.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sewa Mistyfan Blower MGRS',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      '$qty Unit × $days Hari @ ${InvoiceRecord.formatRupiah(unitPrice)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                InvoiceRecord.formatRupiah(calc.subtotal),
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          if (_adjustments.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space12),
            for (final adj in _adjustments)
              if (adj.descCtrl.text.trim().isNotEmpty ||
                  (num.tryParse(adj.amountCtrl.text) ?? 0) != 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        adj.descCtrl.text.trim().isNotEmpty
                            ? adj.descCtrl.text.trim()
                            : 'Penyesuaian Biaya',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        InvoiceRecord.formatRupiah(
                          num.tryParse(adj.amountCtrl.text) ?? 0,
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
          const SizedBox(height: AppTokens.space16),
          const Divider(),
          const SizedBox(height: AppTokens.space12),
          _receiptRow(
            'Subtotal Tagihan',
            InvoiceRecord.formatRupiah(calc.subtotal),
          ),
          if (calc.adjustmentTotal != 0) ...[
            const SizedBox(height: AppTokens.space4),
            _receiptRow(
              'Penyesuaian',
              InvoiceRecord.formatRupiah(calc.adjustmentTotal),
            ),
          ],
          const SizedBox(height: AppTokens.space8),
          _receiptRow(
            'Total Tagihan',
            InvoiceRecord.formatRupiah(calc.totalAmount),
            isBold: true,
          ),
          const SizedBox(height: AppTokens.space4),
          _receiptRow(
            'Terbayar',
            InvoiceRecord.formatRupiah(calc.paidAmount),
            valueColor: operational?.onSuccess ?? colors.primary,
          ),
          const SizedBox(height: AppTokens.space8),
          _receiptRow(
            calc.remainingAmount > 0 ? 'Sisa Pembayaran' : 'Status Tagihan',
            calc.remainingAmount > 0
                ? InvoiceRecord.formatRupiah(calc.remainingAmount)
                : 'Lunas',
            isBold: true,
            valueColor: calc.remainingAmount > 0
                ? operational?.onDanger ?? colors.error
                : operational?.onSuccess ?? colors.primary,
          ),
          const SizedBox(height: AppTokens.space16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTokens.space12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTokens.controlRadius),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppTokens.space8),
                Text(
                  'BCA 2302619141 a/n MADNUR',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final labelStyle = isBold
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.bodySmall;
    final valueStyle = isBold
        ? theme.textTheme.labelLarge?.copyWith(color: valueColor)
        : theme.textTheme.labelMedium?.copyWith(
            color: valueColor ?? colors.onSurface,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }

  // Edit Mode (Clean, spacious form without cramped labels)
  Widget _buildEditForm() {
    final theme = Theme.of(context);
    final calc = _calculation;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('INFORMASI KLIEN & ACARA', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppTokens.space8),
            TextFormField(
              controller: _customerNameController,
              decoration: _inputDecoration('Nama Klien'),
            ),
            const SizedBox(height: AppTokens.space12),
            TextFormField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration('No. WhatsApp Klien'),
            ),
            const SizedBox(height: AppTokens.space12),
            TextFormField(
              controller: _productController,
              decoration: _inputDecoration('Nama Acara / Keterangan'),
            ),
            const SizedBox(height: AppTokens.space16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invoiceDateController,
                    decoration: _inputDecoration('Tanggal Invoice'),
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: TextFormField(
                    controller: _dueDateController,
                    decoration: _inputDecoration('Jatuh Tempo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space24),
            Text('KUANTITAS & HARGA SEWA', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppTokens.space8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Unit'),
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: TextFormField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Durasi (Hari)'),
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Harga Satuan',
                      prefix: 'Rp ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PENYESUAIAN / DISKON',
                  style: theme.textTheme.labelMedium,
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _adjustments.add(
                        _AdjustmentItem(
                          descCtrl: TextEditingController(),
                          amountCtrl: TextEditingController(text: '0'),
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            if (_adjustments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
                child: Text(
                  'Tidak ada penyesuaian biaya tambahan.',
                  style: theme.textTheme.bodySmall,
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
            const SizedBox(height: AppTokens.space16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<InvoicePaymentStatus>(
                    key: ValueKey<InvoicePaymentStatus>(_paymentStatus),
                    initialValue: _paymentStatus,
                    decoration: _inputDecoration('Status'),
                    items: InvoicePaymentStatus.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _paymentStatus = val;
                          if (val == InvoicePaymentStatus.unpaid) {
                            _paidAmountController.text = '0';
                          } else if (val == InvoicePaymentStatus.paid) {
                            _paidAmountController.text = calc.totalAmount
                                .toString();
                          }
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: TextFormField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Terbayar',
                      prefix: 'Rp ',
                    ),
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
      prefixText: prefix,
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onTap,
    Widget? icon,
    required String label,
    required Color bg,
    required Color border,
    required Color textColor,
    Key? key,
  }) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        key: key,
        height: _footerActionHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(_footerActionRadius),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: AppTokens.space4)],
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconActionButton({
    required Key key,
    required VoidCallback? onTap,
    required String tooltip,
    required Widget icon,
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: PressableScale(
          onTap: onTap,
          child: Container(
            key: key,
            width: _footerActionHeight,
            height: _footerActionHeight,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(_footerActionRadius),
              border: Border.all(color: borderColor),
            ),
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(size: 20, color: iconColor),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterTextButton({
    required Key key,
    required VoidCallback onTap,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        key: key,
        height: _footerActionHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(_footerActionRadius),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            child: Text(
              label,
              maxLines: 1,
              style: theme.textTheme.labelLarge?.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>();
    if (_isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: const Text('Batal Ubah'),
          ),
          const SizedBox(width: _footerActionGap),
          _buildActionButton(
            onTap: _isExporting ? null : _exportPdf,
            icon: _isExporting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.download_rounded, color: colors.onSurface),
            label: _isExporting ? 'Mengunduh...' : 'Unduh PDF',
            bg: colors.surfaceContainer,
            border: colors.outlineVariant,
            textColor: colors.onSurface,
          ),
          const SizedBox(width: _footerActionGap),
          _buildActionButton(
            onTap: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTokens.white,
                    ),
                  )
                : const Icon(Icons.save_outlined, color: AppTokens.white),
            label: 'Simpan',
            bg: colors.primary,
            border: colors.primary,
            textColor: colors.onPrimary,
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildIconActionButton(
          key: const Key('btn-export-pdf'),
          onTap: _isExporting ? null : _exportPdf,
          tooltip: _isExporting ? 'Mengunduh PDF' : 'Unduh PDF',
          icon: _isExporting
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onSurface,
                  ),
                )
              : const Icon(Icons.file_download_outlined),
          backgroundColor: colors.surfaceContainer,
          borderColor: colors.outlineVariant,
          iconColor: colors.onSurface,
        ),
        const SizedBox(width: _footerActionGap),
        _buildIconActionButton(
          key: const Key('btn-share-whatsapp'),
          onTap: _shareToWhatsApp,
          tooltip: 'Bagikan melalui WhatsApp',
          icon: const Icon(Icons.share_rounded),
          backgroundColor: operational?.success ?? _footerShareSurface,
          borderColor: operational?.onSuccess ?? _footerShareBorder,
          iconColor: operational?.onSuccess ?? _footerShareInk,
        ),
        const SizedBox(width: _footerActionGap),
        Expanded(
          flex: 3,
          child: _buildFooterTextButton(
            key: const Key('btn-quick-payment'),
            onTap: () {
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
            label: 'Atur Bayar',
            backgroundColor: colors.surface,
            borderColor: colors.outline,
            textColor: colors.onSurface,
          ),
        ),
        const SizedBox(width: _footerActionGap),
        Expanded(
          flex: 2,
          child: _buildFooterTextButton(
            key: const Key('btn-close-dialog'),
            onTap: () => Navigator.of(context).pop(),
            label: 'Selesai',
            backgroundColor: colors.primary,
            borderColor: colors.primary,
            textColor: colors.onPrimary,
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
