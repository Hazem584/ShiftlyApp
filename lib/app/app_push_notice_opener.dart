import 'package:flutter/material.dart';
import 'package:shiftly/app/app_composition.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:shiftly/features/notifications/presentation/utils/notifications_formatters.dart';

Future<void> openAppPushNotice({
  required AppComposition composition,
  required GlobalKey<ScaffoldMessengerState> messengerKey,
  required bool Function() isMounted,
  required PushNotice notice,
}) async {
  if (notice.taskId != null) {
    await _openTaskNotice(composition, isMounted, notice);
    return;
  }
  final scope = composition.notificationsCubit.scope;
  if (!isMounted() ||
      scope == null ||
      notice.recipientProfileId != scope.userId ||
      notice.workspaceId != scope.workspaceId) {
    return;
  }
  BuildContext? overlayContext() => composition
      .router
      .routerDelegate
      .navigatorKey
      .currentState
      ?.overlay
      ?.context;
  try {
    final record = await composition.pushDevices!.getNotification(
      notice.notificationId,
    );
    if (!isMounted() ||
        composition.notificationsCubit.scope != scope ||
        record.id != notice.notificationId ||
        record.workspaceId != scope.workspaceId) {
      return;
    }
    if (record.isUnread) {
      final result = await composition.notificationsCubit.markRead(record.id);
      if (result != NotificationMutationResult.success) return;
    }
    final context = overlayContext();
    if (!isMounted() ||
        context == null ||
        !context.mounted ||
        composition.notificationsCubit.scope != scope) {
      return;
    }
    if (record.type == NotificationType.unknown) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
      return;
    }
    await NotificationsScreenNotificationNavigator.open(context, scope, record);
  } catch (_) {
    final context = overlayContext();
    if (!isMounted() ||
        composition.notificationsCubit.scope != scope ||
        context == null ||
        !context.mounted) {
      return;
    }
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          context.tr('This notification destination is no longer available.'),
        ),
      ),
    );
  }
}

Future<void> _openTaskNotice(
  AppComposition c,
  bool Function() isMounted,
  PushNotice notice,
) async {
  final scope = c.tasksCubit.scope;
  if (scope == null ||
      scope.userId != notice.recipientProfileId ||
      c.pushDevices == null) {
    return;
  }
  try {
    final record = await c.pushDevices!.getNotification(notice.notificationId);
    if (record.type != NotificationType.taskReminder ||
        record.data?['taskId'] != notice.taskId ||
        record.workspaceId != notice.workspaceId) {
      return;
    }
    final task = await c.tasksCubit.resolveTap(scope.userId, notice.taskId!);
    if (task != null && isMounted() && c.tasksCubit.scope == scope) {
      c.router.push('/tasks?taskId=${task.id}');
    }
  } catch (_) {}
}
