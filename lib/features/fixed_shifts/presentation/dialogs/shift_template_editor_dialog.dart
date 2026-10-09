import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/core/utils/clock_time_picker.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
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
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final List<TextEditingController> _policies;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late String _colorValue;
  String? _localError;
  static const _colors = [
    '#2563EB',
    '#0F766E',
    '#7C3AED',
    '#C2410C',
    '#BE123C',
    '#334155',
  ];

  @override
  void initState() {
    super.initState();
    final value = widget.template;
    _name = TextEditingController(text: value?.name);
    _description = TextEditingController(text: value?.description);
    _start = shiftTemplatesScreenTod(value?.startMinute ?? 540);
    _end = shiftTemplatesScreenTod(value?.endMinute ?? 1020);
    _colorValue = value?.color ?? _colors.first;
    _policies = [
      TextEditingController(text: '${value?.graceMinutes ?? 10}'),
      TextEditingController(text: '${value?.allowedEarlyCheckInMinutes ?? 30}'),
      TextEditingController(text: '${value?.allowedLateCheckInMinutes ?? 120}'),
      TextEditingController(text: '${value?.minimumWorkMinutes ?? 0}'),
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    for (final controller in _policies) {
      controller.dispose();
    }
    super.dispose();
  }

  ShiftTemplateInput get _input => ShiftTemplateInput(
    name: _name.text,
    description: _description.text,
    color: _colorValue,
    startMinute: _start.hour * 60 + _start.minute,
    endMinute: _end.hour * 60 + _end.minute,
    graceMinutes: int.tryParse(_policies[0].text) ?? -1,
    allowedEarlyCheckInMinutes: int.tryParse(_policies[1].text) ?? -1,
    allowedLateCheckInMinutes: int.tryParse(_policies[2].text) ?? -1,
    minimumWorkMinutes: int.tryParse(_policies[3].text) ?? -1,
  );

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ManagerTemplatesCubit, ManagerTemplatesState>(
    builder: (context, state) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(
        widget.template == null ? 'Create fixed shift' : 'Edit fixed shift',
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Template name'),
                  validator: (_) => _input.validate()?.contains('name') == true
                      ? _input.validate()
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _description,
                  maxLength: 1000,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: state.saving ? null : () => _pick(true),
                      icon: const Icon(Icons.login_rounded),
                      label: Text(
                        'Start ${ClockTime.format(_start.hour, _start.minute, locale: Localizations.localeOf(context).toString())}',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: state.saving ? null : () => _pick(false),
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(
                        'End ${ClockTime.format(_end.hour, _end.minute, locale: Localizations.localeOf(context).toString())}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: 'Template color',
                  child: Wrap(
                    spacing: 10,
                    children: [
                      if (!_colors.contains(_colorValue))
                        ChoiceChip(
                          label: Text(_colorValue),
                          avatar: CircleAvatar(
                            backgroundColor: shiftTemplatesScreenColor(
                              _colorValue,
                            ),
                          ),
                          selected: true,
                          onSelected: null,
                        ),
                      for (final value in _colors)
                        ChoiceChip(
                          label: const SizedBox.square(dimension: 20),
                          avatar: CircleAvatar(
                            backgroundColor: shiftTemplatesScreenColor(value),
                          ),
                          selected: _colorValue == value,
                          onSelected: state.saving
                              ? null
                              : (_) => setState(() => _colorValue = value),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 440
                        ? (constraints.maxWidth - 10) / 2
                        : constraints.maxWidth;
                    final labels = [
                      'Grace minutes',
                      'Early check-in minutes',
                      'Late check-in minutes',
                      'Minimum work minutes',
                    ];
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < 4; i++)
                          SizedBox(
                            width: width,
                            child: TextFormField(
                              controller: _policies[i],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: labels[i]),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final number = int.tryParse(value ?? '');
                                return number == null ||
                                        number < 0 ||
                                        number > 1440
                                    ? 'Use 0 to 1440'
                                    : null;
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${ClockTime.format(_start.hour, _start.minute, locale: Localizations.localeOf(context).toString())} – ${ClockTime.format(_end.hour, _end.minute, locale: Localizations.localeOf(context).toString())} • ${shiftTemplatesScreenDuration(_input.durationMinutes)} • ${_input.durationMinutes == 1440
                        ? '24-hour'
                        : _input.endMinute <= _input.startMinute
                        ? 'Overnight'
                        : 'Same day'}',
                  ),
                ),
                if (state.failure != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    shiftTemplatesScreenSupportMessage(
                      state.failure!.message,
                      state.failure!.requestId,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_localError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _localError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-shift-template'),
          onPressed: state.saving ? null : _save,
          child: state.saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save template'),
        ),
      ],
    ),
  );

  Future<void> _pick(bool start) async {
    final value = await ClockTimePicker.show(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value != null) {
      setState(() => start ? _start = value : _end = value);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final validation = _input.validate();
    if (validation != null) {
      setState(() => _localError = validation);
      return;
    }
    setState(() => _localError = null);
    final result = await context.read<ManagerTemplatesCubit>().save(
      _input,
      templateId: widget.template?.id,
    );
    if (mounted && result == FixedShiftMutationResult.success) {
      Navigator.pop(context);
    }
  }
}
