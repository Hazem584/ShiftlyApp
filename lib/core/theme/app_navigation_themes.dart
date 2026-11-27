import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_dimensions.dart';
import 'package:shiftly/core/theme/app_palette.dart';

NavigationBarThemeData buildNavigationBarTheme(AppPalette colors) =>
    NavigationBarThemeData(
      height: 66,
      backgroundColor: colors.surface,
      indicatorColor: colors.selected,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? colors.ink
              : colors.textSecondary,
        ),
      ),
    );

TabBarThemeData buildTabBarTheme(AppPalette colors) => TabBarThemeData(
  indicatorSize: TabBarIndicatorSize.label,
  labelColor: colors.primaryColor,
  unselectedLabelColor: colors.textSecondary,
  dividerColor: colors.borderColor,
  labelStyle: const TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w800,
    fontSize: 13,
  ),
  unselectedLabelStyle: const TextStyle(
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w600,
    fontSize: 13,
  ),
);

NavigationRailThemeData buildNavigationRailTheme(AppPalette colors) =>
    NavigationRailThemeData(
      backgroundColor: colors.surface,
      selectedIconTheme: IconThemeData(color: colors.primaryColor),
      unselectedIconTheme: IconThemeData(color: colors.textSecondary),
      selectedLabelTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        color: colors.ink,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 12,
        color: colors.textSecondary,
      ),
    );

TooltipThemeData buildTooltipTheme(ColorScheme colorScheme) => TooltipThemeData(
  decoration: BoxDecoration(
    color: colorScheme.inverseSurface,
    borderRadius: BorderRadius.circular(AppRadii.s),
  ),
  textStyle: TextStyle(
    fontFamily: 'Cairo',
    color: colorScheme.onInverseSurface,
    fontSize: 12,
  ),
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
);
