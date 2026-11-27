import 'package:flutter/material.dart';
import 'package:shiftly/app/app_composition.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/utils/notifications_formatters.dart';

Future<void> openAppPushNotice({
  required AppComposition composition,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
  required bool Function() isMounted,
  required PushNotice notice,
}) async {
  final scope = composition.tasksCubit.scope;
  final devices = composition.pushDevices;
  if (scope == null ||
      devices == null ||
      scope.userId != notice.recipientProfileId) {
    return;
  }
  bool current() => isMounted() && composition.tasksCubit.scope == scope;
  try {
    final record = await devices.getNotification(notice.notificationId);
    if (!current() ||
        record.id != notice.notificationId ||
        record.workspaceId != notice.workspaceId) {
      return;
    }
    if (record.type == NotificationType.taskReminder &&
        notice.taskId != null &&
        record.data?['taskId'] == notice.taskId) {
      final kind = record.data?['kind'];
      if (kind == 'TEAM_TASK_ASSIGNED' || kind == 'TEAM_TASK_REMINDER') {
        if (scope.workspaceId == notice.workspaceId) {
          composition.router.push('/assigned-tasks?taskId=${notice.taskId}');
        }
      } else {
        final task = await composition.tasksCubit.resolveTap(
          scope.userId,
          notice.taskId!,
        );
        if (current() && task != null) {
          composition.router.push('/tasks?taskId=${task.id}');
        }
      }
      return;
    }
    if (record.type != NotificationType.chatMessage ||
        scope.workspaceId != notice.workspaceId) {
      return;
    }
    final context = composition
        .router
        .routerDelegate
        .navigatorKey
        .currentState
        ?.overlay
        ?.context;
    if (context == null || !context.mounted) return;
    await NotificationsScreenNotificationNavigator.open(context, scope, record);
  } catch (_) {
    final context = messengerKey.currentContext;
    if (current() && context != null && context.mounted) {
      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            context.tr('This notification destination is no longer available.'),
          ),
        ),
      );
    }
  }
}
