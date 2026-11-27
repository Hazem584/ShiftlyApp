import 'package:dio/dio.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/network/auth_interceptor_exceptions.dart';
import 'package:shiftly/core/network/auth_request_replay.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class AuthSessionCoordinator {
  AuthSessionCoordinator(
    this.dio,
    this.authentication,
    this.workspaceStorage,
    this.allowedBaseUri,
  );

  final Dio dio;
  final AuthenticationService authentication;
  final ActiveWorkspaceStorage workspaceStorage;
  final Uri allowedBaseUri;
  Future<AuthSession?>? _refreshing;
  Future<void>? _expiring;
  bool sessionExpired = false;

  bool isAllowed(Uri uri) => isAllowedAuthUri(uri, allowedBaseUri);

  bool stillCurrent(AuthSession? initial, {AuthSession? refreshed}) =>
      isSessionStillCurrent(
        authentication.currentSession,
        initial,
        refreshed: refreshed,
      );

  Future<AuthSession?> refreshSession() async {
    final activeRefresh = _refreshing;
    if (activeRefresh != null) return activeRefresh;
    final refresh = authentication.refreshSession();
    _refreshing = refresh;
    try {
      return await refresh;
    } finally {
      if (identical(_refreshing, refresh)) _refreshing = null;
    }
  }

  Future<void> expireSession() async {
    if (sessionExpired) return;
    final activeExpiry = _expiring;
    if (activeExpiry != null) return activeExpiry;
    sessionExpired = true;
    final expiry = performAuthSessionExpiry(authentication, workspaceStorage);
    _expiring = expiry;
    try {
      await expiry;
    } finally {
      if (identical(_expiring, expiry)) _expiring = null;
    }
  }

  Future<void> handleRefreshFailure(
    DioException err,
    ErrorInterceptorHandler handler,
    AuthSession? initial,
    Object error,
  ) async {
    if (!stillCurrent(initial)) {
      handler.next(sessionChangedException(err));
    } else if (error is AuthenticationException &&
        error.failure.kind == FailureKind.authentication) {
      await expireSession();
      handler.next(authenticationExpiredException(err));
    } else {
      handler.next(refreshUnavailableException(err, error));
    }
  }
}
