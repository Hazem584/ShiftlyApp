import 'package:equatable/equatable.dart';

enum AppLanguage { system, english, arabic }

class LanguageSettings extends Equatable {
  const LanguageSettings({
    this.language = AppLanguage.system,
    this.saving = false,
    this.saveFailed = false,
  });
  final AppLanguage language;
  final bool saving;
  final bool saveFailed;
  String? get languageCode => switch (language) {
    AppLanguage.system => null,
    AppLanguage.english => 'en',
    AppLanguage.arabic => 'ar',
  };
  @override
  List<Object?> get props => [language, saving, saveFailed];
}
