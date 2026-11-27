import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/manager_dashboard_header.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_attendance_overview.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_review_summary.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_team_update.dart';

class ManagerDashboardContent extends StatelessWidget {
  const ManagerDashboardContent({
    required this.data,
    required this.state,
    super.key,
  });
  final ManagerDashboardData data;
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) {
    final scope = context.read<DashboardCubit>().scope;
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().load(refresh: true),
      child: ListView(
        key: const Key('dashboard-content'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          ManagerDashboardHeader(
            data: data,
            workspaceName: scope?.workspaceName,
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
            key: ValueKey(('reviews', scope)),
            refreshToken: data.generatedAt,
            workspaceId: scope?.workspaceId ?? '',
          ),
          const SizedBox(height: 28),
          ManagerTeamUpdate(
            key: ValueKey(('announcements', scope)),
            refreshToken: data.generatedAt,
            workspaceId: scope?.workspaceId ?? '',
          ),
        ],
      ),
    );
  }
}
