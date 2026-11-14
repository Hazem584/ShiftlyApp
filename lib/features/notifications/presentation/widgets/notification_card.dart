import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/utils/notification_display_text.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_presentation.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.timezone,
    required this.mutating,
    required this.onOpen,
    required this.onDelete,
  });

  final NotificationRecord notification;
  final String timezone;
  final bool mutating;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final presentation = notificationPresentation(notification.type);
    return Material(
      key: Key('notification-${notification.id}'),
      color: AppPalette.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: mutating ? null : onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                presentation.icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(notification.title),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          DecoratedBox(
                            key: Key('unread-indicator'),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(dimension: 8),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notificationDisplayMessage(
                        context,
                        notification.type,
                        notification.message,
                      ),
                      style: TextStyle(
                        color: AppPalette.of(context).textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('{value1} · {value2}', {
                        'value1': context.tr(
                          notification.isUnread ? 'Unread' : 'Read',
                        ),
                        'value2': (WorkspaceTime.dateTime(
                          notification.createdAt,
                          timezone,
                          locale: Localizations.localeOf(context).toString(),
                        )).toString(),
                      }),
                      style: TextStyle(
                        color: AppPalette.of(context).textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('delete-${notification.id}'),
                onPressed: mutating ? null : onDelete,
                tooltip: context.tr('Delete notification'),
                icon: mutating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
