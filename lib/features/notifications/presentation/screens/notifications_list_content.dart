import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:shiftly/features/notifications/presentation/screens/notifications_list_header.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_card.dart';

class NotificationsListContent extends StatelessWidget {
  const NotificationsListContent({
    required this.state,
    required this.unreadOnly,
    required this.onUnreadFilterChanged,
    required this.onOpen,
    required this.onDelete,
    super.key,
  });

  final NotificationsState state;
  final bool unreadOnly;
  final ValueChanged<bool> onUnreadFilterChanged;
  final ValueChanged<NotificationRecord> onOpen, onDelete;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();
    final items = state.notifications.where((n) => !unreadOnly || n.isUnread);
    return RefreshIndicator(
      onRefresh: () => cubit.load(refresh: true),
      child: ListView(
        key: const Key('notifications-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          NotificationsListHeader(
            state: state,
            unreadOnly: unreadOnly,
            onUnreadFilterChanged: onUnreadFilterChanged,
          ),
          if (state.notifications.isEmpty)
            EmptyState(
              icon: Icons.notifications_none_rounded,
              title: context.tr('No notifications'),
              message:
                  'Workspace updates will appear here. Pull down to refresh.',
            )
          else
            for (final item in items) ...[
              NotificationCard(
                notification: item,
                timezone: cubit.scope?.timezone ?? 'Etc/UTC',
                mutating:
                    state.markingIds.contains(item.id) ||
                    state.deletingIds.contains(item.id),
                onOpen: () => onOpen(item),
                onDelete: () => onDelete(item),
              ),
              const SizedBox(height: 10),
            ],
          if (state.hasMore)
            OutlinedButton(
              onPressed: state.loadingMore ? null : cubit.loadMore,
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
  }
}
