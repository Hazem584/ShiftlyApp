import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import 'communication_actions.dart';
import 'communication_page.dart';
import 'preference_editor_screen.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});
  @override
  Widget build(BuildContext context) => CommunicationPage(
    title: 'Preferences',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: ListTile(
            key: const Key('language-selector'),
            leading: const Icon(Icons.language),
            title: Text(context.tr('Language')),
            subtitle: Text(context.tr('English · العربية')),
            onTap: () => openCommunicationPage(
              context,
              const PreferenceEditorScreen(language: true),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            key: const Key('theme-selector'),
            leading: const Icon(Icons.palette_outlined),
            title: Text(context.tr('Appearance')),
            subtitle: Text(context.tr('Light, dark or your device theme')),
            onTap: () =>
                openCommunicationPage(context, const PreferenceEditorScreen()),
          ),
        ),
      ],
    ),
  );
}
