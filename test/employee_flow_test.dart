import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';

Future<void> _openEmployees(WidgetTester tester) async {
  await tester.tap(find.text('Employees').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('employee search filters locally and has a clear empty result', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    await _openEmployees(tester);
    await tester.enterText(find.byKey(const Key('employee-search')), 'Mariam');
    await tester.pumpAndSettle();
    expect(find.text('Mariam Hassan'), findsOneWidget);
    expect(find.text('Omar Khaled'), findsNothing);
    await tester.enterText(find.byKey(const Key('employee-search')), 'Nobody');
    await tester.pumpAndSettle();
    expect(find.text('No matching employees'), findsOneWidget);
  });

  testWidgets('add employee validates required fields', (tester) async {
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    await _openEmployees(tester);
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(find.text('Add New Employee'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('email-field')), 'invalid');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('submit-employee')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('valid add employee submission updates the session list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShiftlyApp(
        employeeRepository: MockEmployeeRepository(delay: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();
    await _openEmployees(tester);
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(find.text('Add New Employee'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('full-name-field')),
      'Salma Nabil',
    );
    await tester.enterText(
      find.byKey(const Key('phone-field')),
      '+20 100 555 1212',
    );
    await tester.enterText(
      find.byKey(const Key('email-field')),
      'salma@shiftlab.com',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('job-title-field')),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('add-employee-form')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(
      find.byKey(const Key('job-title-field')),
      'Designer',
    );
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -750));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('submit-employee')));
    await tester.pumpAndSettle();
    expect(find.text('Employee added successfully'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('employee-search')),
      'Salma Nabil',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('employee-list')),
        matching: find.text('Salma Nabil'),
      ),
      findsOneWidget,
    );
    ToastService.dismissAll();
  });
}
