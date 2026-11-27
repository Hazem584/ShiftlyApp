import 'package:dio/dio.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_exception.dart';

abstract final class RequestOptionsKeys {
  static const isPublic = 'shiftly.public';
  static const hasRetried = 'shiftly.authRetried';
}

bool isAllowedAuthUri(Uri uri, Uri allowedBaseUri) =>
    uri.scheme == allowedBaseUri.scheme &&
    uri.host == allowedBaseUri.host &&
    uri.port == allowedBaseUri.port &&
    (uri.path == allowedBaseUri.path ||
        uri.path.startsWith('${allowedBaseUri.path}/'));

bool isSessionStillCurrent(
  AuthSession? current,
  AuthSession? initial, {
  AuthSession? refreshed,
}) {
  if (current == null) return true;
  return (initial != null && current.sameLoginAs(initial)) ||
      (refreshed != null &&
          current.sameLoginAs(refreshed) &&
          (initial?.sessionId == null || initial!.sameLoginAs(refreshed)));
}

DioException sessionChangedException(DioException source) => DioException(
  requestOptions: source.requestOptions,
  type: DioExceptionType.cancel,
  message: 'The signed-in account changed while this request was running.',
);

DioException refreshUnavailableException(DioException source, Object error) {
  final failure = error is AuthenticationException ? error.failure : null;
  return DioException(
    requestOptions: source.requestOptions,
    response: Response<Object?>(
      requestOptions: source.requestOptions,
      statusCode: 503,
      data: const {
        'code': 'SESSION_REFRESH_UNAVAILABLE',
        'message':
            'Could not refresh your session. Check your connection and retry.',
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

DioException authenticationExpiredException(DioException source) =>
    DioException(
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
