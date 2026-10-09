import 'package:shiftly/core/session/feature_scope.dart';

import 'legacy_clock_in_review.dart';

abstract interface class LegacyClockInRepository {
  Future<List<LegacyClockInReview>> inspectLegacyClockIns(
    FeatureSessionScope scope,
  );
}
