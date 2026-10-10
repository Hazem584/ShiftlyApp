abstract interface class PushPreferenceStore {
  Future<String> installationId();
  Future<bool> enabled(String userId);
  Future<void> setEnabled(String userId, bool enabled);
}
