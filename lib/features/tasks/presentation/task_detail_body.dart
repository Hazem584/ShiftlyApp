import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';

import '../domain/personal_task.dart';
import 'task_actions.dart';
import 'widgets/task_editor.dart';

Widget buildTaskDetailPage(
  BuildContext context,
  PersonalTask t, {
  required bool saving,
}) {
  final locale = Localizations.localeOf(context).toString();
  return EmployeePage(
    title: t.title,
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          key: const Key('task-detail-complete'),
          onPressed: saving
              ? null
              : () async {
                  if (await togglePersonalTask(context, t) && context.mounted) {
                    Navigator.pop(context);
                  }
                },
          child: Text(
            context.tr(t.completed ? 'Reopen task' : 'Mark complete'),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: saving ? null : () => showTaskEditor(context, task: t),
              child: Text(context.tr('Edit task')),
            ),
            TextButton(
              onPressed: saving
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
            t.completed ? 'Personal task · Completed' : 'Personal task · Open',
          ),
        ),
        const SizedBox(height: 24),
        EmployeeTile(
          icon: Icons.schedule_outlined,
          title: DateFormat.yMMMd(locale).add_Hm().format(t.dueAt.toLocal()),
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
              context.tr('{minutes} min', {'minutes': '${t.durationMinutes}'}),
            if (t.remindHourBefore) context.tr('Remind me one hour before'),
            if (t.remindDayBefore) context.tr('Remind me one day before'),
            for (final date in t.additionalDueAts)
              DateFormat.yMMMd(locale).add_Hm().format(date.toLocal()),
          ].join('\n'),
          icon: Icons.notifications_none,
        ),
      ],
    ),
  );
}
