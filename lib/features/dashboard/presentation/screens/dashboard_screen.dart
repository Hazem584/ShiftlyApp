import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/ease_hint.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/current_shift_card.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_activity_section.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_hero_section.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_loading.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_metrics_grid.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_quick_actions.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_top_bar.dart';

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
            title: 'Something went wrong',
            message: failure.message,
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

  Widget _loaded(
    BuildContext context,
    ManagerDashboardData data,
    DashboardLoaded state,
  ) => RefreshIndicator(
    onRefresh: () => context.read<DashboardCubit>().load(refresh: true),
    color: AppColors.ink,
    child: ListView(
      key: const Key('dashboard-content'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        DashboardTopBar(
          workspaceName:
              context.read<DashboardCubit>().scope?.workspaceName ??
              'Workspace',
          timezone: data.timezone,
        ),
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            state.failure!.message,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        DashboardHeroSection(data: data),
        const SizedBox(height: AppSpacing.m),
        const EaseHint(
          icon: Icons.touch_app_outlined,
          message: 'Tap a card or Quick action to jump to employees, shifts, or leave reviews.',
        ),
        const SizedBox(height: AppSpacing.m),
        DashboardMetricsGrid(data: data),
        const SizedBox(height: AppSpacing.l),
        DashboardQuickActions(
          pendingRequests: data.summary.pendingLeaveRequests,
        ),
        const SizedBox(height: AppSpacing.l),
        DashboardDayStatusCard(data: data),
        const SizedBox(height: AppSpacing.l),
        DashboardActivitySection(
          shifts: data.todayShifts,
          timezone: data.timezone,
        ),
        const SizedBox(height: AppSpacing.l),
        DashboardApprovalsCard(
          pendingRequests: data.summary.pendingLeaveRequests,
        ),
      ],
    ),
  );
}
