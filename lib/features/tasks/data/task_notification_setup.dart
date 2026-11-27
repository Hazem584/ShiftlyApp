import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'task_notification_actions.dart';

@pragma('vm:entry-point')
void taskNotificationActionBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    await snoozeTaskNotification(response);
  } catch (_) {
    /* OS may reject an alarm. */
  }
}

class TaskNotificationSetup {
  static void Function(NotificationResponse)? _onTap;
  static Future<void> initialize(
    FlutterLocalNotificationsPlugin plugin, {
    void Function(NotificationResponse)? onTap,
  }) async {
    if (onTap != null) _onTap = onTap;
    final prefs = await SharedPreferences.getInstance();
    final arabic =
        (prefs.getString('app.language') ??
            PlatformDispatcher.instance.locale.languageCode) ==
        'ar';
    tzdata.initializeTimeZones();
    await plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              taskNotificationCategory,
              actions: [
                DarwinNotificationAction.plain(
                  taskSnoozeAction,
                  arabic ? 'ذكّرني بعد 10 دقائق' : 'Remind me in 10 minutes',
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == taskSnoozeAction) {
          snoozeTaskNotification(response).catchError((Object _) => false);
        } else {
          _onTap?.call(response);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          taskNotificationActionBackground,
    );
  }
}
