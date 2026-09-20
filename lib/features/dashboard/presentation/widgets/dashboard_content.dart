import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/models/attendance_record.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/summary_card.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/profile/presentation/widgets/profile_content.dart';

class DashboardContentHost extends StatelessWidget {
  const DashboardContentHost({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => switch (state) {
          DashboardLoading() => const _DashboardLoading(),
          DashboardLoaded(:final data) => _DashboardContent(data: data),
          DashboardEmpty() => EmptyState(
            icon: Icons.group_add_outlined,
            title: 'Your workplace is ready',
            message: 'Add your first employee to begin tracking shifts and attendance.',
            action: FilledButton.icon(
              onPressed: () => context.push('/employees/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.addEmployee),
            ),
          ),
          DashboardError(:final message) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Something went wrong',
            message: message,
            action: FilledButton.icon(
              onPressed: context.read<DashboardCubit>().load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
        },
      ),
    ),
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: context.read<DashboardCubit>().load,
    color: AppColors.ink,
    child: ListView(
      key: const Key('dashboard-content'),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        const _TopBar(),
        const SizedBox(height: AppSpacing.m),
        _Hero(data: data),
        const SizedBox(height: AppSpacing.m),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - AppSpacing.s) / 2;
            return Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                SizedBox(
                  width: width,
                  child: SummaryCard(
                    label: 'Total employees',
                    value: data.totalEmployees,
                    icon: Icons.groups_outlined,
                    color: AppColors.ink,
                    caption: 'Shift Lab team',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: SummaryCard(
                    label: 'Present today',
                    value: data.presentEmployees,
                    icon: Icons.person_rounded,
                    color: AppColors.success,
                    caption: 'Checked in',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: SummaryCard(
                    label: 'Absent',
                    value: data.absentEmployees,
                    icon: Icons.person_off_outlined,
                    color: AppColors.error,
                    caption: 'Today',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: SummaryCard(
                    label: 'Late',
                    value: data.lateEmployees,
                    icon: Icons.schedule_rounded,
                    color: AppColors.warning,
                    caption: 'Needs review',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.l),
        _SectionHeading(
          title: 'Quick actions',
          trailing: '${data.pendingRequests} pending',
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
        const SizedBox(height: AppSpacing.l),
        const _SectionHeading(title: 'Current shift'),
        const SizedBox(height: AppSpacing.s),
        SurfaceCard(
          child: Row(
            children: [
              const _IconBox(
                icon: Icons.wb_sunny_outlined,
                color: AppColors.orange,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.currentShift.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.currentShift.timeRange,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    '${data.currentShiftEmployees} on shift',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        const _SectionHeading(title: 'Recent attendance'),
        const SizedBox(height: AppSpacing.s),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (
                var index = 0;
                index < data.recentActivity.length;
                index++
              ) ...[
                _ActivityTile(record: data.recentActivity[index]),
                if (index < data.recentActivity.length - 1)
                  const Divider(height: 1, indent: 64, endIndent: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        const _SectionHeading(title: 'Pending approvals'),
        const SizedBox(height: AppSpacing.s),
        SurfaceCard(
          child: Row(
            children: [
              const _IconBox(
                icon: Icons.pending_actions_outlined,
                color: AppColors.warning,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.pendingRequests} requests waiting',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Review attendance and leave requests',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.go(AppRoutes.attendanceLeaveRequests),
                tooltip: 'Review requests',
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.ink, AppColors.orange],
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.white),
      ),
      const SizedBox(width: 11),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.workplace,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              'Manager workspace',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: () {},
        tooltip: 'Notifications',
        icon: const Badge(
          smallSize: 7,
          child: Icon(Icons.notifications_none_rounded),
        ),
      ),
      BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) => state is ProfileLoaded
            ? ProfileAvatar(profile: state.profile, radius: 19)
            : const CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                child: Text('M'),
              ),
      ),
    ],
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.data});
  final DashboardData data;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.ink, AppColors.orange, AppColors.teal],
        stops: [0, .55, 1],
      ),
      borderRadius: BorderRadius.circular(AppRadii.xl),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -32,
          top: -45,
          child: Container(
            width: 125,
            height: 125,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning, Manager! 👋',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              "Here's what's happening with your team today.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: .85),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 17),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroChip(
                  icon: Icons.groups_outlined,
                  label: '${data.totalEmployees} employees',
                ),
                _HeroChip(
                  icon: Icons.check_circle_outline,
                  label: '${data.presentEmployees} active today',
                ),
                _HeroChip(
                  icon: Icons.calendar_today_outlined,
                  label: _date(DateTime.now()),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: 22),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.record});
  final AttendanceRecord record;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: CircleAvatar(
      backgroundColor: AppColors.field,
      foregroundColor: AppColors.ink,
      child: Text(
        record.employeeName.substring(0, 1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    title: Text(
      record.employeeName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
    subtitle: Text(record.isLate ? 'Checked in late' : 'Checked in for work'),
    trailing: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _time(record.occurredAt),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        Text(
          record.isLate ? 'Late' : 'Present',
          style: TextStyle(
            color: record.isLate ? AppColors.warning : AppColors.success,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: const [
      _Skeleton(height: 42, width: 180),
      SizedBox(height: 16),
      _Skeleton(height: 160),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _Skeleton(height: 120)),
          SizedBox(width: 12),
          Expanded(child: _Skeleton(height: 120)),
        ],
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _Skeleton(height: 120)),
          SizedBox(width: 12),
          Expanded(child: _Skeleton(height: 120)),
        ],
      ),
      SizedBox(height: 20),
      Center(
        child: Text(
          'Preparing your dashboard…',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height, this.width});
  final double height;
  final double? width;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
    ),
  );
}

String _time(DateTime value) =>
    '${value.hour % 12 == 0 ? 12 : value.hour % 12}:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';

String _date(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
