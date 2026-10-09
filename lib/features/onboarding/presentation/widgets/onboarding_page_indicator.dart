import 'package:flutter/material.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    required this.page,
    required this.count,
    super.key,
  });
  final int page, count;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Page ${page + 1} of $count',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++)
            Container(
              width: index == page ? 28 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: index == page
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    ),
  );
}
