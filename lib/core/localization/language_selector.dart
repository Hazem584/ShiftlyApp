import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_settings.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LanguageCubit?>();
    if (cubit == null) return const SizedBox.shrink();
    return BlocConsumer<LanguageCubit, LanguageSettings>(
      bloc: cubit,
      listenWhen: (_, current) => current.saveFailed,
      listener: (context, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Could not save language. Please try again.'),
          ),
        ),
      ),
      builder: (context, state) => PopupMenuButton<AppLanguage>(
        key: const Key('language-selector'),
        tooltip: context.tr('Language'),
        enabled: !state.saving,
        initialValue: state.language,
        onSelected: cubit.select,
        icon: const Icon(Icons.translate_rounded),
        itemBuilder: (context) => [
          for (final language in AppLanguage.values)
            CheckedPopupMenuItem(
              value: language,
              checked: state.language == language,
              child: Text(switch (language) {
                AppLanguage.system => context.tr('Device language'),
                AppLanguage.english => 'English',
                AppLanguage.arabic => 'العربية',
              }),
            ),
        ],
      ),
    );
  }
}
