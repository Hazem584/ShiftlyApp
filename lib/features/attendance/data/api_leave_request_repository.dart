import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';

class ApiLeaveRequestRepository implements LeaveRequestRepository {
  ApiLeaveRequestRepository(this._dio);
  final Dio _dio;

  @override
  Future<LeaveRequestRecord> create(
    String workspaceId,
    CreateLeaveRequestInput input,
  ) => _object(
    () =>
        _dio.post<Object?>('/leave-requests', data: input.toJson(workspaceId)),
  );

  @override
  Future<LeaveRequestPage> listMine(
    String workspaceId,
    LeaveRequestQuery query,
  ) => _request(() async {
    final response = await _dio.get<Object?>(
      '/leave-requests/me',
      queryParameters: {
        ...query.toQuery(manager: false),
        'workspaceId': workspaceId,
      },
    );
    return _page(response.data);
  });

  @override
  Future<LeaveRequestRecord> getMine(String requestId) =>
      _object(() => _dio.get<Object?>('/leave-requests/me/$requestId'));

  @override
  Future<LeaveRequestRecord> cancelMine(String requestId) => _object(
    () => _dio.patch<Object?>('/leave-requests/me/$requestId/cancel'),
  );

  @override
  Future<LeaveRequestPage> listWorkspace(
    String workspaceId,
    LeaveRequestQuery query,
  ) => _request(() async {
    final response = await _dio.get<Object?>(
      '/workspaces/$workspaceId/leave-requests',
      queryParameters: query.toQuery(manager: true),
    );
    return _page(response.data);
  });

  @override
  Future<LeaveRequestRecord> getWorkspace(
    String workspaceId,
    String requestId,
  ) => _object(
    () =>
        _dio.get<Object?>('/workspaces/$workspaceId/leave-requests/$requestId'),
  );

  @override
  Future<LeaveRequestRecord> review(
    String workspaceId,
    String requestId,
    LeaveReviewDecision decision, {
    String? rejectionReason,
  }) => _object(
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

  Future<LeaveRequestRecord> _object(
    Future<Response<Object?>> Function() operation,
  ) => _request(() async {
    final response = await operation();
    return LeaveRequestRecord.fromJson(ApiModelParser.map(response.data));
  });

  LeaveRequestPage _page(Object? value) {
    final json = ApiModelParser.map(value);
    return LeaveRequestPage(
      data: ApiModelParser.list(json['data'], 'data')
          .map((item) => LeaveRequestRecord.fromJson(ApiModelParser.map(item)))
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
      throw ApiErrorParser.parse(error);
    }
  }
}
