import 'package:dio/dio.dart';
import 'package:shiftly/core/network/auth_interceptor_exceptions.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

Future<Response<Object?>> replayAuthenticatedRequest(
  Dio dio,
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
  return dio.request<Object?>(
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

Future<void> performAuthSessionExpiry(
  AuthenticationService authentication,
  ActiveWorkspaceStorage workspaceStorage,
) async {
  final expiring = authentication.currentSession;
  try {
    await authentication.signOut();
  } catch (_) {}
  try {
    final current = authentication.currentSession;
    if (current != null &&
        (expiring == null || !current.sameLoginAs(expiring))) {
      return;
    }
    await workspaceStorage.clear();
  } catch (_) {}
}
