import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/theme/theme_selector.dart';
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
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF153935),
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: BrandLogo(size: 64),
              ),
            ),
            PositionedDirectional(end: 0, top: 0, child: LanguageSelector()),
            PositionedDirectional(start: 0, top: 0, child: ThemeSelector()),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.m),
      Text(
        context.tr(title),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontSize: 28, height: 1.15),
      ),
      const SizedBox(height: 8),
      Text(
        context.tr(subtitle),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppPalette.of(context).textSecondary,
          height: 1.45,
          fontSize: 14,
        ),
      ),
    ],
  );
}
