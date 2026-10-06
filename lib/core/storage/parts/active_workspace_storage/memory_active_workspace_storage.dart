part of '../../active_workspace_storage.dart';

class MemoryActiveWorkspaceStorage implements ActiveWorkspaceStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String workspaceId) async => value = workspaceId;
}
