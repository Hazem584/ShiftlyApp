import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/employee_design.dart';

/// Semantic colors for custom widgets that cannot inherit Material defaults.
class AppPalette {
  const AppPalette(this.brightness);
  final Brightness brightness;
  bool get _dark => brightness == Brightness.dark;
  static AppPalette of(BuildContext context) => EmployeeDesign.applies(context)
      ? _EmployeePalette(Theme.of(context).brightness)
      : AppPalette(Theme.of(context).brightness);
  Color get ink => _dark ? const Color(0xFFEDF6F8) : AppColors.ink;
  Color get black => ink;
  Color get primaryColor =>
      _dark ? const Color(0xFF3ED6C3) : AppColors.primaryColor;
  Color get canvas => _dark ? const Color(0xFF0B1014) : AppColors.canvas;
  Color get surface => _dark ? const Color(0xFF131C22) : AppColors.surface;
  Color get field => _dark ? const Color(0xFF19252C) : AppColors.field;
  Color get selected => _dark ? const Color(0xFF153935) : AppColors.selected;
  Color get textSecondary =>
      _dark ? const Color(0xFFA0B4BF) : AppColors.textSecondary;
  Color get lightGray => textSecondary;
  Color get lighterGray =>
      _dark ? const Color(0xFF8096A2) : AppColors.lighterGray;
  Color get borderColor =>
      _dark ? const Color(0xFF223139) : AppColors.borderColor;
  Color get success => _dark ? const Color(0xFF3ED6C3) : AppColors.success;
  Color get successSoft =>
      _dark ? const Color(0xFF123630) : AppColors.successSoft;
  Color get warning => _dark ? const Color(0xFFFFD46B) : AppColors.warning;
  Color get warningSoft =>
      _dark ? const Color(0xFF433820) : AppColors.warningSoft;
  Color get error => _dark ? const Color(0xFFFF938A) : AppColors.error;
  Color get errorSoft =>
      _dark ? const Color(0xFF472725) : const Color(0xFFFFE4E1);
  Color get brandBackground => const Color(0xFF112A2C);
  Color get brandGradientEnd => AppColors.inkMuted;
  Color get info => _dark ? const Color(0xFF78CBF6) : AppColors.info;
  Color get orange => _dark ? const Color(0xFFFFAB80) : AppColors.orange;
  Color get orangeSoft =>
      _dark ? const Color(0xFF392D20) : AppColors.orangeSoft;
  Color get teal => _dark ? const Color(0xFF3ED6C3) : AppColors.teal;
  Color get tealSoft => _dark ? const Color(0xFF153935) : AppColors.tealSoft;
  Color get inkMuted => _dark ? const Color(0xFF102024) : AppColors.inkMuted;
  Color get purpleSoft =>
      _dark ? const Color(0xFF29353F) : AppColors.purpleSoft;
  Color get lightGreen => success;
  Color get secondaryColor => success;
}

class _EmployeePalette extends AppPalette {
  const _EmployeePalette(super.brightness);
  @override
  Color get ink => _dark ? const Color(0xFFF2F4FC) : const Color(0xFF17213C);
  @override
  Color get primaryColor =>
      _dark ? const Color(0xFFB1A7FF) : const Color(0xFF4338CA);
  @override
  Color get canvas => _dark ? const Color(0xFF101426) : const Color(0xFFF7F8FC);
  @override
  Color get surface => _dark ? const Color(0xFF1C233A) : Colors.white;
  @override
  Color get field => surface;
  @override
  Color get selected =>
      _dark ? const Color(0xFF30285B) : const Color(0xFFEDEBFF);
  @override
  Color get textSecondary =>
      _dark ? const Color(0xFFB2BDD4) : const Color(0xFF657087);
  @override
  Color get borderColor =>
      _dark ? const Color(0xFF303B57) : const Color(0xFFE1E5EF);
  @override
  Color get success =>
      _dark ? const Color(0xFF88E3BF) : const Color(0xFF116B57);
  @override
  Color get successSoft =>
      _dark ? const Color(0xFF163D35) : const Color(0xFFDCF5EA);
}
