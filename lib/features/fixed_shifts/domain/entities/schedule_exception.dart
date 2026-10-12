import 'package:shiftly/core/serialization/api_model_parser.dart';

class ScheduleException {
  const ScheduleException({
    required this.id,
    required this.workspaceId,
    required this.operationalDate,
    required this.kind,
    required this.reason,
    required this.status,
    required this.createdByMembershipId,
    required this.createdAt,
    this.employeeMembershipId,
    this.shiftName,
    this.originalShiftName,
    this.cancellationReason,
    this.cancelledByMembershipId,
    this.cancelledAt,
    this.creatorName,
    this.cancellerName,
  });
  final String id,
      workspaceId,
      operationalDate,
      kind,
      reason,
      status,
      createdByMembershipId;
  final String? employeeMembershipId,
      shiftName,
      originalShiftName,
      cancellationReason,
      cancelledByMembershipId;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? creatorName, cancellerName;
  bool get active => status == 'ACTIVE';
  factory ScheduleException.fromJson(Map<String, Object?> json) {
    final schedule = ApiModelParser.optionalMap(json['scheduleSnapshot']);
    final original = ApiModelParser.optionalMap(json['originalSchedule']);
    final originalSchedule = ApiModelParser.optionalMap(original?['schedule']);
    return ScheduleException(
      id: ApiModelParser.string(json, 'id'),
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      operationalDate: ApiModelParser.string(json, 'operationalDate'),
      kind: ApiModelParser.string(json, 'kind'),
      reason: ApiModelParser.string(json, 'reason'),
      status: ApiModelParser.string(json, 'status'),
      createdByMembershipId: ApiModelParser.string(
        json,
        'createdByMembershipId',
      ),
      createdAt: ApiModelParser.date(json, 'createdAt'),
      employeeMembershipId: ApiModelParser.optionalString(
        json['employeeMembershipId'],
      ),
      shiftName: ApiModelParser.optionalString(schedule?['name']),
      originalShiftName: ApiModelParser.optionalString(
        originalSchedule?['name'],
      ),
      cancellationReason: ApiModelParser.optionalString(
        json['cancellationReason'],
      ),
      cancelledByMembershipId: ApiModelParser.optionalString(
        json['cancelledByMembershipId'],
      ),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : ApiModelParser.date(json, 'cancelledAt'),
      creatorName: ApiModelParser.optionalString(json['creatorName']),
      cancellerName: ApiModelParser.optionalString(json['cancellerName']),
    );
  }
}

class ScheduleExceptionNotice {
  const ScheduleExceptionNotice({
    required this.operationalDate,
    required this.kind,
    required this.reason,
  });
  final String operationalDate, kind, reason;
  factory ScheduleExceptionNotice.fromJson(Map<String, Object?> json) =>
      ScheduleExceptionNotice(
        operationalDate: ApiModelParser.string(json, 'operationalDate'),
        kind: ApiModelParser.string(json, 'kind'),
        reason: ApiModelParser.string(json, 'reason'),
      );
}
