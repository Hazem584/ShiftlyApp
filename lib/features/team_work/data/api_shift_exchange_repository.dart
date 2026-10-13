import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

class ApiShiftExchangeRepository implements ShiftExchangeRepository {
  ApiShiftExchangeRepository(this._dio);
  final Dio _dio;
  String _path(String w) => '/workspaces/$w/shift-exchanges';
  Future<T> _request<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<WorkPage<ShiftExchange>> list(String workspaceId, {int page = 1}) =>
      _request(() async {
        final j = ApiModelParser.map(
          (await _dio.get<Object?>(
            _path(workspaceId),
            queryParameters: {'page': page, 'limit': 20},
          )).data,
        );
        final rows = ApiModelParser.list(j['data'])
            .map((e) => ShiftExchange.fromJson(ApiModelParser.map(e)))
            .toList();
        if (rows.any((r) => r.workspaceId != workspaceId)) {
          throw const FormatException('Cross-workspace exchange');
        }
        return WorkPage(rows, ApiModelParser.integer(j, 'total'));
      });
  @override
  Future<WorkPage<ExchangeColleague>> colleagues(
    String workspaceId, {
    int page = 1,
  }) => _request(() async {
    final j = ApiModelParser.map(
      (await _dio.get<Object?>(
        '${_path(workspaceId)}/colleagues',
        queryParameters: {'page': page, 'limit': 100},
      )).data,
    );
    return WorkPage(
      ApiModelParser.list(j['data']).map((e) {
        final v = ApiModelParser.map(e);
        return ExchangeColleague(
          ApiModelParser.string(v, 'id'),
          ApiModelParser.string(v, 'name'),
        );
      }).toList(),
      ApiModelParser.integer(j, 'total'),
    );
  });
  @override
  Future<Map<String, Object?>> occurrence(
    String workspaceId,
    String membershipId,
    String date,
  ) => _request(() async {
    final j = ApiModelParser.map(
      (await _dio.get<Object?>(
        '${_path(workspaceId)}/occurrence',
        queryParameters: {
          'employeeMembershipId': membershipId,
          'operationalDate': date,
        },
      )).data,
    );
    if (j['employeeMembershipId'] != membershipId ||
        j['operationalDate'] != date) {
      throw const FormatException('Invalid exchange occurrence');
    }
    return j;
  });
  @override
  Future<void> create(
    String workspaceId, {
    required String clientId,
    required String targetMembershipId,
    required String kind,
    required String requesterDate,
    required String targetDate,
    required String reason,
    required Map<String, Object?> requesterSnapshot,
    required Map<String, Object?> targetSnapshot,
  }) => _request(() async {
    await _dio.post<Object?>(
      _path(workspaceId),
      data: {
        'clientRequestId': clientId,
        'targetMembershipId': targetMembershipId,
        'kind': kind,
        'requesterDate': requesterDate,
        'targetDate': targetDate,
        'reason': reason,
        'requesterSnapshot': requesterSnapshot,
        'targetSnapshot': targetSnapshot,
      },
    );
  });
  @override
  Future<void> decide(
    String workspaceId,
    String id,
    String decision, {
    String? note,
  }) => _request(() async {
    await _dio.post<Object?>(
      '${_path(workspaceId)}/$id/decision',
      data: {'decision': decision, 'note': ?note},
    );
  });
}
