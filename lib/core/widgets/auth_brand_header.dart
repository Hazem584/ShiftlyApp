import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(
        height: 88,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            BrandLogo(size: 88),
            PositionedDirectional(end: 0, top: 0, child: LanguageSelector()),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      Text(
        context.tr(title),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 8),
      Text(
        context.tr(subtitle),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textSecondary,
          height: 1.45,
          fontSize: 14,
        ),
      ),
    ],
  );
}
