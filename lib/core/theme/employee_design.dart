import 'package:flutter/material.dart';

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
    final text = base.textTheme
        .apply(
          fontFamily: arabic ? 'Cairo' : 'InterTight',
          bodyColor: ink,
          displayColor: ink,
        )
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
        .apply(fontFamily: arabic ? 'Cairo' : 'InterTight');
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return base.copyWith(
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
          fontFamily: arabic ? 'Cairo' : 'InterTight',
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerForegroundColor: ink,
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : states.contains(WidgetState.disabled)
              ? muted
              : ink,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        weekdayStyle: TextStyle(color: muted),
        yearForegroundColor: WidgetStatePropertyAll(ink),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 52),
          shape: shape,
          textStyle: TextStyle(
            fontFamily: arabic ? 'Cairo' : 'InterTight',
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: selected,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: arabic ? 'Cairo' : 'InterTight',
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
          fontFamily: arabic ? 'Cairo' : 'InterTight',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
        shape: const StadiumBorder(),
      ),
    );
  }
}
