import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/active_template_selector.dart';

const extraShiftReasons = [
  'COVERED_EMPLOYEE',
  'ADDITIONAL_SHIFT',
  'APPROVED_OVERTIME',
  'EMERGENCY_SUPPORT',
  'HIGH_WORKLOAD_SUPPORT',
  'OTHER',
];

Widget buildExtraTemplateField({
  required BuildContext context,
  required List<ShiftTemplate>? templates,
  required String? templateId,
  required bool busy,
  required VoidCallback onLoadTemplates,
  required ValueChanged<String?> onTemplateChanged,
}) {
  if (templates == null) {
    return TextButton(
      onPressed: busy ? null : onLoadTemplates,
      child: Text(context.tr('Load / retry templates')),
    );
  }
  if (templates.isEmpty) {
    return Text(
      context.tr('No active templates. Create one before assigning extras.'),
    );
  }
  return ActiveTemplateSelector(
    templates: templates,
    value: templateId,
    onChanged: busy ? null : onTemplateChanged,
  );
}

List<Widget> buildExtraShiftActualFields({
  required BuildContext context,
  required TextEditingController actualIn,
  required TextEditingController actualOut,
  required bool busy,
}) => [
  Text(
    context.tr(
      'Enter local dates/times with the offset applicable at each instant. During a repeated DST hour, choose the intended offset explicitly. Missing DST times are invalid.',
    ),
  ),
  TextField(
    controller: actualIn,
    enabled: !busy,
    decoration: InputDecoration(
      labelText: context.tr('Actual clock-in with offset'),
      hintText: '2026-10-09T08:00:00+03:00',
    ),
  ),
  TextField(
    controller: actualOut,
    enabled: !busy,
    decoration: InputDecoration(
      labelText: context.tr('Actual clock-out with offset'),
      hintText: '2026-10-09T16:00:00+03:00',
    ),
  ),
  Text(
    context.tr(
      'Extra attendance records the authorized shift and its actual working time.',
    ),
  ),
];
