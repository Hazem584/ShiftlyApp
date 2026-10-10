import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';
import 'package:shiftly/core/localization/language_settings.dart';

class LanguageCubit extends Cubit<LanguageSettings> {
  LanguageCubit(this._store)
    : super(
        LanguageSettings(
          language: switch (_store.languageCode) {
            'ar' => AppLanguage.arabic,
            'en' => AppLanguage.english,
            _ => AppLanguage.system,
          },
        ),
      );
  final LanguagePreferenceStore _store;

  Future<void> select(AppLanguage language) async {
    if (state.saving || state.language == language) return;
    final previous = state.language;
    emit(LanguageSettings(language: previous, saving: true));
    try {
      final next = LanguageSettings(language: language);
      await _store.save(next.languageCode);
      if (!isClosed) emit(next);
    } catch (_) {
      if (!isClosed) {
        emit(LanguageSettings(language: previous, saveFailed: true));
      }
    }
  }
}
