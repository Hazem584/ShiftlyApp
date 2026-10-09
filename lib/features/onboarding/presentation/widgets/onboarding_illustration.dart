import 'package:flutter/material.dart';

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
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surfaceContainerLow],
        ),
      ),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Icon(
              content.icon,
              size: 64,
              color: colors.onPrimaryContainer,
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(feature.$1, color: colors.primary),
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
