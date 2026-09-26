import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ActiveWorkspaceStorage {
  Future<String?> read();
  Future<void> write(String workspaceId);
  Future<void> clear();
}

class SharedPreferencesActiveWorkspaceStorage
    implements ActiveWorkspaceStorage {
  SharedPreferencesActiveWorkspaceStorage(this._preferences);

  static const _key = 'active_workspace_id';
  final SharedPreferences _preferences;

  @override
  Future<String?> read() async => _preferences.getString(_key);

  @override
  Future<void> write(String workspaceId) async {
    await _preferences.setString(_key, workspaceId);
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_key);
  }
}

class MemoryActiveWorkspaceStorage implements ActiveWorkspaceStorage {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String workspaceId) async => value = workspaceId;
}
