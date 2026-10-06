part of '../../notification_repository.dart';

class NotificationQuery {
  const NotificationQuery({
    this.page = 1,
    this.limit = 20,
    this.unread,
    this.type,
  });

  final int page;
  final int limit;
  final bool? unread;
  final NotificationType? type;

  NotificationQuery copyWith({int? page}) => NotificationQuery(
    page: page ?? this.page,
    limit: limit,
    unread: unread,
    type: type,
  );
}
