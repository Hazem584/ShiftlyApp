import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/summary_card.dart';

class DashboardMetricsGrid extends StatelessWidget {
  const DashboardMetricsGrid({required this.data, super.key});
  final DashboardData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
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
  );
}
