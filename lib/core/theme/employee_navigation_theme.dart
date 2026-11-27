import 'package:flutter/material.dart';

NavigationBarThemeData employeeNavigationTheme(
  ColorScheme scheme,
  String fontFamily,
) {
  final surface = scheme.surface;
  final selected = scheme.primaryContainer;
  final primary = scheme.primary;
  final muted = scheme.onSurfaceVariant;
  return NavigationBarThemeData(
    backgroundColor: surface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: selected,
    height: 80,
    labelTextStyle: WidgetStateProperty.resolveWith(
      (s) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: s.contains(WidgetState.selected)
            ? FontWeight.w600
            : FontWeight.w400,
        color: s.contains(WidgetState.selected) ? primary : muted,
      ),
    ),
    iconTheme: WidgetStateProperty.resolveWith(
      (s) => IconThemeData(
        size: 23,
        color: s.contains(WidgetState.selected) ? primary : muted,
      ),
    ),
  );
}
