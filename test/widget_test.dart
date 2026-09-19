import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

void main() {
  testWidgets('application starts on the manager dashboard', (tester) async {
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Good morning, Manager'), findsOneWidget);
    expect(find.textContaining('Shift Lab'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom navigation changes and preserves the selected tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Employees').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('employee-search')), findsOneWidget);
    await tester.tap(find.text('Attendance').last);
    await tester.pumpAndSettle();
    expect(find.text('Attendance is coming next'), findsOneWidget);
    await tester.tap(find.text('Employees').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('employee-search')), findsOneWidget);
  });

  testWidgets('manager shell fits a compact mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
