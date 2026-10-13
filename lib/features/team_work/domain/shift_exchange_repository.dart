import 'package:shiftly/features/team_work/domain/shift_exchange.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

abstract interface class ShiftExchangeRepository {
  Future<WorkPage<ShiftExchange>> list(String workspaceId, {int page = 1});
  Future<WorkPage<ExchangeColleague>> colleagues(
    String workspaceId, {
    int page = 1,
  });
  Future<Map<String, Object?>> occurrence(
    String workspaceId,
    String membershipId,
    String date,
  );
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
  });
  Future<void> decide(
    String workspaceId,
    String id,
    String decision, {
    String? note,
  });
}
