import 'package:flutter/material.dart';

TextTheme employeeTypography(
  TextTheme base,
  Color ink,
  Color muted,
  String fontFamily,
) {
  final applied = base.apply(
    fontFamily: fontFamily,
    bodyColor: ink,
    displayColor: ink,
  );
  return applied
      .copyWith(
        headlineSmall: applied.headlineSmall?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
          height: 1.2,
          color: ink,
        ),
        titleLarge: applied.titleLarge?.copyWith(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          letterSpacing: -.4,
          color: ink,
        ),
        titleMedium: applied.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: applied.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.45,
          color: ink,
        ),
        bodyMedium: applied.bodyMedium?.copyWith(
          fontSize: 15,
          height: 1.45,
          color: ink,
        ),
        bodySmall: applied.bodySmall?.copyWith(
          fontSize: 13,
          height: 1.4,
          color: muted,
        ),
      )
      .apply(fontFamily: fontFamily);
}
