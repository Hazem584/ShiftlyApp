import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';

import '../../application/tasks_cubit.dart';
import '../task_actions.dart';
import '../task_detail_screen.dart';
import 'task_card.dart';
import 'task_progress_overview.dart';
import 'tasks_header_and_filters.dart';

class TasksListContent extends StatelessWidget {
  const TasksListContent({required this.state, super.key});
  final TasksState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TasksCubit>();
    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          if (!state.completed) ...[
            TaskProgressOverview(
              open: state.totalsAvailable ? state.openTotal : null,
              done: state.totalsAvailable ? state.doneTotal : null,
            ),
            const SizedBox(height: 20),
          ],
          buildTasksFilterChips(context, state),
          const SizedBox(height: 20),
          if (state.loading && state.items.isEmpty) const AppContentLoading(),
          if (state.error != null) ...[
            Text(
              context.tr(state.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: cubit.refresh,
              child: Text(context.tr('Try again')),
            ),
          ],
          if (!state.loading && state.items.isEmpty && state.error == null)
            _buildEmpty(context),
          for (final task in state.items) ...[
            TaskCard(
              task: task,
              busy: state.saving,
              onOpen: () => showTaskDetails(context, task),
              onToggle: () => togglePersonalTask(context, task),
              onDelete: () => deletePersonalTask(context, task),
            ),
            const SizedBox(height: 12),
          ],
          if (state.page > 1 || state.page * 30 < state.total)
            _buildPager(context, cubit),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44),
    child: Column(
      children: [
        const Icon(Icons.task_alt_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          context.tr(
            state.completed
                ? 'Completed tasks will appear here.'
                : 'A clear start.',
          ),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            state.completed
                ? 'A good day’s work. Open a completed task to reopen it.'
                : 'No open tasks yet. Add one for your next small win.',
          ),
        ),
      ],
    ),
  );

  Widget _buildPager(BuildContext context, TasksCubit cubit) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        tooltip: context.tr('Previous page'),
        onPressed: state.page > 1 && !state.loading
            ? () => cubit.load(page: state.page - 1)
            : null,
        icon: const BackButtonIcon(),
      ),
      Text('${state.page}'),
      IconButton(
        tooltip: context.tr('Next page'),
        onPressed: state.page * 30 < state.total && !state.loading
            ? () => cubit.load(page: state.page + 1)
            : null,
        icon: const RotatedBox(quarterTurns: 2, child: BackButtonIcon()),
      ),
    ],
  );
}
