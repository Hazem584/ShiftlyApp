import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
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
      color: notification.isUnread
          ? AppPalette.of(context).selected
          : AppPalette.of(context).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.l),
        side: BorderSide(color: AppPalette.of(context).borderColor),
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
                            context.tr(notification.title),
                            style: TextStyle(
                              fontWeight: notification.isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (notification.isUnread)
                          DecoratedBox(
                            key: Key('unread-indicator'),
                            decoration: BoxDecoration(
                              color: AppPalette.of(context).orange,
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('{value1} · {value2}', {
                        'value1': context.tr(presentation.label),
                        'value2': (WorkspaceTime.dateTime(
                          notification.createdAt,
                          timezone,
                          locale: Localizations.localeOf(context).toString(),
                        )).toString(),
                      }),
                      style: TextStyle(
                        color: AppPalette.of(context).lighterGray,
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
