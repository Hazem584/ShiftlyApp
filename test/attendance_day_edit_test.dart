import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/edit_attendance_day_dialog.dart';

class DayRepository implements TeamWorkRepository {
  int requests = 0, direct = 0;
  String? employee, assignment, date;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<void> requestMissedAttendance(
    String workspaceId, {
    String? assignmentId,
    String? extraAuthorizationId,
    String? shiftId,
    required String operationalDate,
    required String reasonKind,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  }) async {
    requests++;
    assignment = assignmentId;
    date = operationalDate;
  }

  @override
  Future<void> recordAttendanceDay(
    String workspaceId, {
    required String employeeMembershipId,
    String? attendanceId,
    String? assignmentId,
    String? extraAuthorizationId,
    String? shiftId,
    required String operationalDate,
    required String reasonKind,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  }) async {
    direct++;
    employee = employeeMembershipId;
    assignment = assignmentId;
    date = operationalDate;
  }
}

void main() {
  final start = DateTime.utc(2026, 10, 1, 8),
      end = DateTime.utc(2026, 10, 1, 16);
  final employee = ShiftEmployeeSummary(
    membershipId: 'employee',
    profileId: 'profile',
    role: WorkspaceRole.employee,
    membershipStatus: MembershipStatus.active,
    fullName: 'Employee',
  );
  final shift = ShiftRecord(
    id: 'schedule:assignment:2026-10-01',
    workspaceId: 'workspace',
    employeeMembershipId: 'employee',
    createdByMembershipId: 'manager',
    assignmentId: 'assignment',
    startsAt: start,
    endsAt: end,
    breakMinutes: 60,
    graceMinutes: 0,
    status: ShiftStatus.scheduled,
    createdAt: start,
    updatedAt: start,
    employee: employee,
  );
  for (final manager in [false, true]) {
    testWidgets(
      manager
          ? 'manager day edit saves directly'
          : 'employee day edit submits for approval',
      (tester) async {
        final repository = DayRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => EditAttendanceDayDialog(
                      entry: AttendanceCalendarEntry(
                        employeeMembershipId: 'employee',
                        employee: employee,
                        status: CalendarAttendanceStatus.absent,
                        shift: shift,
                      ),
                      date: DateTime(2026, 10, 1),
                      workspaceId: 'workspace',
                      timezone: 'Etc/UTC',
                      manager: manager,
                      repository: repository,
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField),
          'I attended this shift but forgot to clock in.',
        );
        await tester.ensureVisible(
          find.byKey(const Key('save-attendance-day')),
        );
        await tester.tap(find.byKey(const Key('save-attendance-day')));
        await tester.pumpAndSettle();
        expect(repository.direct, manager ? 1 : 0);
        expect(repository.requests, manager ? 0 : 1);
        expect(repository.assignment, 'assignment');
        expect(repository.date, '2026-10-01');
        if (manager) expect(repository.employee, 'employee');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
