import 'package:dio/dio.dart';
import 'package:shiftly/core/network/auth_interceptor_exceptions.dart';
import 'package:shiftly/core/network/auth_request_replay.dart';
import 'package:shiftly/core/network/auth_session_coordinator.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

export 'auth_interceptor_exceptions.dart' show RequestOptionsKeys;

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    Dio dio,
    AuthenticationService authentication,
    ActiveWorkspaceStorage workspaceStorage,
    Uri allowedBaseUri,
  ) : _coordinator = AuthSessionCoordinator(
        dio,
        authentication,
        workspaceStorage,
        allowedBaseUri,
      );

  final AuthSessionCoordinator _coordinator;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = options.extra[RequestOptionsKeys.isPublic] == true;
    if (!isPublic && _coordinator.isAllowed(options.uri)) {
      final session = _coordinator.authentication.currentSession;
      if (session != null) {
        _coordinator.sessionExpired = false;
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
        _coordinator.isAllowed(request.uri);
    final auth = request.headers['Authorization']?.toString();
    final sent = auth?.startsWith('Bearer ') == true
        ? AuthSession(accessToken: auth!.substring(7))
        : null;
    if (!shouldRefresh || sent == null) {
      handler.next(err);
      return;
    }
    final initial = _coordinator.authentication.currentSession;
    if (initial != null && !initial.sameLoginAs(sent)) {
      handler.next(sessionChangedException(err));
      return;
    }
    final body = err.response?.data;
    if (body is Map && body['code'] == 'SESSION_REVOKED') {
      await _coordinator.expireSession();
      handler.next(authenticationExpiredException(err));
      return;
    }
    AuthSession? session;
    try {
      session = initial != null && initial.accessToken != sent.accessToken
          ? initial
          : await _coordinator.refreshSession();
    } catch (error) {
      await _coordinator.handleRefreshFailure(err, handler, initial, error);
      return;
    }
    if ((session != null &&
            _coordinator.authentication.currentSession == null) ||
        !_coordinator.stillCurrent(initial, refreshed: session)) {
      handler.next(sessionChangedException(err));
      return;
    }
    if (session == null) {
      await _coordinator.expireSession();
      handler.next(authenticationExpiredException(err));
      return;
    }
    await _replayOrFail(request, session, handler);
  }

  Future<void> _replayOrFail(
    RequestOptions request,
    AuthSession session,
    ErrorInterceptorHandler handler,
  ) async {
    _coordinator.sessionExpired = false;
    try {
      handler.resolve(
        await replayAuthenticatedRequest(_coordinator.dio, request, session),
      );
    } on DioException catch (retryError) {
      if (retryError.response?.statusCode == 401 &&
          _coordinator.stillCurrent(session)) {
        await _coordinator.expireSession();
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
}
