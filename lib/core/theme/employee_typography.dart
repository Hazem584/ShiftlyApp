import 'package:flutter/material.dart';

TextTheme employeeTypography(
  TextTheme base,
  Color ink,
  Color muted,
  String fontFamily,
) {
  return base
      .apply(fontFamily: fontFamily, bodyColor: ink, displayColor: ink)
      .copyWith(
        headlineSmall: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
          height: 1.2,
          color: ink,
        ),
        titleLarge: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          letterSpacing: -.4,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: ink),
        bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: ink),
        bodySmall: TextStyle(fontSize: 13, height: 1.4, color: muted),
      )
      .apply(fontFamily: fontFamily);
}
