import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/utils/notification_destination.dart';

String readNotificationId(Map<String, Object?> data, String key) =>
    data[key] is String ? data[key]! as String : '';

NotificationDestination? resolveEmployeeDestination(
  FeatureSessionScope scope,
  NotificationType type,
  Map<String, Object?> data,
) => switch (type) {
  NotificationType.fixedShiftReminder when scope.isEmployee =>
    NotificationDestination(
      id: readNotificationId(data, 'assignmentId'),
      location: '/employee?tab=shifts',
      kind: NotificationDestinationKind.teamWork,
    ),
  NotificationType.clockOutReminder when scope.isEmployee =>
    NotificationDestination(
      id: readNotificationId(data, 'attendanceId'),
      location: '/employee?tab=shifts',
      kind: NotificationDestinationKind.teamWork,
    ),
  NotificationType.shiftAssigned ||
  NotificationType.shiftUpdated ||
  NotificationType.shiftCancelled ||
  NotificationType.shiftReminder
      when scope.isEmployee &&
          readNotificationId(data, 'employeeMembershipId') ==
              scope.membershipId =>
    NotificationDestination(
      id: readNotificationId(data, 'shiftId'),
      location: '/employee?tab=shifts',
      kind: NotificationDestinationKind.employeeShift,
    ),
  NotificationType.leaveRequestApproved ||
  NotificationType.leaveRequestRejected when scope.isEmployee =>
    NotificationDestination(
      id: readNotificationId(data, 'leaveRequestId'),
      location: '/employee?tab=leave',
      kind: NotificationDestinationKind.employeeLeave,
    ),
  _ => null,
};
