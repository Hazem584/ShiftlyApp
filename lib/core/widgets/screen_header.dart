import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    required this.subtitle,
    this.icon,
    this.action,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stackAction =
          action != null &&
          (constraints.maxWidth < 420 ||
              MediaQuery.textScalerOf(context).scale(14) > 20);
      final heading = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(AppRadii.m),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: AppColors.orange, size: 22),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(title),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  context.tr(subtitle),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (action != null && !stackAction) ...[
            const SizedBox(width: AppSpacing.s),
            action!,
          ],
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading,
          if (stackAction) ...[
            const SizedBox(height: AppSpacing.s),
            Align(alignment: AlignmentDirectional.centerEnd, child: action!),
          ],
        ],
      );
    },
  );
}
