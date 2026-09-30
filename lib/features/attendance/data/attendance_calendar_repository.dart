import 'package:equatable/equatable.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';
import 'package:timezone/timezone.dart' as timezone;

enum CalendarAttendanceStatus { present, absent, late, leave }

class AttendanceCalendarEntry extends Equatable {
  const AttendanceCalendarEntry({
    required this.employeeMembershipId,
    required this.employee,
    required this.status,
    this.shift,
    this.attendance,
    this.leave,
  });

  final String employeeMembershipId;
  final ShiftEmployeeSummary employee;
  final CalendarAttendanceStatus status;
  final ShiftRecord? shift;
  final AttendanceRecordApi? attendance;
  final LeaveRequestRecord? leave;

  @override
  List<Object?> get props => [
    employeeMembershipId,
    employee,
    status,
    shift,
    attendance,
    leave,
  ];
}

class AttendanceCalendarMonth extends Equatable {
  const AttendanceCalendarMonth({
    required this.year,
    required this.month,
    required this.timezone,
    required this.days,
  });

  final int year;
  final int month;
  final String timezone;
  final Map<String, List<AttendanceCalendarEntry>> days;

  List<AttendanceCalendarEntry> entriesFor(DateTime date) =>
      days[WorkspaceTime.localDateKey(
        year: date.year,
        month: date.month,
        day: date.day,
      )] ??
      const [];

  @override
  List<Object?> get props => [year, month, timezone, days];
}

abstract interface class AttendanceCalendarRepository {
  Future<AttendanceCalendarMonth> loadMonth({
    required String workspaceId,
    required String timezone,
    required int year,
    required int month,
  });
}

class ApiAttendanceCalendarRepository implements AttendanceCalendarRepository {
  ApiAttendanceCalendarRepository(
    this._shifts,
    this._attendance,
    this._leaveRequests, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _pageSize = 100;
  static const _maximumPages = 1000;
  final ShiftRepository _shifts;
  final AttendanceRepository _attendance;
  final LeaveRequestRepository _leaveRequests;
  final DateTime Function() _now;

  @override
  Future<AttendanceCalendarMonth> loadMonth({
    required String workspaceId,
    required String timezone,
    required int year,
    required int month,
  }) async {
    final range = WorkspaceTime.monthUtcRange(
      year: year,
      month: month,
      timezoneName: timezone,
    );
    final results = await Future.wait<Object>([
      _allShifts(workspaceId, range.start, range.end),
      _allAttendance(workspaceId, range.start, range.end),
      _allLeave(workspaceId, range.start, range.end),
    ]);
    return deriveAttendanceCalendarMonth(
      workspaceId: workspaceId,
      timezoneName: timezone,
      year: year,
      month: month,
      shifts: results[0] as List<ShiftRecord>,
      attendance: results[1] as List<AttendanceRecordApi>,
      leaveRequests: results[2] as List<LeaveRequestRecord>,
      nowUtc: _now().toUtc(),
    );
  }

  Future<List<ShiftRecord>> _allShifts(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) async {
    final values = <ShiftRecord>[];
    for (var page = 1; page <= _maximumPages; page++) {
      final result = await _shifts.listWorkspaceShifts(
        workspaceId,
        ShiftQuery(page: page, limit: _pageSize, from: from, to: to),
      );
      values.addAll(result.data);
      if (!_hasNext(result.pagination, page)) {
        return _dedupe(values, (e) => e.id);
      }
    }
    throw const FormatException('Shift pagination exceeded its safe limit');
  }

  Future<List<AttendanceRecordApi>> _allAttendance(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) async {
    final values = <AttendanceRecordApi>[];
    for (var page = 1; page <= _maximumPages; page++) {
      final result = await _attendance.listWorkspaceAttendance(
        workspaceId,
        AttendanceQuery(page: page, limit: _pageSize, from: from, to: to),
      );
      values.addAll(result.data);
      if (!_hasNext(result.pagination, page)) {
        return _dedupe(values, (e) => e.id);
      }
    }
    throw const FormatException(
      'Attendance pagination exceeded its safe limit',
    );
  }

  Future<List<LeaveRequestRecord>> _allLeave(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) async {
    final values = <LeaveRequestRecord>[];
    for (var page = 1; page <= _maximumPages; page++) {
      final result = await _leaveRequests.listWorkspace(
        workspaceId,
        LeaveRequestQuery(
          page: page,
          limit: _pageSize,
          from: from,
          to: to,
          status: LeaveRequestStatus.approved,
        ),
      );
      values.addAll(result.data);
      if (!_hasNext(result.pagination, page)) {
        return _dedupe(values, (e) => e.id);
      }
    }
    throw const FormatException('Leave pagination exceeded its safe limit');
  }

  bool _hasNext(ApiPagination pagination, int requestedPage) {
    if (pagination.page != requestedPage || pagination.totalPages < 0) {
      throw const FormatException('Invalid pagination response');
    }
    return requestedPage < pagination.totalPages;
  }

  List<T> _dedupe<T>(List<T> values, String Function(T) id) {
    final ids = <String>{};
    return values.where((value) => ids.add(id(value))).toList(growable: false);
  }
}

AttendanceCalendarMonth deriveAttendanceCalendarMonth({
  required String workspaceId,
  required String timezoneName,
  required int year,
  required int month,
  required List<ShiftRecord> shifts,
  required List<AttendanceRecordApi> attendance,
  required List<LeaveRequestRecord> leaveRequests,
  required DateTime nowUtc,
}) {
  final zone = WorkspaceTime.location(timezoneName);
  final monthStart = timezone.TZDateTime(zone, year, month);
  final monthEnd = timezone.TZDateTime(zone, year, month + 1);
  final validShifts = <String, ShiftRecord>{};
  for (final shift in shifts) {
    if (shift.workspaceId == workspaceId &&
        (shift.status == ShiftStatus.scheduled ||
            shift.status == ShiftStatus.completed)) {
      validShifts.putIfAbsent(shift.id, () => shift);
    }
  }
  final validAttendance = <String, AttendanceRecordApi>{};
  for (final record in attendance) {
    if (record.workspaceId == workspaceId &&
        record.reviewStatus != AttendanceReviewStatus.rejected &&
        record.reviewStatus != AttendanceReviewStatus.unknown &&
        record.shift.status != ShiftStatus.cancelled &&
        record.shift.status != ShiftStatus.unknown) {
      validAttendance.putIfAbsent(record.id, () => record);
    }
  }
  final approvedLeave = <String, LeaveRequestRecord>{};
  for (final request in leaveRequests) {
    if (request.workspaceId == workspaceId &&
        request.status == LeaveRequestStatus.approved) {
      approvedLeave.putIfAbsent(request.id, () => request);
    }
  }

  final days = <String, List<AttendanceCalendarEntry>>{};
  for (
    var day = monthStart;
    day.isBefore(monthEnd);
    day = timezone.TZDateTime(zone, day.year, day.month, day.day + 1)
  ) {
    final nextDay = timezone.TZDateTime(zone, day.year, day.month, day.day + 1);
    final key = WorkspaceTime.localDateKey(
      year: day.year,
      month: day.month,
      day: day.day,
    );
    final dayShifts = validShifts.values
        .where((item) {
          final start = item.startsAt.toUtc();
          return !start.isBefore(day.toUtc()) &&
              start.isBefore(nextDay.toUtc());
        })
        .toList(growable: false);
    final dayLeave = approvedLeave.values
        .where(
          (item) =>
              item.startsAt.isBefore(nextDay.toUtc()) &&
              item.endsAt.isAfter(day.toUtc()),
        )
        .toList(growable: false);
    final employees = <String>{
      ...dayShifts.map((item) => item.employeeMembershipId),
      ...dayLeave.map((item) => item.employeeMembershipId),
    };
    final entries = <AttendanceCalendarEntry>[];
    for (final employeeId in employees) {
      final employeeShifts = dayShifts
          .where((item) => item.employeeMembershipId == employeeId)
          .toList();
      final employeeLeave = dayLeave
          .where((item) => item.employeeMembershipId == employeeId)
          .firstOrNull;
      final records = validAttendance.values
          .where(
            (item) =>
                item.employeeMembershipId == employeeId &&
                employeeShifts.any((shift) => shift.id == item.shiftId),
          )
          .toList();
      final attendanceRecord = records.isEmpty ? null : records.first;
      final lateRecord = records
          .where((item) => item.minutesLate > 0)
          .firstOrNull;
      final shift = employeeShifts.firstOrNull;
      final employee =
          attendanceRecord?.employee ??
          shift?.employee ??
          employeeLeave?.employee;
      if (employee == null) continue;
      CalendarAttendanceStatus? status;
      if (lateRecord != null) {
        status = CalendarAttendanceStatus.late;
      } else if (attendanceRecord != null) {
        status = CalendarAttendanceStatus.present;
      } else if (employeeLeave != null) {
        status = CalendarAttendanceStatus.leave;
      } else if (employeeShifts.any((item) => !item.endsAt.isAfter(nowUtc))) {
        status = CalendarAttendanceStatus.absent;
      }
      if (status != null) {
        entries.add(
          AttendanceCalendarEntry(
            employeeMembershipId: employeeId,
            employee: employee,
            status: status,
            shift: shift,
            attendance: lateRecord ?? attendanceRecord,
            leave: employeeLeave,
          ),
        );
      }
    }
    if (entries.isNotEmpty) {
      entries.sort(
        (a, b) => a.employee.displayName.compareTo(b.employee.displayName),
      );
      days[key] = List.unmodifiable(entries);
    }
  }
  return AttendanceCalendarMonth(
    year: year,
    month: month,
    timezone: timezoneName,
    days: Map.unmodifiable(days),
  );
}
