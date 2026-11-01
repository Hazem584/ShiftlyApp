import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/core/theme/theme_cubit.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/manager/presentation/widgets/manager_reason_dialog.dart';

void main() {
  testWidgets(
    'manager reference, compact RTL large text and desktop render review',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      for (final entry in const {
        'AccessInter': 'assets/access/fonts/InterTight-Variable.ttf',
        'AccessArabic': 'assets/access/fonts/NotoSansArabic-Variable.ttf',
      }.entries) {
        await (FontLoader(
          entry.key,
        )..addFont(rootBundle.load(entry.value))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final output = Directory('.artifacts/manager-experience')
        ..createSync(recursive: true);
      for (final variant in ['reference', 'compact-ar', 'desktop-dark']) {
        final compact = variant == 'compact-ar';
        final desktop = variant == 'desktop-dark';
        tester.view.physicalSize = Size(
          compact
              ? 320
              : desktop
              ? 1280
              : 390,
          desktop ? 900 : 844,
        );
        tester.platformDispatcher.textScaleFactorTestValue = compact ? 1.6 : 1;
        tester.platformDispatcher.platformBrightnessTestValue = desktop
            ? Brightness.dark
            : Brightness.light;
        final employees = MockEmployeeRepository(delay: Duration.zero);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: ShiftlyApp.preview(
              key: ValueKey(variant),
              languageStore: MemoryLanguageStore(compact ? 'ar' : 'en'),
              employeeRepository: employees,
              dashboardRepository: MockDashboardRepository(
                employeeRepository: employees,
                delay: Duration.zero,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final navigationContext = tester.element(find.byType(Navigator).last);
        await navigationContext.read<ThemeCubit>().select(
          desktop ? ThemeMode.dark : ThemeMode.light,
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(navigationContext);
        for (final entry in const {
          'B01-overview': '/dashboard',
          'B03-directory': '/employees',
          'NAV01-work': '/work',
          'L01b-profile': '/profile',
        }.entries) {
          router.go(entry.value);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key}/$variant',
          );
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary
                .toImage(pixelRatio: 1)
                .timeout(const Duration(seconds: 15));
            try {
              final bytes = await image
                  .toByteData(format: ui.ImageByteFormat.png)
                  .timeout(const Duration(seconds: 15));
              await File('${output.path}/${entry.key}-$variant.png')
                  .writeAsBytes(bytes!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
        if (compact) {
          for (final index in [4, 0]) {
            await tester.ensureVisible(find.byKey(Key('nav-$index')));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(Key('nav-$index')));
            await tester.pumpAndSettle();
            expect(
              find.byKey(
                Key(index == 4 ? 'profile-heading' : 'manager-home-greeting'),
              ),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'review reason validates and releases its controller after closing',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (_) => const ManagerReasonDialog(
                    title: 'Decline request',
                    confirm: 'Decline',
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Decline'));
        await tester.pumpAndSettle();
        expect(find.text('Please add a reason.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const Key('manager-review-reason')),
          'Schedule conflict',
        );
        await tester.tap(find.text('Decline'));
        await tester.pumpAndSettle();
        expect(find.byType(ManagerReasonDialog), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
