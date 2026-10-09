import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/onboarding/domain/repositories/onboarding_storage.dart';

class PreferencesOnboardingStorage implements OnboardingStorage {
  PreferencesOnboardingStorage(this.preferences);
  static const key = 'shiftly.onboarding.completed.v1';
  final SharedPreferences preferences;

  @override
  Future<bool> readCompleted() async {
    await preferences.reload();
    return preferences.getBool(key) ?? false;
  }

  @override
  Future<void> complete() async {
    if (!await preferences.setBool(key, true)) {
      // SharedPreferences updates its memory cache before the platform result.
      await preferences.reload();
      throw StateError('Onboarding completion was not saved');
    }
  }
}
