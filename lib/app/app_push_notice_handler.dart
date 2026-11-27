import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/app/app_composition.dart';
import 'package:shiftly/app/app_push_notice_opener.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
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
    final c = composition();
    unawaited(c.notificationsCubit.load(refresh: true));
    c.dashboardCubit.invalidate();
    final scope = c.notificationsCubit.scope;
    if (scope == null || c.pushDevices == null) return;
    String? content;
    try {
      final record = await c.pushDevices!.getNotification(
        notice.notificationId,
      );
      if (!isMounted() ||
          c.notificationsCubit.scope != scope ||
          (record.workspaceId != scope.workspaceId &&
              !(record.type == NotificationType.taskReminder &&
                  record.data?['taskId'] == notice.taskId)) ||
          record.id != notice.notificationId) {
        return;
      }
      content = '${record.title}\n${record.message}';
    } catch (_) {
      return;
    }
    final context = c.router.routerDelegate.navigatorKey.currentState?.overlay
        ?.context;
    if (!isMounted() || context == null || !context.mounted) return;
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(content),
        action: SnackBarAction(
          label: context.tr('View'),
          onPressed: () => unawaited(openPushNotice(notice)),
        ),
      ),
    );
  }

  Future<void> openPushNotice(PushNotice notice) => openAppPushNotice(
    composition: composition(),
    messengerKey: messengerKey,
    isMounted: isMounted,
    notice: notice,
  );
}
