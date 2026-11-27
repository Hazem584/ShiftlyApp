import 'package:shiftly/features/team_work/domain/team_work_models.dart';

WorkPage<WorkTask> parseWorkTasksPage(Object? raw) {
  final json = workMap(raw);
  final items = (json['data'] as List)
      .map((e) => WorkTask.fromJson(workMap(e)))
      .toList();
  return WorkPage(
    items,
    items.length,
    notice: json['scheduleUnavailable'] == true
        ? 'Some shift schedules need review. Open shifts to check assignments.'
        : json['truncated'] == true
        ? 'More items need attention. Open attendance or requests to see the complete list.'
        : null,
  );
}

List<AnnouncementReader> parseAnnouncementReaders(Object? raw) {
  final json = workMap(raw);
  return (json['data'] as List)
      .map((e) => AnnouncementReader.fromJson(workMap(e)))
      .toList();
}

Map<String, Object?> buildRecordAttendanceDayPayload({
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
}) => {
  'employeeMembershipId': employeeMembershipId,
  'attendanceId': ?attendanceId,
  'assignmentId': ?assignmentId,
  'extraAuthorizationId': ?extraAuthorizationId,
  'shiftId': ?shiftId,
  'operationalDate': operationalDate,
  'reasonKind': reasonKind,
  'clockInAt': clockIn.toUtc().toIso8601String(),
  'clockOutAt': clockOut.toUtc().toIso8601String(),
  'reason': reason.trim(),
};

Map<String, Object?> buildMissedAttendancePayload({
  String? assignmentId,
  String? extraAuthorizationId,
  String? shiftId,
  required String operationalDate,
  required String reasonKind,
  required DateTime clockIn,
  required DateTime clockOut,
  required String reason,
}) => {
  'shiftId': ?shiftId,
  'assignmentId': ?assignmentId,
  'extraAuthorizationId': ?extraAuthorizationId,
  'operationalDate': operationalDate,
  'reasonKind': reasonKind,
  'clockInAt': clockIn.toUtc().toIso8601String(),
  'clockOutAt': clockOut.toUtc().toIso8601String(),
  'reason': reason.trim(),
};
