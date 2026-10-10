import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_preference_store.dart';
import 'theme_settings.dart';

class ThemeCubit extends Cubit<ThemeSettings> {
  ThemeCubit(this._store)
    : super(
        ThemeSettings(
          mode: switch (_store.mode) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
        ),
      );
  final ThemePreferenceStore _store;
  Future<void> select(ThemeMode mode) async {
    if (state.saving || state.mode == mode) return;
    final previous = state.mode;
    emit(ThemeSettings(mode: mode, saving: true));
    try {
      await _store.save(mode.name);
      if (!isClosed) emit(ThemeSettings(mode: mode));
    } catch (_) {
      if (!isClosed) emit(ThemeSettings(mode: previous, saveFailed: true));
    }
  }
}
