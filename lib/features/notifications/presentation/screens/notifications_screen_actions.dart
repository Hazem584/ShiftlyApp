import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/screens/delete_notification_dialog.dart';
import 'package:shiftly/features/notifications/presentation/utils/notifications_formatters.dart';

Future<void> openNotificationItem(
  BuildContext context,
  NotificationRecord notification,
) async {
  final cubit = context.read<NotificationsCubit>();
  if (notification.isUnread) {
    final result = await cubit.markRead(notification.id);
    if (!context.mounted || result == NotificationMutationResult.stale) return;
    if (result == NotificationMutationResult.failure) {
      final msg =
          cubit.state.failure?.message ?? 'Unable to open the notification.';
      ToastService.error(context, message: msg);
      return;
    }
    if (result == NotificationMutationResult.busy) return;
  }
  if (!context.mounted) return;
  await NotificationsScreenNotificationNavigator.open(
    context,
    cubit.scope,
    notification,
  );
}

Future<void> markAllNotificationsRead(BuildContext context) async {
  final cubit = context.read<NotificationsCubit>();
  final result = await cubit.markAllRead();
  if (!context.mounted || result == NotificationMutationResult.stale) return;
  if (result == NotificationMutationResult.success) {
    ToastService.success(context, message: 'All notifications marked read');
  } else if (result == NotificationMutationResult.failure) {
    final msg =
        cubit.state.failure?.message ??
        'Unable to mark all notifications as read.';
    ToastService.error(context, message: msg);
  }
}

Future<void> confirmAndDeleteNotification(
  BuildContext context,
  NotificationRecord notification,
) async {
  final confirmed = await showDeleteNotificationDialog(context);
  if (confirmed != true || !context.mounted) return;
  final cubit = context.read<NotificationsCubit>();
  final result = await cubit.delete(notification.id);
  if (!context.mounted || result == NotificationMutationResult.stale) return;
  if (result == NotificationMutationResult.success) {
    ToastService.success(context, message: 'Notification deleted');
  } else if (result == NotificationMutationResult.failure) {
    final msg =
        cubit.state.failure?.message ?? 'Unable to delete the notification.';
    ToastService.error(context, message: msg);
  }
}
