import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_loading.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_attendance_overview.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_review_summary.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_team_update.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => switch (state) {
          DashboardLoading() => const DashboardLoadingView(),
          DashboardLoaded(:final data) when data is ManagerDashboardData =>
            _loaded(context, data, state),
          DashboardLoaded() => const SizedBox.shrink(),
          DashboardError(:final failure) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: context.tr('Dashboard unavailable'),
            message: failure.message,
            action: FilledButton.icon(
              onPressed: context.read<DashboardCubit>().load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('Try again')),
            ),
          ),
        },
      ),
    ),
  );

  Widget _loaded(
    BuildContext context,
    ManagerDashboardData data,
    DashboardLoaded state,
  ) {
    final scope = context.read<DashboardCubit>().scope;
    final profile = context.watch<ProfileCubit>().state;
    final name = profile is ProfileLoaded
        ? profile.profile.displayName.split(' ').first
        : context.tr('Manager');
    final time = WorkspaceTime.inWorkspace(data.generatedAt, data.timezone);
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().load(refresh: true),
      child: ListView(
        key: const Key('dashboard-content'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('WORKSPACE'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      scope?.workspaceName.isNotEmpty == true
                          ? scope!.workspaceName
                          : context.tr('Workspace'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const NotificationBell(),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            DateFormat(
              'EEEE, d MMMM',
              Localizations.localeOf(context).toString(),
            ).format(time),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              time.hour < 12
                  ? 'Morning, {name}'
                  : time.hour < 18
                  ? 'Afternoon, {name}'
                  : 'Evening, {name}',
              {'name': name},
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          if (state.failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                context.tr(state.failure!.message),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ManagerAttendanceOverview(summary: data.summary),
          const SizedBox(height: 28),
          ManagerReviewSummary(
            key: ValueKey(('reviews', scope, data.generatedAt)),
            workspaceId: scope?.workspaceId ?? '',
          ),
          const SizedBox(height: 28),
          ManagerTeamUpdate(
            key: ValueKey(('announcements', scope, data.generatedAt)),
            workspaceId: scope?.workspaceId ?? '',
          ),
        ],
      ),
    );
  }
}
