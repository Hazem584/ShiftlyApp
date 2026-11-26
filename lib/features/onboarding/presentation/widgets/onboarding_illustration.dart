import 'package:flutter/material.dart';
import 'package:shiftly/features/onboarding/presentation/models/onboarding_page_content.dart';

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({required this.content, super.key});
  final OnboardingPageContent content;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        height: (MediaQuery.sizeOf(context).height * 0.32).clamp(145.0, 276.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(content.icon, size: 84, color: colors.onPrimaryContainer),
      ),
    );
  }
}
