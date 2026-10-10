import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shiftly/core/localization/arabic_translations.dart';

/// English source messages are stable lookup keys; user content is never passed here.
class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;
  static const supportedLocales = [Locale('en'), Locale('ar')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  String text(String source, [Map<String, String> arguments = const {}]) {
    final result = locale.languageCode == 'ar'
        ? arabicTranslations[source] ?? source
        : source;
    return result.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (match) => arguments[match[1]] ?? match[0]!,
    );
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedContext on BuildContext {
  String tr(String source, [Map<String, String> arguments = const {}]) =>
      AppLocalizations.of(this).text(source, arguments);
}
