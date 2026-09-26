import 'package:shiftly/features/workspaces/data/workspace_repository.dart';

class MockWorkspaceRepository implements WorkspaceRepository {
  final List<WorkspaceRecord> _items = [];
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
