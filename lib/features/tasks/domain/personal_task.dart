import 'personal_task_parser.dart';

class PersonalTask {
  const PersonalTask({
    required this.id,
    required this.ownerId,
    required this.workspaceId,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.revision,
    required this.completed,
    this.durationMinutes,
    this.remindDayBefore = false,
    this.remindHourBefore = false,
    this.additionalDueAts = const [],
  });
  final String id, ownerId, workspaceId, title, description;
  final DateTime dueAt;
  final int revision;
  final bool completed;
  final int? durationMinutes;
  final bool remindDayBefore;
  final bool remindHourBefore;
  final List<DateTime> additionalDueAts;

  List<DateTime> get scheduledDates =>
      [dueAt, ...additionalDueAts]..sort((a, b) => a.compareTo(b));

  DateTime nextDueAt(DateTime now) {
    final dates = scheduledDates;
    return dates.firstWhere(
      (date) => date.add(Duration(minutes: durationMinutes ?? 0)).isAfter(now),
      orElse: () => dates.last,
    );
  }

  DateTime? get endsAt => durationMinutes == null
      ? null
      : dueAt.add(Duration(minutes: durationMinutes!));

  bool get overdue =>
      !completed &&
      scheduledDates.last
          .add(Duration(minutes: durationMinutes ?? 0))
          .isBefore(DateTime.now());

  factory PersonalTask.fromJson(Map<String, Object?> json) =>
      parsePersonalTask(json);
}

class TaskPage {
  const TaskPage(this.items, this.total);
  final List<PersonalTask> items;
  final int total;
}
