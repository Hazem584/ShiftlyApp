import 'package:shiftly/features/team_work/domain/team_work_models.dart';

abstract interface class TeamWorkRepository {
  Future<WorkPage<WorkTask>> tasks(String workspaceId);
  Future<WorkPage<CorrectionRequest>> corrections(
    String workspaceId, {
    int page = 1,
    String? status,
  });
  Future<CorrectionRequest> correction(String workspaceId, String id);
  Future<void> requestCorrection(
    String workspaceId, {
    required String attendanceId,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  });
  Future<void> reviewCorrection(
    String workspaceId,
    String id, {
    required bool approve,
    String? note,
  });
  Future<WorkPage<TeamAnnouncement>> announcements(
    String workspaceId, {
    int page = 1,
  });
  Future<void> publish(
    String workspaceId, {
    required String clientId,
    required String title,
    required String body,
    required bool acknowledgment,
  });
  Future<void> markAnnouncement(
    String workspaceId,
    String id, {
    bool acknowledge = false,
  });
  Future<List<AnnouncementReader>> readers(String workspaceId, String id);
}
