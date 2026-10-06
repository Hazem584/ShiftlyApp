part of '../../fixed_shifts_cubit.dart';

class FlexibleAttendanceState extends Equatable {
  const FlexibleAttendanceState({
    this.loading = true,
    this.refreshing = false,
    this.eligibility,
    this.current,
    this.templates = const [],
    this.submittingTemplateId,
    this.clockingOut = false,
    this.failure,
  });
  final bool loading;
  final bool refreshing;
  final TemplateEligibility? eligibility;
  final FlexibleAttendance? current;
  final List<ShiftTemplate> templates;
  final String? submittingTemplateId;
  final bool clockingOut;
  final Failure? failure;

  FlexibleAttendanceState copyWith({
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
    loading,
    refreshing,
    eligibility?.evaluatedAt,
    eligibility?.eligibleTemplates,
    current,
    templates,
    submittingTemplateId,
    clockingOut,
    failure?.message,
    failure?.requestId,
  ];
}
