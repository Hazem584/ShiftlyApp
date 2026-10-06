part of '../../workspace_repository.dart';

abstract interface class WorkspaceRepository {
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  });
  Future<List<WorkspaceRecord>> listWorkspaces();
  Future<WorkspaceRecord> getWorkspace(String workspaceId);
}
