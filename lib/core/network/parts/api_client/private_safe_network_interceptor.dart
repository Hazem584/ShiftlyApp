part of '../../api_client.dart';

class _SafeNetworkInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('API ${options.method} ${options.uri.path}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint(
        'API ${response.requestOptions.method} '
        '${response.requestOptions.uri.path} ${response.statusCode}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final parsed = error.error is ApiException
          ? error.error! as ApiException
          : ApiErrorParser.parse(error);
      final code = parsed.code == null ? '' : ' code=${parsed.code}';
      final requestId = parsed.requestId == null
          ? ''
          : ' requestId=${parsed.requestId}';
      debugPrint(
        'API ${error.requestOptions.method} '
        '${error.requestOptions.uri.path} '
        '${error.response?.statusCode ?? 'failed'}$code$requestId',
      );
    }
    handler.next(error);
  }
}
