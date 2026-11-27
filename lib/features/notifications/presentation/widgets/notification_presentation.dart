import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/notifications/domain/repositories/notification_repository.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_shift_presentation.dart';

({String label, IconData icon, Color color}) notificationPresentation(
  NotificationType type,
) => switch (type) {
  NotificationType.supportReply => (
    label: 'Support report reply',
    icon: Icons.support_agent_outlined,
    color: AppColors.info,
  ),
  NotificationType.taskReminder => (
    label: 'Task reminder',
    icon: Icons.checklist_rounded,
    color: AppColors.info,
  ),
  NotificationType.fixedShiftReminder => (
    label: 'Upcoming fixed shift',
    icon: Icons.alarm,
    color: AppColors.orange,
  ),
  NotificationType.clockOutReminder => (
    label: 'Remember to clock out',
    icon: Icons.logout,
    color: AppColors.orange,
  ),
  NotificationType.teamAnnouncement => (
    label: 'Team announcement',
    icon: Icons.campaign_outlined,
    color: AppColors.info,
  ),
  NotificationType.attendanceCorrectionCreated ||
  NotificationType.attendanceCorrectionReviewed => (
    label: 'Attendance correction',
    icon: Icons.edit_calendar_outlined,
    color: AppColors.orange,
  ),
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
  _ => shiftAndLeavePresentation(type),
};
