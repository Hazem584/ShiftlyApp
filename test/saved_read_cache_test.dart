import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/offline/read_sync_cubit.dart';
import 'package:shiftly/core/offline/read_sync_state.dart';
import 'package:shiftly/core/offline/saved_read_interceptor.dart';
import 'package:shiftly/core/offline/saved_read_policy.dart';
import 'package:shiftly/core/offline/saved_read_store.dart';
import 'package:shiftly/core/session/session_state.dart';

class _Adapter implements HttpClientAdapter {
  FutureOr<ResponseBody> Function(RequestOptions) handler = (_) =>
      ResponseBody.fromString(
        '{"data":["shift"]}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  final now = DateTime.utc(2026, 10, 10);
  late SavedReadStore store;
  late ReadSyncCubit sync;
  late Dio dio;
  late _Adapter adapter;
  setUp(() {
    store = SavedReadStore();
    sync = ReadSyncCubit(store)
      ..owner = 'user|workspace|member|employee'
      ..workspaceId = 'workspace';
    adapter = _Adapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        SavedReadInterceptor(sync, hasSession: () => true, now: () => now),
      );
  });
  tearDown(() async {
    dio.close();
    await sync.close();
  });
  Future<Response<dynamic>> read() =>
      dio.get('/attendance/me', queryParameters: {'workspaceId': 'workspace'});
  void disconnect() {
    adapter.handler = (options) => throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  test(
    'a successful read survives a connection failure with its timestamp',
    () async {
      final fresh = await read();
      disconnect();
      final saved = await read();
      expect(saved.data, fresh.data);
      expect(saved.extra['fromSavedRead'], isTrue);
      expect(sync.state.statuses[ReadCategory.attendance]!.usingSaved, isTrue);
      expect(sync.state.statuses[ReadCategory.attendance]!.updatedAt, now);
      expect(sync.state.statuses[ReadCategory.attendance]!.pending, 0);
    },
  );
  test('authorization errors never return saved data', () async {
    await read();
    adapter.handler = (_) => ResponseBody.fromString('{}', 403);
    await expectLater(read(), throwsA(isA<DioException>()));
    disconnect();
    await expectLater(read(), throwsA(isA<DioException>()));
  });
  test(
    'switching workspace or account cannot expose the previous snapshot',
    () async {
      await read();
      sync.owner = 'another-user|workspace|member|employee';
      sync.generation++;
      disconnect();
      await expectLater(read(), throwsA(isA<DioException>()));
      expect(
        SavedReadPolicy.category(
          RequestOptions(
            path: '/attendance/me',
            queryParameters: {'workspaceId': 'other'},
          ),
          'workspace',
        ),
        isNull,
      );
    },
  );
  test(
    'a response arriving after logout does not repopulate the cache',
    () async {
      final pending = Completer<ResponseBody>();
      adapter.handler = (_) => pending.future;
      final request = read();
      await Future<void>.delayed(Duration.zero);
      sync.bind(const SessionState(status: SessionStatus.unauthenticated));
      pending.complete(ResponseBody.fromString(jsonEncode({'data': []}), 200));
      await request;
      expect(
        store.read(
          store.key(
            'user|workspace|member|employee',
            'https://example.test/attendance/me?workspaceId=workspace',
          ),
          'user|workspace|member|employee',
          now,
        ),
        isNull,
      );
    },
  );
  test(
    'mutations and live eligibility and recovery reads are never cached',
    () {
      for (final request in [
        RequestOptions(path: '/attendance/me', method: 'POST'),
        RequestOptions(path: '/attendance/me/current'),
        RequestOptions(path: '/shift-templates/eligibility'),
        RequestOptions(
          path: '/attendance/me',
          queryParameters: {
            'workspaceId': 'workspace',
            'clientAttendanceId': 'request',
          },
        ),
        RequestOptions(
          path: '/attendance/me',
          queryParameters: {'workspaceId': 'workspace'},
          extra: {'requireFresh': true},
        ),
      ]) {
        expect(SavedReadPolicy.category(request, 'workspace'), isNull);
      }
    },
  );
  test('snapshots persist across store instances, expire, and clear all user workspaces', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final first = SavedReadStore(prefs);
    for (final owner in ['user|one', 'user|two', 'other|one']) {
      await first.write(
        first.key(owner, '/shifts'),
        SavedRead(owner: owner, data: [], updatedAt: now),
      );
    }
    final reopened = SavedReadStore(prefs);
    final key = reopened.key('user|one', '/shifts');
    expect(reopened.read(key, 'user|one', now), isNotNull);
    expect(reopened.read(key, 'other|one', now), isNull);
    expect(
      reopened.read(key, 'user|one', now.add(const Duration(days: 8))),
      isNull,
    );
    await reopened.clearUser('user');
    expect(reopened.read(key, 'user|one', now), isNull);
    expect(
      reopened.read(reopened.key('user|two', '/shifts'), 'user|two', now),
      isNull,
    );
    expect(
      reopened.read(reopened.key('other|one', '/shifts'), 'other|one', now),
      isNotNull,
    );
  });
  test(
    'a fresh parallel response does not replace the saved data timestamp',
    () {
      sync.begin(ReadCategory.schedule);
      sync.begin(ReadCategory.schedule);
      final old = now.subtract(const Duration(hours: 2));
      sync.finish(ReadCategory.schedule, saved: true, updatedAt: old);
      sync.finish(ReadCategory.schedule, updatedAt: now);
      expect(sync.state.statuses[ReadCategory.schedule]!.updatedAt, old);
    },
  );
}
