import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../../application/tasks_cubit.dart';

Widget buildTasksHeader(
  BuildContext context, {
  required bool completed,
  required VoidCallback onOptions,
}) => Padding(
  padding: const EdgeInsets.fromLTRB(24, 20, 12, 24),
  child: Row(
    children: [
      if (Navigator.canPop(context)) const BackButton(),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(completed ? 'Completed' : 'A little more done.'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('Your personal tasks'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: context.tr('Task options'),
        onPressed: onOptions,
        icon: const Icon(Icons.more_horiz),
      ),
    ],
  ),
);

Widget buildTasksFilterChips(BuildContext context, TasksState state) {
  final cubit = context.read<TasksCubit>();
  return Wrap(
    spacing: 12,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: Text(
          context.tr('Open {count}', {
            'count': state.openTotal?.toString() ?? '—',
          }),
        ),
        selected: !state.completed,
        onSelected: state.saving
            ? null
            : (_) => cubit.load(completed: false, page: 1),
      ),
      ChoiceChip(
        label: Text(
          context.tr('Completed {count}', {
            'count': state.doneTotal?.toString() ?? '—',
          }),
        ),
        selected: state.completed,
        onSelected: state.saving
            ? null
            : (_) => cubit.load(completed: true, page: 1),
      ),
    ],
  );
}
