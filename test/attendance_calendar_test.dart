import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/data/api_attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/data/api_attendance_repository.dart';
import 'package:shiftly/features/attendance/data/api_leave_request_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_employee_day_row.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_state.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_daily_status_panel.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_month_summary.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';
import 'package:shiftly/features/shifts/data/api_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

const _workspace = 'workspace';

ShiftEmployeeSummary _employee(String id, [String? name]) =>
    ShiftEmployeeSummary(
      membershipId: id,
      profileId: 'profile-$id',
      role: WorkspaceRole.employee,
      membershipStatus: MembershipStatus.active,
      fullName: name ?? 'Employee $id',
    );

ShiftRecord _shift({
  required String id,
  required String employeeId,
  required DateTime start,
  required DateTime end,
  ShiftStatus status = ShiftStatus.scheduled,
}) => ShiftRecord(
  id: id,
  workspaceId: _workspace,
  employeeMembershipId: employeeId,
  createdByMembershipId: 'manager',
  startsAt: start,
  endsAt: end,
  breakMinutes: 0,
  graceMinutes: 0,
  status: status,
  createdAt: start,
  updatedAt: start,
  employee: _employee(employeeId),
);

AttendanceRecordApi _attendanceRecord({
  required String id,
  required ShiftRecord shift,
  int minutesLate = 0,
  AttendanceReviewStatus reviewStatus = AttendanceReviewStatus.approved,
}) => AttendanceRecordApi(
  id: id,
  workspaceId: _workspace,
  shiftId: shift.id,
  employeeMembershipId: shift.employeeMembershipId,
  clockInAt: shift.startsAt,
  clockOutAt: shift.endsAt,
  reviewStatus: reviewStatus,
  minutesLate: minutesLate,
  createdAt: shift.startsAt,
  updatedAt: shift.startsAt,
  shift: AttendanceShiftSummary(
    id: shift.id,
    startsAt: shift.startsAt,
    endsAt: shift.endsAt,
    breakMinutes: 0,
    graceMinutes: 0,
    status: shift.status,
  ),
  employee: shift.employee,
);

LeaveRequestRecord _leave(
  String id,
  String employeeId, {
  LeaveRequestStatus status = LeaveRequestStatus.approved,
}) => LeaveRequestRecord(
  id: id,
  workspaceId: _workspace,
  employeeMembershipId: employeeId,
  type: LeaveRequestType.annualLeave,
  status: status,
  startsAt: DateTime.utc(2026, 3, 11),
  endsAt: DateTime.utc(2026, 3, 13),
  reason: 'Leave',
  createdAt: DateTime.utc(2026, 3),
  updatedAt: DateTime.utc(2026, 3),
  employee: _employee(employeeId),
);

AttendanceRecordApi _templateAttendance({
  String id = 'template-attendance',
  String employeeId = 'template-employee',
  String workspaceId = _workspace,
  String? operationalDate = '2026-03-10',
  String? occurrenceKind = 'BASELINE',
  AttendanceSource source = AttendanceSource.template,
  AttendanceReviewStatus reviewStatus = AttendanceReviewStatus.approved,
  AttendanceClassification classification = AttendanceClassification.onTime,
  int minutesLate = 0,
  DateTime? clockInAt,
  DateTime? scheduledStart,
}) {
  final start = scheduledStart ?? DateTime.utc(2026, 3, 10, 22);
  return AttendanceRecordApi(
    id: id,
    workspaceId: workspaceId,
    shiftId: null,
    employeeMembershipId: employeeId,
    employee: _employee(employeeId),
    source: source,
    occurrenceKind: occurrenceKind,
    operationalDate: operationalDate,
    shiftTemplateId: 'template',
    templateName: 'Night shift',
    scheduledStartAt: start,
    scheduledEndAt: start.add(const Duration(hours: 8)),
    clockInAt: clockInAt ?? DateTime.utc(2026, 3, 11),
    clockOutAt: start.add(const Duration(hours: 8)),
    clockInClassification: classification,
    minutesLate: minutesLate,
    reviewStatus: reviewStatus,
    createdAt: start,
    updatedAt: start,
  );
}

AttendanceCalendarMonth _deriveTemplates(
  List<AttendanceRecordApi> records, {
  List<ShiftRecord> shifts = const [],
  List<LeaveRequestRecord> leave = const [],
}) => deriveAttendanceCalendarMonth(
  workspaceId: _workspace,
  timezoneName: 'Etc/UTC',
  year: 2026,
  month: 3,
  shifts: shifts,
  attendance: records,
  leaveRequests: leave,
  nowUtc: DateTime.utc(2026, 3, 15),
);

ApiPagination _pagination(int page, int totalPages) => ApiPagination(
  page: page,
  limit: 100,
  total: totalPages * 100,
  totalPages: totalPages,
);

class _ShiftRepository implements ShiftRepository {
  final queries = <ShiftQuery>[];
  @override
  Future<ShiftPage> listWorkspaceShifts(
    String workspaceId,
    ShiftQuery query,
  ) async {
    queries.add(query);
    return ShiftPage(data: const [], pagination: _pagination(query.page, 2));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _AttendanceRepository implements AttendanceRepository {
  _AttendanceRepository({this.records = const []});
  final List<AttendanceRecordApi> records;
  final queries = <AttendanceQuery>[];
  @override
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) async {
    queries.add(query);
    return AttendancePage(
      data: records,
      pagination: _pagination(query.page, 2),
    );
  }

  @override
  Future<AttendancePage> listAttendanceRequests(
    String workspaceId, {
    int page = 1,
    int limit = 20,
  }) async => AttendancePage(
    data: const [],
    pagination: ApiPagination(
      page: page,
      limit: limit,
      total: 0,
      totalPages: 0,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LeaveRepository implements LeaveRequestRepository {
  final queries = <LeaveRequestQuery>[];
  @override
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  ) async {
    queries.add(query);
    return LeaveRequestPage(
      data: const [],
      pagination: _pagination(query.page, 2),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CalendarRepository implements AttendanceCalendarRepository {
  AttendanceCalendarMonth value = const AttendanceCalendarMonth(
    year: 2026,
    month: 3,
    timezone: 'Etc/UTC',
    days: {},
  );
  Object? error;
  Completer<AttendanceCalendarMonth>? pending;
  int calls = 0;

  @override
  Future<AttendanceCalendarMonth> loadMonth({
    required String workspaceId,
    required String timezone,
    required int year,
    required int month,
  }) async {
    calls++;
    if (pending != null) return pending!.future;
    if (error != null) throw error!;
    return AttendanceCalendarMonth(
      year: year,
      month: month,
      timezone: timezone,
      days: value.days,
    );
  }
}

const _scope = FeatureSessionScope(
  userId: 'manager-user',
  workspaceId: _workspace,
  membershipId: 'manager-membership',
  timezone: 'Etc/UTC',
  role: WorkspaceRole.manager,
);

void main() {
  test(
    'employee calendar calls only its own attendance, leave and shifts APIs',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      final paths = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            paths.add(options.path);
            handler.resolve(
              Response(
                requestOptions: options,
                data: options.path.endsWith('attendance-controls')
                    ? _emptyControls
                    : options.path.endsWith('attendance-schedule')
                    ? {'data': [], 'evaluatedAt': '2026-11-10T16:00:00Z'}
                    : {
                        'data': [],
                        'pagination': {
                          'page': 1,
                          'limit': 100,
                          'total': 0,
                          'totalPages': 0,
                        },
                      },
              ),
            );
          },
        ),
      );
      final repository = ApiAttendanceCalendarRepository(
        ApiShiftRepository(dio),
        ApiAttendanceRepository(dio),
        ApiLeaveRequestRepository(dio),
        dio: dio,
        employeeOnly: true,
      );
      await repository.loadMonth(
        workspaceId: _workspace,
        timezone: 'Africa/Cairo',
        year: 2026,
        month: 11,
      );
      expect(paths.toSet(), {
        '/shifts/me',
        '/attendance/me',
        '/leave-requests/me',
        '/workspaces/workspace/attendance-schedule',
        '/workspaces/workspace/attendance-controls',
      });
    },
  );
  testWidgets(
    'monthly employee totals include late days in presence without inflating absences',
    (tester) async {
      final repository = _CalendarRepository()
        ..value = AttendanceCalendarMonth(
          year: 2026,
          month: 3,
          timezone: 'Etc/UTC',
          days: {
            '2026-03-01': [
              AttendanceCalendarEntry(
                employeeMembershipId: 'a',
                employee: _employee('a'),
                status: CalendarAttendanceStatus.present,
              ),
            ],
            '2026-03-02': [
              AttendanceCalendarEntry(
                employeeMembershipId: 'a',
                employee: _employee('a'),
                status: CalendarAttendanceStatus.late,
              ),
            ],
            '2026-03-03': [
              AttendanceCalendarEntry(
                employeeMembershipId: 'a',
                employee: _employee('a'),
                status: CalendarAttendanceStatus.absent,
              ),
            ],
          },
        );
      final cubit =
          AttendanceCalendarCubit(
            repository,
            employee: true,
            now: () => DateTime.utc(2026, 3, 10),
          )..bindSession(
            const FeatureSessionScope(
              userId: 'u',
              workspaceId: _workspace,
              membershipId: 'a',
              timezone: 'Etc/UTC',
              role: WorkspaceRole.employee,
            ),
          );
      addTearDown(cubit.close);
      await cubit.open();
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(
            home: Scaffold(body: AttendanceMonthSummary()),
          ),
        ),
      );
      expect(find.text('Present days (including late)  2'), findsOneWidget);
      expect(find.text('Late days  1'), findsOneWidget);
      expect(find.text('Absent days  1'), findsOneWidget);
      cubit.bindSession(null);
      expect(cubit.state.hasData, false);
    },
  );

  test('only an approved leave replaces a missed shift on its dates', () {
    final shift = _shift(
      id: 'schedule:leave-day',
      employeeId: 'a',
      start: DateTime.utc(2026, 3, 11, 8),
      end: DateTime.utc(2026, 3, 11, 16),
    );
    CalendarAttendanceStatus status(LeaveRequestStatus decision) =>
        deriveAttendanceCalendarMonth(
          workspaceId: _workspace,
          timezoneName: 'Etc/UTC',
          year: 2026,
          month: 3,
          shifts: [shift],
          attendance: [],
          leaveRequests: [_leave('leave', 'a', status: decision)],
          nowUtc: DateTime.utc(2026, 3, 11, 17),
        ).days['2026-03-11']!.single.status;
    expect(status(LeaveRequestStatus.pending), CalendarAttendanceStatus.absent);
    expect(
      status(LeaveRequestStatus.rejected),
      CalendarAttendanceStatus.absent,
    );
    expect(status(LeaveRequestStatus.approved), CalendarAttendanceStatus.leave);
  });

  test('loads fixed schedules over HTTP and replaces November 10 absence after approval', () async {
    final dio = Dio();
    addTearDown(dio.close);
    var evaluatedAt = DateTime.utc(2026, 11, 10, 14, 59);
    final paths = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add(options.path);
          expect(options.queryParameters, {'year': 2026, 'month': 11});
          handler.resolve(
            Response(
              requestOptions: options,
              data: options.path.endsWith('attendance-controls')
                  ? _emptyControls
                  : {
                      'evaluatedAt': evaluatedAt.toIso8601String(),
                      'data': [
                        {
                          'id': 'schedule:pattern:2026-11-10',
                          'workspaceId': _workspace,
                          'employeeMembershipId': 'a',
                          'createdByMembershipId': 'manager',
                          'startsAt': '2026-11-10T07:00:00Z',
                          'endsAt': '2026-11-10T15:00:00Z',
                          'breakMinutes': 60,
                          'graceMinutes': 0,
                          'status': 'SCHEDULED',
                          'createdAt': '2026-11-01T00:00:00Z',
                          'updatedAt': '2026-11-01T00:00:00Z',
                          'employee': {
                            'id': 'a',
                            'profileId': 'profile-a',
                            'role': 'EMPLOYEE',
                            'status': 'ACTIVE',
                          },
                        },
                      ],
                    },
            ),
          );
        },
      ),
    );
    final records = <AttendanceRecordApi>[];
    final repository = ApiAttendanceCalendarRepository(
      _ShiftRepository(),
      _AttendanceRepository(records: records),
      _LeaveRepository(),
      dio: dio,
    );
    Future<AttendanceCalendarMonth> load() => repository.loadMonth(
      workspaceId: _workspace,
      timezone: 'Africa/Cairo',
      year: 2026,
      month: 11,
    );
    expect((await load()).days, isEmpty);
    evaluatedAt = DateTime.utc(2026, 11, 10, 16);
    expect(
      (await load()).days['2026-11-10']!.single.status,
      CalendarAttendanceStatus.absent,
    );
    // A pending missed-attendance request does not create an attendance record.
    expect(
      (await load()).days['2026-11-10']!.single.status,
      CalendarAttendanceStatus.absent,
    );
    records.add(
      _templateAttendance(
        employeeId: 'a',
        operationalDate: '2026-11-10',
        clockInAt: DateTime.utc(2026, 11, 10, 7),
        scheduledStart: DateTime.utc(2026, 11, 10, 7),
      ),
    );
    expect(
      (await load()).days['2026-11-10']!.single.status,
      CalendarAttendanceStatus.present,
    );
    expect(
      paths,
      everyElement(
        isIn([
          '/workspaces/workspace/attendance-schedule',
          '/workspaces/workspace/attendance-controls',
        ]),
      ),
    );
  });
  testWidgets(
    'regular attendance shows today absence and approved leave without clock-ins',
    (tester) async {
      final now = DateTime.now().toUtc();
      final key =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final repository = _CalendarRepository()
        ..value = AttendanceCalendarMonth(
          year: now.year,
          month: now.month,
          timezone: 'Etc/UTC',
          days: {
            key: [
              AttendanceCalendarEntry(
                employeeMembershipId: 'a',
                employee: _employee('a', 'Absent Employee'),
                status: CalendarAttendanceStatus.absent,
              ),
              AttendanceCalendarEntry(
                employeeMembershipId: 'b',
                employee: _employee('b', 'Leave Employee'),
                status: CalendarAttendanceStatus.leave,
              ),
            ],
          },
        );
      final calendar = AttendanceCalendarCubit(repository, now: () => now)
        ..bindSession(_scope);
      final attendance = ManagerAttendanceCubit(_AttendanceRepository())
        ..bindSession(_scope);
      addTearDown(calendar.close);
      addTearDown(attendance.close);
      await calendar.showCurrentMonth();
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: calendar),
            BlocProvider.value(value: attendance),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AttendanceDailyStatusPanel(timezone: 'Etc/UTC'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Absent Employee'), findsOneWidget);
      expect(find.text('Leave Employee'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
    },
  );

  test(
    'uses DST-safe month boundaries and loads every pagination page',
    () async {
      final shifts = _ShiftRepository();
      final attendance = _AttendanceRepository();
      final leave = _LeaveRepository();
      final repository = ApiAttendanceCalendarRepository(
        shifts,
        attendance,
        leave,
        dio: null,
      );

      await repository.loadMonth(
        workspaceId: _workspace,
        timezone: 'America/New_York',
        year: 2026,
        month: 3,
      );

      expect(shifts.queries.map((query) => query.page), [1, 2]);
      expect(attendance.queries.map((query) => query.page), [1, 2]);
      expect(leave.queries.map((query) => query.page), [1, 2]);
      expect(shifts.queries.first.limit, 100);
      expect(shifts.queries.first.from, DateTime.utc(2026, 3, 1, 5));
      expect(shifts.queries.first.to, DateTime.utc(2026, 4, 1, 4));
      expect(attendance.queries.first.from, DateTime.utc(2026, 2, 27, 5));
      expect(attendance.queries.first.to, DateTime.utc(2026, 4, 3, 4));
      expect(leave.queries.first.status, LeaveRequestStatus.approved);
    },
  );

  test('template, flexible and extra attendance use the operational day', () {
    final records = [
      _templateAttendance(id: 'baseline', employeeId: 'a'),
      _templateAttendance(
        id: 'flexible',
        employeeId: 'b',
        occurrenceKind: null,
        operationalDate: '2026-03-10T00:00:00.000Z',
      ),
      _templateAttendance(
        id: 'extra',
        employeeId: 'c',
        occurrenceKind: 'EXTRA',
        classification: AttendanceClassification.late,
      ),
    ];
    final data = _deriveTemplates([...records, records.first]);
    expect(data.days.keys, ['2026-03-10']);
    final entries = data.days['2026-03-10']!;
    expect(entries, hasLength(3));
    expect(
      entries.where((e) => e.status == CalendarAttendanceStatus.present),
      hasLength(2),
    );
    expect(entries.last.status, CalendarAttendanceStatus.late);
    expect(entries.every((e) => e.shift == null), isTrue);
  });

  test('ignores unsafe template records and does not invent absence', () {
    final data = _deriveTemplates([
      _templateAttendance(
        id: 'rejected',
        reviewStatus: AttendanceReviewStatus.rejected,
      ),
      _templateAttendance(
        id: 'unknown-review',
        reviewStatus: AttendanceReviewStatus.unknown,
      ),
      _templateAttendance(
        id: 'unknown-source',
        source: AttendanceSource.unknown,
      ),
      _templateAttendance(
        id: 'unknown-classification',
        classification: AttendanceClassification.unknown,
      ),
      _templateAttendance(id: 'missing-date', operationalDate: null),
      _templateAttendance(id: 'invalid-date', operationalDate: '2026-02-30'),
      _templateAttendance(
        id: 'invalid-timestamp',
        operationalDate: '2026-02-30T00:00:00.000Z',
      ),
      _templateAttendance(id: 'other-workspace', workspaceId: 'other'),
      _templateAttendance(id: 'other-month', operationalDate: '2026-04-01'),
    ]);
    expect(data.days, isEmpty);
  });

  test(
    'mixed attendance keeps one outcome and matching schedule per employee',
    () {
      final shift = _shift(
        id: 'legacy',
        employeeId: 'a',
        start: DateTime.utc(2026, 3, 10, 8),
        end: DateTime.utc(2026, 3, 10, 16),
      );
      final late = _templateAttendance(employeeId: 'a', minutesLate: 15);
      final data = _deriveTemplates(
        [_attendanceRecord(id: 'legacy-attendance', shift: shift), late],
        shifts: [shift],
      );
      final entry = data.days['2026-03-10']!.single;
      expect(entry.status, CalendarAttendanceStatus.late);
      expect(entry.attendance, late);
      expect(entry.shift, isNull);
    },
  );

  test('template presence takes precedence over approved leave', () {
    final record = _templateAttendance(operationalDate: '2026-03-11');
    final data = _deriveTemplates(
      [record],
      leave: [_leave('leave', record.employeeMembershipId)],
    );
    expect(
      data.days['2026-03-11']!.single.status,
      CalendarAttendanceStatus.present,
    );
    expect(
      data.days['2026-03-12']!.single.status,
      CalendarAttendanceStatus.leave,
    );
  });

  test('month-edge clock-in remains on the server operational date', () async {
    final record = _templateAttendance(
      operationalDate: '2026-03-31',
      clockInAt: DateTime.utc(2026, 4, 1),
    );
    final repository = ApiAttendanceCalendarRepository(
      _ShiftRepository(),
      _AttendanceRepository(records: [record]),
      _LeaveRepository(),
      dio: null,
    );
    final data = await repository.loadMonth(
      workspaceId: _workspace,
      timezone: 'Etc/UTC',
      year: 2026,
      month: 3,
    );
    expect(data.days.keys, ['2026-03-31']);
    expect(data.days['2026-03-31']!.single.attendance, record);
  });

  test(
    'fixed occurrence becomes absent only after its overnight shift ends',
    () {
      final shift = _shift(
        id: 'schedule:assignment:2026-03-10',
        employeeId: 'a',
        start: DateTime.utc(2026, 3, 10, 22),
        end: DateTime.utc(2026, 3, 11, 6),
      );
      AttendanceCalendarMonth derive(DateTime now) =>
          deriveAttendanceCalendarMonth(
            workspaceId: _workspace,
            timezoneName: 'Etc/UTC',
            year: 2026,
            month: 3,
            shifts: [shift],
            attendance: [],
            leaveRequests: [],
            nowUtc: now,
          );
      final before = derive(DateTime.utc(2026, 3, 11, 5, 59));
      expect(before.days, isEmpty);
      expect(before.nextRefreshAt, shift.endsAt);
      expect(
        derive(DateTime.utc(2026, 3, 11, 6)).days['2026-03-10']!.single.status,
        CalendarAttendanceStatus.absent,
      );
      final present = deriveAttendanceCalendarMonth(
        workspaceId: _workspace,
        timezoneName: 'Etc/UTC',
        year: 2026,
        month: 3,
        shifts: [shift],
        attendance: [_templateAttendance(employeeId: 'a')],
        leaveRequests: [],
        nowUtc: DateTime.utc(2026, 3, 12),
      );
      expect(
        present.days['2026-03-10']!.single.status,
        CalendarAttendanceStatus.present,
      );
    },
  );

  testWidgets('template calendar details show the saved schedule and times', (
    tester,
  ) async {
    final entry = _deriveTemplates([_templateAttendance()])
        .days['2026-03-10']!
        .single;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceCalendarEmployeeDayRow(
            entry: entry,
            timezone: 'Etc/UTC',
          ),
        ),
      ),
    );
    expect(find.textContaining('Night shift'), findsOneWidget);
    expect(find.textContaining('10:00 PM'), findsOneWidget);
    expect(find.textContaining('6:00 AM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'derives canonical statuses, precedence, unknown safety and deduplication',
    () {
      final present = _shift(
        id: 'present',
        employeeId: 'a',
        start: DateTime.utc(2026, 3, 10, 8),
        end: DateTime.utc(2026, 3, 10, 16),
      );
      final late = _shift(
        id: 'late',
        employeeId: 'b',
        start: DateTime.utc(2026, 3, 10, 8),
        end: DateTime.utc(2026, 3, 10, 16),
      );
      final absent = _shift(
        id: 'absent',
        employeeId: 'c',
        start: DateTime.utc(2026, 3, 10, 8),
        end: DateTime.utc(2026, 3, 10, 16),
      );
      final future = _shift(
        id: 'future',
        employeeId: 'd',
        start: DateTime.utc(2026, 3, 20, 8),
        end: DateTime.utc(2026, 3, 20, 16),
      );
      final rejected = _shift(
        id: 'rejected',
        employeeId: 'e',
        start: DateTime.utc(2026, 3, 10, 8),
        end: DateTime.utc(2026, 3, 10, 16),
      );
      final cancelled = _shift(
        id: 'cancelled',
        employeeId: 'f',
        start: DateTime.utc(2026, 3, 10, 8),
        end: DateTime.utc(2026, 3, 10, 16),
        status: ShiftStatus.cancelled,
      );
      final data = deriveAttendanceCalendarMonth(
        workspaceId: _workspace,
        timezoneName: 'Etc/UTC',
        year: 2026,
        month: 3,
        shifts: [present, present, late, absent, future, rejected, cancelled],
        attendance: [
          _attendanceRecord(id: 'p', shift: present),
          _attendanceRecord(id: 'p', shift: present),
          _attendanceRecord(id: 'l', shift: late, minutesLate: 12),
          _attendanceRecord(
            id: 'r',
            shift: rejected,
            reviewStatus: AttendanceReviewStatus.rejected,
          ),
          _attendanceRecord(
            id: 'u',
            shift: absent,
            reviewStatus: AttendanceReviewStatus.unknown,
          ),
        ],
        leaveRequests: [_leave('leave', 'g'), _leave('leave', 'g')],
        nowUtc: DateTime.utc(2026, 3, 15),
      );

      final march10 = data.days['2026-03-10']!;
      expect(march10.map((entry) => entry.status).toSet(), {
        CalendarAttendanceStatus.present,
        CalendarAttendanceStatus.late,
        CalendarAttendanceStatus.absent,
      });
      expect(
        march10.where((entry) => entry.employeeMembershipId == 'a'),
        hasLength(1),
      );
      expect(
        march10.where((entry) => entry.employeeMembershipId == 'f'),
        isEmpty,
      );
      expect(data.days['2026-03-20'], isNull);
      expect(
        data.days['2026-03-11']!.single.status,
        CalendarAttendanceStatus.leave,
      );
    },
  );

  test(
    'cubit retains data on refresh failure and rejects stale workspace data',
    () async {
      final repository = _CalendarRepository();
      final cubit = AttendanceCalendarCubit(
        repository,
        now: () => DateTime.utc(2026, 3, 10),
      );
      addTearDown(cubit.close);
      cubit.bindSession(_scope);
      await cubit.open();
      expect(cubit.state.hasData, isTrue);

      repository.error = const ApiException(message: 'Offline');
      await cubit.load(refresh: true);
      expect(cubit.state.hasData, isTrue);
      expect(cubit.state.failure?.message, 'Offline');

      repository.error = null;
      repository.pending = Completer<AttendanceCalendarMonth>();
      final pending = cubit.nextMonth();
      await Future<void>.delayed(Duration.zero);
      cubit.bindSession(
        const FeatureSessionScope(
          userId: 'other',
          workspaceId: 'other-workspace',
          membershipId: 'other-membership',
          timezone: 'Etc/UTC',
          role: WorkspaceRole.manager,
        ),
      );
      repository.pending!.complete(repository.value);
      await pending;
      expect(cubit.state.data, isNull);
    },
  );

  testWidgets('renders seven columns, legend and selected details at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final shift = _shift(
      id: 'shift',
      employeeId: 'employee-with-a-long-name',
      start: DateTime.utc(2026, 3, 10, 8),
      end: DateTime.utc(2026, 3, 10, 16),
    );
    final entry = AttendanceCalendarEntry(
      employeeMembershipId: shift.employeeMembershipId,
      employee: _employee(
        shift.employeeMembershipId,
        'An Employee With A Very Long Display Name',
      ),
      status: CalendarAttendanceStatus.present,
      shift: shift,
      attendance: _attendanceRecord(id: 'attendance', shift: shift),
    );
    final repository = _CalendarRepository()
      ..value = AttendanceCalendarMonth(
        year: 2026,
        month: 3,
        timezone: 'Etc/UTC',
        days: {
          '2026-03-10': [entry],
        },
      );
    final cubit = AttendanceCalendarCubit(
      repository,
      now: () => DateTime.utc(2026, 3, 10),
    )..bindSession(_scope);
    addTearDown(cubit.close);
    await cubit.open();

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: AttendanceCalendarStateView()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-grid')), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
    expect(find.text('Late'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
    expect(find.text('Holiday'), findsNothing);
    await tester.tap(find.byKey(const Key('calendar-day-2026-03-10')));
    await tester.pumpAndSettle();
    expect(
      find.text('An Employee With A Very Long Display Name'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull-to-refresh targets the selected attendance tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final attendanceRepository = _AttendanceRepository();
    final leaveRepository = _LeaveRepository();
    final calendarRepository = _CalendarRepository();
    final attendanceCubit = ManagerAttendanceCubit(attendanceRepository)
      ..bindSession(_scope);
    final leaveCubit = LeaveRequestsCubit(leaveRepository)..bindSession(_scope);
    final calendarCubit = AttendanceCalendarCubit(
      calendarRepository,
      now: () => DateTime.utc(2026, 3, 10),
    )..bindSession(_scope);
    addTearDown(attendanceCubit.close);
    addTearDown(leaveCubit.close);
    addTearDown(calendarCubit.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: attendanceCubit),
          BlocProvider.value(value: leaveCubit),
          BlocProvider.value(value: calendarCubit),
        ],
        child: const MaterialApp(home: AttendanceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final attendanceCalls = attendanceRepository.queries.length;
    await tester.drag(
      find.byKey(const Key('attendance-content')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(attendanceRepository.queries.length, attendanceCalls + 1);

    expect(find.byKey(const Key('attendance-tab-requests')), findsNothing);
    await tester.tap(find.byKey(const Key('attendance-tab-calendar')));
    await tester.pumpAndSettle();
    final calendarCalls = calendarRepository.calls;
    await tester.drag(
      find.byKey(const Key('attendance-content')),
      const Offset(0, 400),
    );
    await tester.pumpAndSettle();
    expect(calendarRepository.calls, calendarCalls + 1);
  });
}

const _emptyControls = <String, Object?>{
  'revision': 0,
  'closedAt': null,
  'overrides': [],
  'events': [],
  'summary': {'days': [], 'pending': 0, 'open': 0, 'pendingCorrections': 0},
};
