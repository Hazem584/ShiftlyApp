import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';

import 'communication_page.dart';
import 'settings_choice_card.dart';

class PreferenceEditorScreen extends StatefulWidget {
  const PreferenceEditorScreen({this.language = false, super.key});
  final bool language;
  @override
  State<PreferenceEditorScreen> createState() => _PreferenceEditorScreenState();
}

class _PreferenceEditorScreenState extends State<PreferenceEditorScreen> {
  late AppLanguage _language;
  late ThemeMode _mode;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _language = context.read<LanguageCubit>().state.language;
    _mode = context.read<ThemeCubit>().state.mode;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    if (widget.language) {
      await context.read<LanguageCubit>().select(_language);
    } else {
      await context.read<ThemeCubit>().select(_mode);
    }
    if (!mounted) return;
    final failed = widget.language
        ? context.read<LanguageCubit>().state.saveFailed
        : context.read<ThemeCubit>().state.saveFailed;
    if (failed) {
      setState(() {
        _saving = false;
        _error = 'Could not save your preference. Try again.';
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: CommunicationPage(
      title: widget.language ? 'Language' : 'Appearance',
      footer: FilledButton(
        key: Key(widget.language ? 'apply-language' : 'apply-appearance'),
        onPressed: _saving ? null : _save,
        child: Text(
          context.tr(
            _saving
                ? 'Saving…'
                : widget.language
                ? 'Apply language'
                : 'Apply appearance',
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.language)
            for (final item in const [
              (AppLanguage.english, 'English', 'Left to right'),
              (AppLanguage.arabic, 'العربية', 'Arabic · من اليمين إلى اليسار'),
              (
                AppLanguage.system,
                'Use device setting',
                'Follows your system language',
              ),
            ])
              SettingsChoiceCard(
                key: Key('language-${item.$1.name}'),
                title: context.tr(item.$2),
                subtitle: context.tr(item.$3),
                selected: _language == item.$1,
                onTap: _saving
                    ? null
                    : () => setState(() => _language = item.$1),
              ),
          if (!widget.language)
            for (final item in const [
              (ThemeMode.system, 'Use device setting', 'Follows your system'),
              (ThemeMode.light, 'Light', 'Bright surfaces and dark text'),
              (ThemeMode.dark, 'Dark', 'Dark surfaces for low-light use'),
            ])
              SettingsChoiceCard(
                key: Key('appearance-${item.$1.name}'),
                title: context.tr(item.$2),
                subtitle: context.tr(item.$3),
                selected: _mode == item.$1,
                onTap: _saving ? null : () => setState(() => _mode = item.$1),
              ),
          if (widget.language)
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
          if (_error != null)
            Text(
              context.tr(_error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
  );
}
