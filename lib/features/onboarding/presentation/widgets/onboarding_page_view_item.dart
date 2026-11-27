import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_illustration.dart';

class OnboardingPageViewItem extends StatelessWidget {
  const OnboardingPageViewItem({required this.page, super.key});
  final OnboardingPageContent page;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingIllustration(content: page),
        const SizedBox(height: 24),
        Text(
          context.tr(page.title),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          context.tr(page.description),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
