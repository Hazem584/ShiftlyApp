import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/network/api_model_parser.dart';
import 'package:shiftly/features/notifications/data/notification_repository.dart';

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._dio);
  final Dio _dio;

  @override
  Future<NotificationPage> list(String workspaceId, NotificationQuery query) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          '/notifications',
          queryParameters: {
            'page': query.page,
            'limit': query.limit,
            if (query.unread != null) 'unread': query.unread,
            if (query.type?.apiValue != null) 'type': query.type!.apiValue,
            'workspaceId': workspaceId,
          },
        );
        final json = ApiModelParser.map(response.data);
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
      });

  @override
  Future<int> unreadCount() => _request(() async {
    final response = await _dio.get<Object?>('/notifications/unread-count');
    return ApiModelParser.integer(ApiModelParser.map(response.data), 'count');
  });

  @override
  Future<NotificationRecord> markRead(String notificationId) =>
      _request(() async {
        final response = await _dio.patch<Object?>(
          '/notifications/$notificationId/read',
        );
        return NotificationRecord.fromJson(
          ApiModelParser.map(response.data, 'notification'),
        );
      });

  @override
  Future<int> markAllRead(String workspaceId) => _request(() async {
    final response = await _dio.patch<Object?>(
      '/notifications/read-all',
      data: {'workspaceId': workspaceId},
    );
    return ApiModelParser.integer(
      ApiModelParser.map(response.data),
      'updatedCount',
    );
  });

  @override
  Future<bool> delete(String notificationId) => _request(() async {
    final response = await _dio.delete<Object?>(
      '/notifications/$notificationId',
    );
    final json = ApiModelParser.map(response.data);
    if (json['deleted'] is! bool) {
      throw const FormatException('Invalid deleted acknowledgement');
    }
    return json['deleted']! as bool;
  });

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}
