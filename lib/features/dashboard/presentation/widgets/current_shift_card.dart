import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/current_shift_value.dart';

class DashboardDayStatusCard extends StatelessWidget {
  const DashboardDayStatusCard({required this.data, super.key});
  final ManagerDashboardData data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.tr('Today at a glance'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.s),
      SizedBox(
        key: const Key('today-at-a-glance-card'),
        width: double.infinity,
        child: SurfaceCard(
          child: Row(
            children: [
              Expanded(
                child: CurrentShiftValue(
                  label: context.tr('Late'),
                  value: data.summary.lateToday,
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: CurrentShiftValue(
                  label: context.tr('Missed'),
                  value: data.summary.missedToday,
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: CurrentShiftValue(
                  label: context.tr('On approved leave'),
                  value: data.summary.onApprovedLeave,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
