import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
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
  Future<void>? _expiring;
  bool _sessionExpired = false;

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
        _sessionExpired = false;
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      } else {
        options.headers.remove('Authorization');
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
    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final initial = _authentication.currentSession;
    final authorization = request.headers['Authorization']?.toString();
    final sent = authorization?.startsWith('Bearer ') == true
        ? AuthSession(accessToken: authorization!.substring(7))
        : null;
    if (sent == null) {
      handler.next(err);
      return;
    }
    if (initial != null && !initial.sameLoginAs(sent)) {
      handler.next(_sessionChanged(err));
      return;
    }
    final body = err.response?.data;
    if (body is Map && body['code'] == 'SESSION_REVOKED') {
      await _expireSession();
      handler.next(_authenticationError(err));
      return;
    }

    final AuthSession? session;
    try {
      // A delayed 401 may refer to a token already refreshed by another request.
      session = initial != null && initial.accessToken != sent.accessToken
          ? initial
          : await _refreshSession();
    } catch (error) {
      if (!_stillCurrent(initial)) {
        handler.next(_sessionChanged(err));
      } else if (error is AuthenticationException &&
          error.failure.kind == FailureKind.authentication) {
        await _expireSession();
        handler.next(_authenticationError(err));
      } else {
        handler.next(_refreshUnavailable(err, error));
      }
      return;
    }

    if ((session != null && _authentication.currentSession == null) ||
        !_stillCurrent(initial, refreshed: session)) {
      handler.next(_sessionChanged(err));
      return;
    }

    if (session == null) {
      await _expireSession();
      handler.next(_authenticationError(err));
      return;
    }

    _sessionExpired = false;
    try {
      final response = await _replay(request, session);
      handler.resolve(response);
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401) {
        if (_stillCurrent(session)) await _expireSession();
      }
      handler.next(retryError);
    } catch (error, stackTrace) {
      handler.next(
        DioException(
          requestOptions: request,
          error: error,
          stackTrace: stackTrace,
          type: DioExceptionType.unknown,
          message: 'Request replay failed.',
        ),
      );
    }
  }

  bool _stillCurrent(AuthSession? initial, {AuthSession? refreshed}) {
    final current = _authentication.currentSession;
    if (current == null) return true;
    return (initial != null && current.sameLoginAs(initial)) ||
        (refreshed != null &&
            current.sameLoginAs(refreshed) &&
            (initial?.sessionId == null || initial!.sameLoginAs(refreshed)));
  }

  DioException _sessionChanged(DioException source) => DioException(
    requestOptions: source.requestOptions,
    type: DioExceptionType.cancel,
    message: 'The signed-in account changed while this request was running.',
  );

  DioException _refreshUnavailable(DioException source, Object error) {
    final failure = error is AuthenticationException ? error.failure : null;
    return DioException(
      requestOptions: source.requestOptions,
      response: Response<Object?>(
        requestOptions: source.requestOptions,
        statusCode: 503,
        data: const {
          'code': 'SESSION_REFRESH_UNAVAILABLE',
          'message': 'Could not refresh your session. Check your connection and retry.',
        },
      ),
      type: failure?.kind == FailureKind.timeout
          ? DioExceptionType.connectionTimeout
          : failure?.kind == FailureKind.server
          ? DioExceptionType.badResponse
          : DioExceptionType.connectionError,
      message: 'Session refresh temporarily unavailable.',
    );
  }

  Future<AuthSession?> _refreshSession() async {
    final activeRefresh = _refreshing;
    if (activeRefresh != null) return activeRefresh;

    final refresh = _authentication.refreshSession();
    _refreshing = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshing, refresh)) _refreshing = null;
    }
  }

  Future<Response<Object?>> _replay(
    RequestOptions request,
    AuthSession session,
  ) {
    final headers = Map<String, Object?>.from(request.headers)
      ..['Authorization'] = 'Bearer ${session.accessToken}';
    final extras = Map<String, Object?>.from(request.extra)
      ..[RequestOptionsKeys.hasRetried] = true;
    final data = request.data is FormData
        ? (request.data as FormData).clone()
        : request.data;

    return _dio.request<Object?>(
      request.path,
      data: data,
      queryParameters: request.queryParameters,
      cancelToken: request.cancelToken,
      onSendProgress: request.onSendProgress,
      onReceiveProgress: request.onReceiveProgress,
      options: Options(
        method: request.method,
        headers: headers,
        responseType: request.responseType,
        contentType: request.contentType,
        sendTimeout: request.sendTimeout,
        receiveTimeout: request.receiveTimeout,
        transformTimeout: request.transformTimeout,
        connectTimeout: request.connectTimeout,
        followRedirects: request.followRedirects,
        maxRedirects: request.maxRedirects,
        persistentConnection: request.persistentConnection,
        receiveDataWhenStatusError: request.receiveDataWhenStatusError,
        validateStatus: request.validateStatus,
        requestEncoder: request.requestEncoder,
        responseDecoder: request.responseDecoder,
        listFormat: request.listFormat,
        preserveHeaderCase: request.preserveHeaderCase,
        extra: extras,
      ),
    );
  }

  Future<void> _expireSession() async {
    if (_sessionExpired) return;
    final activeExpiry = _expiring;
    if (activeExpiry != null) return activeExpiry;

    _sessionExpired = true;
    final expiry = _performExpiry();
    _expiring = expiry;
    try {
      await expiry;
    } finally {
      if (identical(_expiring, expiry)) _expiring = null;
    }
  }

  Future<void> _performExpiry() async {
    final expiring = _authentication.currentSession;
    try {
      await _authentication.signOut();
    } catch (_) {
      // Continue clearing app-owned authorization state even if the SDK fails.
    }
    try {
      final current = _authentication.currentSession;
      if (current != null &&
          (expiring == null || !current.sameLoginAs(expiring))) {
        return;
      }
      await _workspaceStorage.clear();
    } catch (_) {
      // The authentication error must still reach the caller safely.
    }
  }

  DioException _authenticationError(DioException source) => DioException(
    requestOptions: source.requestOptions,
    response: Response<Object?>(
      requestOptions: source.requestOptions,
      statusCode: 401,
      data: const <String, Object?>{
        'statusCode': 401,
        'code': 'SESSION_EXPIRED',
        'message': 'Your session has expired. Please sign in again.',
      },
    ),
    type: DioExceptionType.badResponse,
    message: 'Authentication session expired.',
  );
}
