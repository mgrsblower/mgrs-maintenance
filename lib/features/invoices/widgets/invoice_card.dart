import 'package:flutter/material.dart';

import '../../../design_system/components/mgrs_status_badge.dart';
import '../../../design_system/mgrs_tokens.dart';
import '../invoice_model.dart';

class InvoiceCard extends StatelessWidget {
  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onPayment,
    required this.onOpen,
    required this.onDelete,
  });

  final InvoiceRecord invoice;
  final VoidCallback onPayment;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  MgrsStatusTone get _tone => switch (invoice.paymentStatus) {
    InvoicePaymentStatus.paid => MgrsStatusTone.success,
    InvoicePaymentStatus.partial => MgrsStatusTone.warning,
    InvoicePaymentStatus.unpaid ||
    InvoicePaymentStatus.cancelled => MgrsStatusTone.danger,
  };

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: MgrsColors.surface,
      borderRadius: BorderRadius.circular(MgrsRadii.card),
      border: Border.all(color: MgrsColors.line),
    ),
    child: Padding(
      padding: const EdgeInsets.all(MgrsSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  invoice.invoiceReference,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MgrsColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: MgrsSpacing.sm),
              Flexible(
                child: MgrsStatusBadge(
                  invoice.paymentStatusDisplay,
                  tone: _tone,
                ),
              ),
            ],
          ),
          const SizedBox(height: MgrsSpacing.md),
          Text(
            invoice.customerName.isEmpty ? 'Klien MGRS' : invoice.customerName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: MgrsColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MgrsSpacing.xs),
          Text(
            '${invoice.productName} · ${invoice.quantity} unit · ${invoice.rentalDays} hari',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
          ),
          const SizedBox(height: MgrsSpacing.base),
          const Divider(height: 1, color: MgrsColors.line),
          const SizedBox(height: MgrsSpacing.md),
          Wrap(
            spacing: MgrsSpacing.xl,
            runSpacing: MgrsSpacing.sm,
            children: [
              _Amount(label: 'Total', value: invoice.totalAmountFormatted),
              _Amount(
                label: invoice.remainingAmount > 0 ? 'Sisa' : 'Pembayaran',
                value: invoice.remainingAmount > 0
                    ? invoice.remainingAmountFormatted
                    : 'Lunas',
                emphasized: invoice.remainingAmount > 0,
              ),
            ],
          ),
          const SizedBox(height: MgrsSpacing.md),
          Text(
            '${invoice.formattedInvoiceDate}${invoice.orderanId?.isNotEmpty == true ? ' · #${invoice.orderanId}' : ''}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
          ),
          const SizedBox(height: MgrsSpacing.base),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack =
                  constraints.maxWidth < 360 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21;
              final payment = OutlinedButton(
                key: Key('btn-quick-payment-${invoice.id}'),
                onPressed: onPayment,
                child: const Text('Atur Bayar'),
              );
              final open = FilledButton(
                key: Key('btn-open-builder-${invoice.id}'),
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: MgrsColors.ink,
                  foregroundColor: MgrsColors.surface,
                ),
                child: const Text('Buka Invoice'),
              );
              final delete = IconButton.outlined(
                key: Key('btn-delete-invoice-${invoice.id}'),
                onPressed: onDelete,
                tooltip: 'Hapus invoice',
                constraints: const BoxConstraints.tightFor(
                  width: MgrsSizes.minTouch,
                  height: MgrsSizes.minTouch,
                ),
                icon: const Icon(
                  Icons.delete_outline,
                  color: MgrsColors.danger,
                ),
              );
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: MgrsSizes.minTouch,
                      ),
                      child: payment,
                    ),
                    const SizedBox(height: MgrsSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: MgrsSizes.minTouch,
                      ),
                      child: open,
                    ),
                    const SizedBox(height: MgrsSpacing.sm),
                    Align(alignment: Alignment.centerRight, child: delete),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: payment),
                  const SizedBox(width: MgrsSpacing.sm),
                  Expanded(child: open),
                  const SizedBox(width: MgrsSpacing.sm),
                  delete,
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
      ),
      const SizedBox(height: MgrsSpacing.xs),
      Text(
        value,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: emphasized ? MgrsColors.danger : MgrsColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
