import 'package:flutter/material.dart';

import 'access_icon.dart';

class AccessTile extends StatelessWidget {
  const AccessTile({
    required this.title,
    required this.subtitle,
    this.icon = 'work',
    this.onTap,
    this.selected = false,
    this.trailing,
    super.key,
  });
  final String title, subtitle, icon;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: AccessIcon(icon),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    ),
  );
}
