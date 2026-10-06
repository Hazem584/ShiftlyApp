part of '../../active_workspace_storage.dart';

abstract interface class ActiveWorkspaceStorage {
  Future<String?> read();
  Future<void> write(String workspaceId);
  Future<void> clear();
}
