import 'package:flutter/material.dart';

import 'employee_controls_theme.dart';
import 'employee_navigation_theme.dart';
import 'employee_typography.dart';

/// Tokens from the Employee boards in the approved Penpot file.
class EmployeeDesign extends ThemeExtension<EmployeeDesign> {
  const EmployeeDesign();
  static bool applies(BuildContext context) =>
      Theme.of(context).extension<EmployeeDesign>() != null;
  static const hero = Color(0xFF141B36);
  static const heroDark = Color(0xFF202945);
  static const heroText = Color(0xFFC7CEED);
  static const mint = Color(0xFFA9F1D8);
  @override
  EmployeeDesign copyWith() => this;
  @override
  EmployeeDesign lerp(covariant EmployeeDesign? other, double t) => this;

  static ThemeData theme(ThemeData base, {required bool arabic}) {
    final dark = base.brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFF2F4FC) : const Color(0xFF17213C);
    final muted = dark ? const Color(0xFFB2BDD4) : const Color(0xFF657087);
    final canvas = dark ? const Color(0xFF101426) : const Color(0xFFF7F8FC);
    final surface = dark ? const Color(0xFF1C233A) : Colors.white;
    final primary = dark ? const Color(0xFFB1A7FF) : const Color(0xFF4338CA);
    final selected = dark ? const Color(0xFF30285B) : const Color(0xFFEDEBFF);
    final border = dark ? const Color(0xFF303B57) : const Color(0xFFE1E5EF);
    final scheme = base.colorScheme.copyWith(
      primary: primary,
      onPrimary: dark ? canvas : Colors.white,
      primaryContainer: selected,
      onPrimaryContainer: primary,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: muted,
      outlineVariant: border,
      surfaceContainerLow: canvas,
      surfaceContainerHighest: selected,
    );
    final fontFamily = arabic ? 'Cairo' : 'InterTight';
    final text = employeeTypography(base.textTheme, ink, muted, fontFamily);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final themed = base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: text,
      extensions: [
        ...base.extensions.values.where((e) => e is! EmployeeDesign),
        const EmployeeDesign(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          fontSize: 23,
          fontFamily: fontFamily,
        ),
      ),
      datePickerTheme: employeeDatePickerTheme(scheme),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      navigationBarTheme: employeeNavigationTheme(scheme, fontFamily),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: selected,
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: primary,
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
        shape: const StadiumBorder(),
      ),
    );
    return employeeControlsTheme(themed, shape, fontFamily);
  }
}
