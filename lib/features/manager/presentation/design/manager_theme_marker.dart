import 'package:flutter/material.dart';

/// Marks manager presentation without changing employee/shared route themes.
class ManagerThemeMarker extends ThemeExtension<ManagerThemeMarker> {
  const ManagerThemeMarker();
  @override
  ManagerThemeMarker copyWith() => this;
  @override
  ManagerThemeMarker lerp(covariant ManagerThemeMarker? other, double t) =>
      this;
}
