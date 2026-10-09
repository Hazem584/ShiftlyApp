import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';

class MockAttendanceRepository implements AttendanceRepository {
  const MockAttendanceRepository();

  AttendancePage _empty(int page, int limit) => AttendancePage(
    data: const [],
    pagination: ApiPagination(
      page: page,
      limit: limit,
      total: 0,
      totalPages: 0,
    ),
  );

  @override
  Future<AttendanceRecordApi> clockIn(String shiftId) =>
      throw UnsupportedError('No preview attendance');
  @override
  Future<AttendanceRecordApi> clockOut(String shiftId) =>
      throw UnsupportedError('No preview attendance');
  @override
  Future<AttendanceRecordApi> getWorkspaceAttendance(
    String workspaceId,
    String attendanceId,
  ) => throw UnsupportedError('No preview attendance');
  @override
  Future<AttendancePage> listAttendanceRequests(
    String workspaceId, {
    int page = 1,
    int limit = 20,
  }) async => _empty(page, limit);
  @override
  Future<AttendancePage> listMyAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) async => _empty(query.page, query.limit);
  @override
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) async => _empty(query.page, query.limit);
  @override
  Future<AttendanceRecordApi> reviewAttendance(
    String workspaceId,
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  }) => throw UnsupportedError('No preview attendance');
}
