import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

part 'parts/dashboard_quick_actions/private_quick_action.dart';
part 'parts/dashboard_quick_actions/private_section_heading.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({required this.pendingRequests, super.key});
  final int pendingRequests;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SectionHeading(
        title: 'Quick actions',
        trailing: '$pendingRequests pending',
      ),
      const SizedBox(height: AppSpacing.s),
      ListTile(
        leading: const Icon(Icons.insights_outlined),
        title: const Text('Performance'),
        subtitle: const Text(
          'Employee Points, policies, disputes and warnings',
        ),
        onTap: () => context.push(AppRoutes.managerPerformance),
      ),
      Row(
        children: [
          Expanded(
            child: _QuickAction(
              icon: Icons.add_rounded,
              label: 'Add employee',
              onTap: () => context.push('/employees/add'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: Icons.schedule_rounded,
              label: 'Shifts',
              onTap: () => context.push(AppRoutes.managerShifts),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickAction(
              icon: Icons.approval_outlined,
              label: 'Requests',
              onTap: () => context.go(AppRoutes.attendanceLeaveRequests),
            ),
          ),
        ],
      ),
    ],
  );
}
