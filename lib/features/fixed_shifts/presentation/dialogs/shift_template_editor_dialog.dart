import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/manager_design.dart';
import 'package:shiftly/core/utils/clock_time.dart';
import 'package:shiftly/core/utils/clock_time_picker.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

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
  TimeOfDay? _breakAt;
  late TimeOfDay _end;
  late String _colorValue;
  String? _localError;
  int _step = 0;
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
    _breakAt = value?.breakStartMinute == null
        ? null
        : shiftTemplatesScreenTod(value!.breakStartMinute!);
    _colorValue = value?.color ?? _colors.first;
    _policies = [
      TextEditingController(text: (value?.graceMinutes ?? 10).toString()),
      TextEditingController(
        text: (value?.allowedEarlyCheckInMinutes ?? 30).toString(),
      ),
      TextEditingController(
        text: (value?.allowedLateCheckInMinutes ?? 120).toString(),
      ),
      TextEditingController(text: (value?.minimumWorkMinutes ?? 0).toString()),
      TextEditingController(text: (value?.breakMinutes ?? 60).toString()),
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
    breakMinutes: int.tryParse(_policies[4].text) ?? -1,
    breakStartMinute: _breakAt == null
        ? null
        : _breakAt!.hour * 60 + _breakAt!.minute,
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
    builder: (context, state) => ManagerDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      onBack: ManagerDesign.applies(context) && _step == 1
          ? () => setState(() => _step = 0)
          : null,
      title: Text(
        widget.template == null
            ? context.tr(_step == 0 ? 'Create template' : 'Template policy')
            : context.tr('Edit template'),
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.template != null) ...[
                  Text(
                    context.tr(
                      'Changes apply automatically to assigned employees. Shifts already started keep their saved schedule; changes apply from the next day.',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!ManagerDesign.applies(context) || _step == 0) ...[
                  TextFormField(
                    controller: _name,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: context.tr('Template name'),
                    ),
                    validator: (_) =>
                        _input.validate()?.contains('name') == true
                        ? _input.validate()
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _description,
                    maxLength: 1000,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: context.tr('Description (optional)'),
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
                          context.tr('Start {value1}', {
                            'value1': (ClockTime.format(
                              _start.hour,
                              _start.minute,
                              locale: Localizations.localeOf(context)
                                  .toString(),
                            )).toString(),
                          }),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: state.saving ? null : () => _pick(false),
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(
                          context.tr('End {value1}', {
                            'value1': (ClockTime.format(
                              _end.hour,
                              _end.minute,
                              locale: Localizations.localeOf(context)
                                  .toString(),
                            )).toString(),
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: context.tr('Template color'),
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
                ],
                if (!ManagerDesign.applies(context) || _step == 1) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('Break reminder time')),
                    subtitle: Text(
                      _breakAt?.format(context) ?? context.tr('Not set'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: state.saving
                          ? null
                          : () => setState(() => _breakAt = null),
                    ),
                    onTap: state.saving
                        ? null
                        : () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime:
                                  _breakAt ??
                                  const TimeOfDay(hour: 14, minute: 0),
                            );
                            if (time != null && mounted) {
                              setState(() => _breakAt = time);
                            }
                          },
                  ),
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
                        'Break minutes',
                      ];
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < 5; i++)
                            SizedBox(
                              width: width,
                              child: TextFormField(
                                controller: _policies[i],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: context.tr(labels[i]),
                                ),
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  final number = int.tryParse(value ?? '');
                                  return number == null ||
                                          number < 0 ||
                                          number > 1440
                                      ? context.tr('Use 0 to 1440')
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
                      context.tr('{value1} – {value2} • {value3} • {value4}', {
                        'value1': (ClockTime.format(
                          _start.hour,
                          _start.minute,
                          locale: Localizations.localeOf(context).toString(),
                        )).toString(),
                        'value2': (ClockTime.format(
                          _end.hour,
                          _end.minute,
                          locale: Localizations.localeOf(context).toString(),
                        )).toString(),
                        'value3': (shiftTemplatesScreenDuration(
                          _input.durationMinutes,
                          context,
                        )).toString(),
                        'value4': context.tr(
                          _input.durationMinutes == 1440
                              ? '24-hour'
                              : _input.endMinute <= _input.startMinute
                              ? 'Overnight'
                              : 'Same day',
                        ),
                      }),
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
                ],
                if (_localError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    context.tr(_localError!),
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
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('save-shift-template'),
          onPressed: state.saving
              ? null
              : ManagerDesign.applies(context) && _step == 0
              ? () {
                  if (_name.text.trim().isEmpty) {
                    _formKey.currentState!.validate();
                    return;
                  }
                  setState(() => _step = 1);
                }
              : _save,
          child: state.saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  context.tr(
                    ManagerDesign.applies(context) && _step == 0
                        ? 'Continue to policy'
                        : 'Save template',
                  ),
                ),
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
