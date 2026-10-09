import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';
import 'package:shiftly/features/points/domain/repositories/redemption_intent_storage.dart';

class MemoryRedemptionIntentStorage implements RedemptionIntentStorage {
  final Map<String, RedemptionIntent> _values = {};

  String _key(FeatureSessionScope scope) =>
      '${scope.userId}:${scope.workspaceId}:${scope.membershipId}';

  @override
  Future<RedemptionIntent?> read(FeatureSessionScope scope) async =>
      _values[_key(scope)];

  @override
  Future<void> write(FeatureSessionScope scope, RedemptionIntent intent) async {
    _values[_key(scope)] = intent;
  }

  @override
  Future<void> clear(
    FeatureSessionScope scope,
    String clientRedemptionId,
  ) async {
    final key = _key(scope);
    if (_values[key]?.clientRedemptionId == clientRedemptionId) {
      _values.remove(key);
    }
  }
}
