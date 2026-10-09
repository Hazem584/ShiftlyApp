import 'package:shiftly/features/workspaces/domain/entities/workspace_models.dart';

export 'package:shiftly/features/workspaces/domain/entities/workspace_models.dart';

abstract interface class WorkspaceRepository {
  Future<WorkspaceRecord> createWorkspace({
    required String name,
    String? timezone,
  });
  Future<List<WorkspaceRecord>> listWorkspaces();
  Future<WorkspaceRecord> getWorkspace(String workspaceId);
}
