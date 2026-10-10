import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/utils/notifications_formatters.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_card.dart';
import 'package:shiftly/features/notifications/presentation/widgets/push_notification_settings.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationsCubit>().load(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Notifications')),
      actions: [
        BlocBuilder<NotificationsCubit, NotificationsState>(
          buildWhen: (previous, current) =>
              previous.unreadCount != current.unreadCount ||
              previous.markingAll != current.markingAll,
          builder: (context, state) => TextButton(
            key: const Key('mark-all-notifications-read'),
            onPressed: state.unreadCount == 0 || state.markingAll
                ? null
                : _markAll,
            child: state.markingAll
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('Mark all read')),
          ),
        ),
      ],
    ),
    body: BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        if (state.initialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.notifications.isEmpty && state.failure != null) {
          return EmptyState(
            icon: Icons.cloud_off_outlined,
            title: context.tr('Could not load notifications'),
            message: state.failure!.message,
            action: FilledButton(
              onPressed: context.read<NotificationsCubit>().load,
              child: Text(context.tr('Retry')),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              context.read<NotificationsCubit>().load(refresh: true),
          child: ListView(
            key: const Key('notifications-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              const PushNotificationSettings(),
              if (state.failure != null) ...[
                Text(
                  state.failure!.message,
                  style: TextStyle(color: AppPalette.of(context).error),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              if (state.notifications.isEmpty)
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: context.tr('No notifications'),
                  message: 'Workspace updates will appear here. Pull down to refresh.',
                )
              else
                for (final notification in state.notifications) ...[
                  NotificationCard(
                    notification: notification,
                    timezone:
                        context.read<NotificationsCubit>().scope?.timezone ??
                        'Etc/UTC',
                    mutating:
                        state.markingIds.contains(notification.id) ||
                        state.deletingIds.contains(notification.id),
                    onOpen: () => _open(notification),
                    onDelete: () => _delete(notification),
                  ),
                  const SizedBox(height: 10),
                ],
              if (state.hasMore)
                OutlinedButton(
                  onPressed: state.loadingMore
                      ? null
                      : context.read<NotificationsCubit>().loadMore,
                  child: state.loadingMore
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('Load more')),
                ),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _open(NotificationRecord notification) async {
    final cubit = context.read<NotificationsCubit>();
    if (notification.isUnread) {
      final result = await cubit.markRead(notification.id);
      if (!mounted || result == NotificationMutationResult.stale) return;
      if (result == NotificationMutationResult.failure) {
        ToastService.error(
          context,
          message:
              cubit.state.failure?.message ??
              'Unable to open the notification.',
        );
        return;
      }
      if (result == NotificationMutationResult.busy) return;
    }
    if (!mounted) return;
    await NotificationsScreenNotificationNavigator.open(
      context,
      cubit.scope,
      notification,
    );
  }

  Future<void> _markAll() async {
    final cubit = context.read<NotificationsCubit>();
    final result = await cubit.markAllRead();
    if (!mounted || result == NotificationMutationResult.stale) return;
    if (result == NotificationMutationResult.success) {
      ToastService.success(context, message: 'All notifications marked read');
    } else if (result == NotificationMutationResult.failure) {
      ToastService.error(
        context,
        message:
            cubit.state.failure?.message ??
            'Unable to mark all notifications as read.',
      );
    }
  }

  Future<void> _delete(NotificationRecord notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete notification?')),
        content: Text(
          context.tr('This notification will be permanently removed.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            key: const Key('confirm-delete-notification'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final cubit = context.read<NotificationsCubit>();
    final result = await cubit.delete(notification.id);
    if (!mounted || result == NotificationMutationResult.stale) return;
    if (result == NotificationMutationResult.success) {
      ToastService.success(context, message: 'Notification deleted');
    } else if (result == NotificationMutationResult.failure) {
      ToastService.error(
        context,
        message:
            cubit.state.failure?.message ??
            'Unable to delete the notification.',
      );
    }
  }
}
