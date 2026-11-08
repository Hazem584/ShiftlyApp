import 'package:shiftly/features/workspaces/domain/repositories/workspace_exit_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

class MockWorkspaceRepository
    implements WorkspaceRepository, WorkspaceExitRepository {
  final List<WorkspaceRecord> _items = [];
  @override
  Future<void> leaveWorkspace(
    String workspaceId, {
    String? confirmation,
  }) async {
    final workspace = await getWorkspace(workspaceId);
    if (workspace.role == WorkspaceAccessRole.manager &&
        confirmation != workspace.name) {
      throw StateError('Confirmation required');
    }
    _items.removeWhere((e) => e.id == workspaceId);
  }

  @override
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  }) async {
    final item = WorkspaceRecord(
      id: 'workspace-${_items.length + 1}',
      name: name.trim(),
      code: 'PREVIEW${_items.length + 1}',
      timezone: timezone?.trim().isNotEmpty == true
          ? timezone!.trim()
          : 'Africa/Cairo',
      role: WorkspaceAccessRole.manager,
      status: WorkspaceAccessStatus.active,
    );
    _items.add(item);
    return item;
  }

  @override
  Future<WorkspaceRecord> getWorkspace(String workspaceId) async =>
      _items.singleWhere((item) => item.id == workspaceId);
  @override
  Future<List<WorkspaceRecord>> listWorkspaces() async =>
      List.unmodifiable(_items);
}
