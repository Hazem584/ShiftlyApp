import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';

abstract interface class LegacyClockInRepository {
  Future<List<LegacyClockInReview>> inspectLegacyClockIns(
    FeatureSessionScope scope,
  );
}
