import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_button_themes.dart';
import 'package:shiftly/core/theme/app_color_scheme.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_form_themes.dart';
import 'package:shiftly/core/theme/app_navigation_themes.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_surface_themes.dart';

export 'package:shiftly/core/theme/app_dimensions.dart';

class AppTheme {
  static const Color seedColor = AppColors.primaryColor;

  static ThemeData lightTheme() => _theme(Brightness.light);
  static ThemeData darkTheme() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colors = AppPalette(brightness);
    final colorScheme = buildAppColorScheme(brightness, colors);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.canvas,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      brightness: brightness,
      textTheme: buildAppTextTheme(colors),
      appBarTheme: buildAppBarTheme(colors),
      inputDecorationTheme: buildInputDecorationTheme(colors),
      datePickerTheme: buildDatePickerTheme(colors, colorScheme),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: colors.ink, fontFamily: 'Cairo'),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(
          color: colors.ink,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: TextStyle(color: colors.ink, fontFamily: 'Cairo'),
      ),
      cardTheme: buildCardTheme(colors),
      chipTheme: buildChipTheme(colors),
      navigationBarTheme: buildNavigationBarTheme(colors),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryColor,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
      dialogTheme: buildDialogTheme(colors),
      snackBarTheme: buildSnackBarTheme(colorScheme),
      dividerTheme: DividerThemeData(color: colors.borderColor, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: colors.ink,
        minVerticalPadding: 10,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colors.ink,
        ),
      ),
      bottomSheetTheme: buildBottomSheetTheme(colors),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primaryColor,
        linearTrackColor: colors.field,
      ),
      tooltipTheme: buildTooltipTheme(colorScheme),
      segmentedButtonTheme: buildSegmentedButtonTheme(colors),
      tabBarTheme: buildTabBarTheme(colors),
      navigationRailTheme: buildNavigationRailTheme(colors),
      elevatedButtonTheme: buildElevatedButtonTheme(),
      filledButtonTheme: buildFilledButtonTheme(colors, colorScheme),
      outlinedButtonTheme: buildOutlinedButtonTheme(colors),
      textButtonTheme: buildTextButtonTheme(colors),
    );
  }
}
