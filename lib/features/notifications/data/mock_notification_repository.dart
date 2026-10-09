import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository({this.delay = Duration.zero})
    : _records = [
        _record(
          id: 'a5e624e8-ee45-4417-a932-5b48ad019656',
          type: NotificationType.leaveRequestCreated,
          title: 'New leave request',
          message: 'Mariam Hassan submitted a leave request.',
          data: {
            'leaveRequestId': 'f65933d1-57ce-4f70-a28e-574bea205344',
            'employeeMembershipId': '040e52de-05b9-46b8-80ca-e7df3ef7444b',
          },
        ),
        _record(
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
          (record) =>
              record.workspaceId == workspaceId &&
              (query.unread == null || record.isUnread == query.unread) &&
              (query.type == null || record.type == query.type),
        )
        .toList(growable: false);
    return NotificationPage(
      data: filtered,
      pagination: ApiPagination(
        page: query.page,
        limit: query.limit,
        total: filtered.length,
        totalPages: filtered.isEmpty ? 0 : 1,
      ),
    );
  }

  @override
  Future<int> unreadCount() async {
    await _wait();
    return _records.where((record) => record.isUnread).length;
  }

  @override
  Future<NotificationRecord> markRead(String notificationId) async {
    await _wait();
    final index = _records.indexWhere((record) => record.id == notificationId);
    final updated = _copy(_records[index], readAt: DateTime.utc(2030, 1, 2));
    _records[index] = updated;
    return updated;
  }

  @override
  Future<int> markAllRead(String workspaceId) async {
    await _wait();
    var count = 0;
    for (var index = 0; index < _records.length; index++) {
      if (_records[index].workspaceId == workspaceId &&
          _records[index].isUnread) {
        _records[index] = _copy(
          _records[index],
          readAt: DateTime.utc(2030, 1, 2),
        );
        count += 1;
      }
    }
    return count;
  }

  @override
  Future<bool> delete(String notificationId) async {
    await _wait();
    final before = _records.length;
    _records.removeWhere((record) => record.id == notificationId);
    return _records.length == before - 1;
  }
}

NotificationRecord _record({
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

NotificationRecord _copy(
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
