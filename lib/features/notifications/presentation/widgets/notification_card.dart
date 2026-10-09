import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
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
      color: notification.isUnread ? AppColors.selected : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.l),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      child: InkWell(
        onTap: mutating ? null : onOpen,
        borderRadius: BorderRadius.circular(AppRadii.l),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: presentation.color.withValues(alpha: .12),
                foregroundColor: presentation.color,
                child: Icon(presentation.icon, size: 20),
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
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          const DecoratedBox(
                            key: Key('unread-indicator'),
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(dimension: 8),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${presentation.label} · ${WorkspaceTime.dateTime(notification.createdAt, timezone, locale: Localizations.localeOf(context).toString())}',
                      style: const TextStyle(
                        color: AppColors.lighterGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('delete-${notification.id}'),
                onPressed: mutating ? null : onDelete,
                tooltip: 'Delete notification',
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
