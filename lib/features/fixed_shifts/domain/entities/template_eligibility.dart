import 'package:shiftly/features/fixed_shifts/domain/entities/fixed_shift_models.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';

class TemplateEligibility {
  const TemplateEligibility({
    this.status = 'UNKNOWN',
    this.dayExceptions = const [],
    this.authorizedOccurrences = const [],
    this.openAttendanceId,
    required this.workspaceId,
    required this.timezone,
    required this.evaluatedAt,
    required this.recommended,
    required this.eligibleTemplates,
  });
  final String status;
  final List<ScheduleExceptionNotice> dayExceptions;
  final String? openAttendanceId;
  final List<EligibleShiftOccurrence> authorizedOccurrences;
  final String workspaceId;
  final String timezone;
  final DateTime evaluatedAt;
  final EligibleShiftOccurrence? recommended;
  final List<EligibleShiftOccurrence> eligibleTemplates;
}
