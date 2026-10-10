import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';

class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.language_rounded),
    title: Text(context.tr('Language')),
    subtitle: Text(
      context.tr('Choose Arabic, English or your device language'),
    ),
    trailing: const LanguageSelector(),
  );
}
