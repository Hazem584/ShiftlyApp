import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';

enum ToastType { success, error, warning, info }

class AppToastWidget extends StatelessWidget {
  const AppToastWidget({
    required this.message,
    required this.type,
    this.onClose,
    super.key,
  });

  final String message;
  final ToastType type;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final style = _ToastStyle.forType(type, colors);
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.background,
          border: Border.all(color: style.accent.withValues(alpha: .22)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22080414),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, color: style.accent, size: 21),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              if (onClose != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onClose,
                  tooltip: context.tr('Dismiss'),
                  color: colors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToastStyle {
  const _ToastStyle({
    required this.icon,
    required this.accent,
    required this.background,
  });

  final IconData icon;
  final Color accent;
  final Color background;

  factory _ToastStyle.forType(ToastType type, AppPalette colors) {
    final dark = colors.brightness == Brightness.dark;
    final (icon, accent, lightBackground) = switch (type) {
      ToastType.success => (
        Icons.check_circle_rounded,
        colors.success,
        const Color(0xFFF0FFF6),
      ),
      ToastType.error => (
        Icons.error_rounded,
        colors.error,
        const Color(0xFFFFF3F2),
      ),
      ToastType.warning => (
        Icons.warning_amber_rounded,
        dark ? colors.warning : const Color(0xFF946800),
        const Color(0xFFFFFAE8),
      ),
      ToastType.info => (
        Icons.info_rounded,
        dark ? colors.info : const Color(0xFF087AB0),
        const Color(0xFFF0F9FF),
      ),
    };
    return _ToastStyle(
      icon: icon,
      accent: accent,
      background: dark
          ? Color.alphaBlend(accent.withValues(alpha: .12), colors.surface)
          : lightBackground,
    );
  }
}
