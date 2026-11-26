import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/app_shimmer.dart';

import 'dashboard_skeleton.dart';

enum DashboardCardKind { attendance, tile, announcement }

class DashboardCardLoading extends StatelessWidget {
  const DashboardCardLoading({super.key, required this.kind});
  final DashboardCardKind kind;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.all(kind == DashboardCardKind.attendance ? 20 : 16),
      child: AppShimmer(
        child: switch (kind) {
          DashboardCardKind.attendance => const Column(
            children: [
              DashboardSkeleton(height: 13, width: 136),
              SizedBox(height: 16),
              DashboardSkeleton(height: 35, width: 104),
              SizedBox(height: 12),
              DashboardSkeleton(height: 12, width: 159),
              SizedBox(height: 18),
              DashboardSkeleton(height: 39),
            ],
          ),
          DashboardCardKind.tile => const Row(
            children: [
              DashboardSkeleton(height: 38, width: 38),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    DashboardSkeleton(height: 15, width: 152),
                    SizedBox(height: 8),
                    DashboardSkeleton(height: 11),
                  ],
                ),
              ),
            ],
          ),
          DashboardCardKind.announcement => const Column(
            children: [
              DashboardSkeleton(height: 17, width: 152),
              SizedBox(height: 10),
              DashboardSkeleton(height: 12),
              SizedBox(height: 8),
              DashboardSkeleton(height: 12, width: 175),
              SizedBox(height: 14),
              DashboardSkeleton(height: 22, width: 105),
            ],
          ),
        },
      ),
    ),
  );
}
