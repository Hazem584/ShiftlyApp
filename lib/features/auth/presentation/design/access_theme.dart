import 'package:flutter/material.dart';

import 'access_tokens.dart';

class AccessTheme extends StatelessWidget {
  const AccessTheme({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final canvas = dark ? AccessTokens.darkCanvas : AccessTokens.canvas;
    final ink = dark ? AccessTokens.darkInk : AccessTokens.ink;
    final primary = dark ? AccessTokens.darkPrimary : AccessTokens.primary;
    final surface = dark ? AccessTokens.darkSurface : Colors.white;
    final line = dark ? AccessTokens.darkLine : AccessTokens.line;
    final muted = dark ? AccessTokens.darkMuted : AccessTokens.muted;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: dark ? AccessTokens.darkCanvas : Colors.white,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: muted,
          outline: line,
          primaryContainer: dark ? const Color(0xFF2B2753) : AccessTokens.soft,
          onPrimaryContainer: primary,
          error: dark ? const Color(0xFFFFB2BD) : const Color(0xFFB73748),
        );
    final family = arabic ? 'AccessArabic' : 'AccessInter';
    final text = ThemeData(fontFamily: family).textTheme
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          headlineLarge: TextStyle(
            fontFamily: family,
            color: ink,
            fontSize: arabic ? 32 : 38,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            fontFamily: family,
            color: ink,
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            fontFamily: family,
            color: ink,
            fontSize: 22,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: TextStyle(
            fontFamily: family,
            color: ink,
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontFamily: family,
            color: ink,
            fontSize: 16,
            height: arabic ? 1.4 : 1.25,
          ),
          bodyMedium: TextStyle(
            fontFamily: family,
            color: ink,
            fontSize: 15,
            height: arabic ? 1.4 : 1.25,
          ),
          bodySmall: TextStyle(
            fontFamily: family,
            color: muted,
            fontSize: 14,
            height: 1.25,
          ),
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: line),
    );
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: family,
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: canvas,
        textTheme: text,
        canvasColor: canvas,
        dividerColor: line,
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: primary,
          linearTrackColor: line,
        ),
        iconTheme: IconThemeData(color: muted, size: 24),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: border.copyWith(
            borderSide: BorderSide(color: scheme.error),
          ),
          focusedErrorBorder: border.copyWith(
            borderSide: BorderSide(color: scheme.error, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: text.bodyLarge?.copyWith(color: muted),
          errorMaxLines: 3,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: button.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? primary.withValues(alpha: .35)
                  : primary,
            ),
            foregroundColor: WidgetStatePropertyAll(scheme.onPrimary),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(style: button),
        textButtonTheme: TextButtonThemeData(
          style: button.copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: text.titleLarge,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: canvas,
          modalBackgroundColor: canvas,
        ),
      ),
      child: child,
    );
  }
}
