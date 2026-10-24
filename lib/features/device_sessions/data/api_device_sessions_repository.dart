import 'package:dio/dio.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/features/device_sessions/data/device_description.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

class ApiDeviceSessionsRepository implements DeviceSessionsRepository {
  ApiDeviceSessionsRepository(
    this._api, {
    Future<DeviceDescription> Function()? describe,
  }) : _describe = describe ?? DeviceDescription.read;
  final Dio _api;
  final Future<DeviceDescription> Function() _describe;
  Future<DeviceDescription>? _description;
  @override
  Future<void> registerCurrent() async {
    try {
      final description = await (_description ??= _describe().timeout(
        const Duration(seconds: 10),
      ));
      await _api.post<Object?>(
        '/auth/sessions/current',
        data: description.toJson(),
      );
    } catch (error) {
      _description = null;
      throw ApiErrorParser.parse(error);
    }
  }

  @override
  Future<DeviceSessionsPage> load({int page = 1}) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/auth/sessions',
        queryParameters: {'page': page},
      );
      final data = response.data!;
      final items = (data['items'] as List)
          .map((value) {
            final row = Map<String, dynamic>.from(value as Map);
            return DeviceSession(
              id: row['id'] as String,
              deviceName:
                  (row['deviceName'] as String?)?.trim().isNotEmpty == true
                  ? row['deviceName'] as String
                  : 'Unknown device',
              platform: row['platform'] as String? ?? '',
              osVersion: row['osVersion'] as String? ?? '',
              appVersion: row['appVersion'] as String? ?? '',
              createdAt: DateTime.parse(row['createdAt'] as String),
              lastSeenAt: DateTime.parse(row['lastSeenAt'] as String),
              isCurrent: row['isCurrent'] == true,
              isFirst: row['isFirst'] == true,
            );
          })
          .toList(growable: false);
      return DeviceSessionsPage(items, hasNext: data['hasNext'] == true);
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  @override
  Future<bool> revoke(String sessionId) async {
    try {
      final response = await _api.delete<Map<String, dynamic>>(
        '/auth/sessions/${Uri.encodeComponent(sessionId)}',
      );
      return response.data?['currentSessionRevoked'] == true;
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }

  @override
  Future<void> revokeAll() async {
    try {
      await _api.delete<Object?>('/auth/sessions');
    } catch (error) {
      throw ApiErrorParser.parse(error);
    }
  }
}
