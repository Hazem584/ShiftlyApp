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
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_editor_dialog.dart';
import 'package:shiftly/features/profile/data/mock_profile_repository.dart';

import 'support/manager_template_repository.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('MANAGER_PREVIEWS')) {
    return;
  }
  await tester.pump(const Duration(milliseconds: 350));
  await tester.runAsync(() async {
    final image = await tester
        .renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('manager-capture')),
        )
        .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.artifacts/manager-design/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final locale in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        'manager destinations and template steps in $locale dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          for (final name in ['InterTight', 'Cairo']) {
            await (FontLoader(name)
                  ..addFont(rootBundle.load('assets/fonts/$name-Variable.ttf')))
                .load();
          }
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
          final templates = ManagerTemplateRepository();
          final employees = MockEmployeeRepository(delay: Duration.zero);
          await tester.pumpWidget(
            RepaintBoundary(
              key: const Key('manager-capture'),
              child: ShiftlyApp.preview(
                fixedShiftRepository: templates,
                employeeRepository: employees,
                dashboardRepository: MockDashboardRepository(
                  employeeRepository: employees,
                  delay: Duration.zero,
                ),
                profileRepository: MockProfileRepository(delay: Duration.zero),
                languageStore: MemoryLanguageStore(locale),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(
            find.byKey(const Key('manager-bottom-navigation')),
          );
          await context.read<ThemeCubit>().select(
            dark ? ThemeMode.dark : ThemeMode.light,
          );
          await tester.pumpAndSettle();
          final router = GoRouter.of(context);
          final suffix = '$locale-${dark ? 'dark' : 'light'}';
          await _capture(tester, 'home-$suffix');
          await tester.tap(find.byKey(const Key('nav-1')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('employee-search')), findsOneWidget);
          await _capture(tester, 'team-$suffix');
          await tester.tap(find.byKey(const Key('invite-employee')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('submit-employee')).hitTestable(),
            findsOneWidget,
          );
          await _capture(tester, 'invite-$suffix');
          router.go('/work');
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('work-destination-shifts')),
            findsOneWidget,
          );
          await _capture(tester, 'work-$suffix');
          for (final item in [
            ('attendance', '/employees?tab=attendance'),
            ('calendar', '/employees?tab=calendar'),
            ('reports', '/employees?tab=reports'),
            ('corrections', '/employees?tab=corrections'),
            ('templates', '/work?tab=shifts'),
          ]) {
            router.go(item.$2);
            await tester.pumpAndSettle();
            await _capture(tester, '${item.$1}-$suffix');
            expect(tester.takeException(), isNull);
          }
          await tester.tap(find.byKey(const Key('show-archived-templates')));
          await tester.pumpAndSettle();
          expect(find.text('Old inventory shift'), findsOneWidget);
          expect(find.text('Morning operations'), findsNothing);
          await _capture(tester, 'templates-archived-$suffix');
          await tester.tap(find.byKey(const Key('show-archived-templates')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Morning operations'));
          await tester.pumpAndSettle();
          await _capture(tester, 'template-details-$suffix');
          await tester.tap(find.byType(BackButton).last);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('create-shift-template')));
          await tester.pumpAndSettle();
          expect(find.byType(ShiftTemplateEditorDialog), findsOneWidget);
          await tester.enterText(
            find.byType(TextFormField).first,
            locale == 'ar' ? 'شيفت تجريبي' : 'Design review shift',
          );
          await tester.pumpAndSettle();
          await _capture(tester, 'template-create-$suffix');
          await tester.tap(find.byKey(const Key('save-shift-template')));
          await tester.pumpAndSettle();
          expect(
            find.text(locale == 'ar' ? 'قواعد الشيفت' : 'Template policy'),
            findsOneWidget,
          );
          await _capture(tester, 'template-policy-$suffix');
          await tester.tap(find.byKey(const Key('save-shift-template')));
          await tester.pumpAndSettle();
          expect(
            templates.items.last.name,
            locale == 'ar' ? 'شيفت تجريبي' : 'Design review shift',
          );
          expect(find.byType(ShiftTemplateEditorDialog), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
