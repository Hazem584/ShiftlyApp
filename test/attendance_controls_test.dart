import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/attendance/data/api_attendance_controls_repository.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_entry.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_calendar_month.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_month_control.dart';
import 'package:shiftly/features/attendance/domain/entities/calendar_attendance_status.dart';
import 'package:shiftly/features/attendance/domain/services/apply_attendance_day_decisions.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_day_breakdown.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_decision_dialog.dart';

import 'support/report_fixtures.dart';

void main() {
  final recorded = reportRecord();
  AttendanceCalendarMonth calendar() => AttendanceCalendarMonth(
    year: 2026,
    month: 10,
    timezone: 'Africa/Cairo',
    days: {
      '2026-10-01': [
        AttendanceCalendarEntry(
          employeeMembershipId: 'employee',
          employee: recorded.employee,
          status: CalendarAttendanceStatus.present,
          attendance: recorded,
        ),
      ],
    },
  );
  AttendanceMonthControl decision(String status) => AttendanceMonthControl(
    overrides: [
      AttendanceDayDecision(
        date: '2026-10-01',
        employeeMembershipId: 'employee',
        status: status,
        reason: 'Manager reviewed this day',
        revision: 2,
        employee: recorded.employee,
      ),
    ],
  );
  test('a closed-month snapshot keeps absent days after the active schedule loses an employee', () {
    final control = AttendanceMonthControl(
      closedAt: DateTime.utc(2026, 11, 1),
      approvedDays: [
        AttendanceApprovedDay(
          '2026-10-02',
          'employee',
          'ABSENT',
          recorded.employee,
        ),
      ],
    );
    final result = applyAttendanceDayDecisions(calendar(), control);
    expect(
      result.days['2026-10-02']!.single.status,
      CalendarAttendanceStatus.absent,
    );
    expect(result.days['2026-10-02']!.single.employee, recorded.employee);
  });
  test(
    'manager absence takes priority and preserves recorded times and revision',
    () {
      final day = applyAttendanceDayDecisions(
        calendar(),
        decision('ABSENT'),
      ).days.values.single.single;
      expect(day.status, CalendarAttendanceStatus.absent);
      expect(day.attendance, recorded);
      expect(day.decisionRevision, 2);
      expect(day.decisionReason, 'Manager reviewed this day');
    },
  );
  test(
    'manager can mark late, leave, present and restore automatic attendance',
    () {
      for (final entry in {
        'LATE': CalendarAttendanceStatus.late,
        'LEAVE': CalendarAttendanceStatus.leave,
        'PRESENT': CalendarAttendanceStatus.present,
        'AUTO': CalendarAttendanceStatus.present,
      }.entries) {
        expect(
          applyAttendanceDayDecisions(
            calendar(),
            decision(entry.key),
          ).days.values.single.single.status,
          entry.value,
        );
      }
    },
  );
  test(
    'absent and leave decisions exclude genuine approved hours from reports',
    () {
      for (final status in ['ABSENT', 'LEAVE']) {
        final metrics = fixtureReport(
          records: [
            reportRecord(dayStatus: status, netWork: 480, overtime: 60),
          ],
        ).totalsFor(null);
        expect(metrics.attendanceDays, 0);
        expect(metrics.workMinutes, 0);
        expect(metrics.excessMinutes, 0);
      }
      final present = fixtureReport(
        records: [reportRecord(dayStatus: 'PRESENT', late: 30)],
      ).totalsFor(null);
      expect(present.late, 0);
      expect(present.lateMinutes, 0);
      final late = fixtureReport(
        records: [reportRecord(dayStatus: 'LATE', late: 0)],
      ).totalsFor(null);
      expect(late.late, 1);
    },
  );
  test('overnight reports group attendance by its operational day', () {
    final records = [
      reportRecord(
        id: 'a',
        operationalDate: '2026-10-01',
        clockIn: DateTime.utc(2026, 10, 1, 22),
      ),
      reportRecord(
        id: 'b',
        operationalDate: '2026-10-01',
        clockIn: DateTime.utc(2026, 10, 2, 1),
      ),
    ];
    expect(fixtureReport(records: records).totalsFor(null).attendanceDays, 1);
  });
  testWidgets(
    'month approval requires a reason and sends the expected revision',
    (tester) async {
      final dio = Dio();
      addTearDown(dio.close);
      final requests = <RequestOptions>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            requests.add(o);
            h.resolve(Response(requestOptions: o, statusCode: 200));
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceDecisionDialog(
              repository: ApiAttendanceControlsRepository(dio),
              workspaceId: 'workspace',
              year: 2026,
              month: 10,
              revision: 3,
              closeMonth: true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Save decision'));
      await tester.pump();
      expect(requests, isEmpty);
      expect(
        find.text('Enter a reason of at least 3 characters.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField),
        'Reviewed the full month',
      );
      await tester.tap(find.text('Save decision'));
      await tester.pumpAndSettle();
      expect(
        requests.single.path,
        '/workspaces/workspace/attendance-controls/month',
      );
      expect(requests.single.data, {
        'year': 2026,
        'month': 10,
        'revision': 3,
        'action': 'CLOSE',
        'reason': 'Reviewed the full month',
      });
    },
  );
  testWidgets('daily breakdown explains recorded and excluded credited hours', (
    tester,
  ) async {
    final record = reportRecord(
      dayStatus: 'ABSENT',
      netWork: 0,
      calculation: {
        'elapsedMinutes': 540,
        'breakTakenMinutes': 30,
        'netWorkedMinutes': 510,
        'plannedBreakMinutes': 60,
        'lateBreakDeductionMinutes': 0,
        'allowedBreakMinutes': 60,
        'expectedWorkMinutes': 480,
        'postShiftOvertimeMinutes': 30,
        'unusedBreakOvertimeMinutes': 30,
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AttendanceDayBreakdown(record: record),
          ),
        ),
      ),
    );
    await tester.tap(find.text('How this day was calculated'));
    await tester.pumpAndSettle();
    expect(find.text('8h 30m'), findsOneWidget);
    expect(find.text('0h 0m'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
