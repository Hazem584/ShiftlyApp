import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';

import '../../application/tasks_cubit.dart';
import '../../domain/personal_task.dart';
import 'task_basics_fields.dart';
import 'task_date_time_picker.dart';
import 'task_editor_helpers.dart';
import 'task_editor_page_body.dart';
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
  late final FeatureSessionScope? _scope = context.read<TasksCubit>().scope;
  late final _title = TextEditingController(text: widget.task?.title ?? '');
  late final _desc = TextEditingController(text: widget.task?.description ?? '');
  late final _dur = TextEditingController(
    text: '${widget.task?.durationMinutes ?? 25}',
  );
  late bool _day = widget.task?.remindDayBefore ?? true;
  late bool _hour = widget.task?.remindHourBefore ?? true;
  late List<DateTime> _dates = [...?widget.task?.additionalDueAts];
  late DateTime _dueAt;
  bool _saving = false, _allowPop = false;
  int _step = 0;
  String? _error;
  late final String _initialSig;

  @override
  void initState() {
    super.initState();
    final init =
        widget.task?.dueAt.toLocal() ??
        DateTime.now().add(const Duration(hours: 1));
    _dueAt = widget.task != null
        ? init
        : DateTime(init.year, init.month, init.day, init.hour, init.minute);
    _initialSig = _sig;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _dur.dispose();
    super.dispose();
  }

  String get _sig =>
      '${_title.text}|${_desc.text}|${_dur.text}|${_dueAt.toIso8601String()}|'
      '$_hour|$_day|${_dates.map((d) => d.toIso8601String()).join('|')}';

  Future<void> _pickDate() async {
    final d = await pickTaskCalendarDate(context, _dueAt);
    if (d != null && mounted) {
      setState(() {
        _dueAt = DateTime(d.year, d.month, d.day, _dueAt.hour, _dueAt.minute);
        _error = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await pickTaskClockTime(context, _dueAt, includeUnitLabels: true);
    if (t != null && mounted) {
      setState(() {
        _dueAt = t;
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final err = validateTaskEditorDates(
      context: context,
      task: widget.task,
      dueAt: _dueAt,
      additionalDueAts: _dates,
    );
    if (err != null) return setState(() => _error = err);
    setState(() {
      _saving = true;
      _error = null;
    });
    final cubit = context.read<TasksCubit>();
    final ok = await cubit.save(
      task: widget.task,
      title: _title.text,
      description: _desc.text,
      dueAt: _dueAt,
      durationMinutes: int.tryParse(_dur.text),
      remindDayBefore: _day,
      remindHourBefore: _hour,
      additionalDueAts: _dates,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = context.tr(
          cubit.state.error ?? 'Could not save task. Try again.',
        );
      });
    }
  }

  Future<void> _back() async {
    if (_saving) return;
    if (_step == 1) return setState(() => _step = 0);
    if (!await confirmDiscardTaskEditorChanges(
          context,
          currentSignature: _sig,
          initialSignature: _initialSig,
        ) ||
        !mounted) {
      return;
    }
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => CollaborationAppearance(
    child: BlocListener<TasksCubit, TasksState>(
      listener: (c, _) {
        if (c.read<TasksCubit>().scope != _scope) {
          final route = ModalRoute.of(c);
          if (route != null) Navigator.of(c).removeRoute(route);
        }
      },
      child: PopScope(
        canPop: _allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Builder(
          builder: (context) => TaskEditorPageBody(
            step: _step,
            isNew: widget.task == null,
            saving: _saving,
            error: _error,
            onNextOrSave: _step == 1
                ? _save
                : () {
                    if (_form.currentState!.validate()) {
                      FocusScope.of(context).unfocus();
                      setState(() => _step = 1);
                    }
                  },
            stepOne: Form(
              key: _form,
              child: TaskBasicsFields(
                title: _title,
                description: _desc,
                duration: _dur,
                dueAt: _dueAt,
                busy: _saving,
                pickDate: _pickDate,
                pickTime: _pickTime,
              ),
            ),
            stepTwo: TaskReminderFields(
              dueAt: _dueAt,
              duration: int.tryParse(_dur.text),
              day: _day,
              hour: _hour,
              dates: _dates,
              busy: _saving,
              onDay: (v) => setState(() => _day = v),
              onHour: (v) => setState(() => _hour = v),
              onDates: (v) => setState(() => _dates = v),
            ),
          ),
        ),
      ),
    ),
  );
}
