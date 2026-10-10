import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';

/// Semantic colors for custom widgets that cannot inherit Material defaults.
class AppPalette {
  const AppPalette(this.brightness);
  final Brightness brightness;
  bool get _dark => brightness == Brightness.dark;
  static AppPalette of(BuildContext context) =>
      AppPalette(Theme.of(context).brightness);
  Color get ink => _dark ? const Color(0xFFF1ECFA) : AppColors.ink;
  Color get black => ink;
  Color get primaryColor =>
      _dark ? const Color(0xFF9D7DFF) : AppColors.primaryColor;
  Color get canvas => _dark ? const Color(0xFF121019) : AppColors.canvas;
  Color get surface => _dark ? const Color(0xFF1C1925) : AppColors.surface;
  Color get field => _dark ? const Color(0xFF292432) : AppColors.field;
  Color get selected => _dark ? const Color(0xFF3C2C4F) : AppColors.selected;
  Color get textSecondary =>
      _dark ? const Color(0xFFC0B7CE) : AppColors.textSecondary;
  Color get lightGray => textSecondary;
  Color get lighterGray =>
      _dark ? const Color(0xFF9D94AC) : AppColors.lighterGray;
  Color get borderColor =>
      _dark ? const Color(0xFF3D354B) : AppColors.borderColor;
  Color get success => _dark ? const Color(0xFF72DFA2) : AppColors.success;
  Color get successSoft =>
      _dark ? const Color(0xFF183D2B) : AppColors.successSoft;
  Color get warning => _dark ? const Color(0xFFFFD46B) : AppColors.warning;
  Color get warningSoft =>
      _dark ? const Color(0xFF433820) : AppColors.warningSoft;
  Color get error => _dark ? const Color(0xFFFF938A) : AppColors.error;
  Color get errorSoft =>
      _dark ? const Color(0xFF472725) : const Color(0xFFFFE4E1);
  Color get brandBackground => AppColors.ink;
  Color get brandGradientEnd => AppColors.inkMuted;
  Color get info => _dark ? const Color(0xFF78CBF6) : AppColors.info;
  Color get orange => _dark ? const Color(0xFFFFAB80) : AppColors.orange;
  Color get orangeSoft =>
      _dark ? const Color(0xFF442C23) : AppColors.orangeSoft;
  Color get teal => _dark ? const Color(0xFF72DED2) : AppColors.teal;
  Color get tealSoft => _dark ? const Color(0xFF173E3C) : AppColors.tealSoft;
  Color get inkMuted => _dark ? const Color(0xFF211B30) : AppColors.inkMuted;
  Color get purpleSoft =>
      _dark ? const Color(0xFF352642) : AppColors.purpleSoft;
  Color get lightGreen => success;
  Color get secondaryColor => success;
}
