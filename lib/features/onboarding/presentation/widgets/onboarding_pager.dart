import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shiftly/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:shiftly/features/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:shiftly/features/onboarding/presentation/widgets/onboarding_page_view_item.dart';

class OnboardingPager extends StatefulWidget {
  const OnboardingPager({super.key});
  @override
  State<OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<OnboardingPager> {
  late final _controller = PageController(
    initialPage: context.read<OnboardingCubit>().state.page,
  );
  static const _devices = {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };

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
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(dragDevices: _devices),
            child: PageView.builder(
              key: const Key('onboarding-pager'),
              controller: _controller,
              physics: state.saving || state.loading
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              onPageChanged: context.read<OnboardingCubit>().showPage,
              itemCount: OnboardingPageContent.pages.length,
              itemBuilder: (_, i) =>
                  OnboardingPageViewItem(page: OnboardingPageContent.pages[i]),
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
