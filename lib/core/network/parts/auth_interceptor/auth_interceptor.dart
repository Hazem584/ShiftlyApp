part of '../../auth_interceptor.dart';

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

    final AuthSession? session;
    try {
      session = await _refreshSession();
    } catch (_) {
      await _expireSession();
      handler.next(_authenticationError(err));
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
        await _expireSession();
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
    try {
      await _authentication.signOut();
    } catch (_) {
      // Continue clearing app-owned authorization state even if the SDK fails.
    }
    try {
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
