import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/manager_design.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_color_picker.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/template_work_location_picker.dart';

List<Widget> buildTemplateEditorBasicFields({
  required BuildContext context,
  required TextEditingController name,
  required TextEditingController description,
  required TimeOfDay start,
  required TimeOfDay end,
  required String colorValue,
  required String? workLocationId,
  required bool saving,
  required ShiftTemplateInput input,
  required void Function(bool) onPickTime,
  required ValueChanged<String> onColorChanged,
  required ValueChanged<String?> onWorkLocationChanged,
}) => [
  TextFormField(
    controller: name,
    maxLength: 100,
    decoration: InputDecoration(labelText: context.tr('Template name')),
    validator: (_) =>
        input.validate()?.contains('name') == true ? input.validate() : null,
  ),
  const SizedBox(height: 10),
  TextFormField(
    controller: description,
    maxLength: 1000,
    maxLines: 2,
    decoration: InputDecoration(
      labelText: context.tr('Description (optional)'),
    ),
  ),
  const SizedBox(height: 12),
  TemplateWorkLocationPicker(
    selectedId: workLocationId,
    enabled: !saving,
    onChanged: onWorkLocationChanged,
  ),
  buildTemplateTimeButtons(
    context: context,
    start: start,
    end: end,
    saving: saving,
    onPickTime: onPickTime,
  ),
  const SizedBox(height: 12),
  buildTemplateColorPicker(
    context: context,
    colorValue: colorValue,
    saving: saving,
    onColorChanged: onColorChanged,
  ),
  const SizedBox(height: 12),
];

List<Widget> buildTemplateEditorActions({
  required BuildContext context,
  required ManagerTemplatesState state,
  required int step,
  required VoidCallback onContinue,
  required VoidCallback onSave,
}) {
  final isStep0 = ManagerDesign.applies(context) && step == 0;
  return [
    TextButton(
      onPressed: state.saving ? null : () => Navigator.pop(context),
      child: Text(context.tr('Cancel')),
    ),
    FilledButton(
      key: const Key('save-shift-template'),
      onPressed: state.saving ? null : (isStep0 ? onContinue : onSave),
      child: state.saving
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(context.tr(isStep0 ? 'Continue to policy' : 'Save template')),
    ),
  ];
}
