import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/presentation/design/access_theme.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

import 'access_test_fixture.dart';

Widget accessHarness(
  AccessTestFixture fixture,
  Widget child, {
  String language = 'en',
  bool dark = false,
  double scale = 1,
  EdgeInsets insets = EdgeInsets.zero,
  GlobalKey? boundary,
}) => MultiBlocProvider(
  providers: [
    BlocProvider<SessionCoordinator>.value(value: fixture.session),
    BlocProvider<WorkspacesCubit>.value(value: fixture.workspaces),
  ],
  child: MaterialApp(
    key: UniqueKey(),
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme(),
    darkTheme: AppTheme.darkTheme(),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, content) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        viewInsets: insets,
        disableAnimations: true,
        padding: const EdgeInsets.only(top: 44, bottom: 34),
      ),
      child: content!,
    ),
    home: RepaintBoundary(
      key: boundary,
      child: AccessTheme(child: child),
    ),
  ),
);
