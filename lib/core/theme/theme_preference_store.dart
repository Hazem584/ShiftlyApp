abstract interface class ThemePreferenceStore {
  String? get mode;
  Future<void> save(String mode);
}
