import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import 'invoice_model.dart';

class QuickPaymentDialog extends StatefulWidget {
  const QuickPaymentDialog({
    super.key,
    required this.invoice,
    required this.gateway,
    required this.onPaymentUpdated,
  });

  final InvoiceRecord invoice;
  final MaintenanceGateway gateway;
  final ValueChanged<InvoiceRecord> onPaymentUpdated;

  @override
  State<QuickPaymentDialog> createState() => _QuickPaymentDialogState();
}

class _QuickPaymentDialogState extends State<QuickPaymentDialog> {
  late InvoicePaymentStatus _status;
  late final TextEditingController _paidController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.invoice.paymentStatus;
    _paidController = TextEditingController(
      text: widget.invoice.paidAmount > 0
          ? widget.invoice.paidAmount.toInt().toString()
          : '',
    );
    _paidController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  num get _currentPaidAmount {
    switch (_status) {
      case InvoicePaymentStatus.unpaid:
        return 0;
      case InvoicePaymentStatus.paid:
        return widget.invoice.totalAmount;
      case InvoicePaymentStatus.partial:
        return num.tryParse(_paidController.text.trim()) ?? 0;
    }
  }

  num get _currentRemainingAmount {
    final rem = widget.invoice.totalAmount - _currentPaidAmount;
    return rem > 0 ? rem : 0;
  }

  Future<void> _submit() async {
    final paid = _currentPaidAmount;
    if (_status == InvoicePaymentStatus.partial && paid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal DP / sebagian harus lebih dari 0.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await widget.gateway.updateInvoicePayment(
        widget.invoice.id,
        _status,
        paid,
      );
      if (!mounted) return;
      widget.onPaymentUpdated(updated);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pembayaran ${widget.invoice.invoiceReference} berhasil diperbarui.',
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
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Atur Pembayaran',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.invoice.invoiceReference,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Summary box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Tagihan',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.invoice.totalAmountFormatted,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Sisa Pembayaran',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          InvoiceRecord.formatRupiah(_currentRemainingAmount),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _currentRemainingAmount > 0
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Status Pembayaran:',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              // Status selector cards
              ...InvoicePaymentStatus.values.map((status) {
                final isSelected = _status == status;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _status = status;
                        if (status == InvoicePaymentStatus.paid) {
                          _paidController.text =
                              widget.invoice.totalAmount.toInt().toString();
                        } else if (status == InvoicePaymentStatus.unpaid) {
                          _paidController.text = '0';
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEFF6FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            size: 18,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_status == InvoicePaymentStatus.partial) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nominal Terbayar (DP)',
                    prefixText: 'Rp ',
                    hintText: 'Misal: 1000000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Status Pembayaran',
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
