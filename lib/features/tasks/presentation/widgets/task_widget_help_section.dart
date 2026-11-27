import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';

import '../../application/tasks_cubit.dart';

class TaskWidgetHelpSection extends StatelessWidget {
  const TaskWidgetHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }
}
