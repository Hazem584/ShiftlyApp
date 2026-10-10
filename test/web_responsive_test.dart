import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/localization/memory_language_store.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/shell/presentation/widgets/app_bottom_navigation.dart';

void main() {
  for (final language in ['en', 'ar']) {
    testWidgets('$language workspace resizes and navigates without overflow', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final employees = MockEmployeeRepository(delay: Duration.zero);
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(
        ShiftlyApp.preview(
          languageStore: MemoryLanguageStore(language),
          employeeRepository: employees,
          dashboardRepository: MockDashboardRepository(
            employeeRepository: employees,
            delay: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isTrue,
      );
      expect(tester.takeException(), isNull);
      for (final size in [
        const Size(1440, 900),
        const Size(1024, 768),
        const Size(768, 1024),
        const Size(320, 740),
        const Size(1440, 540),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size');
        if (size.width < 840 || size.height < 600) {
          expect(
            find.byKey(const Key('manager-bottom-navigation')),
            findsOneWidget,
          );
        } else {
          expect(
            tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
            size.width >= 1200,
          );
        }
        for (var index = 0; index < 5; index++) {
          if (find.byType(NavigationRail).evaluate().isNotEmpty) {
            tester
                .widget<NavigationRail>(find.byType(NavigationRail))
                .onDestinationSelected!(index);
          } else {
            tester
                .widget<AppBottomNavigation>(
                  find.byType(AppBottomNavigation),
                )
                .onDestinationSelected(index);
          }
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$language $size branch $index',
          );
        }
      }
    });
  }
}
