abstract interface class OnboardingStorage {
  Future<bool> readCompleted();
  Future<void> complete();
}
