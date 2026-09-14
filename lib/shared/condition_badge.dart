import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_status_badge.dart';

class ConditionBadge extends StatelessWidget {
  const ConditionBadge(this.value, {super.key});
  final String value;
  @override
  Widget build(BuildContext context) => MgrsStatusBadge(
    value,
    tone: value == 'OK'
        ? MgrsStatusTone.success
        : value == 'Rusak Ringan'
        ? MgrsStatusTone.warning
        : MgrsStatusTone.danger,
  );
}
