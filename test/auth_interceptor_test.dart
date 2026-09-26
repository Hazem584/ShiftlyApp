import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/network/auth_interceptor.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_repository.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class _Auth implements AuthenticationService {
  AuthSession? session;
  int refreshCalls = 0;
  int signOutCalls = 0;
  bool refreshFails = false;
  bool refreshReturnsNull = false;
  Duration refreshDelay = Duration.zero;
  void Function()? onRefresh;
  final events = StreamController<AuthenticationEvent>.broadcast();

  @override
  Stream<AuthenticationEvent> get authStateChanges => events.stream;
  @override
  AuthSession? get currentSession => session;
  @override
  Future<AuthSession?> refreshSession() async {
    refreshCalls++;
    await Future<void>.delayed(refreshDelay);
    onRefresh?.call();
    if (refreshFails) throw Exception('refresh failed');
    if (refreshReturnsNull) return null;
    session = const AuthSession(accessToken: 'new-token');
    return session;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    session = null;
  }

  @override
  Future<AuthenticationResult> signIn({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<AuthenticationResult> signUp({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}

class _Storage implements ActiveWorkspaceStorage {
  String? value = 'workspace';
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    value = null;
  }

  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String workspaceId) async => value = workspaceId;
}

typedef _ResponseHandler = FutureOr<ResponseBody> Function(
  RequestOptions options,
  int requestNumber,
);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final _ResponseHandler handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, [Map<String, Object?> body = const {}]) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

({Dio dio, _Adapter adapter}) _client(
  _Auth auth,
  ActiveWorkspaceStorage storage,
  _ResponseHandler handler,
) {
  final adapter = _Adapter(handler);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    AuthInterceptor(
      dio,
      auth,
      storage,
      Uri.parse('https://api.example.com/api/v1'),
    ),
  );
  return (dio: dio, adapter: adapter);
}

class _NeverRepository implements AuthenticationRepository {
  int loads = 0;

  @override
  Future<void> bootstrapProfile({String? fullName, String? phone}) async {}
  @override
  Future<CurrentUser> loadCurrentUser() async {
    loads++;
    throw StateError('A signed-out app must not load the current user.');
  }
}

void main() {
  test('successful refresh replays the complete request once', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final client = _client(
      auth,
      _Storage(),
      (options, number) => number == 1
          ? _json(401, {'code': 'UNAUTHORIZED'})
          : _json(200, {'ok': true}),
    );
    final response = await client.dio.post<Object?>(
      '/protected',
      data: {'value': 7},
      queryParameters: {'page': 2},
      options: Options(headers: {'X-Custom': 'preserved'}),
    );

    expect(response.statusCode, 200);
    expect(auth.refreshCalls, 1);
    expect(client.adapter.requests, hasLength(2));
    final retry = client.adapter.requests.last;
    expect(retry.method, 'POST');
    expect(retry.uri.path, '/api/v1/protected');
    expect(retry.queryParameters, {'page': 2});
    expect(retry.data, {'value': 7});
    expect(retry.headers['X-Custom'], 'preserved');
    expect(retry.headers['Authorization'], 'Bearer new-token');
    expect(retry.extra[RequestOptionsKeys.hasRetried], isTrue);
  });

  test('concurrent 401 responses share one refresh operation', () async {
    final auth = _Auth()
      ..session = const AuthSession(accessToken: 'old-token')
      ..refreshDelay = const Duration(milliseconds: 20);
    final client = _client(
      auth,
      _Storage(),
      (options, _) => options.headers['Authorization'] == 'Bearer new-token'
          ? _json(200)
          : _json(401),
    );
    await Future.wait([
      client.dio.get<Object?>('/first'),
      client.dio.get<Object?>('/second'),
    ]);
    expect(auth.refreshCalls, 1);
  });

  test('refresh failure signs out and clears workspace', () async {
    final auth = _Auth()
      ..session = const AuthSession(accessToken: 'old-token')
      ..refreshFails = true;
    final storage = _Storage();
    final client = _client(auth, storage, (_, _) => _json(401));

    await expectLater(
      client.dio.get<Object?>('/protected'),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(auth.signOutCalls, 1);
    expect(storage.clearCalls, 1);
    expect(storage.value, isNull);
  });

  test('concurrent refresh failure performs controlled cleanup once', () async {
    final auth = _Auth()
      ..session = const AuthSession(accessToken: 'old-token')
      ..refreshFails = true
      ..refreshDelay = const Duration(milliseconds: 20);
    final storage = _Storage();
    final client = _client(auth, storage, (_, _) => _json(401));

    final results = await Future.wait(
      [
        client.dio.get<Object?>('/first'),
        client.dio.get<Object?>('/second'),
      ].map(
        (request) => request
            .then<Object?>((value) => value)
            .catchError((Object error) => error),
      ),
    );
    expect(results.whereType<DioException>(), hasLength(2));
    expect(auth.refreshCalls, 1);
    expect(auth.signOutCalls, 1);
    expect(storage.clearCalls, 1);
  });

  test('retried 500 propagates without signing out', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final storage = _Storage();
    final client = _client(
      auth,
      storage,
      (_, number) => number == 1 ? _json(401) : _json(500),
    );

    await expectLater(
      client.dio.get<Object?>('/protected'),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'latest status',
          500,
        ),
      ),
    );
    expect(auth.signOutCalls, 0);
    expect(storage.clearCalls, 0);
  });

  test('retried network failure propagates without signing out', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final storage = _Storage();
    final client = _client(auth, storage, (options, number) {
      if (number == 1) return _json(401);
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    });

    await expectLater(
      client.dio.get<Object?>('/protected'),
      throwsA(
        isA<DioException>().having(
          (error) => error.type,
          'latest type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    expect(auth.signOutCalls, 0);
    expect(storage.clearCalls, 0);
  });

  test('replay cancellation propagates without signing out', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final storage = _Storage();
    final token = CancelToken();
    auth.onRefresh = () => token.cancel('cancel replay');
    final client = _client(auth, storage, (_, _) => _json(401));

    await expectLater(
      client.dio.get<Object?>('/protected', cancelToken: token),
      throwsA(
        isA<DioException>().having(
          (error) => error.type,
          'latest type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(auth.signOutCalls, 0);
    expect(storage.clearCalls, 0);
  });

  test(
    'a second 401 expires the session and retries no more than once',
    () async {
      final auth = _Auth()
        ..session = const AuthSession(accessToken: 'old-token');
      final storage = _Storage();
      final client = _client(auth, storage, (_, _) => _json(401));

      await expectLater(
        client.dio.get<Object?>('/protected'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'final status',
            401,
          ),
        ),
      );
      expect(client.adapter.requests, hasLength(2));
      expect(auth.refreshCalls, 1);
      expect(auth.signOutCalls, 1);
      expect(storage.value, isNull);
    },
  );

  test('latest retry error is propagated instead of original 401', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final client = _client(
      auth,
      _Storage(),
      (_, number) => number == 1 ? _json(401) : _json(429),
    );
    await expectLater(
      client.dio.get<Object?>('/protected'),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'latest status',
          429,
        ),
      ),
    );
    expect(auth.signOutCalls, 0);
  });

  test('never sends authorization to an unrelated host', () async {
    final auth = _Auth()
      ..session = const AuthSession(accessToken: 'secret-token');
    final client = _client(auth, _Storage(), (_, _) => _json(200));
    await client.dio.get<Object?>('https://other.example/path');
    expect(client.adapter.requests.single.headers['Authorization'], isNull);
  });

  test('public requests are never refreshed', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final client = _client(auth, _Storage(), (_, _) => _json(401));
    await expectLater(
      client.dio.get<Object?>(
        '/protected',
        options: Options(extra: {RequestOptionsKeys.isPublic: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(auth.refreshCalls, 0);
  });

  test('multipart FormData is cloned and safely replayed', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    FormData? firstData;
    FormData? retryData;
    final client = _client(auth, _Storage(), (options, number) {
      if (number == 1) {
        firstData = options.data! as FormData;
        return _json(401);
      }
      retryData = options.data! as FormData;
      return _json(200);
    });
    final form = FormData.fromMap({
      'label': 'avatar',
      'avatar': MultipartFile.fromBytes(
        Uint8List.fromList([1, 2, 3]),
        filename: 'avatar.png',
      ),
    });

    await client.dio.post<Object?>('/avatar', data: form);
    expect(firstData, same(form));
    expect(retryData, isNot(same(firstData)));
    expect(retryData!.fields, firstData!.fields);
    expect(retryData!.files.single.key, 'avatar');
    expect(retryData!.files.single.value.filename, 'avatar.png');
  });

  test(
    'restart after final 401 cannot restore a stale protected session',
    () async {
      final auth = _Auth()
        ..session = const AuthSession(accessToken: 'old-token');
      final storage = _Storage();
      final client = _client(auth, storage, (_, _) => _json(401));
      await expectLater(
        client.dio.get<Object?>('/protected'),
        throwsA(isA<DioException>()),
      );

      final repository = _NeverRepository();
      final coordinator = SessionCoordinator(auth, repository, storage);
      addTearDown(coordinator.close);
      addTearDown(auth.events.close);
      await coordinator.initialize();
      expect(coordinator.state.status, SessionStatus.unauthenticated);
      expect(repository.loads, 0);
      expect(storage.value, isNull);
    },
  );
}
