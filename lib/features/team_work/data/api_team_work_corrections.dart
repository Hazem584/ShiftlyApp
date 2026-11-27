import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

import 'api_team_work_payloads.dart';
import 'api_team_work_queries.dart';

mixin ApiTeamWorkCorrections implements TeamWorkRepository {
  Future<void> postWorkRequest(String path, [Map<String, Object?>? data]);

  @override
  Future<void> requestCorrection(
    String workspaceId, {
    required String attendanceId,
    required DateTime clockIn,
    required DateTime clockOut,
    required String reason,
  }) => postWorkRequest('${teamWorkBasePath(workspaceId)}/corrections', {
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
  }) => postWorkRequest(
    '${teamWorkBasePath(workspaceId)}/corrections/$id/review',
    {
      'decision': approve ? 'APPROVED' : 'REJECTED',
      'note': ?note,
      if (clockIn != null) 'clockInAt': clockIn.toUtc().toIso8601String(),
      if (clockOut != null) 'clockOutAt': clockOut.toUtc().toIso8601String(),
    },
  );
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
  }) => postWorkRequest(
    '${teamWorkBasePath(workspaceId)}/corrections/direct',
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
  }) => postWorkRequest(
    '${teamWorkBasePath(workspaceId)}/corrections/missed',
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
}
