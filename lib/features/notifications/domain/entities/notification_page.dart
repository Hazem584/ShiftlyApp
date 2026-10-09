import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/notifications/domain/entities/notification_record.dart';

class NotificationPage {
  const NotificationPage({required this.data, required this.pagination});
  final List<NotificationRecord> data;
  final ApiPagination pagination;
}
