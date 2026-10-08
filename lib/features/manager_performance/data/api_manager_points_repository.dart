import 'package:dio/dio.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/points/data/points_models.dart';

import 'manager_points_page.dart';
import 'manager_points_record.dart';
import 'manager_points_repository.dart';

class ApiManagerPointsRepository implements ManagerPointsRepository {
  ApiManagerPointsRepository(this._dio);
  final Dio _dio;
  CancelToken? _scopeCancellation;
  @override
  void bindSession(FeatureSessionScope? scope) {
    _scopeCancellation?.cancel('Manager session scope changed');
    _scopeCancellation = CancelToken();
    if (scope == null) {
      _scopeCancellation!.cancel('Manager access unavailable');
    }
  }

  void _policy(Map<String, Object?> json) {
    OperationalDate.parse(ApiModelParser.string(json, 'effectiveFrom'));
    for (final key in const ['streakRewardEnabled', 'isEnabled']) {
      if (json[key] is! bool) {
        throw const FormatException('Invalid policy setting');
      }
    }
    for (final key in const [
      'greenPointsForCompletedAttendance',
      'blackPointsForLateAttendance',
      'redPointsForAbsence',
      'orangePointsForIncompleteAttendance',
      'bluePointsForExtraEffort',
      'blueGreenEquivalent',
      'greenCostPerRedCompensation',
      'monthlyRedCompensationLimit',
      'blackPointsWarningThreshold',
      'disputeWindowHours',
      'earlyDepartureToleranceMinutes',
      'incompleteAttendanceResolutionMinutes',
      'streakRequiredDays',
      'streakGreenReward',
    ]) {
      ApiModelParser.integer(json, key);
    }
  }

  String _path(String workspace, String resource, String? target) =>
      '/workspaces/$workspace/${target == null ? '' : 'employees/$target/'}points${resource.isEmpty ? '' : '/$resource'}';

  Future<T> _request<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  @override
  Future<Map<String, Object?>> get(
    String workspace,
    String resource, {
    String? target,
  }) => _request(() async {
    final map = ApiModelParser.map(
      (await _dio.get<Object?>(
        _path(workspace, resource, target),
        cancelToken: _scopeCancellation,
      )).data,
      resource,
    );
    if (resource.isEmpty) {
      for (final group in const {
        'green': ['earned', 'bonuses', 'adjusted', 'redeemed', 'available'],
        'black': ['total', 'currentMonth'],
        'red': ['compensated', 'active'],
        'orange': ['total', 'currentMonth'],
        'blue': ['total', 'currentMonth'],
      }.entries) {
        final balance = ApiModelParser.map(map[group.key], group.key);
        for (final field in group.value) {
          if (balance[field] is! int) {
            throw const FormatException('Invalid canonical balance');
          }
        }
      }
      final wallet = PointsWallet.fromJson(map);
      if (wallet.workspaceId != workspace) {
        throw const FormatException('Wallet scope mismatch');
      }
    } else {
      ApiModelParser.string(map, 'id');
      if (map['workspaceId'] != workspace) {
        throw const FormatException('Record scope mismatch');
      }
      if (target != null && map['employeeMembershipId'] != target) {
        throw const FormatException('Employee scope mismatch');
      }
      if (resource == 'policies/current') {
        _policy(map);
      }
    }
    return map;
  });

  @override
  Future<ManagerPointsPage> list(
    String workspace,
    String resource, {
    String? target,
    Map<String, Object?> query = const {},
  }) => _request(() async {
    final body = (await _dio.get<Object?>(
      _path(workspace, resource, target),
      queryParameters: query,
      cancelToken: _scopeCancellation,
    )).data;
    final paginated =
        resource == 'summary' ||
        resource == 'history' ||
        resource == 'disputes';
    final map = paginated ? ApiModelParser.map(body, resource) : null;
    final records =
        ApiModelParser.list(paginated ? map!['data'] : body, resource)
            .map(
              (value) =>
                  ManagerPointsRecord(ApiModelParser.map(value, resource)),
            )
            .toList(growable: false);
    for (final record in records) {
      if (resource == 'policies') {
        _policy(record.fields);
      }
      if (resource == 'calendar') {
        PerformanceDay.fromJson(record.fields);
      }
      if (resource == 'achievements') {
        Achievement.fromJson(record.fields);
      }
      if (resource == 'history') {
        PointLedgerEntry.fromJson(record.fields);
      }
      if (record.fields['workspaceId'] != null &&
          record.fields['workspaceId'] != workspace) {
        throw const FormatException('Record scope mismatch');
      }
      if (target != null &&
          record.fields['employeeMembershipId'] != null &&
          record.fields['employeeMembershipId'] != target) {
        throw const FormatException('Employee scope mismatch');
      }
    }
    return ManagerPointsPage(
      records,
      pagination: paginated
          ? ApiPagination.fromJson(
              ApiModelParser.map(map!['pagination'], 'pagination'),
            )
          : null,
    );
  });

  @override
  Future<ManagerPointsRecord> mutate(
    String workspace,
    String resource,
    Map<String, Object?> payload, {
    String? target,
    bool patch = false,
  }) => _request(() async {
    final response = patch
        ? await _dio.patch<Object?>(
            _path(workspace, resource, target),
            data: payload,
            cancelToken: _scopeCancellation,
          )
        : await _dio.post<Object?>(
            _path(workspace, resource, target),
            data: payload,
            cancelToken: _scopeCancellation,
          );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw const FormatException('Unconfirmed response status');
    }
    final result = ManagerPointsRecord(
      ApiModelParser.map(response.data, resource),
    );
    if (result.fields['workspaceId'] != workspace ||
        (target != null && result.fields['employeeMembershipId'] != target)) {
      throw const FormatException('Mutation scope could not be confirmed');
    }
    final reverse = resource.endsWith('/reverse');
    if (reverse && result.id != resource.split('/')[1]) {
      throw const FormatException('Reversal target mismatch');
    }
    if (patch && result.id != resource.split('/')[1]) {
      throw const FormatException('Dispute target mismatch');
    }
    for (final entry in payload.entries) {
      final key = reverse && entry.key == 'reason'
          ? 'reversalReason'
          : reverse && entry.key == 'explanation'
          ? 'reversalExplanation'
          : entry.key == 'decision'
          ? 'status'
          : entry.key == 'response'
          ? 'managerResponse'
          : entry.key;
      if (result.fields[key] != entry.value) {
        throw const FormatException('Mutation response could not be confirmed');
      }
    }
    if (reverse && !result.reversed) {
      throw const FormatException('Reversal is unconfirmed');
    }
    return result;
  });
}
