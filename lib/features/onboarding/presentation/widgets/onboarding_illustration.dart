import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';

import '../../domain/onboarding_page_content.dart';

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({required this.content, super.key});
  final OnboardingPageContent content;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.orangeSoft.withValues(alpha: .9),
            colors.surfaceContainerLow,
          ],
        ),
      ),
      child: Column(
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Icon(content.icon, size: 48, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final feature in content.features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.m),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(feature.$1, color: AppColors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature.$2,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
