import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/app_shimmer.dart';

import 'dashboard_skeleton.dart';

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      Semantics(
        liveRegion: true,
        child: Text(
          context.tr('Preparing your dashboard…'),
          style: TextStyle(color: AppPalette.of(context).textSecondary),
        ),
      ),
      const SizedBox(height: 16),
      AppShimmer(
        child: Column(
          children: [
            const DashboardSkeleton(height: 42, width: 180),
            const SizedBox(height: 16),
            const DashboardSkeleton(height: 160),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: DashboardSkeleton(height: 120)),
                SizedBox(width: 12),
                Expanded(child: DashboardSkeleton(height: 120)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: DashboardSkeleton(height: 120)),
                SizedBox(width: 12),
                Expanded(child: DashboardSkeleton(height: 120)),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
