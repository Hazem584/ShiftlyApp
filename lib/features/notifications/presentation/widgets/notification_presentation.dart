import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';

({String label, IconData icon, Color color}) notificationPresentation(
  NotificationType type,
) => switch (type) {
  NotificationType.attendanceClockedIn => (
    label: 'Clock-in',
    icon: Icons.login_rounded,
    color: AppColors.success,
  ),
  NotificationType.attendanceClockedOut => (
    label: 'Clock-out',
    icon: Icons.logout_rounded,
    color: AppColors.info,
  ),
  NotificationType.leaveRequestCreated => (
    label: 'Leave request',
    icon: Icons.event_note_outlined,
    color: AppColors.orange,
  ),
  NotificationType.leaveRequestApproved => (
    label: 'Leave approved',
    icon: Icons.event_available_outlined,
    color: AppColors.success,
  ),
  NotificationType.leaveRequestRejected => (
    label: 'Leave rejected',
    icon: Icons.event_busy_outlined,
    color: AppColors.error,
  ),
  NotificationType.shiftAssigned => (
    label: 'Shift assigned',
    icon: Icons.calendar_month_outlined,
    color: AppColors.info,
  ),
  NotificationType.shiftUpdated => (
    label: 'Shift updated',
    icon: Icons.edit_calendar_outlined,
    color: AppColors.orange,
  ),
  NotificationType.shiftCancelled => (
    label: 'Shift cancelled',
    icon: Icons.event_busy_outlined,
    color: AppColors.error,
  ),
  NotificationType.unknown => (
    label: 'Notification',
    icon: Icons.notifications_none_rounded,
    color: AppColors.textSecondary,
  ),
  NotificationType.shiftReminder => (
    label: 'Upcoming shift',
    icon: Icons.alarm_rounded,
    color: AppColors.orange,
  ),
  NotificationType.chatMessage => (
    label: 'New chat message',
    icon: Icons.chat_bubble_outline_rounded,
    color: AppColors.info,
  ),
};
