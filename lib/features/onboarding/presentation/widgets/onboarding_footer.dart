import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:shiftly/features/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_page_indicator.dart';

class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({required this.cubit, required this.state, super.key});
  final OnboardingCubit cubit;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final busy = state.saving || state.loading;
    final last = state.page == OnboardingPageContent.pages.length - 1;
    final label = state.saving
        ? 'Saving…'
        : last
        ? 'Get Started'
        : 'Next';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingPageIndicator(
          page: state.page,
          count: OnboardingPageContent.pages.length,
          onSelect: busy ? null : cubit.showPage,
        ),
        const SizedBox(height: 12),
        if (state.error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(state.error!, textAlign: TextAlign.center),
          ),
          TextButton(
            onPressed: busy ? null : cubit.restore,
            child: Text(context.tr('Retry preference check')),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: busy
              ? null
              : last
              ? cubit.complete
              : () => cubit.showPage(state.page + 1),
          style: FilledButton.styleFrom(minimumSize: const Size(48, 56)),
          child: Text(context.tr(label)),
        ),
      ],
    );
  }
}
