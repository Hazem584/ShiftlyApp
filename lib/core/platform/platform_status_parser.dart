import 'package:dio/dio.dart';

Future<Map<String, dynamic>> fetchPlatformStatus(Dio client) async {
  final response = await client.get<Object?>('/platform/status');
  return parsePlatformStatus(response.data);
}

Map<String, dynamic> parsePlatformStatus(Object? data) {
  if (data is! Map ||
      !const [
        'OPERATIONAL',
        'MAINTENANCE',
        'UPDATING',
        'DISABLED',
      ].contains(data['mode'])) {
    throw const FormatException('Invalid platform status');
  }
  return Map<String, dynamic>.from(data);
}
