import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_palette.dart';

class AppTheme {
  static const Color seedColor = AppColors.ink;

  static ThemeData lightTheme() => _theme(Brightness.light);
  static ThemeData darkTheme() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colors = AppPalette(brightness);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        ).copyWith(
          primary: colors.primaryColor,
          onPrimary: brightness == Brightness.dark
              ? Color(0xFF1B1035)
              : Colors.white,
          primaryContainer: colors.selected,
          onPrimaryContainer: colors.ink,
          secondary: colors.orange,
          onSecondary: brightness == Brightness.dark
              ? colors.canvas
              : Colors.white,
          secondaryContainer: colors.orangeSoft,
          onSecondaryContainer: colors.ink,
          tertiary: colors.teal,
          onTertiary: brightness == Brightness.dark
              ? colors.canvas
              : Colors.white,
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

    const radius = BorderRadius.all(Radius.circular(AppRadii.m));

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.canvas,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      brightness: brightness,
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
          height: 1.15,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -.2,
        ),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: colors.textSecondary,
        ),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
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
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: colors.lighterGray),
        helperStyle: TextStyle(color: colors.textSecondary, fontSize: 12),
        prefixIconColor: colors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.orange, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.borderColor),
          borderRadius: BorderRadius.circular(AppRadii.l),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.field,
        selectedColor: colors.selected,
        side: BorderSide(color: colors.borderColor),
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
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
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.orange,
        foregroundColor: colorScheme.onSecondary,
        elevation: 2,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.l),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.borderColor, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: colors.ink,
        minVerticalPadding: 12,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(48, 48),
          foregroundColor: colors.ink,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        showDragHandle: true,
        dragHandleColor: colors.borderColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.orange,
        linearTrackColor: colors.field,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadii.s),
        ),
        textStyle: TextStyle(
          fontFamily: 'Cairo',
          color: colorScheme.onInverseSurface,
          fontSize: 12,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(48, 48)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.selected
                : colors.surface,
          ),
          foregroundColor: WidgetStatePropertyAll(colors.ink),
          side: WidgetStatePropertyAll(BorderSide(color: colors.borderColor)),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        selectedIconTheme: IconThemeData(color: colors.ink),
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
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colors.field,
          disabledForegroundColor: colors.textSecondary,
          minimumSize: Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.m),
          textStyle: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.borderColor),
          minimumSize: Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.orange,
          minimumSize: Size(48, 48),
          textStyle: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 6;
  static const double s = 12;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

class AppRadii {
  static const double s = 12;
  static const double m = 16;
  static const double l = 20;
  static const double xl = 28;
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(color: Color(0x14080414), blurRadius: 28, offset: Offset(0, 10)),
  ];
}
