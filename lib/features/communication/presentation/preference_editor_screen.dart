import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';
import 'package:shiftly/features/communication/presentation/preference_editor_options.dart';

import 'communication_page.dart';

class PreferenceEditorScreen extends StatefulWidget {
  const PreferenceEditorScreen({this.language = false, super.key});
  final bool language;
  @override
  State<PreferenceEditorScreen> createState() => _PreferenceEditorScreenState();
}

class _PreferenceEditorScreenState extends State<PreferenceEditorScreen> {
  late AppLanguage _language = context.read<LanguageCubit>().state.language;
  late ThemeMode _mode = context.read<ThemeCubit>().state.mode;
  bool _saving = false;
  String? _error;

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
      child: buildPreferenceEditorList(
        context,
        isLanguage: widget.language,
        language: _language,
        mode: _mode,
        saving: _saving,
        error: _error,
        onSelectLanguage: (v) => setState(() => _language = v),
        onSelectMode: (v) => setState(() => _mode = v),
      ),
    ),
  );
}
