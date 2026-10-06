part of '../../leave_request_repository.dart';

class CreateLeaveRequestInput {
  const CreateLeaveRequestInput({
    required this.type,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
  });

  final LeaveRequestType type;
  final DateTime startsAt;
  final DateTime endsAt;
  final String reason;

  Map<String, Object?> toJson(String workspaceId) => {
    'workspaceId': workspaceId,
    'type': type.apiValue,
    'startsAt': startsAt.toUtc().toIso8601String(),
    'endsAt': endsAt.toUtc().toIso8601String(),
    'reason': reason.trim(),
  };
}
