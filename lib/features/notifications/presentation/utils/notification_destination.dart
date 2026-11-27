import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/utils/notification_employee_destination.dart';

enum NotificationDestinationKind {
  support,
  teamWork,
  chatGroup,
  managerAttendance,
  managerLeave,
  employeeShift,
  employeeLeave,
}

class NotificationDestination {
  const NotificationDestination({
    required this.id,
    required this.location,
    required this.kind,
  });
  final String id;
  final String location;
  final NotificationDestinationKind kind;
}

NotificationDestination? resolveNotificationDestination(
  FeatureSessionScope scope,
  NotificationRecord notification,
) {
  final data = notification.data;
  if (data == null || notification.type == NotificationType.unknown) {
    return null;
  }
  return switch (notification.type) {
    NotificationType.teamAnnouncement => NotificationDestination(
      id: readNotificationId(data, 'announcementId'),
      location: '/team-work?tab=announcements',
      kind: NotificationDestinationKind.teamWork,
    ),
    NotificationType.attendanceCorrectionCreated ||
    NotificationType.attendanceCorrectionReviewed => NotificationDestination(
      id: readNotificationId(data, 'correctionId'),
      location: '/team-work?tab=corrections',
      kind: NotificationDestinationKind.teamWork,
    ),
    NotificationType.attendanceClockedIn ||
    NotificationType.attendanceClockedOut when scope.isManager =>
      NotificationDestination(
        id: readNotificationId(data, 'attendanceId'),
        location: '/attendance',
        kind: NotificationDestinationKind.managerAttendance,
      ),
    NotificationType.leaveRequestCreated when scope.isManager =>
      NotificationDestination(
        id: readNotificationId(data, 'leaveRequestId'),
        location: '/attendance?tab=leaveRequests',
        kind: NotificationDestinationKind.managerLeave,
      ),
    NotificationType.supportReply => NotificationDestination(
      id: readNotificationId(data, 'supportTicketId'),
      location: '/support/${readNotificationId(data, 'supportTicketId')}',
      kind: NotificationDestinationKind.support,
    ),
    NotificationType.chatMessage => NotificationDestination(
      id: readNotificationId(data, 'groupId'),
      location: scope.isManager
          ? '/chat/${readNotificationId(data, 'groupId')}'
          : '/employee/chat/${readNotificationId(data, 'groupId')}',
      kind: NotificationDestinationKind.chatGroup,
    ),
    _ => resolveEmployeeDestination(scope, notification.type, data),
  };
}
