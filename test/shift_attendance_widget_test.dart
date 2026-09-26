import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/routing/app_router.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

void main() {
  testWidgets('manager shift quick action opens API-backed shift screen', (
    tester,
  ) async {
    final router = createAppRouter();
    addTearDown(router.dispose);
    final employees = MockEmployeeRepository(delay: Duration.zero);
    await tester.pumpWidget(
      ShiftlyApp(
        router: router,
        employeeRepository: employees,
        dashboardRepository: MockDashboardRepository(
          employeeRepository: employees,
          delay: Duration.zero,
        ),
      ),
    );
    router.go(AppRoutes.managerShifts);
    await tester.pumpAndSettle();

    expect(find.text('Shift Management'), findsOneWidget);
    expect(find.byKey(const Key('create-shift')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
