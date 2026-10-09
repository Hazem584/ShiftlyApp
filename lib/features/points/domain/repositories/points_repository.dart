import 'package:shiftly/features/points/domain/entities/points_models.dart';

abstract interface class PointsRepository {
  Future<PointsWallet> loadWallet(String workspaceId);
  Future<List<PerformanceDay>> loadCalendar(
    String workspaceId,
    int year,
    int month,
  );
  Future<PointsHistoryPage> loadHistory(
    String workspaceId, {
    required int page,
    required int limit,
  });
  Future<List<Achievement>> loadAchievements(String workspaceId);
  Future<void> redeem(RedemptionIntent intent);
}
