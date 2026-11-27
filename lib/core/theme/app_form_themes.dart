import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_dimensions.dart';
import 'package:shiftly/core/theme/app_palette.dart';

const _radius = BorderRadius.all(Radius.circular(AppRadii.m));

AppBarTheme buildAppBarTheme(AppPalette colors) => AppBarTheme(
  backgroundColor: colors.canvas,
  foregroundColor: colors.ink,
  elevation: 0,
  scrolledUnderElevation: 0,
  centerTitle: false,
  titleTextStyle: TextStyle(
    fontFamily: 'Cairo',
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: colors.ink,
  ),
);

InputDecorationTheme buildInputDecorationTheme(AppPalette colors) =>
    InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: 14,
      ),
      hintStyle: TextStyle(color: colors.lighterGray),
      helperStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
      prefixIconColor: colors.textSecondary,
      border: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: colors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: colors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: colors.primaryColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: colors.error),
      ),
    );

DatePickerThemeData buildDatePickerTheme(
  AppPalette colors,
  ColorScheme colorScheme,
) {
  final dateForeground = WidgetStateProperty.resolveWith<Color>((states) {
    if (states.contains(WidgetState.disabled)) return colors.textSecondary;
    if (states.contains(WidgetState.selected)) return colorScheme.onPrimary;
    return colors.ink;
  });
  return DatePickerThemeData(
    backgroundColor: colors.surface,
    headerForegroundColor: colors.ink,
    dayForegroundColor: dateForeground,
    yearForegroundColor: dateForeground,
  );
}
