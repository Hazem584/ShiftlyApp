import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/section_heading.dart';

import 'dashboard_action_link.dart';
import 'dashboard_quick_action.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({required this.pendingRequests, super.key});
  final int pendingRequests;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      SectionHeading(
        title: context.tr('Quick actions'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.of(context).field,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            context.tr('{value1} pending', {
              'value1': pendingRequests.toString(),
            }),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.s),
      Row(
        children: [
          Expanded(
            child: DashboardQuickAction(
              icon: Icons.person_add_alt_1_rounded,
              label: context.tr('Add employee'),
              caption: 'Invite someone',
              color: AppPalette.of(context).primaryColor,
              onTap: () => context.push('/employees/add'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DashboardQuickAction(
              icon: Icons.schedule_rounded,
              label: context.tr('Shifts'),
              caption: 'Plan the day',
              color: AppPalette.of(context).teal,
              onTap: () => context.push(AppRoutes.managerShifts),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DashboardQuickAction(
              icon: Icons.approval_outlined,
              label: context.tr('Requests'),
              caption: 'Review leave',
              color: AppPalette.of(context).orange,
              onTap: () => context.go(AppRoutes.attendanceLeaveRequests),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 3 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          final links = [
            DashboardActionLink(
              key: const Key('dashboard-manager-tasks'),
              icon: Icons.task_alt_outlined,
              title: 'Manager tasks',
              subtitle: 'View all tasks',
              onTap: () => context.push('/team-work?tab=tasks'),
            ),
            DashboardActionLink(
              key: const Key('dashboard-team-announcements'),
              icon: Icons.campaign_outlined,
              title: 'Team announcements',
              subtitle: 'View all announcements',
              onTap: () => context.push('/team-work?tab=announcements'),
            ),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final link in links)
                SizedBox(
                  width: width,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: columns > 1 ? 116 : 0,
                    ),
                    child: link,
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}
