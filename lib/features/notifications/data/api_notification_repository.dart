import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/notifications/data/notification_api_parser.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._dio);
  final Dio _dio;

  @override
  Future<NotificationPage> list(String workspaceId, NotificationQuery query) =>
      _request(() async {
        final res = await _dio.get<Object?>(
          '/notifications',
          queryParameters: {
            'page': query.page,
            'limit': query.limit,
            if (query.unread != null) 'unread': query.unread,
            if (query.type?.apiValue != null) 'type': query.type!.apiValue,
            'workspaceId': workspaceId,
          },
        );
        return parseNotificationPage(res.data);
      });

  @override
  Future<int> unreadCount() => _request(() async {
    final res = await _dio.get<Object?>('/notifications/unread-count');
    return ApiModelParser.integer(ApiModelParser.map(res.data), 'count');
  });

  @override
  Future<NotificationRecord> markRead(String id) => _request(() async {
    final res = await _dio.patch<Object?>('/notifications/$id/read');
    return NotificationRecord.fromJson(
      ApiModelParser.map(res.data, 'notification'),
    );
  });

  @override
  Future<int> markAllRead(String workspaceId) => _request(() async {
    final res = await _dio.patch<Object?>(
      '/notifications/read-all',
      data: {'workspaceId': workspaceId},
    );
    return ApiModelParser.integer(ApiModelParser.map(res.data), 'updatedCount');
  });

  @override
  Future<bool> delete(String id) => _request(() async {
    final res = await _dio.delete<Object?>('/notifications/$id');
    return parseDeletedAck(res.data);
  });

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}
