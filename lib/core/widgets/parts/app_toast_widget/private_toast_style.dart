part of '../../app_toast_widget.dart';

class _ToastStyle {
  const _ToastStyle({
    required this.icon,
    required this.accent,
    required this.background,
  });

  final IconData icon;
  final Color accent;
  final Color background;

  factory _ToastStyle.forType(ToastType type) => switch (type) {
    ToastType.success => const _ToastStyle(
      icon: Icons.check_circle_rounded,
      accent: AppColors.success,
      background: Color(0xFFF0FFF6),
    ),
    ToastType.error => const _ToastStyle(
      icon: Icons.error_rounded,
      accent: AppColors.error,
      background: Color(0xFFFFF3F2),
    ),
    ToastType.warning => const _ToastStyle(
      icon: Icons.warning_amber_rounded,
      accent: AppColors.warning,
      background: Color(0xFFFFFAE8),
    ),
    ToastType.info => const _ToastStyle(
      icon: Icons.info_rounded,
      accent: AppColors.info,
      background: Color(0xFFF0F9FF),
    ),
  };
}
