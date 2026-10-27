import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/app_shimmer.dart';

class PointsLoadingSkeleton extends StatelessWidget {
  const PointsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView(
      key: const Key('performance-loading-skeleton'),
      padding: const EdgeInsets.all(16),
      children: List.generate(
        5,
        (index) => Container(
          height: index == 0 ? 170 : 110,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    ),
  );
}
