import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';

class PreferencesLanguageStore implements LanguagePreferenceStore {
  PreferencesLanguageStore(this._preferences);
  static const key = 'app.language';
  final SharedPreferences _preferences;

  @override
  String? get languageCode => _preferences.getString(key);

  @override
  Future<void> save(String? languageCode) async {
    final saved = languageCode == null
        ? await _preferences.remove(key)
        : await _preferences.setString(key, languageCode);
    if (!saved) throw StateError('Language preference was not saved');
  }
}
