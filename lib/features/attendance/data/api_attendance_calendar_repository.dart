import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/data/api_attendance_calendar_pages.dart';
import 'package:shiftly/features/attendance/domain/entities/attendance_month_control.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_calendar_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/attendance/domain/services/apply_attendance_day_decisions.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class ApiAttendanceCalendarRepository implements AttendanceCalendarRepository {
  ApiAttendanceCalendarRepository(
    this._shifts,
    this._attendance,
    this._leaveRequests, {
    required this.dio,
    this.employeeOnly = false,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

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
      fetchAllCalendarShifts(
        shifts: _shifts,
        employeeOnly: employeeOnly,
        workspaceId: workspaceId,
        from: range.start,
        to: range.end,
      ),
      fetchAllCalendarAttendance(
        attendance: _attendance,
        employeeOnly: employeeOnly,
        workspaceId: workspaceId,
        from: range.start.subtract(const Duration(days: 2)),
        to: range.end.add(const Duration(days: 2)),
      ),
      fetchAllCalendarLeave(
        leaveRequests: _leaveRequests,
        employeeOnly: employeeOnly,
        workspaceId: workspaceId,
        from: range.start,
        to: range.end,
      ),
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
}
