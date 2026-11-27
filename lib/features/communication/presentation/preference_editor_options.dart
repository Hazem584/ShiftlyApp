import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/features/communication/presentation/settings_choice_card.dart';

const _languageOptions = [
  (AppLanguage.english, 'English', 'Left to right'),
  (AppLanguage.arabic, 'العربية', 'Arabic · من اليمين إلى اليسار'),
  (AppLanguage.system, 'Use device setting', 'Follows your system language'),
];

const _themeOptions = [
  (ThemeMode.system, 'Use device setting', 'Follows your system'),
  (ThemeMode.light, 'Light', 'Bright surfaces and dark text'),
  (ThemeMode.dark, 'Dark', 'Dark surfaces for low-light use'),
];

Widget buildPreferenceEditorList(
  BuildContext context, {
  required bool isLanguage,
  required AppLanguage language,
  required ThemeMode mode,
  required bool saving,
  required String? error,
  required ValueChanged<AppLanguage> onSelectLanguage,
  required ValueChanged<ThemeMode> onSelectMode,
}) => ListView(
  padding: const EdgeInsets.all(24),
  children: [
    if (isLanguage)
      for (final item in _languageOptions)
        SettingsChoiceCard(
          key: Key('language-${item.$1.name}'),
          title: context.tr(item.$2),
          subtitle: context.tr(item.$3),
          selected: language == item.$1,
          onTap: saving ? null : () => onSelectLanguage(item.$1),
        ),
    if (!isLanguage)
      for (final item in _themeOptions)
        SettingsChoiceCard(
          key: Key('appearance-${item.$1.name}'),
          title: context.tr(item.$2),
          subtitle: context.tr(item.$3),
          selected: mode == item.$1,
          onTap: saving ? null : () => onSelectMode(item.$1),
        ),
    if (isLanguage)
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.tr(
              'The interface will update after you choose a language.',
            ),
          ),
        ),
      ),
    if (error != null)
      Text(
        context.tr(error),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
  ],
);
