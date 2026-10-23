import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import '../../application/tasks_cubit.dart';
import '../../domain/personal_task.dart';

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
  late final TextEditingController _title, _description;
  late DateTime _dueAt;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _scope = context.read<TasksCubit>().scope;
    _title = TextEditingController(text: widget.task?.title ?? '');
    _description = TextEditingController(text: widget.task?.description ?? '');
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
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt.isBefore(now) ? now : _dueAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 100, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
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
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pick,
                      icon: const Icon(Icons.event_outlined),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          DateFormat.yMMMd(locale).add_jm().format(_dueAt),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('Time is shown in your device timezone.'),
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
