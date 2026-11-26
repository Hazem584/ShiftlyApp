import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_shimmer.dart';

import 'package:shiftly/core/widgets/dashboard_card_loading.dart';
import 'package:shiftly/core/widgets/dashboard_skeleton.dart';

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key, this.employee = false});
  final bool employee;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('Preparing your dashboard…'),
    liveRegion: true,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      children: [
        const AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardSkeleton(height: 12, width: 108),
              SizedBox(height: 16),
              DashboardSkeleton(height: 28, width: 176),
              SizedBox(height: 8),
              DashboardSkeleton(height: 14, width: 135),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const DashboardCardLoading(kind: DashboardCardKind.attendance),
        const SizedBox(height: 24),
        const DashboardCardLoading(kind: DashboardCardKind.tile),
        const SizedBox(height: 16),
        DashboardCardLoading(
          kind: employee
              ? DashboardCardKind.tile
              : DashboardCardKind.announcement,
        ),
      ],
    ),
  );
}
