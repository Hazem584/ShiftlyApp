import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

List<NavigationRailDestination> buildWorkspaceRailDestinations(
  BuildContext context, {
  required bool employee,
  required int unreadCount,
}) {
  Widget chatBadge(IconData icon) => Badge(
    isLabelVisible: unreadCount > 0,
    label: Text(
      unreadCount > 99
          ? '99+'
          : context.tr('{value1}', {'value1': unreadCount.toString()}),
    ),
    child: Icon(icon),
  );

  return [
    NavigationRailDestination(
      icon: const Icon(Icons.home_outlined),
      selectedIcon: const Icon(Icons.home_rounded),
      label: Text(context.tr(employee ? 'Overview' : 'Home')),
    ),
    NavigationRailDestination(
      icon: Icon(
        employee ? Icons.calendar_month_outlined : Icons.groups_outlined,
      ),
      selectedIcon: Icon(
        employee ? Icons.calendar_month_rounded : Icons.groups_rounded,
      ),
      label: Text(context.tr(employee ? 'My Shifts' : 'Team')),
    ),
    if (employee)
      NavigationRailDestination(
        icon: const Icon(Icons.check_outlined),
        label: Text(context.tr('Tasks')),
      ),
    if (!employee)
      NavigationRailDestination(
        icon: const Icon(Icons.work_outline_rounded),
        selectedIcon: const Icon(Icons.work_rounded),
        label: Text(context.tr('Work')),
      ),
    NavigationRailDestination(
      icon: chatBadge(Icons.chat_bubble_outline_rounded),
      selectedIcon: chatBadge(Icons.chat_bubble_rounded),
      label: Text(context.tr('Chat')),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.person_outline_rounded),
      selectedIcon: const Icon(Icons.person_rounded),
      label: Text(context.tr('Profile')),
    ),
  ];
}
