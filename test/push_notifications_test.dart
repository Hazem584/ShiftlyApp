import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/notifications/domain/entities/notification_record.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_device_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit.dart';

const _user = '4f6c53d3-8518-44d8-813e-b915cc93d203';
const _workspace = 'c551356a-e456-4a3e-a49a-9dd0caa7e790';
const _notification = '5b6d92e6-7054-413f-ab26-bff810f2ff61';
const _scope = FeatureSessionScope(
  userId: _user,
  workspaceId: _workspace,
  membershipId: 'member',
  role: WorkspaceRole.employee,
  timezone: 'Africa/Cairo',
);
const _notice = PushNotice(
  notificationId: _notification,
  workspaceId: _workspace,
  recipientProfileId: _user,
);

class _Messaging implements PushMessaging {
  final foregroundController = StreamController<PushNotice>.broadcast(
    sync: true,
  );
  final openedController = StreamController<PushNotice>.broadcast(sync: true);
  final tokenController = StreamController<String>.broadcast(sync: true);
  PushPermission authorization = PushPermission.granted;
  PushNotice? initial;
  String tokenValue = 'private-fcm-token';
  Completer<String?>? pendingToken;
  int permissionRequests = 0;
  int revocations = 0;
  bool failRevoke = false;
  @override
  String get platform => 'ANDROID';
  @override
  Stream<PushNotice> get foreground => foregroundController.stream;
  @override
  Stream<PushNotice> get opened => openedController.stream;
  @override
  Stream<String> get tokenChanges => tokenController.stream;
  @override
  Future<PushPermission> initialize() async => authorization;
  @override
  Future<PushPermission> permission({bool request = false}) async {
    if (request) permissionRequests++;
    return authorization;
  }

  @override
  Future<PushNotice?> initialNotice() async => initial;
  @override
  Future<String?> token() async =>
      pendingToken == null ? tokenValue : pendingToken!.future;
  @override
  Future<void> revokeToken() async {
    revocations++;
    if (failRevoke) throw StateError('offline');
  }

  @override
  Future<void> close() async {
    await foregroundController.close();
    await openedController.close();
    await tokenController.close();
  }
}

class _Devices implements PushDeviceRepository {
  final tokens = <String>[];
  int revocations = 0;
  bool fail = false;
  @override
  Future<void> register({
    required String installationId,
    required String token,
    required String platform,
  }) async {
    if (fail) throw StateError('private-fcm-token provider detail');
    tokens.add(token);
  }

  @override
  Future<void> unregister(String installationId) async {
    revocations++;
    if (fail) throw StateError('offline');
  }

  @override
  Future<NotificationRecord> getNotification(String notificationId) =>
      throw UnimplementedError();
}

class _Preferences implements PushPreferenceStore {
  final values = <String, bool>{};
  @override
  Future<String> installationId() async => 'installation';
  @override
  Future<bool> enabled(String userId) async => values[userId] ?? false;
  @override
  Future<void> setEnabled(String userId, bool enabled) async {
    values[userId] = enabled;
  }
}

void main() {
  late _Messaging messaging;
  late _Devices devices;
  late _Preferences preferences;
  late PushNotificationsCubit cubit;
  late List<PushNotice> opened;
  late List<PushNotice> foreground;
  setUp(() {
    messaging = _Messaging();
    devices = _Devices();
    preferences = _Preferences();
    opened = [];
    foreground = [];
    cubit = PushNotificationsCubit(
      messaging,
      devices,
      preferences,
      onOpened: opened.add,
      onForeground: foreground.add,
    );
  });
  tearDown(() async {
    await cubit.close();
  });

  test('payload accepts only identifiers, ignores arbitrary routes and invalid data', () {
    expect(
      PushNotice.fromData({
        'notificationId': _notification,
        'workspaceId': _workspace,
        'recipientProfileId': _user,
        'route': 'https://untrusted.invalid',
      }),
      _notice,
    );
    expect(
      PushNotice.fromData({
        'notificationId': 'invalid',
        'workspaceId': _workspace,
        'recipientProfileId': _user,
      }),
      isNull,
    );
    expect(
      PushNotice.fromData({
        'notificationId': _notification,
        'workspaceId': _workspace,
      }),
      isNull,
    );
  });

  test('does not prompt or register before explicit opt-in', () async {
    cubit.bindSession(_scope);
    await cubit.refresh();
    expect(messaging.permissionRequests, 0);
    expect(devices.tokens, isEmpty);
    expect(cubit.state.enabled, isFalse);
    await cubit.setEnabled(true);
    expect(messaging.permissionRequests, 1);
    expect(devices.tokens, ['private-fcm-token']);
    expect(cubit.state.enabled, isTrue);
    expect(preferences.values[_user], isTrue);
  });

  test('denied permissions do not register a token', () async {
    messaging.authorization = PushPermission.denied;
    cubit.bindSession(_scope);
    await cubit.refresh();
    await cubit.setEnabled(true);
    expect(devices.tokens, isEmpty);
    expect(cubit.state.permission, PushPermission.denied);
  });

  test(
    'foreground and taps are scoped to the validated account/workspace',
    () async {
      cubit.bindSession(_scope);
      await cubit.refresh();
      await cubit.setEnabled(true);
      messaging.foregroundController.add(_notice);
      messaging.openedController.add(_notice);
      const other = PushNotice(
        notificationId: _notification,
        workspaceId: _workspace,
        recipientProfileId: 'other-user',
      );
      messaging.foregroundController.add(other);
      messaging.openedController.add(other);
      expect(foreground, [_notice]);
      expect(opened, [_notice]);
    },
  );

  test('cold-start tap waits for session restoration', () async {
    // FCM's initial callback can arrive before the authenticated workspace.
    await Future<void>.delayed(Duration.zero);
    messaging.openedController.add(_notice);
    expect(opened, isEmpty);
    cubit.bindSession(_scope);
    await cubit.refresh();
    expect(opened, [_notice]);
  });

  test('opt-out invalidates token even if API revocation is offline', () async {
    cubit.bindSession(_scope);
    await cubit.refresh();
    await cubit.setEnabled(true);
    final before = messaging.revocations;
    devices.fail = true;
    await cubit.setEnabled(false);
    expect(messaging.revocations, before + 1);
    expect(cubit.state.enabled, isFalse);
    expect(preferences.values[_user], isFalse);
  });

  test(
    'logout suppresses foreground notices and revokes the FCM token',
    () async {
      cubit.bindSession(_scope);
      await cubit.refresh();
      await cubit.setEnabled(true);
      final before = messaging.revocations;
      cubit.bindSession(null);
      cubit.discardPending();
      await Future<void>.delayed(Duration.zero);
      messaging.foregroundController.add(_notice);
      expect(foreground, isEmpty);
      expect(messaging.revocations, before + 1);
      expect(cubit.state.enabled, isFalse);
    },
  );

  test(
    'permission removal revokes existing registration without prompting',
    () async {
      cubit.bindSession(_scope);
      await cubit.refresh();
      await cubit.setEnabled(true);
      final before = messaging.revocations;
      messaging.authorization = PushPermission.denied;
      await cubit.refresh();
      expect(cubit.state.enabled, isFalse);
      expect(messaging.revocations, before + 1);
      expect(messaging.permissionRequests, 1);
    },
  );

  test('token refresh re-registers the current token', () async {
    cubit.bindSession(_scope);
    await cubit.refresh();
    await cubit.setEnabled(true);
    messaging.tokenValue = 'rotated-token';
    messaging.tokenController.add('rotated-token');
    await cubit.refresh();
    expect(devices.tokens.last, 'rotated-token');
  });

  test('late token retrieval cannot register after logout', () async {
    cubit.bindSession(_scope);
    await cubit.refresh();
    messaging.pendingToken = Completer<String?>();
    final enable = cubit.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    cubit.bindSession(null);
    messaging.pendingToken!.complete('old-token');
    await enable;
    expect(devices.tokens, isEmpty);
    expect(cubit.state.enabled, isFalse);
  });

  test('registration failure reports a safe recoverable message', () async {
    cubit.bindSession(_scope);
    await cubit.refresh();
    devices.fail = true;
    await cubit.setEnabled(true);
    expect(cubit.state.enabled, isFalse);
    expect(
      cubit.state.message,
      'Could not update mobile notifications. Try again.',
    );
    devices.fail = false;
    await cubit.refresh();
    expect(cubit.state.enabled, isTrue);
  });

  test('offline token revocation is retried after signed-out resume', () async {
    cubit.bindSession(_scope);
    await cubit.refresh();
    await cubit.setEnabled(true);
    messaging.failRevoke = true;
    cubit.bindSession(null);
    cubit.signedOut();
    await Future<void>.delayed(Duration.zero);
    final before = messaging.revocations;
    messaging.failRevoke = false;
    await cubit.refresh();
    expect(messaging.revocations, greaterThan(before));
    expect(cubit.state.enabled, isFalse);
  });
}
