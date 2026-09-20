import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

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
              label: 'Attendance',
              onTap: () => context.go('/attendance'),
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
    child: Column(
      children: [
        Icon(icon, size: 21),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (trailing != null)
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              trailing!,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ),
    ],
  );
}
