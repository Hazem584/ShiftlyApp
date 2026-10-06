part of '../../attendance_repository.dart';

abstract interface class AttendanceRepository {
  Future<AttendanceRecordApi> clockIn(String shiftId);
  Future<AttendanceRecordApi> clockOut(String shiftId);
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  );
  Future<AttendancePage> listAttendanceRequests(
    String workspaceId, {
    int page = 1,
    int limit = 20,
  });
  Future<AttendanceRecordApi> getWorkspaceAttendance(
    String workspaceId,
    String attendanceId,
  );
  Future<AttendanceRecordApi> reviewAttendance(
    String workspaceId,
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  });
  Future<AttendancePage> listMyAttendance(
    String workspaceId,
    AttendanceQuery query,
  );
}
