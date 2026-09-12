import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

class InvoiceAdjustmentEditor extends StatelessWidget {
  const InvoiceAdjustmentEditor({
    required this.index,
    required this.descriptionController,
    required this.amountController,
    required this.readOnly,
    required this.onChanged,
    required this.onRemove,
    this.canRemove = true,
    super.key,
  });

  final int index;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final bool readOnly;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final operational = theme.extension<OperationalColors>();
    final removeButton = IconButton(
      key: Key('invoice-adjustment-remove-$index'),
      onPressed: readOnly || !canRemove ? null : onRemove,
      tooltip: 'Hapus penyesuaian',
      icon: Icon(
        Icons.remove_circle_outline_rounded,
        color: operational?.onDanger ?? theme.colorScheme.error,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 450;
        if (compact) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  key: Key('invoice-adjustment-description-$index'),
                  controller: descriptionController,
                  readOnly: readOnly,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Penyesuaian',
                    hintText: 'Misal: Diskon, Tambahan Kabel, Transport',
                  ),
                  onChanged: (_) => onChanged(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        key: Key('invoice-adjustment-amount-$index'),
                        controller: amountController,
                        readOnly: readOnly,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nominal (+ / -)',
                          prefixText: 'Rp ',
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    removeButton,
                  ],
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: Key('invoice-adjustment-description-$index'),
                  controller: descriptionController,
                  readOnly: readOnly,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Misal: Diskon, Transport',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: Key('invoice-adjustment-amount-$index'),
                  controller: amountController,
                  readOnly: readOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nominal (+ / -)',
                    prefixText: 'Rp ',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              removeButton,
            ],
          ),
        );
      },
    );
  }
}
