import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    required this.page,
    required this.count,
    this.onSelect,
    super.key,
  });
  final int page, count;
  final ValueChanged<int>? onSelect;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('Page {value1} of {value2}', {
      'value1': (page + 1).toString(),
      'value2': (count).toString(),
    }),
    liveRegion: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < count; index++)
          Semantics(
            button: onSelect != null,
            selected: index == page,
            label: context.tr('Page {value1} of {value2}', {
              'value1': (index + 1).toString(),
              'value2': count.toString(),
            }),
            child: InkWell(
              onTap: onSelect == null ? null : () => onSelect!(index),
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
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
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
