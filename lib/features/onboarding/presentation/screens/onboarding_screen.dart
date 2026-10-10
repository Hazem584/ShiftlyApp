import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/theme/theme_selector.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:shiftly/features/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_page_indicator.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_pager.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
          final last = state.page == OnboardingPageContent.pages.length - 1;
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const BrandLogo(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.tr('Shiftly'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            TextButton(
                              onPressed: state.saving || state.loading
                                  ? null
                                  : cubit.complete,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              child: Text(context.tr('Skip')),
                            ),
                            const LanguageSelector(),
                            const ThemeSelector(),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Expanded(child: OnboardingPager()),
                        const SizedBox(height: 12),
                        OnboardingPageIndicator(
                          page: state.page,
                          count: OnboardingPageContent.pages.length,
                          onSelect: state.saving || state.loading
                              ? null
                              : cubit.showPage,
                        ),
                        const SizedBox(height: 12),
                        if (state.error != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              state.error!,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          TextButton(
                            onPressed: state.saving || state.loading
                                ? null
                                : cubit.restore,
                            child: Text(context.tr('Retry preference check')),
                          ),
                          const SizedBox(height: 12),
                        ],
                        FilledButton(
                          onPressed: state.loading || state.saving
                              ? null
                              : last
                              ? cubit.complete
                              : () => cubit.showPage(state.page + 1),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 56),
                          ),
                          child: Text(
                            context.tr(
                              state.saving
                                  ? 'Saving…'
                                  : last
                                  ? 'Get Started'
                                  : 'Next',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
