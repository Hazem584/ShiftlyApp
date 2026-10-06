part of '../../fixed_shift_repository.dart';

class PendingClockIn {
  const PendingClockIn({
    required this.userId,
    required this.workspaceId,
    required this.membershipId,
    required this.templateId,
    required this.clientAttendanceId,
  });
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
