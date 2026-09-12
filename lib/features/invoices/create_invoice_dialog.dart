import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../schedule/order_model.dart';
import 'invoice_model.dart';

class CreateInvoiceDialog extends StatefulWidget {
  const CreateInvoiceDialog({
    super.key,
    required this.gateway,
    required this.onCreated,
  });

  final MaintenanceGateway gateway;
  final ValueChanged<InvoiceRecord> onCreated;

  @override
  State<CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<CreateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isManualReimbursement = false;
  bool _isLoadingOrders = false;
  bool _isSubmitting = false;

  List<OrderanSewa> _availableOrders = [];
  OrderanSewa? _selectedOrder;

  final _refController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _productController = TextEditingController(text: 'Sewa Mistyfan');
  final _qtyController = TextEditingController(text: '1');
  final _daysController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController(text: '250000');

  @override
  void initState() {
    super.initState();
    _generateReference();
    _loadAvailableOrders();
  }

  @override
  void dispose() {
    _refController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _productController.dispose();
    _qtyController.dispose();
    _daysController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  void _generateReference([String? orderSuffix]) {
    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.day.toString().padLeft(2, '0')}';
    final suffix = orderSuffix ?? '${now.hour}${now.minute}${now.second}';
    _refController.text = 'INV/$date-$suffix';
  }

  Future<void> _loadAvailableOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final orders = await widget.gateway.fetchUpcomingOrders(limit: 50);
      if (!mounted) return;
      setState(() {
        _availableOrders = orders;
        _isLoadingOrders = false;
      });
      if (orders.isNotEmpty) _selectOrder(orders.first);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingOrders = false);
    }
  }

  void _selectOrder(OrderanSewa order) {
    _selectedOrder = order;
    final orderanId = order.orderanId ?? order.id;
    _generateReference(orderanId.split('-').last);
    _customerNameController.text = order.namaClient ?? '';
    _customerPhoneController.text = order.nomorWhatsapp ?? '';
    _productController.text = order.namaEvent.isNotEmpty ? order.namaEvent : 'Sewa Mistyfan';
    _qtyController.text = order.jumlahUnit.toString();
    _daysController.text = order.rentalDays > 0 ? order.rentalDays.toString() : '1';
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final dueStr = now.add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    final qty = num.tryParse(_qtyController.text.trim()) ?? 1;
    final days = num.tryParse(_daysController.text.trim()) ?? 1;
    final price = num.tryParse(_unitPriceController.text.trim()) ?? 250000;
    final subtotal = qty * price;
    final total = subtotal * days;
    final payload = <String, Object?>{
      'orderan_id': _isManualReimbursement ? null : (_selectedOrder?.orderanId ?? _selectedOrder?.id),
      'invoice_reference': _refController.text.trim(),
      'invoice_date': todayStr,
      'due_date': dueStr,
      'product_name': _productController.text.trim().isNotEmpty ? _productController.text.trim() : 'Sewa Mistyfan',
      'quantity': qty,
      'rental_days': days,
      'unit_price': price,
      'subtotal': subtotal,
      'total_amount': total,
      'paid_amount': 0,
      'payment_status': 'unpaid',
      'invoice_source': _isManualReimbursement ? 'manual_reimbursement' : 'order',
      'customer_name': _customerNameController.text.trim(),
      'customer_phone': _customerPhoneController.text.trim(),
      'adjustments': <Map<String, Object?>>[],
    };

    setState(() => _isSubmitting = true);
    try {
      final created = await widget.gateway.createInvoice(payload);
      if (!mounted) return;
      widget.onCreated(created);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${created.invoiceReference} berhasil dibuat.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat invoice: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final media = MediaQuery.of(context);
    final maxHeight = math.max(
      280.0,
      media.size.height - media.viewInsets.bottom - AppTokens.space32,
    ).toDouble();
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Buat Invoice Baru', style: theme.textTheme.titleLarge)),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded), tooltip: 'Tutup'),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.event_note_rounded), label: Text('Dari Order Sewa')),
                  ButtonSegment(value: true, icon: Icon(Icons.assignment_return_outlined), label: Text('Manual Reimbursement')),
                ],
                selected: {_isManualReimbursement},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  final manual = selection.first;
                  setState(() {
                    _isManualReimbursement = manual;
                    if (manual) {
                      _selectedOrder = null;
                      _generateReference();
                      _customerNameController.clear();
                      _customerPhoneController.clear();
                      _productController.text = 'Reimbursement Operasional';
                    } else if (_selectedOrder != null) {
                      _selectOrder(_selectedOrder!);
                    }
                  });
                },
              ),
              const SizedBox(height: AppTokens.space16),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isManualReimbursement) ...[
                          Text('Pilih Orderan Terjadwal:', style: theme.textTheme.labelLarge),
                          const SizedBox(height: AppTokens.space8),
                          if (_isLoadingOrders)
                            const Center(child: Padding(padding: EdgeInsets.all(AppTokens.space12), child: CircularProgressIndicator()))
                          else if (_availableOrders.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppTokens.space12),
                              decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(AppTokens.controlRadius)),
                              child: Text('Belum ada data orderan terjadwal.', style: theme.textTheme.bodySmall?.copyWith(color: colors.onErrorContainer)),
                            )
                          else
                            DropdownButtonFormField<OrderanSewa>(
                              key: ValueKey<String>(_selectedOrder?.id ?? 'none'),
                              initialValue: _selectedOrder,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Orderan'),
                              items: _availableOrders
                                  .map((order) => DropdownMenuItem(value: order, child: Text('${order.orderanId ?? order.id} • ${order.namaClient}', overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (order) {
                                if (order != null) _selectOrder(order);
                              },
                            ),
                          const SizedBox(height: AppTokens.space16),
                        ],
                        TextFormField(
                          controller: _refController,
                          decoration: const InputDecoration(labelText: 'No. Referensi Invoice'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: AppTokens.space12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 420) {
                              return Column(
                                children: [
                                  _customerNameField(),
                                  const SizedBox(height: AppTokens.space12),
                                  _customerPhoneField(),
                                ],
                              );
                            }
                            return Row(children: [Expanded(child: _customerNameField()), const SizedBox(width: AppTokens.space12), Expanded(child: _customerPhoneField())]);
                          },
                        ),
                        const SizedBox(height: AppTokens.space12),
                        TextFormField(
                          controller: _productController,
                          decoration: const InputDecoration(labelText: 'Acara / Deskripsi Tagihan'),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: AppTokens.space12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 420) {
                              return Column(
                                children: [
                                  Row(children: [Expanded(child: _numberField(_qtyController, 'Unit')), const SizedBox(width: AppTokens.space12), Expanded(child: _numberField(_daysController, 'Hari'))]),
                                  const SizedBox(height: AppTokens.space12),
                                  _priceField(),
                                ],
                              );
                            }
                            return Row(children: [Expanded(child: _numberField(_qtyController, 'Unit')), const SizedBox(width: AppTokens.space12), Expanded(child: _numberField(_daysController, 'Hari')), const SizedBox(width: AppTokens.space12), Expanded(flex: 2, child: _priceField())]);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTokens.white))
                      : const Text('Buat dan Simpan Invoice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerNameField() => TextFormField(
        controller: _customerNameController,
        decoration: InputDecoration(labelText: _isManualReimbursement ? 'Penerima Reimbursement' : 'Nama Klien'),
        validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
      );

  Widget _customerPhoneField() => TextFormField(
        controller: _customerPhoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(labelText: 'No. WhatsApp'),
      );

  Widget _numberField(TextEditingController controller, String label) => TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      );

  Widget _priceField() => TextFormField(
        controller: _unitPriceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Harga Satuan', prefixText: 'Rp '),
      );
}
