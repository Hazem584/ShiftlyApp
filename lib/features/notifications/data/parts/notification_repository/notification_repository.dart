part of '../../notification_repository.dart';

abstract interface class NotificationRepository {
  Future<NotificationPage> list(String workspaceId, NotificationQuery query);
  Future<int> unreadCount();
  Future<NotificationRecord> markRead(String notificationId);
  Future<int> markAllRead(String workspaceId);
  Future<bool> delete(String notificationId);
}
