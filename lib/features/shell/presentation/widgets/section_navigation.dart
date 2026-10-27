import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

/// Every section is visible, including on narrow screens; no hidden icon menu.
class SectionNavigation extends StatelessWidget {
  const SectionNavigation({
    required this.items,
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final List<(String, String)> items;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 21;
      final columns = large || box.maxWidth < 300
          ? 1
          : box.maxWidth >= 900
          ? 4
          : box.maxWidth >= 600
          ? 3
          : 2;
      final width = (box.maxWidth - 32 - (columns - 1) * 8) / columns;
      final colors = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < items.length; i++)
              SizedBox(
                width: width,
                child: Semantics(
                  selected: i == selected,
                  child: OutlinedButton(
                    key: Key('section-${items[i].$1}'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: i == selected
                          ? colors.primaryContainer
                          : colors.surface,
                      foregroundColor: i == selected
                          ? colors.primary
                          : colors.onSurface,
                      side: BorderSide(
                        color: i == selected
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => onSelected(i),
                    child: Text(
                      context.tr(items[i].$2),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
