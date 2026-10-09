import 'fixed_shift_repository.dart';

class PendingClockIn {
  const PendingClockIn({
    this.occurrenceKind,
    this.assignmentId,
    this.extraAuthorizationId,
    this.operationalDate,
    required this.userId,
    required this.workspaceId,
    required this.membershipId,
    required this.templateId,
    required this.clientAttendanceId,
  });
  final String? occurrenceKind,
      assignmentId,
      extraAuthorizationId,
      operationalDate;
  bool get hasEvidence =>
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(clientAttendanceId) &&
      operationalDate != null &&
      ((occurrenceKind == 'BASELINE' &&
              assignmentId != null &&
              extraAuthorizationId == null) ||
          (occurrenceKind == 'EXTRA' &&
              extraAuthorizationId != null &&
              assignmentId == null));
  Map<String, Object?> get payload => {
    'workspaceId': workspaceId,
    'shiftTemplateId': templateId,
    'clientAttendanceId': clientAttendanceId,
    if (assignmentId != null) 'assignmentId': assignmentId,
    if (extraAuthorizationId != null)
      'extraAuthorizationId': extraAuthorizationId,
  };
  bool sameOccurrence(EligibleShiftOccurrence value) =>
      templateId == value.template.id &&
      occurrenceKind == value.occurrenceKind &&
      assignmentId == value.assignmentId &&
      extraAuthorizationId == value.extraAuthorizationId &&
      operationalDate == value.operationalDate;
  final String userId;
  final String workspaceId;
  final String membershipId;
  final String templateId;
  final String clientAttendanceId;

  bool matches({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) =>
      this.userId == userId &&
      this.workspaceId == workspaceId &&
      this.membershipId == membershipId &&
      this.templateId == templateId;
}
