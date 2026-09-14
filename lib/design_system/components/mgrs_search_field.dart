import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

class MgrsSearchField extends StatelessWidget {
  const MgrsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Cari data',
    this.onClear,
    this.focusNode,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final bool enabled;

  void _clear() {
    controller.clear();
    onChanged('');
    onClear?.call();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => SizedBox(
          height: MgrsSizes.minTouch,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: EdgeInsets.zero,
              prefixIcon: const Icon(Icons.search, semanticLabel: 'Pencarian'),
              prefixIconConstraints: const BoxConstraints.tightFor(
                width: MgrsSizes.minTouch,
                height: MgrsSizes.minTouch,
              ),
              suffixIcon: enabled && value.text.isNotEmpty
                  ? Semantics(
                      label: 'Hapus pencarian',
                      button: true,
                      excludeSemantics: true,
                      onTap: _clear,
                      child: IconButton(
                        tooltip: 'Hapus pencarian',
                        constraints: const BoxConstraints.tightFor(
                          width: MgrsSizes.minTouch,
                          height: MgrsSizes.minTouch,
                        ),
                        onPressed: _clear,
                        icon: const Icon(Icons.close),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints.tightFor(
                width: MgrsSizes.minTouch,
                height: MgrsSizes.minTouch,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.pill),
                borderSide: const BorderSide(color: MgrsColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.pill),
                borderSide: const BorderSide(color: MgrsColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.pill),
                borderSide: const BorderSide(
                  color: MgrsColors.operational,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      );
}
