import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/app_icons/app_icon_sync.dart';

class IconAdapter implements HttpClientAdapter {
  Object selection;
  int requests = 0, failures = 0;
  IconAdapter(this.selection);
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    requests++;
    if (failures > 0) {
      failures--;
      throw DioException(
        requestOptions: o,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(selection),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('shiftly/app_icons');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  for (final key in ['default', 'icon_${'a' * 64}', 'icon_${'b' * 64}']) {
    test('applies only bundled and matching icon selection $key', () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (c) async {
        if (c.method == 'capabilities') {
          return {
            'supported': true,
            'icons': {'default': 'default', 'icon_${'a' * 64}': 'a' * 64},
            'current': 'other',
          };
        }
        calls.add(c.arguments['key'] as String);
        return true;
      });
      final dio = Dio()
        ..httpClientAdapter = IconAdapter({
          'key': key,
          'sha256': key == 'default' ? null : key.substring(5),
          'revision': 1,
        });
      final sync = AppIconSync(dio, enabled: true);
      await sync.synchronize();
      expect(calls, key.contains('b') ? <String>[] : [key]);
      sync.dispose();
    });
  }
  test(
    'a mismatched digest or fetch failure leaves the launcher unchanged',
    () async {
      var changes = 0;
      messenger.setMockMethodCallHandler(channel, (c) async {
        if (c.method == 'capabilities') {
          return {
            'supported': true,
            'icons': {'default': 'default', 'icon_${'a' * 64}': 'a' * 64},
            'current': 'default',
          };
        }
        changes++;
        return true;
      });
      final dio = Dio()
        ..httpClientAdapter = IconAdapter({
          'key': 'icon_${'a' * 64}',
          'sha256': 'b' * 64,
        });
      final sync = AppIconSync(dio, enabled: true);
      await sync.synchronize();
      expect(changes, 0);
      sync.dispose();
    },
  );
  test(
    'resuming rechecks a changed selection inside the periodic throttle',
    () async {
      final key = 'icon_${'a' * 64}';
      final selected = Completer<String>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'capabilities') {
          return {
            'supported': true,
            'current': 'default',
            'icons': {'default': 'default', key: 'a' * 64},
          };
        }
        selected.complete(call.arguments['key'] as String);
        return true;
      });
      final adapter = IconAdapter({'key': 'default', 'sha256': null});
      final dio = Dio()..httpClientAdapter = adapter;
      final sync = AppIconSync(
        dio,
        enabled: true,
        now: () => DateTime.utc(2026),
      );
      addTearDown(sync.dispose);
      await sync.synchronize();
      adapter.selection = {'key': key, 'sha256': 'a' * 64};
      sync.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(await selected.future.timeout(const Duration(seconds: 2)), key);
      expect(adapter.requests, 2);
    },
  );

  test(
    'a failed fetch can retry immediately instead of caching failure',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => {
          'supported': true,
          'current': 'default',
          'icons': {'default': 'default'},
        },
      );
      final adapter = IconAdapter({'key': 'default', 'sha256': null})
        ..failures = 1;
      final sync = AppIconSync(
        Dio()..httpClientAdapter = adapter,
        enabled: true,
        now: () => DateTime.utc(2026),
      );
      addTearDown(sync.dispose);
      await sync.synchronize();
      await sync.synchronize();
      expect(adapter.requests, 2);
    },
  );

  test('unsupported platforms skip network and native operations', () async {
    final dio = Dio();
    final sync = AppIconSync(dio, enabled: false);
    await sync.synchronize();
    sync.dispose();
  });
}
