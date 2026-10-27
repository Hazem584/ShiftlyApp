import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';

import '../application/tasks_cubit.dart';
import '../domain/personal_task.dart';
import 'widgets/task_card.dart';
import 'widgets/task_editor.dart';
import 'widgets/task_progress_overview.dart';
import 'widgets/task_reminder_banner.dart';

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
      await showTaskEditor(context, task: task);
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

  Future<void> _delete(PersonalTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Delete task?')),
        content: Text(
          context.tr(
            'This permanently deletes the task and cancels its reminder.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<TasksCubit>().remove(task);
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<TasksCubit, TasksState>(
    listenWhen: (before, after) =>
        after.error != null && before.error != after.error,
    listener: (context, state) =>
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr(state.error!)))),
    builder: (context, state) {
      final cubit = context.read<TasksCubit>(),
          colors = Theme.of(context).colorScheme;
      if (state.loading && state.items.isEmpty) return Scaffold(appBar: AppBar(title: Text(context.tr('Task manager'))), body: const AppContentLoading());
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Task manager')),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: FloatingActionButton.small(
                heroTag: 'personal-create-task',
                tooltip: context.tr('New task'),
                onPressed: state.saving ? null : () => showTaskEditor(context),
                child: const Icon(Icons.add_rounded),
              ),
            ),
            IconButton(
              onPressed: state.loading
                  ? null
                  : () => unawaited(cubit.refresh()),
              tooltip: context.tr('Refresh'),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: cubit.refresh,
          child: LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 1000
                  ? 3
                  : box.maxWidth >= 650
                  ? 2
                  : 1;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TaskProgressOverview(
                                open: state.totalsAvailable
                                    ? state.openTotal
                                    : null,
                                done: state.totalsAvailable
                                    ? state.doneTotal
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TaskReminderBanner(
                                permission: state.reminderPermission,
                                failed: state.reminderError,
                                onEnable: () => unawaited(
                                  cubit.syncReminders(request: true),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ChoiceChip(
                                    label: Text(context.tr('Open tasks')),
                                    selected: !state.completed,
                                    onSelected: state.saving
                                        ? null
                                        : (_) => unawaited(
                                            cubit.load(
                                              completed: false,
                                              page: 1,
                                            ),
                                          ),
                                  ),
                                  ChoiceChip(
                                    label: Text(context.tr('Completed tasks')),
                                    selected: state.completed,
                                    onSelected: state.saving
                                        ? null
                                        : (_) => unawaited(
                                            cubit.load(
                                              completed: true,
                                              page: 1,
                                            ),
                                          ),
                                  ),
                                  Text(
                                    context.tr('{count} tasks', {
                                      'count': state.total.toString(),
                                    }),
                                  ),
                                ],
                              ),
                              if (state.loading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: AppContentLoading(rows: 1),
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (state.items.isEmpty && !state.loading)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 64,
                              color: colors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr(
                                state.completed
                                    ? 'Completed tasks will appear here.'
                                    : 'A clear mind starts with a task.',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => showTaskEditor(context),
                              icon: const Icon(Icons.add),
                              label: Text(context.tr('New task')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: columns == 1
                        ? SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final task = state.items[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TaskCard(
                                  task: task,
                                  busy: state.saving,
                                  onOpen: () =>
                                      showTaskEditor(context, task: task),
                                  onToggle: () => unawaited(cubit.toggle(task)),
                                  onDelete: () => unawaited(_delete(task)),
                                ),
                              );
                            }, childCount: state.items.length),
                          )
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisExtent:
                                      238 *
                                      MediaQuery.textScalerOf(context)
                                          .scale(14) /
                                      14,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final task = state.items[index];
                              return TaskCard(
                                task: task,
                                busy: state.saving,
                                onOpen: () =>
                                    showTaskEditor(context, task: task),
                                onToggle: () => unawaited(cubit.toggle(task)),
                                onDelete: () => unawaited(_delete(task)),
                              );
                            }, childCount: state.items.length),
                          ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: state.loading || state.page <= 1
                                ? null
                                : () => unawaited(
                                    cubit.load(page: state.page - 1),
                                  ),
                            tooltip: context.tr('Previous page'),
                            icon: const BackButtonIcon(),
                          ),
                          Text(
                            context.tr('Page {page}', {
                              'page': state.page.toString(),
                            }),
                          ),
                          IconButton(
                            onPressed:
                                state.loading || state.page * 30 >= state.total
                                ? null
                                : () => unawaited(
                                    cubit.load(page: state.page + 1),
                                  ),
                            tooltip: context.tr('Next page'),
                            icon: const RotatedBox(
                              quarterTurns: 2,
                              child: BackButtonIcon(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
