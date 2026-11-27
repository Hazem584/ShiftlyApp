import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

Future<bool> scheduleDeviceBreak(
  FlutterLocalNotificationsPlugin plugin,
  DateTime end, {
  required bool arabic,
  required bool start,
}) async {
  final android = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  var exact = true;
  if (android != null) {
    if (await android.requestNotificationsPermission() != true) return false;
    exact = await android.canScheduleExactNotifications() == true;
  } else {
    final ios = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (await ios?.requestPermissions(alert: true, sound: true, badge: false) !=
        true) {
      return false;
    }
  }
  await plugin.zonedSchedule(
    id: start ? 1600000002 : 1600000001,
    title: start
        ? (arabic ? 'ميعاد البريك' : 'Time for your break')
        : (arabic ? 'البريك خلص' : 'Your break is over'),
    body: start
        ? (arabic
              ? 'ابدأ البريك من التطبيق لما توقف شغل.'
              : 'Start your break in the app when you stop working.')
        : arabic
        ? 'وقت البريك انتهى، ارجع كمّل الشيفت.'
        : 'Your break has ended. Time to return to work.',
    scheduledDate: tz.TZDateTime.from(end, tz.UTC),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'shiftly_breaks',
        'Break reminders',
        channelDescription: 'Local shift break timer',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    ),
    androidScheduleMode: exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
    payload: '{"kind":"shift-break"}',
  );
  return true;
}
