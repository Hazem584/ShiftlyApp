import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._dio);
  final Dio _dio;

  @override
  Future<AttendanceRecordApi> clockIn(String shiftId) =>
      _object(() => _dio.post<Object?>('/shifts/$shiftId/clock-in'));

  @override
  Future<AttendanceRecordApi> clockOut(String shiftId) =>
      _object(() => _dio.post<Object?>('/shifts/$shiftId/clock-out'));

  @override
  Future<AttendancePage> listWorkspaceAttendance(
    String workspaceId,
    AttendanceQuery query,
  ) => _request(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/attendance',
      queryParameters: query.toQuery(),
    );
    return _page(response.data);
  });

  @override
  Future<AttendancePage> listAttendanceRequests(
    String workspaceId, {
    int page = 1,
    int limit = 20,
  }) => _request(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/attendance/requests',
      queryParameters: <String, Object?>{'page': page, 'limit': limit},
    );
    return _page(response.data);
  });

  @override
  Future<AttendanceRecordApi> getWorkspaceAttendance(
    String workspaceId,
    String attendanceId,
  ) => _object(
    () =>
        _dio.get<Object?>('/workspaces/$workspaceId/attendance/$attendanceId'),
  );

  @override
  Future<AttendanceRecordApi> reviewAttendance(
    String workspaceId,
    String attendanceId,
    AttendanceReviewDecision decision, {
    String? rejectionReason,
  }) => _object(
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
  ) => _request(() async {
    final response = await _dio.get<Object?>(
      '/attendance/me',
      queryParameters: {
        ...query.toQuery(includeEmployee: false, includeShiftStatus: false),
        'workspaceId': workspaceId,
      },
    );
    return _page(response.data);
  });

  Future<AttendanceRecordApi> _object(
    Future<Response<Object?>> Function() operation,
  ) => _request(() async {
    final response = await operation();
    return AttendanceRecordApi.fromJson(ApiModelParser.map(response.data));
  });

  AttendancePage _page(Object? value) {
    final json = ApiModelParser.map(value);
    return AttendancePage(
      data: ApiModelParser.list(json['data'], 'data')
          .map((item) => AttendanceRecordApi.fromJson(ApiModelParser.map(item)))
          .toList(growable: false),
      pagination: ApiPagination.fromJson(
        ApiModelParser.map(json['pagination'], 'pagination'),
      ),
    );
  }

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(
        error is DioException && error.error != null ? error.error! : error,
      );
    }
  }
}
