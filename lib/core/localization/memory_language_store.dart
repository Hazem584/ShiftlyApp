import 'package:shiftly/core/localization/language_preference_store.dart';

class MemoryLanguageStore implements LanguagePreferenceStore {
  MemoryLanguageStore([this.languageCode]);
  @override
  String? languageCode;
  @override
  Future<void> save(String? languageCode) async {
    this.languageCode = languageCode;
  }
}
