import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

NotificationPage parseNotificationPage(Object? data) {
  final json = ApiModelParser.map(data);
  return NotificationPage(
    data: ApiModelParser.list(json['data'], 'data')
        .map(
          (item) => NotificationRecord.fromJson(
            ApiModelParser.map(item, 'notification'),
          ),
        )
        .toList(growable: false),
    pagination: ApiPagination.fromJson(
      ApiModelParser.map(json['pagination'], 'pagination'),
    ),
  );
}

bool parseDeletedAck(Object? data) {
  final json = ApiModelParser.map(data);
  if (json['deleted'] is! bool) {
    throw const FormatException('Invalid deleted acknowledgement');
  }
  return json['deleted']! as bool;
}
