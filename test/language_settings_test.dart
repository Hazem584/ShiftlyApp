import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_preference_store.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/core/localization/preferences_language_store.dart';

class _PendingStore implements LanguagePreferenceStore {
  final pending = Completer<void>();
  int writes = 0;
  @override
  String? get languageCode => 'en';
  @override
  Future<void> save(String? languageCode) {
    writes++;
    return pending.future;
  }
}

void main() {
  test(
    'language survives restart and device option removes explicit override',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = PreferencesLanguageStore(
        await SharedPreferences.getInstance(),
      );
      final first = LanguageCubit(store);
      await first.select(AppLanguage.arabic);
      await first.close();
      final restarted = LanguageCubit(store);
      expect(restarted.state.language, AppLanguage.arabic);
      await restarted.select(AppLanguage.system);
      expect(store.languageCode, isNull);
      expect(restarted.state.languageCode, isNull);
      await restarted.close();
    },
  );

  test('unsupported stored locale follows device language', () async {
    final cubit = LanguageCubit(MemoryLanguageStore('unknown'));
    expect(cubit.state.language, AppLanguage.system);
    await cubit.close();
  });

  test('pending save prevents competing writes; failed save preserves current language', () async {
    final store = _PendingStore();
    final cubit = LanguageCubit(store);
    final saving = cubit.select(AppLanguage.arabic);
    expect(cubit.state.saving, isTrue);
    await cubit.select(AppLanguage.system);
    expect(store.writes, 1);
    store.pending.completeError(StateError('disk unavailable'));
    await saving;
    expect(cubit.state.language, AppLanguage.english);
    expect(cubit.state.saveFailed, isTrue);
    expect(cubit.state.saving, isFalse);
    await cubit.close();
  });

  test(
    'finishing a save after disposal does not emit into closed controller',
    () async {
      final store = _PendingStore();
      final cubit = LanguageCubit(store);
      final saving = cubit.select(AppLanguage.arabic);
      await cubit.close();
      store.pending.complete();
      await saving;
      expect(cubit.isClosed, isTrue);
    },
  );
}
