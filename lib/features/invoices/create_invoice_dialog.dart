import 'package:flutter/material.dart';
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
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final suffix = orderSuffix ?? '${now.hour}${now.minute}${now.second}';
    _refController.text = 'INV/$y/$m/$d-$suffix';
  }

  Future<void> _loadAvailableOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final orders = await widget.gateway.fetchUpcomingOrders(limit: 50);
      if (!mounted) return;
      setState(() {
        _availableOrders = orders;
        _isLoadingOrders = false;
        if (orders.isNotEmpty) {
          _selectOrder(orders.first);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingOrders = false);
    }
  }

  void _selectOrder(OrderanSewa order) {
    _selectedOrder = order;
    final orderanId = order.orderanId ?? order.id;
    final suffix = orderanId.split('-').last;
    _generateReference(suffix);

    _customerNameController.text = order.namaClient ?? '';
    _customerPhoneController.text = order.nomorWhatsapp ?? '';
    _productController.text =
        order.namaEvent.isNotEmpty ? order.namaEvent : 'Sewa Mistyfan';
    _qtyController.text = order.jumlahUnit.toString();
    _daysController.text =
        order.rentalDays > 0 ? order.rentalDays.toString() : '1';
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final dueStr =
        now.add(const Duration(days: 7)).toIso8601String().substring(0, 10);

    final qty = num.tryParse(_qtyController.text.trim()) ?? 1;
    final days = num.tryParse(_daysController.text.trim()) ?? 1;
    final price = num.tryParse(_unitPriceController.text.trim()) ?? 250000;
    final subtotal = qty * price;
    final total = subtotal * days;

    final payload = <String, Object?>{
      'orderan_id': _isManualReimbursement
          ? null
          : (_selectedOrder?.orderanId ?? _selectedOrder?.id),
      'invoice_reference': _refController.text.trim(),
      'invoice_date': todayStr,
      'due_date': dueStr,
      'product_name': _productController.text.trim().isNotEmpty
          ? _productController.text.trim()
          : 'Sewa Mistyfan',
      'quantity': qty,
      'rental_days': days,
      'unit_price': price,
      'subtotal': subtotal,
      'total_amount': total,
      'paid_amount': 0,
      'payment_status': 'unpaid',
      'invoice_source':
          _isManualReimbursement ? 'manual_reimbursement' : 'order',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invoice ${created.invoiceReference} berhasil dibuat.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat invoice: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Buat Invoice Baru',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Segmented Type: Dari Order vs Manual
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isManualReimbursement = false;
                            if (_selectedOrder != null) {
                              _selectOrder(_selectedOrder!);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isManualReimbursement
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isManualReimbursement
                                ? const [
                                    BoxShadow(
                                      color: Color(0x0A0F172A),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Dari Order Sewa',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: !_isManualReimbursement
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: !_isManualReimbursement
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isManualReimbursement = true;
                            _selectedOrder = null;
                            _generateReference();
                            _customerNameController.clear();
                            _customerPhoneController.clear();
                            _productController.text = 'Reimbursement Operasional';
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isManualReimbursement
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isManualReimbursement
                                ? const [
                                    BoxShadow(
                                      color: Color(0x0A0F172A),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Manual Reimbursement',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: _isManualReimbursement
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _isManualReimbursement
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isManualReimbursement) ...[
                          const Text(
                            'Pilih Orderan Terjadwal:',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (_isLoadingOrders)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else if (_availableOrders.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Belum ada data orderan terjadwal.',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<OrderanSewa>(
                              key: ValueKey<String>(_selectedOrder?.id ?? 'none'),
                              initialValue: _selectedOrder,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              items: _availableOrders.map((ord) {
                                return DropdownMenuItem(
                                  value: ord,
                                  child: Text(
                                    '${ord.orderanId ?? ord.id} • ${ord.namaClient}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (ord) {
                                if (ord != null) _selectOrder(ord);
                              },
                            ),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _refController,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'No. Referensi Invoice',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _customerNameController,
                                style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: _isManualReimbursement
                                      ? 'Penerima Reimbursement'
                                      : 'Nama Klien',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _customerPhoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'No. WhatsApp',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _productController,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Acara / Deskripsi Tagihan',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _daysController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Hari',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _unitPriceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Harga Satuan',
                                  prefixText: 'Rp ',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Buat dan Simpan Invoice',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
