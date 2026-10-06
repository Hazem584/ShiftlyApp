part of '../../fixed_shift_repository.dart';

class TemplateEligibility {
  const TemplateEligibility({
    required this.workspaceId,
    required this.timezone,
    required this.evaluatedAt,
    required this.recommended,
    required this.eligibleTemplates,
  });
  final String workspaceId;
  final String timezone;
  final DateTime evaluatedAt;
  final EligibleShiftOccurrence? recommended;
  final List<EligibleShiftOccurrence> eligibleTemplates;
}
