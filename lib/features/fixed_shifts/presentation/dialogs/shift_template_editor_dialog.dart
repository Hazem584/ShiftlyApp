import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/utils/clock_time_picker.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_color_picker.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_editor_view.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_policy_fields.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';

class ShiftTemplateEditorDialog extends StatefulWidget {
  const ShiftTemplateEditorDialog({super.key, this.template});
  final ShiftTemplate? template;
  @override
  State<ShiftTemplateEditorDialog> createState() =>
      _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<ShiftTemplateEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.template?.name);
  late final _description = TextEditingController(
    text: widget.template?.description,
  );
  late final _policies = createTemplatePolicyControllers(widget.template);
  late TimeOfDay _start = shiftTemplatesScreenTod(
    widget.template?.startMinute ?? 540,
  );
  late TimeOfDay _end = shiftTemplatesScreenTod(
    widget.template?.endMinute ?? 1020,
  );
  late TimeOfDay? _breakAt = widget.template?.breakStartMinute == null
      ? null
      : shiftTemplatesScreenTod(widget.template!.breakStartMinute!);
  late String _colorValue =
      widget.template?.color ?? templatePresetColors.first;
  String? _localError;
  int _step = 0;

  @override
  void dispose() {
    for (final c in [_name, _description, ..._policies]) {
      c.dispose();
    }
    super.dispose();
  }

  ShiftTemplateInput get _input => buildShiftTemplateInput(
    name: _name,
    description: _description,
    policies: _policies,
    start: _start,
    end: _end,
    breakAt: _breakAt,
    colorValue: _colorValue,
  );

  @override
  Widget build(BuildContext context) => buildShiftTemplateEditorDialog(
    context: context,
    formKey: _formKey,
    template: widget.template,
    step: _step,
    name: _name,
    description: _description,
    policies: _policies,
    start: _start,
    end: _end,
    breakAt: _breakAt,
    colorValue: _colorValue,
    localError: _localError,
    input: _input,
    onStepChanged: (v) => setState(() => _step = v),
    onPickTime: _pick,
    onColorChanged: (v) => setState(() => _colorValue = v),
    onBreakChanged: (v) {
      if (mounted) setState(() => _breakAt = v);
    },
    onPolicyChanged: () => setState(() {}),
    onSave: _save,
  );

  Future<void> _pick(bool start) async {
    final value = await ClockTimePicker.show(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value != null) setState(() => start ? _start = value : _end = value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final validation = _input.validate();
    if (validation != null) return setState(() => _localError = validation);
    setState(() => _localError = null);
    final res = await context.read<ManagerTemplatesCubit>().save(
      _input,
      templateId: widget.template?.id,
    );
    if (mounted && res == FixedShiftMutationResult.success) {
      Navigator.pop(context);
    }
  }
}
