import 'package:day_night_time_picker/day_night_time_picker.dart'
    as clock_picker;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';

import '../../application/tasks_cubit.dart';
import '../../domain/personal_task.dart';
import '../task_actions.dart';
import 'task_basics_fields.dart';
import 'task_reminder_fields.dart';

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
    _initialSignature = _signature;
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
      durationMinutes: int.tryParse(_duration.text),
      remindDayBefore: _remindDayBefore,
      remindHourBefore: _remindHourBefore,
      additionalDueAts: _additionalDueAts,
    );
    if (!mounted) return;
    if (success) {
      setState(() => _allowPop = true);
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

  int _step = 0;
  bool _allowPop = false;
  late String _initialSignature;
  String get _signature => [
    _title.text,
    _description.text,
    _duration.text,
    _dueAt.toIso8601String(),
    _remindHourBefore,
    _remindDayBefore,
    ..._additionalDueAts.map((d) => d.toIso8601String()),
  ].join('|');
  Future<void> _back() async {
    if (_saving) return;
    if (_step == 1) {
      setState(() => _step = 0);
      return;
    }
    if (_signature != _initialSignature) {
      final discard = await confirmTaskAction(
        context,
        title: 'Leave without saving?',
        message: context.tr('Your changes to this task will be lost.'),
        action: 'Discard changes',
      );
      if (!discard || !mounted) return;
    }
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CollaborationAppearance(
      child: BlocListener<TasksCubit, TasksState>(
        listener: (context, state) {
          if (context.read<TasksCubit>().scope != _scope) {
            final route = ModalRoute.of(context);
            if (route != null) Navigator.of(context).removeRoute(route);
          }
        },
        child: PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _back();
          },
          child: Builder(
            builder: (context) {
              return EmployeePage(
                title: _step == 1
                    ? 'Dates and reminders'
                    : widget.task == null
                    ? 'Create task'
                    : 'Edit task',
                footer: FilledButton(
                  key: const Key('save-personal-task'),
                  onPressed: _saving
                      ? null
                      : _step == 1
                      ? _save
                      : () {
                          if (_form.currentState!.validate()) {
                            FocusScope.of(context).unfocus();
                            setState(() => _step = 1);
                          }
                        },
                  child: Text(
                    context.tr(
                      _saving
                          ? 'Saving…'
                          : _step == 0
                          ? 'Continue to reminders'
                          : 'Save task',
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                      child: Text(
                        context.tr(
                          _step == 0
                              ? 'Step 1 of 2 · Personal to you'
                              : 'Step 2 of 2 · Device timezone',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _step,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Form(
                              key: _form,
                              child: TaskBasicsFields(
                                title: _title,
                                description: _description,
                                duration: _duration,
                                dueAt: _dueAt,
                                busy: _saving,
                                pickDate: _pickDate,
                                pickTime: _pickTime,
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: TaskReminderFields(
                              dueAt: _dueAt,
                              duration: int.tryParse(_duration.text),
                              day: _remindDayBefore,
                              hour: _remindHourBefore,
                              dates: _additionalDueAts,
                              busy: _saving,
                              onDay: (v) =>
                                  setState(() => _remindDayBefore = v),
                              onHour: (v) =>
                                  setState(() => _remindHourBefore = v),
                              onDates: (v) =>
                                  setState(() => _additionalDueAts = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
