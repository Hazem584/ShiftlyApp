import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

class _PendingDashboardRepository implements DashboardRepository {
  final completer = Completer<DashboardData>();
  @override
  Future<DashboardData> getDashboard() => completer.future;
}

void main() {
  testWidgets('dashboard renders repository statistics', (tester) async {
    final employees = MockEmployeeRepository(delay: Duration.zero);
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: employees,
        dashboardRepository: MockDashboardRepository(
          employeeRepository: employees,
          delay: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total employees'), findsOneWidget);
    expect(find.text('Present today'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Quick actions'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('dashboard-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('dashboard shows loading state', (tester) async {
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
        dashboardRepository: _PendingDashboardRepository(),
      ),
    );
    await tester.pump();
    expect(find.text('Preparing your dashboard…'), findsOneWidget);
  });

  testWidgets('dashboard shows an error and retry action', (tester) async {
    final employees = MockEmployeeRepository(delay: Duration.zero);
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: employees,
        dashboardRepository: MockDashboardRepository(
          employeeRepository: employees,
          delay: Duration.zero,
          shouldFail: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('dashboard has a useful empty state', (tester) async {
    final employees = MockEmployeeRepository(
      delay: Duration.zero,
      initialEmployees: const [],
    );
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: employees,
        dashboardRepository: MockDashboardRepository(
          employeeRepository: employees,
          delay: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your workplace is ready'), findsOneWidget);
    expect(find.text('Add Employee'), findsOneWidget);
  });
}
