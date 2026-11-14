import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

class CommunicationNotifications implements NotificationRepository {
  final records = List.generate(
    3,
    (index) => NotificationRecord(
      id: 'notice-$index',
      workspaceId: 'workspace',
      type: NotificationType.unknown,
      title: [
        'Opening checklist updated',
        'Attendance approved',
        'Team announcement',
      ][index],
      message: [
        'Please review the checklist before your next shift.',
        'Your attendance correction has been approved.',
        'A new update from your workspace manager.',
      ][index],
      readAt: index == 1 ? DateTime.utc(2026, 11, 14, 8) : null,
      createdAt: DateTime.utc(2026, 11, 14, 7, index),
      updatedAt: DateTime.utc(2026, 11, 14, 7, index),
    ),
  );
  @override
  Future<NotificationPage> list(
    String workspaceId,
    NotificationQuery query,
  ) async => NotificationPage(
    data: records,
    pagination: ApiPagination(
      page: 1,
      limit: 20,
      total: records.length,
      totalPages: 1,
    ),
  );
  @override
  Future<int> unreadCount() async => records.where((n) => n.isUnread).length;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CommunicationDevices implements DeviceSessionsRepository {
  @override
  Future<DeviceSessionsPage> load({int page = 1}) async => DeviceSessionsPage([
    for (final name in ['Samsung Galaxy A54', 'Chrome on Windows'])
      DeviceSession(
        id: name,
        deviceName: name,
        platform: name.startsWith('Samsung') ? 'android' : 'web',
        osVersion: name.startsWith('Samsung') ? 'Android 14' : 'Windows 11',
        appVersion: '1.0.2',
        createdAt: DateTime.utc(2026, 11, 10, 8),
        lastSeenAt: DateTime.utc(2026, 11, 14, 8),
        isCurrent: name.startsWith('Samsung'),
        isFirst: name.startsWith('Samsung'),
      ),
  ], hasNext: false);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
