import 'package:dio/dio.dart';
import 'package:shiftly/features/attendance/data/api_leave_request_parser.dart';
import 'package:shiftly/features/attendance/domain/repositories/leave_request_repository.dart';

class ApiLeaveRequestRepository implements LeaveRequestRepository {
  ApiLeaveRequestRepository(this._dio);
  final Dio _dio;

  @override
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  ) => parseLeaveRecordResponse(
    () =>
        _dio.post<Object?>('/leave-requests', data: input.toJson(workspaceId)),
  );

  @override
  Future<LeaveRequestPage> listMine(
    String workspaceId,
    LeaveRequestQuery query,
  ) => runLeaveApiRequest(() async {
    final response = await _dio.get<Object?>(
      '/leave-requests/me',
      queryParameters: {
        ...query.toQuery(manager: false),
        'workspaceId': workspaceId,
      },
    );
    return parseLeavePageResponse(response.data);
  });

  @override
  Future<LeaveRequestRecord> getMine(String requestId) =>
      parseLeaveRecordResponse(
        () => _dio.get<Object?>('/leave-requests/me/$requestId'),
      );

  @override
  Future<LeaveRequestRecord> cancelMine(String requestId) =>
      parseLeaveRecordResponse(
        () => _dio.patch<Object?>('/leave-requests/me/$requestId/cancel'),
      );

  @override
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  ) => runLeaveApiRequest(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/leave-requests',
      queryParameters: query.toQuery(manager: true),
    );
    return parseLeavePageResponse(response.data);
  });

  @override
  Future<LeaveRequestRecord> getWorkspace(
    String workspaceId,
    String requestId,
  ) => parseLeaveRecordResponse(
    () =>
        _dio.get<Object?>('/workspaces/$workspaceId/leave-requests/$requestId'),
  );

  @override
  Future<LeaveRequestRecord> review(
    String workspaceId,
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  }) => parseLeaveRecordResponse(
    () => _dio.patch<Object?>(
      '/workspaces/$workspaceId/leave-requests/$requestId/review',
      data: {
        'decision': decision == LeaveReviewDecision.approved
            ? 'APPROVED'
            : 'REJECTED',
        if (decision == LeaveReviewDecision.rejected)
          'rejectionReason': rejectionReason?.trim(),
      },
    ),
  );
}
