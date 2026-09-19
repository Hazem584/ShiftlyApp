import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

ShiftlyApp _appWith(MockEmployeeRepository employees) => ShiftlyApp(
  employeeRepository: employees,
  dashboardRepository: MockDashboardRepository(
    employeeRepository: employees,
    delay: Duration.zero,
  ),
);

void main() {
  testWidgets('attendance reference UI and leave sheet render on mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _appWith(MockEmployeeRepository(delay: Duration.zero)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Attendance').last);
    await tester.pumpAndSettle();
    expect(find.text('Attendance & Leave'), findsOneWidget);
    expect(find.text('Attendance Rate'), findsOneWidget);
    expect(find.text('Recent Attendance'), findsOneWidget);

    await tester.tap(find.text('Request Leave'));
    await tester.pumpAndSettle();
    expect(find.text('Leave type'), findsOneWidget);
    expect(find.text('Submit Request'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('employee card opens redesigned details', (tester) async {
    await tester.pumpWidget(
      _appWith(MockEmployeeRepository(delay: Duration.zero)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Employees').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mariam Hassan'));
    await tester.pumpAndSettle();

    expect(find.text('Employee details'), findsOneWidget);
    expect(find.text('Contact information'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Work details'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-details-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Work details'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Start date'),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-details-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Start date'), findsOneWidget);
  });

  testWidgets('long employee content does not overflow a 360px viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final base = MockEmployeeRepository(delay: Duration.zero);
    final template = (await base.getEmployees()).first;
    final employees = MockEmployeeRepository(
      delay: Duration.zero,
      initialEmployees: [
        Employee(
          id: 'long-copy',
          fullName: 'Alexandria Very Long Employee Family Name',
          phone: template.phone,
          email: 'alexandria.with.a.very.long.address@shiftlab.example.com',
          jobTitle: 'Senior International Workplace Operations Coordinator',
          location: template.location,
          shift: template.shift,
          startDate: template.startDate,
          employmentStatus: EmploymentStatus.active,
          attendanceStatus: AttendanceStatus.present,
        ),
      ],
    );
    await tester.pumpWidget(_appWith(employees));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Employees').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Alexandria Very Long'), findsOneWidget);
  });
}
