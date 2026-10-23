import 'personal_task.dart';

enum TaskReminderPermission { unsupported, disabled, approximate, exact }

abstract interface class TaskReminders {
  Future<TaskReminderPermission> permission(
    String userId, {
    bool request = false,
  });

  /// Returns precise alarms installed successfully. Preserve old alarms when
  /// server acknowledgements could not be withdrawn, without exceeding the cap.
  Future<List<PersonalTask>> replace(
    String userId,
    List<PersonalTask> tasks, {
    bool preserveExisting = false,
  });
  Future<void> clear();
  Future<void> cancel(String taskId);
  Future<String?> installationId();
  Future<void> close();
}

class NoTaskReminders implements TaskReminders {
  const NoTaskReminders();
  @override
  Future<TaskReminderPermission> permission(
    String userId, {
    bool request = false,
  }) async => TaskReminderPermission.unsupported;
  @override
  Future<List<PersonalTask>> replace(
    String userId,
    List<PersonalTask> tasks, {
    bool preserveExisting = false,
  }) async => [];
  @override
  Future<void> clear() async {}
  @override
  Future<void> cancel(String taskId) async {}
  @override
  Future<String?> installationId() async => null;
  @override
  Future<void> close() async {}
}
