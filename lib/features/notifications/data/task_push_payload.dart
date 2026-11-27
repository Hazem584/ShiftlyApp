import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/tasks/data/task_notification_actions.dart';

bool isTaskPushEligible(SharedPreferences prefs, PushNotice notice) =>
    prefs.getString(taskNotificationOwnerKey) == notice.recipientProfileId &&
    prefs.getBool(
          'tasks.notification.cancelled.${notice.recipientProfileId}.${notice.taskId}',
        ) !=
        true;

bool isTaskPushArabic(SharedPreferences prefs) =>
    (prefs.getString('app.language') ??
        PlatformDispatcher.instance.locale.languageCode) ==
    'ar';

String encodeTaskPushPayload(
  PushNotice notice,
  Map<String, dynamic> data, {
  required bool arabic,
}) => jsonEncode({
  'kind': 'personal-task',
  'ownerId': notice.recipientProfileId,
  'taskId': notice.taskId,
  'workspaceId': notice.workspaceId,
  if (int.tryParse(data['taskRevision']?.toString() ?? '')
      case final int revision)
    'revision': revision,
  'title': data['title'],
  'body': data['body'],
  'arabic': arabic,
});
