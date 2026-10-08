import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/data/points_repository.dart';
import 'package:shiftly/core/network/api_model_parser.dart';

class MockPointsRepository implements PointsRepository {
  const MockPointsRepository();
  @override
  Future<List<Achievement>> loadAchievements(String workspaceId) async => [];
  @override
  Future<List<PerformanceDay>> loadCalendar(
    String workspaceId,
    int year,
    int month,
  ) async => [];
  @override
  Future<PointsHistoryPage> loadHistory(
    String workspaceId, {
    required int page,
    required int limit,
  }) async => PointsHistoryPage(
    data: const [],
    pagination: ApiPagination(
      page: page,
      limit: limit,
      total: 0,
      totalPages: 0,
    ),
  );
  @override
  Future<PointsWallet> loadWallet(String workspaceId) async => PointsWallet(
    workspaceId: workspaceId,
    workspaceName: 'Shift Lab Preview Workspace',
    timezone: 'Etc/UTC',
    green: const PointBalance(available: 8, earned: 8),
    black: const PointBalance(),
    red: const PointBalance(active: 1),
    orange: const PointBalance(),
    blue: const PointBalance(),
    currentStreak: 4,
    bestStreak: 4,
    nextRewardAt: 5,
    greenCostPerRed: 5,
    monthlyRedLimit: 2,
    remainingMonthlyCompensations: 2,
  );
  @override
  Future<void> redeem(RedemptionIntent intent) async {}
}
