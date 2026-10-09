import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/points/domain/entities/points_models.dart';

abstract interface class RedemptionIntentStorage {
  Future<RedemptionIntent?> read(FeatureSessionScope scope);
  Future<void> write(FeatureSessionScope scope, RedemptionIntent intent);
  Future<void> clear(FeatureSessionScope scope, String clientRedemptionId);
}
