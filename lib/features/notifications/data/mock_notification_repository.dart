import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/notifications/data/mock_notification_seed.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({this.delay = Duration.zero})
    : _records = seedMockNotifications();

  final Duration delay;
  final List<NotificationRecord> _records;

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<NotificationPage> list(
    String workspaceId,
    NotificationQuery query,
  ) async {
    await _wait();
    final filtered = _records
        .where(
          (r) =>
              r.workspaceId == workspaceId &&
              (query.unread == null || r.isUnread == query.unread) &&
              (query.type == null || r.type == query.type),
        )
        .toList(growable: false);
    final pg = ApiPagination(
      page: query.page,
      limit: query.limit,
      total: filtered.length,
      totalPages: filtered.isEmpty ? 0 : 1,
    );
    return NotificationPage(data: filtered, pagination: pg);
  }

  @override
  Future<int> unreadCount() async {
    await _wait();
    return _records.where((r) => r.isUnread).length;
  }

  @override
  Future<NotificationRecord> markRead(String notificationId) async {
    await _wait();
    final idx = _records.indexWhere((r) => r.id == notificationId);
    return _records[idx] = copyMockNotificationRead(
      _records[idx],
      readAt: DateTime.utc(2030, 1, 2),
    );
  }

  @override
  Future<int> markAllRead(String workspaceId) async {
    await _wait();
    return markAllMockNotificationsRead(_records, workspaceId);
  }

  @override
  Future<bool> delete(String notificationId) async {
    await _wait();
    final before = _records.length;
    _records.removeWhere((r) => r.id == notificationId);
    return _records.length == before - 1;
  }
}
