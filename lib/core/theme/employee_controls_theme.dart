import 'package:flutter/material.dart';

ThemeData employeeControlsTheme(
  ThemeData theme,
  RoundedRectangleBorder shape,
  String fontFamily,
) {
  final scheme = theme.colorScheme;
  final primary = scheme.primary;
  final border = scheme.outlineVariant;
  final muted = scheme.onSurfaceVariant;
  final surface = scheme.surface;
  return theme.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, 52),
        shape: shape,
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(0, 48),
        shape: shape,
        side: BorderSide(color: border),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.all(16),
      labelStyle: TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
  );
}

DatePickerThemeData employeeDatePickerTheme(ColorScheme scheme) =>
    DatePickerThemeData(
      backgroundColor: scheme.surface,
      headerForegroundColor: scheme.onSurface,
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : states.contains(WidgetState.disabled)
            ? scheme.onSurfaceVariant
            : scheme.onSurface,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? scheme.primary : null,
      ),
      weekdayStyle: TextStyle(color: scheme.onSurfaceVariant),
      yearForegroundColor: WidgetStatePropertyAll(scheme.onSurface),
    );
