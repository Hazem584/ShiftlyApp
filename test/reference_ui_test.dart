import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

ShiftlyApp _appWith(MockEmployeeRepository employees) => ShiftlyApp.preview(
  employeeRepository: employees,
  dashboardRepository: MockDashboardRepository(
    employeeRepository: employees,
    delay: Duration.zero,
  ),
);

void main() {
  testWidgets('attendance manager request UI renders on mobile', (
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

    await tester.tap(find.byKey(const Key('attendance-tab-requests')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Mariam Hassan'),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('attendance-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Mariam Hassan'), findsOneWidget);
    expect(find.text('Early departure'), findsOneWidget);
    expect(find.text('Request Leave'), findsNothing);
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
      find.text('Joined'),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-details-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Joined'), findsOneWidget);
  });

  testWidgets('employee deactivation is confirmed and can be reversed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _appWith(MockEmployeeRepository(delay: Duration.zero)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Employees').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mariam Hassan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('deactivate-employee')),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-details-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    await tester.tap(find.byKey(const Key('deactivate-employee')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate employee?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-deactivate-employee')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('reactivate-employee')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-details-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const Key('reactivate-employee')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reactivate-employee')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('deactivate-employee')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('employee-details-content')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const Key('deactivate-employee')), findsOneWidget);
    ToastService.dismissAll();
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

  testWidgets('add employee form fits all requested mobile viewports', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        _appWith(MockEmployeeRepository(delay: Duration.zero)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Employees').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();
      expect(find.text('Invite Employee'), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'Top failed at $size');
      await tester.drag(
        find.byKey(const Key('add-employee-form')),
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('submit-employee')),
        findsOneWidget,
        reason: 'Submit action missing at $size',
      );
      expect(tester.takeException(), isNull, reason: 'Bottom failed at $size');
    }
  });
}
