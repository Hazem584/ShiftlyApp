import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/manager_performance/domain/repositories/manager_intent_storage.dart';

class PreferencesManagerIntentStorage implements ManagerIntentStorage {
  PreferencesManagerIntentStorage(this._preferences);
  final SharedPreferences _preferences;
  // One unresolved operation blocks all conflicting manager mutations. The
  // stored intent additionally includes target membership and exact action.
  String _key(FeatureSessionScope scope) =>
      'manager_points_intent_v1:${scope.userId}:${scope.workspaceId}:${scope.membershipId}';
  @override
  Future<String?> read(FeatureSessionScope scope) async =>
      _preferences.getString(_key(scope));
  @override
  Future<void> write(FeatureSessionScope scope, String value) async {
    if (!await _preferences.setString(_key(scope), value)) {
      throw StateError('Could not save operation');
    }
  }

  @override
  Future<void> clear(FeatureSessionScope scope, String value) async {
    if (await read(scope) != value) {
      return;
    }
    if (!await _preferences.remove(_key(scope)) &&
        _preferences.containsKey(_key(scope))) {
      throw StateError('Could not clear saved operation');
    }
  }
}
