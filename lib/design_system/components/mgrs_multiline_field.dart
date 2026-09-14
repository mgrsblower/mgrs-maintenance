import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

class MgrsMultilineField extends StatelessWidget {
  const MgrsMultilineField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.minLines = 3,
    this.maxLines = 5,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final int minLines;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final borderColor = hasError ? MgrsColors.danger : MgrsColors.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        const SizedBox(height: MgrsSpacing.sm),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onChanged: onChanged,
            minLines: minLines,
            maxLines: maxLines,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: hintText,
              helperText: hasError ? null : helperText,
              errorText: errorText,
              alignLabelWithHint: true,
              fillColor: hasError ? MgrsColors.dangerSoft : MgrsColors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.control),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.control),
                borderSide: const BorderSide(
                  color: MgrsColors.operational,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.control),
                borderSide: const BorderSide(color: MgrsColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.control),
                borderSide: const BorderSide(
                  color: MgrsColors.danger,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
