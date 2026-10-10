import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_skeleton.dart';

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      DashboardSkeleton(height: 42, width: 180),
      SizedBox(height: 16),
      DashboardSkeleton(height: 160),
      SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: DashboardSkeleton(height: 120)),
          SizedBox(width: 12),
          Expanded(child: DashboardSkeleton(height: 120)),
        ],
      ),
      SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: DashboardSkeleton(height: 120)),
          SizedBox(width: 12),
          Expanded(child: DashboardSkeleton(height: 120)),
        ],
      ),
      SizedBox(height: 20),
      Center(
        child: Text(
          context.tr('Preparing your dashboard…'),
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    ],
  );
}
