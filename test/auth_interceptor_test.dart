import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/network/auth_interceptor.dart';
import 'package:shiftly/core/storage/active_workspace_storage.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class _Auth implements AuthenticationService {
  AuthSession? session;
  int refreshCalls = 0;
  int signOutCalls = 0;
  bool refreshFails = false;
  Duration refreshDelay = Duration.zero;
  final events = StreamController<AuthenticationEvent>.broadcast();

  @override
  Stream<AuthenticationEvent> get authStateChanges => events.stream;
  @override
  AuthSession? get currentSession => session;
  @override
  Future<AuthSession?> refreshSession() async {
    refreshCalls++;
    await Future<void>.delayed(refreshDelay);
    if (refreshFails) throw Exception('refresh failed');
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

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final authorization = options.headers['Authorization'];
    if (options.uri.host == 'api.example.com' &&
        authorization != 'Bearer new-token') {
      return ResponseBody.fromString(
        jsonEncode({'code': 'UNAUTHORIZED', 'message': 'expired'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({Dio dio, _Adapter adapter}) _client(
  _Auth auth,
  ActiveWorkspaceStorage storage,
) {
  final adapter = _Adapter();
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

void main() {
  test('attaches the latest bearer token and retries once after 401', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final client = _client(auth, MemoryActiveWorkspaceStorage());
    final response = await client.dio.get<Object?>('/protected');
    expect(response.statusCode, 200);
    expect(auth.refreshCalls, 1);
    expect(client.adapter.requests, hasLength(2));
    expect(
      client.adapter.requests.first.headers['Authorization'],
      'Bearer old-token',
    );
    expect(
      client.adapter.requests.last.headers['Authorization'],
      'Bearer new-token',
    );
  });

  test('concurrent 401 responses share one refresh operation', () async {
    final auth = _Auth()
      ..session = const AuthSession(accessToken: 'old-token')
      ..refreshDelay = const Duration(milliseconds: 20);
    final client = _client(auth, MemoryActiveWorkspaceStorage());
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
    final storage = MemoryActiveWorkspaceStorage()..value = 'workspace';
    final client = _client(auth, storage);
    await expectLater(
      client.dio.get<Object?>('/protected'),
      throwsA(isA<DioException>()),
    );
    expect(auth.signOutCalls, 1);
    expect(storage.value, isNull);
    expect(client.adapter.requests, hasLength(1));
  });

  test('never sends authorization to an unrelated host', () async {
    final auth = _Auth()
      ..session = const AuthSession(accessToken: 'secret-token');
    final client = _client(auth, MemoryActiveWorkspaceStorage());
    await client.dio.get<Object?>('https://other.example/path');
    expect(client.adapter.requests.single.headers['Authorization'], isNull);
  });

  test('public requests are never refreshed', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final client = _client(auth, MemoryActiveWorkspaceStorage());
    await expectLater(
      client.dio.get<Object?>(
        '/protected',
        options: Options(extra: {RequestOptionsKeys.isPublic: true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(auth.refreshCalls, 0);
  });

  test('cancelled requests are never refreshed', () async {
    final auth = _Auth()..session = const AuthSession(accessToken: 'old-token');
    final client = _client(auth, MemoryActiveWorkspaceStorage());
    final token = CancelToken()..cancel('test cancellation');
    await expectLater(
      client.dio.get<Object?>('/protected', cancelToken: token),
      throwsA(isA<DioException>()),
    );
    expect(auth.refreshCalls, 0);
  });
}
