import '../../data/legacy_clock_in_review.dart';

import 'package:equatable/equatable.dart';
import 'package:shiftly/core/error/failure.dart';

import '../../data/fixed_shift_repository.dart';

class FlexibleAttendanceState extends Equatable {
  const FlexibleAttendanceState({
    this.legacyReviews = const [],
    this.recovery,
    this.recoveryBlocked = false,
    this.loading = true,
    this.refreshing = false,
    this.eligibility,
    this.current,
    this.templates = const [],
    this.submittingTemplateId,
    this.clockingOut = false,
    this.failure,
  });
  final List<LegacyClockInReview> legacyReviews;
  bool get legacyReviewRequired => legacyReviews.any((v) => v.requiresReview);
  final PendingClockIn? recovery;
  final bool recoveryBlocked;
  final bool loading;
  final bool refreshing;
  final TemplateEligibility? eligibility;
  final FlexibleAttendance? current;
  final List<ShiftTemplate> templates;
  final String? submittingTemplateId;
  final bool clockingOut;
  final Failure? failure;

  FlexibleAttendanceState copyWith({
    List<LegacyClockInReview>? legacyReviews,
    PendingClockIn? recovery,
    bool clearRecovery = false,
    bool? recoveryBlocked,
    bool? loading,
    bool? refreshing,
    TemplateEligibility? eligibility,
    FlexibleAttendance? current,
    List<ShiftTemplate>? templates,
    bool clearCurrent = false,
    String? submittingTemplateId,
    bool clearSubmitting = false,
    bool? clockingOut,
    Failure? failure,
    bool clearFailure = false,
  }) => FlexibleAttendanceState(
    legacyReviews: legacyReviews ?? this.legacyReviews,
    recovery: clearRecovery ? null : recovery ?? this.recovery,
    recoveryBlocked: recoveryBlocked ?? this.recoveryBlocked,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    eligibility: eligibility ?? this.eligibility,
    current: clearCurrent ? null : current ?? this.current,
    templates: templates ?? this.templates,
    submittingTemplateId: clearSubmitting
        ? null
        : submittingTemplateId ?? this.submittingTemplateId,
    clockingOut: clockingOut ?? this.clockingOut,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    legacyReviews,
    recovery,
    recoveryBlocked,
    loading,
    refreshing,
    eligibility?.evaluatedAt,
    eligibility?.eligibleTemplates,
    eligibility?.authorizedOccurrences,
    eligibility?.status,
    eligibility?.openAttendanceId,
    current,
    templates,
    submittingTemplateId,
    clockingOut,
    failure?.message,
    failure?.requestId,
  ];
}
