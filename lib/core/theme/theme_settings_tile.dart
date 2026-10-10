import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import 'theme_selector.dart';

class ThemeSettingsTile extends StatelessWidget {
  const ThemeSettingsTile({super.key});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.palette_outlined),
    title: Text(context.tr('Appearance')),
    subtitle: Text(context.tr('Light, dark or your device theme')),
    trailing: const ThemeSelector(),
  );
}
