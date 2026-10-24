import 'personal_task.dart';

enum TaskAlarmKind { due, advance, hour, end }

class TaskAlarm {
  const TaskAlarm(this.task, this.kind, this.at, {this.occurrenceDueAt});
  final PersonalTask task;
  final TaskAlarmKind kind;
  final DateTime at;
  final DateTime? occurrenceDueAt;
  String get wireKind => kind.name.toUpperCase();
  String get key =>
      '${task.id}:$wireKind${occurrenceDueAt == null ? '' : ':${occurrenceDueAt!.toUtc().toIso8601String()}'}';

  static List<TaskAlarm> upcoming(PersonalTask task, DateTime now) {
    if (task.completed) return [];
    final result = <TaskAlarm>[];
    for (final due in task.scheduledDates) {
      final occurrence = due.isAtSameMomentAs(task.dueAt) ? null : due;
      result.addAll([
        TaskAlarm(task, TaskAlarmKind.due, due, occurrenceDueAt: occurrence),
        if (task.remindDayBefore)
          TaskAlarm(
            task,
            TaskAlarmKind.advance,
            due.subtract(const Duration(hours: 24)),
            occurrenceDueAt: occurrence,
          ),
        if (task.remindHourBefore)
          TaskAlarm(
            task,
            TaskAlarmKind.hour,
            due.subtract(const Duration(hours: 1)),
            occurrenceDueAt: occurrence,
          ),
        if (task.durationMinutes != null)
          TaskAlarm(
            task,
            TaskAlarmKind.end,
            due.add(Duration(minutes: task.durationMinutes!)),
            occurrenceDueAt: occurrence,
          ),
      ]);
    }
    return result.where((alarm) => alarm.at.isAfter(now)).toList();
  }
}
