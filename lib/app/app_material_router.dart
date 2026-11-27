import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:shiftly/app/app_composition.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_cubit.dart';
import 'package:shiftly/core/localization/language_settings.dart';
import 'package:shiftly/core/monitoring/monitoring_gate.dart';
import 'package:shiftly/core/platform/platform_gate.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/theme/employee_appearance.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';
import 'package:shiftly/core/theme/theme_settings.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/device_sessions/application/device_sessions_scope.dart';

Widget buildShiftlyMaterialApp({
  required AppComposition composition,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
  required GetIt? locator,
  required Dio Function(AppConfig) platformStatusClient,
}) {
  return BlocBuilder<LanguageCubit, LanguageSettings>(
    buildWhen: (previous, current) => previous.language != current.language,
    builder: (context, language) => BlocBuilder<ThemeCubit, ThemeSettings>(
      buildWhen: (previous, current) => previous.mode != current.mode,
      builder: (context, appearance) => MaterialApp.router(
        locale: language.languageCode == null
            ? null
            : Locale(language.languageCode!),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        title: AppStrings.appName,
        scaffoldMessengerKey: messengerKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: appearance.mode,
        routerConfig: composition.router,
        builder: (context, child) {
          final content = EmployeeAppearance(child: child!);
          if (locator == null) return content;
          return DeviceSessionsScope(
            api: locator<Dio>(),
            authentication: locator<AuthenticationService>(),
            child: MonitoringGate(
              apiClient: locator<Dio>(),
              authentication: locator<AuthenticationService>(),
              child: PlatformGate(
                statusClient: platformStatusClient(locator<AppConfig>()),
                apiClient: locator<Dio>(),
                authentication: locator<AuthenticationService>(),
                child: content,
              ),
            ),
          );
        },
      ),
    ),
  );
}
