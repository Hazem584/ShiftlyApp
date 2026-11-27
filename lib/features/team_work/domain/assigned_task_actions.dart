import 'team_work_models.dart';
import 'team_work_repository.dart';

class AssignedTaskActions {
  const AssignedTaskActions(this._repository);

  final TeamWorkRepository _repository;

  Future<WorkPage<AssignedTeamTask>> load(String workspaceId) async {
    final tasks = await _repository.assignedTasks(workspaceId);
    return WorkPage(tasks, tasks.length);
  }

  Future<void> update(String workspaceId, String id, String status) =>
      _repository.updateAssignedTaskStatus(workspaceId, id, status);

  Future<void> remind(String workspaceId, String id) =>
      _repository.remindAssignedTask(workspaceId, id);
}
