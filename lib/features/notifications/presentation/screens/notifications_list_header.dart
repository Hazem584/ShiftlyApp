import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/notifications/presentation/cubit/notifications_cubit.dart';

class NotificationsListHeader extends StatelessWidget {
  const NotificationsListHeader({
    required this.state,
    required this.unreadOnly,
    required this.onUnreadFilterChanged,
    super.key,
  });

  final NotificationsState state;
  final bool unreadOnly;
  final ValueChanged<bool> onUnreadFilterChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr('Your workspace activity'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            key: const Key('notifications-unread-filter'),
            label: Text(
              context.tr('Unread {count}', {'count': '${state.unreadCount}'}),
            ),
            selected: unreadOnly,
            onSelected: (_) => onUnreadFilterChanged(true),
          ),
          ChoiceChip(
            label: Text(context.tr('All')),
            selected: !unreadOnly,
            onSelected: (_) => onUnreadFilterChanged(false),
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (state.failure != null) ...[
        Text(
          state.failure!.message,
          style: TextStyle(color: AppPalette.of(context).error),
        ),
        const SizedBox(height: AppSpacing.s),
      ],
      if (unreadOnly &&
          state.notifications.isNotEmpty &&
          !state.notifications.any((n) => n.isUnread))
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.tr(
              state.hasMore
                  ? 'Load more to see earlier notifications.'
                  : 'You’re all caught up.',
            ),
          ),
        ),
    ],
  );
}
