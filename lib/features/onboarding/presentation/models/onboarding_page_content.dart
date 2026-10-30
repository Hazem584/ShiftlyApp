import 'package:flutter/material.dart';

class OnboardingPageContent {
  const OnboardingPageContent(
    this.title,
    this.description,
    this.icon,
    this.features,
  );
  final String title, description;
  final IconData icon;
  final List<(IconData, String)> features;
  static const pages = [
    OnboardingPageContent(
      'Your shifts, clearly organized',
      'Know what’s next, and keep your working day in view.',
      Icons.calendar_month_rounded,
      [
        (Icons.event_available_rounded, 'Assigned fixed shifts'),
        (Icons.login_rounded, 'Check in and check out'),
        (Icons.more_time_rounded, 'Manager-authorized extra shifts'),
      ],
    ),
    OnboardingPageContent(
      'Manage your tasks',
      'Keep your daily tasks organized and track what is done.',
      Icons.insights_rounded,
      [
        (Icons.stars_rounded, 'Personal tasks'),
        (Icons.timeline_rounded, 'Task reminders'),
        (Icons.emoji_events_rounded, 'Completed tasks'),
      ],
    ),
    OnboardingPageContent(
      'Stay connected',
      'Keep your workspace conversations and updates together.',
      Icons.forum_rounded,
      [
        (Icons.groups_rounded, 'Workspace group chat'),
        (Icons.photo_library_rounded, 'Images and voice messages'),
        (Icons.notifications_active_rounded, 'Notifications and updates'),
      ],
    ),
  ];
}
