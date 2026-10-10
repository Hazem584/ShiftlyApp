abstract interface class LanguagePreferenceStore {
  String? get languageCode;
  Future<void> save(String? languageCode);
}
