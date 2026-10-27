import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';
import 'package:shiftly/core/widgets/brand_session_loading.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_loading.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  testWidgets(
    'startup contains only the logo and tagline while checks are pending',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: const BrandSessionLoading(),
        ),
      );
      expect(find.byType(BrandLogo), findsOneWidget);
      expect(find.text(BrandSessionLoading.tagline), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Checking'), findsNothing);
      expect(find.textContaining('Restoring'), findsNothing);
      expect(find.byType(Shimmer), findsNothing);
    },
  );
  testWidgets(
    'content placeholders use one RTL shimmer and respect reduced motion',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(body: AppContentLoading()),
            ),
          ),
        ),
      );
      expect(find.byType(Shimmer), findsOneWidget);
      final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
      expect(shimmer.direction, ShimmerDirection.rtl);
      expect(shimmer.enabled, isFalse);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dashboard shimmer animates while data is pending and disposes cleanly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: const Scaffold(body: DashboardLoadingView()),
        ),
      );
      expect(tester.widget<Shimmer>(find.byType(Shimmer)).enabled, isTrue);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('capture refreshed splash and shimmer for review', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('UI_BRAND_CAPTURE')) return;
    final font = FontLoader('Cairo')
      ..addFont(rootBundle.load('assets/fonts/Cairo-Variable.ttf'));
    await font.load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final output = Directory('docs/ui-review/brand')
      ..createSync(recursive: true);
    for (final language in ['ar', 'en']) {
      for (final kind in ['splash', 'loading']) {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.darkTheme(),
              home: kind == 'splash'
                  ? const BrandSessionLoading()
                  : const Scaffold(body: DashboardLoadingView()),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 180)),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${output.path}/$kind-$language.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
