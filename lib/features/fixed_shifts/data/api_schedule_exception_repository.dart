import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';

class ApiScheduleExceptionRepository implements ScheduleExceptionRepository {
  ApiScheduleExceptionRepository(this._dio);
  final Dio _dio;
  String _path(String w) => '/workspaces/$w/schedule-exceptions';
  @override
  Future<ScheduleExceptionPage> list(
    String workspaceId, {
    String? employeeMembershipId,
    int page = 1,
  }) => _request(() async {
    final response = await _dio.get<Object?>(
      _path(workspaceId),
      queryParameters: {
        'page': page,
        'limit': 20,
        'employeeMembershipId': ?employeeMembershipId,
      },
    );
    final json = ApiModelParser.map(response.data);
    final rows = ApiModelParser.list(json['data'])
        .map((e) => ScheduleException.fromJson(ApiModelParser.map(e)))
        .toList();
    if (rows.any(
      (e) =>
          e.workspaceId != workspaceId ||
          (e.employeeMembershipId != null &&
              e.employeeMembershipId != employeeMembershipId),
    )) {
      throw const FormatException('Cross-scope schedule exceptions');
    }
    return ScheduleExceptionPage(
      rows,
      ApiPagination.fromJson(ApiModelParser.map(json['pagination'])),
    );
  });
  @override
  Future<ScheduleException> create(
    String workspaceId, {
    required String clientExceptionId,
    required String kind,
    required String operationalDate,
    required String reason,
    String? employeeMembershipId,
    String? shiftTemplateId,
  }) => _request(() async {
    final response = await _dio.post<Object?>(
      _path(workspaceId),
      data: {
        'clientExceptionId': clientExceptionId,
        'kind': kind,
        'operationalDate': operationalDate,
        'reason': reason,
        'employeeMembershipId': ?employeeMembershipId,
        'shiftTemplateId': ?shiftTemplateId,
      },
    );
    return _record(response.data, workspaceId);
  });
  @override
  Future<ScheduleException> cancel(
    String workspaceId,
    String id,
    String reason,
  ) => _request(() async {
    final response = await _dio.post<Object?>(
      '${_path(workspaceId)}/$id/cancel',
      data: {'reason': reason},
    );
    return _record(response.data, workspaceId);
  });
  ScheduleException _record(Object? data, String workspaceId) {
    final record = ScheduleException.fromJson(ApiModelParser.map(data));
    if (record.workspaceId != workspaceId) {
      throw const FormatException('Cross-workspace exception');
    }
    return record;
  }

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }
}
