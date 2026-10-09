import 'fixed_shift_repository.dart';

class TemplateEligibility {
  const TemplateEligibility({
    this.status = 'UNKNOWN',
    this.authorizedOccurrences = const [],
    this.openAttendanceId,
    required this.workspaceId,
    required this.timezone,
    required this.evaluatedAt,
    required this.recommended,
    required this.eligibleTemplates,
  });
  final String status;
  final String? openAttendanceId;
  final List<EligibleShiftOccurrence> authorizedOccurrences;
  final String workspaceId;
  final String timezone;
  final DateTime evaluatedAt;
  final EligibleShiftOccurrence? recommended;
  final List<EligibleShiftOccurrence> eligibleTemplates;
}
