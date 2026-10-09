import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';
import 'package:shiftly/core/theme/app_theme.dart';

import '../../domain/onboarding_page_content.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../widgets/onboarding_illustration.dart';
import '../widgets/onboarding_page_indicator.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => Theme(
    data: MediaQuery.platformBrightnessOf(context) == Brightness.dark
        ? ThemeData(
            useMaterial3: true,
            fontFamily: 'Cairo',
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.seedColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF080414),
          )
        : AppTheme.lightTheme(),
    child: BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        final page = OnboardingPageContent.pages[state.page];
        final last = state.page == OnboardingPageContent.pages.length - 1;
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const BrandLogo(),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Shiftly',
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
                                child: const Text('Skip'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            child: Column(
                              key: ValueKey(state.page),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OnboardingIllustration(content: page),
                                const SizedBox(height: 28),
                                Text(
                                  page.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.description,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          OnboardingPageIndicator(
                            page: state.page,
                            count: OnboardingPageContent.pages.length,
                          ),
                          const SizedBox(height: 24),
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
                              child: const Text('Retry preference check'),
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
                              state.saving
                                  ? 'Saving…'
                                  : last
                                  ? 'Get Started'
                                  : 'Next',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
