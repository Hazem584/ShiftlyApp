import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shiftly/core/monitoring/app_monitor.dart';
import 'package:shiftly/core/monitoring/monitoring_gate.dart';

import 'support/onboarding_test_auth.dart';

class _ReleaseAdapter implements HttpClientAdapter {
  Map<String, Object?>? release;
  bool fail = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'release': release}),
      fail ? 503 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Shiftly',
      packageName: 'app.shiftly',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test',
    );
  });
  Future<void> mount(
    WidgetTester tester,
    _ReleaseAdapter adapter, {
    Future<bool> Function(Uri)? openRelease,
  }) async {
    final auth = OnboardingTestAuth();
    addTearDown(() => auth.events.close());
    final public = Dio()..httpClientAdapter = adapter;
    await tester.pumpWidget(
      MaterialApp(
        home: MonitoringGate(
          apiClient: Dio(),
          releaseClient: public,
          openRelease: openRelease,
          authentication: auth,
          child: const Scaffold(body: Text('Application content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Map<String, Object?> release({bool required = false}) => {
    'build': 2,
    'version': '1.1.0',
    'message': 'Please install the latest fixes',
    'required': required,
    'url': 'https://appdistribution.firebase.google.com/testerapps/app/releases/release',
  };
  testWidgets('optional update appears before entry and can be deferred', (
    tester,
  ) async {
    await mount(tester, _ReleaseAdapter()..release = release());
    expect(find.text('Application content'), findsNothing);
    expect(find.text('Please install the latest fixes'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Application content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
  testWidgets('required update prevents deferring entry', (tester) async {
    await mount(tester, _ReleaseAdapter()..release = release(required: true));
    expect(find.text('Later'), findsNothing);
    expect(find.text('Application content'), findsNothing);
    expect(find.text('Update required to continue.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
  testWidgets('release service outage leaves the application usable', (
    tester,
  ) async {
    await mount(tester, _ReleaseAdapter()..fail = true);
    expect(find.text('Application content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
  for (final opened in [false, true]) {
    testWidgets(
      'required tester release can recover after launch result $opened',
      (tester) async {
        await mount(
          tester,
          _ReleaseAdapter()..release = release(required: true),
          openRelease: (_) async => opened,
        );
        await tester.tap(find.text('Update now'));
        await tester.pumpAndSettle();
        expect(find.text('Continue temporarily'), findsOneWidget);
        await tester.ensureVisible(find.text('Continue temporarily'));
        await tester.tap(find.text('Continue temporarily'));
        await tester.pumpAndSettle();
        expect(find.text('Application content'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      },
      variant: TargetPlatformVariant({TargetPlatform.android}),
    );
  }
  testWidgets('a disabled release clears an existing required update', (
    tester,
  ) async {
    final adapter = _ReleaseAdapter()..release = release(required: true);
    await mount(tester, adapter);
    adapter.release = null;
    await tester.tap(find.text('Check update again'));
    await tester.pumpAndSettle();
    expect(find.text('Application content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
  testWidgets('rejects a release for another channel or platform', (
    tester,
  ) async {
    await mount(
      tester,
      _ReleaseAdapter()
        ..release = {
          ...release(required: true),
          'channel': 'production',
          'platform': 'ios',
        },
    );
    expect(find.text('Application content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant({TargetPlatform.android}));
  test('diagnostics redact credentials and release URLs use the Firebase tester host', () {
    final safe = redactDiagnostic(
      'password=secret Bearer xyz person@example.com https://example.com?token=secret',
      2000,
    );
    expect(safe, isNot(contains('secret')));
    expect(safe, isNot(contains('xyz')));
    expect(
      validReleaseUrl(
        'https://appdistribution.firebase.google.com/testerapps/a/releases/b',
      ),
      isTrue,
    );
    expect(
      validReleaseUrl(
        'https://appdistribution.firebase.google.com.evil.test/testerapps/a',
      ),
      isFalse,
    );
    expect(
      validReleaseUrl(
        'http://appdistribution.firebase.google.com/testerapps/a',
      ),
      isFalse,
    );
  });
}
