import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shiftly/app/app_composition.dart';
import 'package:shiftly/app/app_push_notice_opener.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

class AppPushNoticeHandler {
  const AppPushNoticeHandler({
    required this.composition,
    required this.messengerKey,
    required this.isMounted,
  });

  final AppComposition Function() composition;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final bool Function() isMounted;

  Future<void> showPushNotice(PushNotice notice) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final app = composition();
    final scope = app.tasksCubit.scope;
    final devices = app.pushDevices;
    if (scope == null ||
        devices == null ||
        scope.userId != notice.recipientProfileId) {
      return;
    }
    try {
      final row = await devices.getNotification(notice.notificationId);
      if (!isMounted() ||
          app.tasksCubit.scope != scope ||
          row.id != notice.notificationId ||
          row.workspaceId != notice.workspaceId ||
          (row.type != NotificationType.chatMessage &&
              row.type != NotificationType.taskReminder)) {
        return;
      }
      final kind = row.data?['kind'];
      final assigned =
          kind == 'TEAM_TASK_ASSIGNED' || kind == 'TEAM_TASK_REMINDER';
      if ((row.type == NotificationType.chatMessage || assigned) &&
          row.workspaceId != scope.workspaceId) {
        return;
      }
      await FlutterLocalNotificationsPlugin().show(
        id: notice.notificationId.hashCode & 0x3fffffff,
        title: row.title,
        body: row.message,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'shiftly_updates',
            'Shiftly updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode({
          'kind': 'foreground-push',
          'notificationId': notice.notificationId,
          'workspaceId': notice.workspaceId,
          'recipientProfileId': notice.recipientProfileId,
          'taskId': notice.taskId,
        }),
      );
    } catch (_) {
      // A stale message or a disabled OS channel may prevent presentation.
    }
  }

  Future<void> openPushNotice(PushNotice notice) => openAppPushNotice(
    composition: composition(),
    messengerKey: messengerKey,
    isMounted: isMounted,
    notice: notice,
  );
}
