import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class DashboardActionLink extends StatelessWidget {
  const DashboardActionLink({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPalette.of(context).selected,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 20, color: AppPalette.of(context).primaryColor),
      ),
      title: Text(
        context.tr(title),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              context.tr(subtitle!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}
