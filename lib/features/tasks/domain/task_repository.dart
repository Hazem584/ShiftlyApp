import 'personal_task.dart';

abstract interface class TaskRepository {
  Future<TaskPage> list({required bool completed, required int page});
  Future<List<PersonalTask>> upcoming();
  Future<PersonalTask> get(String id);
  Future<void> create({
    required String workspaceId,
    required String title,
    required String description,
    required DateTime dueAt,
    int? durationMinutes,
    bool remindDayBefore = false,
    bool remindHourBefore = false,
  });
  Future<void> update(
    PersonalTask task, {
    String? title,
    String? description,
    DateTime? dueAt,
    bool? completed,
    int? durationMinutes,
    bool? remindDayBefore,
    bool? remindHourBefore,
  });
  Future<void> remove(PersonalTask task);
  Future<void> register(String installationId, List<PersonalTask> scheduled);
}
