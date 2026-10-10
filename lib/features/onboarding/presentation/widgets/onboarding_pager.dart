import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:shiftly/features/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_illustration.dart';

class OnboardingPager extends StatefulWidget {
  const OnboardingPager({super.key});

  @override
  State<OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<OnboardingPager> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: context.read<OnboardingCubit>().state.page,
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<OnboardingCubit, OnboardingState>(
        listenWhen: (previous, current) => previous.page != current.page,
        listener: (context, state) {
          if (!_controller.hasClients ||
              _controller.page?.round() == state.page) {
            return;
          }
          if (MediaQuery.disableAnimationsOf(context)) {
            _controller.jumpToPage(state.page);
          } else {
            _controller.animateToPage(
              state.page,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            );
          }
        },
        builder: (context, state) => SizedBox(
          height: (MediaQuery.sizeOf(context).height - 300).clamp(360, 640),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              key: const Key('onboarding-pager'),
              controller: _controller,
              physics: state.saving || state.loading
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: context.read<OnboardingCubit>().showPage,
              itemCount: OnboardingPageContent.pages.length,
              itemBuilder: (context, index) {
                final page = OnboardingPageContent.pages[index];
                return SingleChildScrollView(
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
              },
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
