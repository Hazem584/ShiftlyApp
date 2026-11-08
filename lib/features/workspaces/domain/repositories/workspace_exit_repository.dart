abstract interface class WorkspaceExitRepository {
  Future<void> leaveWorkspace(String workspaceId, {String? confirmation});
}
