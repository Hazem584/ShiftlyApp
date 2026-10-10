import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    required this.page,
    required this.count,
    super.key,
  });
  final int page, count;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('Page {value1} of {value2}', {
      'value1': (page + 1).toString(),
      'value2': (count).toString(),
    }),
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
