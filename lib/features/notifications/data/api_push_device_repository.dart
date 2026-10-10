import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/notifications/domain/entities/notification_record.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_device_repository.dart';

class ApiPushDeviceRepository implements PushDeviceRepository {
  ApiPushDeviceRepository(this._dio);
  final Dio _dio;

  @override
  Future<void> register({
    required String installationId,
    required String token,
    required String platform,
  }) => _request(() async {
    final response = await _dio.put<Object?>(
      '/notifications/devices',
      data: {
        'installationId': installationId,
        'token': token,
        'platform': platform,
      },
    );
    if (ApiModelParser.map(response.data)['registered'] != true) {
      throw const FormatException('Invalid device acknowledgement');
    }
  });

  @override
  Future<void> unregister(String installationId) => _request(() async {
    final response = await _dio.delete<Object?>(
      '/notifications/devices/$installationId',
    );
    if (ApiModelParser.map(response.data)['deleted'] != true) {
      throw const FormatException('Invalid device acknowledgement');
    }
  });

  @override
  Future<NotificationRecord> getNotification(String notificationId) =>
      _request(() async {
        final response = await _dio.get<Object?>(
          '/notifications/$notificationId',
        );
        return NotificationRecord.fromJson(ApiModelParser.map(response.data));
      });

  Future<T> _request<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}
