import 'package:flutter/widgets.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

/// Translate known server notification templates without translating names or
/// replacing a message whose content differs from the known template.
String notificationDisplayMessage(
  BuildContext context,
  NotificationType type,
  String message,
) {
  final template = switch (type) {
    NotificationType.attendanceClockedIn => '{name} has clocked in.',
    NotificationType.attendanceClockedOut => '{name} has clocked out.',
    NotificationType.leaveRequestCreated => '{name} submitted a leave request.',
    _ => null,
  };
  if (template != null) {
    final suffix = template.substring('{name}'.length);
    if (message.endsWith(suffix) && message.length > suffix.length) {
      return context.tr(template, {
        'name': message.substring(0, message.length - suffix.length),
      });
    }
  }
  return context.tr(message);
}
