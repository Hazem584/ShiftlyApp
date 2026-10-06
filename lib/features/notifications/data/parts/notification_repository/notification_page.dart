part of '../../notification_repository.dart';

class NotificationPage {
  const NotificationPage({required this.data, required this.pagination});
  final List<NotificationRecord> data;
  final ApiPagination pagination;
}
