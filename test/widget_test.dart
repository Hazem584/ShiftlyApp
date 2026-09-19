import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

ShiftlyApp _testApp() {
  final employees = MockEmployeeRepository(delay: Duration.zero);
  return ShiftlyApp(
    employeeRepository: employees,
    dashboardRepository: MockDashboardRepository(
      employeeRepository: employees,
      delay: Duration.zero,
    ),
  );
}

void main() {
  testWidgets('application starts on the manager dashboard', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Good morning, Manager'), findsOneWidget);
    expect(find.text('Shift Lab'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom navigation changes and preserves the selected tab', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Employees').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('employee-search')), findsOneWidget);
    await tester.tap(find.text('Attendance').last);
    await tester.pumpAndSettle();
    expect(find.text('Attendance & Leave'), findsOneWidget);
    await tester.tap(find.text('Employees').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('employee-search')), findsOneWidget);
  });

  testWidgets('manager shell fits a compact mobile viewport', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Layout failed at $size');
      expect(find.byType(NavigationBar), findsOneWidget);
    }
  });
}
