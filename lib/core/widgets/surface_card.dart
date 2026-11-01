import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/manager/presentation/design/manager_theme_marker.dart';

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppPalette.of(context).surface,
      borderRadius: BorderRadius.circular(
        Theme.of(context).extension<ManagerThemeMarker>() != null
            ? 16
            : AppRadii.l,
      ),
      border: Theme.of(context).extension<ManagerThemeMarker>() != null
          ? null
          : Border.all(color: AppPalette.of(context).borderColor),
      boxShadow:
          Theme.of(context).extension<ManagerThemeMarker>() != null ||
              Theme.of(context).brightness == Brightness.dark
          ? const []
          : AppShadows.soft,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          Theme.of(context).extension<ManagerThemeMarker>() != null
              ? 16
              : AppRadii.l,
        ),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}
