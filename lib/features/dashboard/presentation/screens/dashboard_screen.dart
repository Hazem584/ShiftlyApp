import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
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
          DashboardLoaded(:final data) => _loaded(context, data),
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

  Widget _loaded(BuildContext context, DashboardData data) => RefreshIndicator(
    onRefresh: context.read<DashboardCubit>().load,
    color: AppColors.ink,
    child: ListView(
      key: const Key('dashboard-content'),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        const DashboardTopBar(),
        const SizedBox(height: AppSpacing.m),
        DashboardHeroSection(data: data),
        const SizedBox(height: AppSpacing.m),
        DashboardMetricsGrid(data: data),
        const SizedBox(height: AppSpacing.l),
        DashboardQuickActions(pendingRequests: data.pendingRequests),
        const SizedBox(height: AppSpacing.l),
        CurrentShiftCard(data: data),
        const SizedBox(height: AppSpacing.l),
        DashboardActivitySection(records: data.recentActivity),
        const SizedBox(height: AppSpacing.l),
        DashboardApprovalsCard(pendingRequests: data.pendingRequests),
      ],
    ),
  );
}
