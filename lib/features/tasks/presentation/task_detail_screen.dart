import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';

import '../application/tasks_cubit.dart';
import '../domain/personal_task.dart';
import 'task_actions.dart';
import 'widgets/task_editor.dart';

Future<void> showTaskDetails(BuildContext context, PersonalTask task) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<TasksCubit>(),
          child: TaskDetailScreen(task: task),
        ),
      ),
    );

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({required this.task, super.key});
  final PersonalTask task;
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late PersonalTask _task = widget.task;
  late final FeatureSessionScope? _scope;
  @override
  void initState() {
    super.initState();
    _scope = context.read<TasksCubit>().scope;
  }

  @override
  Widget build(BuildContext context) =>
      CollaborationSessionBoundary(child: Builder(builder: _build));
  Widget _build(BuildContext context) => CollaborationAppearance(
    child: BlocConsumer<TasksCubit, TasksState>(
      listener: (c, state) {
        if (c.read<TasksCubit>().scope != _scope) {
          final route = ModalRoute.of(c);
          if (route != null) Navigator.of(c).removeRoute(route);
          return;
        }
        final next = state.items.where((t) => t.id == _task.id).firstOrNull;
        if (next != null) setState(() => _task = next);
      },
      builder: (context, state) {
        final t = _task, locale = Localizations.localeOf(context).toString();
        return EmployeePage(
          title: t.title,
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: const Key('task-detail-complete'),
                onPressed: state.saving
                    ? null
                    : () async {
                        final updated = await togglePersonalTask(context, t);
                        if (updated && context.mounted) Navigator.pop(context);
                      },
                child: Text(
                  context.tr(t.completed ? 'Reopen task' : 'Mark complete'),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: state.saving
                        ? null
                        : () => showTaskEditor(context, task: t),
                    child: Text(context.tr('Edit task')),
                  ),
                  TextButton(
                    onPressed: state.saving
                        ? null
                        : () async {
                            if (await deletePersonalTask(context, t) &&
                                context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: Text(context.tr('Delete task')),
                  ),
                ],
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                context.tr(
                  t.completed
                      ? 'Personal task · Completed'
                      : 'Personal task · Open',
                ),
              ),
              const SizedBox(height: 24),
              EmployeeTile(
                icon: Icons.schedule_outlined,
                title: DateFormat.yMMMd(locale)
                    .add_Hm()
                    .format(t.dueAt.toLocal()),
                subtitle: context.tr('Time is shown in your device timezone.'),
              ),
              const SizedBox(height: 14),
              EmployeeTile(
                title: context.tr('Task details'),
                subtitle: t.description.isEmpty
                    ? context.tr('No description')
                    : t.description,
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 14),
              EmployeeTile(
                title: context.tr('Reminders and dates'),
                subtitle: [
                  if (t.durationMinutes != null)
                    context.tr('{minutes} min', {
                      'minutes': '${t.durationMinutes}',
                    }),
                  if (t.remindHourBefore)
                    context.tr('Remind me one hour before'),
                  if (t.remindDayBefore) context.tr('Remind me one day before'),
                  for (final date in t.additionalDueAts)
                    DateFormat.yMMMd(locale).add_Hm().format(date.toLocal()),
                ].join('\n'),
                icon: Icons.notifications_none,
              ),
            ],
          ),
        );
      },
    ),
  );
}
