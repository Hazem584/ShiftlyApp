import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shiftly/features/notifications/data/task_push_notifications.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/tasks/data/task_notification_actions.dart';

Future<void> setupFirebasePushInstance() async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  await TaskNotificationSetup.initialize(FlutterLocalNotificationsPlugin());
  FirebaseMessaging.onBackgroundMessage(taskPushBackground);
  await FirebaseMessaging.instance.setAutoInitEnabled(false);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: false,
    sound: true,
  );
}

Future<PushPermission> resolveFirebasePushPermission({
  required bool ready,
  required bool supported,
  required bool request,
}) async {
  if (!ready) {
    return supported ? PushPermission.unavailable : PushPermission.unsupported;
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

Future<String?> fetchFirebasePushToken({
  required bool ready,
  required bool ios,
}) async {
  if (!ready) return null;
  if (ios && await FirebaseMessaging.instance.getAPNSToken() == null) {
    return null;
  }
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  return FirebaseMessaging.instance.getToken();
}

Future<void> revokeFirebasePushToken({required bool ready}) async {
  if (!ready) return;
  await FirebaseMessaging.instance.setAutoInitEnabled(false);
  await FirebaseMessaging.instance.deleteToken();
}
