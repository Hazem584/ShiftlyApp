import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/tasks/application/tasks_cubit.dart';

import 'employee_tile.dart';

class EmployeeTasksPreview extends StatelessWidget {
  const EmployeeTasksPreview({required this.timezone, super.key});
  final String timezone;
  @override
  Widget build(BuildContext context) => BlocBuilder<TasksCubit, TasksState>(
    builder: (context, state) {
      final available = state.items.where((t) => !t.completed).toList()
        ..sort(
          (a, b) => a
              .nextDueAt(DateTime.now())
              .compareTo(b.nextDueAt(DateTime.now())),
        );
      final next = available.firstOrNull;
      final count = state.openTotal;
      return EmployeeTile(
        key: const Key('employee-tasks-preview'),
        icon: Icons.check,
        title: count == null
            ? context.tr('Personal tasks')
            : context.tr('{count} personal tasks remaining', {
                'count': '$count',
              }),
        subtitle: next == null
            ? context.tr('View your tasks and reminders')
            : context.tr('Next: {title} · {time}', {
                'title': next.title,
                'time': WorkspaceTime.dateTime(
                  next.nextDueAt(DateTime.now()),
                  timezone,
                  locale: Localizations.localeOf(context).toString(),
                ),
              }),
        onTap: () => context.go('/employee?tab=tasks'),
      );
    },
  );
}
