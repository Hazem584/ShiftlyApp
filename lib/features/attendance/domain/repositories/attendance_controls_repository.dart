abstract interface class AttendanceControlsRepository {
  Future<void> decideMonth({
    required String workspaceId,
    required int year,
    required int month,
    required int revision,
    required bool close,
    required String reason,
  });
  Future<void> decideDay({
    required String workspaceId,
    required String employeeMembershipId,
    required String date,
    required String status,
    required String reason,
    required int revision,
  });
}
