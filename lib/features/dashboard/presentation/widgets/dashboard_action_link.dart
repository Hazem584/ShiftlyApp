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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppPalette.of(context).orange),
      title: Text(context.tr(title)),
      subtitle: subtitle == null ? null : Text(context.tr(subtitle!)),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}
