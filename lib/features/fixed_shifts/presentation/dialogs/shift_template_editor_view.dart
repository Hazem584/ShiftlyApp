import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/manager_design.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_editor_content.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_policy_step.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Widget buildShiftTemplateEditorDialog({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required ShiftTemplate? template,
  required int step,
  required TextEditingController name,
  required TextEditingController description,
  required List<TextEditingController> policies,
  required TimeOfDay start,
  required TimeOfDay end,
  required TimeOfDay? breakAt,
  required String colorValue,
  required String? localError,
  required ShiftTemplateInput input,
  required ValueChanged<int> onStepChanged,
  required void Function(bool) onPickTime,
  required ValueChanged<String> onColorChanged,
  required ValueChanged<TimeOfDay?> onBreakChanged,
  required VoidCallback onPolicyChanged,
  required VoidCallback onSave,
}) => BlocBuilder<ManagerTemplatesCubit, ManagerTemplatesState>(
  builder: (context, state) => ManagerDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    onBack: ManagerDesign.applies(context) && step == 1
        ? () => onStepChanged(0)
        : null,
    title: Text(
      template == null
          ? context.tr(step == 0 ? 'Create template' : 'Template policy')
          : context.tr('Edit template'),
    ),
    content: SizedBox(
      width: 520,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (template != null) ...[
                Text(
                  context.tr(
                    'Changes apply automatically to assigned employees. Shifts already started keep their saved schedule; changes apply from the next day.',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!ManagerDesign.applies(context) || step == 0)
                ...buildTemplateEditorBasicFields(
                  context: context,
                  name: name,
                  description: description,
                  start: start,
                  end: end,
                  colorValue: colorValue,
                  saving: state.saving,
                  input: input,
                  onPickTime: onPickTime,
                  onColorChanged: onColorChanged,
                ),
              if (!ManagerDesign.applies(context) || step == 1)
                ...buildTemplatePolicyStep(
                  context: context,
                  start: start,
                  end: end,
                  breakAt: breakAt,
                  policies: policies,
                  input: input,
                  state: state,
                  onBreakChanged: onBreakChanged,
                  onPolicyChanged: onPolicyChanged,
                ),
              if (localError != null) ...[
                const SizedBox(height: 10),
                Text(
                  context.tr(localError),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: buildTemplateEditorActions(
      context: context,
      state: state,
      step: step,
      onContinue: () => name.text.trim().isEmpty
          ? formKey.currentState!.validate()
          : onStepChanged(1),
      onSave: onSave,
    ),
  ),
);
