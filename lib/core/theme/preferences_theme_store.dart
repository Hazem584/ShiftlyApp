import 'package:shared_preferences/shared_preferences.dart';

import 'theme_preference_store.dart';

class PreferencesThemeStore implements ThemePreferenceStore {
  PreferencesThemeStore(this._preferences);
  final SharedPreferences _preferences;
  static const key = 'app.theme';
  @override
  String? get mode => _preferences.getString(key);
  @override
  Future<void> save(String mode) async {
    if (!await _preferences.setString(key, mode)) {
      throw StateError('Could not save appearance');
    }
  }
}
