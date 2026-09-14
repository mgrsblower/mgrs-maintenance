import 'package:flutter/material.dart';

import '../../../design_system/components/mgrs_search_field.dart';
import '../../../design_system/mgrs_tokens.dart';
import '../invoice_model.dart';

enum InvoiceSourceFilter { automatic, manual }

class InvoiceListShell extends StatelessWidget {
  const InvoiceListShell({
    super.key,
    required this.sourceFilter,
    required this.paymentFilter,
    required this.searchController,
    required this.onSourceChanged,
    required this.onPaymentChanged,
    required this.onSearchChanged,
    required this.onCreate,
    required this.body,
    this.title = 'Daftar Invoice',
  });

  final InvoiceSourceFilter sourceFilter;
  final InvoicePaymentStatus? paymentFilter;
  final TextEditingController searchController;
  final ValueChanged<InvoiceSourceFilter> onSourceChanged;
  final ValueChanged<InvoicePaymentStatus?> onPaymentChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;
  final Widget body;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MgrsColors.canvas,
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: MgrsSizes.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        MgrsSpacing.lg,
                        MgrsSpacing.base,
                        MgrsSpacing.lg,
                        MgrsSpacing.md,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact =
                              constraints.maxWidth < 360 ||
                              MediaQuery.textScalerOf(context).scale(16) > 24;
                          final heading = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: MgrsColors.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: MgrsSpacing.xs),
                                Text(
                                  'Daftar Invoice & Tagihan',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: MgrsColors.muted),
                                ),
                              ],
                            ],
                          );
                          final create = FilledButton.icon(
                            key: const Key('invoice-create-action'),
                            icon: const Icon(Icons.add),
                            onPressed: onCreate,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(
                                MgrsSizes.minTouch,
                                MgrsSizes.minTouch,
                              ),
                              backgroundColor: MgrsColors.ink,
                              foregroundColor: MgrsColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  MgrsRadii.pill,
                                ),
                              ),
                            ),
                            label: const Text('Buat Invoice'),
                          );
                          if (compact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                heading,
                                const SizedBox(height: MgrsSpacing.md),
                                create,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: heading),
                              const SizedBox(width: MgrsSpacing.md),
                              create,
                            ],
                          );
                        },
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: MgrsSpacing.lg,
                      ),
                      child: _InvoiceChoiceBar<InvoiceSourceFilter>(
                        options: const [
                          (InvoiceSourceFilter.automatic, 'Order Sewa'),
                          (InvoiceSourceFilter.manual, 'Reimbursement'),
                        ],
                        selected: sourceFilter,
                        onSelected: onSourceChanged,
                      ),
                    ),
                    const SizedBox(height: MgrsSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MgrsSpacing.lg,
                      ),
                      child: MgrsSearchField(
                        key: const Key('invoice-search-field'),
                        controller: searchController,
                        hintText: 'Cari invoice, order, atau klien',
                        onChanged: onSearchChanged,
                      ),
                    ),
                    const SizedBox(height: MgrsSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: MgrsSpacing.lg,
                      ),
                      child: _InvoiceChoiceBar<InvoicePaymentStatus?>(
                        options: const [
                          (null, 'Semua'),
                          (InvoicePaymentStatus.unpaid, 'Belum Bayar'),
                          (InvoicePaymentStatus.partial, 'Sebagian'),
                          (InvoicePaymentStatus.paid, 'Lunas'),
                        ],
                        selected: paymentFilter,
                        onSelected: onPaymentChanged,
                      ),
                    ),
                    const SizedBox(height: MgrsSpacing.md),
                    const Divider(height: 1, color: MgrsColors.line),
                    Expanded(child: body),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InvoiceChoiceBar<T> extends StatelessWidget {
  const _InvoiceChoiceBar({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: MgrsSpacing.sm,
    runSpacing: MgrsSpacing.sm,
    children: options
        .map((option) {
          final active = option.$1 == selected;
          return ChoiceChip(
            label: Text(option.$2),
            selected: active,
            onSelected: (_) => onSelected(option.$1),
            showCheckmark: false,
            labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: active ? MgrsColors.surface : MgrsColors.ink,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: MgrsColors.ink,
            backgroundColor: MgrsColors.surface,
            side: const BorderSide(color: MgrsColors.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MgrsRadii.pill),
            ),
          );
        })
        .toList(growable: false),
  );
}
