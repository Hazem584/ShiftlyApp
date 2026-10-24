import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';
import 'package:shiftly/features/device_sessions/presentation/device_sessions_screen.dart';

DeviceSession device(String id, {bool current = false, bool first = false}) =>
    DeviceSession(
      id: id,
      deviceName: id == 'remote' ? 'Samsung Galaxy' : 'Chrome on Windows',
      platform: 'android',
      osVersion: 'Android 16',
      appVersion: '1.1.0+2',
      createdAt: DateTime.utc(2026, 10, 20),
      lastSeenAt: DateTime.utc(2026, 10, 24),
      isCurrent: current,
      isFirst: first,
    );

class _Repository implements DeviceSessionsRepository {
  List<DeviceSession> items = [
    device('remote', first: true),
    device('current', current: true),
  ];
  final revoked = <String>[];
  int all = 0;
  bool failMutation = false;
  @override
  Future<void> registerCurrent() async {}
  @override
  Future<DeviceSessionsPage> load({int page = 1}) async =>
      DeviceSessionsPage([...items], hasNext: false);
  @override
  Future<bool> revoke(String id) async {
    if (failMutation) {
      throw const ApiException(
        message: 'Could not connect.',
        kind: FailureKind.network,
      );
    }
    revoked.add(id);
    final current = items.firstWhere((item) => item.id == id).isCurrent;
    items.removeWhere((item) => item.id == id);
    return current;
  }

  @override
  Future<void> revokeAll() async {
    if (failMutation) {
      throw const ApiException(
        message: 'Could not connect.',
        kind: FailureKind.network,
      );
    }
    all++;
    items.clear();
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    _Repository repository,
    Future<void> Function() signOut,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceSessionsScreen(
          repository: repository,
          onCurrentSessionRevoked: signOut,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows earliest and current devices with their session details', (
    tester,
  ) async {
    await mount(tester, _Repository(), () async {});
    expect(find.text('Samsung Galaxy'), findsOneWidget);
    expect(find.text('Chrome on Windows'), findsOneWidget);
    expect(find.text('This device'), findsOneWidget);
    expect(find.text('Earliest active sign-in'), findsOneWidget);
  });
  testWidgets('signing out one remote device leaves this device signed in', (
    tester,
  ) async {
    final repository = _Repository();
    var signOuts = 0;
    await mount(tester, repository, () async {
      signOuts++;
    });
    await tester.ensureVisible(find.byKey(const ValueKey('revoke-remote')));
    await tester.tap(find.byKey(const ValueKey('revoke-remote')));
    await confirm(tester);
    expect(repository.revoked, ['remote']);
    expect(signOuts, 0);
    expect(find.text('Samsung Galaxy'), findsNothing);
    expect(find.text('Chrome on Windows'), findsOneWidget);
  });
  testWidgets(
    'sign out all includes this device and clears its local session only after success',
    (tester) async {
      final repository = _Repository();
      var signOuts = 0;
      await mount(tester, repository, () async {
        signOuts++;
      });
      await tester.tap(find.byKey(const Key('logout-all-devices')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'All devices, including this one, will need to sign in again.',
        ),
        findsOneWidget,
      );
      await confirm(tester);
      expect(repository.all, 1);
      expect(signOuts, 1);
    },
  );
  testWidgets('cancelling logout does not change any session', (tester) async {
    final repository = _Repository();
    await mount(tester, repository, () async {});
    await tester.tap(find.byKey(const Key('logout-all-devices')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.all, 0);
    expect(repository.items, hasLength(2));
  });
  testWidgets(
    'network failure while logging out all devices preserves this session and shows a retry',
    (tester) async {
      final repository = _Repository()..failMutation = true;
      var signOuts = 0;
      await mount(tester, repository, () async {
        signOuts++;
      });
      await tester.tap(find.byKey(const Key('logout-all-devices')));
      await confirm(tester);
      expect(signOuts, 0);
      expect(find.text('Could not connect.'), findsOneWidget);
      expect(repository.items, hasLength(2));
    },
  );
}
