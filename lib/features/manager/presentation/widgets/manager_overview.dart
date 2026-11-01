import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_top_bar.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:shiftly/features/team_work/presentation/widgets/dashboard_announcements.dart';

import 'manager_attendance_summary.dart';

class ManagerOverview extends StatelessWidget {
  const ManagerOverview({
    required this.data,
    required this.workspaceName,
    super.key,
  });
  final ManagerDashboardData data;
  final String workspaceName;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(data.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardTopBar(workspaceName: workspaceName, timezone: data.timezone),
        const SizedBox(height: 24),
        Text(
          date == null
              ? data.date
              : DateFormat.yMMMMEEEEd(
                  Localizations.localeOf(context).toString(),
                ).format(date),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profile) => Text(
            profile is ProfileLoaded
                ? context.tr('Hello, {name}', {
                    'name': profile.profile.displayName,
                  })
                : context.tr('Your workday'),
            key: const Key('manager-home-greeting'),
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 24),
        ManagerAttendanceSummary(summary: data.summary),
        const SizedBox(height: 28),
        Text(
          context.tr('Needs your review'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          key: const Key('dashboard-section-tasks'),
          onTap: () => context.go('/work?tab=tasks'),
          child: Row(
            children: [
              const Icon(Icons.fact_check_outlined),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Attendance & requests'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('{count} pending leave requests', {
                        'count': data.summary.pendingLeaveRequests.toString(),
                      }),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(context.tr('Team update'), style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        DashboardAnnouncements(refreshToken: data.generatedAt),
        TextButton(
          onPressed: () => context.go('/work?tab=announcements'),
          child: Text(context.tr('View announcements')),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/employees?tab=attendance'),
              icon: const Icon(Icons.schedule_outlined),
              label: Text(context.tr('Attendance')),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/employees?tab=leaveRequests'),
              icon: const Icon(Icons.event_note_outlined),
              label: Text(context.tr('Leave requests')),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/work?tab=shifts'),
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(context.tr('Shift templates')),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/work/reports'),
              icon: const Icon(Icons.assessment_outlined),
              label: Text(context.tr('Reports')),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('{count} employees', {
            'count': data.summary.totalEmployees.toString(),
          }),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('{count} missed starts', {
            'count': data.summary.missedToday.toString(),
          }),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        Text(
          context.tr('{count} completed today', {
            'count': data.summary.completedToday.toString(),
          }),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
