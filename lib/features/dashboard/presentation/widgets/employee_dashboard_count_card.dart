import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class EmployeeDashboardCountCard extends StatelessWidget {
  const EmployeeDashboardCountCard({
    super.key,
    required this.label,
    required this.value,
  });
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}
