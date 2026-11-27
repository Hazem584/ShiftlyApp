import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shiftly/features/notifications/data/firebase_push_helpers.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';

class FirebasePushMessaging implements PushMessaging {
  bool _ready = false;
  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID';

  @override
  Stream<PushNotice> get foreground => FirebaseMessaging.onMessage
      .map((m) => PushNotice.fromData(m.data))
      .where((n) => n != null)
      .cast<PushNotice>();

  @override
  Stream<PushNotice> get opened => FirebaseMessaging.onMessageOpenedApp
      .map((m) => PushNotice.fromData(m.data))
      .where((n) => n != null)
      .cast<PushNotice>();

  @override
  Stream<String> get tokenChanges =>
      _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Future<PushPermission> initialize() async {
    if (!_supported) return PushPermission.unsupported;
    try {
      await setupFirebasePushInstance();
      _ready = true;
      return await permission();
    } catch (_) {
      _ready = false;
      return PushPermission.unavailable;
    }
  }

  @override
  Future<PushPermission> permission({bool request = false}) =>
      resolveFirebasePushPermission(
        ready: _ready,
        supported: _supported,
        request: request,
      );

  @override
  Future<PushNotice?> initialNotice() async {
    if (!_ready) return null;
    final msg = await FirebaseMessaging.instance.getInitialMessage();
    return msg == null ? null : PushNotice.fromData(msg.data);
  }

  @override
  Future<String?> token() => fetchFirebasePushToken(ready: _ready, ios: platform == 'IOS');

  @override
  Future<void> revokeToken() => revokeFirebasePushToken(ready: _ready);

  @override
  Future<void> close() async {}
}
