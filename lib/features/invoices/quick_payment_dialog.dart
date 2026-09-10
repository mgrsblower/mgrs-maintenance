import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
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
          backgroundColor: Color(0xFF9F2F2D),
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
            'Status pembayaran ${widget.invoice.invoiceReference} tersimpan.',
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
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: const Color(0xFF9F2F2D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _currentRemainingAmount;
    final isLunas = remaining == 0 && _currentPaidAmount > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Atur Pembayaran',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.invoice.invoiceReference} • ${widget.invoice.customerName.isNotEmpty ? widget.invoice.customerName : "Klien MGRS"}',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            color: Color(0xFF71717A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: Color(0xFF71717A)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF4F4F5)),
              const SizedBox(height: 12),
              // Clean Typographic Balances
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Tagihan',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  Text(
                    widget.invoice.totalAmountFormatted,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isLunas ? 'Status Pembayaran' : 'Sisa Tagihan',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: isLunas
                          ? const Color(0xFF346538)
                          : const Color(0xFF9F2F2D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isLunas
                        ? 'Lunas'
                        : InvoiceRecord.formatRupiah(remaining),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isLunas
                          ? const Color(0xFF346538)
                          : const Color(0xFF9F2F2D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'PILIH STATUS',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA1A1AA),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              // Minimalist 3-tab segmented selector (Belum Bayar, Sebagian, Lunas)
              Container(
                height: 34,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE4E4E7)),
                ),
                child: Row(
                  children: [
                    _buildSegmentTab(
                      label: 'Belum Bayar',
                      status: InvoicePaymentStatus.unpaid,
                    ),
                    _buildSegmentTab(
                      label: 'Sebagian (DP)',
                      status: InvoicePaymentStatus.partial,
                    ),
                    _buildSegmentTab(
                      label: 'Lunas',
                      status: InvoicePaymentStatus.paid,
                    ),
                  ],
                ),
              ),
              // Input for partial / DP
              if (_status == InvoicePaymentStatus.partial) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Nominal DP / Terbayar',
                    labelStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: Color(0xFF71717A),
                    ),
                    prefixText: 'Rp ',
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 38,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
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
                            fontSize: 12.5,
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

  Widget _buildSegmentTab({
    required String label,
    required InvoicePaymentStatus status,
  }) {
    final isSelected = _status == status;
    return Expanded(
      child: PressableScale(
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
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF71717A),
            ),
          ),
        ),
      ),
    );
  }
}
