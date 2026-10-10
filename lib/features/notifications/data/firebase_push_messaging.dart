import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
      .map((message) => PushNotice.fromData(message.data))
      .where((notice) => notice != null)
      .cast<PushNotice>();

  @override
  Stream<PushNotice> get opened => FirebaseMessaging.onMessageOpenedApp
      .map((message) => PushNotice.fromData(message.data))
      .where((notice) => notice != null)
      .cast<PushNotice>();

  @override
  Stream<String> get tokenChanges =>
      _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Future<PushPermission> initialize() async {
    if (!_supported) return PushPermission.unsupported;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _ready = true;
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      // Foreground notices are shown inside Shiftly, avoiding duplicate alerts.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      return await permission();
    } catch (_) {
      _ready = false;
      return PushPermission.unavailable;
    }
  }

  @override
  Future<PushPermission> permission({bool request = false}) async {
    if (!_ready) {
      return _supported
          ? PushPermission.unavailable
          : PushPermission.unsupported;
    }
    final settings = request
        ? await FirebaseMessaging.instance.requestPermission()
        : await FirebaseMessaging.instance.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => PushPermission.granted,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => PushPermission.denied,
      AuthorizationStatus.notDetermined => PushPermission.notDetermined,
    };
  }

  @override
  Future<PushNotice?> initialNotice() async {
    if (!_ready) return null;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : PushNotice.fromData(message.data);
  }

  @override
  Future<String?> token() async {
    if (!_ready) return null;
    if (platform == 'IOS' &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      return null;
    }
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> revokeToken() async {
    if (!_ready) return;
    await FirebaseMessaging.instance.setAutoInitEnabled(false);
    await FirebaseMessaging.instance.deleteToken();
  }

  @override
  Future<void> close() async {}
}
