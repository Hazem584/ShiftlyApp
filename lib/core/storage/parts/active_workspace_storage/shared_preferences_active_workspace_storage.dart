part of '../../active_workspace_storage.dart';

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
