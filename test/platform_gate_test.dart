import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/platform/platform_gate.dart';
import 'package:shiftly/features/auth/domain/entities/auth_session.dart';

import 'support/onboarding_test_auth.dart';

class _Adapter implements HttpClientAdapter {
  Map<String, Object?> status = {'mode': 'OPERATIONAL', 'announcement': ''};
  Map<String, Object?>? accessError;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final access = options.path == '/platform/access';
    return ResponseBody.fromString(
      jsonEncode(access ? accessError ?? {'allowed': true} : status),
      access && accessError != null ? 403 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('deleted accounts clear their local authentication', (
    tester,
  ) async {
    final adapter = _Adapter()
      ..accessError = {'code': 'ACCOUNT_DELETED', 'message': 'Deleted'};
    final auth = OnboardingTestAuth()
      ..session = const AuthSession(accessToken: 'deleted-token');
    final public = Dio()..httpClientAdapter = adapter;
    final api = Dio()..httpClientAdapter = adapter;
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformGate(
          statusClient: public,
          apiClient: api,
          authentication: auth,
          child: const Scaffold(body: Text('Application content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(auth.currentSession, isNull);
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });
  Future<void> mount(
    WidgetTester tester,
    _Adapter adapter,
    OnboardingTestAuth auth,
  ) async {
    final public = Dio()..httpClientAdapter = adapter;
    final api = Dio()..httpClientAdapter = adapter;
    await tester.pumpWidget(
      MaterialApp(
        home: PlatformGate(
          statusClient: public,
          apiClient: api,
          authentication: auth,
          child: const Scaffold(body: Text('Application content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('operational mode shows the application and its announcement', (
    tester,
  ) async {
    final adapter = _Adapter()
      ..status['announcement'] = 'Platform announcement';
    final auth = OnboardingTestAuth();
    await mount(tester, adapter, auth);
    expect(find.text('Application content'), findsOneWidget);
    expect(find.text('Platform announcement'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });

  testWidgets('maintenance hides application and recovers after retry', (
    tester,
  ) async {
    final adapter = _Adapter()
      ..status = {
        'mode': 'MAINTENANCE',
        'title': 'Scheduled maintenance',
        'message': 'Back soon',
      };
    final auth = OnboardingTestAuth();
    await mount(tester, adapter, auth);
    expect(find.text('Application content'), findsNothing);
    expect(find.text('Scheduled maintenance'), findsOneWidget);
    expect(find.text('Back soon'), findsOneWidget);
    adapter.status = {'mode': 'OPERATIONAL'};
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Application content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });

  testWidgets('suspension shows reason and recovers after access is restored', (
    tester,
  ) async {
    final adapter = _Adapter()
      ..accessError = {
        'code': 'ACCOUNT_SUSPENDED',
        'message': 'Review required',
      };
    final auth = OnboardingTestAuth()
      ..session = const AuthSession(accessToken: 'test');
    await mount(tester, adapter, auth);
    expect(find.text('Account suspended'), findsOneWidget);
    expect(find.text('Review required'), findsOneWidget);
    expect(find.text('Application content'), findsNothing);
    adapter.accessError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Application content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
  });
}
