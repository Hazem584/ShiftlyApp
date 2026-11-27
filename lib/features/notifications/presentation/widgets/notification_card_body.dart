import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/utils/notification_display_text.dart';

class NotificationCardBody extends StatelessWidget {
  const NotificationCardBody({
    required this.notification,
    required this.timezone,
    super.key,
  });

  final NotificationRecord notification;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = AppPalette.of(context).textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(notification.title),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (notification.isUnread)
              DecoratedBox(
                key: const Key('unread-indicator'),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 8),
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
          style: TextStyle(color: secondaryColor, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('{value1} · {value2}', {
            'value1': context.tr(notification.isUnread ? 'Unread' : 'Read'),
            'value2': WorkspaceTime.dateTime(
              notification.createdAt,
              timezone,
              locale: Localizations.localeOf(context).toString(),
            ),
          }),
          style: TextStyle(color: secondaryColor, fontSize: 11),
        ),
      ],
    );
  }
}
