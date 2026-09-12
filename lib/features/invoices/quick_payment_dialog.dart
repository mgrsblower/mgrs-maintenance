import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
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
      case InvoicePaymentStatus.cancelled:
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>();
    final paidTone = operational?.onSuccess ?? colors.primary;
    final errorTone = operational?.onDanger ?? colors.onErrorContainer;
    final paidSurface = operational?.success ?? colors.surfaceContainer;
    final errorSurface = operational?.danger ?? colors.errorContainer;
    final paid = _currentPaidAmount;
    if (_status == InvoicePaymentStatus.partial && paid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominal DP / sebagian harus lebih dari 0.',
            style: theme.textTheme.bodyMedium?.copyWith(color: errorTone),
          ),
          backgroundColor: errorSurface,
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: paidTone,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: paidSurface,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui status: $e',
            style: theme.textTheme.bodyMedium?.copyWith(color: errorTone),
          ),
          backgroundColor: errorSurface,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>();
    final remaining = _currentRemainingAmount;
    final isLunas = remaining == 0 && _currentPaidAmount > 0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space16,
        vertical: AppTokens.space24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atur Pembayaran',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          '${widget.invoice.invoiceReference} • ${widget.invoice.customerName.isNotEmpty ? widget.invoice.customerName : "Klien MGRS"}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              const Divider(),
              const SizedBox(height: AppTokens.space12),
              _summaryRow(
                context,
                'Total Tagihan',
                widget.invoice.totalAmountFormatted,
              ),
              const SizedBox(height: AppTokens.space8),
              _summaryRow(
                context,
                isLunas ? 'Status Pembayaran' : 'Sisa Tagihan',
                isLunas ? 'Lunas' : InvoiceRecord.formatRupiah(remaining),
                valueColor: isLunas
                    ? operational?.onSuccess ?? colors.primary
                    : operational?.onDanger ?? colors.error,
              ),
              const SizedBox(height: AppTokens.space24),
              Text('PILIH STATUS', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppTokens.space8),
              Container(
                height: 48,
                padding: const EdgeInsets.all(AppTokens.space4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
                  border: Border.all(color: colors.outlineVariant),
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
              if (_status == InvoicePaymentStatus.partial) ...[
                const SizedBox(height: AppTokens.space12),
                TextFormField(
                  controller: _paidController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nominal DP / Terbayar',
                    prefixText: 'Rp ',
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.space24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTokens.white,
                          ),
                        )
                      : const Text('Simpan Status Pembayaran'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(color: valueColor),
        ),
      ],
    );
  }

  Widget _buildSegmentTab({
    required String label,
    required InvoicePaymentStatus status,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = theme.extension<OperationalColors>();
    final isSelected = _status == status;
    final selectedBackground = switch (status) {
      InvoicePaymentStatus.paid =>
        operational?.success ?? colors.surfaceContainerHighest,
      InvoicePaymentStatus.partial =>
        operational?.warning ?? colors.surfaceContainerHighest,
      _ => colors.surfaceContainerHighest,
    };
    final selectedForeground = switch (status) {
      InvoicePaymentStatus.paid => operational?.onSuccess ?? colors.onSurface,
      InvoicePaymentStatus.partial =>
        operational?.onWarning ?? colors.onSurface,
      _ => colors.onSurface,
    };
    return Expanded(
      child: PressableScale(
        onTap: () {
          setState(() {
            _status = status;
            if (status == InvoicePaymentStatus.paid) {
              _paidController.text = widget.invoice.totalAmount
                  .toInt()
                  .toString();
            } else if (status == InvoicePaymentStatus.unpaid) {
              _paidController.text = '0';
            }
          });
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppTokens.minTouchTarget,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? selectedForeground : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
