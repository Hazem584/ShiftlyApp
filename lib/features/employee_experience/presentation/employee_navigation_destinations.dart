import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

List<NavigationDestination> buildEmployeeDestinations(
  BuildContext context,
  int unreadCount,
) {
  Widget chatBadge(IconData icon) => Badge(
    isLabelVisible: unreadCount > 0,
    label: Text(
      unreadCount > 99
          ? '99+'
          : context.tr('{value1}', {'value1': '$unreadCount'}),
    ),
    child: Icon(icon),
  );
  return [
    NavigationDestination(
      icon: const Icon(Icons.home_outlined),
      selectedIcon: const Icon(Icons.home_rounded),
      label: context.tr('Home'),
    ),
    NavigationDestination(
      icon: const Icon(Icons.calendar_month_outlined),
      selectedIcon: const Icon(Icons.calendar_month_rounded),
      label: context.tr('My Shifts'),
    ),
    NavigationDestination(
      icon: const Icon(Icons.check_outlined),
      selectedIcon: const Icon(Icons.check),
      label: context.tr('Tasks'),
    ),
    NavigationDestination(
      icon: chatBadge(Icons.chat_bubble_outline_rounded),
      selectedIcon: chatBadge(Icons.chat_bubble_rounded),
      label: context.tr('Chat'),
    ),
    NavigationDestination(
      icon: const Icon(Icons.person_outline_rounded),
      selectedIcon: const Icon(Icons.person_rounded),
      label: context.tr('Profile'),
    ),
  ];
}
