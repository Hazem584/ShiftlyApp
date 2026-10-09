import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';

/// Used only by explicit previews and isolated tests.
class MemoryOnboardingStorage implements OnboardingStorage {
  MemoryOnboardingStorage({this.completed = true});
  bool completed;
  @override
  Future<bool> readCompleted() async => completed;
  @override
  Future<void> complete() async {
    completed = true;
  }
}
