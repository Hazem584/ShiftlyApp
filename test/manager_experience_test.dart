import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/attendance/data/mock_leave_request_repository.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/profile/data/mock_profile_repository.dart';
import 'package:shiftly/features/profile/data/profile_image_picker.dart';

class _CancelledImagePicker implements ProfileImagePicker {
  @override
  Future<Uint8List?> pickImage() async => null;
}

ShiftlyApp _testApp() {
  final employees = MockEmployeeRepository(delay: Duration.zero);
  return ShiftlyApp(
    employeeRepository: employees,
    dashboardRepository: MockDashboardRepository(
      employeeRepository: employees,
      delay: Duration.zero,
    ),
    leaveRequestRepository: MockLeaveRequestRepository(delay: Duration.zero),
    profileRepository: MockProfileRepository(delay: Duration.zero),
    profileImagePicker: _CancelledImagePicker(),
  );
}

Finder _attendanceScroll() => find
    .descendant(
      of: find.byKey(const Key('attendance-content')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _openRequests(WidgetTester tester) async {
  await tester.tap(find.text('Attendance').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('attendance-tab-requests')));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('request-leave-1')),
    250,
    scrollable: _attendanceScroll(),
  );
  await tester.ensureVisible(find.byKey(const Key('approve-leave-1')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('dashboard Review Requests opens Attendance leave requests', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('dashboard-content')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    await tester.drag(_attendanceScroll(), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Employee requests'), findsOneWidget);
    expect(find.byKey(const Key('leave-request-list')), findsOneWidget);
  });

  testWidgets('manager approves a request and decision survives tab changes', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await _openRequests(tester);
    expect(find.byKey(const Key('approve-leave-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('approve-leave-1')));
    await tester.pumpAndSettle();
    expect(find.text('Request approved'), findsOneWidget);
    expect(find.byKey(const Key('approve-leave-1')), findsNothing);

    await tester.drag(_attendanceScroll(), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attendance-tab-calendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('attendance-tab-requests')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('request-leave-1')),
      250,
      scrollable: _attendanceScroll(),
    );
    expect(find.byKey(const Key('approve-leave-1')), findsNothing);
    expect(find.text('Approved'), findsAtLeastNWidgets(1));
    expect(find.text('1 pending'), findsOneWidget);
    ToastService.dismissAll();
  });

  testWidgets('manager confirms rejecting a pending request', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await _openRequests(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('reject-leave-2')),
      250,
      scrollable: _attendanceScroll(),
    );
    await tester.ensureVisible(find.byKey(const Key('reject-leave-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reject-leave-2')));
    await tester.pumpAndSettle();
    expect(find.text('Reject request?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-reject')));
    await tester.pumpAndSettle();
    expect(find.text('Request rejected'), findsOneWidget);
    expect(find.byKey(const Key('reject-leave-2')), findsNothing);
    ToastService.dismissAll();
  });

  testWidgets('profile edit can be cancelled and validates input', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Manager Profile'), findsOneWidget);
    expect(find.byKey(const Key('profile-initials')), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    await tester.tap(find.byKey(const Key('change-photo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-initials')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('profile-email-field')), 'bad');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-profile')));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('cancel-profile-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel-profile-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Manager Profile'), findsOneWidget);
  });

  testWidgets('profile updates manager text for the current session', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-name-field')),
      'Layla Mostafa',
    );
    tester.testTextInput.hide();
    await tester.ensureVisible(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Layla Mostafa'), findsOneWidget);
    expect(find.text('Profile updated successfully'), findsOneWidget);

    await tester.tap(find.text('Dashboard').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Good morning'), findsOneWidget);
    ToastService.dismissAll();
  });
}
