import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/summary_card.dart';

class DashboardMetricsGrid extends StatelessWidget {
  const DashboardMetricsGrid({required this.data, super.key});
  final ManagerDashboardData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
      final columns = largeText || constraints.maxWidth < 300
          ? 1
          : constraints.maxWidth >= 800
          ? 4
          : 2;
      final width =
          (constraints.maxWidth - AppSpacing.s * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.s,
        runSpacing: AppSpacing.s,
        children: [
          SizedBox(
            width: width,
            child: SummaryCard(
              label: context.tr('Total employees'),
              value: data.summary.totalEmployees,
              icon: Icons.groups_outlined,
              color: AppColors.ink,
              caption: 'Active employees',
            ),
          ),
          SizedBox(
            width: width,
            child: SummaryCard(
              label: context.tr('Scheduled today'),
              value: data.summary.scheduledToday,
              icon: Icons.person_rounded,
              color: AppColors.success,
              caption: 'Non-cancelled shifts',
            ),
          ),
          SizedBox(
            width: width,
            child: SummaryCard(
              label: context.tr('Clocked in now'),
              value: data.summary.clockedInNow,
              icon: Icons.login_rounded,
              color: AppColors.success,
              caption: 'Open attendance',
            ),
          ),
          SizedBox(
            width: width,
            child: SummaryCard(
              label: context.tr('Completed today'),
              value: data.summary.completedToday,
              icon: Icons.task_alt_rounded,
              color: AppColors.teal,
              caption: 'Clocked out',
            ),
          ),
        ],
      );
    },
  );
}
