import 'package:dio/dio.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

import 'api_team_work_payloads.dart';
import 'api_team_work_queries.dart';

class ApiTeamWorkRepository implements TeamWorkRepository {
  ApiTeamWorkRepository(this._dio);
  final Dio _dio;
  String _base(String id) => teamWorkBasePath(id);
  Future<void> _post(String path, [Map<String, Object?>? data]) =>
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
  Future<void> requestCorrection(
    String workspaceId, {
    required String attendanceId,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  }) => _post('${_base(workspaceId)}/corrections', {
    'attendanceId': attendanceId,
    'clockInAt': clockIn.toUtc().toIso8601String(),
    'clockOutAt': clockOut.toUtc().toIso8601String(),
    'reason': reason.trim(),
  });
  @override
  Future<void> reviewCorrection(
    String workspaceId,
    String id, {
    required bool approve,
    String? note,
    DateTime? clockIn,
    DateTime? clockOut,
  }) => _post('${_base(workspaceId)}/corrections/$id/review', {
    'decision': approve ? 'APPROVED' : 'REJECTED',
    'note': ?note,
    if (clockIn != null) 'clockInAt': clockIn.toUtc().toIso8601String(),
    if (clockOut != null) 'clockOutAt': clockOut.toUtc().toIso8601String(),
  });
  @override
  Future<void> recordAttendanceDay(
    String workspaceId, {
    required String employeeMembershipId,
    String? attendanceId,
    String? assignmentId,
    String? extraAuthorizationId,
    String? shiftId,
    required String operationalDate,
    required String reasonKind,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  }) => _post(
    '${_base(workspaceId)}/corrections/direct',
    buildRecordAttendanceDayPayload(
      employeeMembershipId: employeeMembershipId,
      attendanceId: attendanceId,
      assignmentId: assignmentId,
      extraAuthorizationId: extraAuthorizationId,
      shiftId: shiftId,
      operationalDate: operationalDate,
      reasonKind: reasonKind,
      clockIn: clockIn,
      clockOut: clockOut,
      reason: reason,
    ),
  );
  @override
  Future<void> requestMissedAttendance(
    String workspaceId, {
    String? assignmentId,
    String? extraAuthorizationId,
    String? shiftId,
    required String operationalDate,
    required String reasonKind,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  }) => _post(
    '${_base(workspaceId)}/corrections/missed',
    buildMissedAttendancePayload(
      assignmentId: assignmentId,
      extraAuthorizationId: extraAuthorizationId,
      shiftId: shiftId,
      operationalDate: operationalDate,
      reasonKind: reasonKind,
      clockIn: clockIn,
      clockOut: clockOut,
      reason: reason,
    ),
  );
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
  }) => _post('${_base(workspaceId)}/announcements', {
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
  }) => _post(
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
}
