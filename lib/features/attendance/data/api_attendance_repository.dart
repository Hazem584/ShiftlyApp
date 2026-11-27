import 'package:dio/dio.dart';
import 'package:shiftly/features/attendance/data/api_attendance_parser.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._dio);
  final Dio _dio;

  @override
  Future<AttendanceRecordApi> clockIn(String shiftId) =>
      parseAttendanceRecordResponse(
        () => _dio.post<Object?>('/shifts/$shiftId/clock-in'),
      );

  @override
  Future<AttendanceRecordApi> clockOut(String shiftId) =>
      parseAttendanceRecordResponse(
        () => _dio.post<Object?>('/shifts/$shiftId/clock-out'),
      );

  @override
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) => runAttendanceApiRequest(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/attendance',
      queryParameters: query.toQuery(),
    );
    return parseAttendancePageResponse(response.data);
  });

  @override
  Future<AttendancePage> listAttendanceRequests(
    String workspaceId, {
    int page = 1,
    int limit = 20,
  }) => runAttendanceApiRequest(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/attendance/requests',
      queryParameters: <String, Object?>{'page': page, 'limit': limit},
    );
    return parseAttendancePageResponse(response.data);
  });

  @override
  Future<AttendanceRecordApi> getWorkspaceAttendance(
    String workspaceId,
    String attendanceId,
  ) => parseAttendanceRecordResponse(
    () =>
        _dio.get<Object?>('/workspaces/$workspaceId/attendance/$attendanceId'),
  );

  @override
  Future<AttendanceRecordApi> reviewAttendance(
    String workspaceId,
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  }) => parseAttendanceRecordResponse(
    () => _dio.patch<Object?>(
      '/workspaces/$workspaceId/attendance/$attendanceId/review',
      data: <String, Object?>{
        'decision': decision == AttendanceReviewDecision.approved
            ? 'APPROVED'
            : 'REJECTED',
        if (decision == AttendanceReviewDecision.rejected)
          'rejectionReason': rejectionReason?.trim(),
      },
    ),
  );

  @override
  Future<AttendancePage> listMyAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) => runAttendanceApiRequest(() async {
    final response = await _dio.get<Object?>(
      '/attendance/me',
      queryParameters: {
        ...query.toQuery(includeEmployee: false, includeShiftStatus: false),
        'workspaceId': workspaceId,
      },
    );
    return parseAttendancePageResponse(response.data);
  });
}
