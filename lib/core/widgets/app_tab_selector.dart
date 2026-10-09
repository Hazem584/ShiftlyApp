import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';

/// Tabs with wrapping labels and accessible touch targets.
class AppTabSelector extends StatelessWidget {
  const AppTabSelector({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.labelKeys,
    super.key,
  });

  final List<String> labels;
  final List<Key>? labelKeys;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.field,
      borderRadius: BorderRadius.circular(AppRadii.m),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Semantics(
                selected: selectedIndex == index,
                child: TextButton(
                  onPressed: () => onSelected(index),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    foregroundColor: selectedIndex == index
                        ? AppColors.ink
                        : AppColors.textSecondary,
                    backgroundColor: selectedIndex == index
                        ? AppColors.surface
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.s),
                    ),
                  ),
                  child: Text(
                    labels[index],
                    key: labelKeys?[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
