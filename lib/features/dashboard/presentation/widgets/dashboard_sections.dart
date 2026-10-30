import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

/// Named destinations replace ambiguous header icons and quick actions.
class DashboardSections extends StatelessWidget {
  const DashboardSections({super.key});
  static const items = [
    (
      'Manager tasks',
      'Review work that needs your decision',
      '/work?tab=tasks',
      Icons.checklist_rounded,
    ),
    (
      'Shifts',
      'Manage shift templates and schedules',
      '/work?tab=shifts',
      Icons.calendar_month_outlined,
    ),
    (
      'Team announcements',
      'Publish updates and follow acknowledgments',
      '/work?tab=announcements',
      Icons.campaign_outlined,
    ),
  ];
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr('Workspace sections'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              key: Key('dashboard-section-${item.$3.split('=').last}'),
              leading: Icon(
                item.$4,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(context.tr(item.$1)),
              subtitle: Text(context.tr(item.$2)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(item.$3),
            ),
          ),
        ),
    ],
  );
}
