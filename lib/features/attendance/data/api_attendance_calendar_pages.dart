import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

const _pageSize = 100;
const _maximumPages = 1000;

Future<List<ShiftRecord>> fetchAllCalendarShifts({
  required ShiftRepository shifts,
  required bool employeeOnly,
  required String workspaceId,
  required DateTime from,
  required DateTime to,
}) async {
  final values = <ShiftRecord>[];
  for (var page = 1; page <= _maximumPages; page++) {
    final query = ShiftQuery(
      page: page,
      limit: _pageSize,
      from: from,
      to: to,
    );
    final result = employeeOnly
        ? await shifts.listMyShifts(workspaceId, query)
        : await shifts.listWorkspaceShifts(workspaceId, query);
    values.addAll(result.data);
    if (!_hasNext(result.pagination, page)) return _dedupe(values, (e) => e.id);
  }
  throw const FormatException('Shift pagination exceeded its safe limit');
}

Future<List<AttendanceRecordApi>> fetchAllCalendarAttendance({
  required AttendanceRepository attendance,
  required bool employeeOnly,
  required String workspaceId,
  required DateTime from,
  required DateTime to,
}) async {
  final values = <AttendanceRecordApi>[];
  for (var page = 1; page <= _maximumPages; page++) {
    final query = AttendanceQuery(
      page: page,
      limit: _pageSize,
      from: from,
      to: to,
    );
    final result = employeeOnly
        ? await attendance.listMyAttendance(workspaceId, query)
        : await attendance.listWorkspaceAttendance(workspaceId, query);
    values.addAll(result.data);
    if (!_hasNext(result.pagination, page)) return _dedupe(values, (e) => e.id);
  }
  throw const FormatException('Attendance pagination exceeded its safe limit');
}

Future<List<LeaveRequestRecord>> fetchAllCalendarLeave({
  required LeaveRequestRepository leaveRequests,
  required bool employeeOnly,
  required String workspaceId,
  required DateTime from,
  required DateTime to,
}) async {
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
        ? await leaveRequests.listMine(workspaceId, query)
        : await leaveRequests.listWorkspace(workspaceId, query);
    values.addAll(result.data);
    if (!_hasNext(result.pagination, page)) return _dedupe(values, (e) => e.id);
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
