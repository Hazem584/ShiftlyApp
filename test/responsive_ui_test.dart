import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_tab_selector.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

void main() {
  testWidgets('compact RTL header and attendance tabs support large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ScreenHeader(
                        title: 'Attendance & Leave',
                        subtitle: 'Review your team attendance',
                        icon: Icons.fact_check_outlined,
                        action: FilledButton(
                          onPressed: () {},
                          child: const Text('Add employee'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setState) => AttendanceTabSelector(
                          selectedTab: selected,
                          onSelected: (value) =>
                              setState(() => selected = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('attendance-tab-requests')));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
    final headerBottom = tester
        .getBottomLeft(find.text('Review your team attendance'))
        .dy;
    expect(
      tester.getTopLeft(find.text('Add employee')).dy,
      greaterThan(headerBottom),
    );
  });

  testWidgets(
    'desktop rail switches branches and returns to mobile navigation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final employees = MockEmployeeRepository(delay: Duration.zero);
      await tester.pumpWidget(
        ShiftlyApp.preview(
          employeeRepository: employees,
          dashboardRepository: MockDashboardRepository(
            employeeRepository: employees,
            delay: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('manager-navigation-rail')), findsOneWidget);
      expect(find.byKey(const Key('manager-bottom-navigation')), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('Employees'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('employee-search')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('manager-bottom-navigation')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('manager-navigation-rail')), findsNothing);
      expect(find.byKey(const Key('employee-search')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
