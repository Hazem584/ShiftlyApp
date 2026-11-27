import '../domain/personal_task.dart';
import '../domain/task_repository.dart';
import 'memory_task_helpers.dart';

class MemoryTaskRepository implements TaskRepository {
  final _items = <String, PersonalTask>{};
  @override
  Future<TaskPage> list({required bool completed, required int page}) async {
    final items = _items.values.where((t) => t.completed == completed).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return TaskPage(
      items.skip((page - 1) * 30).take(30).toList(),
      items.length,
    );
  }

  @override
  Future<List<PersonalTask>> upcoming() async => _items.values
      .where(
        (t) =>
            !t.completed &&
            (t.scheduledDates.any(
                  (date) => date
                      .add(Duration(minutes: t.durationMinutes ?? 0))
                      .isAfter(DateTime.now()),
                ) ||
                (t.endsAt?.isAfter(DateTime.now()) ?? false)),
      )
      .toList();
  @override
  Future<PersonalTask> get(String id) async => _items[id]!;
  @override
  Future<void> create({
    required String workspaceId,
    required String title,
    required String description,
    required DateTime dueAt,
    int? durationMinutes,
    bool remindDayBefore = false,
    bool remindHourBefore = false,
    List<DateTime> additionalDueAts = const [],
  }) async {
    final created = buildCreatedMemoryTask(
      workspaceId: workspaceId,
      title: title,
      description: description,
      dueAt: dueAt,
      durationMinutes: durationMinutes,
      remindDayBefore: remindDayBefore,
      remindHourBefore: remindHourBefore,
      additionalDueAts: additionalDueAts,
    );
    _items[created.id] = created;
  }

  @override
  Future<void> update(
    PersonalTask task, {
    String? title,
    String? description,
    DateTime? dueAt,
    bool? completed,
    int? durationMinutes,
    bool? remindDayBefore,
    bool? remindHourBefore,
    List<DateTime>? additionalDueAts,
  }) async {
    _items[task.id] = buildUpdatedMemoryTask(
      task,
      title: title,
      description: description,
      dueAt: dueAt,
      completed: completed,
      durationMinutes: durationMinutes,
      remindDayBefore: remindDayBefore,
      remindHourBefore: remindHourBefore,
      additionalDueAts: additionalDueAts,
    );
  }

  @override
  Future<void> remove(PersonalTask task) async => _items.remove(task.id);
  @override
  Future<void> register(
    String installationId,
    List<PersonalTask> scheduled,
  ) async {}
}
