import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class AttendanceMetric extends StatelessWidget {
  const AttendanceMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.tr(label),
                style: TextStyle(
                  color: AppPalette.of(context).textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                alignment: AlignmentDirectional.centerStart,
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
        ),
        Icon(icon, color: color, size: 27),
      ],
    ),
  );
}
