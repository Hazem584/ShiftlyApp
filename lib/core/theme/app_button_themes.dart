import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_dimensions.dart';
import 'package:shiftly/core/theme/app_palette.dart';

const _radius = BorderRadius.all(Radius.circular(AppRadii.m));

SegmentedButtonThemeData buildSegmentedButtonTheme(AppPalette colors) =>
    SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.selected
              : colors.surface,
        ),
        foregroundColor: WidgetStatePropertyAll(colors.ink),
        side: WidgetStatePropertyAll(BorderSide(color: colors.borderColor)),
      ),
    );

ElevatedButtonThemeData buildElevatedButtonTheme() => ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(48),
    shape: const RoundedRectangleBorder(borderRadius: _radius),
  ),
);

FilledButtonThemeData buildFilledButtonTheme(
  AppPalette colors,
  ColorScheme colorScheme,
) => FilledButtonThemeData(
  style: FilledButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    disabledBackgroundColor: colors.field,
    disabledForegroundColor: colors.textSecondary,
    minimumSize: const Size(48, 48),
    shape: const RoundedRectangleBorder(borderRadius: _radius),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
    textStyle: const TextStyle(
      fontFamily: 'Cairo',
      fontWeight: FontWeight.w800,
      fontSize: 15,
    ),
  ),
);

OutlinedButtonThemeData buildOutlinedButtonTheme(AppPalette colors) =>
    OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.ink,
        side: BorderSide(color: colors.borderColor),
        minimumSize: const Size(48, 48),
        shape: const RoundedRectangleBorder(borderRadius: _radius),
      ),
    );

TextButtonThemeData buildTextButtonTheme(AppPalette colors) =>
    TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primaryColor,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
