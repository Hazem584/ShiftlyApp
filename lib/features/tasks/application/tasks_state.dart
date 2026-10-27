import '../domain/personal_task.dart';
import '../domain/task_reminders.dart';

class TasksState {
  const TasksState({
    this.items = const [],
    this.total = 0,
    this.totalsAvailable = false,
    this.openTotal,
    this.doneTotal,
    this.page = 1,
    this.completed = false,
    this.loading = false,
    this.saving = false,
    this.error,
    this.reminderPermission = TaskReminderPermission.disabled,
    this.reminderError = false,
  });
  final List<PersonalTask> items;
  final int total, page;
  final int? openTotal, doneTotal;
  final bool totalsAvailable;
  final bool completed, loading, saving, reminderError;
  final String? error;
  final TaskReminderPermission reminderPermission;
  TasksState copy({
    List<PersonalTask>? items,
    int? total,
    bool? totalsAvailable,
    int? openTotal,
    int? doneTotal,
    int? page,
    bool? completed,
    bool? loading,
    bool? saving,
    String? error,
    TaskReminderPermission? reminderPermission,
    bool? reminderError,
  }) => TasksState(
    items: items ?? this.items,
    total: total ?? this.total,
    totalsAvailable: totalsAvailable ?? this.totalsAvailable,
    openTotal: openTotal ?? this.openTotal,
    doneTotal: doneTotal ?? this.doneTotal,
    page: page ?? this.page,
    completed: completed ?? this.completed,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    error: error,
    reminderPermission: reminderPermission ?? this.reminderPermission,
    reminderError: reminderError ?? this.reminderError,
  );
}
