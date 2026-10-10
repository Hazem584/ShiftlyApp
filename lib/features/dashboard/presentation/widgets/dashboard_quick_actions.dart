import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/section_heading.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_quick_action.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({required this.pendingRequests, super.key});
  final int pendingRequests;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SectionHeading(
        title: 'Quick actions',
        trailing: DecoratedBox(
          decoration: BoxDecoration(
            color: pendingRequests > 0 ? AppColors.orangeSoft : AppColors.field,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              '$pendingRequests pending',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        onTap: () => context.push(AppRoutes.managerPerformance),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.insights_outlined, color: AppColors.orange),
          title: Text(context.tr('Performance')),
          subtitle: Text(
            context.tr('Employee points, policies, disputes and warnings'),
          ),
          trailing: Icon(Icons.chevron_right_rounded),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: DashboardQuickAction(
              icon: Icons.person_add_alt_1_rounded,
              label: context.tr('Add employee'),
              caption: 'Invite someone',
              color: AppColors.ink,
              onTap: () => context.push('/employees/add'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DashboardQuickAction(
              icon: Icons.schedule_rounded,
              label: context.tr('Shifts'),
              caption: 'Plan the day',
              color: AppColors.teal,
              onTap: () => context.push(AppRoutes.managerShifts),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DashboardQuickAction(
              icon: Icons.approval_outlined,
              label: context.tr('Requests'),
              caption: 'Review leave',
              color: AppColors.orange,
              onTap: () => context.go(AppRoutes.attendanceLeaveRequests),
            ),
          ),
        ],
      ),
    ],
  );
}
