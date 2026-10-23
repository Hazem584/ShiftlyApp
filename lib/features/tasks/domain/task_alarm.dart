import 'personal_task.dart';

enum TaskAlarmKind { due, advance, hour, end }

class TaskAlarm {
  const TaskAlarm(this.task, this.kind, this.at);
  final PersonalTask task;
  final TaskAlarmKind kind;
  final DateTime at;
  String get wireKind => kind.name.toUpperCase();
  String get key => '${task.id}:$wireKind';

  static List<TaskAlarm> upcoming(PersonalTask task, DateTime now) {
    if (task.completed) return [];
    return [
      TaskAlarm(task, TaskAlarmKind.due, task.dueAt),
      if (task.remindDayBefore)
        TaskAlarm(
          task,
          TaskAlarmKind.advance,
          task.dueAt.subtract(const Duration(hours: 24)),
        ),
      if (task.remindHourBefore)
        TaskAlarm(
          task,
          TaskAlarmKind.hour,
          task.dueAt.subtract(const Duration(hours: 1)),
        ),
      if (task.endsAt != null) TaskAlarm(task, TaskAlarmKind.end, task.endsAt!),
    ].where((alarm) => alarm.at.isAfter(now)).toList();
  }
}
