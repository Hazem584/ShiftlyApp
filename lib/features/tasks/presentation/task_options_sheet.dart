import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../application/tasks_cubit.dart';
import 'task_options_screen.dart';

Future<void> openTaskOptionsMenu(BuildContext context) async {
  final cubit = context.read<TasksCubit>();
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(c.tr('Task options')),
            subtitle: Text(c.tr('Your personal tasks')),
          ),
          for (final (value, label, icon) in [
            ('reminders', 'Reminders', Icons.notifications_none),
            ('widget', 'Home-screen widget', Icons.widgets_outlined),
            ('completed', 'Completed tasks', Icons.check_circle_outline),
          ])
            ListTile(
              leading: Icon(icon),
              title: Text(c.tr(label)),
              onTap: () => Navigator.pop(c, value),
            ),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  if (choice == 'completed') {
    await cubit.load(completed: true, page: 1);
    return;
  }
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: TaskOptionsScreen(widgetHelp: choice == 'widget'),
      ),
    ),
  );
}
