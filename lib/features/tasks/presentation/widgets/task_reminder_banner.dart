import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../../domain/task_reminders.dart';

class TaskReminderBanner extends StatelessWidget {
  const TaskReminderBanner({
    required this.permission,
    required this.failed,
    required this.onEnable,
    super.key,
  });
  final TaskReminderPermission permission;
  final bool failed;
  final VoidCallback onEnable;
  @override
  Widget build(BuildContext context) {
    final message = failed
        ? 'Reminder sync failed. Open the app online to retry.'
        : switch (permission) {
            TaskReminderPermission.unsupported =>
              'Manage tasks here. Enable mobile reminders on your phone.',
            TaskReminderPermission.disabled =>
              'Enable notifications and precise alarms for task reminders.',
            TaskReminderPermission.approximate =>
              'Reminders are enabled. Allow precise alarms for better timing.',
            TaskReminderPermission.exact => 'Mobile reminders are scheduled. Keep notification permissions enabled.',
          };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            failed
                ? Icons.sync_problem_rounded
                : Icons.notifications_active_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr(message),
              style: const TextStyle(height: 1.4),
            ),
          ),
          if (permission != TaskReminderPermission.unsupported &&
              (failed || permission != TaskReminderPermission.exact))
            IconButton(
              onPressed: onEnable,
              tooltip: context.tr('Enable reminders'),
              icon: const Icon(Icons.settings_outlined),
            ),
        ],
      ),
    );
  }
}
