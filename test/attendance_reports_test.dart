import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/reports/data/api_attendance_report_repository.dart';
import 'package:shiftly/features/reports/domain/attendance_report.dart';
import 'package:shiftly/features/reports/presentation/attendance_reports_cubit.dart';
import 'package:shiftly/features/shifts/domain/entities/attendance_review_status.dart';

import 'support/report_fixtures.dart';

void main() {
  test('weekly range starts Saturday and crosses a year boundary', () {
    final range = ReportRange.forPeriod(
      ReportPeriod.weekly,
      DateTime.utc(2027, 1, 1),
    );
    expect(range.startKey, '2026-12-26');
    expect(range.endKey, '2027-01-01');
    expect(range.move(ReportPeriod.weekly, 1).startKey, '2027-01-02');
  });
  test('monthly ranges handle leap years and previous/next year', () {
    expect(
      ReportRange.forPeriod(
        ReportPeriod.monthly,
        DateTime.utc(2028, 2, 10),
      ).days,
      29,
    );
    final range = ReportRange.forPeriod(
      ReportPeriod.monthly,
      DateTime.utc(2026, 12),
    );
    expect(range.move(ReportPeriod.monthly, 1).endKey, '2027-01-31');
  });
  test('inclusive local dates preserve spring and autumn DST boundaries', () {
    final spring = ReportRange(
      DateTime.utc(2026, 3, 8),
      DateTime.utc(2026, 3, 8),
    ).utcBounds('America/New_York');
    final autumn = ReportRange(
      DateTime.utc(2026, 11, 1),
      DateTime.utc(2026, 11, 1),
    ).utcBounds('America/New_York');
    expect(
      spring.to
          .add(const Duration(microseconds: 1))
          .difference(spring.from)
          .inHours,
      23,
    );
    expect(
      autumn.to
          .add(const Duration(microseconds: 1))
          .difference(autumn.from)
          .inHours,
      25,
    );
    expect(() => reportRange.utcBounds('Invalid/Zone'), throwsFormatException);
  });
  test('rejects reversed and excessively long custom periods', () {
    expect(
      () => ReportRange(DateTime.utc(2026, 2), DateTime.utc(2026)),
      throwsFormatException,
    );
    expect(
      () => ReportRange(DateTime.utc(2026), DateTime.utc(2027, 1, 2)),
      throwsFormatException,
    );
  });
  test('hours and lateness exclude pending, rejected and unknown records', () {
    final report = fixtureReport(
      records: [
        reportRecord(),
        reportRecord(id: 'pending', status: AttendanceReviewStatus.pending),
        reportRecord(id: 'rejected', status: AttendanceReviewStatus.rejected),
        reportRecord(id: 'unknown', status: AttendanceReviewStatus.unknown),
      ],
    );
    final m = report.totalsFor(null);
    expect(m.workMinutes, 540);
    expect(m.excessMinutes, 60);
    expect(m.late, 1);
    expect(m.lateMinutes, 15);
    expect((m.pending, m.rejected, m.unknown), (1, 1, 1));
  });
  test(
    'extra hours are a subset of worked hours and do not double count excess',
    () {
      final m = fixtureReport(
        records: [
          reportRecord(),
          reportRecord(id: 'extra', extra: true, work: 180),
        ],
      ).totalsFor(null);
      expect((m.workMinutes, m.extraMinutes, m.excessMinutes), (720, 180, 60));
    },
  );
  test(
    'open records count attendance and lateness but never contribute hours',
    () {
      final m = fixtureReport(records: [reportRecord(open: true)])
          .totalsFor(null);
      expect((m.attendanceDays, m.approved, m.open, m.late), (1, 1, 1, 1));
      expect((m.workMinutes, m.extraMinutes, m.excessMinutes), (0, 0, 0));
    },
  );
  test(
    'missing schedule/duration is surfaced without guessing payroll hours',
    () {
      final m = fixtureReport(
        records: [reportRecord(work: null, scheduled: false)],
      ).totalsFor(null);
      expect((m.missingSchedule, m.missingWorkMinutes), (1, 1));
      expect((m.workMinutes, m.excessMinutes), (0, 0));
    },
  );
  test('same local day counts once per employee, overnight records use clock-in date', () {
    final report = fixtureReport(
      records: [
        reportRecord(clockIn: DateTime.utc(2026, 10, 1, 22)),
        reportRecord(id: 'second-shift', clockIn: DateTime.utc(2026, 10, 2, 5)),
        reportRecord(id: 'second-employee', employeeId: 'second', work: 60),
      ],
    );
    expect(report.totalsFor('employee').attendanceDays, 1);
    expect(report.totalsFor(null).attendanceDays, 2);
    expect(report.recordsFor('second').length, 1);
    expect(report.totalsFor('second').workMinutes, 60);
  });
  test('employees without records appear with zero totals', () {
    expect(fixtureReport().rowsFor('second').single.metrics.approved, 0);
  });
  group('complete manager API pagination', () {
    late _Attendance attendance;
    late _Employees employees;
    late ApiAttendanceReportRepository repository;
    setUp(() {
      attendance = _Attendance(
        List.generate(101, (i) => reportRecord(id: '$i')),
      );
      employees = _Employees(List.generate(101, (i) => rosterEmployee('$i')));
      repository = ApiAttendanceReportRepository(attendance, employees);
    });
    Future<AttendanceReport> load({bool Function()? current}) =>
        repository.load(
          workspaceId: 'workspace',
          workspaceName: 'Test',
          timezone: 'Africa/Cairo',
          range: reportRange,
          isCurrent: current ?? () => true,
        );
    test(
      'loads all pages and preserves historical employees absent from roster',
      () async {
        final report = await load();
        expect(report.records.length, 101);
        expect(attendance.queries.map((q) => q.page), [1, 2]);
        expect(employees.pages, [1, 2]);
        expect(report.employees.length, 102);
        expect(attendance.queries.first.from, DateTime.utc(2026, 9, 30, 21));
        expect(report.totalsFor(null).workMinutes, 101 * 540);
      },
    );
    test('fails the entire report if a later page fails', () async {
      attendance.failPage = 2;
      await expectLater(load(), throwsA(isA<ApiException>()));
    });
    test(
      'detects changed totals and refuses partial exportable data',
      () async {
        attendance.changeTotal = true;
        await expectLater(load(), throwsA(isA<ApiException>()));
      },
    );
    test('detects duplicate page data', () async {
      attendance.records[100] = attendance.records[0];
      await expectLater(load(), throwsA(isA<ApiException>()));
    });
    test(
      'rejects cross-workspace data and records outside the selected period',
      () async {
        attendance.records[0] = reportRecord(workspaceId: 'other');
        await expectLater(load(), throwsA(isA<ApiException>()));
        attendance.records[0] = reportRecord(clockIn: DateTime.utc(2026, 9));
        await expectLater(load(), throwsA(isA<ApiException>()));
      },
    );
    test(
      'stops before requesting further pages on scope cancellation',
      () async {
        await expectLater(
          load(current: () => attendance.queries.isEmpty),
          throwsA(isA<ApiException>()),
        );
        expect(attendance.queries.length, 1);
        expect(employees.pages, isEmpty);
      },
    );
    test('empty attendance still loads the complete employee roster', () async {
      attendance.records.clear();
      final report = await load();
      expect(report.records, isEmpty);
      expect(report.employees.length, 101);
      expect(report.totalsFor(null).workMinutes, 0);
    });
  });
  group('account scoped reports', () {
    late _Reports repository;
    late AttendanceReportsCubit cubit;
    setUp(() {
      repository = _Reports();
      cubit = AttendanceReportsCubit(
        repository,
        now: () => DateTime.utc(2026, 10, 10),
      );
    });
    tearDown(() => cubit.close());
    test('employee roles cannot load manager reports', () async {
      cubit.bindSession(
        const FeatureSessionScope(
          userId: 'user',
          workspaceId: 'workspace',
          membershipId: 'employee',
          timezone: 'Africa/Cairo',
          role: WorkspaceRole.employee,
        ),
      );
      await cubit.open();
      expect(repository.pending, isEmpty);
    });
    test('logout discards a late result and clears all report data', () async {
      cubit.bindSession(reportScope);
      final load = cubit.open();
      cubit.bindSession(null);
      repository.pending.single.complete(fixtureReport());
      await load;
      expect(cubit.state.report, isNull);
      expect(cubit.state.range, isNull);
    });
    test(
      'latest selected period wins if requests return out of order',
      () async {
        cubit.bindSession(reportScope);
        final first = cubit.open();
        final second = cubit.selectPeriod(ReportPeriod.weekly);
        repository.pending[1].complete(
          fixtureReport(range: repository.ranges[1]),
        );
        await second;
        repository.pending[0].complete(fixtureReport());
        await first;
        expect(cubit.state.period, ReportPeriod.weekly);
        expect(cubit.state.report!.range.days, 7);
      },
    );
    test(
      'filters stay consistent and mutations disable exports until refresh',
      () async {
        cubit.bindSession(reportScope);
        final load = cubit.open();
        final report = fixtureReport();
        repository.pending.single.complete(report);
        await load;
        cubit.selectEmployee('second');
        expect(cubit.state.employeeId, 'second');
        expect(cubit.canExport(report), isTrue);
        cubit.invalidate();
        expect(cubit.state.report, isNull);
        expect(cubit.canExport(report), isFalse);
      },
    );
    test(
      'cross-workspace responses become failures without showing data',
      () async {
        cubit.bindSession(reportScope);
        final load = cubit.open();
        repository.pending.single.complete(fixtureReport(workspaceId: 'other'));
        await load;
        expect(cubit.state.report, isNull);
        expect(cubit.state.failure, isNotNull);
      },
    );
  });
}

class _Attendance implements AttendanceRepository {
  _Attendance(this.records);
  final List<AttendanceRecordApi> records;
  final queries = <AttendanceQuery>[];
  int? failPage;
  bool changeTotal = false;
  @override
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) async {
    queries.add(query);
    if (query.page == failPage) {
      throw const ApiException(message: 'Network failure');
    }
    final total = records.length + (changeTotal && query.page == 2 ? 1 : 0);
    return AttendancePage(
      data: records
          .skip((query.page - 1) * query.limit)
          .take(query.limit)
          .toList(),
      pagination: ApiPagination(
        page: query.page,
        limit: query.limit,
        total: total,
        totalPages: (total / query.limit).ceil(),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Employees implements EmployeeRepository {
  _Employees(this.records);
  final List<Employee> records;
  final pages = <int>[];
  @override
  Future<EmployeePage> listEmployees({
    required String workspaceId,
    String search = '',
    EmployeeStatusFilter? status,
    int page = 1,
    int limit = 20,
  }) async {
    pages.add(page);
    return EmployeePage(
      data: records.skip((page - 1) * limit).take(limit).toList(),
      page: page,
      limit: limit,
      total: records.length,
      totalPages: (records.length / limit).ceil(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reports implements AttendanceReportRepository {
  final pending = <Completer<AttendanceReport>>[];
  final ranges = <ReportRange>[];
  @override
  Future<AttendanceReport> load({
    required String workspaceId,
    required String workspaceName,
    required String timezone,
    required ReportRange range,
    required bool Function() isCurrent,
  }) {
    ranges.add(range);
    final completer = Completer<AttendanceReport>();
    pending.add(completer);
    return completer.future;
  }
}
