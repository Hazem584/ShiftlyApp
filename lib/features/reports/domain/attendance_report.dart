import 'dart:math' as math;

import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_record_api.dart';
import 'package:shiftly/features/shifts/domain/entities/attendance_review_status.dart';

enum ReportPeriod { weekly, monthly, custom }

class ReportRange {
  ReportRange(DateTime start, DateTime end)
    : start = DateTime.utc(start.year, start.month, start.day),
      end = DateTime.utc(end.year, end.month, end.day) {
    if (this.end.isBefore(this.start) || days > 366) {
      throw const FormatException('Choose a period of up to 366 days.');
    }
  }

  final DateTime start;
  final DateTime end;
  int get days => end.difference(start).inDays + 1;
  String get startKey => _key(start);
  String get endKey => _key(end);
  String get label => '$startKey — $endKey';

  static String _key(DateTime date) => WorkspaceTime.localDateKey(
    year: date.year,
    month: date.month,
    day: date.day,
  );

  static ReportRange forPeriod(ReportPeriod period, DateTime localDate) {
    final date = DateTime.utc(localDate.year, localDate.month, localDate.day);
    if (period == ReportPeriod.monthly) {
      return ReportRange(
        DateTime.utc(date.year, date.month),
        DateTime.utc(date.year, date.month + 1, 0),
      );
    }
    // Saturday through Friday, using calendar dates rather than elapsed hours.
    final start = date.subtract(Duration(days: (date.weekday + 1) % 7));
    return ReportRange(start, start.add(const Duration(days: 6)));
  }

  ReportRange move(ReportPeriod period, int direction) {
    if (period == ReportPeriod.monthly) {
      return forPeriod(
        period,
        DateTime.utc(start.year, start.month + direction),
      );
    }
    final delta = Duration(days: days * direction);
    return ReportRange(start.add(delta), end.add(delta));
  }

  ({DateTime from, DateTime to}) utcBounds(String timezone) {
    if (!WorkspaceTime.isValid(timezone)) {
      throw const FormatException('Invalid report timezone');
    }
    final next = end.add(const Duration(days: 1));
    return (
      from: WorkspaceTime.wallTimeToUtc(
        date: start,
        hour: 0,
        minute: 0,
        timezoneName: timezone,
      ),
      to: WorkspaceTime.wallTimeToUtc(
        date: next,
        hour: 0,
        minute: 0,
        timezoneName: timezone,
      ).subtract(const Duration(microseconds: 1)),
    );
  }
}

class ReportEmployee {
  const ReportEmployee(this.id, this.name);
  final String id;
  final String name;
}

class ReportMetrics {
  const ReportMetrics({
    this.attendanceDays = 0,
    this.approved = 0,
    this.pending = 0,
    this.rejected = 0,
    this.unknown = 0,
    this.open = 0,
    this.late = 0,
    this.lateMinutes = 0,
    this.workMinutes = 0,
    this.extraMinutes = 0,
    this.excessMinutes = 0,
    this.missingSchedule = 0,
    this.missingWorkMinutes = 0,
  });
  final int attendanceDays,
      approved,
      pending,
      rejected,
      unknown,
      open,
      late,
      lateMinutes,
      workMinutes,
      extraMinutes,
      excessMinutes,
      missingSchedule,
      missingWorkMinutes;

  ReportMetrics operator +(ReportMetrics other) => ReportMetrics(
    attendanceDays: attendanceDays + other.attendanceDays,
    approved: approved + other.approved,
    pending: pending + other.pending,
    rejected: rejected + other.rejected,
    unknown: unknown + other.unknown,
    open: open + other.open,
    late: late + other.late,
    lateMinutes: lateMinutes + other.lateMinutes,
    workMinutes: workMinutes + other.workMinutes,
    extraMinutes: extraMinutes + other.extraMinutes,
    excessMinutes: excessMinutes + other.excessMinutes,
    missingSchedule: missingSchedule + other.missingSchedule,
    missingWorkMinutes: missingWorkMinutes + other.missingWorkMinutes,
  );
}

class ReportEmployeeRow {
  const ReportEmployeeRow(this.employee, this.metrics);
  final ReportEmployee employee;
  final ReportMetrics metrics;
}

class AttendanceReport {
  AttendanceReport({
    required this.workspaceId,
    required this.workspaceName,
    required this.timezone,
    required this.range,
    required this.generatedAt,
    required List<ReportEmployee> employees,
    required List<AttendanceRecordApi> records,
  }) : employees = List.unmodifiable(employees),
       records = List.unmodifiable(records);

  final String workspaceId, workspaceName, timezone;
  final ReportRange range;
  final DateTime generatedAt;
  final List<ReportEmployee> employees;
  final List<AttendanceRecordApi> records;

  List<AttendanceRecordApi> recordsFor(String? employeeId) => records
      .where((r) => employeeId == null || r.employeeMembershipId == employeeId)
      .toList(growable: false);

  List<ReportEmployeeRow> rowsFor(String? employeeId) => employees
      .where((e) => employeeId == null || e.id == employeeId)
      .map(
        (e) => ReportEmployeeRow(
          e,
          _employeeMetrics[e.id] ?? const ReportMetrics(),
        ),
      )
      .toList(growable: false);

  late final Map<String, ReportMetrics> _employeeMetrics = _buildMetrics();

  Map<String, ReportMetrics> _buildMetrics() {
    final grouped = <String, List<AttendanceRecordApi>>{};
    for (final r in records) {
      grouped.putIfAbsent(r.employeeMembershipId, () => []).add(r);
    }
    return grouped.map((id, values) => MapEntry(id, _metrics(values)));
  }

  ReportMetrics totalsFor(String? employeeId) =>
      rowsFor(employeeId)
          .fold(const ReportMetrics(), (sum, row) => sum + row.metrics);

  ReportMetrics _metrics(List<AttendanceRecordApi> values) {
    var result = const ReportMetrics();
    final days = <String>{};
    for (final r in values) {
      switch (r.reviewStatus) {
        case AttendanceReviewStatus.pending:
          result += const ReportMetrics(pending: 1);
        case AttendanceReviewStatus.rejected:
          result += const ReportMetrics(rejected: 1);
        case AttendanceReviewStatus.unknown:
          result += const ReportMetrics(unknown: 1);
        case AttendanceReviewStatus.approved:
          days.add(WorkspaceTime.dateKey(r.clockInAt, timezone));
          final closed = r.clockOutAt != null;
          final work = closed ? r.workedMinutes ?? 0 : 0;
          final extra = r.occurrenceKind == 'EXTRA';
          final start = r.scheduledStartAt ?? r.shift?.startsAt;
          final end = r.scheduledEndAt ?? r.shift?.endsAt;
          final scheduled = start != null && end != null
              ? end.difference(start).inMinutes
              : null;
          result += ReportMetrics(
            approved: 1,
            open: closed ? 0 : 1,
            late: r.minutesLate > 0 ? 1 : 0,
            lateMinutes: r.minutesLate,
            workMinutes: work,
            extraMinutes: extra ? work : 0,
            excessMinutes: !extra && scheduled != null && scheduled > 0
                ? math.max(0, work - scheduled)
                : 0,
            missingSchedule:
                closed && !extra && (scheduled == null || scheduled <= 0)
                ? 1
                : 0,
            missingWorkMinutes: closed && r.workedMinutes == null ? 1 : 0,
          );
      }
    }
    return result + ReportMetrics(attendanceDays: days.length);
  }
}

abstract interface class AttendanceReportRepository {
  Future<AttendanceReport> load({
    required String workspaceId,
    required String workspaceName,
    required String timezone,
    required ReportRange range,
    required bool Function() isCurrent,
  });
}
