import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shiftly/core/config/app_config.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/network/auth_interceptor.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

part 'parts/api_client/private_safe_network_interceptor.dart';

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
