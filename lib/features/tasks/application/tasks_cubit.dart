import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import '../domain/personal_task.dart';
import '../domain/task_reminders.dart';
import '../domain/task_repository.dart';
import 'tasks_state.dart';

export 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(this.repository, this.reminders, {this.enableRemoteReminders})
    : super(const TasksState());
  final TaskRepository repository;
  final TaskReminders reminders;
  final Future<void> Function()? enableRemoteReminders;
  FeatureSessionScope? scope;
  int _generation = 0, _load = 0;
  Future<void> _reminderQueue = Future.value();
  String? _lastReminderSignature;
  bool _valid(int generation) => !isClosed && generation == _generation;

  Future<void> bindSession(FeatureSessionScope? value) async {
    if (scope == value) return;
    final oldUser = scope?.userId;
    scope = value;
    final generation = ++_generation;
    _lastReminderSignature = null;
    _load++;
    emit(const TasksState());
    _reminderQueue = _reminderQueue
        .then((_) async {
          if (!_valid(generation)) return;
          if (oldUser != value?.userId || value == null) {
            await reminders.clear();
          }
        })
        .catchError((Object _) {});
    if (value != null) {
      await refresh();
    } else {
      await _reminderQueue;
    }
  }

  Future<void> refresh() async {
    await Future.wait([load(), syncReminders()]);
  }

  Future<void> load({bool? completed, int? page}) async {
    if (scope == null || isClosed) return;
    final generation = _generation, request = ++_load;
    final changed =
        (completed != null && completed != state.completed) ||
        (page != null && page != state.page);
    emit(
      state.copy(
        loading: true,
        completed: completed,
        page: page,
        items: changed ? [] : null,
      ),
    );
    final selected = state.completed, selectedPage = state.page;
    try {
      final result = await repository.list(
        completed: selected,
        page: selectedPage,
      );
      if (!_valid(generation) || request != _load) return;
      if (result.items.isEmpty &&
          selectedPage > 1 &&
          result.total <= (selectedPage - 1) * 30) {
        await load(page: ((result.total - 1) ~/ 30 + 1).clamp(1, 100000));
        return;
      }
      emit(
        state.copy(items: result.items, total: result.total, loading: false),
      );
    } catch (error) {
      if (_valid(generation) && request == _load) {
        emit(
          state.copy(
            loading: false,
            error: ApiErrorParser.parse(error).message,
          ),
        );
      }
    }
  }

  Future<void> syncReminders({bool request = false}) {
    final generation = _generation;
    _reminderQueue = _reminderQueue.then((_) async {
      if (!_valid(generation) || scope == null) return;
      final user = scope!.userId;
      try {
        final permission = await reminders.permission(user, request: request);
        if (request && _valid(generation)) {
          await enableRemoteReminders?.call();
        }
        if (!_valid(generation)) return;
        emit(state.copy(reminderPermission: permission, reminderError: false));
        final tasks = await repository.upcoming();
        if (!_valid(generation)) return;
        final signature =
            '$user:$permission:${tasks.map((t) => '${t.id}:${t.revision}').join(',')}';
        if (signature == _lastReminderSignature) return;
        final installation = await reminders.installationId();
        // Withdraw acknowledgements first: partial native scheduling must leave
        // the server fallback available. Only successful exact alarms are acked.
        var registrationFailed = false;
        if (installation != null) {
          try {
            await repository.register(installation, []);
          } catch (_) {
            // A failed server acknowledgement must not prevent the phone's
            // primary alarm from being installed after a successful task save.
            registrationFailed = true;
          }
        }
        if (!_valid(generation)) return;
        final scheduled = await reminders.replace(
          user,
          tasks,
          preserveExisting: registrationFailed,
        );
        if (!_valid(generation)) {
          await reminders.clear();
          return;
        }
        if (installation != null) {
          try {
            await repository.register(installation, scheduled);
          } catch (_) {
            registrationFailed = true;
          }
        }
        if (!_valid(generation)) return;
        _lastReminderSignature = registrationFailed ? null : signature;
        if (registrationFailed) emit(state.copy(reminderError: true));
      } catch (_) {
        _lastReminderSignature = null;
        if (_valid(generation)) emit(state.copy(reminderError: true));
      }
    });
    return _reminderQueue;
  }

  Future<bool> _mutate(
    Future<void> Function(FeatureSessionScope) action, {
    PersonalTask? changedTask,
  }) async {
    final current = scope, generation = _generation;
    if (current == null || state.saving) return false;
    if (changedTask != null && changedTask.ownerId != current.userId) {
      return false;
    }
    emit(state.copy(saving: true));
    try {
      await action(current);
      if (!_valid(generation)) return false;
      if (changedTask != null) {
        _lastReminderSignature = null;
        _reminderQueue = _reminderQueue
            .then((_) => reminders.cancel(changedTask.id))
            .catchError((Object _) {
              if (_valid(generation)) emit(state.copy(reminderError: true));
            });
        await _reminderQueue;
        if (!_valid(generation)) return false;
      }
      emit(state.copy(saving: false));
      await refresh();
      return _valid(generation);
    } catch (error) {
      if (_valid(generation)) {
        emit(
          state.copy(saving: false, error: ApiErrorParser.parse(error).message),
        );
        unawaited(syncReminders());
      }
      return false;
    }
  }

  Future<bool> save({
    PersonalTask? task,
    required String title,
    required String description,
    required DateTime dueAt,
  }) => _mutate(
    (s) => task == null
        ? repository.create(
            workspaceId: s.workspaceId,
            title: title.trim(),
            description: description.trim(),
            dueAt: dueAt,
          )
        : repository.update(
            task,
            title: title.trim(),
            description: description.trim(),
            dueAt: dueAt.isAtSameMomentAs(task.dueAt) ? null : dueAt,
          ),
    changedTask: task,
  );

  Future<bool> toggle(PersonalTask task) => _mutate(
    (_) => repository.update(task, completed: !task.completed),
    changedTask: task,
  );
  Future<bool> remove(PersonalTask task) =>
      _mutate((_) => repository.remove(task), changedTask: task);

  Future<PersonalTask?> resolveTap(String ownerId, String taskId) async {
    final generation = _generation;
    if (scope?.userId != ownerId) return null;
    try {
      final task = await repository.get(taskId);
      return _valid(generation) && task.ownerId == ownerId ? task : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    _generation++;
    await _reminderQueue;
    await reminders.close();
    return super.close();
  }
}
