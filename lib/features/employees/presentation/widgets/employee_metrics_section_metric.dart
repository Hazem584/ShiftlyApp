import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class EmployeeMetricsSectionMetric extends StatelessWidget {
  const EmployeeMetricsSectionMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 145,
    child: SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.of(context).textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  context.tr('{value1}', {'value1': (value).toString()}),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Icon(icon, color: color, size: 24),
        ],
      ),
    ),
  );
}
