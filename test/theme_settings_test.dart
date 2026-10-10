import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/theme/preferences_theme_store.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';
import 'package:shiftly/core/theme/theme_preference_store.dart';

class _FailingStore implements ThemePreferenceStore {
  @override
  String? get mode => 'dark';
  @override
  Future<void> save(String mode) async => throw StateError('disk unavailable');
}

void main() {
  test('appearance persists across launches and defaults to system', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = ThemeCubit(PreferencesThemeStore(prefs));
    expect(cubit.state.mode, ThemeMode.system);
    await cubit.select(ThemeMode.dark);
    final reopened = ThemeCubit(PreferencesThemeStore(prefs));
    expect(reopened.state.mode, ThemeMode.dark);
    await reopened.select(ThemeMode.system);
    expect(prefs.getString('app.theme'), 'system');
    await cubit.close();
    await reopened.close();
  });
  test('failed save restores the previous mode', () async {
    final cubit = ThemeCubit(_FailingStore());
    await cubit.select(ThemeMode.light);
    expect(cubit.state.mode, ThemeMode.dark);
    expect(cubit.state.saveFailed, isTrue);
    await cubit.close();
  });
  testWidgets('system mode follows device brightness and uses dark surfaces', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    late ThemeData actual;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        home: Builder(
          builder: (context) {
            actual = Theme.of(context);
            return const Scaffold(body: Text('Shiftly'));
          },
        ),
      ),
    );
    expect(actual.brightness, Brightness.dark);
    expect(actual.scaffoldBackgroundColor.computeLuminance(), lessThan(.1));
    expect(actual.colorScheme.onSurface.computeLuminance(), greaterThan(.7));
    expect(actual.colorScheme.primary, isNot(actual.colorScheme.onPrimary));
  });
}
