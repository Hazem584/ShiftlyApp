import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';
import 'package:uuid/uuid.dart';

class PreferencesPushStore implements PushPreferenceStore {
  PreferencesPushStore(this._preferences);
  final SharedPreferences _preferences;

  @override
  Future<String> installationId() async {
    const key = 'shiftly.push.installation.v1';
    final saved = _preferences.getString(key);
    if (saved != null) return saved;
    final value = const Uuid().v4();
    if (!await _preferences.setString(key, value)) {
      throw StateError('Could not save notification settings');
    }
    return value;
  }

  @override
  Future<bool> enabled(String userId) async =>
      _preferences.getBool('shiftly.push.enabled.v1.$userId') ?? false;

  @override
  Future<void> setEnabled(String userId, bool enabled) async {
    if (!await _preferences.setBool(
      'shiftly.push.enabled.v1.$userId',
      enabled,
    )) {
      throw StateError('Could not save notification settings');
    }
  }
}
