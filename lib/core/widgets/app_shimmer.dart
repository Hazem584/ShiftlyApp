import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shimmer/shimmer.dart';

/// One animation for an entire placeholder layout, respecting reduced motion.
class AppShimmer extends StatelessWidget {
  const AppShimmer({
    required this.child,
    this.label = 'Loading content',
    super.key,
  });
  final Widget child;
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: context.tr(label),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Shimmer.fromColors(
          baseColor: dark
              ? colors.surfaceContainerHighest
              : colors.outlineVariant,
          highlightColor: dark ? const Color(0xFF30464D) : colors.surface,
          direction: Directionality.of(context) == TextDirection.rtl
              ? ShimmerDirection.rtl
              : ShimmerDirection.ltr,
          period: const Duration(milliseconds: 1400),
          enabled:
              TickerMode.valuesOf(context).enabled &&
              !MediaQuery.disableAnimationsOf(context),
          child: IgnorePointer(child: child),
        ),
      ),
    );
  }
}
