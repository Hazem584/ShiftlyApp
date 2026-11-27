import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

List<NotificationRecord> seedMockNotifications() => [
  createMockNotification(
    id: 'a5e624e8-ee45-4417-a932-5b48ad019656',
    type: NotificationType.leaveRequestCreated,
    title: 'New leave request',
    message: 'Mariam Hassan submitted a leave request.',
    data: {
      'leaveRequestId': 'f65933d1-57ce-4f70-a28e-574bea205344',
      'employeeMembershipId': '040e52de-05b9-46b8-80ca-e7df3ef7444b',
    },
  ),
  createMockNotification(
    id: 'b5e624e8-ee45-4417-a932-5b48ad019657',
    type: NotificationType.attendanceClockedIn,
    title: 'Employee clocked in',
    message: 'Omar Khaled has clocked in.',
    data: {
      'attendanceId': 'd65933d1-57ce-4f70-a28e-574bea205344',
      'employeeMembershipId': '140e52de-05b9-46b8-80ca-e7df3ef7444b',
    },
    readAt: DateTime.utc(2030, 1, 1, 8),
  ),
];

NotificationRecord createMockNotification({
  required String id,
  required NotificationType type,
  required String title,
  required String message,
  required Map<String, Object?> data,
  DateTime? readAt,
}) => NotificationRecord(
  id: id,
  workspaceId: 'preview-workspace',
  type: type,
  title: title,
  message: message,
  data: data,
  readAt: readAt,
  createdAt: DateTime.utc(2030, 1, 1, 7),
  updatedAt: DateTime.utc(2030, 1, 1, 7),
);

NotificationRecord copyMockNotificationRead(
  NotificationRecord record, {
  required DateTime readAt,
}) => NotificationRecord(
  id: record.id,
  workspaceId: record.workspaceId,
  type: record.type,
  title: record.title,
  message: record.message,
  data: record.data,
  readAt: readAt,
  createdAt: record.createdAt,
  updatedAt: readAt,
);

int markAllMockNotificationsRead(
  List<NotificationRecord> records,
  String workspaceId,
) {
  var count = 0;
  for (var i = 0; i < records.length; i++) {
    if (records[i].workspaceId == workspaceId && records[i].isUnread) {
      records[i] = copyMockNotificationRead(
        records[i],
        readAt: DateTime.utc(2030, 1, 2),
      );
      count += 1;
    }
  }
  return count;
}
