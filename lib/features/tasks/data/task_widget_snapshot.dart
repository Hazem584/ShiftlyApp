import '../domain/personal_task.dart';

Map<String, Object?> buildTaskWidgetSnapshot(
  String ownerId,
  TaskPage page,
  DateTime now,
) {
  final tasks =
      page.items.where((t) => !t.completed && t.ownerId == ownerId).toList()
        ..sort((a, b) => a.nextDueAt(now).compareTo(b.nextDueAt(now)));
  return {
    'ownerId': ownerId,
    'total': page.total,
    'updatedAt': now.millisecondsSinceEpoch,
    'expiresAt': now.add(const Duration(hours: 24)).millisecondsSinceEpoch,
    'tasks': tasks
        .take(3)
        .map(
          (t) => {
            'id': t.id,
            'title': t.title,
            'dueAt': t.nextDueAt(now).millisecondsSinceEpoch,
            'dueDates': t.scheduledDates
                .map((d) => d.millisecondsSinceEpoch)
                .toList(),
            'durationMs': (t.durationMinutes ?? 0) * 60000,
            'endsAt': t
                .nextDueAt(now)
                .add(Duration(minutes: t.durationMinutes ?? 0))
                .millisecondsSinceEpoch,
          },
        )
        .toList(),
  };
}
