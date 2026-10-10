import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';

import 'theme_cubit.dart';
import 'theme_settings.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ThemeCubit?>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocConsumer<ThemeCubit, ThemeSettings>(
      bloc: cubit,
      listenWhen: (previous, current) =>
          current.saveFailed && !previous.saveFailed,
      listener: (context, _) => ToastService.error(
        context,
        message: 'Could not save appearance. Please try again.',
      ),
      builder: (context, state) => PopupMenuButton<ThemeMode>(
        key: const Key('theme-selector'),
        enabled: !state.saving,
        tooltip: context.tr('Appearance'),
        icon: Icon(switch (state.mode) {
          ThemeMode.light => Icons.light_mode_outlined,
          ThemeMode.dark => Icons.dark_mode_outlined,
          ThemeMode.system => Icons.brightness_auto_outlined,
        }),
        onSelected: cubit.select,
        itemBuilder: (context) => [
          for (final entry in const {
            ThemeMode.system: 'Use device theme',
            ThemeMode.light: 'Light',
            ThemeMode.dark: 'Dark',
          }.entries)
            CheckedPopupMenuItem(
              value: entry.key,
              checked: state.mode == entry.key,
              child: Text(context.tr(entry.value)),
            ),
        ],
      ),
    );
  }
}
