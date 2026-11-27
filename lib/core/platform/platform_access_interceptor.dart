import 'package:dio/dio.dart';

Interceptor installPlatformAccessInterceptor(
  Dio client,
  void Function(DioException) inspect,
) {
  final interceptor = InterceptorsWrapper(
    onError: (error, handler) {
      inspect(error);
      handler.next(error);
    },
  );
  client.interceptors.insert(0, interceptor);
  return interceptor;
}

({bool deleted, String? suspension, Map<String, dynamic>? status})
parsePlatformAccessError(Object? body) {
  if (body is Map) {
    if (body['code'] == 'ACCOUNT_DELETED') {
      return (deleted: true, suspension: null, status: null);
    }
    if (body['code'] == 'ACCOUNT_SUSPENDED') {
      return (
        deleted: false,
        suspension: body['message']?.toString() ?? 'Account suspended',
        status: null,
      );
    }
    if (body['code'] == 'PLATFORM_UNAVAILABLE' && body['platform'] is Map) {
      return (
        deleted: false,
        suspension: null,
        status: Map<String, dynamic>.from(body['platform'] as Map),
      );
    }
  }
  return (deleted: false, suspension: null, status: null);
}
