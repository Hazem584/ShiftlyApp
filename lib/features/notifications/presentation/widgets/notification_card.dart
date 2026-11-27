import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_card_body.dart';
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
                child: NotificationCardBody(
                  notification: notification,
                  timezone: timezone,
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
