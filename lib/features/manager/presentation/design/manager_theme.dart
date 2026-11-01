import 'package:flutter/material.dart';
import 'package:shiftly/features/auth/presentation/design/access_theme.dart';

import 'manager_theme_marker.dart';

/// Reuses the approved Phase 1 fonts and semantic foundation for managers.
class ManagerTheme extends StatelessWidget {
  const ManagerTheme({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => AccessTheme(
    child: Builder(
      builder: (context) {
        final base = Theme.of(context);
        final scheme = base.colorScheme;
        final shape = RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        );
        return Theme(
          data: base.copyWith(
            extensions: [...base.extensions.values, const ManagerThemeMarker()],
            textTheme: base.textTheme.copyWith(
              headlineSmall: base.textTheme.headlineMedium?.copyWith(
                fontSize: 30,
              ),
              bodyMedium: base.textTheme.bodyLarge,
            ),
            navigationRailTheme: base.navigationRailTheme.copyWith(
              selectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelTextStyle: base.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            cardTheme: CardThemeData(
              color: scheme.surface,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: shape,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: scheme.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titleTextStyle: base.textTheme.titleLarge,
              contentTextStyle: base.textTheme.bodyLarge,
            ),
            bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: scheme.surface,
              modalBackgroundColor: scheme.surface,
              showDragHandle: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            chipTheme: base.chipTheme.copyWith(
              backgroundColor: scheme.surface,
              selectedColor: scheme.primaryContainer,
              side: BorderSide.none,
              labelStyle: base.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
              ),
            ),
            listTileTheme: ListTileThemeData(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              titleTextStyle: base.textTheme.titleMedium,
              subtitleTextStyle: base.textTheme.bodySmall,
              iconColor: scheme.onSurfaceVariant,
              shape: shape,
            ),
          ),
          child: child,
        );
      },
    ),
  );
}
