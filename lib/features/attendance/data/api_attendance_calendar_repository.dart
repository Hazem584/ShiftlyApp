import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

import '../domain/entities/attendance_month_control.dart';
import '../domain/services/apply_attendance_day_decisions.dart';

class ApiAttendanceCalendarRepository implements AttendanceCalendarRepository {
  ApiAttendanceCalendarRepository(
    this._shifts,
    this._attendance,
    this._leaveRequests, {
    required this.dio,
    this.employeeOnly = false,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const _pageSize = 100;
  static const _maximumPages = 1000;
  final Dio? dio;
  final bool employeeOnly;
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
      // Template check-in windows can extend 24 hours before/after the
      // scheduled start. Include neighbouring days, then filter by the
      // server's operational date so month-edge overnight records survive.
      _allAttendance(
        workspaceId,
        range.start.subtract(const Duration(days: 2)),
        range.end.add(const Duration(days: 2)),
      ),
      _allLeave(workspaceId, range.start, range.end),
      _scheduled(workspaceId, year, month),
      _controls(workspaceId, year, month),
    ]);
    final scheduled = results[3] as ({List<ShiftRecord> shifts, DateTime now});
    final derived = deriveAttendanceCalendarMonth(
      workspaceId: workspaceId,
      timezoneName: timezone,
      year: year,
      month: month,
      shifts: [...results[0] as List<ShiftRecord>, ...scheduled.shifts],
      attendance: results[1] as List<AttendanceRecordApi>,
      leaveRequests: results[2] as List<LeaveRequestRecord>,
      nowUtc: scheduled.now,
    );
    return applyAttendanceDayDecisions(
      derived,
      results[4] as AttendanceMonthControl,
    );
  }

  Future<AttendanceMonthControl> _controls(
    String workspaceId,
    int year,
    int month,
  ) async {
    if (dio == null) return const AttendanceMonthControl();
    final response = await dio!.get<Object?>(
      '/workspaces/$workspaceId/attendance-controls',
      queryParameters: {'year': year, 'month': month},
    );
    return AttendanceMonthControl.fromJson(ApiModelParser.map(response.data));
  }

  Future<({List<ShiftRecord> shifts, DateTime now})> _scheduled(
    String workspaceId,
    int year,
    int month,
  ) async {
    if (dio == null) return (shifts: <ShiftRecord>[], now: _now().toUtc());
    final result = await dio!.get<Object?>(
      '/workspaces/$workspaceId/attendance-schedule',
      queryParameters: {'year': year, 'month': month},
    );
    final json = ApiModelParser.map(result.data);
    return (
      shifts: ApiModelParser.list(
        json['data'],
        'data',
      ).map((e) => ShiftRecord.fromJson(ApiModelParser.map(e))).toList(),
      now: ApiModelParser.date(json, 'evaluatedAt'),
    );
  }

  Future<List<ShiftRecord>> _allShifts(
    String workspaceId,
    DateTime from,
    DateTime to,
  ) async {
    final values = <ShiftRecord>[];
    for (var page = 1; page <= _maximumPages; page++) {
      final query = ShiftQuery(
        page: page,
        limit: _pageSize,
        from: from,
        to: to,
      );
      final result = employeeOnly
          ? await _shifts.listMyShifts(workspaceId, query)
          : await _shifts.listWorkspaceShifts(workspaceId, query);
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
      final query = AttendanceQuery(
        page: page,
        limit: _pageSize,
        from: from,
        to: to,
      );
      final result = employeeOnly
          ? await _attendance.listMyAttendance(workspaceId, query)
          : await _attendance.listWorkspaceAttendance(workspaceId, query);
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
      final query = LeaveRequestQuery(
        page: page,
        limit: _pageSize,
        from: from,
        to: to,
        status: LeaveRequestStatus.approved,
      );
      final result = employeeOnly
          ? await _leaveRequests.listMine(workspaceId, query)
          : await _leaveRequests.listWorkspace(workspaceId, query);
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
