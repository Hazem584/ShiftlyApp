import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_palette.dart';

ColorScheme buildAppColorScheme(Brightness brightness, AppPalette colors) {
  return ColorScheme.fromSeed(
    seedColor: AppColors.primaryColor,
    brightness: brightness,
  ).copyWith(
    primary: colors.primaryColor,
    onPrimary: brightness == Brightness.dark
        ? const Color(0xFF062B29)
        : Colors.white,
    primaryContainer: colors.selected,
    onPrimaryContainer: colors.ink,
    secondary: colors.orange,
    onSecondary: brightness == Brightness.dark ? colors.canvas : Colors.white,
    secondaryContainer: colors.orangeSoft,
    onSecondaryContainer: colors.ink,
    tertiary: colors.teal,
    onTertiary: brightness == Brightness.dark ? colors.canvas : Colors.white,
    tertiaryContainer: colors.tealSoft,
    onTertiaryContainer: colors.ink,
    surface: colors.surface,
    onSurface: colors.ink,
    surfaceContainerLowest: colors.surface,
    surfaceContainerLow: colors.canvas,
    surfaceContainerHighest: colors.field,
    onSurfaceVariant: colors.textSecondary,
    outline: colors.textSecondary,
    outlineVariant: colors.borderColor,
    error: colors.error,
  );
}

TextTheme buildAppTextTheme(AppPalette colors) => TextTheme(
  headlineMedium: const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -.6,
    height: 1.3,
  ),
  headlineSmall: const TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: -.3,
    height: 1.35,
  ),
  titleLarge: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -.2,
  ),
  titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  bodyLarge: const TextStyle(fontSize: 15, height: 1.5),
  bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
  bodySmall: TextStyle(fontSize: 12, height: 1.4, color: colors.textSecondary),
  labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
);
