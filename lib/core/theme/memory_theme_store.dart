import 'theme_preference_store.dart';

class MemoryThemeStore implements ThemePreferenceStore {
  @override
  String? mode;
  @override
  Future<void> save(String value) async => mode = value;
}
