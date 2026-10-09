import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class EmployeeInformationSection extends StatelessWidget {
  const EmployeeInformationSection({
    super.key,
    required this.title,
    required this.rows,
  });

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0)
                const Divider(height: 1, indent: 58, endIndent: 14),
              rows[index],
            ],
          ],
        ),
      ),
    ],
  );
}
