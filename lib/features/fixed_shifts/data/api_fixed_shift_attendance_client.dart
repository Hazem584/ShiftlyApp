import 'package:dio/dio.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/data/api_fixed_shift_parsers.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization_page.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

Future<FlexibleAttendance?> fetchPendingAttendance(
  Dio dio,
  PendingClockIn value,
) => requestFixedShift(() async {
  var page = 1;
  while (true) {
    final response = await dio.get<Object?>(
      '/attendance/me',
      options: Options(extra: {'requireFresh': true}),
      queryParameters: {
        'workspaceId': value.workspaceId,
        'page': page,
        'limit': 100,
      },
    );
    final json = ApiModelParser.map(response.data);
    for (final item in ApiModelParser.list(json['data'], 'data')) {
      final record = ApiModelParser.map(item);
      if (record['clientAttendanceId'] == value.clientAttendanceId &&
          record['employeeMembershipId'] == value.membershipId) {
        return FlexibleAttendance.fromJson(record);
      }
    }
    final pagination = ApiPagination.fromJson(
      ApiModelParser.map(json['pagination']),
    );
    if (page >= pagination.totalPages) return null;
    page++;
  }
});

Future<ExtraAuthorizationPage> fetchExtraAuthorizations(
  Dio dio,
  String workspaceId,
  String membershipId, {
  int page = 1,
  int limit = 20,
}) => requestFixedShift(() async {
  final response = await dio.get<Object?>(
    '/workspaces/$workspaceId/employees/$membershipId/extra-shifts',
    queryParameters: {'page': page, 'limit': limit},
  );
  return parseExtraAuthorizationPage(response.data);
});

Future<ExtraAuthorization> postExtraAuthorization(
  Dio dio,
  String workspaceId,
  String membershipId,
  Map<String, Object?> payload, {
  required bool actual,
}) => requestFixedShift(() async {
  final response = await dio.post<Object?>(
    '/workspaces/$workspaceId/employees/$membershipId/extra-shifts${actual ? '/attendance' : ''}',
    data: payload,
  );
  return ExtraAuthorization(ApiModelParser.map(response.data));
});
