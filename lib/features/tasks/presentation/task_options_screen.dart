import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';

import '../application/tasks_cubit.dart';
import 'widgets/task_reminder_banner.dart';

class TaskOptionsScreen extends StatelessWidget {
  const TaskOptionsScreen({this.widgetHelp = false, super.key});
  final bool widgetHelp;
  @override
  Widget build(BuildContext context) => BlocBuilder<TasksCubit, TasksState>(
    builder: (context, state) => EmployeePage(
      title: widgetHelp ? 'Add a widget' : 'Enable reminders',
      footer: FilledButton(
        onPressed: widgetHelp
            ? () => Navigator.pop(context)
            : () async {
                await context.read<TasksCubit>().syncReminders(request: true);
              },
        child: Text(context.tr(widgetHelp ? 'Done' : 'Enable reminders')),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            context.tr(
              widgetHelp ? 'Your tasks, at a glance.' : 'A timely nudge.',
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 28),
          if (widgetHelp) ...[
            EmployeeTile(
              title: 'Android',
              subtitle: context.tr(
                'Long-press your home screen, choose Widgets, then Shiftly tasks.',
              ),
              icon: Icons.android,
            ),
            const SizedBox(height: 14),
            EmployeeTile(
              title: 'iPhone',
              subtitle: context.tr(
                'Touch and hold your home screen. Tap Add Widget, then choose Shiftly.',
              ),
              icon: Icons.phone_iphone,
            ),
            const SizedBox(height: 16),
            Text(context.tr('Tap a task in the widget to open its details.')),
            if (context.read<TasksCubit>().canAddHomeWidget)
              TextButton(
                onPressed: () async {
                  await context.read<TasksCubit>().requestHomeWidget();
                },
                child: Text(context.tr('Add home screen widget')),
              ),
          ] else ...[
            TaskReminderBanner(
              permission: state.reminderPermission,
              failed: state.reminderError,
              onEnable: () =>
                  context.read<TasksCubit>().syncReminders(request: true),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr(
                'Your tasks stay available if reminders are off. You can change permission in device settings.',
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
