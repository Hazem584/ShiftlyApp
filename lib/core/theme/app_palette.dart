import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/manager/presentation/design/manager_theme_marker.dart';

/// Semantic colors for custom widgets that cannot inherit Material defaults.
class AppPalette {
  const AppPalette(this.brightness, {this.manager = false});
  final bool manager;
  final Brightness brightness;
  bool get _dark => brightness == Brightness.dark;
  static AppPalette of(BuildContext context) => AppPalette(
    Theme.of(context).brightness,
    manager: Theme.of(context).extension<ManagerThemeMarker>() != null,
  );
  Color get ink => manager
      ? (_dark ? const Color(0xFFF2F4FC) : const Color(0xFF17213C))
      : _dark
      ? const Color(0xFFEDF6F8)
      : AppColors.ink;
  Color get black => ink;
  Color get primaryColor => manager
      ? (_dark ? const Color(0xFFB1A7FF) : const Color(0xFF4338CA))
      : _dark
      ? const Color(0xFF3ED6C3)
      : AppColors.primaryColor;
  Color get canvas => manager
      ? (_dark ? const Color(0xFF101426) : const Color(0xFFF7F8FC))
      : _dark
      ? const Color(0xFF0B1014)
      : AppColors.canvas;
  Color get surface => manager
      ? (_dark ? const Color(0xFF1C233A) : const Color(0xFFFFFFFF))
      : _dark
      ? const Color(0xFF131C22)
      : AppColors.surface;
  Color get field => manager
      ? (_dark ? const Color(0xFF1C233A) : const Color(0xFFFFFFFF))
      : _dark
      ? const Color(0xFF19252C)
      : AppColors.field;
  Color get selected => manager
      ? (_dark ? const Color(0xFF302B54) : const Color(0xFFECEBFF))
      : _dark
      ? const Color(0xFF153935)
      : AppColors.selected;
  Color get textSecondary => manager
      ? (_dark ? const Color(0xFFB2BDD4) : const Color(0xFF657087))
      : _dark
      ? const Color(0xFFA0B4BF)
      : AppColors.textSecondary;
  Color get lightGray => textSecondary;
  Color get lighterGray => manager
      ? (_dark ? const Color(0xFFB2BDD4) : const Color(0xFF657087))
      : _dark
      ? const Color(0xFF8096A2)
      : AppColors.lighterGray;
  Color get borderColor => manager
      ? (_dark ? const Color(0xFF36415C) : const Color(0xFFE1E5EF))
      : _dark
      ? const Color(0xFF223139)
      : AppColors.borderColor;
  Color get success => manager
      ? (_dark ? const Color(0xFF88E3BF) : const Color(0xFF116B57))
      : _dark
      ? const Color(0xFF3ED6C3)
      : AppColors.success;
  Color get successSoft => manager
      ? (_dark ? const Color(0xFF163D35) : const Color(0xFFDCF5EA))
      : _dark
      ? const Color(0xFF123630)
      : AppColors.successSoft;
  Color get warning => manager
      ? (_dark ? const Color(0xFFFFD08B) : const Color(0xFF8A5108))
      : _dark
      ? const Color(0xFFFFD46B)
      : AppColors.warning;
  Color get warningSoft => manager
      ? (_dark ? const Color(0xFF45331E) : const Color(0xFFFFF1D9))
      : _dark
      ? const Color(0xFF433820)
      : AppColors.warningSoft;
  Color get error => manager
      ? (_dark ? const Color(0xFFFFA7B3) : const Color(0xFFB73748))
      : _dark
      ? const Color(0xFFFF938A)
      : AppColors.error;
  Color get errorSoft => manager
      ? (_dark ? const Color(0xFF482532) : const Color(0xFFFCE9EC))
      : _dark
      ? const Color(0xFF472725)
      : const Color(0xFFFFE4E1);
  Color get brandBackground => manager
      ? (_dark ? const Color(0xFF202945) : const Color(0xFF141B36))
      : const Color(0xFF112A2C);
  Color get brandGradientEnd => manager
      ? (_dark ? const Color(0xFF202945) : const Color(0xFF141B36))
      : AppColors.inkMuted;
  Color get info => manager
      ? (_dark ? const Color(0xFFB1A7FF) : const Color(0xFF4338CA))
      : _dark
      ? const Color(0xFF78CBF6)
      : AppColors.info;
  Color get orange => manager
      ? (_dark ? const Color(0xFFFFD08B) : const Color(0xFF8A5108))
      : _dark
      ? const Color(0xFFFFAB80)
      : AppColors.orange;
  Color get orangeSoft => manager
      ? (_dark ? const Color(0xFF45331E) : const Color(0xFFFFF1D9))
      : _dark
      ? const Color(0xFF392D20)
      : AppColors.orangeSoft;
  Color get teal => manager
      ? (_dark ? const Color(0xFF88E3BF) : const Color(0xFF116B57))
      : _dark
      ? const Color(0xFF3ED6C3)
      : AppColors.teal;
  Color get tealSoft => manager
      ? (_dark ? const Color(0xFF163D35) : const Color(0xFFDCF5EA))
      : _dark
      ? const Color(0xFF153935)
      : AppColors.tealSoft;
  Color get inkMuted => _dark ? const Color(0xFF102024) : AppColors.inkMuted;
  Color get purpleSoft => manager
      ? (_dark ? const Color(0xFF302B54) : const Color(0xFFECEBFF))
      : _dark
      ? const Color(0xFF29353F)
      : AppColors.purpleSoft;
  Color get lightGreen => success;
  Color get secondaryColor => success;
}
