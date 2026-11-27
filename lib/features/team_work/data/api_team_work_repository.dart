import 'package:dio/dio.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

import 'api_team_work_corrections.dart';
import 'api_team_work_payloads.dart';
import 'api_team_work_queries.dart';

class ApiTeamWorkRepository
    with ApiTeamWorkCorrections
    implements TeamWorkRepository {
  ApiTeamWorkRepository(this._dio);
  final Dio _dio;
  String _base(String id) => teamWorkBasePath(id);
  @override
  Future<void> postWorkRequest(String path, [Map<String, Object?>? data]) =>
      runTeamWorkRequest(() => _dio.post<Object?>(path, data: data));

  @override
  Future<WorkPage<WorkTask>> tasks(String workspaceId) =>
      fetchWorkTasks(_dio, workspaceId);
  @override
  Future<CorrectionRequest> correction(String workspaceId, String id) =>
      fetchCorrectionById(_dio, workspaceId, id);
  @override
  Future<WorkPage<CorrectionRequest>> corrections(
    String workspaceId, {
    int page = 1,
    String? status,
  }) => fetchCorrectionsPage(_dio, workspaceId, page: page, status: status);
  @override
  Future<WorkPage<TeamAnnouncement>> announcements(
    String workspaceId, {
    int page = 1,
    bool pendingOnly = false,
  }) => fetchAnnouncementsPage(
    _dio,
    workspaceId,
    page: page,
    pendingOnly: pendingOnly,
  );
  @override
  Future<void> publish(
    String workspaceId, {
    required String clientId,
    required String title,
    required String body,
    required bool acknowledgment,
  }) => postWorkRequest('${_base(workspaceId)}/announcements', {
    'clientId': clientId,
    'title': title.trim(),
    'body': body.trim(),
    'requiresAcknowledgment': acknowledgment,
  });
  @override
  Future<void> markAnnouncement(
    String workspaceId,
    String id, {
    bool acknowledge = false,
  }) => postWorkRequest(
    '${_base(workspaceId)}/announcements/$id/${acknowledge ? 'acknowledge' : 'read'}',
  );
  @override
  Future<List<AnnouncementReader>> readers(String workspaceId, String id) =>
      runTeamWorkRequest(
        () async => parseAnnouncementReaders(
          (await _dio.get<Object?>(
            '${_base(workspaceId)}/announcements/$id/receipts',
          )).data,
        ),
      );
  @override
  Future<List<AssignedTeamTask>> assignedTasks(
    String workspaceId, {
    String? status,
  }) => fetchAssignedTasks(_dio, workspaceId, status: status);
  @override
  Future<void> createAssignedTask(
    String workspaceId, {
    required List<String> assigneeMembershipIds,
    required String title,
    String? description,
    String priority = 'MEDIUM',
    DateTime? dueAt,
  }) => postWorkRequest('${_base(workspaceId)}/assigned-tasks', {
    'assigneeMembershipIds': assigneeMembershipIds,
    'title': title.trim(),
    if (description != null && description.trim().isNotEmpty)
      'description': description.trim(),
    'priority': priority,
    if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
  });
  @override
  Future<void> updateAssignedTaskStatus(
    String workspaceId,
    String taskId,
    String status,
  ) => runTeamWorkRequest(
    () => _dio.patch<Object?>(
      '${_base(workspaceId)}/assigned-tasks/$taskId',
      data: {'status': status},
    ),
  );
  @override
  Future<void> deleteAssignedTask(String workspaceId, String taskId) =>
      runTeamWorkRequest(
        () => _dio.delete<Object?>(
          '${_base(workspaceId)}/assigned-tasks/$taskId',
        ),
      );
}
