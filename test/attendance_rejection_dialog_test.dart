import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_rejection_dialog.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_panel.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

const _reasonKey = Key('attendance-rejection-reason');
const _confirmKey = Key('confirm-reject-attendance');
const _scope = FeatureSessionScope(
  userId: 'manager',
  workspaceId: 'workspace',
  membershipId: 'manager-membership',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.manager,
);

AttendanceRecordApi _record({bool rejected = false}) => AttendanceRecordApi(
  id: 'attendance',
  workspaceId: 'workspace',
  shiftId: 'shift',
  employeeMembershipId: 'employee',
  clockInAt: DateTime.utc(2026, 10, 8, 9),
  reviewStatus: rejected
      ? AttendanceReviewStatus.rejected
      : AttendanceReviewStatus.pending,
  rejectionReason: rejected ? 'Server canonical reason' : null,
  minutesLate: 7,
  createdAt: DateTime.utc(2026, 10, 8),
  updatedAt: DateTime.utc(2026, 10, 8, 10),
  employee: const ShiftEmployeeSummary(
    membershipId: 'employee',
    profileId: 'profile',
    role: WorkspaceRole.employee,
    membershipStatus: MembershipStatus.active,
    fullName: 'Mariam Hassan',
  ),
);

class _Repository implements AttendanceRepository {
  final requests = <Completer<AttendanceRecordApi>>[];
  final reasons = <String?>[];

  AttendancePage get page => AttendancePage(
    data: [_record()],
    pagination: const ApiPagination(
      page: 1,
      limit: 20,
      total: 1,
      totalPages: 1,
    ),
  );

  @override
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) async => page;

  @override
  Future<AttendancePage> listAttendanceRequests(
    String workspaceId, {
    int page = 1,
    int limit = 20,
  }) async => this.page;

  @override
  Future<AttendanceRecordApi> getWorkspaceAttendance(
    String workspaceId,
    String attendanceId,
  ) async => _record();

  @override
  Future<AttendanceRecordApi> reviewAttendance(
    String workspaceId,
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  }) {
    expect(workspaceId, 'workspace');
    expect(attendanceId, 'attendance');
    expect(decision, AttendanceReviewDecision.rejected);
    reasons.add(rejectionReason);
    final request = Completer<AttendanceRecordApi>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<AttendanceRecordApi> clockIn(String shiftId) =>
      throw UnimplementedError();

  @override
  Future<AttendanceRecordApi> clockOut(String shiftId) =>
      throw UnimplementedError();

  @override
  Future<AttendancePage> listMyAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) => throw UnimplementedError();
}

Future<ManagerAttendanceCubit> _mount(
  WidgetTester tester,
  _Repository repository, {
  VoidCallback? onDashboardChanged,
}) async {
  final cubit = ManagerAttendanceCubit(
    repository,
    onDashboardChanged: onDashboardChanged,
  )..bindSession(_scope);
  addTearDown(cubit.close);
  addTearDown(ToastService.dismissAll);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: cubit,
                  child: const Scaffold(
                    key: Key('attendance-screen'),
                    body: SingleChildScrollView(
                      child: ManagerAttendancePanel(timezone: 'Etc/UTC'),
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('Open attendance'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open attendance'));
  await tester.pumpAndSettle();
  await _openDialog(tester);
  return cubit;
}

Future<void> _openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Mariam Hassan').first);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('reject-attendance')));
  await tester.pumpAndSettle();
  expect(find.byType(AttendanceRejectionDialog), findsOneWidget);
}

Future<void> _finishClosing(WidgetTester tester) async {
  final dialog = find.byType(AttendanceRejectionDialog);
  final closingDuration = dialog.evaluate().isEmpty
      ? Duration.zero
      : ModalRoute.of(tester.element(dialog))!.reverseTransitionDuration;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  expect(tester.takeException(), isNull);
  // Finish the route animation even if the underlying attendance list is
  // showing an indeterminate spinner for a request that is still pending.
  await tester.pump(closingDuration);
  ToastService.dismissAll();
  await tester.pump();
  expect(find.byType(AttendanceRejectionDialog), findsNothing);
  expect(find.byKey(const Key('attendance-screen')), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets(
    'valid rejection closes safely and applies canonical attendance',
    (tester) async {
      final repository = _Repository();
      var dashboardChanges = 0;
      final cubit = await _mount(
        tester,
        repository,
        onDashboardChanged: () => dashboardChanges++,
      );
      await tester.enterText(find.byKey(_reasonKey), '  Missing clock-out  ');
      await tester.tap(find.byKey(_confirmKey));
      expect(repository.reasons, ['Missing clock-out']);
      final canonical = _record(rejected: true);
      repository.requests.single.complete(canonical);
      await _finishClosing(tester);
      expect(cubit.state.records.single, canonical);
      expect(cubit.state.selected, canonical);
      expect(cubit.state.pending, isEmpty);
      expect(dashboardChanges, 1);
      expect(find.text('Rejected'), findsOneWidget);
    },
  );

  for (final dismissal in ['Cancel', 'Back', 'barrier']) {
    testWidgets('$dismissal closes safely and permits reopening', (
      tester,
    ) async {
      final repository = _Repository();
      await _mount(tester, repository);
      await tester.enterText(find.byKey(_reasonKey), 'Draft reason');
      switch (dismissal) {
        case 'Cancel':
          await tester.tap(find.text('Cancel'));
        case 'Back':
          await tester.binding.handlePopRoute();
        case 'barrier':
          await tester.tapAt(const Offset(5, 5));
      }
      await _finishClosing(tester);
      expect(repository.requests, isEmpty);
      await _openDialog(tester);
      expect(
        tester.widget<TextField>(find.byKey(_reasonKey)).controller!.text,
        '',
      );
      await tester.tap(find.text('Cancel'));
      await _finishClosing(tester);
    });
  }

  testWidgets(
    'blank reason is invalid and request failure retains retry input',
    (tester) async {
      final repository = _Repository();
      final cubit = await _mount(tester, repository);
      await tester.enterText(find.byKey(_reasonKey), '   ');
      await tester.tap(find.byKey(_confirmKey));
      await tester.pump();
      expect(find.text('A rejection reason is required.'), findsOneWidget);
      expect(repository.requests, isEmpty);

      await tester.enterText(find.byKey(_reasonKey), 'Needs correction');
      // Both taps occur before the disabled button is rebuilt.
      await tester.tap(find.byKey(_confirmKey));
      await tester.tap(find.byKey(_confirmKey));
      await tester.pump();
      expect(repository.requests, hasLength(1));
      expect(
        tester.widget<FilledButton>(find.byKey(_confirmKey)).onPressed,
        isNull,
      );
      repository.requests.single.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(find.byType(AttendanceRejectionDialog), findsOneWidget);
      expect(find.text('Unable to review attendance.'), findsWidgets);
      expect(
        tester.widget<TextField>(find.byKey(_reasonKey)).controller!.text,
        'Needs correction',
      );
      expect(cubit.state.pending, hasLength(1));
      expect(
        cubit.state.records.single.reviewStatus,
        AttendanceReviewStatus.pending,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(_confirmKey));
      expect(repository.requests, hasLength(2));
      repository.requests.last.complete(_record(rejected: true));
      await _finishClosing(tester);
    },
  );

  for (final duringAnimation in [true, false]) {
    testWidgets(
      'late request completion after dismissal (during animation: $duringAnimation) keeps screen',
      (tester) async {
        final repository = _Repository();
        await _mount(tester, repository);
        await tester.enterText(find.byKey(_reasonKey), 'Valid reason');
        await tester.tap(find.byKey(_confirmKey));
        await tester.pump();
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        if (duringAnimation) {
          expect(find.byType(AttendanceRejectionDialog), findsOneWidget);
        } else {
          await _finishClosing(tester);
        }
        repository.requests.single.complete(_record(rejected: true));
        await _finishClosing(tester);
      },
    );
  }
}
