import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';

import '../application/tasks_cubit.dart';
import 'task_actions.dart';
import 'task_detail_screen.dart';
import 'task_options_screen.dart';
import 'widgets/task_card.dart';
import 'widgets/task_editor.dart';
import 'widgets/task_progress_overview.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({this.taskId, super.key});
  final String? taskId;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  Timer? _refresh;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<TasksCubit>().refresh());
      unawaited(_openInitial());
    });
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(context.read<TasksCubit>().refresh());
      }
    });
  }

  Future<void> _openInitial() async {
    if (widget.taskId == null) return;
    final cubit = context.read<TasksCubit>(),
        owner = context.read<TasksCubit>().scope?.userId;
    if (owner == null) return;
    final task = await cubit.resolveTap(owner, widget.taskId!);
    if (!mounted) return;
    if (task != null) {
      await showTaskDetails(context, task);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Task is no longer available.'))),
      );
    }
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _options() async {
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
    if (!mounted || choice == null) return;
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

  @override
  Widget build(BuildContext context) =>
      CollaborationAppearance(child: Builder(builder: _body));
  Widget _body(BuildContext context) => BlocConsumer<TasksCubit, TasksState>(
    listenWhen: (before, after) =>
        after.error != null && before.error != after.error,
    listener: (context, state) =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr(state.error!)))),
    builder: (context, state) {
      final cubit = context.read<TasksCubit>();
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 12, 24),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context)) const BackButton(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(
                                  state.completed
                                      ? 'Completed'
                                      : 'A little more done.',
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.tr('Your personal tasks'),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('Task options'),
                          onPressed: _options,
                          icon: const Icon(Icons.more_horiz),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: cubit.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          if (!state.completed) ...[
                            TaskProgressOverview(
                              open: state.totalsAvailable
                                  ? state.openTotal
                                  : null,
                              done: state.totalsAvailable
                                  ? state.doneTotal
                                  : null,
                            ),
                            const SizedBox(height: 20),
                          ],
                          Wrap(
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
                                    : (_) =>
                                          cubit.load(completed: false, page: 1),
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
                                    : (_) =>
                                          cubit.load(completed: true, page: 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (state.loading && state.items.isEmpty)
                            const AppContentLoading(),
                          if (state.error != null) ...[
                            Text(
                              context.tr(state.error!),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            TextButton(
                              onPressed: cubit.refresh,
                              child: Text(context.tr('Try again')),
                            ),
                          ],
                          if (!state.loading &&
                              state.items.isEmpty &&
                              state.error == null)
                            Padding(
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
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
                            ),
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
                            Row(
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
                                  onPressed:
                                      state.page * 30 < state.total &&
                                          !state.loading
                                      ? () => cubit.load(page: state.page + 1)
                                      : null,
                                  icon: const RotatedBox(
                                    quarterTurns: 2,
                                    child: BackButtonIcon(),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
                    child: FilledButton(
                      key: const Key('add-personal-task'),
                      onPressed: state.saving
                          ? null
                          : () => showTaskEditor(context),
                      child: Text(context.tr('Add task')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
