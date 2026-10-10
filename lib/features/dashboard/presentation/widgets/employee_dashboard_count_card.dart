import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
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
            context.tr('{value1}', {'value1': (value).toString()}),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Text(
          context.tr(label),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppPalette.of(context).textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}
