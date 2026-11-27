import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import '../domain/personal_task.dart';
import '../domain/task_home_widget.dart';
import '../domain/task_reminders.dart';
import '../domain/task_repository.dart';
import 'task_widget_sync.dart';
import 'tasks_cubit_helpers.dart';
import 'tasks_cubit_mutation.dart';
import 'tasks_page_loader.dart';
import 'tasks_state.dart';

export 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(
    this.repository,
    this.reminders, {
    this.enableRemoteReminders,
    TaskHomeWidget? homeWidget,
    DateTime Function()? clock,
  }) : _homeWidget = homeWidget,
       _clock = clock ?? DateTime.now,
       super(const TasksState()) {
    if (homeWidget != null) {
      widgetSync = TaskWidgetSync(repository, homeWidget);
      unawaited(widgetSync!.bind(null));
    }
  }
  TaskWidgetSync? widgetSync;
  final TaskHomeWidget? _homeWidget;
  bool get canAddHomeWidget => _homeWidget?.isSupported ?? false;
  Future<bool> requestHomeWidget() =>
      _homeWidget?.requestPin() ?? Future.value(false);
  final DateTime Function() _clock;
  final TaskRepository repository;
  final TaskReminders reminders;
  final Future<void> Function()? enableRemoteReminders;
  FeatureSessionScope? scope;
  int _generation = 0, _load = 0;
  Future<void> _reminderQueue = Future.value();
  String? _lastReminderSignature;
  bool _valid(int g) => !isClosed && g == _generation;

  Future<void> bindSession(FeatureSessionScope? value) async {
    if (scope == value) return;
    final oldUser = scope?.userId;
    scope = value;
    final g = ++_generation;
    _lastReminderSignature = null;
    _load++;
    emit(const TasksState());
    await widgetSync?.bind(value?.userId);
    if (!_valid(g)) return;
    _reminderQueue = _reminderQueue
        .then((_) async {
          if (_valid(g) && (oldUser != value?.userId || value == null)) {
            await reminders.clear();
          }
        })
        .catchError((Object _) {});
    await (value != null ? refresh() : _reminderQueue);
  }

  Future<void> refresh() => Future.wait([
    load(),
    syncReminders(),
    if (widgetSync != null) widgetSync!.refresh(),
  ]);

  Future<void> load({bool? completed, int? page}) async {
    if (scope == null || isClosed) return;
    final g = _generation, req = ++_load;
    await loadTasksPageIntoState(
      repository: repository,
      getState: () => state,
      emitState: emit,
      isValidRequest: () => _valid(g) && req == _load,
      reloadPage: load,
      completed: completed,
      page: page,
    );
  }

  Future<void> syncReminders({bool request = false}) {
    final g = _generation;
    return _reminderQueue = _reminderQueue.then(
      (_) => !_valid(g) || scope == null
          ? null
          : syncTaskRemindersFlow(
              repository: repository,
              reminders: reminders,
              user: scope!.userId,
              request: request,
              clock: _clock,
              enableRemoteReminders: enableRemoteReminders,
              isValid: () => _valid(g),
              getLastSignature: () => _lastReminderSignature,
              setLastSignature: (s) => _lastReminderSignature = s,
              onPermission: (p) =>
                  emit(state.copy(reminderPermission: p, reminderError: false)),
              onError: () => emit(state.copy(reminderError: true)),
            ),
    );
  }

  Future<bool> _mutate(
    Future<void> Function(FeatureSessionScope) action, {
    PersonalTask? changedTask,
  }) {
    final g = _generation;
    return runTaskMutation(
      scope: scope,
      getState: () => state,
      emitState: emit,
      isValid: () => _valid(g),
      action: action,
      changedTask: changedTask,
      clearSignature: () => _lastReminderSignature = null,
      enqueueReminder: (fn) => _reminderQueue = _reminderQueue
          .then((_) => fn())
          .catchError((Object _) {
            if (_valid(g)) emit(state.copy(reminderError: true));
          }),
      reminders: reminders,
      refresh: refresh,
      syncReminders: syncReminders,
    );
  }

  Future<bool> save({
    PersonalTask? task,
    required String title,
    required String description,
    required DateTime dueAt,
    int? durationMinutes,
    bool remindDayBefore = false,
    bool remindHourBefore = false,
    List<DateTime> additionalDueAts = const [],
  }) => _mutate(
    (s) => savePersonalTask(
      repository,
      s,
      task: task,
      title: title,
      description: description,
      dueAt: dueAt,
      durationMinutes: durationMinutes,
      remindDayBefore: remindDayBefore,
      remindHourBefore: remindHourBefore,
      additionalDueAts: additionalDueAts,
    ),
    changedTask: task,
  );
  Future<bool> toggle(PersonalTask t) => _mutate(
    (_) => repository.update(t, completed: !t.completed),
    changedTask: t,
  );
  Future<bool> remove(PersonalTask t) =>
      _mutate((_) => repository.remove(t), changedTask: t);
  Future<PersonalTask?> resolveTap(String ownerId, String taskId) {
    final g = _generation;
    return resolveOwnerTaskTap(
      repository,
      scope,
      ownerId,
      taskId,
      () => _valid(g),
    );
  }

  @override
  Future<void> close() async {
    _generation++;
    await _reminderQueue;
    await reminders.close();
    await widgetSync?.close();
    return super.close();
  }
}
