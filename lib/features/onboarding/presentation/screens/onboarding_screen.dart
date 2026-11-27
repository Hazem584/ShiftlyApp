import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/localization/language_selector.dart';
import 'package:shiftly/core/theme/theme_selector.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_footer.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_pager.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
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
                            const BrandLogo(size: 36),
                            const Spacer(),
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
                        OnboardingFooter(cubit: cubit, state: state),
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
