import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/network/auth_interceptor.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class ApiClient {
  ApiClient({
    required AppConfig config,
    required AuthenticationService authentication,
    required ActiveWorkspaceStorage workspaceStorage,
    Dio? dio,
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiBaseUrl.toString(),
               connectTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 30),
               receiveTimeout: const Duration(seconds: 30),
               headers: const {
                 'Accept': 'application/json',
                 'Content-Type': 'application/json',
               },
             ),
           ) {
    this.dio.interceptors.addAll([
      AuthInterceptor(
        this.dio,
        authentication,
        workspaceStorage,
        config.apiBaseUrl,
      ),
      _SafeNetworkInterceptor(),
      InterceptorsWrapper(
        onError: (error, handler) => handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiErrorParser.parse(error),
            stackTrace: error.stackTrace,
            message: error.message,
          ),
        ),
      ),
    ]);
  }

  final Dio dio;
}

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
