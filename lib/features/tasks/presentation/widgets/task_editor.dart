import 'package:day_night_time_picker/day_night_time_picker.dart'
    as clock_picker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import '../../application/tasks_cubit.dart';
import '../../domain/personal_task.dart';
import 'task_additional_times.dart';

Future<void> showTaskEditor(BuildContext context, {PersonalTask? task}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<TasksCubit>(),
        child: TaskEditor(task: task),
      ),
    );

class TaskEditor extends StatefulWidget {
  const TaskEditor({this.task, super.key});
  final PersonalTask? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final FeatureSessionScope? _scope;
  late final TextEditingController _title, _description, _duration;
  late bool _remindDayBefore;
  late bool _remindHourBefore;
  late DateTime _dueAt;
  late List<DateTime> _additionalDueAts;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _scope = context.read<TasksCubit>().scope;
    _additionalDueAts = [...?widget.task?.additionalDueAts];
    _title = TextEditingController(text: widget.task?.title ?? '');
    _description = TextEditingController(text: widget.task?.description ?? '');
    _duration = TextEditingController(
      text: (widget.task?.durationMinutes ?? 25).toString(),
    );
    _remindDayBefore = widget.task?.remindDayBefore ?? true;
    _remindHourBefore = widget.task?.remindHourBefore ?? true;
    final initial =
        widget.task?.dueAt.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    // Preserve an existing instant, including seconds and the chosen DST
    // offset. Opening the editor must not silently reschedule an overdue task.
    _dueAt = widget.task != null
        ? initial
        : DateTime(
            initial.year,
            initial.month,
            initial.day,
            initial.hour,
            initial.minute,
          );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt.isBefore(now) ? now : _dueAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 100, 12, 31),
    );
    if (date == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        _dueAt.hour,
        _dueAt.minute,
      );
      _error = null;
    });
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    clock_picker.Time? chosen;
    await Navigator.of(context).push(
      clock_picker.showPicker(
        context: context,
        value: clock_picker.Time(hour: _dueAt.hour, minute: _dueAt.minute),
        onChange: (time) => chosen = time,
        is24HrFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        accentColor: Theme.of(context).colorScheme.primary,
        themeData: Theme.of(context),
        backgroundColor: Theme.of(context).colorScheme.surface,
        ltrMode: Directionality.of(context) == TextDirection.ltr,
        amLabel: MaterialLocalizations.of(context).anteMeridiemAbbreviation,
        pmLabel: MaterialLocalizations.of(context).postMeridiemAbbreviation,
        width: (MediaQuery.sizeOf(context).width - 48).clamp(240.0, 380.0),
        borderRadius: 24,
        dialogInsetPadding: const EdgeInsets.all(16),
        cancelText: context.tr('Cancel'),
        okText: context.tr('Confirm time'),
        hourLabel: context.tr('Hours'),
        minuteLabel: context.tr('Minutes'),
      ),
    );
    final time = chosen;
    if (!mounted || time == null) return;
    setState(() {
      _dueAt = DateTime(
        _dueAt.year,
        _dueAt.month,
        _dueAt.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_additionalDueAts.any((date) => date.isAtSameMomentAs(_dueAt))) {
      setState(
        () => _error = context.tr('Choose a different future alarm time.'),
      );
      return;
    }
    final unchanged =
        widget.task != null && _dueAt.isAtSameMomentAs(widget.task!.dueAt);
    if (!_dueAt.isAfter(DateTime.now()) && !unchanged) {
      setState(() => _error = context.tr('Choose a future date and time.'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final cubit = context.read<TasksCubit>();
    final success = await cubit.save(
      task: widget.task,
      title: _title.text,
      description: _description.text,
      dueAt: _dueAt,
      durationMinutes: int.parse(_duration.text),
      remindDayBefore: _remindDayBefore,
      remindHourBefore: _remindHourBefore,
      additionalDueAts: _additionalDueAts,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = false;
      _error = context.tr(
        cubit.state.error ?? 'Could not save task. Try again.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return BlocListener<TasksCubit, TasksState>(
      listener: (context, state) {
        if (context.read<TasksCubit>().scope != _scope) {
          final route = ModalRoute.of(context);
          if (route != null) Navigator.of(context).removeRoute(route);
        }
      },
      child: PopScope(
        canPop: !_saving,
        child: Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.edit_calendar_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr(
                              widget.task == null ? 'New task' : 'Edit task',
                            ),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
                          tooltip: context.tr('Close'),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _title,
                      enabled: !_saving,
                      autofocus: true,
                      maxLength: 160,
                      decoration: InputDecoration(
                        labelText: context.tr('Task title'),
                        prefixIcon: const Icon(Icons.title_rounded),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? context.tr('Enter a task title.')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('task-duration'),
                      controller: _duration,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: context.tr('Task duration in minutes'),
                        prefixIcon: const Icon(Icons.timer_outlined),
                      ),
                      validator: (text) {
                        final minutes = int.tryParse(text ?? '');
                        return minutes == null || minutes < 1 || minutes > 10080
                            ? context.tr(
                                'Choose a duration from 1 to 10080 minutes.',
                              )
                            : null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [5, 15, 25, 45, 60]
                          .map(
                            (minutes) => ActionChip(
                              label: Text(
                                context.tr('{minutes} min', {
                                  'minutes': '$minutes',
                                }),
                              ),
                              onPressed: _saving
                                  ? null
                                  : () => _duration.text = '$minutes',
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      enabled: !_saving,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 5000,
                      decoration: InputDecoration(
                        labelText: context.tr('Task details'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _pickDate,
                          icon: const Icon(Icons.event_outlined),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              DateFormat.yMMMd(locale).format(_dueAt),
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const Key('task-time-picker'),
                          onPressed: _saving ? null : _pickTime,
                          icon: const Icon(Icons.schedule_rounded),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(DateFormat.jm(locale).format(_dueAt)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('Time is shown in your device timezone.'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      key: const Key('task-remind-day'),
                      value: _remindDayBefore,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _remindDayBefore = value),
                      title: Text(context.tr('Remind me one day before')),
                      subtitle: Text(
                        context.tr('A notification 24 hours before the task.'),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      key: const Key('task-remind-hour'),
                      contentPadding: EdgeInsets.zero,
                      value: _remindHourBefore,
                      onChanged: _saving
                          ? null
                          : (value) =>
                                setState(() => _remindHourBefore = value),
                      title: Text(context.tr('Remind me one hour before')),
                      subtitle: Text(
                        context.tr(
                          'A notification 60 minutes before the task.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TaskAdditionalTimes(
                      primary: _dueAt,
                      dates: _additionalDueAts,
                      enabled: !_saving,
                      onChanged: (dates) =>
                          setState(() => _additionalDueAts = dates),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        'An alarm at the task time and when its duration ends.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(context.tr('Save task')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
