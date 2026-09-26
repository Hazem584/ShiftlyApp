import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

abstract final class RequestOptionsKeys {
  static const isPublic = 'shiftly.public';
  static const hasRetried = 'shiftly.authRetried';
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._dio,
    this._authentication,
    this._workspaceStorage,
    this._allowedBaseUri,
  );

  final Dio _dio;
  final AuthenticationService _authentication;
  final ActiveWorkspaceStorage _workspaceStorage;
  final Uri _allowedBaseUri;
  Future<AuthSession?>? _refreshing;

  bool _isAllowed(Uri uri) =>
      uri.scheme == _allowedBaseUri.scheme &&
      uri.host == _allowedBaseUri.host &&
      uri.port == _allowedBaseUri.port &&
      (uri.path == _allowedBaseUri.path ||
          uri.path.startsWith('${_allowedBaseUri.path}/'));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = options.extra[RequestOptionsKeys.isPublic] == true;
    if (!isPublic && _isAllowed(options.uri)) {
      final session = _authentication.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        err.type != DioExceptionType.cancel &&
        request.extra[RequestOptionsKeys.isPublic] != true &&
        request.extra[RequestOptionsKeys.hasRetried] != true &&
        _isAllowed(request.uri);
    if (!shouldRefresh) return handler.next(err);

    try {
      final refresh = _refreshing ??= _authentication.refreshSession();
      final session = await refresh;
      if (identical(_refreshing, refresh)) _refreshing = null;
      if (session == null) {
        await _expireSession();
        return handler.next(err);
      }
      final response = await _dio.request<Object?>(
        request.path,
        data: request.data,
        queryParameters: request.queryParameters,
        cancelToken: request.cancelToken,
        options: Options(
          method: request.method,
          headers: Map<String, Object?>.from(request.headers)
            ..['Authorization'] = 'Bearer ${session.accessToken}',
          responseType: request.responseType,
          contentType: request.contentType,
          sendTimeout: request.sendTimeout,
          receiveTimeout: request.receiveTimeout,
          followRedirects: request.followRedirects,
          receiveDataWhenStatusError: request.receiveDataWhenStatusError,
          validateStatus: request.validateStatus,
          extra: Map<String, Object?>.from(request.extra)
            ..[RequestOptionsKeys.hasRetried] = true,
        ),
      );
      handler.resolve(response);
    } catch (_) {
      _refreshing = null;
      await _expireSession();
      handler.next(err);
    }
  }

  Future<void> _expireSession() async {
    await _authentication.signOut();
    await _workspaceStorage.clear();
  }
}
