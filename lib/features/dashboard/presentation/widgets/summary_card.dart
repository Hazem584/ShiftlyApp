import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
    super.key,
  });
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(15),
      child: SizedBox(
        height: 88,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(icon, color: color, size: 23),
              ],
            ),
            const Spacer(),
            Text('$value', style: Theme.of(context).textTheme.headlineSmall),
            if (caption != null)
              Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
