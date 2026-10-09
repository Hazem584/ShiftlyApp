import 'package:shiftly/features/notifications/domain/entities/notification_models.dart';

export 'package:shiftly/features/notifications/domain/entities/notification_models.dart';

abstract interface class NotificationRepository {
  Future<NotificationPage> list(String workspaceId, NotificationQuery query);
  Future<int> unreadCount();
  Future<NotificationRecord> markRead(String notificationId);
  Future<int> markAllRead(String workspaceId);
  Future<bool> delete(String notificationId);
}
