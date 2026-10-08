import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/data/points_repository.dart';

class ApiPointsRepository implements PointsRepository {
  ApiPointsRepository(this._dio);
  final Dio _dio;

  @override
  Future<PointsWallet> loadWallet(String workspaceId) => _request(() async {
    final response = await _dio.get<Object?>(
      '/points/me',
      queryParameters: {'workspaceId': workspaceId},
    );
    return PointsWallet.fromJson(ApiModelParser.map(response.data, 'wallet'));
  });

  @override
  Future<List<PerformanceDay>> loadCalendar(
    String workspaceId,
    int year,
    int month,
  ) => _request(() async {
    final response = await _dio.get<Object?>(
      '/points/me/calendar',
      queryParameters: {
        'workspaceId': workspaceId,
        'year': year,
        'month': month,
      },
    );
    return ApiModelParser.list(response.data, 'calendar')
        .map(
          (item) =>
              PerformanceDay.fromJson(ApiModelParser.map(item, 'calendarDay')),
        )
        .toList(growable: false);
  });

  @override
  Future<PointsHistoryPage> loadHistory(
    String workspaceId, {
    required int page,
    required int limit,
  }) => _request(() async {
    final response = await _dio.get<Object?>(
      '/points/me/history',
      queryParameters: {
        'workspaceId': workspaceId,
        'page': page,
        'limit': limit.clamp(1, 100),
      },
    );
    return PointsHistoryPage.fromJson(
      ApiModelParser.map(response.data, 'historyPage'),
    );
  });

  @override
  Future<List<Achievement>> loadAchievements(String workspaceId) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          '/points/me/achievements',
          queryParameters: {'workspaceId': workspaceId},
        );
        return ApiModelParser.list(response.data, 'achievements')
            .map(
              (item) =>
                  Achievement.fromJson(ApiModelParser.map(item, 'achievement')),
            )
            .toList(growable: false);
      });

  @override
  Future<void> redeem(RedemptionIntent intent) => _request(() async {
    await _dio.post<Object?>('/points/me/redemptions', data: intent.toJson());
  });

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}
