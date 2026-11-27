import 'package:shiftly/core/serialization/api_model_parser.dart';

import 'team_announcement_models.dart';

export 'team_announcement_models.dart';

class CorrectionRequest {
  CorrectionRequest.fromJson(Map<String, Object?> json)
    : id = ApiModelParser.string(json, 'id'),
      attendanceId = ApiModelParser.optionalString(json['attendanceId']),
      name = workName(json['requester']),
      reviewer = json['reviewer'] == null ? null : workName(json['reviewer']),
      reason = ApiModelParser.string(json, 'reason'),
      status = ApiModelParser.string(json, 'status'),
      reviewNote = json['reviewNote'] as String?,
      originalIn = workDate(json['originalClockInAt']),
      originalOut = workDate(json['originalClockOutAt']),
      occurrenceSnapshot = json['occurrenceSnapshot'] == null
          ? null
          : workMap(json['occurrenceSnapshot']),
      reasonKind = json['reasonKind'] as String?,
      approvedIn = workDate(json['approvedClockInAt']),
      approvedOut = workDate(json['approvedClockOutAt']),
      requestedIn = workDate(json['requestedClockInAt'])!,
      requestedOut = workDate(json['requestedClockOutAt'])!,
      reviewedAt = workDate(json['reviewedAt']);
  final String id, name, reason, status;
  final String? attendanceId, reviewer, reviewNote, reasonKind;
  final DateTime requestedIn, requestedOut;
  final DateTime? originalIn, originalOut, reviewedAt, approvedIn, approvedOut;
  final Map<String, Object?>? occurrenceSnapshot;
  bool get isMissingAttendance => occurrenceSnapshot != null;
  String? get shiftName => occurrenceSnapshot == null
      ? null
      : workMap(occurrenceSnapshot!['schedule'])['name'] as String?;
  String? get operationalDate =>
      occurrenceSnapshot?['operationalDate'] as String?;
}

class AssignedTeamTask {
  AssignedTeamTask.fromJson(Map<String, Object?> json)
    : id = ApiModelParser.string(json, 'id'),
      assigneeMembershipId = ApiModelParser.string(
        json,
        'assigneeMembershipId',
      ),
      assigneeName = (json['assigneeName'] as String?) ?? 'Employee',
      assigneeJobTitle = json['assigneeJobTitle'] as String?,
      createdByName = (json['createdByName'] as String?) ?? 'Manager',
      title = ApiModelParser.string(json, 'title'),
      description = json['description'] as String?,
      priority = (json['priority'] as String?) ?? 'MEDIUM',
      status = (json['status'] as String?) ?? 'OPEN',
      dueAt = workDate(json['dueAt']),
      completedAt = workDate(json['completedAt']),
      createdAt = workDate(json['createdAt']) ?? DateTime.now().toUtc();

  final String id,
      assigneeMembershipId,
      assigneeName,
      createdByName,
      title,
      priority,
      status;
  final String? assigneeJobTitle, description;
  final DateTime? dueAt, completedAt;
  final DateTime createdAt;
}
