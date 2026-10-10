import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class DashboardQuickAction extends StatelessWidget {
  const DashboardQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    child: Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(label),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        Text(
          context.tr(caption),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: AppPalette.of(context).textSecondary,
          ),
        ),
      ],
    ),
  );
}
