import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class WorkspaceAccessLink extends StatelessWidget {
  const WorkspaceAccessLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(context.tr(title)),
      subtitle: Text(context.tr(subtitle)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    ),
  );
}
