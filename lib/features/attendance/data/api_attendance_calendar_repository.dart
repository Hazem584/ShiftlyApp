import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

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
